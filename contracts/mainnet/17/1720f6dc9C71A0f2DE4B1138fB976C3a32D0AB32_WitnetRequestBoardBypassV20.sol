// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "../../WitnetUpgradableBase.sol";
import "../../../WitnetRequestBoard.sol";

import "../../../data/WitnetBoardDataACLs.sol";

import "../../../interfaces/V2/IWitnetConsumer.sol";
import "../../../interfaces/V2/IWitnetOracle.sol";
import "../../../interfaces/V2/IWitnetOracleEvents.sol";

import "../../../libs/WitnetErrorsLib.sol";

abstract contract WitnetOracleV07 {
    
    WitnetRequestFactory immutable public factory;
    WitnetBytecodes immutable public registry;

    constructor (WitnetRequestFactory _factory) {
        require(
            _factory.class() == type(WitnetRequestFactory).interfaceId,
            "WitnetRequestBoardBypassV20: uncompliant factory"
        );
        factory = _factory;
        registry = _factory.registry();
    }
}

abstract contract WitnetOracleV20
    is
        IWitnetOracle,
        IWitnetOracleEvents
{
    function specs() virtual external view returns (bytes4);
}

/// @title Witnet Request Board bypass implementation to V2.0 
/// @author The Witnet Foundation
contract WitnetRequestBoardBypassV20
    is 
        IWitnetConsumer,
        IWitnetOracleEvents,
        IWitnetRequestBoardEvents,
        WitnetUpgradableBase,
        WitnetOracleV07,
        WitnetBoardDataACLs
{
    using ERC165Checker for address;

    using Witnet for bytes;
    using Witnet for Witnet.Result;
    using WitnetCBOR for WitnetCBOR.CBOR;

    WitnetOracleV07 immutable public legacy;
    WitnetOracleV20 immutable public surrogate;

    uint24 immutable public legacyCallbackLimit;

    uint8  constant internal _DEFAULT_SLA_COMMITTEE_SIZE = 10;
    uint64 constant internal _DEFAULT_SLA_WITNESSING_FEE_NANOWIT = 200000000;
    
    function defaultRadonSLA() virtual public pure returns (WitnetV2.RadonSLA memory) {
        return WitnetV2.RadonSLA({
            committeeSize: _DEFAULT_SLA_COMMITTEE_SIZE,
            witnessingFeeNanoWit: _DEFAULT_SLA_WITNESSING_FEE_NANOWIT
        });
    }

    modifier legacyFallback(uint256 queryId) {
        if (queryId <= __storage().numQueries) {
            __legacyFallback();
        } else {
            _;
        }
    }

    modifier onlySurrogate {
        require(
            msg.sender == address(surrogate),
            "WitnetRequestBoardBypassV20: only surrogate"
        ); _;
    }
    
    constructor(
            WitnetOracleV07 _legacy,
            WitnetOracleV20 _surrogate,
            bool _upgradable,
            bytes32 _versionTag,
            uint24 _legacyCallbackLimit
        )
        WitnetOracleV07(_legacy.factory())
        WitnetUpgradableBase(
            _upgradable,
            _versionTag,
            "io.witnet.proxiable.board"
        )
    {
        legacy = _legacy;
        require(
            address(_surrogate).code.length > 0
                && _surrogate.specs() == type(IWitnetOracle).interfaceId,
            "WitnetRequestBoardBypassV20: uncompliant WitnetOracle"
        );
        surrogate = _surrogate;
        require(
            _legacyCallbackLimit >= 50000,
            "WitnetRequestBoardBypassV20: legacy callback too low"
        );
        legacyCallbackLimit = _legacyCallbackLimit;
    }

    receive() external payable { 
        revert("WitnetRequestBoardBypassV20: no transfers accepted");
    }

    /// @dev Fallback unhandled methods to whatever the late legacy implementation was supported
    // solhint-disable-next-line payable-fallback
    fallback() virtual override external { /* solhint-disable no-complex-fallback */
        __legacyFallback();
    }

    function numLegacyQueries() external view returns (uint256) {
        return __storage().numQueries;
    }


    // ================================================================================================================
    // --- Implementation of IERC165 interface ------------------------------------------------------------------------

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return (
            _interfaceId == type(WitnetRequestBoard).interfaceId
                || super.supportsInterface(_interfaceId)
        );
    }


    // ================================================================================================================
    // --- Implementation of 'Upgradeable' ----------------------------------------------------------------------------

    /// @notice Re-initialize contract's storage context upon a new upgrade from a proxy.
    /// @dev Must fail when trying to upgrade to same logic contract more than once.
    function initialize(bytes memory) public override {
        address _owner = __storage().owner;
        if (_owner == address(0)) {
            revert("WitnetRequestBoardBypassV20: cannot bypass uninitialized proxy");
        } else {
            // only owner can initialize:
            require(
                msg.sender == _owner,
                "WitnetRequestBoardBypassV20: only legacy owner"
            );
        }

        if (__storage().base != address(0)) {
            // current implementation cannot be initialized more than once:
            require(
                __storage().base != base(),
                "WitnetRequestBoardBypassV20: already upgraded"
            );
        }        
        __storage().base = base();

        emit Upgraded(msg.sender, base(), codehash(), version());
    }

    /// Tells whether provided address could eventually upgrade the contract.
    function isUpgradableFrom(address _from) external view override returns (bool) {
        address _owner = __storage().owner;
        return (
            // false if the WRB is intrinsically not upgradable, or `_from` is no owner
            isUpgradable()
                && _owner == _from
        );
    }


    // ================================================================================================================
    // --- Implementation of 'Ownable' --------------------------------------------------------------------------------

    /// Gets admin/owner address.
    function owner() public view override returns (address) {
        return __storage().owner;
    }

    /// Transfers ownership.
    function transferOwnership(address _newOwner) public override onlyOwner {
        address _owner = __storage().owner;
        if (_newOwner != _owner) {
            __storage().owner = _newOwner;
            emit OwnershipTransferred(_owner, _newOwner);
        }
    }


    // ================================================================================================================
    // --- Implementation of 'IWitnetConsumer' ------------------------------------------------------------------------

    /// @notice Method to be called from the WitnetOracle contract as soon as the given Witnet `queryId`
    /// @notice gets reported, if reported with no errors.
    /// @dev It should revert if called from any other address different to the WitnetOracle being used
    /// @dev by the WitnetConsumer contract. 
    /// @param _witnetQueryId The unique identifier of the Witnet query being reported.
    /// @param _witnetResultCborValue The CBOR-encoded resulting value of the Witnet query being reported.
    function reportWitnetQueryResult(
            uint256 _witnetQueryId, 
            uint64, bytes32, uint256,
            WitnetCBOR.CBOR calldata _witnetResultCborValue
        ) 
        external override
        onlySurrogate 
    {
        _witnetQueryId += __storage().numQueries;
        require(
            _statusOf(_witnetQueryId) == Witnet.QueryStatus.Posted,
            "WitnetRequestBoardBypassV20: not in Posted status"
        );
        Witnet.Query storage __record = __storage().queries[_witnetQueryId];
        __record.response = Witnet.Response({
            reporter: address(0), //msg.sender,
            timestamp: 0, // uint256(_witnetResultTimestamp),
            drTxHash: 0, // _witnetResultTallyHash,
            cborBytes: _witnetResultCborValue.buffer.data
        });
        emit PostedResult(_witnetQueryId, msg.sender);
    }

    /// @notice Method to be called from the WitnetOracle contract as soon as the given Witnet `queryId`
    /// @notice gets reported, if reported WITH errors.
    /// @dev It should revert if called from any other address different to the WitnetOracle being used
    /// @dev by the WitnetConsumer contract. 
    /// @param _witnetQueryId The unique identifier of the Witnet query being reported.
    /// @param _errorArgs Error arguments, if any. An empty buffer is to be passed if no error arguments apply.
    function reportWitnetQueryError(
            uint256 _witnetQueryId, 
            uint64, bytes32, uint256,
            Witnet.ResultErrorCodes, 
            WitnetCBOR.CBOR calldata _errorArgs
        ) 
        external override
        onlySurrogate
    {
        _witnetQueryId += __storage().numQueries;
        require(
            _statusOf(_witnetQueryId) == Witnet.QueryStatus.Posted,
            "WitnetRequestBoardBypassV20: not in Posted status"
        );
        Witnet.Query storage __record = __storage().queries[_witnetQueryId];
        __record.response = Witnet.Response({
            reporter: address(0), //msg.sender,
            timestamp: 0, //uint256(_witnetResultTimestamp),
            drTxHash: 0, //_witnetResultTallyHash,
            cborBytes: _errorArgs.buffer.data
        });
        emit PostedResult(_witnetQueryId, msg.sender);
    }


    /// @notice Determines if Witnet queries can be reported from given address.
    /// @dev In practice, must only be true on the WitnetOracle address that's being used by
    /// @dev the WitnetConsumer to post queries. 
    function reportableFrom(address _from) external view override returns (bool) {
        return (
            _from == address(surrogate)
        );
    }


    // ================================================================================================================
    // --- Interception of 'IWitnetRequestBoardReporter' --------------------------------------------------------------

    function reportResult(uint256 _queryId, bytes32, bytes calldata)
        external 
        legacyFallback(_queryId)
    {
        revert("WitnetRequestBoardBypassV20: not permitted");
    }
    
    function reportResult(uint256 _queryId, uint256, bytes32, bytes calldata) 
        external 
        legacyFallback(_queryId)
    {
        revert("WitnetRequestBoardBypassV20: not permitted");
    }
    
    function reportResultBatch(IWitnetRequestBoardReporter.BatchResult[] memory, bool)
        external pure
    {
        revert("WitnetRequestBoardBypassV20: not permitted");
    }


    // ================================================================================================================
    // --- Full interception of 'IWitnetRequestBoardRequestor' --------------------------------------------------------

    /// @notice Returns query's result current status from a requester's point of view:
    /// @notice   - 0 => Void: the query is either non-existent or deleted;
    /// @notice   - 1 => Awaiting: the query has not yet been reported;
    /// @notice   - 2 => Ready: the query has been succesfully solved;
    /// @notice   - 3 => Error: the query couldn't get solved due to some issue.
    /// @param _queryId The unique query identifier.
    function checkResultStatus(uint256 _queryId)
        public
        legacyFallback(_queryId) 
        returns (Witnet.ResultStatus)
    {
        Witnet.QueryStatus _status = _statusOf(_queryId);
        if (_status == Witnet.QueryStatus.Reported) {
            if (__response(_queryId).cborBytes[0] == bytes1(0xd8)) {
                return Witnet.ResultStatus.Error;
            } else {
                return Witnet.ResultStatus.Ready;
            }
        } else if (_status == Witnet.QueryStatus.Posted) {
            return Witnet.ResultStatus.Awaiting;
        } else {
            return Witnet.ResultStatus.Void;
        }
    }

    /// @notice Gets error code identifying some possible failure on the resolution of the given query.
    /// @param _queryId The unique query identifier.
    function checkResultError(uint256 _queryId)
        external 
        legacyFallback(_queryId) 
        returns (Witnet.ResultError memory)
    {
        Witnet.ResultStatus _status = checkResultStatus(_queryId);
        if (_status == Witnet.ResultStatus.Awaiting) {
            return Witnet.ResultError({
                code: Witnet.ResultErrorCodes.Unknown,
                reason: "WitnetRequestBoardBypassV20: not yet solved"
            });
        } else if (_status == Witnet.ResultStatus.Void) {
            return Witnet.ResultError({
                code: Witnet.ResultErrorCodes.Unknown,
                reason: "WitnetRequestBoardBypassV20: unknown query"
            });
        } else {
            try WitnetErrorsLib.resultErrorFromCborBytes(__response(_queryId).cborBytes)
                returns (Witnet.ResultError memory _error)
            {
                return _error;
            }
            catch Error(string memory _reason) {
                return Witnet.ResultError({
                    code: Witnet.ResultErrorCodes.Unknown,
                    reason: string(abi.encodePacked("WitnetErrorsLib: ", _reason))
                });
            }
            catch (bytes memory) {
                return Witnet.ResultError({
                    code: Witnet.ResultErrorCodes.Unknown,
                    reason: "WitnetErrorsLib: assertion failed"
                });
            }
        }
    }

    /// Retrieves copy of all response data related to a previously posted request, removing the whole query from storage.
    /// @dev Fails if the `_queryId` is not in 'Reported' status, or called from an address different to
    /// @dev the one that actually posted the given request.
    /// @param _queryId The unique query identifier.
    function deleteQuery(uint256 _queryId)
        external
        legacyFallback(_queryId) 
        returns (Witnet.Response memory _response)
    {
        Witnet.Query storage __record = __storage().queries[_queryId];
        require(
            msg.sender == __record.from,
            "WitnetRequestBoardBypassV20: only requester"
        );
        WitnetV2.Response memory _responseV2 = surrogate.fetchQueryResponse(
            _queryId - __storage().numQueries
        );
        _response = Witnet.Response({
            reporter: _responseV2.reporter,
            timestamp: uint256(_responseV2.resultTimestamp),
            drTxHash: _responseV2.resultTallyHash,
            cborBytes: __record.response.cborBytes
        });
        delete __storage().queries[_queryId];
    }

    /// Requests the execution of the given Witnet Data Request in expectation that it will be relayed and solved by the Witnet DON.
    /// A reward amount is escrowed by the Witnet Request Board that will be transferred to the reporter who relays back the Witnet-provided 
    /// result to this request.
    /// @dev Fails if:
    /// @dev - provided reward is too low.
    /// @dev - provided address is zero.
    /// @param _witnetRequest The address of a IWitnetRequest contract, containing the actual Data Request seralized bytecode.
    /// @return _queryId An unique query identifier.
    function postRequest(IWitnetRequest _witnetRequest)
        external payable
        returns (uint256 _queryId)
    {
        _queryId = (
            __storage().numQueries + 
                surrogate.postRequestWithCallback{
                    value: msg.value
                }(
                    _extractRAD(_witnetRequest.bytecode()),
                    defaultRadonSLA(),
                    legacyCallbackLimit
                )
        );
        __storage().queries[_queryId].from = msg.sender;
        __storage().queries[_queryId].request.addr = address(_witnetRequest);
        __storage().queries[_queryId].request.gasprice = tx.gasprice;
    }

    /// Requests the execution of the given Witnet Data Request in expectation that it will be relayed and solved by the Witnet DON.
    /// A reward amount is escrowed by the Witnet Request Board that will be transferred to the reporter who relays back the Witnet-provided 
    /// result to this request.
    /// @dev Fails if:
    /// @dev - provided reward is too low.
    /// @param _radHash The radHash of the Witnet Data Request.
    /// @param _slaHash The slaHash of the Witnet Data Request.
    function postRequest(bytes32 _radHash, bytes32 _slaHash)
        external payable
        returns (uint256 _queryId)
    {
        Witnet.RadonSLA memory _slaParams = registry.lookupRadonSLA(_slaHash);
        _queryId = (
            __storage().numQueries +
                surrogate.postRequestWithCallback{
                    value: msg.value
                }(
                    registry.bytecodeOf(_radHash),
                    WitnetV2.RadonSLA({
                        committeeSize: _slaParams.numWitnesses,
                        witnessingFeeNanoWit: _slaParams.witnessCollateral / 100
                    }),
                    legacyCallbackLimit
                )
        );
        __storage().queries[_queryId].from = msg.sender;
        __storage().queries[_queryId].request.gasprice = tx.gasprice;
        __storage().queries[_queryId].request.radHash = _radHash;
        __storage().queries[_queryId].request.slaHash = _slaHash;
    }

    /// Requests the execution of the given Witnet Data Request in expectation that it will be relayed and solved by the Witnet DON.
    /// A reward amount is escrowed by the Witnet Request Board that will be transferred to the reporter who relays back the Witnet-provided 
    /// result to this request.
    /// @dev Fails if:
    /// @dev - provided reward is too low.
    /// @param _radHash The RAD hash of the data tequest to be solved by Witnet.
    /// @param _slaParams The SLA param of the data request to be solved by Witnet.
    function postRequest(
            bytes32 _radHash, 
            Witnet.RadonSLA calldata _slaParams
        ) 
        public payable 
        returns (uint256 _queryId)
    {
        _queryId = (
            __storage().numQueries +
                surrogate.postRequestWithCallback{
                    value: msg.value
                }(
                    registry.bytecodeOf(_radHash),
                    WitnetV2.RadonSLA({
                        committeeSize: _slaParams.numWitnesses,
                        witnessingFeeNanoWit: _slaParams.witnessCollateral / 100
                    }),
                    legacyCallbackLimit
                )
        );
        __storage().queries[_queryId].from = msg.sender;
        __storage().queries[_queryId].request.gasprice = tx.gasprice;
        __storage().queries[_queryId].request.radHash = _radHash;
        __storage().queries[_queryId].request.slaHash = registry.verifyRadonSLA(_slaParams);
    }
    
    /// Increments the reward of a previously posted request by adding the transaction value to it.
    /// @dev Updates request `gasPrice` in case this method is called with a higher 
    /// @dev gas price value than the one used in previous calls to `postRequest` or
    /// @dev `upgradeReward`. 
    /// @dev Fails if the `_queryId` is not in 'Posted' status.
    /// @dev Fails also in case the request `gasPrice` is increased, and the new 
    /// @dev reward value gets below new recalculated threshold. 
    /// @param _queryId The unique query identifier.
    function upgradeReward(uint256 _queryId)
        external payable 
        legacyFallback(_queryId)
    {
        surrogate.upgradeQueryEvmReward{
            value: msg.value
        }(
            _queryId - __storage().numQueries
        );
        if (__request(_queryId).gasprice < tx.gasprice) {
            __request(_queryId).gasprice = tx.gasprice;
        }
    }


    // ================================================================================================================
    // --- Full interception of 'IWitnetRequestBoardView' -------------------------------------------------------------

    /// Estimates the amount of reward we need to insert for a given gas price.
    /// @param _gasPrice The gas price for which we need to calculate the rewards.
    function estimateReward(uint256 _gasPrice) external view returns (uint256) {
        return surrogate.estimateBaseFeeWithCallback(
            _gasPrice, 
            legacyCallbackLimit
        );
    }

    /// Returns next request id to be generated by the Witnet Request Board.
    function getNextQueryId() external view returns (uint256) {
        return (
            __storage().numQueries 
                + surrogate.getNextQueryId()
        );
    }

    /// Gets the whole Query data contents, if any, no matter its current status.
    function getQueryData(uint256 _queryId)
        external 
        legacyFallback(_queryId) 
        returns (Witnet.Query memory)
    {
        return Witnet.Query({
            from: __query(_queryId).from,
            request: readRequest(_queryId),
            response: readResponse(_queryId)
        });
    }

    /// Gets current status of given query.
    function getQueryStatus(uint256 _queryId)
        external 
        legacyFallback(_queryId) 
        returns (Witnet.QueryStatus)
    {
        WitnetV2.QueryStatus _queryStatusV2 = surrogate.getQueryStatus(
            _queryId - __storage().numQueries
        );
        if (_queryStatusV2 == WitnetV2.QueryStatus.Finalized) {
            return Witnet.QueryStatus.Reported;
        } else {
            return Witnet.QueryStatus(uint8(_queryStatusV2));
        }
    }

    /// Retrieves the whole Request record posted to the Witnet Request Board.
    /// @dev Fails if the `_queryId` is not valid or, if it has already been reported
    /// @dev or deleted.
    /// @param _queryId The unique identifier of a previously posted query.
    function readRequest(uint256 _queryId)
        public 
        legacyFallback(_queryId) 
        returns (Witnet.Request memory _request)
    {
        return Witnet.Request({
            addr: __request(_queryId).addr,
            slaHash: __request(_queryId).slaHash,
            radHash: __request(_queryId).radHash,
            gasprice: __request(_queryId).gasprice,
            reward: surrogate.getQueryEvmReward(_queryId - __storage().numQueries)
        });
    }
    
    /// Retrieves the serialized bytecode of a previously posted Witnet Data Request.
    /// @dev Fails if the `_queryId` is not valid, or if the related script bytecode 
    /// @dev got changed after being posted. Returns empty array once it gets reported, 
    /// @dev or deleted.
    /// @param _queryId The unique query identifier.
    function readRequestBytecode(uint256 _queryId)
        external 
        legacyFallback(_queryId) 
        returns (bytes memory _bytecode)
    {
        WitnetV2.Request memory _requestV2 = surrogate.getQueryRequest(
            _queryId - __storage().numQueries
        );
        return _requestV2.witnetBytecode;
    }

    /// @notice Retrieves the gas price that any assigned reporter will have to pay when reporting 
    /// result to a previously posted Witnet data request.
    /// @dev Fails if the `_queryId` is not valid or, if it has already been 
    /// @dev reported, or deleted. 
    /// @param _queryId The unique query identifie
    function readRequestGasPrice(uint256 _queryId) 
        external 
        legacyFallback(_queryId)
        returns (uint256)
    {
        return __request(_queryId).gasprice;
    }

    /// Retrieves the reward currently set for a previously posted request.
    /// @dev Fails if the `_queryId` is not valid or, if it has already been 
    /// @dev reported, or deleted. 
    /// @param _queryId The unique query identifier
    function readRequestReward(uint256 _queryId) external legacyFallback(_queryId) returns (uint256) {
        return surrogate.getQueryEvmReward(
            _queryId - __storage().numQueries
        );
    }

    /// Retrieves the Witnet-provided result, and metadata, to a previously posted request.    
    /// @dev Fails if the `_queryId` is not in 'Reported' status.
    /// @param _queryId The unique query identifier
    function readResponse(uint256 _queryId)
        public 
        legacyFallback(_queryId) 
        returns (Witnet.Response memory _response)
    {
        WitnetV2.Response memory _responseV2 = surrogate.getQueryResponse(
            _queryId - __storage().numQueries
        );
        return Witnet.Response({
            reporter: _responseV2.reporter,
            timestamp: uint256(_responseV2.resultTimestamp),
            drTxHash: _responseV2.resultTallyHash,
            cborBytes: __response(_queryId).cborBytes
        });
    }

    /// Retrieves the hash of the Witnet transaction that actually solved the referred query.
    /// @dev Fails if the `_queryId` is not in 'Reported' status.
    /// @param _queryId The unique query identifier.
    function readResponseDrTxHash(uint256 _queryId)
        external 
        legacyFallback(_queryId) 
        returns (bytes32)
    {
        WitnetV2.Response memory _responseV2 = surrogate.getQueryResponse(
            _queryId - __storage().numQueries
        );
        return _responseV2.resultTallyHash;
    }

    /// Retrieves the address that reported the result to a previously-posted request.
    /// @dev Fails if the `_queryId` is not in 'Reported' status.
    /// @param _queryId The unique query identifier
    function readResponseReporter(uint256 _queryId)
        external 
        legacyFallback(_queryId) 
        returns (address)
    {
        WitnetV2.Response memory _responseV2 = surrogate.getQueryResponse(
            _queryId - __storage().numQueries
        );
        return _responseV2.reporter;
    }

    /// Retrieves the Witnet-provided CBOR-bytes result of a previously posted request.
    /// @dev Fails if the `_queryId` is not in 'Reported' status.
    /// @param _queryId The unique query identifier
    function readResponseResult(uint256 _queryId)
        external
        legacyFallback(_queryId) 
        returns (Witnet.Result memory)
    {
        return Witnet.resultFromCborBytes(__response(_queryId).cborBytes);
    }

    /// Retrieves the timestamp in which the result to the referred query was solved by the Witnet DON.
    /// @dev Fails if the `_queryId` is not in 'Reported' status.
    /// @param _queryId The unique query identifier.
    function readResponseTimestamp(uint256 _queryId)
        external 
        legacyFallback(_queryId) 
        returns (uint256)
    {
        WitnetV2.Response memory _responseV2 = surrogate.getQueryResponse(
            _queryId - __storage().numQueries
        );
        return uint256(_responseV2.resultTimestamp);
    }


    // ================================================================================================================
    // --- Internal functions -----------------------------------------------------------------------------------------

    function _reverseSeek(bytes memory _buffer, bytes1 _char, uint256 _offset) internal pure returns (uint256 _index) {
        unchecked {
            _index = _offset;
            while (_index > 0 && _buffer[-- _index] != _char) {}            
        }
    }

    function _extractRAD(bytes memory _witnetBytecode) internal pure returns (bytes memory _output) {
        uint256 _length = _reverseSeek(_witnetBytecode, 0x30, _witnetBytecode.length);
        _length = _reverseSeek(_witnetBytecode, 0x28, _length);
        _length = _reverseSeek(_witnetBytecode, 0x20, _length);
        _length = _reverseSeek(_witnetBytecode, 0x18, _length);
        _length = _reverseSeek(_witnetBytecode, 0x10, _length);
        uint256 _offset = _skipCborStructLength(_witnetBytecode);
        unchecked {
            _output = new bytes(_length - _offset);
            for (uint256 _ix = 0; _ix < _length - _offset; _ix ++) {
                _output[_ix] = _witnetBytecode[_ix + _offset];
            }
        }
    }

    function _skipCborStructLength(bytes memory _buffer) internal pure returns (uint256 _index) {
        unchecked {
            _index = 1;
            while (_index < _buffer.length && _buffer[_index ++] & 0x80 != bytes1(0)) {}
        }
    }

    function _statusOf(uint256 _queryId)
      override internal view
      returns (Witnet.QueryStatus)
    {
      Witnet.Query storage _query = __storage().queries[_queryId];
      if (_query.response.cborBytes.length != 0) {
        return Witnet.QueryStatus.Reported;
      }
      else if (_query.from != address(0)) {
        return Witnet.QueryStatus.Posted;
      }
      else {
        return Witnet.QueryStatus.Unknown;
      }
    }

    function __legacyFallback() internal {
        address _legacy = address(legacy);
        assembly { /* solhint-disable avoid-low-level-calls */
            // Gas optimized delegate call to 'implementation' contract.
            // Note: `msg.data`, `msg.sender` and `msg.value` will be passed over 
            //       to actual implementation of `msg.sig` within `implementation` contract.
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _legacy, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            switch result
                case 0  { 
                    // pass back revert message:
                    revert(ptr, size) 
                }
                default {
                  // pass back same data as returned by 'implementation' contract:
                  return(ptr, size) 
                }
        }
    }
}

// SPDX-License-Identifier: MIT

/* solhint-disable var-name-mixedcase */

pragma solidity >=0.6.0 <0.9.0;

import "./Initializable.sol";
import "./Proxiable.sol";

abstract contract Upgradeable is Initializable, Proxiable {

    address internal immutable _BASE;
    bytes32 internal immutable _CODEHASH;
    bool internal immutable _UPGRADABLE;

    modifier onlyDelegateCalls virtual {
        require(
            address(this) != _BASE,
            "Upgradeable: not a delegate call"
        );
        _;
    }

    /// Emitted every time the contract gets upgraded.
    /// @param from The address who ordered the upgrading. Namely, the WRB operator in "trustable" implementations.
    /// @param baseAddr The address of the new implementation contract.
    /// @param baseCodehash The EVM-codehash of the new implementation contract.
    /// @param versionTag Ascii-encoded version literal with which the implementation deployer decided to tag it.
    event Upgraded(
        address indexed from,
        address indexed baseAddr,
        bytes32 indexed baseCodehash,
        string  versionTag
    );

    constructor (bool _isUpgradable) {
        address _base = address(this);
        bytes32 _codehash;        
        assembly {
            _codehash := extcodehash(_base)
        }
        _BASE = _base;
        _CODEHASH = _codehash;
        _UPGRADABLE = _isUpgradable;
    }

    /// @dev Retrieves base contract. Differs from address(this) when called via delegate-proxy pattern.
    function base() public view returns (address) {
        return _BASE;
    }

    /// @dev Retrieves the immutable codehash of this contract, even if invoked as delegatecall.
    function codehash() public view returns (bytes32) {
        return _CODEHASH;
    }

    /// @dev Determines whether the logic of this contract is potentially upgradable.
    function isUpgradable() public view returns (bool) {
        return _UPGRADABLE;
    }

    /// @dev Tells whether provided address could eventually upgrade the contract.
    function isUpgradableFrom(address from) virtual external view returns (bool);

    /// @notice Re-initialize contract's storage context upon a new upgrade from a proxy.    
    /// @dev Must fail when trying to upgrade to same logic contract more than once.
    function initialize(bytes memory) virtual external;

    /// @dev Retrieves human-redable named version of current implementation.
    function version() virtual public view returns (string memory); 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

abstract contract Proxiable {
    /// @dev Complying with EIP-1822: Universal Upgradeable Proxy Standard (UUPS)
    /// @dev See https://eips.ethereum.org/EIPS/eip-1822.
    function proxiableUUID() virtual external view returns (bytes32);

    struct ProxiableSlot {
        address implementation;
        address proxy;
    }

    function __implementation() internal view returns (address) {
        return __proxiable().implementation;
    }

    function __proxy() internal view returns (address) {
        return __proxiable().proxy;
    }

    function __proxiable() internal pure returns (ProxiableSlot storage proxiable) {
        assembly {
            // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
            proxiable.slot := 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is specified at deployment time in the constructor for `Ownable`. This
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
        if (pendingOwner() != sender) {
            revert("Ownable2Step: caller is not the new owner");
        }
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./Witnet.sol";

library WitnetV2 {

    /// Struct containing both request and response data related to every query posted to the Witnet Request Board
    struct Query {
        Request request;
        Response response;
    }

    /// Possible status of a Witnet query.
    enum QueryStatus {
        Unknown,
        Posted,
        Reported,
        Finalized
    }

    /// Data kept in EVM-storage for every Request posted to the Witnet Request Board.
    struct Request {
        address requester;              // EVM address from which the request was posted.
        uint24  gasCallback;            // Max callback gas limit upon response, if a callback is required.
        uint72  evmReward;              // EVM amount in wei eventually to be paid to the legit result reporter.
        bytes   witnetBytecode;         // Optional: Witnet Data Request bytecode to be solved by the Witnet blockchain.
        bytes32 witnetRAD;              // Optional: Previously verified hash of the Witnet Data Request to be solved.
        Witnet.RadonSLA witnetSLA;    // Minimum Service-Level parameters to be committed by the Witnet blockchain. 
    }

    /// Response metadata and result as resolved by the Witnet blockchain.
    struct Response {
        address reporter;               // EVM address from which the Data Request result was reported.
        uint64  finality;               // EVM block number at which the reported data will be considered to be finalized.
        uint32  resultTimestamp;        // Unix timestamp (seconds) at which the data request was resolved in the Witnet blockchain.
        bytes32 resultTallyHash;        // Unique hash of the commit/reveal act in the Witnet blockchain that resolved the data request.
        bytes   resultCborBytes;        // CBOR-encode result to the request, as resolved in the Witnet blockchain.
    }

    /// Response status from a requester's point of view.
    enum ResponseStatus {
        Void,
        Awaiting,
        Ready,
        Error,
        Finalizing,
        Delivered
    }

    struct RadonSLA {
        /// @notice Number of nodes in the Witnet blockchain that will take part in solving the data request. 
        uint8   committeeSize;
        
        /// @notice Fee in $nanoWIT paid to every node in the Witnet blockchain involved in solving the data request.
        /// @dev Witnet nodes participating as witnesses will have to stake as collateral 100x this amount.
        uint64  witnessingFeeNanoWit;
    }

    
    /// ===============================================================================================================
    /// --- 'WitnetV2.RadonSLA' helper methods ------------------------------------------------------------------------

    function equalOrGreaterThan(RadonSLA memory a, RadonSLA memory b) 
        internal pure returns (bool)
    {
        return (a.committeeSize >= b.committeeSize);
    }
     
    function isValid(RadonSLA calldata sla) internal pure returns (bool) {
        return (
            sla.witnessingFeeNanoWit > 0 
                && sla.committeeSize > 0 && sla.committeeSize <= 127
                // v1.7.x requires witnessing collateral to be greater or equal to 20 WIT:
                && sla.witnessingFeeNanoWit * 100 >= 20 * 10 ** 9 
        );
    }

    function toV1(RadonSLA memory self) internal pure returns (Witnet.RadonSLA memory) {
        return Witnet.RadonSLA({
            numWitnesses: self.committeeSize,
            minConsensusPercentage: 51,
            witnessReward: self.witnessingFeeNanoWit,
            witnessCollateral: self.witnessingFeeNanoWit * 100,
            minerCommitRevealFee: self.witnessingFeeNanoWit / self.committeeSize
        });
    }

    function nanoWitTotalFee(RadonSLA storage self) internal view returns (uint64) {
        return self.witnessingFeeNanoWit * (self.committeeSize + 3);
    }


    /// ===============================================================================================================
    /// --- P-RNG generators ------------------------------------------------------------------------------------------

    /// Generates a pseudo-random uint32 number uniformly distributed within the range `[0 .. range)`, based on
    /// the given `nonce` and `seed` values. 
    function randomUint32(uint32 range, uint256 nonce, bytes32 seed)
        internal pure 
        returns (uint32) 
    {
        uint256 _number = uint256(
            keccak256(
                abi.encode(seed, nonce)
            )
        ) & uint256(2 ** 224 - 1);
        return uint32((_number * range) >> 224);
    }


    /// ===============================================================================================================
    /// --- Runtime Custom errors -------------------------------------------------------------------------------------

    error IndexOutOfBounds(uint256 index, uint256 range);
    error InsufficientBalance(uint256 weiBalance, uint256 weiExpected);
    error InsufficientFee(uint256 weiProvided, uint256 weiExpected);
    error Unauthorized(address violator);

    error RadonFilterMissingArgs(uint8 opcode);

    error RadonRequestNoSources();
    error RadonRequestSourcesArgsMismatch(uint256 expected, uint256 actual);
    error RadonRequestMissingArgs(uint256 index, uint256 expected, uint256 actual);
    error RadonRequestResultsMismatch(uint256 index, uint8 read, uint8 expected);
    error RadonRequestTooHeavy(bytes bytecode, uint256 weight);

    error RadonSlaNoReward();
    error RadonSlaNoWitnesses();
    error RadonSlaTooManyWitnesses(uint256 numWitnesses);
    error RadonSlaConsensusOutOfRange(uint256 percentage);
    error RadonSlaLowCollateral(uint256 witnessCollateral);

    error UnsupportedDataRequestMethod(uint8 method, string schema, string body, string[2][] headers);
    error UnsupportedRadonDataType(uint8 datatype, uint256 maxlength);
    error UnsupportedRadonFilterOpcode(uint8 opcode);
    error UnsupportedRadonFilterArgs(uint8 opcode, bytes args);
    error UnsupportedRadonReducerOpcode(uint8 opcode);
    error UnsupportedRadonReducerScript(uint8 opcode, bytes script, uint256 offset);
    error UnsupportedRadonScript(bytes script, uint256 offset);
    error UnsupportedRadonScriptOpcode(bytes script, uint256 cursor, uint8 opcode);
    error UnsupportedRadonTallyScript(bytes32 hash);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./Witnet.sol";

/// @title A library for interpreting Witnet resolution errors
/// @author The Witnet Foundation.
library WitnetErrorsLib {

    using Witnet for uint8;
    using Witnet for uint256;
    using WitnetCBOR for WitnetCBOR.CBOR;

    // ================================================================================================================
    // --- Library public methods -------------------------------------------------------------------------------------
    
    /// @notice Extract error code and description string from given Witnet.Result.
    /// @dev Client contracts should wrap this function into a try-catch foreseeing potential parsing errors.
    /// @return _error Witnet.ResultError data struct containing error code and description.
    function asError(Witnet.Result memory result)
        public pure
        returns (Witnet.ResultError memory _error)
    {
         return _fromErrorArray(
            _errorsFromResult(result)
        );
    }

    /// @notice Extract error code and description string from given CBOR-encoded value.
    /// @dev Client contracts should wrap this function into a try-catch foreseeing potential parsing errors.
    /// @return _error Witnet.ResultError data struct containing error code and description.
    function resultErrorFromCborBytes(bytes memory cborBytes)
        public pure
        returns (Witnet.ResultError memory _error)
    {
        WitnetCBOR.CBOR[] memory errors = _errorsFromCborBytes(cborBytes);
        return _fromErrorArray(errors);
    }


    // ================================================================================================================
    // --- Library private methods ------------------------------------------------------------------------------------

    /// @dev Extract error codes from a CBOR-encoded `bytes` value.
    /// @param cborBytes CBOR-encode `bytes` value.
    /// @return The `uint[]` error parameters as decoded from the `Witnet.Result`.
    function _errorsFromCborBytes(bytes memory cborBytes)
        private pure
        returns(WitnetCBOR.CBOR[] memory)
    {
        Witnet.Result memory result = Witnet.resultFromCborBytes(cborBytes);
        return _errorsFromResult(result);
    }

    /// @dev Extract error codes from a Witnet.Result value.
    /// @param result An instance of `Witnet.Result`.
    /// @return The `uint[]` error parameters as decoded from the `Witnet.Result`.
    function _errorsFromResult(Witnet.Result memory result)
        private pure
        returns (WitnetCBOR.CBOR[] memory)
    {
        require(!result.success, "no errors");
        return result.value.readArray();
    }

    /// @dev Extract Witnet.ResultErrorCodes and error description from given array of CBOR values.
    function _fromErrorArray(WitnetCBOR.CBOR[] memory errors)
        private pure
        returns (Witnet.ResultError memory _error)
    {
        if (errors.length < 2) {
            return Witnet.ResultError({
                code: Witnet.ResultErrorCodes.Unknown,
                reason: "Unknown error: no error code was found."
            });
        }
        else {
            _error.code = Witnet.ResultErrorCodes(errors[0].readUint());
        }
        // switch on _error.code
        if (
            _error.code == Witnet.ResultErrorCodes.SourceScriptNotCBOR
                && errors.length > 1
        ) {
            _error.reason = string(abi.encodePacked(
                "Witnet: Radon: invalid CBOR value."
            ));
        } else if (
            _error.code == Witnet.ResultErrorCodes.SourceScriptNotArray
                && errors.length > 1
        ) {
            _error.reason = string(abi.encodePacked(
                "Witnet: Radon: CBOR value expected to be an array of calls."
            ));
        } else if (
            _error.code == Witnet.ResultErrorCodes.SourceScriptNotRADON
                && errors.length > 1
        ) {
            _error.reason = string(abi.encodePacked(
                "Witnet: Radon: CBOR value expected to be a data request."
            ));
        } else if (
            _error.code == Witnet.ResultErrorCodes.RequestTooManySources
                && errors.length > 1
        ) {
            _error.reason = string(abi.encodePacked(
                "Witnet: Radon: too many sources."
            ));
        } else if (
            _error.code == Witnet.ResultErrorCodes.ScriptTooManyCalls
                && errors.length > 1
        ) {
            _error.reason = string(abi.encodePacked(
                "Witnet: Radon: too many calls."
            ));
        } else if (
            _error.code == Witnet.ResultErrorCodes.UnsupportedOperator
                && errors.length > 3
        ) {
            _error.reason = string(abi.encodePacked(
                "Witnet: Radon: unsupported '",
                errors[2].readString(),
                "' for input type '",
                errors[1].readString(),
                "'."
            ));
        } else if (
            _error.code == Witnet.ResultErrorCodes.HttpErrors
                && errors.length > 2
        ) {
            _error.reason = string(abi.encodePacked(
                "Witnet: Retrieval: HTTP/",
                errors[1].readUint().toString(), 
                " error."
            ));
        } else if (
            _error.code == Witnet.ResultErrorCodes.RetrievalsTimeout
                && errors.length > 1
        ) {
            _error.reason = string(abi.encodePacked(
                "Witnet: Retrieval: timeout."
            ));
        } else if (
            _error.code == Witnet.ResultErrorCodes.MathUnderflow
                && errors.length > 1
        ) {
            _error.reason = string(abi.encodePacked(
                "Witnet: Aggregation: math underflow."
            ));
        } else if (
            _error.code == Witnet.ResultErrorCodes.MathOverflow
                && errors.length > 1
        ) {
            _error.reason = string(abi.encodePacked(
                "Witnet: Aggregation: math overflow."
            ));
        } else if (
            _error.code == Witnet.ResultErrorCodes.MathDivisionByZero
                && errors.length > 1
        ) {
            _error.reason = string(abi.encodePacked(
                "Witnet: Aggregation: division by zero."
            ));
        } else if (
            _error.code == Witnet.ResultErrorCodes.BridgeMalformedDataRequest
        ) {
            _error.reason = "Witnet: Bridge: malformed data request cannot be processed.";
        } else if (
            _error.code == Witnet.ResultErrorCodes.BridgePoorIncentives
        ) {
            _error.reason = "Witnet: Bridge: rejected due to poor witnessing incentives.";
        } else if (
            _error.code == Witnet.ResultErrorCodes.BridgeOversizedTallyResult
        ) {
            _error.reason = "Witnet: Bridge: rejected due to poor bridging incentives.";
        } else if (
            _error.code == Witnet.ResultErrorCodes.InsufficientMajority
                && errors.length > 3
        ) {
            uint reached = (errors[1].additionalInformation == 25
                ? uint(int(errors[1].readFloat16() / 10 ** 4))
                : uint(int(errors[1].readFloat64() / 10 ** 15))
            );
            uint expected = (errors[2].additionalInformation == 25
                ? uint(int(errors[2].readFloat16() / 10 ** 4))
                : uint(int(errors[2].readFloat64() / 10 ** 15))
            );
            _error.reason = string(abi.encodePacked(
                "Witnet: Tally: insufficient consensus: ",
                reached.toString(), 
                "% <= ",
                expected.toString(), 
                "%."
            ));
        } else if (
            _error.code == Witnet.ResultErrorCodes.InsufficientCommits
        ) {
            _error.reason = "Witnet: Tally: insufficient commits.";
        } else if (
            _error.code == Witnet.ResultErrorCodes.TallyExecution
                && errors.length > 3
        ) {
            _error.reason = string(abi.encodePacked(
                "Witnet: Tally: execution error: ",
                errors[2].readString(),
                "."
            ));
        } else if (
            _error.code == Witnet.ResultErrorCodes.ArrayIndexOutOfBounds
                && errors.length > 2
        ) {
            _error.reason = string(abi.encodePacked(
                "Witnet: Aggregation: tried to access a value from an array with an index (",
                errors[1].readUint().toString(),
                ") out of bounds."
            ));
        } else if (
            _error.code == Witnet.ResultErrorCodes.MapKeyNotFound
                && errors.length > 2
        ) {
            _error.reason = string(abi.encodePacked(
                "Witnet: Aggregation: tried to access a value from a map with a key (\"",
                errors[1].readString(),
                "\") that was not found."
            ));
        } else if (
            _error.code == Witnet.ResultErrorCodes.InsufficientReveals
        ) {
            _error.reason = "Witnet: Tally: no reveals.";
        } else if (
            _error.code == Witnet.ResultErrorCodes.MalformedReveals
        ) {
            _error.reason = "Witnet: Tally: malformed reveal.";
        } else if (
            _error.code == Witnet.ResultErrorCodes.UnhandledIntercept
        ) {
            _error.reason = "Witnet: Tally: unhandled intercept.";
        } else {
            _error.reason = string(abi.encodePacked(
                "Unhandled error: 0x",
                Witnet.toHexString(uint8(_error.code)),
                errors.length > 2
                    ? string(abi.encodePacked(" (", uint(errors.length - 1).toString(), " params)."))
                    : "."
            ));
        }
    }

    /// @notice Convert a stage index number into the name of the matching Witnet request stage.
    /// @param stageIndex A `uint64` identifying the index of one of the Witnet request stages.
    /// @return The name of the matching stage.
    function _stageName(uint64 stageIndex)
        private pure
        returns (string memory)
    {
        if (stageIndex == 0) {
            return "Retrieval";
        } else if (stageIndex == 1) {
            return "Aggregation";
        } else if (stageIndex == 2) {
            return "Tally";
        } else {
            return "(unknown)";
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./WitnetBuffer.sol";

/// @title A minimalistic implementation of “RFC 7049 Concise Binary Object Representation”
/// @notice This library leverages a buffer-like structure for step-by-step decoding of bytes so as to minimize
/// the gas cost of decoding them into a useful native type.
/// @dev Most of the logic has been borrowed from Patrick Gansterer’s cbor.js library: https://github.com/paroga/cbor-js
/// @author The Witnet Foundation.

library WitnetCBOR {

  using WitnetBuffer for WitnetBuffer.Buffer;
  using WitnetCBOR for WitnetCBOR.CBOR;

  /// Data struct following the RFC-7049 standard: Concise Binary Object Representation.
  struct CBOR {
      WitnetBuffer.Buffer buffer;
      uint8 initialByte;
      uint8 majorType;
      uint8 additionalInformation;
      uint64 len;
      uint64 tag;
  }

  uint8 internal constant MAJOR_TYPE_INT = 0;
  uint8 internal constant MAJOR_TYPE_NEGATIVE_INT = 1;
  uint8 internal constant MAJOR_TYPE_BYTES = 2;
  uint8 internal constant MAJOR_TYPE_STRING = 3;
  uint8 internal constant MAJOR_TYPE_ARRAY = 4;
  uint8 internal constant MAJOR_TYPE_MAP = 5;
  uint8 internal constant MAJOR_TYPE_TAG = 6;
  uint8 internal constant MAJOR_TYPE_CONTENT_FREE = 7;

  uint32 internal constant UINT32_MAX = type(uint32).max;
  uint64 internal constant UINT64_MAX = type(uint64).max;
  
  error EmptyArray();
  error InvalidLengthEncoding(uint length);
  error UnexpectedMajorType(uint read, uint expected);
  error UnsupportedPrimitive(uint primitive);
  error UnsupportedMajorType(uint unexpected);  

  modifier isMajorType(
      WitnetCBOR.CBOR memory cbor,
      uint8 expected
  ) {
    if (cbor.majorType != expected) {
      revert UnexpectedMajorType(cbor.majorType, expected);
    }
    _;
  }

  modifier notEmpty(WitnetBuffer.Buffer memory buffer) {
    if (buffer.data.length == 0) {
      revert WitnetBuffer.EmptyBuffer();
    }
    _;
  }

  function eof(CBOR memory cbor)
    internal pure
    returns (bool)
  {
    return cbor.buffer.cursor >= cbor.buffer.data.length;
  }

  /// @notice Decode a CBOR structure from raw bytes.
  /// @dev This is the main factory for CBOR instances, which can be later decoded into native EVM types.
  /// @param bytecode Raw bytes representing a CBOR-encoded value.
  /// @return A `CBOR` instance containing a partially decoded value.
  function fromBytes(bytes memory bytecode)
    internal pure
    returns (CBOR memory)
  {
    WitnetBuffer.Buffer memory buffer = WitnetBuffer.Buffer(bytecode, 0);
    return fromBuffer(buffer);
  }

  /// @notice Decode a CBOR structure from raw bytes.
  /// @dev This is an alternate factory for CBOR instances, which can be later decoded into native EVM types.
  /// @param buffer A Buffer structure representing a CBOR-encoded value.
  /// @return A `CBOR` instance containing a partially decoded value.
  function fromBuffer(WitnetBuffer.Buffer memory buffer)
    internal pure
    notEmpty(buffer)
    returns (CBOR memory)
  {
    uint8 initialByte;
    uint8 majorType = 255;
    uint8 additionalInformation;
    uint64 tag = UINT64_MAX;
    uint256 len;
    bool isTagged = true;
    while (isTagged) {
      // Extract basic CBOR properties from input bytes
      initialByte = buffer.readUint8();
      len ++;
      majorType = initialByte >> 5;
      additionalInformation = initialByte & 0x1f;
      // Early CBOR tag parsing.
      if (majorType == MAJOR_TYPE_TAG) {
        uint _cursor = buffer.cursor;
        tag = readLength(buffer, additionalInformation);
        len += buffer.cursor - _cursor;
      } else {
        isTagged = false;
      }
    }
    if (majorType > MAJOR_TYPE_CONTENT_FREE) {
      revert UnsupportedMajorType(majorType);
    }
    return CBOR(
      buffer,
      initialByte,
      majorType,
      additionalInformation,
      uint64(len),
      tag
    );
  }

  function fork(WitnetCBOR.CBOR memory self)
    internal pure
    returns (WitnetCBOR.CBOR memory)
  {
    return CBOR({
      buffer: self.buffer.fork(),
      initialByte: self.initialByte,
      majorType: self.majorType,
      additionalInformation: self.additionalInformation,
      len: self.len,
      tag: self.tag
    });
  }

  function settle(CBOR memory self)
      internal pure
      returns (WitnetCBOR.CBOR memory)
  {
    if (!self.eof()) {
      return fromBuffer(self.buffer);
    } else {
      return self;
    }
  }

  function skip(CBOR memory self)
      internal pure
      returns (WitnetCBOR.CBOR memory)
  {
    if (
      self.majorType == MAJOR_TYPE_INT
        || self.majorType == MAJOR_TYPE_NEGATIVE_INT
        || (
          self.majorType == MAJOR_TYPE_CONTENT_FREE 
            && self.additionalInformation >= 25
            && self.additionalInformation <= 27
        )
    ) {
      self.buffer.cursor += self.peekLength();
    } else if (
        self.majorType == MAJOR_TYPE_STRING
          || self.majorType == MAJOR_TYPE_BYTES
    ) {
      uint64 len = readLength(self.buffer, self.additionalInformation);
      self.buffer.cursor += len;
    } else if (
      self.majorType == MAJOR_TYPE_ARRAY
        || self.majorType == MAJOR_TYPE_MAP
    ) { 
      self.len = readLength(self.buffer, self.additionalInformation);      
    } else if (
       self.majorType != MAJOR_TYPE_CONTENT_FREE
        || (
          self.additionalInformation != 20
            && self.additionalInformation != 21
        )
    ) {
      revert("WitnetCBOR.skip: unsupported major type");
    }
    return self;
  }

  function peekLength(CBOR memory self)
    internal pure
    returns (uint64)
  {
    if (self.additionalInformation < 24) {
      return 0;
    } else if (self.additionalInformation < 28) {
      return uint64(1 << (self.additionalInformation - 24));
    } else {
      revert InvalidLengthEncoding(self.additionalInformation);
    }
  }

  function readArray(CBOR memory self)
    internal pure
    isMajorType(self, MAJOR_TYPE_ARRAY)
    returns (CBOR[] memory items)
  {
    // read array's length and move self cursor forward to the first array element:
    uint64 len = readLength(self.buffer, self.additionalInformation);
    items = new CBOR[](len + 1);
    for (uint ix = 0; ix < len; ix ++) {
      // settle next element in the array:
      self = self.settle();
      // fork it and added to the list of items to be returned:
      items[ix] = self.fork();
      if (self.majorType == MAJOR_TYPE_ARRAY) {
        CBOR[] memory _subitems = self.readArray();
        // move forward to the first element after inner array:
        self = _subitems[_subitems.length - 1];
      } else if (self.majorType == MAJOR_TYPE_MAP) {
        CBOR[] memory _subitems = self.readMap();
        // move forward to the first element after inner map:
        self = _subitems[_subitems.length - 1];
      } else {
        // move forward to the next element:
        self.skip();
      }
    }
    // return self cursor as extra item at the end of the list,
    // as to optimize recursion when jumping over nested arrays:
    items[len] = self;
  }

  function readMap(CBOR memory self)
    internal pure
    isMajorType(self, MAJOR_TYPE_MAP)
    returns (CBOR[] memory items)
  {
    // read number of items within the map and move self cursor forward to the first inner element:
    uint64 len = readLength(self.buffer, self.additionalInformation) * 2;
    items = new CBOR[](len + 1);
    for (uint ix = 0; ix < len; ix ++) {
      // settle next element in the array:
      self = self.settle();
      // fork it and added to the list of items to be returned:
      items[ix] = self.fork();
      if (ix % 2 == 0 && self.majorType != MAJOR_TYPE_STRING) {
        revert UnexpectedMajorType(self.majorType, MAJOR_TYPE_STRING);
      } else if (self.majorType == MAJOR_TYPE_ARRAY || self.majorType == MAJOR_TYPE_MAP) {
        CBOR[] memory _subitems = (self.majorType == MAJOR_TYPE_ARRAY
            ? self.readArray()
            : self.readMap()
        );
        // move forward to the first element after inner array or map:
        self = _subitems[_subitems.length - 1];
      } else {
        // move forward to the next element:
        self.skip();
      }
    }
    // return self cursor as extra item at the end of the list,
    // as to optimize recursion when jumping over nested arrays:
    items[len] = self;
  }

  /// Reads the length of the settle CBOR item from a buffer, consuming a different number of bytes depending on the
  /// value of the `additionalInformation` argument.
  function readLength(
      WitnetBuffer.Buffer memory buffer,
      uint8 additionalInformation
    ) 
    internal pure
    returns (uint64)
  {
    if (additionalInformation < 24) {
      return additionalInformation;
    }
    if (additionalInformation == 24) {
      return buffer.readUint8();
    }
    if (additionalInformation == 25) {
      return buffer.readUint16();
    }
    if (additionalInformation == 26) {
      return buffer.readUint32();
    }
    if (additionalInformation == 27) {
      return buffer.readUint64();
    }
    if (additionalInformation == 31) {
      return UINT64_MAX;
    }
    revert InvalidLengthEncoding(additionalInformation);
  }

  /// @notice Read a `CBOR` structure into a native `bool` value.
  /// @param cbor An instance of `CBOR`.
  /// @return The value represented by the input, as a `bool` value.
  function readBool(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_CONTENT_FREE)
    returns (bool)
  {
    if (cbor.additionalInformation == 20) {
      return false;
    } else if (cbor.additionalInformation == 21) {
      return true;
    } else {
      revert UnsupportedPrimitive(cbor.additionalInformation);
    }
  }

  /// @notice Decode a `CBOR` structure into a native `bytes` value.
  /// @param cbor An instance of `CBOR`.
  /// @return output The value represented by the input, as a `bytes` value.   
  function readBytes(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_BYTES)
    returns (bytes memory output)
  {
    cbor.len = readLength(
      cbor.buffer,
      cbor.additionalInformation
    );
    if (cbor.len == UINT32_MAX) {
      // These checks look repetitive but the equivalent loop would be more expensive.
      uint32 length = uint32(_readIndefiniteStringLength(
        cbor.buffer,
        cbor.majorType
      ));
      if (length < UINT32_MAX) {
        output = abi.encodePacked(cbor.buffer.read(length));
        length = uint32(_readIndefiniteStringLength(
          cbor.buffer,
          cbor.majorType
        ));
        if (length < UINT32_MAX) {
          output = abi.encodePacked(
            output,
            cbor.buffer.read(length)
          );
        }
      }
    } else {
      return cbor.buffer.read(uint32(cbor.len));
    }
  }

  /// @notice Decode a `CBOR` structure into a `fixed16` value.
  /// @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values
  /// by 5 decimal orders so as to get a fixed precision of 5 decimal positions, which should be OK for most `fixed16`
  /// use cases. In other words, the output of this method is 10,000 times the actual value, encoded into an `int32`.
  /// @param cbor An instance of `CBOR`.
  /// @return The value represented by the input, as an `int128` value.
  function readFloat16(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_CONTENT_FREE)
    returns (int32)
  {
    if (cbor.additionalInformation == 25) {
      return cbor.buffer.readFloat16();
    } else {
      revert UnsupportedPrimitive(cbor.additionalInformation);
    }
  }

  /// @notice Decode a `CBOR` structure into a `fixed32` value.
  /// @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values
  /// by 9 decimal orders so as to get a fixed precision of 9 decimal positions, which should be OK for most `fixed64`
  /// use cases. In other words, the output of this method is 10^9 times the actual value, encoded into an `int`.
  /// @param cbor An instance of `CBOR`.
  /// @return The value represented by the input, as an `int` value.
  function readFloat32(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_CONTENT_FREE)
    returns (int)
  {
    if (cbor.additionalInformation == 26) {
      return cbor.buffer.readFloat32();
    } else {
      revert UnsupportedPrimitive(cbor.additionalInformation);
    }
  }

  /// @notice Decode a `CBOR` structure into a `fixed64` value.
  /// @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values
  /// by 15 decimal orders so as to get a fixed precision of 15 decimal positions, which should be OK for most `fixed64`
  /// use cases. In other words, the output of this method is 10^15 times the actual value, encoded into an `int`.
  /// @param cbor An instance of `CBOR`.
  /// @return The value represented by the input, as an `int` value.
  function readFloat64(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_CONTENT_FREE)
    returns (int)
  {
    if (cbor.additionalInformation == 27) {
      return cbor.buffer.readFloat64();
    } else {
      revert UnsupportedPrimitive(cbor.additionalInformation);
    }
  }

  /// @notice Decode a `CBOR` structure into a native `int128[]` value whose inner values follow the same convention 
  /// @notice as explained in `decodeFixed16`.
  /// @param cbor An instance of `CBOR`.
  function readFloat16Array(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_ARRAY)
    returns (int32[] memory values)
  {
    uint64 length = readLength(cbor.buffer, cbor.additionalInformation);
    if (length < UINT64_MAX) {
      values = new int32[](length);
      for (uint64 i = 0; i < length; ) {
        CBOR memory item = fromBuffer(cbor.buffer);
        values[i] = readFloat16(item);
        unchecked {
          i ++;
        }
      }
    } else {
      revert InvalidLengthEncoding(length);
    }
  }

  /// @notice Decode a `CBOR` structure into a native `int128` value.
  /// @param cbor An instance of `CBOR`.
  /// @return The value represented by the input, as an `int128` value.
  function readInt(CBOR memory cbor)
    internal pure
    returns (int)
  {
    if (cbor.majorType == 1) {
      uint64 _value = readLength(
        cbor.buffer,
        cbor.additionalInformation
      );
      return int(-1) - int(uint(_value));
    } else if (cbor.majorType == 0) {
      // Any `uint64` can be safely casted to `int128`, so this method supports majorType 1 as well so as to have offer
      // a uniform API for positive and negative numbers
      return int(readUint(cbor));
    }
    else {
      revert UnexpectedMajorType(cbor.majorType, 1);
    }
  }

  /// @notice Decode a `CBOR` structure into a native `int[]` value.
  /// @param cbor instance of `CBOR`.
  /// @return array The value represented by the input, as an `int[]` value.
  function readIntArray(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_ARRAY)
    returns (int[] memory array)
  {
    uint64 length = readLength(cbor.buffer, cbor.additionalInformation);
    if (length < UINT64_MAX) {
      array = new int[](length);
      for (uint i = 0; i < length; ) {
        CBOR memory item = fromBuffer(cbor.buffer);
        array[i] = readInt(item);
        unchecked {
          i ++;
        }
      }
    } else {
      revert InvalidLengthEncoding(length);
    }
  }

  /// @notice Decode a `CBOR` structure into a native `string` value.
  /// @param cbor An instance of `CBOR`.
  /// @return text The value represented by the input, as a `string` value.
  function readString(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_STRING)
    returns (string memory text)
  {
    cbor.len = readLength(cbor.buffer, cbor.additionalInformation);
    if (cbor.len == UINT64_MAX) {
      bool _done;
      while (!_done) {
        uint64 length = _readIndefiniteStringLength(
          cbor.buffer,
          cbor.majorType
        );
        if (length < UINT64_MAX) {
          text = string(abi.encodePacked(
            text,
            cbor.buffer.readText(length / 4)
          ));
        } else {
          _done = true;
        }
      }
    } else {
      return string(cbor.buffer.readText(cbor.len));
    }
  }

  /// @notice Decode a `CBOR` structure into a native `string[]` value.
  /// @param cbor An instance of `CBOR`.
  /// @return strings The value represented by the input, as an `string[]` value.
  function readStringArray(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_ARRAY)
    returns (string[] memory strings)
  {
    uint length = readLength(cbor.buffer, cbor.additionalInformation);
    if (length < UINT64_MAX) {
      strings = new string[](length);
      for (uint i = 0; i < length; ) {
        CBOR memory item = fromBuffer(cbor.buffer);
        strings[i] = readString(item);
        unchecked {
          i ++;
        }
      }
    } else {
      revert InvalidLengthEncoding(length);
    }
  }

  /// @notice Decode a `CBOR` structure into a native `uint64` value.
  /// @param cbor An instance of `CBOR`.
  /// @return The value represented by the input, as an `uint64` value.
  function readUint(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_INT)
    returns (uint)
  {
    return readLength(
      cbor.buffer,
      cbor.additionalInformation
    );
  }

  /// @notice Decode a `CBOR` structure into a native `uint64[]` value.
  /// @param cbor An instance of `CBOR`.
  /// @return values The value represented by the input, as an `uint64[]` value.
  function readUintArray(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_ARRAY)
    returns (uint[] memory values)
  {
    uint64 length = readLength(cbor.buffer, cbor.additionalInformation);
    if (length < UINT64_MAX) {
      values = new uint[](length);
      for (uint ix = 0; ix < length; ) {
        CBOR memory item = fromBuffer(cbor.buffer);
        values[ix] = readUint(item);
        unchecked {
          ix ++;
        }
      }
    } else {
      revert InvalidLengthEncoding(length);
    }
  }  

  /// Read the length of a CBOR indifinite-length item (arrays, maps, byte strings and text) from a buffer, consuming
  /// as many bytes as specified by the first byte.
  function _readIndefiniteStringLength(
      WitnetBuffer.Buffer memory buffer,
      uint8 majorType
    )
    private pure
    returns (uint64 len)
  {
    uint8 initialByte = buffer.readUint8();
    if (initialByte == 0xff) {
      return UINT64_MAX;
    }
    len = readLength(
      buffer,
      initialByte & 0x1f
    );
    if (len >= UINT64_MAX) {
      revert InvalidLengthEncoding(len);
    } else if (majorType != (initialByte >> 5)) {
      revert UnexpectedMajorType((initialByte >> 5), majorType);
    }
  }
 
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/// @title A convenient wrapper around the `bytes memory` type that exposes a buffer-like interface
/// @notice The buffer has an inner cursor that tracks the final offset of every read, i.e. any subsequent read will
/// start with the byte that goes right after the last one in the previous read.
/// @dev `uint32` is used here for `cursor` because `uint16` would only enable seeking up to 8KB, which could in some
/// theoretical use cases be exceeded. Conversely, `uint32` supports up to 512MB, which cannot credibly be exceeded.
/// @author The Witnet Foundation.
library WitnetBuffer {

  error EmptyBuffer();
  error IndexOutOfBounds(uint index, uint range);
  error MissingArgs(uint expected, uint given);

  /// Iterable bytes buffer.
  struct Buffer {
      bytes data;
      uint cursor;
  }

  // Ensures we access an existing index in an array
  modifier withinRange(uint index, uint _range) {
    if (index > _range) {
      revert IndexOutOfBounds(index, _range);
    }
    _;
  }

  /// @notice Concatenate undefinite number of bytes chunks.
  /// @dev Faster than looping on `abi.encodePacked(output, _buffs[ix])`.
  function concat(bytes[] memory _buffs)
    internal pure
    returns (bytes memory output)
  {
    unchecked {
      uint destinationPointer;
      uint destinationLength;
      assembly {
        // get safe scratch location
        output := mload(0x40)
        // set starting destination pointer
        destinationPointer := add(output, 32)
      }      
      for (uint ix = 1; ix <= _buffs.length; ix ++) {  
        uint source;
        uint sourceLength;
        uint sourcePointer;        
        assembly {
          // load source length pointer
          source := mload(add(_buffs, mul(ix, 32)))
          // load source length
          sourceLength := mload(source)
          // sets source memory pointer
          sourcePointer := add(source, 32)
        }
        memcpy(
          destinationPointer,
          sourcePointer,
          sourceLength
        );
        assembly {          
          // increase total destination length
          destinationLength := add(destinationLength, sourceLength)
          // sets destination memory pointer
          destinationPointer := add(destinationPointer, sourceLength)
        }
      }
      assembly {
        // protect output bytes
        mstore(output, destinationLength)
        // set final output length
        mstore(0x40, add(mload(0x40), add(destinationLength, 32)))
      }
    }
  }

  function fork(WitnetBuffer.Buffer memory buffer)
    internal pure
    returns (WitnetBuffer.Buffer memory)
  {
    return Buffer(
      buffer.data,
      buffer.cursor
    );
  }

  function mutate(
      WitnetBuffer.Buffer memory buffer,
      uint length,
      bytes memory pokes
    )
    internal pure
    withinRange(length, buffer.data.length - buffer.cursor + 1)
  {
    bytes[] memory parts = new bytes[](3);
    parts[0] = peek(
      buffer,
      0,
      buffer.cursor
    );
    parts[1] = pokes;
    parts[2] = peek(
      buffer,
      buffer.cursor + length,
      buffer.data.length - buffer.cursor - length
    );
    buffer.data = concat(parts);
  }

  /// @notice Read and consume the next byte from the buffer.
  /// @param buffer An instance of `Buffer`.
  /// @return The next byte in the buffer counting from the cursor position.
  function next(Buffer memory buffer)
    internal pure
    withinRange(buffer.cursor, buffer.data.length)
    returns (bytes1)
  {
    // Return the byte at the position marked by the cursor and advance the cursor all at once
    return buffer.data[buffer.cursor ++];
  }

  function peek(
      WitnetBuffer.Buffer memory buffer,
      uint offset,
      uint length
    )
    internal pure
    withinRange(offset + length, buffer.data.length)
    returns (bytes memory)
  {
    bytes memory data = buffer.data;
    bytes memory peeks = new bytes(length);
    uint destinationPointer;
    uint sourcePointer;
    assembly {
      destinationPointer := add(peeks, 32)
      sourcePointer := add(add(data, 32), offset)
    }
    memcpy(
      destinationPointer,
      sourcePointer,
      length
    );
    return peeks;
  }

  // @notice Extract bytes array from buffer starting from current cursor.
  /// @param buffer An instance of `Buffer`.
  /// @param length How many bytes to peek from the Buffer.
  // solium-disable-next-line security/no-assign-params
  function peek(
      WitnetBuffer.Buffer memory buffer,
      uint length
    )
    internal pure
    withinRange(length, buffer.data.length - buffer.cursor)
    returns (bytes memory)
  {
    return peek(
      buffer,
      buffer.cursor,
      length
    );
  }

  /// @notice Read and consume a certain amount of bytes from the buffer.
  /// @param buffer An instance of `Buffer`.
  /// @param length How many bytes to read and consume from the buffer.
  /// @return output A `bytes memory` containing the first `length` bytes from the buffer, counting from the cursor position.
  function read(Buffer memory buffer, uint length)
    internal pure
    withinRange(buffer.cursor + length, buffer.data.length)
    returns (bytes memory output)
  {
    // Create a new `bytes memory destination` value
    output = new bytes(length);
    // Early return in case that bytes length is 0
    if (length > 0) {
      bytes memory input = buffer.data;
      uint offset = buffer.cursor;
      // Get raw pointers for source and destination
      uint sourcePointer;
      uint destinationPointer;
      assembly {
        sourcePointer := add(add(input, 32), offset)
        destinationPointer := add(output, 32)
      }
      // Copy `length` bytes from source to destination
      memcpy(
        destinationPointer,
        sourcePointer,
        length
      );
      // Move the cursor forward by `length` bytes
      seek(
        buffer,
        length,
        true
      );
    }
  }
  
  /// @notice Read and consume the next 2 bytes from the buffer as an IEEE 754-2008 floating point number enclosed in an
  /// `int32`.
  /// @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values
  /// by 5 decimal orders so as to get a fixed precision of 5 decimal positions, which should be OK for most `float16`
  /// use cases. In other words, the integer output of this method is 10,000 times the actual value. The input bytes are
  /// expected to follow the 16-bit base-2 format (a.k.a. `binary16`) in the IEEE 754-2008 standard.
  /// @param buffer An instance of `Buffer`.
  /// @return result The `int32` value of the next 4 bytes in the buffer counting from the cursor position.
  function readFloat16(Buffer memory buffer)
    internal pure
    returns (int32 result)
  {
    uint32 value = readUint16(buffer);
    // Get bit at position 0
    uint32 sign = value & 0x8000;
    // Get bits 1 to 5, then normalize to the [-15, 16] range so as to counterweight the IEEE 754 exponent bias
    int32 exponent = (int32(value & 0x7c00) >> 10) - 15;
    // Get bits 6 to 15
    int32 fraction = int32(value & 0x03ff);
    // Add 2^10 to the fraction if exponent is not -15
    if (exponent != -15) {
      fraction |= 0x400;
    } else if (exponent == 16) {
      revert(
        string(abi.encodePacked(
          "WitnetBuffer.readFloat16: ",
          sign != 0 ? "negative" : hex"",
          " infinity"
        ))
      );
    }
    // Compute `2 ^ exponent · (1 + fraction / 1024)`
    if (exponent >= 0) {
      result = int32(int(
        int(1 << uint256(int256(exponent)))
          * 10000
          * fraction
      ) >> 10);
    } else {
      result = int32(int(
        int(fraction)
          * 10000
          / int(1 << uint(int(- exponent)))
      ) >> 10);
    }
    // Make the result negative if the sign bit is not 0
    if (sign != 0) {
      result *= -1;
    }
  }

  /// @notice Consume the next 4 bytes from the buffer as an IEEE 754-2008 floating point number enclosed into an `int`.
  /// @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values
  /// by 9 decimal orders so as to get a fixed precision of 9 decimal positions, which should be OK for most `float32`
  /// use cases. In other words, the integer output of this method is 10^9 times the actual value. The input bytes are
  /// expected to follow the 64-bit base-2 format (a.k.a. `binary32`) in the IEEE 754-2008 standard.
  /// @param buffer An instance of `Buffer`.
  /// @return result The `int` value of the next 8 bytes in the buffer counting from the cursor position.
  function readFloat32(Buffer memory buffer)
    internal pure
    returns (int result)
  {
    uint value = readUint32(buffer);
    // Get bit at position 0
    uint sign = value & 0x80000000;
    // Get bits 1 to 8, then normalize to the [-127, 128] range so as to counterweight the IEEE 754 exponent bias
    int exponent = (int(value & 0x7f800000) >> 23) - 127;
    // Get bits 9 to 31
    int fraction = int(value & 0x007fffff);
    // Add 2^23 to the fraction if exponent is not -127
    if (exponent != -127) {
      fraction |= 0x800000;
    } else if (exponent == 128) {
      revert(
        string(abi.encodePacked(
          "WitnetBuffer.readFloat32: ",
          sign != 0 ? "negative" : hex"",
          " infinity"
        ))
      );
    }
    // Compute `2 ^ exponent · (1 + fraction / 2^23)`
    if (exponent >= 0) {
      result = (
        int(1 << uint(exponent))
          * (10 ** 9)
          * fraction
      ) >> 23;
    } else {
      result = (
        fraction 
          * (10 ** 9)
          / int(1 << uint(-exponent)) 
      ) >> 23;
    }
    // Make the result negative if the sign bit is not 0
    if (sign != 0) {
      result *= -1;
    }
  }

  /// @notice Consume the next 8 bytes from the buffer as an IEEE 754-2008 floating point number enclosed into an `int`.
  /// @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values
  /// by 15 decimal orders so as to get a fixed precision of 15 decimal positions, which should be OK for most `float64`
  /// use cases. In other words, the integer output of this method is 10^15 times the actual value. The input bytes are
  /// expected to follow the 64-bit base-2 format (a.k.a. `binary64`) in the IEEE 754-2008 standard.
  /// @param buffer An instance of `Buffer`.
  /// @return result The `int` value of the next 8 bytes in the buffer counting from the cursor position.
  function readFloat64(Buffer memory buffer)
    internal pure
    returns (int result)
  {
    uint value = readUint64(buffer);
    // Get bit at position 0
    uint sign = value & 0x8000000000000000;
    // Get bits 1 to 12, then normalize to the [-1023, 1024] range so as to counterweight the IEEE 754 exponent bias
    int exponent = (int(value & 0x7ff0000000000000) >> 52) - 1023;
    // Get bits 6 to 15
    int fraction = int(value & 0x000fffffffffffff);
    // Add 2^52 to the fraction if exponent is not -1023
    if (exponent != -1023) {
      fraction |= 0x10000000000000;
    } else if (exponent == 1024) {
      revert(
        string(abi.encodePacked(
          "WitnetBuffer.readFloat64: ",
          sign != 0 ? "negative" : hex"",
          " infinity"
        ))
      );
    }
    // Compute `2 ^ exponent · (1 + fraction / 1024)`
    if (exponent >= 0) {
      result = (
        int(1 << uint(exponent))
          * (10 ** 15)
          * fraction
      ) >> 52;
    } else {
      result = (
        fraction 
          * (10 ** 15)
          / int(1 << uint(-exponent)) 
      ) >> 52;
    }
    // Make the result negative if the sign bit is not 0
    if (sign != 0) {
      result *= -1;
    }
  }

  // Read a text string of a given length from a buffer. Returns a `bytes memory` value for the sake of genericness,
  /// but it can be easily casted into a string with `string(result)`.
  // solium-disable-next-line security/no-assign-params
  function readText(
      WitnetBuffer.Buffer memory buffer,
      uint64 length
    )
    internal pure
    returns (bytes memory text)
  {
    text = new bytes(length);
    unchecked {
      for (uint64 index = 0; index < length; index ++) {
        uint8 char = readUint8(buffer);
        if (char & 0x80 != 0) {
          if (char < 0xe0) {
            char = (char & 0x1f) << 6
              | (readUint8(buffer) & 0x3f);
            length -= 1;
          } else if (char < 0xf0) {
            char  = (char & 0x0f) << 12
              | (readUint8(buffer) & 0x3f) << 6
              | (readUint8(buffer) & 0x3f);
            length -= 2;
          } else {
            char = (char & 0x0f) << 18
              | (readUint8(buffer) & 0x3f) << 12
              | (readUint8(buffer) & 0x3f) << 6  
              | (readUint8(buffer) & 0x3f);
            length -= 3;
          }
        }
        text[index] = bytes1(char);
      }
      // Adjust text to actual length:
      assembly {
        mstore(text, length)
      }
    }
  }

  /// @notice Read and consume the next byte from the buffer as an `uint8`.
  /// @param buffer An instance of `Buffer`.
  /// @return value The `uint8` value of the next byte in the buffer counting from the cursor position.
  function readUint8(Buffer memory buffer)
    internal pure
    withinRange(buffer.cursor, buffer.data.length)
    returns (uint8 value)
  {
    bytes memory data = buffer.data;
    uint offset = buffer.cursor;
    assembly {
      value := mload(add(add(data, 1), offset))
    }
    buffer.cursor ++;
  }

  /// @notice Read and consume the next 2 bytes from the buffer as an `uint16`.
  /// @param buffer An instance of `Buffer`.
  /// @return value The `uint16` value of the next 2 bytes in the buffer counting from the cursor position.
  function readUint16(Buffer memory buffer)
    internal pure
    withinRange(buffer.cursor + 2, buffer.data.length)
    returns (uint16 value)
  {
    bytes memory data = buffer.data;
    uint offset = buffer.cursor;
    assembly {
      value := mload(add(add(data, 2), offset))
    }
    buffer.cursor += 2;
  }

  /// @notice Read and consume the next 4 bytes from the buffer as an `uint32`.
  /// @param buffer An instance of `Buffer`.
  /// @return value The `uint32` value of the next 4 bytes in the buffer counting from the cursor position.
  function readUint32(Buffer memory buffer)
    internal pure
    withinRange(buffer.cursor + 4, buffer.data.length)
    returns (uint32 value)
  {
    bytes memory data = buffer.data;
    uint offset = buffer.cursor;
    assembly {
      value := mload(add(add(data, 4), offset))
    }
    buffer.cursor += 4;
  }

  /// @notice Read and consume the next 8 bytes from the buffer as an `uint64`.
  /// @param buffer An instance of `Buffer`.
  /// @return value The `uint64` value of the next 8 bytes in the buffer counting from the cursor position.
  function readUint64(Buffer memory buffer)
    internal pure
    withinRange(buffer.cursor + 8, buffer.data.length)
    returns (uint64 value)
  {
    bytes memory data = buffer.data;
    uint offset = buffer.cursor;
    assembly {
      value := mload(add(add(data, 8), offset))
    }
    buffer.cursor += 8;
  }

  /// @notice Read and consume the next 16 bytes from the buffer as an `uint128`.
  /// @param buffer An instance of `Buffer`.
  /// @return value The `uint128` value of the next 16 bytes in the buffer counting from the cursor position.
  function readUint128(Buffer memory buffer)
    internal pure
    withinRange(buffer.cursor + 16, buffer.data.length)
    returns (uint128 value)
  {
    bytes memory data = buffer.data;
    uint offset = buffer.cursor;
    assembly {
      value := mload(add(add(data, 16), offset))
    }
    buffer.cursor += 16;
  }

  /// @notice Read and consume the next 32 bytes from the buffer as an `uint256`.
  /// @param buffer An instance of `Buffer`.
  /// @return value The `uint256` value of the next 32 bytes in the buffer counting from the cursor position.
  function readUint256(Buffer memory buffer)
    internal pure
    withinRange(buffer.cursor + 32, buffer.data.length)
    returns (uint256 value)
  {
    bytes memory data = buffer.data;
    uint offset = buffer.cursor;
    assembly {
      value := mload(add(add(data, 32), offset))
    }
    buffer.cursor += 32;
  }

  /// @notice Count number of required parameters for given bytes arrays
  /// @dev Wildcard format: "\#\", with # in ["0".."9"].
  /// @param input Bytes array containing strings.
  /// @param count Highest wildcard index found, plus 1.
  function argsCountOf(bytes memory input)
    internal pure
    returns (uint8 count)
  {
    if (input.length < 3) {
      return 0;
    }
    unchecked {
      uint ix = 0; 
      uint length = input.length - 2;
      for (; ix < length; ) {
        if (
          input[ix] == bytes1("\\")
            && input[ix + 2] == bytes1("\\")
            && input[ix + 1] >= bytes1("0")
            && input[ix + 1] <= bytes1("9")
        ) {
          uint8 ax = uint8(uint8(input[ix + 1]) - uint8(bytes1("0")) + 1);
          if (ax > count) {
            count = ax;
          }
          ix += 3;
        } else {
          ix ++;
        }
      }
    }
  }

  /// @notice Replace bytecode indexed wildcards by correspondent substrings.
  /// @dev Wildcard format: "\#\", with # in ["0".."9"].
  /// @param input Bytes array containing strings.
  /// @param args Array of substring values for replacing indexed wildcards.
  /// @return output Resulting bytes array after replacing all wildcards.
  /// @return hits Total number of replaced wildcards.
  function replace(bytes memory input, string[] memory args)
    internal pure
    returns (bytes memory output, uint hits)
  {
    uint ix = 0; uint lix = 0;
    uint inputLength;
    uint inputPointer;
    uint outputLength;
    uint outputPointer;    
    uint source;
    uint sourceLength;
    uint sourcePointer;

    if (input.length < 3) {
      return (input, 0);
    }
    
    assembly {
      // set starting input pointer
      inputPointer := add(input, 32)
      // get safe output location
      output := mload(0x40)
      // set starting output pointer
      outputPointer := add(output, 32)
    }         

    unchecked {
      uint length = input.length - 2;
      for (; ix < length; ) {
        if (
          input[ix] == bytes1("\\")
            && input[ix + 2] == bytes1("\\")
            && input[ix + 1] >= bytes1("0")
            && input[ix + 1] <= bytes1("9")
        ) {
          inputLength = (ix - lix);
          if (ix > lix) {
            memcpy(
              outputPointer,
              inputPointer,
              inputLength
            );
            inputPointer += inputLength + 3;
            outputPointer += inputLength;
          } else {
            inputPointer += 3;
          }
          uint ax = uint(uint8(input[ix + 1]) - uint8(bytes1("0")));
          if (ax >= args.length) {
            revert MissingArgs(ax + 1, args.length);
          }
          assembly {
            source := mload(add(args, mul(32, add(ax, 1))))
            sourceLength := mload(source)
            sourcePointer := add(source, 32)      
          }        
          memcpy(
            outputPointer,
            sourcePointer,
            sourceLength
          );
          outputLength += inputLength + sourceLength;
          outputPointer += sourceLength;
          ix += 3;
          lix = ix;
          hits ++;
        } else {
          ix ++;
        }
      }
      ix = input.length;    
    }
    if (outputLength > 0) {
      if (ix > lix ) {
        memcpy(
          outputPointer,
          inputPointer,
          ix - lix
        );
        outputLength += (ix - lix);
      }
      assembly {
        // set final output length
        mstore(output, outputLength)
        // protect output bytes
        mstore(0x40, add(mload(0x40), add(outputLength, 32)))
      }
    }
    else {
      return (input, 0);
    }
  }

  /// @notice Replace string indexed wildcards by correspondent substrings.
  /// @dev Wildcard format: "\#\", with # in ["0".."9"].
  /// @param input String potentially containing wildcards.
  /// @param args Array of substring values for replacing indexed wildcards.
  /// @return output Resulting string after replacing all wildcards.
  function replace(string memory input, string[] memory args)
    internal pure
    returns (string memory)
  {
    (bytes memory _outputBytes, ) = replace(bytes(input), args);
    return string(_outputBytes);
  }

  /// @notice Move the inner cursor of the buffer to a relative or absolute position.
  /// @param buffer An instance of `Buffer`.
  /// @param offset How many bytes to move the cursor forward.
  /// @param relative Whether to count `offset` from the last position of the cursor (`true`) or the beginning of the
  /// buffer (`true`).
  /// @return The final position of the cursor (will equal `offset` if `relative` is `false`).
  // solium-disable-next-line security/no-assign-params
  function seek(
      Buffer memory buffer,
      uint offset,
      bool relative
    )
    internal pure
    withinRange(offset, buffer.data.length)
    returns (uint)
  {
    // Deal with relative offsets
    if (relative) {
      offset += buffer.cursor;
    }
    buffer.cursor = offset;
    return offset;
  }

  /// @notice Move the inner cursor a number of bytes forward.
  /// @dev This is a simple wrapper around the relative offset case of `seek()`.
  /// @param buffer An instance of `Buffer`.
  /// @param relativeOffset How many bytes to move the cursor forward.
  /// @return The final position of the cursor.
  function seek(
      Buffer memory buffer,
      uint relativeOffset
    )
    internal pure
    returns (uint)
  {
    return seek(
      buffer,
      relativeOffset,
      true
    );
  }

  /// @notice Copy bytes from one memory address into another.
  /// @dev This function was borrowed from Nick Johnson's `solidity-stringutils` lib, and reproduced here under the terms
  /// of [Apache License 2.0](https://github.com/Arachnid/solidity-stringutils/blob/master/LICENSE).
  /// @param dest Address of the destination memory.
  /// @param src Address to the source memory.
  /// @param len How many bytes to copy.
  // solium-disable-next-line security/no-assign-params
  function memcpy(
      uint dest,
      uint src,
      uint len
    )
    private pure
  {
    unchecked {
      // Copy word-length chunks while possible
      for (; len >= 32; len -= 32) {
        assembly {
          mstore(dest, mload(src))
        }
        dest += 32;
        src += 32;
      }
      if (len > 0) {
        // Copy remaining bytes
        uint _mask = 256 ** (32 - len) - 1;
        assembly {
          let srcpart := and(mload(src), not(_mask))
          let destpart := and(mload(dest), _mask)
          mstore(dest, or(destpart, srcpart))
        }
      }
    }
  }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./WitnetCBOR.sol";

library Witnet {

    using WitnetBuffer for WitnetBuffer.Buffer;
    using WitnetCBOR for WitnetCBOR.CBOR;
    using WitnetCBOR for WitnetCBOR.CBOR[];

    /// Struct containing both request and response data related to every query posted to the Witnet Request Board
    struct Query {
        Request request;
        Response response;
        address from;      // Address from which the request was posted.
    }

    /// Possible status of a Witnet query.
    enum QueryStatus {
        Unknown,
        Posted,
        Reported,
        Deleted
    }

    /// Data kept in EVM-storage for every Request posted to the Witnet Request Board.
    struct Request {
        address addr;       // Address of the (deprecated) IWitnetRequest contract containing Witnet data request raw bytecode.
        bytes32 slaHash;    // Radon SLA hash of the Witnet data request.
        bytes32 radHash;    // Radon radHash of the Witnet data request.
        uint256 gasprice;   // Minimum gas price the DR resolver should pay on the solving tx.
        uint256 reward;     // Escrowed reward to be paid to the DR resolver.
    }

    /// Data kept in EVM-storage containing the Witnet-provided response metadata and CBOR-encoded result.
    struct Response {
        address reporter;       // Address from which the result was reported.
        uint256 timestamp;      // Timestamp of the Witnet-provided result.
        bytes32 drTxHash;       // Hash of the Witnet transaction that solved the queried Data Request.
        bytes   cborBytes;      // Witnet-provided result CBOR-bytes to the queried Data Request.
    }

    /// Data struct containing the Witnet-provided result to a Data Request.
    struct Result {
        bool success;           // Flag stating whether the request could get solved successfully, or not.
        WitnetCBOR.CBOR value;  // Resulting value, in CBOR-serialized bytes.
    }

    /// Final query's result status from a requester's point of view.
    enum ResultStatus {
        Void,
        Awaiting,
        Ready,
        Error
    }

    /// Data struct describing an error when trying to fetch a Witnet-provided result to a Data Request.
    struct ResultError {
        ResultErrorCodes code;
        string reason;
    }

    enum ResultErrorCodes {
        /// 0x00: Unknown error. Something went really bad!
        Unknown, 
        
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Source-specific format error sub-codes ============================================================================
        /// 0x01: At least one of the source scripts is not a valid CBOR-encoded value.
        SourceScriptNotCBOR, 
        /// 0x02: The CBOR value decoded from a source script is not an Array.
        SourceScriptNotArray,
        /// 0x03: The Array value decoded form a source script is not a valid Data Request.
        SourceScriptNotRADON,
        /// 0x04: The request body of at least one data source was not properly formated.
        SourceRequestBody,
        /// 0x05: The request headers of at least one data source was not properly formated.
        SourceRequestHeaders,
        /// 0x06: The request URL of at least one data source was not properly formated.
        SourceRequestURL,
        /// Unallocated
        SourceFormat0x07, SourceFormat0x08, SourceFormat0x09, SourceFormat0x0A, SourceFormat0x0B, SourceFormat0x0C,
        SourceFormat0x0D, SourceFormat0x0E, SourceFormat0x0F, 
        
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Complexity error sub-codes ========================================================================================
        /// 0x10: The request contains too many sources.
        RequestTooManySources,
        /// 0x11: The script contains too many calls.
        ScriptTooManyCalls,
        /// Unallocated
        Complexity0x12, Complexity0x13, Complexity0x14, Complexity0x15, Complexity0x16, Complexity0x17, Complexity0x18,
        Complexity0x19, Complexity0x1A, Complexity0x1B, Complexity0x1C, Complexity0x1D, Complexity0x1E, Complexity0x1F,

        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Lack of support error sub-codes ===================================================================================
        /// 0x20: Some Radon operator code was found that is not supported (1+ args).
        UnsupportedOperator,
        /// 0x21: Some Radon filter opcode is not currently supported (1+ args).
        UnsupportedFilter,
        /// 0x22: Some Radon request type is not currently supported (1+ args).
        UnsupportedHashFunction,
        /// 0x23: Some Radon reducer opcode is not currently supported (1+ args)
        UnsupportedReducer,
        /// 0x24: Some Radon hash function is not currently supported (1+ args).
        UnsupportedRequestType, 
        /// 0x25: Some Radon encoding function is not currently supported (1+ args).
        UnsupportedEncodingFunction,
        /// Unallocated
        Operator0x26, Operator0x27, 
        /// 0x28: Wrong number (or type) of arguments were passed to some Radon operator.
        WrongArguments,
        /// Unallocated
        Operator0x29, Operator0x2A, Operator0x2B, Operator0x2C, Operator0x2D, Operator0x2E, Operator0x2F,
        
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Retrieve-specific circumstantial error sub-codes ================================================================================
        /// 0x30: A majority of data sources returned an HTTP status code other than 200 (1+ args):
        HttpErrors,
        /// 0x31: A majority of data sources timed out:
        RetrievalsTimeout,
        /// Unallocated
        RetrieveCircumstance0x32, RetrieveCircumstance0x33, RetrieveCircumstance0x34, RetrieveCircumstance0x35,
        RetrieveCircumstance0x36, RetrieveCircumstance0x37, RetrieveCircumstance0x38, RetrieveCircumstance0x39,
        RetrieveCircumstance0x3A, RetrieveCircumstance0x3B, RetrieveCircumstance0x3C, RetrieveCircumstance0x3D,
        RetrieveCircumstance0x3E, RetrieveCircumstance0x3F,
        
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Scripting-specific runtime error sub-code =========================================================================
        /// 0x40: Math operator caused an underflow.
        MathUnderflow,
        /// 0x41: Math operator caused an overflow.
        MathOverflow,
        /// 0x42: Math operator tried to divide by zero.
        MathDivisionByZero,            
        /// 0x43:Wrong input to subscript call.
        WrongSubscriptInput,
        /// 0x44: Value cannot be extracted from input binary buffer.
        BufferIsNotValue,
        /// 0x45: Value cannot be decoded from expected type.
        Decode,
        /// 0x46: Unexpected empty array.
        EmptyArray,
        /// 0x47: Value cannot be encoded to expected type.
        Encode,
        /// 0x48: Failed to filter input values (1+ args).
        Filter,
        /// 0x49: Failed to hash input value.
        Hash,
        /// 0x4A: Mismatching array ranks.
        MismatchingArrays,
        /// 0x4B: Failed to process non-homogenous array.
        NonHomegeneousArray,
        /// 0x4C: Failed to parse syntax of some input value, or argument.
        Parse,
        /// 0x4E: Parsing logic limits were exceeded.
        ParseOverflow,
        /// 0x4F: Unallocated
        ScriptError0x4F,
    
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Actual first-order result error codes =============================================================================
        /// 0x50: Not enough reveals were received in due time:
        InsufficientReveals,
        /// 0x51: No actual reveal majority was reached on tally stage:
        InsufficientMajority,
        /// 0x52: Not enough commits were received before tally stage:
        InsufficientCommits,
        /// 0x53: Generic error during tally execution (to be deprecated after WIP #0028)
        TallyExecution,
        /// 0x54: A majority of data sources could either be temporarily unresponsive or failing to report the requested data:
        CircumstantialFailure,
        /// 0x55: At least one data source is inconsistent when queried through multiple transports at once:
        InconsistentSources,
        /// 0x56: Any one of the (multiple) Retrieve, Aggregate or Tally scripts were badly formated:
        MalformedDataRequest,
        /// 0x57: Values returned from a majority of data sources don't match the expected schema:
        MalformedResponses,
        /// Unallocated:    
        OtherError0x58, OtherError0x59, OtherError0x5A, OtherError0x5B, OtherError0x5C, OtherError0x5D, OtherError0x5E, 
        /// 0x5F: Size of serialized tally result exceeds allowance:
        OversizedTallyResult,

        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Inter-stage runtime error sub-codes ===============================================================================
        /// 0x60: Data aggregation reveals could not get decoded on the tally stage:
        MalformedReveals,
        /// 0x61: The result to data aggregation could not get encoded:
        EncodeReveals,  
        /// 0x62: A mode tie ocurred when calculating some mode value on the aggregation or the tally stage:
        ModeTie, 
        /// Unallocated:
        OtherError0x63, OtherError0x64, OtherError0x65, OtherError0x66, OtherError0x67, OtherError0x68, OtherError0x69, 
        OtherError0x6A, OtherError0x6B, OtherError0x6C, OtherError0x6D, OtherError0x6E, OtherError0x6F,
        
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Runtime access error sub-codes ====================================================================================
        /// 0x70: Tried to access a value from an array using an index that is out of bounds (1+ args):
        ArrayIndexOutOfBounds,
        /// 0x71: Tried to access a value from a map using a key that does not exist (1+ args):
        MapKeyNotFound,
        /// 0X72: Tried to extract value from a map using a JSON Path that returns no values (+1 args):
        JsonPathNotFound,
        /// Unallocated:
        OtherError0x73, OtherError0x74, OtherError0x75, OtherError0x76, OtherError0x77, OtherError0x78, 
        OtherError0x79, OtherError0x7A, OtherError0x7B, OtherError0x7C, OtherError0x7D, OtherError0x7E, OtherError0x7F, 
        OtherError0x80, OtherError0x81, OtherError0x82, OtherError0x83, OtherError0x84, OtherError0x85, OtherError0x86, 
        OtherError0x87, OtherError0x88, OtherError0x89, OtherError0x8A, OtherError0x8B, OtherError0x8C, OtherError0x8D, 
        OtherError0x8E, OtherError0x8F, OtherError0x90, OtherError0x91, OtherError0x92, OtherError0x93, OtherError0x94, 
        OtherError0x95, OtherError0x96, OtherError0x97, OtherError0x98, OtherError0x99, OtherError0x9A, OtherError0x9B,
        OtherError0x9C, OtherError0x9D, OtherError0x9E, OtherError0x9F, OtherError0xA0, OtherError0xA1, OtherError0xA2, 
        OtherError0xA3, OtherError0xA4, OtherError0xA5, OtherError0xA6, OtherError0xA7, OtherError0xA8, OtherError0xA9, 
        OtherError0xAA, OtherError0xAB, OtherError0xAC, OtherError0xAD, OtherError0xAE, OtherError0xAF, OtherError0xB0,
        OtherError0xB1, OtherError0xB2, OtherError0xB3, OtherError0xB4, OtherError0xB5, OtherError0xB6, OtherError0xB7,
        OtherError0xB8, OtherError0xB9, OtherError0xBA, OtherError0xBB, OtherError0xBC, OtherError0xBD, OtherError0xBE,
        OtherError0xBF, OtherError0xC0, OtherError0xC1, OtherError0xC2, OtherError0xC3, OtherError0xC4, OtherError0xC5,
        OtherError0xC6, OtherError0xC7, OtherError0xC8, OtherError0xC9, OtherError0xCA, OtherError0xCB, OtherError0xCC,
        OtherError0xCD, OtherError0xCE, OtherError0xCF, OtherError0xD0, OtherError0xD1, OtherError0xD2, OtherError0xD3,
        OtherError0xD4, OtherError0xD5, OtherError0xD6, OtherError0xD7, OtherError0xD8, OtherError0xD9, OtherError0xDA,
        OtherError0xDB, OtherError0xDC, OtherError0xDD, OtherError0xDE, OtherError0xDF,
        
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Inter-client generic error codes ==================================================================================
        /// Data requests that cannot be relayed into the Witnet blockchain should be reported
        /// with one of these errors. 
        /// 0xE0: Requests that cannot be parsed must always get this error as their result.
        BridgeMalformedDataRequest,
        /// 0xE1: Witnesses exceeds 100
        BridgePoorIncentives,
        /// 0xE2: The request is rejected on the grounds that it may cause the submitter to spend or stake an
        /// amount of value that is unjustifiably high when compared with the reward they will be getting
        BridgeOversizedTallyResult,
        
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Unallocated =======================================================================================================
        OtherError0xE3, OtherError0xE4, OtherError0xE5, OtherError0xE6, OtherError0xE7, OtherError0xE8, OtherError0xE9,
        OtherError0xEA, OtherError0xEB, OtherError0xEC, OtherError0xED, OtherError0xEE, OtherError0xEF, OtherError0xF0,
        OtherError0xF1, OtherError0xF2, OtherError0xF3, OtherError0xF4, OtherError0xF5, OtherError0xF6, OtherError0xF7,
        OtherError0xF8, OtherError0xF9, OtherError0xFA, OtherError0xFB, OtherError0xFC, OtherError0xFD, OtherError0xFE,
        
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// 0xFF: Some tally error is not intercepted but it should (0+ args)
        UnhandledIntercept
    }

    function isCircumstantial(ResultErrorCodes self) internal pure returns (bool) {
        return (self == ResultErrorCodes.CircumstantialFailure);
    }

    function lackOfConsensus(ResultErrorCodes self) internal pure returns (bool) {
        return (
            self == ResultErrorCodes.InsufficientCommits
                || self == ResultErrorCodes.InsufficientMajority
                || self == ResultErrorCodes.InsufficientReveals
        );
    }

    function isRetriable(ResultErrorCodes self) internal pure returns (bool) {
        return (
            lackOfConsensus(self)
                || isCircumstantial(self)
                || poorIncentives(self)
        );
    }

    function poorIncentives(ResultErrorCodes self) internal pure returns (bool) {
        return (
            self == ResultErrorCodes.OversizedTallyResult
                || self == ResultErrorCodes.InsufficientCommits
                || self == ResultErrorCodes.BridgePoorIncentives
                || self == ResultErrorCodes.BridgeOversizedTallyResult
        );
    }
    

    /// Possible Radon data request methods that can be used within a Radon Retrieval. 
    enum RadonDataRequestMethods {
        /* 0 */ Unknown,
        /* 1 */ HttpGet,
        /* 2 */ RNG,
        /* 3 */ HttpPost,
        /* 4 */ HttpHead
    }

    /// Possible types either processed by Witnet Radon Scripts or included within results to Witnet Data Requests.
    enum RadonDataTypes {
        /* 0x00 */ Any, 
        /* 0x01 */ Array,
        /* 0x02 */ Bool,
        /* 0x03 */ Bytes,
        /* 0x04 */ Integer,
        /* 0x05 */ Float,
        /* 0x06 */ Map,
        /* 0x07 */ String,
        Unused0x08, Unused0x09, Unused0x0A, Unused0x0B,
        Unused0x0C, Unused0x0D, Unused0x0E, Unused0x0F,
        /* 0x10 */ Same,
        /* 0x11 */ Inner,
        /* 0x12 */ Match,
        /* 0x13 */ Subscript
    }

    /// Structure defining some data filtering that can be applied at the Aggregation or the Tally stages
    /// within a Witnet Data Request resolution workflow.
    struct RadonFilter {
        RadonFilterOpcodes opcode;
        bytes args;
    }

    /// Filtering methods currently supported on the Witnet blockchain. 
    enum RadonFilterOpcodes {
        /* 0x00 */ Reserved0x00, //GreaterThan,
        /* 0x01 */ Reserved0x01, //LessThan,
        /* 0x02 */ Reserved0x02, //Equals,
        /* 0x03 */ Reserved0x03, //AbsoluteDeviation,
        /* 0x04 */ Reserved0x04, //RelativeDeviation
        /* 0x05 */ StandardDeviation,
        /* 0x06 */ Reserved0x06, //Top,
        /* 0x07 */ Reserved0x07, //Bottom,
        /* 0x08 */ Mode,
        /* 0x09 */ Reserved0x09  //LessOrEqualThan
    }

    /// Structure defining the array of filters and reducting function to be applied at either the Aggregation
    /// or the Tally stages within a Witnet Data Request resolution workflow.
    struct RadonReducer {
        RadonReducerOpcodes opcode;
        RadonFilter[] filters;
        bytes script;
    }

    /// Reducting functions currently supported on the Witnet blockchain.
    enum RadonReducerOpcodes {
        /* 0x00 */ Reserved0x00, //Minimum,
        /* 0x01 */ Reserved0x01, //Maximum,
        /* 0x02 */ Mode,
        /* 0x03 */ AverageMean,
        /* 0x04 */ Reserved0x04, //AverageMeanWeighted,
        /* 0x05 */ AverageMedian,
        /* 0x06 */ Reserved0x06, //AverageMedianWeighted,
        /* 0x07 */ StandardDeviation,
        /* 0x08 */ Reserved0x08, //AverageDeviation,
        /* 0x09 */ Reserved0x09, //MedianDeviation,
        /* 0x0A */ Reserved0x10, //MaximumDeviation,
        /* 0x0B */ ConcatenateAndHash
    }

    /// Structure containing all the parameters that fully describe a Witnet Radon Retrieval within a Witnet Data Request.
    struct RadonRetrieval {
        uint8 argsCount;
        RadonDataRequestMethods method;
        RadonDataTypes resultDataType;
        string url;
        string body;
        string[2][] headers;
        bytes script;
    }

    /// Structure containing the Retrieve-Attestation-Delivery parts of a Witnet Data Request.
    struct RadonRAD {
        RadonRetrieval[] retrieve;
        RadonReducer aggregate;
        RadonReducer tally;
    }

    /// Structure containing the Service Level Aggreement parameters of a Witnet Data Request.
    struct RadonSLA {
        uint8 numWitnesses;
        uint8 minConsensusPercentage;
        uint64 witnessReward;
        uint64 witnessCollateral;
        uint64 minerCommitRevealFee;
    }


    /// ===============================================================================================================
    /// --- 'Witnet.RadonSLA' helper methods ------------------------------------------------------------------------

    function equalOrGreaterThan(RadonSLA memory a, RadonSLA memory b) 
        internal pure returns (bool)
    {
        return (
            a.numWitnesses >= b.numWitnesses
                && a.minConsensusPercentage >= b.minConsensusPercentage
                && a.witnessReward >= b.witnessReward
                && a.witnessCollateral >= b.witnessCollateral
                && a.minerCommitRevealFee >= b.minerCommitRevealFee
        );
    }
    
    function isValid(RadonSLA calldata sla) internal pure returns (bool) {
        return (
            sla.numWitnesses > 0
                && sla.numWitnesses <= 127
                && sla.minConsensusPercentage >= 51
                && sla.witnessReward > 0
                && sla.witnessCollateral > 20 * 10 ** 9
                && sla.witnessCollateral / sla.witnessReward <= 125
        );
    }


    /// ===============================================================================================================
    /// --- 'uint*' helper methods ------------------------------------------------------------------------------------

    /// @notice Convert a `uint8` into a 2 characters long `string` representing its two less significant hexadecimal values.
    function toHexString(uint8 _u)
        internal pure
        returns (string memory)
    {
        bytes memory b2 = new bytes(2);
        uint8 d0 = uint8(_u / 16) + 48;
        uint8 d1 = uint8(_u % 16) + 48;
        if (d0 > 57)
            d0 += 7;
        if (d1 > 57)
            d1 += 7;
        b2[0] = bytes1(d0);
        b2[1] = bytes1(d1);
        return string(b2);
    }

    /// @notice Convert a `uint8` into a 1, 2 or 3 characters long `string` representing its.
    /// three less significant decimal values.
    function toString(uint8 _u)
        internal pure
        returns (string memory)
    {
        if (_u < 10) {
            bytes memory b1 = new bytes(1);
            b1[0] = bytes1(uint8(_u) + 48);
            return string(b1);
        } else if (_u < 100) {
            bytes memory b2 = new bytes(2);
            b2[0] = bytes1(uint8(_u / 10) + 48);
            b2[1] = bytes1(uint8(_u % 10) + 48);
            return string(b2);
        } else {
            bytes memory b3 = new bytes(3);
            b3[0] = bytes1(uint8(_u / 100) + 48);
            b3[1] = bytes1(uint8(_u % 100 / 10) + 48);
            b3[2] = bytes1(uint8(_u % 10) + 48);
            return string(b3);
        }
    }

    /// @notice Convert a `uint` into a string` representing its value.
    function toString(uint v)
        internal pure 
        returns (string memory)
    {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        do {
            uint8 remainder = uint8(v % 10);
            v = v / 10;
            reversed[i ++] = bytes1(48 + remainder);
        } while (v != 0);
        bytes memory buf = new bytes(i);
        for (uint j = 1; j <= i; j ++) {
            buf[j - 1] = reversed[i - j];
        }
        return string(buf);
    }


    /// ===============================================================================================================
    /// --- 'bytes' helper methods ------------------------------------------------------------------------------------

    /// @dev Transform given bytes into a Witnet.Result instance.
    /// @param cborBytes Raw bytes representing a CBOR-encoded value.
    /// @return A `Witnet.Result` instance.
    function resultFromCborBytes(bytes memory cborBytes)
        internal pure
        returns (Witnet.Result memory)
    {
        WitnetCBOR.CBOR memory cborValue = WitnetCBOR.fromBytes(cborBytes);
        return _resultFromCborValue(cborValue);
    }

    function toAddress(bytes memory _value) internal pure returns (address) {
        return address(toBytes20(_value));
    }

    function toBytes4(bytes memory _value) internal pure returns (bytes4) {
        return bytes4(toFixedBytes(_value, 4));
    }
    
    function toBytes20(bytes memory _value) internal pure returns (bytes20) {
        return bytes20(toFixedBytes(_value, 20));
    }
    
    function toBytes32(bytes memory _value) internal pure returns (bytes32) {
        return toFixedBytes(_value, 32);
    }

    function toFixedBytes(bytes memory _value, uint8 _numBytes)
        internal pure
        returns (bytes32 _bytes32)
    {
        assert(_numBytes <= 32);
        unchecked {
            uint _len = _value.length > _numBytes ? _numBytes : _value.length;
            for (uint _i = 0; _i < _len; _i ++) {
                _bytes32 |= bytes32(_value[_i] & 0xff) >> (_i * 8);
            }
        }
    }


    /// ===============================================================================================================
    /// --- 'bytes4' helper methods -----------------------------------------------------------------------------------

    function toHexString(bytes4 word) internal pure returns (string memory) {
        return string(abi.encodePacked(
            toHexString(uint8(bytes1(word))),
            toHexString(uint8(bytes1(word << 8))),
            toHexString(uint8(bytes1(word << 16))),
            toHexString(uint8(bytes1(word << 24)))
        ));
    }


    /// ===============================================================================================================
    /// --- 'string' helper methods -----------------------------------------------------------------------------------

    function toLowerCase(string memory str)
        internal pure
        returns (string memory)
    {
        bytes memory lowered = new bytes(bytes(str).length);
        unchecked {
            for (uint i = 0; i < lowered.length; i ++) {
                uint8 char = uint8(bytes(str)[i]);
                if (char >= 65 && char <= 90) {
                    lowered[i] = bytes1(char + 32);
                } else {
                    lowered[i] = bytes1(char);
                }
            }
        }
        return string(lowered);
    }

    /// @notice Converts bytes32 into string.
    function toString(bytes32 _bytes32)
        internal pure
        returns (string memory)
    {
        bytes memory _bytes = new bytes(_toStringLength(_bytes32));
        for (uint _i = 0; _i < _bytes.length;) {
            _bytes[_i] = _bytes32[_i];
            unchecked {
                _i ++;
            }
        }
        return string(_bytes);
    }

    function tryUint(string memory str)
        internal pure
        returns (uint res, bool)
    {
        unchecked {
            for (uint256 i = 0; i < bytes(str).length; i++) {
                if (
                    (uint8(bytes(str)[i]) - 48) < 0
                        || (uint8(bytes(str)[i]) - 48) > 9
                ) {
                    return (0, false);
                }
                res += (uint8(bytes(str)[i]) - 48) * 10 ** (bytes(str).length - i - 1);
            }
            return (res, true);
        }
    }
    

    /// ===============================================================================================================
    /// --- 'Witnet.Result' helper methods ----------------------------------------------------------------------------

    modifier _isReady(Result memory result) {
        require(result.success, "Witnet: tried to decode value from errored result.");
        _;
    }

    /// @dev Decode an address from the Witnet.Result's CBOR value.
    function asAddress(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (address)
    {
        if (result.value.majorType == uint8(WitnetCBOR.MAJOR_TYPE_BYTES)) {
            return toAddress(result.value.readBytes());
        } else {
            // TODO
            revert("WitnetLib: reading address from string not yet supported.");
        }
    }

    /// @dev Decode a `bool` value from the Witnet.Result's CBOR value.
    function asBool(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (bool)
    {
        return result.value.readBool();
    }

    /// @dev Decode a `bytes` value from the Witnet.Result's CBOR value.
    function asBytes(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns(bytes memory)
    {
        return result.value.readBytes();
    }

    /// @dev Decode a `bytes4` value from the Witnet.Result's CBOR value.
    function asBytes4(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (bytes4)
    {
        return toBytes4(asBytes(result));
    }

    /// @dev Decode a `bytes32` value from the Witnet.Result's CBOR value.
    function asBytes32(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (bytes32)
    {
        return toBytes32(asBytes(result));
    }

    /// @notice Returns the Witnet.Result's unread CBOR value.
    function asCborValue(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (WitnetCBOR.CBOR memory)
    {
        return result.value;
    }

    /// @notice Decode array of CBOR values from the Witnet.Result's CBOR value. 
    function asCborArray(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (WitnetCBOR.CBOR[] memory)
    {
        return result.value.readArray();
    }

    /// @dev Decode a fixed16 (half-precision) numeric value from the Witnet.Result's CBOR value.
    /// @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values.
    /// by 5 decimal orders so as to get a fixed precision of 5 decimal positions, which should be OK for most `fixed16`.
    /// use cases. In other words, the output of this method is 10,000 times the actual value, encoded into an `int32`.
    function asFixed16(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (int32)
    {
        return result.value.readFloat16();
    }

    /// @dev Decode an array of fixed16 values from the Witnet.Result's CBOR value.
    function asFixed16Array(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (int32[] memory)
    {
        return result.value.readFloat16Array();
    }

    /// @dev Decode an `int64` value from the Witnet.Result's CBOR value.
    function asInt(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (int)
    {
        return result.value.readInt();
    }

    /// @dev Decode an array of integer numeric values from a Witnet.Result as an `int[]` array.
    /// @param result An instance of Witnet.Result.
    /// @return The `int[]` decoded from the Witnet.Result.
    function asIntArray(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (int[] memory)
    {
        return result.value.readIntArray();
    }

    /// @dev Decode a `string` value from the Witnet.Result's CBOR value.
    /// @param result An instance of Witnet.Result.
    /// @return The `string` decoded from the Witnet.Result.
    function asText(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns(string memory)
    {
        return result.value.readString();
    }

    /// @dev Decode an array of strings from the Witnet.Result's CBOR value.
    /// @param result An instance of Witnet.Result.
    /// @return The `string[]` decoded from the Witnet.Result.
    function asTextArray(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (string[] memory)
    {
        return result.value.readStringArray();
    }

    /// @dev Decode a `uint64` value from the Witnet.Result's CBOR value.
    /// @param result An instance of Witnet.Result.
    /// @return The `uint` decoded from the Witnet.Result.
    function asUint(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (uint)
    {
        return result.value.readUint();
    }

    /// @dev Decode an array of `uint64` values from the Witnet.Result's CBOR value.
    /// @param result An instance of Witnet.Result.
    /// @return The `uint[]` decoded from the Witnet.Result.
    function asUintArray(Witnet.Result memory result)
        internal pure
        returns (uint[] memory)
    {
        return result.value.readUintArray();
    }


    /// ===============================================================================================================
    /// --- Witnet library private methods ----------------------------------------------------------------------------

    /// @dev Decode a CBOR value into a Witnet.Result instance.
    function _resultFromCborValue(WitnetCBOR.CBOR memory cbor)
        private pure
        returns (Witnet.Result memory)    
    {
        // Witnet uses CBOR tag 39 to represent RADON error code identifiers.
        // [CBOR tag 39] Identifiers for CBOR: https://github.com/lucas-clemente/cbor-specs/blob/master/id.md
        bool success = cbor.tag != 39;
        return Witnet.Result(success, cbor);
    }

    /// @dev Calculate length of string-equivalent to given bytes32.
    function _toStringLength(bytes32 _bytes32)
        private pure
        returns (uint _length)
    {
        for (; _length < 32; ) {
            if (_bytes32[_length] == 0) {
                break;
            }
            unchecked {
                _length ++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "../../WitnetBytecodes.sol";

interface IWitnetRequestFactory {
    event WitnetRequestTemplateBuilt(address template, bool parameterized);
    function buildRequestTemplate(
            bytes32[] memory sourcesIds,
            bytes32 aggregatorId,
            bytes32 tallyId,
            uint16  resultDataMaxSize
        ) external returns (address template);
    function class() external view returns (bytes4);    
    function registry() external view returns (WitnetBytecodes);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "../../libs/WitnetV2.sol";

interface IWitnetOracleEvents {
    
    /// Emitted every time a new query containing some verified data request is posted to the WRB.
    event WitnetQuery(
        uint256 indexed id, 
        uint256 evmReward,
        WitnetV2.RadonSLA witnetSLA
    );

    /// Emitted when a query with no callback gets reported into the WRB.
    event WitnetQueryResponse(
        uint256 id, 
        uint256 evmGasPrice
    );

    /// Emitted when a query with a callback gets successfully reported into the WRB.
    event WitnetQueryResponseDelivered(
        uint256 indexed id, 
        uint256 evmGasPrice, 
        uint256 evmCallbackGas
    );

    /// Emitted when a query with a callback cannot get reported into the WRB.
    event WitnetQueryResponseDeliveryFailed(
        uint256 indexed id, 
        bytes   resultCborBytes,
        uint256 evmGasPrice, 
        uint256 evmCallbackActualGas, 
        string  evmCallbackRevertReason
    );

    /// Emitted when the reward of some not-yet reported query is upgraded.
    event WitnetQueryRewardUpgraded(
        uint256 indexed id, 
        uint256 evmReward
    );

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "../../libs/WitnetV2.sol";

interface IWitnetOracle {

    /// @notice Estimate the minimum reward required for posting a data request.
    /// @dev Underestimates if the size of returned data is greater than `resultMaxSize`. 
    /// @param gasPrice Expected gas price to pay upon posting the data request.
    /// @param resultMaxSize Maximum expected size of returned data (in bytes).  
    function estimateBaseFee(uint256 gasPrice, uint16 resultMaxSize) external view returns (uint256);

    /// @notice Estimate the minimum reward required for posting a data request.
    /// @dev Fails if the RAD hash was not previously verified on the WitnetRequestBytecodes registry.
    /// @param gasPrice Expected gas price to pay upon posting the data request.
    /// @param radHash The RAD hash of the data request to be solved by Witnet.
    function estimateBaseFee(uint256 gasPrice, bytes32 radHash) external view returns (uint256);
    
    /// @notice Estimate the minimum reward required for posting a data request with a callback.
    /// @param gasPrice Expected gas price to pay upon posting the data request.
    /// @param callbackGasLimit Maximum gas to be spent when reporting the data request result.
    function estimateBaseFeeWithCallback(uint256 gasPrice, uint24 callbackGasLimit) external view returns (uint256);
       
    /// @notice Retrieves a copy of all Witnet-provable data related to a previously posted request, 
    /// removing the whole query from the WRB storage.
    /// @dev Fails if the query was not in 'Reported' status, or called from an address different to
    /// @dev the one that actually posted the given request.
    /// @param queryId The unique query identifier.
    function fetchQueryResponse(uint256 queryId) external returns (WitnetV2.Response memory);
   
    /// @notice Gets the whole Query data contents, if any, no matter its current status.
    function getQuery(uint256 queryId) external view returns (WitnetV2.Query memory);

    /// @notice Gets the current EVM reward the report can claim, if not done yet.
    function getQueryEvmReward(uint256 queryId) external view returns (uint256);

    /// @notice Retrieves the RAD hash and SLA parameters of the given query.
    /// @param queryId The unique query identifier.
    function getQueryRequest(uint256 queryId) external view returns (WitnetV2.Request memory);

    /// @notice Retrieves the whole `Witnet.Response` record referred to a previously posted Witnet Data Request.
    /// @param queryId The unique query identifier.
    function getQueryResponse(uint256 queryId) external view returns (WitnetV2.Response memory);

    /// @notice Returns query's result current status from a requester's point of view:
    /// @notice   - 0 => Void: the query is either non-existent or deleted;
    /// @notice   - 1 => Awaiting: the query has not yet been reported;
    /// @notice   - 2 => Ready: the query response was finalized, and contains a result with no erros.
    /// @notice   - 3 => Error: the query response was finalized, and contains a result with errors.
    /// @param queryId The unique query identifier.
    function getQueryResponseStatus(uint256 queryId) external view returns (WitnetV2.ResponseStatus);

    /// @notice Retrieves the CBOR-encoded buffer containing the Witnet-provided result to the given query.
    /// @param queryId The unique query identifier.
    function getQueryResultCborBytes(uint256 queryId) external view returns (bytes memory);

    /// @notice Gets error code identifying some possible failure on the resolution of the given query.
    /// @param queryId The unique query identifier.
    function getQueryResultError(uint256 queryId) external view returns (Witnet.ResultError memory);

    /// @notice Gets current status of given query.
    function getQueryStatus(uint256 queryId) external view returns (WitnetV2.QueryStatus);
    
    /// @notice Get current status of all given query ids.
    function getQueryStatusBatch(uint256[] calldata queryIds) external view returns (WitnetV2.QueryStatus[] memory);

    /// @notice Returns next query id to be generated by the Witnet Request Board.
    function getNextQueryId() external view returns (uint256);

    /// @notice Requests the execution of the given Witnet Data Request, in expectation that it will be relayed and 
    /// @notice solved by the Witnet blockchain. A reward amount is escrowed by the Witnet Request Board that will be 
    /// @notice transferred to the reporter who relays back the Witnet-provable result to this request.
    /// @dev Reasons to fail:
    /// @dev - the RAD hash was not previously verified by the WitnetRequestBytecodes registry;
    /// @dev - invalid SLA parameters were provided;
    /// @dev - insufficient value is paid as reward.
    /// @param queryRAD The RAD hash of the data request to be solved by Witnet.
    /// @param querySLA The data query SLA to be fulfilled on the Witnet blockchain.
    /// @return queryId Unique query identifier.
    function postRequest(
            bytes32 queryRAD, 
            WitnetV2.RadonSLA calldata querySLA
        ) external payable returns (uint256 queryId);

    /// @notice Requests the execution of the given Witnet Data Request, in expectation that it will be relayed and solved by 
    /// @notice the Witnet blockchain. A reward amount is escrowed by the Witnet Request Board that will be transferred to the 
    /// @notice reporter who relays back the Witnet-provable result to this request. The Witnet-provable result will be reported
    /// @notice directly to the requesting contract. If the report callback fails for any reason, an `WitnetQueryResponseDeliveryFailed`
    /// @notice will be triggered, and the Witnet audit trail will be saved in storage, but not so the actual CBOR-encoded result.
    /// @dev Reasons to fail:
    /// @dev - the caller is not a contract implementing the IWitnetConsumer interface;
    /// @dev - the RAD hash was not previously verified by the WitnetRequestBytecodes registry;
    /// @dev - invalid SLA parameters were provided;
    /// @dev - insufficient value is paid as reward.
    /// @param queryRAD The RAD hash of the data request to be solved by Witnet.
    /// @param querySLA The data query SLA to be fulfilled on the Witnet blockchain.
    /// @param queryCallbackGasLimit Maximum gas to be spent when reporting the data request result.
    /// @return queryId Unique query identifier.
    function postRequestWithCallback(
            bytes32 queryRAD, 
            WitnetV2.RadonSLA calldata querySLA, 
            uint24 queryCallbackGasLimit
        ) external payable returns (uint256 queryId);

    /// @notice Requests the execution of the given Witnet Data Request, in expectation that it will be relayed and solved by 
    /// @notice the Witnet blockchain. A reward amount is escrowed by the Witnet Request Board that will be transferred to the 
    /// @notice reporter who relays back the Witnet-provable result to this request. The Witnet-provable result will be reported
    /// @notice directly to the requesting contract. If the report callback fails for any reason, a `WitnetQueryResponseDeliveryFailed`
    /// @notice event will be triggered, and the Witnet audit trail will be saved in storage, but not so the CBOR-encoded result.
    /// @dev Reasons to fail:
    /// @dev - the caller is not a contract implementing the IWitnetConsumer interface;
    /// @dev - the provided bytecode is empty;
    /// @dev - invalid SLA parameters were provided;
    /// @dev - insufficient value is paid as reward.
    /// @param queryUnverifiedBytecode The (unverified) bytecode containing the actual data request to be solved by the Witnet blockchain.
    /// @param querySLA The data query SLA to be fulfilled on the Witnet blockchain.
    /// @param queryCallbackGasLimit Maximum gas to be spent when reporting the data request result.
    /// @return queryId Unique query identifier.
    function postRequestWithCallback(
            bytes calldata queryUnverifiedBytecode,
            WitnetV2.RadonSLA calldata querySLA, 
            uint24 queryCallbackGasLimit
        ) external payable returns (uint256 queryId);

    /// @notice Increments the reward of a previously posted request by adding the transaction value to it.
    /// @param queryId The unique query identifier.
    function upgradeQueryEvmReward(uint256 queryId) external payable;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../libs/Witnet.sol";

interface IWitnetConsumer {

    /// @notice Method to be called from the WitnetOracle contract as soon as the given Witnet `queryId`
    /// @notice gets reported, if reported with no errors.
    /// @dev It should revert if called from any other address different to the WitnetOracle being used
    /// @dev by the WitnetConsumer contract. 
    /// @param witnetQueryId The unique identifier of the Witnet query being reported.
    /// @param witnetResultTallyHash Hash of the commit/reveal witnessing act that took place in the Witnet blockahin.
    /// @param witnetResultTimestamp Timestamp at which the reported value was captured by the Witnet blockchain. 
    /// @param witnetEvmFinalityBlock EVM block at which the provided data can be considered to be final.
    /// @param witnetResultCborValue The CBOR-encoded resulting value of the Witnet query being reported.
    function reportWitnetQueryResult(
            uint256 witnetQueryId, 
            uint64  witnetResultTimestamp,
            bytes32 witnetResultTallyHash,
            uint256 witnetEvmFinalityBlock,
            WitnetCBOR.CBOR calldata witnetResultCborValue
        ) external;

    /// @notice Method to be called from the WitnetOracle contract as soon as the given Witnet `queryId`
    /// @notice gets reported, if reported WITH errors.
    /// @dev It should revert if called from any other address different to the WitnetOracle being used
    /// @dev by the WitnetConsumer contract. 
    /// @param witnetQueryId The unique identifier of the Witnet query being reported.
    /// @param witnetResultTallyHash Hash of the commit/reveal witnessing act that took place in the Witnet blockahin.
    /// @param witnetResultTimestamp Timestamp at which the reported value was captured by the Witnet blockchain. 
    /// @param witnetEvmFinalityBlock EVM block at which the provided data can be considered to be final.
    /// @param errorCode The error code enum identifying the error produced during resolution on the Witnet blockchain.
    /// @param errorArgs Error arguments, if any. An empty buffer is to be passed if no error arguments apply.
    function reportWitnetQueryError(
            uint256 witnetQueryId, 
            uint64  witnetResultTimestamp,
            bytes32 witnetResultTallyHash,
            uint256 witnetEvmFinalityBlock,
            Witnet.ResultErrorCodes errorCode, 
            WitnetCBOR.CBOR calldata errorArgs
        ) external;

    /// @notice Determines if Witnet queries can be reported from given address.
    /// @dev In practice, must only be true on the WitnetOracle address that's being used by
    /// @dev the WitnetConsumer to post queries. 
    function reportableFrom(address) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IWitnetBytecodesEvents {    
    event NewDataProvider(uint256 index);
    event NewRadonRetrievalHash(bytes32 hash);
    event NewRadonReducerHash(bytes32 hash);
    event NewRadHash(bytes32 hash);
    event NewSlaHash(bytes32 hash);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IWitnetBytecodesErrors {
    error UnknownRadonRetrieval(bytes32 hash);
    error UnknownRadonReducer(bytes32 hash);
    error UnknownRadonRequest(bytes32 hash);
    error UnknownRadonSLA(bytes32 hash);  
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../../libs/WitnetV2.sol";

interface IWitnetBytecodes {

    function bytecodeOf(bytes32 radHash) external view returns (bytes memory);
    function bytecodeOf(bytes32 radHash, bytes32 slahHash) external view returns (bytes memory);

    function hashOf(
            bytes32[] calldata sources,
            bytes32 aggregator,
            bytes32 tally,
            uint16 resultMaxSize,
            string[][] calldata args
        ) external pure returns (bytes32);
    function hashOf(bytes32 radHash, bytes32 slaHash) external pure returns (bytes32 drQueryHash);
    function hashWeightWitsOf(bytes32 radHash, bytes32 slaHash) external view returns (
            bytes32 drQueryHash,
            uint32  drQueryWeight,
            uint256 drQueryWits
        );

    function lookupDataProvider(uint256 index) external view returns (string memory, uint);
    function lookupDataProviderIndex(string calldata authority) external view returns (uint);
    function lookupDataProviderSources(uint256 index, uint256 offset, uint256 length) external view returns (bytes32[] memory);

    function lookupRadonReducer(bytes32 hash) external view returns (Witnet.RadonReducer memory);
    
    function lookupRadonRetrieval(bytes32 hash) external view returns (Witnet.RadonRetrieval memory);
    function lookupRadonRetrievalArgsCount(bytes32 hash) external view returns (uint8);
    function lookupRadonRetrievalResultDataType(bytes32 hash) external view returns (Witnet.RadonDataTypes);
    
    function lookupRadonRequestAggregator(bytes32 radHash) external view returns (Witnet.RadonReducer memory);
    function lookupRadonRequestResultMaxSize(bytes32 radHash) external view returns (uint256);
    function lookupRadonRequestResultDataType(bytes32 radHash) external view returns (Witnet.RadonDataTypes);
    function lookupRadonRequestSources(bytes32 radHash) external view returns (bytes32[] memory);
    function lookupRadonRequestSourcesCount(bytes32 radHash) external view returns (uint);
    function lookupRadonRequestTally(bytes32 radHash) external view returns (Witnet.RadonReducer memory);
    
    function lookupRadonSLA(bytes32 slaHash) external view returns (Witnet.RadonSLA memory);
    function lookupRadonSLAReward(bytes32 slaHash) external view returns (uint);
    
    function verifyRadonRetrieval(
            Witnet.RadonDataRequestMethods requestMethod,
            string calldata requestSchema,
            string calldata requestAuthority,
            string calldata requestPath,
            string calldata requestQuery,
            string calldata requestBody,
            string[2][] calldata requestHeaders,
            bytes calldata requestRadonScript
        ) external returns (bytes32 hash);
    
    function verifyRadonRetrieval(
            Witnet.RadonDataRequestMethods requestMethod,
            string calldata requestURL,
            string calldata requestBody,
            string[2][] calldata requestHeaders,
            bytes calldata requestRadonScript
        ) external returns (bytes32 hash);
    
    function verifyRadonReducer(Witnet.RadonReducer calldata reducer)
        external returns (bytes32 hash);
    
    function verifyRadonRequest(
            bytes32[] calldata sources,
            bytes32 aggregator,
            bytes32 tally,
            uint16 resultMaxSize,
            string[][] calldata args
        ) external returns (bytes32 radHash);
    
    function verifyRadonSLA(Witnet.RadonSLA calldata sla)
        external returns (bytes32 slaHash);

    function totalDataProviders() external view returns (uint);
   
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "../libs/Witnet.sol";

/// @title Witnet Request Board info interface.
/// @author The Witnet Foundation.
interface IWitnetRequestBoardView {

    /// @notice Estimates the amount of reward we need to insert for a given gas price.
    /// @param _gasPrice The gas price for which we need to calculate the rewards.
    function estimateReward(uint256 _gasPrice) external view returns (uint256);

    /// @notice Returns next query id to be generated by the Witnet Request Board.
    function getNextQueryId() external view returns (uint256);

    /// @notice Gets the whole Query data contents, if any, no matter its current status.
    function getQueryData(uint256 _queryId) external view returns (Witnet.Query memory);

    /// @notice Gets current status of given query.
    function getQueryStatus(uint256 _queryId) external view returns (Witnet.QueryStatus);

    /// @notice Retrieves the whole Request record posted to the Witnet Request Board.
    /// @dev Fails if the `_queryId` is not valid or, if it has already been reported
    /// @dev or deleted.
    /// @param _queryId The unique identifier of a previously posted query.
    function readRequest(uint256 _queryId) external view returns (Witnet.Request memory);

    /// @notice Retrieves the serialized bytecode of a previously posted Witnet Data Request.
    /// @dev Fails if the `_queryId` is not valid, or if the related script bytecode 
    /// @dev got changed after being posted. Returns empty array once it gets reported, 
    /// @dev or deleted.
    /// @param _queryId The unique query identifier.
    function readRequestBytecode(uint256 _queryId) external view returns (bytes memory);

    /// @notice Retrieves the gas price that any assigned reporter will have to pay when reporting 
    /// result to a previously posted Witnet data request.
    /// @dev Fails if the `_queryId` is not valid or, if it has already been 
    /// @dev reported, or deleted. 
    /// @param _queryId The unique query identifie
    function readRequestGasPrice(uint256 _queryId) external view returns (uint256);

    /// @notice Retrieves the reward currently set for the referred query.
    /// @dev Fails if the `_queryId` is not valid or, if it has already been 
    /// @dev reported, or deleted. 
    /// @param _queryId The unique query identifier.
    function readRequestReward(uint256 _queryId) external view returns (uint256);

    /// @notice Retrieves the whole `Witnet.Response` record referred to a previously posted Witnet Data Request.
    /// @dev Fails if the `_queryId` is not in 'Reported' status.
    /// @param _queryId The unique query identifier.
    function readResponse(uint256 _queryId) external view returns (Witnet.Response memory);

    /// @notice Retrieves error codes of given query.
    /// @dev Fails if the `_queryId` is not in 'Reported' status, or if no actual error.
    /// @param _queryId The unique query identifier.
    function readResponseDrTxHash(uint256 _queryId) external view returns (bytes32);

    /// @notice Retrieves the address that reported the result to a previously-posted request.
    /// @dev Fails if the `_queryId` is not in 'Reported' status.
    /// @param _queryId The unique query identifier.
    function readResponseReporter(uint256 _queryId) external view returns (address);

    /// @notice Retrieves the Witnet-provided CBOR-bytes result of a previously posted request.
    /// @dev Fails if the `_queryId` is not in 'Reported' status.
    /// @param _queryId The unique query identifier.
    function readResponseResult(uint256 _queryId) external view returns (Witnet.Result memory);

    /// @notice Retrieves the timestamp in which the result to the referred query was solved by the Witnet DON.
    /// @dev Fails if the `_queryId` is not in 'Reported' status.
    /// @param _queryId The unique query identifier.
    function readResponseTimestamp(uint256 _queryId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./IWitnetRequest.sol";
import "../libs/WitnetV2.sol";

/// @title Witnet Requestor Interface
/// @notice It defines how to interact with the Witnet Request Board in order to:
///   - request the execution of Witnet Radon scripts (data request);
///   - upgrade the resolution reward of any previously posted request, in case gas price raises in mainnet;
///   - read the result of any previously posted request, eventually reported by the Witnet DON.
///   - remove from storage all data related to past and solved data requests, and results.
/// @author The Witnet Foundation.
interface IWitnetRequestBoardRequestor {

    /// @notice Returns query's result current status from a requester's point of view:
    /// @notice   - 0 => Void: the query is either non-existent or deleted;
    /// @notice   - 1 => Awaiting: the query has not yet been reported;
    /// @notice   - 2 => Ready: the query has been succesfully solved;
    /// @notice   - 3 => Error: the query couldn't get solved due to some issue.
    /// @param _queryId The unique query identifier.
    function checkResultStatus(uint256 _queryId) external view returns (Witnet.ResultStatus);

    /// @notice Gets error code identifying some possible failure on the resolution of the given query.
    /// @param _queryId The unique query identifier.
    function checkResultError(uint256 _queryId) external view returns (Witnet.ResultError memory);

    /// @notice Retrieves a copy of all Witnet-provided data related to a previously posted request, removing the whole query from the WRB storage.
    /// @dev Fails if the `_queryId` is not in 'Reported' status, or called from an address different to
    /// @dev the one that actually posted the given request.
    /// @param _queryId The unique query identifier.
    function deleteQuery(uint256 _queryId) external returns (Witnet.Response memory);

    /// @notice Requests the execution of the given Witnet Data Request in expectation that it will be relayed and solved by the Witnet DON.
    /// @notice A reward amount is escrowed by the Witnet Request Board that will be transferred to the reporter who relays back the Witnet-provided 
    /// @notice result to this request.
    /// @dev Fails if:
    /// @dev - provided reward is too low.
    /// @dev - provided script is zero address.
    /// @dev - provided script bytecode is empty.
    /// @param addr The address of the IWitnetRequest contract that can provide the actual Data Request bytecode.
    /// @return _queryId Unique query identifier.
    function postRequest(IWitnetRequest addr) external payable returns (uint256 _queryId);

    /// @notice Requests the execution of the given Witnet Data Request in expectation that it will be relayed and solved by the Witnet DON.
    /// @notice A reward amount is escrowed by the Witnet Request Board that will be transferred to the reporter who relays back the Witnet-provided 
    /// @notice result to this request.
    /// @dev Fails if, provided reward is too low.
    /// @param radHash The RAD hash of the data request to be solved by Witnet.
    /// @param slaHash The SLA hash of the data request to be solved by Witnet.
    /// @return _queryId Unique query identifier.
    function postRequest(bytes32 radHash, bytes32 slaHash) external payable returns (uint256 _queryId);

    /// @notice Requests the execution of the given Witnet Data Request in expectation that it will be relayed and solved by the Witnet DON.
    /// @notice A reward amount is escrowed by the Witnet Request Board that will be transferred to the reporter who relays back the Witnet-provided 
    /// @notice result to this request.
    /// @dev Fails if, provided reward is too low.
    /// @param radHash The RAD hash of the data request to be solved by Witnet.
    /// @param slaParams The SLA params of the data request to be solved by Witnet.
    /// @return _queryId Unique query identifier.
    function postRequest(bytes32 radHash, Witnet.RadonSLA calldata slaParams) external payable returns (uint256 _queryId);

    /// @notice Increments the reward of a previously posted request by adding the transaction value to it.
    /// @dev Updates request `gasPrice` in case this method is called with a higher 
    /// @dev gas price value than the one used in previous calls to `postRequest` or
    /// @dev `upgradeReward`. 
    /// @dev Fails if the `_queryId` is not in 'Posted' status.
    /// @dev Fails also in case the request `gasPrice` is increased, and the new 
    /// @dev reward value gets below new recalculated threshold. 
    /// @param _queryId The unique query identifier.
    function upgradeReward(uint256 _queryId) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/// @title The Witnet Request Board Reporter interface.
/// @author The Witnet Foundation.
interface IWitnetRequestBoardReporter {

    /// @notice Reports the Witnet-provided result to a previously posted request. 
    /// @dev Will assume `block.timestamp` as the timestamp at which the request was solved.
    /// @dev Fails if:
    /// @dev - the `_queryId` is not in 'Posted' status.
    /// @dev - provided `_drTxHash` is zero;
    /// @dev - length of provided `_result` is zero.
    /// @param _queryId The unique identifier of the data request.
    /// @param _drTxHash The hash of the corresponding data request transaction in Witnet.
    /// @param _result The result itself as bytes.
    function reportResult(
            uint256 _queryId,
            bytes32 _drTxHash,
            bytes calldata _result
        ) external;

    /// @notice Reports the Witnet-provided result to a previously posted request.
    /// @dev Fails if:
    /// @dev - called from unauthorized address;
    /// @dev - the `_queryId` is not in 'Posted' status.
    /// @dev - provided `_drTxHash` is zero;
    /// @dev - length of provided `_result` is zero.
    /// @param _queryId The unique query identifier
    /// @param _timestamp The timestamp of the solving tally transaction in Witnet.
    /// @param _drTxHash The hash of the corresponding data request transaction in Witnet.
    /// @param _result The result itself as bytes.
    function reportResult(
            uint256 _queryId,
            uint256 _timestamp,
            bytes32 _drTxHash,
            bytes calldata _result
        ) external;

    /// @notice Reports Witnet-provided results to multiple requests within a single EVM tx.
    /// @dev Must emit a PostedResult event for every succesfully reported result.
    /// @param _batchResults Array of BatchResult structs, every one containing:
    ///         - unique query identifier;
    ///         - timestamp of the solving tally txs in Witnet. If zero is provided, EVM-timestamp will be used instead;
    ///         - hash of the corresponding data request tx at the Witnet side-chain level;
    ///         - data request result in raw bytes.
    /// @param _verbose If true, must emit a BatchReportError event for every failing report, if any. 
    function reportResultBatch(BatchResult[] calldata _batchResults, bool _verbose) external;
        
        struct BatchResult {
            uint256 queryId;
            uint256 timestamp;
            bytes32 drTxHash;
            bytes   cborBytes;
        }

        event BatchReportError(uint256 queryId, string reason);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/// @title Witnet Request Board emitting events interface.
/// @author The Witnet Foundation.
interface IWitnetRequestBoardEvents {
    
    /// Emitted when a Witnet Data Request is posted to the WRB.
    event PostedRequest(uint256 queryId, address from);

    /// Emitted when a Witnet-solved result is reported to the WRB.
    event PostedResult(uint256 queryId, address from);

    /// Emitted when all data related to given query is deleted from the WRB.
    event DeletedQuery(uint256 queryId, address from);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "../libs/Witnet.sol";

/// @title Witnet Request Board info interface.
/// @author The Witnet Foundation.
interface IWitnetRequestBoardDeprecating {

    /// ===============================================================================================================
    /// --- Deprecating funcionality v0.5 -----------------------------------------------------------------------------
    
    /// Tell if a Witnet.Result is successful.
    /// @param _result An instance of Witnet.Result.
    /// @return `true` if successful, `false` if errored.
    function isOk(Witnet.Result memory _result) external pure returns (bool);

    /// Decode a bytes value from a Witnet.Result as a `bytes32` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `bytes32` decoded from the Witnet.Result.
    function asBytes32(Witnet.Result memory _result) external pure returns (bytes32);

    /// Generate a suitable error message for a member of `Witnet.ResultErrorCodes` and its corresponding arguments.
    /// @dev WARN: Note that client contracts should wrap this function into a try-catch foreseing potential errors generated in this function
    /// @param _result An instance of `Witnet.Result`.
    /// @return A tuple containing the `CBORValue.Error memory` decoded from the `Witnet.Result`, plus a loggable error message.
    function asErrorMessage(Witnet.Result memory _result) external pure returns (Witnet.ResultErrorCodes, string memory);

    /// Decode a natural numeric value from a Witnet.Result as a `uint` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `uint` decoded from the Witnet.Result.
    function asUint64(Witnet.Result memory _result) external pure returns (uint64);

    /// Decode raw CBOR bytes into a Witnet.Result instance.
    /// @param _cborBytes Raw bytes representing a CBOR-encoded value.
    /// @return A `Witnet.Result` instance.
    function resultFromCborBytes(bytes memory _cborBytes) external pure returns (Witnet.Result memory);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/// @title The Witnet Data Request basic interface.
/// @author The Witnet Foundation.
interface IWitnetRequest {
    
    /// @notice A `IWitnetRequest` is constructed around a `bytes` value containing 
    /// @notice a well-formed Witnet Data Request using Protocol Buffers.
    function bytecode() external view returns (bytes memory);

    /// @notice Returns SHA256 hash of Witnet Data Request as CBOR-encoded bytes.
    function hash() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// solhint-disable var-name-mixedcase
// solhint-disable payable-fallback

pragma solidity >=0.8.0 <0.9.0;

import "../patterns/ERC165.sol";
import "../patterns/Ownable2Step.sol";
import "../patterns/ReentrancyGuard.sol";
import "../patterns/Upgradeable.sol";

import "./WitnetProxy.sol";

/// @title Witnet Request Board base contract, with an Upgradeable (and Destructible) touch.
/// @author The Witnet Foundation.
abstract contract WitnetUpgradableBase
    is
        ERC165,
        Ownable2Step,
        Upgradeable, 
        ReentrancyGuard
{
    bytes32 internal immutable _WITNET_UPGRADABLE_VERSION;

    error AlreadyUpgraded(address implementation);
    error NotCompliant(bytes4 interfaceId);
    error NotUpgradable(address self);
    error OnlyOwner(address owner);

    constructor(
            bool _upgradable,
            bytes32 _versionTag,
            string memory _proxiableUUID
        )
        Upgradeable(_upgradable)
    {
        _WITNET_UPGRADABLE_VERSION = _versionTag;
        proxiableUUID = keccak256(bytes(_proxiableUUID));
    }
    
    /// @dev Reverts if proxy delegatecalls to unexistent method.
    fallback() virtual external {
        revert("WitnetUpgradableBase: not implemented");
    }


    // ================================================================================================================
    // --- Overrides IERC165 interface --------------------------------------------------------------------------------

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 _interfaceId)
      public view
      virtual override
      returns (bool)
    {
        return _interfaceId == type(Ownable2Step).interfaceId
            || _interfaceId == type(Upgradeable).interfaceId
            || super.supportsInterface(_interfaceId);
    }

    
    // ================================================================================================================
    // --- Overrides 'Proxiable' --------------------------------------------------------------------------------------

    /// @dev Gets immutable "heritage blood line" (ie. genotype) as a Proxiable, and eventually Upgradeable, contract.
    ///      If implemented as an Upgradeable touch, upgrading this contract to another one with a different 
    ///      `proxiableUUID()` value should fail.
    bytes32 public immutable override proxiableUUID;


    // ================================================================================================================
    // --- Overrides 'Upgradeable' --------------------------------------------------------------------------------------

    /// Retrieves human-readable version tag of current implementation.
    function version() public view virtual override returns (string memory) {
        return _toString(_WITNET_UPGRADABLE_VERSION);
    }


    // ================================================================================================================
    // --- Internal methods -------------------------------------------------------------------------------------------

    /// Converts bytes32 into string.
    function _toString(bytes32 _bytes32)
        internal pure
        returns (string memory)
    {
        bytes memory _bytes = new bytes(_toStringLength(_bytes32));
        for (uint _i = 0; _i < _bytes.length;) {
            _bytes[_i] = _bytes32[_i];
            unchecked {
                _i ++;
            }
        }
        return string(_bytes);
    }

    // Calculate length of string-equivalent to given bytes32.
    function _toStringLength(bytes32 _bytes32)
        internal pure
        returns (uint _length)
    {
        for (; _length < 32; ) {
            if (_bytes32[_length] == 0) {
                break;
            }
            unchecked {
                _length ++;
            }
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "../patterns/Upgradeable.sol";

/// @title WitnetProxy: upgradable delegate-proxy contract. 
/// @author The Witnet Foundation.
contract WitnetProxy {

    /// Event emitted every time the implementation gets updated.
    event Upgraded(address indexed implementation);  

    /// Constructor with no params as to ease eventual support of Singleton pattern (i.e. ERC-2470).
    constructor () {}

    receive() virtual external payable {}

    /// Payable fallback accepts delegating calls to payable functions.  
    fallback() external payable { /* solhint-disable no-complex-fallback */
        address _implementation = implementation();
        assembly { /* solhint-disable avoid-low-level-calls */
            // Gas optimized delegate call to 'implementation' contract.
            // Note: `msg.data`, `msg.sender` and `msg.value` will be passed over 
            //       to actual implementation of `msg.sig` within `implementation` contract.
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _implementation, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            switch result
                case 0  { 
                    // pass back revert message:
                    revert(ptr, size) 
                }
                default {
                  // pass back same data as returned by 'implementation' contract:
                  return(ptr, size) 
                }
        }
    }

    /// Returns proxy's current implementation address.
    function implementation() public view returns (address) {
        return __proxySlot().implementation;
    }

    /// Upgrades the `implementation` address.
    /// @param _newImplementation New implementation address.
    /// @param _initData Raw data with which new implementation will be initialized.
    /// @return Returns whether new implementation would be further upgradable, or not.
    function upgradeTo(address _newImplementation, bytes memory _initData)
        public returns (bool)
    {
        // New implementation cannot be null:
        require(_newImplementation != address(0), "WitnetProxy: null implementation");

        address _oldImplementation = implementation();
        if (_oldImplementation != address(0)) {
            // New implementation address must differ from current one:
            require(_newImplementation != _oldImplementation, "WitnetProxy: nothing to upgrade");

            // Assert whether current implementation is intrinsically upgradable:
            try Upgradeable(_oldImplementation).isUpgradable() returns (bool _isUpgradable) {
                require(_isUpgradable, "WitnetProxy: not upgradable");
            } catch {
                revert("WitnetProxy: unable to check upgradability");
            }

            // Assert whether current implementation allows `msg.sender` to upgrade the proxy:
            (bool _wasCalled, bytes memory _result) = _oldImplementation.delegatecall(
                abi.encodeWithSignature(
                    "isUpgradableFrom(address)",
                    msg.sender
                )
            );
            require(_wasCalled, "WitnetProxy: not compliant");
            require(abi.decode(_result, (bool)), "WitnetProxy: not authorized");
            require(
                Upgradeable(_oldImplementation).proxiableUUID() == Upgradeable(_newImplementation).proxiableUUID(),
                "WitnetProxy: proxiableUUIDs mismatch"
            );
        }

        // Initialize new implementation within proxy-context storage:
        (bool _wasInitialized,) = _newImplementation.delegatecall(
            abi.encodeWithSignature(
                "initialize(bytes)",
                _initData
            )
        );
        require(_wasInitialized, "WitnetProxy: unable to initialize");

        // If all checks and initialization pass, update implementation address:
        __proxySlot().implementation = _newImplementation;
        emit Upgraded(_newImplementation);

        // Asserts new implementation complies w/ minimal implementation of Upgradeable interface:
        try Upgradeable(_newImplementation).isUpgradable() returns (bool _isUpgradable) {
            return _isUpgradable;
        }
        catch {
            revert ("WitnetProxy: not compliant");
        }
    }

    /// @dev Complying with EIP-1967, retrieves storage struct containing proxy's current implementation address.
    function __proxySlot() private pure returns (Proxiable.ProxiableSlot storage _slot) {
        assembly {
            // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
            _slot.slot := 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./WitnetBoardData.sol";

/// @title Witnet Access Control Lists storage layout, for Witnet-trusted request boards.
/// @author The Witnet Foundation.
abstract contract WitnetBoardDataACLs
    is
        WitnetBoardData
{
    bytes32 internal constant _WITNET_BOARD_ACLS_SLOTHASH =
        /* keccak256("io.witnet.boards.data.acls") */
        0xa6db7263983f337bae2c9fb315730227961d1c1153ae1e10a56b5791465dd6fd;

    struct WitnetBoardACLs {
        mapping (address => bool) isReporter_;
    }

    constructor() {
        _acls().isReporter_[msg.sender] = true;
    }

    modifier onlyReporters {
        require(
            _acls().isReporter_[msg.sender],
            "WitnetRequestBoard: unauthorized reporter"
        );
        _;
    } 

    // ================================================================================================================
    // --- Internal functions -----------------------------------------------------------------------------------------

    function _acls() internal pure returns (WitnetBoardACLs storage _struct) {
        assembly {
            _struct.slot := _WITNET_BOARD_ACLS_SLOTHASH
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "../libs/Witnet.sol";

/// @title Witnet Request Board base data model. 
/// @author The Witnet Foundation.
abstract contract WitnetBoardData {  

    bytes32 internal constant _WITNET_BOARD_DATA_SLOTHASH =
        /* keccak256("io.witnet.boards.data") */
        0xf595240b351bc8f951c2f53b26f4e78c32cb62122cf76c19b7fdda7d4968e183;

    struct WitnetBoardState {
        address base;
        address owner;    
        uint256 numQueries;
        mapping (uint => Witnet.Query) queries;
    }

    constructor() {
        __storage().owner = msg.sender;
    }

    /// Asserts the given query is currently in the given status.
    modifier inStatus(uint256 _queryId, Witnet.QueryStatus _status) {
      require(
          _statusOf(_queryId) == _status,
          _statusOfRevertMessage(_status)
        );
      _;
    }

    /// Asserts the given query was previously posted and that it was not yet deleted.
    modifier notDeleted(uint256 _queryId) {
        require(_queryId > 0 && _queryId <= __storage().numQueries, "WitnetRequestBoard: not yet posted");
        require(__query(_queryId).from  != address(0), "WitnetRequestBoard: deleted");
        _;
    }

    modifier onlyRequester(uint256 _queryId) {
      require(__query(_queryId).from == msg.sender, "WitnetRequestBoard: only the requester");
      _;
    }

    /// Asserts the give query was actually posted before calling this method.
    modifier wasPosted(uint256 _queryId) {
        require(_queryId > 0 && _queryId <= __storage().numQueries, "WitnetRequestBoard: not yet posted");
        _;
    }

    // ================================================================================================================
    // --- Internal functions -----------------------------------------------------------------------------------------

    /// Gets query storage by query id.
    function __query(uint256 _queryId) internal view returns (Witnet.Query storage) {
      return __storage().queries[_queryId];
    }

    /// Gets the Witnet.Request part of a given query.
    function __request(uint256 _queryId)
      internal view
      returns (Witnet.Request storage)
    {
        return __storage().queries[_queryId].request;
    }   

    /// Gets the Witnet.Result part of a given query.
    function __response(uint256 _queryId)
      internal view
      returns (Witnet.Response storage)
    {
        return __storage().queries[_queryId].response;
    }

    /// Returns storage pointer to contents of 'WitnetBoardState' struct.
    function __storage()
      internal pure
      returns (WitnetBoardState storage _ptr)
    {
        assembly {
            _ptr.slot := _WITNET_BOARD_DATA_SLOTHASH
        }
    }

    /// Gets current status of given query.
    function _statusOf(uint256 _queryId)
      virtual internal view
      returns (Witnet.QueryStatus)
    {
      Witnet.Query storage _query = __storage().queries[_queryId];
      if (_query.response.drTxHash != 0) {
        // Query is in "Reported" status as soon as the hash of the
        // Witnet transaction that solved the query is reported
        // back from a Witnet bridge:
        return Witnet.QueryStatus.Reported;
      }
      else if (_query.from != address(0)) {
        // Otherwise, while address from which the query was posted
        // is kept in storage, the query remains in "Posted" status:
        return Witnet.QueryStatus.Posted;
      }
      else if (_queryId > __storage().numQueries) {
        // Requester's address is removed from storage only if
        // the query gets "Deleted" by its requester.
        return Witnet.QueryStatus.Deleted;
      } else {
        return Witnet.QueryStatus.Unknown;
      }
    }

    function _statusOfRevertMessage(Witnet.QueryStatus _status)
      internal pure
      returns (string memory)
    {
      if (_status == Witnet.QueryStatus.Posted) {
        return "WitnetRequestBoard: not in Posted status";
      } else if (_status == Witnet.QueryStatus.Reported) {
        return "WitnetRequestBoard: not in Reported status";
      } else if (_status == Witnet.QueryStatus.Deleted) {
        return "WitnetRequestBoard: not in Deleted status";
      } else {
        return "WitnetRequestBoard: bad mood";
      }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./interfaces/V2/IWitnetRequestFactory.sol";

abstract contract WitnetRequestFactory
    is
        IWitnetRequestFactory
{}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./WitnetBytecodes.sol";
import "./WitnetRequestFactory.sol";

import "./interfaces/IWitnetRequestBoardEvents.sol";
import "./interfaces/IWitnetRequestBoardReporter.sol";
import "./interfaces/IWitnetRequestBoardRequestor.sol";
import "./interfaces/IWitnetRequestBoardView.sol";

import "./interfaces/IWitnetRequestBoardDeprecating.sol";

/// @title Witnet Request Board functionality base contract.
/// @author The Witnet Foundation.
abstract contract WitnetRequestBoard is
    IWitnetRequestBoardDeprecating,
    IWitnetRequestBoardEvents,
    IWitnetRequestBoardReporter,
    IWitnetRequestBoardRequestor,
    IWitnetRequestBoardView
{
    WitnetRequestFactory immutable public factory;
    WitnetBytecodes immutable public registry;
    constructor (WitnetRequestFactory _factory) {
        require(
            _factory.class() == type(WitnetRequestFactory).interfaceId,
            "WitnetRequestBoard: uncompliant factory"
        );
        factory = _factory;
        registry = _factory.registry();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./interfaces/V2/IWitnetBytecodes.sol";
import "./interfaces/V2/IWitnetBytecodesErrors.sol";
import "./interfaces/V2/IWitnetBytecodesEvents.sol";

abstract contract WitnetBytecodes
    is
        IWitnetBytecodes,
        IWitnetBytecodesErrors,
        IWitnetBytecodesEvents
{}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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