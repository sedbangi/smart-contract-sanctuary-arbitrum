// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// solhint-disable avoid-low-level-calls
// solhint-disable no-inline-assembly

// WARNING!!!
// Combining BoringBatchable with msg.value can cause double spending issues
// https://www.paradigm.xyz/2021/08/two-rights-might-make-a-wrong/

import "./interfaces/IERC20.sol";

contract BaseBoringBatchable {
    /// @dev Helper function to extract a useful revert message from a failed call.
    /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    /// @notice Allows batched call to self (this contract).
    /// @param calls An array of inputs for each call.
    /// @param revertOnFail If True then reverts after a failed call and stops doing further calls.
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // F2: Calls in the batch may be payable, delegatecall operates in the same context, so each call in the batch has access to msg.value
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is only used on the same contract, so it's safe
    function batch(bytes[] calldata calls, bool revertOnFail) external payable {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            if (!success && revertOnFail) {
                revert(_getRevertMsg(result));
            }
        }
    }
}

contract BoringBatchable is BaseBoringBatchable {
    /// @notice Call wrapper that performs `ERC20.permit` on `token`.
    /// Lookup `IERC20.permit`.
    // F6: Parameters can be used front-run the permit and the user's permit will fail (due to nonce or other revert)
    //     if part of a batch this could be used to grief once as the second call would not need the permit
    function permitToken(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        token.permit(from, to, amount, deadline, v, r, s);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: LZBL-1.2

pragma solidity ^0.8.20;

import { BytesLib } from "solidity-bytes-utils/contracts/BytesLib.sol";

import { BitMap256 } from "@layerzerolabs/lz-evm-protocol-v2/contracts/messagelib/libs/BitMaps.sol";
import { CalldataBytesLib } from "@layerzerolabs/lz-evm-protocol-v2/contracts/libs/CalldataBytesLib.sol";

library DVNOptions {
    using CalldataBytesLib for bytes;
    using BytesLib for bytes;

    uint8 internal constant WORKER_ID = 2;
    uint8 internal constant OPTION_TYPE_PRECRIME = 1;

    error DVN_InvalidDVNIdx();
    error DVN_InvalidDVNOptions(uint256 cursor);

    /// @dev group dvn options by its idx
    /// @param _options [dvn_id][dvn_option][dvn_id][dvn_option]...
    ///        dvn_option = [option_size][dvn_idx][option_type][option]
    ///        option_size = len(dvn_idx) + len(option_type) + len(option)
    ///        dvn_id: uint8, dvn_idx: uint8, option_size: uint16, option_type: uint8, option: bytes
    /// @return dvnOptions the grouped options, still share the same format of _options
    /// @return dvnIndices the dvn indices
    function groupDVNOptionsByIdx(
        bytes memory _options
    ) internal pure returns (bytes[] memory dvnOptions, uint8[] memory dvnIndices) {
        if (_options.length == 0) return (dvnOptions, dvnIndices);

        uint8 numDVNs = getNumDVNs(_options);

        // if there is only 1 dvn, we can just return the whole options
        if (numDVNs == 1) {
            dvnOptions = new bytes[](1);
            dvnOptions[0] = _options;

            dvnIndices = new uint8[](1);
            dvnIndices[0] = _options.toUint8(3); // dvn idx
            return (dvnOptions, dvnIndices);
        }

        // otherwise, we need to group the options by dvn_idx
        dvnIndices = new uint8[](numDVNs);
        dvnOptions = new bytes[](numDVNs);
        unchecked {
            uint256 cursor = 0;
            uint256 start = 0;
            uint8 lastDVNIdx = 255; // 255 is an invalid dvn_idx

            while (cursor < _options.length) {
                ++cursor; // skip worker_id

                // optionLength asserted in getNumDVNs (skip check)
                uint16 optionLength = _options.toUint16(cursor);
                cursor += 2;

                // dvnIdx asserted in getNumDVNs (skip check)
                uint8 dvnIdx = _options.toUint8(cursor);

                // dvnIdx must equal to the lastDVNIdx for the first option
                // so it is always skipped in the first option
                // this operation slices out options whenever the scan finds a different lastDVNIdx
                if (lastDVNIdx == 255) {
                    lastDVNIdx = dvnIdx;
                } else if (dvnIdx != lastDVNIdx) {
                    uint256 len = cursor - start - 3; // 3 is for worker_id and option_length
                    bytes memory opt = _options.slice(start, len);
                    _insertDVNOptions(dvnOptions, dvnIndices, lastDVNIdx, opt);

                    // reset the start and lastDVNIdx
                    start += len;
                    lastDVNIdx = dvnIdx;
                }

                cursor += optionLength;
            }

            // skip check the cursor here because the cursor is asserted in getNumDVNs
            // if we have reached the end of the options, we need to process the last dvn
            uint256 size = cursor - start;
            bytes memory op = _options.slice(start, size);
            _insertDVNOptions(dvnOptions, dvnIndices, lastDVNIdx, op);

            // revert dvnIndices to start from 0
            for (uint8 i = 0; i < numDVNs; ++i) {
                --dvnIndices[i];
            }
        }
    }

    function _insertDVNOptions(
        bytes[] memory _dvnOptions,
        uint8[] memory _dvnIndices,
        uint8 _dvnIdx,
        bytes memory _newOptions
    ) internal pure {
        // dvnIdx starts from 0 but default value of dvnIndices is 0,
        // so we tell if the slot is empty by adding 1 to dvnIdx
        if (_dvnIdx == 255) revert DVN_InvalidDVNIdx();
        uint8 dvnIdxAdj = _dvnIdx + 1;

        for (uint256 j = 0; j < _dvnIndices.length; ++j) {
            uint8 index = _dvnIndices[j];
            if (dvnIdxAdj == index) {
                _dvnOptions[j] = abi.encodePacked(_dvnOptions[j], _newOptions);
                break;
            } else if (index == 0) {
                // empty slot, that means it is the first time we see this dvn
                _dvnIndices[j] = dvnIdxAdj;
                _dvnOptions[j] = _newOptions;
                break;
            }
        }
    }

    /// @dev get the number of unique dvns
    /// @param _options the format is the same as groupDVNOptionsByIdx
    function getNumDVNs(bytes memory _options) internal pure returns (uint8 numDVNs) {
        uint256 cursor = 0;
        BitMap256 bitmap;

        // find number of unique dvn_idx
        unchecked {
            while (cursor < _options.length) {
                ++cursor; // skip worker_id

                uint16 optionLength = _options.toUint16(cursor);
                cursor += 2;
                if (optionLength < 2) revert DVN_InvalidDVNOptions(cursor); // at least 1 byte for dvn_idx and 1 byte for option_type

                uint8 dvnIdx = _options.toUint8(cursor);

                // if dvnIdx is not set, increment numDVNs
                // max num of dvns is 255, 255 is an invalid dvn_idx
                // The order of the dvnIdx is not required to be sequential, as enforcing the order may weaken
                // the composability of the options. e.g. if we refrain from enforcing the order, an OApp that has
                // already enforced certain options can append additional options to the end of the enforced
                // ones without restrictions.
                if (dvnIdx == 255) revert DVN_InvalidDVNIdx();
                if (!bitmap.get(dvnIdx)) {
                    ++numDVNs;
                    bitmap = bitmap.set(dvnIdx);
                }

                cursor += optionLength;
            }
        }
        if (cursor != _options.length) revert DVN_InvalidDVNOptions(cursor);
    }

    /// @dev decode the next dvn option from _options starting from the specified cursor
    /// @param _options the format is the same as groupDVNOptionsByIdx
    /// @param _cursor the cursor to start decoding
    /// @return optionType the type of the option
    /// @return option the option
    /// @return cursor the cursor to start decoding the next option
    function nextDVNOption(
        bytes calldata _options,
        uint256 _cursor
    ) internal pure returns (uint8 optionType, bytes calldata option, uint256 cursor) {
        unchecked {
            // skip worker id
            cursor = _cursor + 1;

            // read option size
            uint16 size = _options.toU16(cursor);
            cursor += 2;

            // read option type
            optionType = _options.toU8(cursor + 1); // skip dvn_idx

            // startCursor and endCursor are used to slice the option from _options
            uint256 startCursor = cursor + 2; // skip option type and dvn_idx
            uint256 endCursor = cursor + size;
            option = _options[startCursor:endCursor];
            cursor += size;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { ILayerZeroComposer } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroComposer.sol";

/**
 * @title IOAppComposer
 * @dev This interface defines the OApp Composer, allowing developers to inherit only the OApp package without the protocol.
 */
// solhint-disable-next-line no-empty-blocks
interface IOAppComposer is ILayerZeroComposer {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { ILayerZeroEndpointV2 } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

/**
 * @title IOAppCore
 */
interface IOAppCore {
    // Custom error messages
    error OnlyPeer(uint32 eid, bytes32 sender);
    error NoPeer(uint32 eid);
    error InvalidEndpointCall();
    error InvalidDelegate();

    // Event emitted when a peer (OApp) is set for a corresponding endpoint
    event PeerSet(uint32 eid, bytes32 peer);

    /**
     * @notice Retrieves the OApp version information.
     * @return senderVersion The version of the OAppSender.sol contract.
     * @return receiverVersion The version of the OAppReceiver.sol contract.
     */
    function oAppVersion() external view returns (uint64 senderVersion, uint64 receiverVersion);

    /**
     * @notice Retrieves the LayerZero endpoint associated with the OApp.
     * @return iEndpoint The LayerZero endpoint as an interface.
     */
    function endpoint() external view returns (ILayerZeroEndpointV2 iEndpoint);

    /**
     * @notice Retrieves the peer (OApp) associated with a corresponding endpoint.
     * @param _eid The endpoint ID.
     * @return peer The peer address (OApp instance) associated with the corresponding endpoint.
     */
    function peers(uint32 _eid) external view returns (bytes32 peer);

    /**
     * @notice Sets the peer address (OApp instance) for a corresponding endpoint.
     * @param _eid The endpoint ID.
     * @param _peer The address of the peer to be associated with the corresponding endpoint.
     */
    function setPeer(uint32 _eid, bytes32 _peer) external;

    /**
     * @notice Sets the delegate address for the OApp Core.
     * @param _delegate The address of the delegate to be set.
     */
    function setDelegate(address _delegate) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title IOAppMsgInspector
 * @dev Interface for the OApp Message Inspector, allowing examination of message and options contents.
 */
interface IOAppMsgInspector {
    // Custom error message for inspection failure
    error InspectionFailed(bytes message, bytes options);

    /**
     * @notice Allows the inspector to examine LayerZero message contents and optionally throw a revert if invalid.
     * @param _message The message payload to be inspected.
     * @param _options Additional options or parameters for inspection.
     * @return valid A boolean indicating whether the inspection passed (true) or failed (false).
     *
     * @dev Optionally done as a revert, OR use the boolean provided to handle the failure.
     */
    function inspect(bytes calldata _message, bytes calldata _options) external view returns (bool valid);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @dev Struct representing enforced option parameters.
 */
struct EnforcedOptionParam {
    uint32 eid; // Endpoint ID
    uint16 msgType; // Message Type
    bytes options; // Additional options
}

/**
 * @title IOAppOptionsType3
 * @dev Interface for the OApp with Type 3 Options, allowing the setting and combining of enforced options.
 */
interface IOAppOptionsType3 {
    // Custom error message for invalid options
    error InvalidOptions(bytes options);

    // Event emitted when enforced options are set
    event EnforcedOptionSet(EnforcedOptionParam[] _enforcedOptions);

    /**
     * @notice Sets enforced options for specific endpoint and message type combinations.
     * @param _enforcedOptions An array of EnforcedOptionParam structures specifying enforced options.
     */
    function setEnforcedOptions(EnforcedOptionParam[] calldata _enforcedOptions) external;

    /**
     * @notice Combines options for a given endpoint and message type.
     * @param _eid The endpoint ID.
     * @param _msgType The OApp message type.
     * @param _extraOptions Additional options passed by the caller.
     * @return options The combination of caller specified options AND enforced options.
     */
    function combineOptions(
        uint32 _eid,
        uint16 _msgType,
        bytes calldata _extraOptions
    ) external view returns (bytes memory options);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ILayerZeroReceiver, Origin } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroReceiver.sol";

interface IOAppReceiver is ILayerZeroReceiver {
    /**
     * @notice Indicates whether an address is an approved composeMsg sender to the Endpoint.
     * @param _origin The origin information containing the source endpoint and sender address.
     *  - srcEid: The source chain endpoint ID.
     *  - sender: The sender address on the src chain.
     *  - nonce: The nonce of the message.
     * @param _message The lzReceive payload.
     * @param _sender The sender address.
     * @return isSender Is a valid sender.
     *
     * @dev Applications can optionally choose to implement a separate composeMsg sender that is NOT the bridging layer.
     * @dev The default sender IS the OAppReceiver implementer.
     */
    function isComposeMsgSender(
        Origin calldata _origin,
        bytes calldata _message,
        address _sender
    ) external view returns (bool isSender);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IOAppOptionsType3, EnforcedOptionParam } from "../interfaces/IOAppOptionsType3.sol";

/**
 * @title OAppOptionsType3
 * @dev Abstract contract implementing the IOAppOptionsType3 interface with type 3 options.
 */
abstract contract OAppOptionsType3 is IOAppOptionsType3, Ownable {
    uint16 internal constant OPTION_TYPE_3 = 3;

    // @dev The "msgType" should be defined in the child contract.
    mapping(uint32 eid => mapping(uint16 msgType => bytes enforcedOption)) public enforcedOptions;

    /**
     * @dev Sets the enforced options for specific endpoint and message type combinations.
     * @param _enforcedOptions An array of EnforcedOptionParam structures specifying enforced options.
     *
     * @dev Only the owner/admin of the OApp can call this function.
     * @dev Provides a way for the OApp to enforce things like paying for PreCrime, AND/OR minimum dst lzReceive gas amounts etc.
     * @dev These enforced options can vary as the potential options/execution on the remote may differ as per the msgType.
     * eg. Amount of lzReceive() gas necessary to deliver a lzCompose() message adds overhead you dont want to pay
     * if you are only making a standard LayerZero message ie. lzReceive() WITHOUT sendCompose().
     */
    function setEnforcedOptions(EnforcedOptionParam[] calldata _enforcedOptions) public virtual onlyOwner {
        _setEnforcedOptions(_enforcedOptions);
    }

    /**
     * @dev Sets the enforced options for specific endpoint and message type combinations.
     * @param _enforcedOptions An array of EnforcedOptionParam structures specifying enforced options.
     *
     * @dev Provides a way for the OApp to enforce things like paying for PreCrime, AND/OR minimum dst lzReceive gas amounts etc.
     * @dev These enforced options can vary as the potential options/execution on the remote may differ as per the msgType.
     * eg. Amount of lzReceive() gas necessary to deliver a lzCompose() message adds overhead you dont want to pay
     * if you are only making a standard LayerZero message ie. lzReceive() WITHOUT sendCompose().
     */
    function _setEnforcedOptions(EnforcedOptionParam[] memory _enforcedOptions) internal virtual {
        for (uint256 i = 0; i < _enforcedOptions.length; i++) {
            // @dev Enforced options are only available for optionType 3, as type 1 and 2 dont support combining.
            _assertOptionsType3(_enforcedOptions[i].options);
            enforcedOptions[_enforcedOptions[i].eid][_enforcedOptions[i].msgType] = _enforcedOptions[i].options;
        }

        emit EnforcedOptionSet(_enforcedOptions);
    }

    /**
     * @notice Combines options for a given endpoint and message type.
     * @param _eid The endpoint ID.
     * @param _msgType The OAPP message type.
     * @param _extraOptions Additional options passed by the caller.
     * @return options The combination of caller specified options AND enforced options.
     *
     * @dev If there is an enforced lzReceive option:
     * - {gasLimit: 200k, msg.value: 1 ether} AND a caller supplies a lzReceive option: {gasLimit: 100k, msg.value: 0.5 ether}
     * - The resulting options will be {gasLimit: 300k, msg.value: 1.5 ether} when the message is executed on the remote lzReceive() function.
     * @dev This presence of duplicated options is handled off-chain in the verifier/executor.
     */
    function combineOptions(
        uint32 _eid,
        uint16 _msgType,
        bytes calldata _extraOptions
    ) public view virtual returns (bytes memory) {
        bytes memory enforced = enforcedOptions[_eid][_msgType];

        // No enforced options, pass whatever the caller supplied, even if it's empty or legacy type 1/2 options.
        if (enforced.length == 0) return _extraOptions;

        // No caller options, return enforced
        if (_extraOptions.length == 0) return enforced;

        // @dev If caller provided _extraOptions, must be type 3 as its the ONLY type that can be combined.
        if (_extraOptions.length >= 2) {
            _assertOptionsType3(_extraOptions);
            // @dev Remove the first 2 bytes containing the type from the _extraOptions and combine with enforced.
            return bytes.concat(enforced, _extraOptions[2:]);
        }

        // No valid set of options was found.
        revert InvalidOptions(_extraOptions);
    }

    /**
     * @dev Internal function to assert that options are of type 3.
     * @param _options The options to be checked.
     */
    function _assertOptionsType3(bytes memory _options) internal pure virtual {
        uint16 optionsType;
        assembly {
            optionsType := mload(add(_options, 2))
        }
        if (optionsType != OPTION_TYPE_3) revert InvalidOptions(_options);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { BytesLib } from "solidity-bytes-utils/contracts/BytesLib.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { ExecutorOptions } from "@layerzerolabs/lz-evm-protocol-v2/contracts/messagelib/libs/ExecutorOptions.sol";
import { DVNOptions } from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/libs/DVNOptions.sol";

/**
 * @title OptionsBuilder
 * @dev Library for building and encoding various message options.
 */
library OptionsBuilder {
    using SafeCast for uint256;
    using BytesLib for bytes;

    // Constants for options types
    uint16 internal constant TYPE_1 = 1; // legacy options type 1
    uint16 internal constant TYPE_2 = 2; // legacy options type 2
    uint16 internal constant TYPE_3 = 3;

    // Custom error message
    error InvalidSize(uint256 max, uint256 actual);
    error InvalidOptionType(uint16 optionType);

    // Modifier to ensure only options of type 3 are used
    modifier onlyType3(bytes memory _options) {
        if (_options.toUint16(0) != TYPE_3) revert InvalidOptionType(_options.toUint16(0));
        _;
    }

    /**
     * @dev Creates a new options container with type 3.
     * @return options The newly created options container.
     */
    function newOptions() internal pure returns (bytes memory) {
        return abi.encodePacked(TYPE_3);
    }

    /**
     * @dev Adds an executor LZ receive option to the existing options.
     * @param _options The existing options container.
     * @param _gas The gasLimit used on the lzReceive() function in the OApp.
     * @param _value The msg.value passed to the lzReceive() function in the OApp.
     * @return options The updated options container.
     *
     * @dev When multiples of this option are added, they are summed by the executor
     * eg. if (_gas: 200k, and _value: 1 ether) AND (_gas: 100k, _value: 0.5 ether) are sent in an option to the LayerZeroEndpoint,
     * that becomes (300k, 1.5 ether) when the message is executed on the remote lzReceive() function.
     */
    function addExecutorLzReceiveOption(
        bytes memory _options,
        uint128 _gas,
        uint128 _value
    ) internal pure onlyType3(_options) returns (bytes memory) {
        bytes memory option = ExecutorOptions.encodeLzReceiveOption(_gas, _value);
        return addExecutorOption(_options, ExecutorOptions.OPTION_TYPE_LZRECEIVE, option);
    }

    /**
     * @dev Adds an executor native drop option to the existing options.
     * @param _options The existing options container.
     * @param _amount The amount for the native value that is airdropped to the 'receiver'.
     * @param _receiver The receiver address for the native drop option.
     * @return options The updated options container.
     *
     * @dev When multiples of this option are added, they are summed by the executor on the remote chain.
     */
    function addExecutorNativeDropOption(
        bytes memory _options,
        uint128 _amount,
        bytes32 _receiver
    ) internal pure onlyType3(_options) returns (bytes memory) {
        bytes memory option = ExecutorOptions.encodeNativeDropOption(_amount, _receiver);
        return addExecutorOption(_options, ExecutorOptions.OPTION_TYPE_NATIVE_DROP, option);
    }

    /**
     * @dev Adds an executor LZ compose option to the existing options.
     * @param _options The existing options container.
     * @param _index The index for the lzCompose() function call.
     * @param _gas The gasLimit for the lzCompose() function call.
     * @param _value The msg.value for the lzCompose() function call.
     * @return options The updated options container.
     *
     * @dev When multiples of this option are added, they are summed PER index by the executor on the remote chain.
     * @dev If the OApp sends N lzCompose calls on the remote, you must provide N incremented indexes starting with 0.
     * ie. When your remote OApp composes (N = 3) messages, you must set this option for index 0,1,2
     */
    function addExecutorLzComposeOption(
        bytes memory _options,
        uint16 _index,
        uint128 _gas,
        uint128 _value
    ) internal pure onlyType3(_options) returns (bytes memory) {
        bytes memory option = ExecutorOptions.encodeLzComposeOption(_index, _gas, _value);
        return addExecutorOption(_options, ExecutorOptions.OPTION_TYPE_LZCOMPOSE, option);
    }

    /**
     * @dev Adds an executor ordered execution option to the existing options.
     * @param _options The existing options container.
     * @return options The updated options container.
     */
    function addExecutorOrderedExecutionOption(
        bytes memory _options
    ) internal pure onlyType3(_options) returns (bytes memory) {
        return addExecutorOption(_options, ExecutorOptions.OPTION_TYPE_ORDERED_EXECUTION, bytes(""));
    }

    /**
     * @dev Adds a DVN pre-crime option to the existing options.
     * @param _options The existing options container.
     * @param _dvnIdx The DVN index for the pre-crime option.
     * @return options The updated options container.
     */
    function addDVNPreCrimeOption(
        bytes memory _options,
        uint8 _dvnIdx
    ) internal pure onlyType3(_options) returns (bytes memory) {
        return addDVNOption(_options, _dvnIdx, DVNOptions.OPTION_TYPE_PRECRIME, bytes(""));
    }

    /**
     * @dev Adds an executor option to the existing options.
     * @param _options The existing options container.
     * @param _optionType The type of the executor option.
     * @param _option The encoded data for the executor option.
     * @return options The updated options container.
     */
    function addExecutorOption(
        bytes memory _options,
        uint8 _optionType,
        bytes memory _option
    ) internal pure onlyType3(_options) returns (bytes memory) {
        return
            abi.encodePacked(
                _options,
                ExecutorOptions.WORKER_ID,
                _option.length.toUint16() + 1, // +1 for optionType
                _optionType,
                _option
            );
    }

    /**
     * @dev Adds a DVN option to the existing options.
     * @param _options The existing options container.
     * @param _dvnIdx The DVN index for the DVN option.
     * @param _optionType The type of the DVN option.
     * @param _option The encoded data for the DVN option.
     * @return options The updated options container.
     */
    function addDVNOption(
        bytes memory _options,
        uint8 _dvnIdx,
        uint8 _optionType,
        bytes memory _option
    ) internal pure onlyType3(_options) returns (bytes memory) {
        return
            abi.encodePacked(
                _options,
                DVNOptions.WORKER_ID,
                _option.length.toUint16() + 2, // +2 for optionType and dvnIdx
                _dvnIdx,
                _optionType,
                _option
            );
    }

    /**
     * @dev Encodes legacy options of type 1.
     * @param _executionGas The gasLimit value passed to lzReceive().
     * @return legacyOptions The encoded legacy options.
     */
    function encodeLegacyOptionsType1(uint256 _executionGas) internal pure returns (bytes memory) {
        if (_executionGas > type(uint128).max) revert InvalidSize(type(uint128).max, _executionGas);
        return abi.encodePacked(TYPE_1, _executionGas);
    }

    /**
     * @dev Encodes legacy options of type 2.
     * @param _executionGas The gasLimit value passed to lzReceive().
     * @param _nativeForDst The amount of native air dropped to the receiver.
     * @param _receiver The _nativeForDst receiver address.
     * @return legacyOptions The encoded legacy options of type 2.
     */
    function encodeLegacyOptionsType2(
        uint256 _executionGas,
        uint256 _nativeForDst,
        bytes memory _receiver // @dev Use bytes instead of bytes32 in legacy type 2 for _receiver.
    ) internal pure returns (bytes memory) {
        if (_executionGas > type(uint128).max) revert InvalidSize(type(uint128).max, _executionGas);
        if (_nativeForDst > type(uint128).max) revert InvalidSize(type(uint128).max, _nativeForDst);
        if (_receiver.length > 32) revert InvalidSize(32, _receiver.length);
        return abi.encodePacked(TYPE_2, _executionGas, _nativeForDst, _receiver);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

// @dev Import the 'MessagingFee' and 'MessagingReceipt' so it's exposed to OApp implementers
// solhint-disable-next-line no-unused-import
import { OAppSender, MessagingFee, MessagingReceipt } from "./OAppSender.sol";
// @dev Import the 'Origin' so it's exposed to OApp implementers
// solhint-disable-next-line no-unused-import
import { OAppReceiver, Origin } from "./OAppReceiver.sol";
import { OAppCore } from "./OAppCore.sol";

/**
 * @title OApp
 * @dev Abstract contract serving as the base for OApp implementation, combining OAppSender and OAppReceiver functionality.
 */
abstract contract OApp is OAppSender, OAppReceiver {
    /**
     * @dev Constructor to initialize the OApp with the provided endpoint and owner.
     * @param _endpoint The address of the LOCAL LayerZero endpoint.
     * @param _delegate The delegate capable of making OApp configurations inside of the endpoint.
     */
    constructor(address _endpoint, address _delegate) OAppCore(_endpoint, _delegate) {}

    /**
     * @notice Retrieves the OApp version information.
     * @return senderVersion The version of the OAppSender.sol implementation.
     * @return receiverVersion The version of the OAppReceiver.sol implementation.
     */
    function oAppVersion()
        public
        pure
        virtual
        override(OAppSender, OAppReceiver)
        returns (uint64 senderVersion, uint64 receiverVersion)
    {
        return (SENDER_VERSION, RECEIVER_VERSION);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IOAppCore, ILayerZeroEndpointV2 } from "./interfaces/IOAppCore.sol";

/**
 * @title OAppCore
 * @dev Abstract contract implementing the IOAppCore interface with basic OApp configurations.
 */
abstract contract OAppCore is IOAppCore, Ownable {
    // The LayerZero endpoint associated with the given OApp
    ILayerZeroEndpointV2 public immutable endpoint;

    // Mapping to store peers associated with corresponding endpoints
    mapping(uint32 eid => bytes32 peer) public peers;

    /**
     * @dev Constructor to initialize the OAppCore with the provided endpoint and delegate.
     * @param _endpoint The address of the LOCAL Layer Zero endpoint.
     * @param _delegate The delegate capable of making OApp configurations inside of the endpoint.
     *
     * @dev The delegate typically should be set as the owner of the contract.
     */
    constructor(address _endpoint, address _delegate) {
        endpoint = ILayerZeroEndpointV2(_endpoint);

        if (_delegate == address(0)) revert InvalidDelegate();
        endpoint.setDelegate(_delegate);
    }

    /**
     * @notice Sets the peer address (OApp instance) for a corresponding endpoint.
     * @param _eid The endpoint ID.
     * @param _peer The address of the peer to be associated with the corresponding endpoint.
     *
     * @dev Only the owner/admin of the OApp can call this function.
     * @dev Indicates that the peer is trusted to send LayerZero messages to this OApp.
     * @dev Set this to bytes32(0) to remove the peer address.
     * @dev Peer is a bytes32 to accommodate non-evm chains.
     */
    function setPeer(uint32 _eid, bytes32 _peer) public virtual onlyOwner {
        _setPeer(_eid, _peer);
    }

    /**
     * @notice Sets the peer address (OApp instance) for a corresponding endpoint.
     * @param _eid The endpoint ID.
     * @param _peer The address of the peer to be associated with the corresponding endpoint.
     *
     * @dev Indicates that the peer is trusted to send LayerZero messages to this OApp.
     * @dev Set this to bytes32(0) to remove the peer address.
     * @dev Peer is a bytes32 to accommodate non-evm chains.
     */
    function _setPeer(uint32 _eid, bytes32 _peer) internal virtual {
        peers[_eid] = _peer;
        emit PeerSet(_eid, _peer);
    }

    /**
     * @notice Internal function to get the peer address associated with a specific endpoint; reverts if NOT set.
     * ie. the peer is set to bytes32(0).
     * @param _eid The endpoint ID.
     * @return peer The address of the peer associated with the specified endpoint.
     */
    function _getPeerOrRevert(uint32 _eid) internal view virtual returns (bytes32) {
        bytes32 peer = peers[_eid];
        if (peer == bytes32(0)) revert NoPeer(_eid);
        return peer;
    }

    /**
     * @notice Sets the delegate address for the OApp.
     * @param _delegate The address of the delegate to be set.
     *
     * @dev Only the owner/admin of the OApp can call this function.
     * @dev Provides the ability for a delegate to set configs, on behalf of the OApp, directly on the Endpoint contract.
     */
    function setDelegate(address _delegate) public onlyOwner {
        endpoint.setDelegate(_delegate);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { IOAppReceiver, Origin } from "./interfaces/IOAppReceiver.sol";
import { OAppCore } from "./OAppCore.sol";

/**
 * @title OAppReceiver
 * @dev Abstract contract implementing the ILayerZeroReceiver interface and extending OAppCore for OApp receivers.
 */
abstract contract OAppReceiver is IOAppReceiver, OAppCore {
    // Custom error message for when the caller is not the registered endpoint/
    error OnlyEndpoint(address addr);

    // @dev The version of the OAppReceiver implementation.
    // @dev Version is bumped when changes are made to this contract.
    uint64 internal constant RECEIVER_VERSION = 2;

    /**
     * @notice Retrieves the OApp version information.
     * @return senderVersion The version of the OAppSender.sol contract.
     * @return receiverVersion The version of the OAppReceiver.sol contract.
     *
     * @dev Providing 0 as the default for OAppSender version. Indicates that the OAppSender is not implemented.
     * ie. this is a RECEIVE only OApp.
     * @dev If the OApp uses both OAppSender and OAppReceiver, then this needs to be override returning the correct versions.
     */
    function oAppVersion() public view virtual returns (uint64 senderVersion, uint64 receiverVersion) {
        return (0, RECEIVER_VERSION);
    }

    /**
     * @notice Indicates whether an address is an approved composeMsg sender to the Endpoint.
     * @dev _origin The origin information containing the source endpoint and sender address.
     *  - srcEid: The source chain endpoint ID.
     *  - sender: The sender address on the src chain.
     *  - nonce: The nonce of the message.
     * @dev _message The lzReceive payload.
     * @param _sender The sender address.
     * @return isSender Is a valid sender.
     *
     * @dev Applications can optionally choose to implement separate composeMsg senders that are NOT the bridging layer.
     * @dev The default sender IS the OAppReceiver implementer.
     */
    function isComposeMsgSender(
        Origin calldata /*_origin*/,
        bytes calldata /*_message*/,
        address _sender
    ) public view virtual returns (bool) {
        return _sender == address(this);
    }

    /**
     * @notice Checks if the path initialization is allowed based on the provided origin.
     * @param origin The origin information containing the source endpoint and sender address.
     * @return Whether the path has been initialized.
     *
     * @dev This indicates to the endpoint that the OApp has enabled msgs for this particular path to be received.
     * @dev This defaults to assuming if a peer has been set, its initialized.
     * Can be overridden by the OApp if there is other logic to determine this.
     */
    function allowInitializePath(Origin calldata origin) public view virtual returns (bool) {
        return peers[origin.srcEid] == origin.sender;
    }

    /**
     * @notice Retrieves the next nonce for a given source endpoint and sender address.
     * @dev _srcEid The source endpoint ID.
     * @dev _sender The sender address.
     * @return nonce The next nonce.
     *
     * @dev The path nonce starts from 1. If 0 is returned it means that there is NO nonce ordered enforcement.
     * @dev Is required by the off-chain executor to determine the OApp expects msg execution is ordered.
     * @dev This is also enforced by the OApp.
     * @dev By default this is NOT enabled. ie. nextNonce is hardcoded to return 0.
     */
    function nextNonce(uint32 /*_srcEid*/, bytes32 /*_sender*/) public view virtual returns (uint64 nonce) {
        return 0;
    }

    /**
     * @dev Entry point for receiving messages or packets from the endpoint.
     * @param _origin The origin information containing the source endpoint and sender address.
     *  - srcEid: The source chain endpoint ID.
     *  - sender: The sender address on the src chain.
     *  - nonce: The nonce of the message.
     * @param _guid The unique identifier for the received LayerZero message.
     * @param _message The payload of the received message.
     * @param _executor The address of the executor for the received message.
     * @param _extraData Additional arbitrary data provided by the corresponding executor.
     *
     * @dev Entry point for receiving msg/packet from the LayerZero endpoint.
     */
    function lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) public payable virtual {
        // Ensures that only the endpoint can attempt to lzReceive() messages to this OApp.
        if (address(endpoint) != msg.sender) revert OnlyEndpoint(msg.sender);

        // Ensure that the sender matches the expected peer for the source endpoint.
        if (_getPeerOrRevert(_origin.srcEid) != _origin.sender) revert OnlyPeer(_origin.srcEid, _origin.sender);

        // Call the internal OApp implementation of lzReceive.
        _lzReceive(_origin, _guid, _message, _executor, _extraData);
    }

    /**
     * @dev Internal function to implement lzReceive logic without needing to copy the basic parameter validation.
     */
    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) internal virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { MessagingParams, MessagingFee, MessagingReceipt } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import { OAppCore } from "./OAppCore.sol";

/**
 * @title OAppSender
 * @dev Abstract contract implementing the OAppSender functionality for sending messages to a LayerZero endpoint.
 */
abstract contract OAppSender is OAppCore {
    using SafeERC20 for IERC20;

    // Custom error messages
    error NotEnoughNative(uint256 msgValue);
    error LzTokenUnavailable();

    // @dev The version of the OAppSender implementation.
    // @dev Version is bumped when changes are made to this contract.
    uint64 internal constant SENDER_VERSION = 1;

    /**
     * @notice Retrieves the OApp version information.
     * @return senderVersion The version of the OAppSender.sol contract.
     * @return receiverVersion The version of the OAppReceiver.sol contract.
     *
     * @dev Providing 0 as the default for OAppReceiver version. Indicates that the OAppReceiver is not implemented.
     * ie. this is a SEND only OApp.
     * @dev If the OApp uses both OAppSender and OAppReceiver, then this needs to be override returning the correct versions
     */
    function oAppVersion() public view virtual returns (uint64 senderVersion, uint64 receiverVersion) {
        return (SENDER_VERSION, 0);
    }

    /**
     * @dev Internal function to interact with the LayerZero EndpointV2.quote() for fee calculation.
     * @param _dstEid The destination endpoint ID.
     * @param _message The message payload.
     * @param _options Additional options for the message.
     * @param _payInLzToken Flag indicating whether to pay the fee in LZ tokens.
     * @return fee The calculated MessagingFee for the message.
     *      - nativeFee: The native fee for the message.
     *      - lzTokenFee: The LZ token fee for the message.
     */
    function _quote(
        uint32 _dstEid,
        bytes memory _message,
        bytes memory _options,
        bool _payInLzToken
    ) internal view virtual returns (MessagingFee memory fee) {
        return
            endpoint.quote(
                MessagingParams(_dstEid, _getPeerOrRevert(_dstEid), _message, _options, _payInLzToken),
                address(this)
            );
    }

    /**
     * @dev Internal function to interact with the LayerZero EndpointV2.send() for sending a message.
     * @param _dstEid The destination endpoint ID.
     * @param _message The message payload.
     * @param _options Additional options for the message.
     * @param _fee The calculated LayerZero fee for the message.
     *      - nativeFee: The native fee.
     *      - lzTokenFee: The lzToken fee.
     * @param _refundAddress The address to receive any excess fee values sent to the endpoint.
     * @return receipt The receipt for the sent message.
     *      - guid: The unique identifier for the sent message.
     *      - nonce: The nonce of the sent message.
     *      - fee: The LayerZero fee incurred for the message.
     */
    function _lzSend(
        uint32 _dstEid,
        bytes memory _message,
        bytes memory _options,
        MessagingFee memory _fee,
        address _refundAddress
    ) internal virtual returns (MessagingReceipt memory receipt) {
        // @dev Push corresponding fees to the endpoint, any excess is sent back to the _refundAddress from the endpoint.
        uint256 messageValue = _payNative(_fee.nativeFee);
        if (_fee.lzTokenFee > 0) _payLzToken(_fee.lzTokenFee);

        return
            // solhint-disable-next-line check-send-result
            endpoint.send{ value: messageValue }(
                MessagingParams(_dstEid, _getPeerOrRevert(_dstEid), _message, _options, _fee.lzTokenFee > 0),
                _refundAddress
            );
    }

    /**
     * @dev Internal function to pay the native fee associated with the message.
     * @param _nativeFee The native fee to be paid.
     * @return nativeFee The amount of native currency paid.
     *
     * @dev If the OApp needs to initiate MULTIPLE LayerZero messages in a single transaction,
     * this will need to be overridden because msg.value would contain multiple lzFees.
     * @dev Should be overridden in the event the LayerZero endpoint requires a different native currency.
     * @dev Some EVMs use an ERC20 as a method for paying transactions/gasFees.
     * @dev The endpoint is EITHER/OR, ie. it will NOT support both types of native payment at a time.
     */
    function _payNative(uint256 _nativeFee) internal virtual returns (uint256 nativeFee) {
        if (msg.value != _nativeFee) revert NotEnoughNative(msg.value);
        return _nativeFee;
    }

    /**
     * @dev Internal function to pay the LZ token fee associated with the message.
     * @param _lzTokenFee The LZ token fee to be paid.
     *
     * @dev If the caller is trying to pay in the specified lzToken, then the lzTokenFee is passed to the endpoint.
     * @dev Any excess sent, is passed back to the specified _refundAddress in the _lzSend().
     */
    function _payLzToken(uint256 _lzTokenFee) internal virtual {
        // @dev Cannot cache the token because it is not immutable in the endpoint.
        address lzToken = endpoint.lzToken();
        if (lzToken == address(0)) revert LzTokenUnavailable();

        // Pay LZ token fee by sending tokens to the endpoint.
        IERC20(lzToken).safeTransferFrom(msg.sender, address(endpoint), _lzTokenFee);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { MessagingReceipt, MessagingFee } from "../../oapp/OAppSender.sol";

/**
 * @dev Struct representing token parameters for the OFT send() operation.
 */
struct SendParam {
    uint32 dstEid; // Destination endpoint ID.
    bytes32 to; // Recipient address.
    uint256 amountLD; // Amount to send in local decimals.
    uint256 minAmountLD; // Minimum amount to send in local decimals.
    bytes extraOptions; // Additional options supplied by the caller to be used in the LayerZero message.
    bytes composeMsg; // The composed message for the send() operation.
    bytes oftCmd; // The OFT command to be executed, unused in default OFT implementations.
}

/**
 * @dev Struct representing OFT limit information.
 * @dev These amounts can change dynamically and are up the the specific oft implementation.
 */
struct OFTLimit {
    uint256 minAmountLD; // Minimum amount in local decimals that can be sent to the recipient.
    uint256 maxAmountLD; // Maximum amount in local decimals that can be sent to the recipient.
}

/**
 * @dev Struct representing OFT receipt information.
 */
struct OFTReceipt {
    uint256 amountSentLD; // Amount of tokens ACTUALLY debited from the sender in local decimals.
    // @dev In non-default implementations, the amountReceivedLD COULD differ from this value.
    uint256 amountReceivedLD; // Amount of tokens to be received on the remote side.
}

/**
 * @dev Struct representing OFT fee details.
 * @dev Future proof mechanism to provide a standardized way to communicate fees to things like a UI.
 */
struct OFTFeeDetail {
    int256 feeAmountLD; // Amount of the fee in local decimals.
    string description; // Description of the fee.
}

/**
 * @title IOFT
 * @dev Interface for the OftChain (OFT) token.
 * @dev Does not inherit ERC20 to accommodate usage by OFTAdapter as well.
 * @dev This specific interface ID is '0x02e49c2c'.
 */
interface IOFT {
    // Custom error messages
    error InvalidLocalDecimals();
    error SlippageExceeded(uint256 amountLD, uint256 minAmountLD);

    // Events
    event OFTSent(
        bytes32 indexed guid, // GUID of the OFT message.
        uint32 dstEid, // Destination Endpoint ID.
        address indexed fromAddress, // Address of the sender on the src chain.
        uint256 amountSentLD, // Amount of tokens sent in local decimals.
        uint256 amountReceivedLD // Amount of tokens received in local decimals.
    );
    event OFTReceived(
        bytes32 indexed guid, // GUID of the OFT message.
        uint32 srcEid, // Source Endpoint ID.
        address indexed toAddress, // Address of the recipient on the dst chain.
        uint256 amountReceivedLD // Amount of tokens received in local decimals.
    );

    /**
     * @notice Retrieves interfaceID and the version of the OFT.
     * @return interfaceId The interface ID.
     * @return version The version.
     *
     * @dev interfaceId: This specific interface ID is '0x02e49c2c'.
     * @dev version: Indicates a cross-chain compatible msg encoding with other OFTs.
     * @dev If a new feature is added to the OFT cross-chain msg encoding, the version will be incremented.
     * ie. localOFT version(x,1) CAN send messages to remoteOFT version(x,1)
     */
    function oftVersion() external view returns (bytes4 interfaceId, uint64 version);

    /**
     * @notice Retrieves the address of the token associated with the OFT.
     * @return token The address of the ERC20 token implementation.
     */
    function token() external view returns (address);

    /**
     * @notice Indicates whether the OFT contract requires approval of the 'token()' to send.
     * @return requiresApproval Needs approval of the underlying token implementation.
     *
     * @dev Allows things like wallet implementers to determine integration requirements,
     * without understanding the underlying token implementation.
     */
    function approvalRequired() external view returns (bool);

    /**
     * @notice Retrieves the shared decimals of the OFT.
     * @return sharedDecimals The shared decimals of the OFT.
     */
    function sharedDecimals() external view returns (uint8);

    /**
     * @notice Provides a quote for OFT-related operations.
     * @param _sendParam The parameters for the send operation.
     * @return limit The OFT limit information.
     * @return oftFeeDetails The details of OFT fees.
     * @return receipt The OFT receipt information.
     */
    function quoteOFT(
        SendParam calldata _sendParam
    ) external view returns (OFTLimit memory, OFTFeeDetail[] memory oftFeeDetails, OFTReceipt memory);

    /**
     * @notice Provides a quote for the send() operation.
     * @param _sendParam The parameters for the send() operation.
     * @param _payInLzToken Flag indicating whether the caller is paying in the LZ token.
     * @return fee The calculated LayerZero messaging fee from the send() operation.
     *
     * @dev MessagingFee: LayerZero msg fee
     *  - nativeFee: The native fee.
     *  - lzTokenFee: The lzToken fee.
     */
    function quoteSend(SendParam calldata _sendParam, bool _payInLzToken) external view returns (MessagingFee memory);

    /**
     * @notice Executes the send() operation.
     * @param _sendParam The parameters for the send operation.
     * @param _fee The fee information supplied by the caller.
     *      - nativeFee: The native fee.
     *      - lzTokenFee: The lzToken fee.
     * @param _refundAddress The address to receive any excess funds from fees etc. on the src.
     * @return receipt The LayerZero messaging receipt from the send() operation.
     * @return oftReceipt The OFT receipt information.
     *
     * @dev MessagingReceipt: LayerZero msg receipt
     *  - guid: The unique identifier for the sent message.
     *  - nonce: The nonce of the sent message.
     *  - fee: The LayerZero fee incurred for the message.
     */
    function send(
        SendParam calldata _sendParam,
        MessagingFee calldata _fee,
        address _refundAddress
    ) external payable returns (MessagingReceipt memory, OFTReceipt memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

library OFTComposeMsgCodec {
    // Offset constants for decoding composed messages
    uint8 private constant NONCE_OFFSET = 8;
    uint8 private constant SRC_EID_OFFSET = 12;
    uint8 private constant AMOUNT_LD_OFFSET = 44;
    uint8 private constant COMPOSE_FROM_OFFSET = 76;

    /**
     * @dev Encodes a OFT composed message.
     * @param _nonce The nonce value.
     * @param _srcEid The source endpoint ID.
     * @param _amountLD The amount in local decimals.
     * @param _composeMsg The composed message.
     * @return _msg The encoded Composed message.
     */
    function encode(
        uint64 _nonce,
        uint32 _srcEid,
        uint256 _amountLD,
        bytes memory _composeMsg // 0x[composeFrom][composeMsg]
    ) internal pure returns (bytes memory _msg) {
        _msg = abi.encodePacked(_nonce, _srcEid, _amountLD, _composeMsg);
    }

    /**
     * @dev Retrieves the nonce from the composed message.
     * @param _msg The message.
     * @return The nonce value.
     */
    function nonce(bytes calldata _msg) internal pure returns (uint64) {
        return uint64(bytes8(_msg[:NONCE_OFFSET]));
    }

    /**
     * @dev Retrieves the source endpoint ID from the composed message.
     * @param _msg The message.
     * @return The source endpoint ID.
     */
    function srcEid(bytes calldata _msg) internal pure returns (uint32) {
        return uint32(bytes4(_msg[NONCE_OFFSET:SRC_EID_OFFSET]));
    }

    /**
     * @dev Retrieves the amount in local decimals from the composed message.
     * @param _msg The message.
     * @return The amount in local decimals.
     */
    function amountLD(bytes calldata _msg) internal pure returns (uint256) {
        return uint256(bytes32(_msg[SRC_EID_OFFSET:AMOUNT_LD_OFFSET]));
    }

    /**
     * @dev Retrieves the composeFrom value from the composed message.
     * @param _msg The message.
     * @return The composeFrom value.
     */
    function composeFrom(bytes calldata _msg) internal pure returns (bytes32) {
        return bytes32(_msg[AMOUNT_LD_OFFSET:COMPOSE_FROM_OFFSET]);
    }

    /**
     * @dev Retrieves the composed message.
     * @param _msg The message.
     * @return The composed message.
     */
    function composeMsg(bytes calldata _msg) internal pure returns (bytes memory) {
        return _msg[COMPOSE_FROM_OFFSET:];
    }

    /**
     * @dev Converts an address to bytes32.
     * @param _addr The address to convert.
     * @return The bytes32 representation of the address.
     */
    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    /**
     * @dev Converts bytes32 to an address.
     * @param _b The bytes32 value to convert.
     * @return The address representation of bytes32.
     */
    function bytes32ToAddress(bytes32 _b) internal pure returns (address) {
        return address(uint160(uint256(_b)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

library OFTMsgCodec {
    // Offset constants for encoding and decoding OFT messages
    uint8 private constant SEND_TO_OFFSET = 32;
    uint8 private constant SEND_AMOUNT_SD_OFFSET = 40;

    /**
     * @dev Encodes an OFT LayerZero message.
     * @param _sendTo The recipient address.
     * @param _amountShared The amount in shared decimals.
     * @param _composeMsg The composed message.
     * @return _msg The encoded message.
     * @return hasCompose A boolean indicating whether the message has a composed payload.
     */
    function encode(
        bytes32 _sendTo,
        uint64 _amountShared,
        bytes memory _composeMsg
    ) internal view returns (bytes memory _msg, bool hasCompose) {
        hasCompose = _composeMsg.length > 0;
        // @dev Remote chains will want to know the composed function caller ie. msg.sender on the src.
        _msg = hasCompose
            ? abi.encodePacked(_sendTo, _amountShared, addressToBytes32(msg.sender), _composeMsg)
            : abi.encodePacked(_sendTo, _amountShared);
    }

    /**
     * @dev Checks if the OFT message is composed.
     * @param _msg The OFT message.
     * @return A boolean indicating whether the message is composed.
     */
    function isComposed(bytes calldata _msg) internal pure returns (bool) {
        return _msg.length > SEND_AMOUNT_SD_OFFSET;
    }

    /**
     * @dev Retrieves the recipient address from the OFT message.
     * @param _msg The OFT message.
     * @return The recipient address.
     */
    function sendTo(bytes calldata _msg) internal pure returns (bytes32) {
        return bytes32(_msg[:SEND_TO_OFFSET]);
    }

    /**
     * @dev Retrieves the amount in shared decimals from the OFT message.
     * @param _msg The OFT message.
     * @return The amount in shared decimals.
     */
    function amountSD(bytes calldata _msg) internal pure returns (uint64) {
        return uint64(bytes8(_msg[SEND_TO_OFFSET:SEND_AMOUNT_SD_OFFSET]));
    }

    /**
     * @dev Retrieves the composed message from the OFT message.
     * @param _msg The OFT message.
     * @return The composed message.
     */
    function composeMsg(bytes calldata _msg) internal pure returns (bytes memory) {
        return _msg[SEND_AMOUNT_SD_OFFSET:];
    }

    /**
     * @dev Converts an address to bytes32.
     * @param _addr The address to convert.
     * @return The bytes32 representation of the address.
     */
    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    /**
     * @dev Converts bytes32 to an address.
     * @param _b The bytes32 value to convert.
     * @return The address representation of bytes32.
     */
    function bytes32ToAddress(bytes32 _b) internal pure returns (address) {
        return address(uint160(uint256(_b)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IOFT, OFTCore } from "./OFTCore.sol";

/**
 * @title OFT Contract
 * @dev OFT is an ERC-20 token that extends the functionality of the OFTCore contract.
 */
abstract contract OFT is OFTCore, ERC20 {
    /**
     * @dev Constructor for the OFT contract.
     * @param _name The name of the OFT.
     * @param _symbol The symbol of the OFT.
     * @param _lzEndpoint The LayerZero endpoint address.
     * @param _delegate The delegate capable of making OApp configurations inside of the endpoint.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        address _delegate
    ) ERC20(_name, _symbol) OFTCore(decimals(), _lzEndpoint, _delegate) {}

    /**
     * @dev Retrieves the address of the underlying ERC20 implementation.
     * @return The address of the OFT token.
     *
     * @dev In the case of OFT, address(this) and erc20 are the same contract.
     */
    function token() public view returns (address) {
        return address(this);
    }

    /**
     * @notice Indicates whether the OFT contract requires approval of the 'token()' to send.
     * @return requiresApproval Needs approval of the underlying token implementation.
     *
     * @dev In the case of OFT where the contract IS the token, approval is NOT required.
     */
    function approvalRequired() external pure virtual returns (bool) {
        return false;
    }

    /**
     * @dev Burns tokens from the sender's specified balance.
     * @param _from The address to debit the tokens from.
     * @param _amountLD The amount of tokens to send in local decimals.
     * @param _minAmountLD The minimum amount to send in local decimals.
     * @param _dstEid The destination chain ID.
     * @return amountSentLD The amount sent in local decimals.
     * @return amountReceivedLD The amount received in local decimals on the remote.
     */
    function _debit(
        address _from,
        uint256 _amountLD,
        uint256 _minAmountLD,
        uint32 _dstEid
    ) internal virtual override returns (uint256 amountSentLD, uint256 amountReceivedLD) {
        (amountSentLD, amountReceivedLD) = _debitView(_amountLD, _minAmountLD, _dstEid);

        // @dev In NON-default OFT, amountSentLD could be 100, with a 10% fee, the amountReceivedLD amount is 90,
        // therefore amountSentLD CAN differ from amountReceivedLD.

        // @dev Default OFT burns on src.
        _burn(_from, amountSentLD);
    }

    /**
     * @dev Credits tokens to the specified address.
     * @param _to The address to credit the tokens to.
     * @param _amountLD The amount of tokens to credit in local decimals.
     * @dev _srcEid The source chain ID.
     * @return amountReceivedLD The amount of tokens ACTUALLY received in local decimals.
     */
    function _credit(
        address _to,
        uint256 _amountLD,
        uint32 /*_srcEid*/
    ) internal virtual override returns (uint256 amountReceivedLD) {
        // @dev Default OFT mints on dst.
        _mint(_to, _amountLD);
        // @dev In the case of NON-default OFT, the _amountLD MIGHT not be == amountReceivedLD.
        return _amountLD;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { OApp, Origin } from "../oapp/OApp.sol";
import { OAppOptionsType3 } from "../oapp/libs/OAppOptionsType3.sol";
import { IOAppMsgInspector } from "../oapp/interfaces/IOAppMsgInspector.sol";

import { OAppPreCrimeSimulator } from "../precrime/OAppPreCrimeSimulator.sol";

import { IOFT, SendParam, OFTLimit, OFTReceipt, OFTFeeDetail, MessagingReceipt, MessagingFee } from "./interfaces/IOFT.sol";
import { OFTMsgCodec } from "./libs/OFTMsgCodec.sol";
import { OFTComposeMsgCodec } from "./libs/OFTComposeMsgCodec.sol";

/**
 * @title OFTCore
 * @dev Abstract contract for the OftChain (OFT) token.
 */
abstract contract OFTCore is IOFT, OApp, OAppPreCrimeSimulator, OAppOptionsType3 {
    using OFTMsgCodec for bytes;
    using OFTMsgCodec for bytes32;

    // @notice Provides a conversion rate when swapping between denominations of SD and LD
    //      - shareDecimals == SD == shared Decimals
    //      - localDecimals == LD == local decimals
    // @dev Considers that tokens have different decimal amounts on various chains.
    // @dev eg.
    //  For a token
    //      - locally with 4 decimals --> 1.2345 => uint(12345)
    //      - remotely with 2 decimals --> 1.23 => uint(123)
    //      - The conversion rate would be 10 ** (4 - 2) = 100
    //  @dev If you want to send 1.2345 -> (uint 12345), you CANNOT represent that value on the remote,
    //  you can only display 1.23 -> uint(123).
    //  @dev To preserve the dust that would otherwise be lost on that conversion,
    //  we need to unify a denomination that can be represented on ALL chains inside of the OFT mesh
    uint256 public immutable decimalConversionRate;

    // @notice Msg types that are used to identify the various OFT operations.
    // @dev This can be extended in child contracts for non-default oft operations
    // @dev These values are used in things like combineOptions() in OAppOptionsType3.sol.
    uint16 public constant SEND = 1;
    uint16 public constant SEND_AND_CALL = 2;

    // Address of an optional contract to inspect both 'message' and 'options'
    address public msgInspector;
    event MsgInspectorSet(address inspector);

    /**
     * @dev Constructor.
     * @param _localDecimals The decimals of the token on the local chain (this chain).
     * @param _endpoint The address of the LayerZero endpoint.
     * @param _delegate The delegate capable of making OApp configurations inside of the endpoint.
     */
    constructor(uint8 _localDecimals, address _endpoint, address _delegate) OApp(_endpoint, _delegate) {
        if (_localDecimals < sharedDecimals()) revert InvalidLocalDecimals();
        decimalConversionRate = 10 ** (_localDecimals - sharedDecimals());
    }

    /**
     * @notice Retrieves interfaceID and the version of the OFT.
     * @return interfaceId The interface ID.
     * @return version The version.
     *
     * @dev interfaceId: This specific interface ID is '0x02e49c2c'.
     * @dev version: Indicates a cross-chain compatible msg encoding with other OFTs.
     * @dev If a new feature is added to the OFT cross-chain msg encoding, the version will be incremented.
     * ie. localOFT version(x,1) CAN send messages to remoteOFT version(x,1)
     */
    function oftVersion() external pure virtual returns (bytes4 interfaceId, uint64 version) {
        return (type(IOFT).interfaceId, 1);
    }

    /**
     * @dev Retrieves the shared decimals of the OFT.
     * @return The shared decimals of the OFT.
     *
     * @dev Sets an implicit cap on the amount of tokens, over uint64.max() will need some sort of outbound cap / totalSupply cap
     * Lowest common decimal denominator between chains.
     * Defaults to 6 decimal places to provide up to 18,446,744,073,709.551615 units (max uint64).
     * For tokens exceeding this totalSupply(), they will need to override the sharedDecimals function with something smaller.
     * ie. 4 sharedDecimals would be 1,844,674,407,370,955.1615
     */
    function sharedDecimals() public view virtual returns (uint8) {
        return 6;
    }

    /**
     * @dev Sets the message inspector address for the OFT.
     * @param _msgInspector The address of the message inspector.
     *
     * @dev This is an optional contract that can be used to inspect both 'message' and 'options'.
     * @dev Set it to address(0) to disable it, or set it to a contract address to enable it.
     */
    function setMsgInspector(address _msgInspector) public virtual onlyOwner {
        msgInspector = _msgInspector;
        emit MsgInspectorSet(_msgInspector);
    }

    /**
     * @notice Provides a quote for OFT-related operations.
     * @param _sendParam The parameters for the send operation.
     * @return oftLimit The OFT limit information.
     * @return oftFeeDetails The details of OFT fees.
     * @return oftReceipt The OFT receipt information.
     */
    function quoteOFT(
        SendParam calldata _sendParam
    )
        external
        view
        virtual
        returns (OFTLimit memory oftLimit, OFTFeeDetail[] memory oftFeeDetails, OFTReceipt memory oftReceipt)
    {
        uint256 minAmountLD = 0; // Unused in the default implementation.
        uint256 maxAmountLD = type(uint64).max; // Unused in the default implementation.
        oftLimit = OFTLimit(minAmountLD, maxAmountLD);

        // Unused in the default implementation; reserved for future complex fee details.
        oftFeeDetails = new OFTFeeDetail[](0);

        // @dev This is the same as the send() operation, but without the actual send.
        // - amountSentLD is the amount in local decimals that would be sent from the sender.
        // - amountReceivedLD is the amount in local decimals that will be credited to the recipient on the remote OFT instance.
        // @dev The amountSentLD MIGHT not equal the amount the user actually receives. HOWEVER, the default does.
        (uint256 amountSentLD, uint256 amountReceivedLD) = _debitView(
            _sendParam.amountLD,
            _sendParam.minAmountLD,
            _sendParam.dstEid
        );
        oftReceipt = OFTReceipt(amountSentLD, amountReceivedLD);
    }

    /**
     * @notice Provides a quote for the send() operation.
     * @param _sendParam The parameters for the send() operation.
     * @param _payInLzToken Flag indicating whether the caller is paying in the LZ token.
     * @return msgFee The calculated LayerZero messaging fee from the send() operation.
     *
     * @dev MessagingFee: LayerZero msg fee
     *  - nativeFee: The native fee.
     *  - lzTokenFee: The lzToken fee.
     */
    function quoteSend(
        SendParam calldata _sendParam,
        bool _payInLzToken
    ) external view virtual returns (MessagingFee memory msgFee) {
        // @dev mock the amount to receive, this is the same operation used in the send().
        // The quote is as similar as possible to the actual send() operation.
        (, uint256 amountReceivedLD) = _debitView(_sendParam.amountLD, _sendParam.minAmountLD, _sendParam.dstEid);

        // @dev Builds the options and OFT message to quote in the endpoint.
        (bytes memory message, bytes memory options) = _buildMsgAndOptions(_sendParam, amountReceivedLD);

        // @dev Calculates the LayerZero fee for the send() operation.
        return _quote(_sendParam.dstEid, message, options, _payInLzToken);
    }

    /**
     * @dev Executes the send operation.
     * @param _sendParam The parameters for the send operation.
     * @param _fee The calculated fee for the send() operation.
     *      - nativeFee: The native fee.
     *      - lzTokenFee: The lzToken fee.
     * @param _refundAddress The address to receive any excess funds.
     * @return msgReceipt The receipt for the send operation.
     * @return oftReceipt The OFT receipt information.
     *
     * @dev MessagingReceipt: LayerZero msg receipt
     *  - guid: The unique identifier for the sent message.
     *  - nonce: The nonce of the sent message.
     *  - fee: The LayerZero fee incurred for the message.
     */
    function send(
        SendParam calldata _sendParam,
        MessagingFee calldata _fee,
        address _refundAddress
    ) external payable virtual returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt) {
        // @dev Applies the token transfers regarding this send() operation.
        // - amountSentLD is the amount in local decimals that was ACTUALLY sent/debited from the sender.
        // - amountReceivedLD is the amount in local decimals that will be received/credited to the recipient on the remote OFT instance.
        (uint256 amountSentLD, uint256 amountReceivedLD) = _debit(
            msg.sender,
            _sendParam.amountLD,
            _sendParam.minAmountLD,
            _sendParam.dstEid
        );

        // @dev Builds the options and OFT message to quote in the endpoint.
        (bytes memory message, bytes memory options) = _buildMsgAndOptions(_sendParam, amountReceivedLD);

        // @dev Sends the message to the LayerZero endpoint and returns the LayerZero msg receipt.
        msgReceipt = _lzSend(_sendParam.dstEid, message, options, _fee, _refundAddress);
        // @dev Formulate the OFT receipt.
        oftReceipt = OFTReceipt(amountSentLD, amountReceivedLD);

        emit OFTSent(msgReceipt.guid, _sendParam.dstEid, msg.sender, amountSentLD, amountReceivedLD);
    }

    /**
     * @dev Internal function to build the message and options.
     * @param _sendParam The parameters for the send() operation.
     * @param _amountLD The amount in local decimals.
     * @return message The encoded message.
     * @return options The encoded options.
     */
    function _buildMsgAndOptions(
        SendParam calldata _sendParam,
        uint256 _amountLD
    ) internal view virtual returns (bytes memory message, bytes memory options) {
        bool hasCompose;
        // @dev This generated message has the msg.sender encoded into the payload so the remote knows who the caller is.
        (message, hasCompose) = OFTMsgCodec.encode(
            _sendParam.to,
            _toSD(_amountLD),
            // @dev Must be include a non empty bytes if you want to compose, EVEN if you dont need it on the remote.
            // EVEN if you dont require an arbitrary payload to be sent... eg. '0x01'
            _sendParam.composeMsg
        );
        // @dev Change the msg type depending if its composed or not.
        uint16 msgType = hasCompose ? SEND_AND_CALL : SEND;
        // @dev Combine the callers _extraOptions with the enforced options via the OAppOptionsType3.
        options = combineOptions(_sendParam.dstEid, msgType, _sendParam.extraOptions);

        // @dev Optionally inspect the message and options depending if the OApp owner has set a msg inspector.
        // @dev If it fails inspection, needs to revert in the implementation. ie. does not rely on return boolean
        if (msgInspector != address(0)) IOAppMsgInspector(msgInspector).inspect(message, options);
    }

    /**
     * @dev Internal function to handle the receive on the LayerZero endpoint.
     * @param _origin The origin information.
     *  - srcEid: The source chain endpoint ID.
     *  - sender: The sender address from the src chain.
     *  - nonce: The nonce of the LayerZero message.
     * @param _guid The unique identifier for the received LayerZero message.
     * @param _message The encoded message.
     * @dev _executor The address of the executor.
     * @dev _extraData Additional data.
     */
    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address /*_executor*/, // @dev unused in the default implementation.
        bytes calldata /*_extraData*/ // @dev unused in the default implementation.
    ) internal virtual override {
        // @dev The src sending chain doesnt know the address length on this chain (potentially non-evm)
        // Thus everything is bytes32() encoded in flight.
        address toAddress = _message.sendTo().bytes32ToAddress();
        // @dev Credit the amountLD to the recipient and return the ACTUAL amount the recipient received in local decimals
        uint256 amountReceivedLD = _credit(toAddress, _toLD(_message.amountSD()), _origin.srcEid);

        if (_message.isComposed()) {
            // @dev Proprietary composeMsg format for the OFT.
            bytes memory composeMsg = OFTComposeMsgCodec.encode(
                _origin.nonce,
                _origin.srcEid,
                amountReceivedLD,
                _message.composeMsg()
            );

            // @dev Stores the lzCompose payload that will be executed in a separate tx.
            // Standardizes functionality for executing arbitrary contract invocation on some non-evm chains.
            // @dev The off-chain executor will listen and process the msg based on the src-chain-callers compose options passed.
            // @dev The index is used when a OApp needs to compose multiple msgs on lzReceive.
            // For default OFT implementation there is only 1 compose msg per lzReceive, thus its always 0.
            endpoint.sendCompose(toAddress, _guid, 0 /* the index of the composed message*/, composeMsg);
        }

        emit OFTReceived(_guid, _origin.srcEid, toAddress, amountReceivedLD);
    }

    /**
     * @dev Internal function to handle the OAppPreCrimeSimulator simulated receive.
     * @param _origin The origin information.
     *  - srcEid: The source chain endpoint ID.
     *  - sender: The sender address from the src chain.
     *  - nonce: The nonce of the LayerZero message.
     * @param _guid The unique identifier for the received LayerZero message.
     * @param _message The LayerZero message.
     * @param _executor The address of the off-chain executor.
     * @param _extraData Arbitrary data passed by the msg executor.
     *
     * @dev Enables the preCrime simulator to mock sending lzReceive() messages,
     * routes the msg down from the OAppPreCrimeSimulator, and back up to the OAppReceiver.
     */
    function _lzReceiveSimulate(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) internal virtual override {
        _lzReceive(_origin, _guid, _message, _executor, _extraData);
    }

    /**
     * @dev Check if the peer is considered 'trusted' by the OApp.
     * @param _eid The endpoint ID to check.
     * @param _peer The peer to check.
     * @return Whether the peer passed is considered 'trusted' by the OApp.
     *
     * @dev Enables OAppPreCrimeSimulator to check whether a potential Inbound Packet is from a trusted source.
     */
    function isPeer(uint32 _eid, bytes32 _peer) public view virtual override returns (bool) {
        return peers[_eid] == _peer;
    }

    /**
     * @dev Internal function to remove dust from the given local decimal amount.
     * @param _amountLD The amount in local decimals.
     * @return amountLD The amount after removing dust.
     *
     * @dev Prevents the loss of dust when moving amounts between chains with different decimals.
     * @dev eg. uint(123) with a conversion rate of 100 becomes uint(100).
     */
    function _removeDust(uint256 _amountLD) internal view virtual returns (uint256 amountLD) {
        return (_amountLD / decimalConversionRate) * decimalConversionRate;
    }

    /**
     * @dev Internal function to convert an amount from shared decimals into local decimals.
     * @param _amountSD The amount in shared decimals.
     * @return amountLD The amount in local decimals.
     */
    function _toLD(uint64 _amountSD) internal view virtual returns (uint256 amountLD) {
        return _amountSD * decimalConversionRate;
    }

    /**
     * @dev Internal function to convert an amount from local decimals into shared decimals.
     * @param _amountLD The amount in local decimals.
     * @return amountSD The amount in shared decimals.
     */
    function _toSD(uint256 _amountLD) internal view virtual returns (uint64 amountSD) {
        return uint64(_amountLD / decimalConversionRate);
    }

    /**
     * @dev Internal function to mock the amount mutation from a OFT debit() operation.
     * @param _amountLD The amount to send in local decimals.
     * @param _minAmountLD The minimum amount to send in local decimals.
     * @dev _dstEid The destination endpoint ID.
     * @return amountSentLD The amount sent, in local decimals.
     * @return amountReceivedLD The amount to be received on the remote chain, in local decimals.
     *
     * @dev This is where things like fees would be calculated and deducted from the amount to be received on the remote.
     */
    function _debitView(
        uint256 _amountLD,
        uint256 _minAmountLD,
        uint32 /*_dstEid*/
    ) internal view virtual returns (uint256 amountSentLD, uint256 amountReceivedLD) {
        // @dev Remove the dust so nothing is lost on the conversion between chains with different decimals for the token.
        amountSentLD = _removeDust(_amountLD);
        // @dev The amount to send is the same as amount received in the default implementation.
        amountReceivedLD = amountSentLD;

        // @dev Check for slippage.
        if (amountReceivedLD < _minAmountLD) {
            revert SlippageExceeded(amountReceivedLD, _minAmountLD);
        }
    }

    /**
     * @dev Internal function to perform a debit operation.
     * @param _from The address to debit.
     * @param _amountLD The amount to send in local decimals.
     * @param _minAmountLD The minimum amount to send in local decimals.
     * @param _dstEid The destination endpoint ID.
     * @return amountSentLD The amount sent in local decimals.
     * @return amountReceivedLD The amount received in local decimals on the remote.
     *
     * @dev Defined here but are intended to be overriden depending on the OFT implementation.
     * @dev Depending on OFT implementation the _amountLD could differ from the amountReceivedLD.
     */
    function _debit(
        address _from,
        uint256 _amountLD,
        uint256 _minAmountLD,
        uint32 _dstEid
    ) internal virtual returns (uint256 amountSentLD, uint256 amountReceivedLD);

    /**
     * @dev Internal function to perform a credit operation.
     * @param _to The address to credit.
     * @param _amountLD The amount to credit in local decimals.
     * @param _srcEid The source endpoint ID.
     * @return amountReceivedLD The amount ACTUALLY received in local decimals.
     *
     * @dev Defined here but are intended to be overriden depending on the OFT implementation.
     * @dev Depending on OFT implementation the _amountLD could differ from the amountReceivedLD.
     */
    function _credit(
        address _to,
        uint256 _amountLD,
        uint32 _srcEid
    ) internal virtual returns (uint256 amountReceivedLD);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

// @dev Import the Origin so it's exposed to OAppPreCrimeSimulator implementers.
// solhint-disable-next-line no-unused-import
import { InboundPacket, Origin } from "../libs/Packet.sol";

/**
 * @title IOAppPreCrimeSimulator Interface
 * @dev Interface for the preCrime simulation functionality in an OApp.
 */
interface IOAppPreCrimeSimulator {
    // @dev simulation result used in PreCrime implementation
    error SimulationResult(bytes result);
    error OnlySelf();

    /**
     * @dev Emitted when the preCrime contract address is set.
     * @param preCrimeAddress The address of the preCrime contract.
     */
    event PreCrimeSet(address preCrimeAddress);

    /**
     * @dev Retrieves the address of the preCrime contract implementation.
     * @return The address of the preCrime contract.
     */
    function preCrime() external view returns (address);

    /**
     * @dev Retrieves the address of the OApp contract.
     * @return The address of the OApp contract.
     */
    function oApp() external view returns (address);

    /**
     * @dev Sets the preCrime contract address.
     * @param _preCrime The address of the preCrime contract.
     */
    function setPreCrime(address _preCrime) external;

    /**
     * @dev Mocks receiving a packet, then reverts with a series of data to infer the state/result.
     * @param _packets An array of LayerZero InboundPacket objects representing received packets.
     */
    function lzReceiveAndRevert(InboundPacket[] calldata _packets) external payable;

    /**
     * @dev checks if the specified peer is considered 'trusted' by the OApp.
     * @param _eid The endpoint Id to check.
     * @param _peer The peer to check.
     * @return Whether the peer passed is considered 'trusted' by the OApp.
     */
    function isPeer(uint32 _eid, bytes32 _peer) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;
struct PreCrimePeer {
    uint32 eid;
    bytes32 preCrime;
    bytes32 oApp;
}

// TODO not done yet
interface IPreCrime {
    error OnlyOffChain();

    // for simulate()
    error PacketOversize(uint256 max, uint256 actual);
    error PacketUnsorted();
    error SimulationFailed(bytes reason);

    // for preCrime()
    error SimulationResultNotFound(uint32 eid);
    error InvalidSimulationResult(uint32 eid, bytes reason);
    error CrimeFound(bytes crime);

    function getConfig(bytes[] calldata _packets, uint256[] calldata _packetMsgValues) external returns (bytes memory);

    function simulate(
        bytes[] calldata _packets,
        uint256[] calldata _packetMsgValues
    ) external payable returns (bytes memory);

    function buildSimulationResult() external view returns (bytes memory);

    function preCrime(
        bytes[] calldata _packets,
        uint256[] calldata _packetMsgValues,
        bytes[] calldata _simulations
    ) external;

    function version() external view returns (uint64 major, uint8 minor);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Origin } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import { PacketV1Codec } from "@layerzerolabs/lz-evm-protocol-v2/contracts/messagelib/libs/PacketV1Codec.sol";

/**
 * @title InboundPacket
 * @dev Structure representing an inbound packet received by the contract.
 */
struct InboundPacket {
    Origin origin; // Origin information of the packet.
    uint32 dstEid; // Destination endpointId of the packet.
    address receiver; // Receiver address for the packet.
    bytes32 guid; // Unique identifier of the packet.
    uint256 value; // msg.value of the packet.
    address executor; // Executor address for the packet.
    bytes message; // Message payload of the packet.
    bytes extraData; // Additional arbitrary data for the packet.
}

/**
 * @title PacketDecoder
 * @dev Library for decoding LayerZero packets.
 */
library PacketDecoder {
    using PacketV1Codec for bytes;

    /**
     * @dev Decode an inbound packet from the given packet data.
     * @param _packet The packet data to decode.
     * @return packet An InboundPacket struct representing the decoded packet.
     */
    function decode(bytes calldata _packet) internal pure returns (InboundPacket memory packet) {
        packet.origin = Origin(_packet.srcEid(), _packet.sender(), _packet.nonce());
        packet.dstEid = _packet.dstEid();
        packet.receiver = _packet.receiverB20();
        packet.guid = _packet.guid();
        packet.message = _packet.message();
    }

    /**
     * @dev Decode multiple inbound packets from the given packet data and associated message values.
     * @param _packets An array of packet data to decode.
     * @param _packetMsgValues An array of associated message values for each packet.
     * @return packets An array of InboundPacket structs representing the decoded packets.
     */
    function decode(
        bytes[] calldata _packets,
        uint256[] memory _packetMsgValues
    ) internal pure returns (InboundPacket[] memory packets) {
        packets = new InboundPacket[](_packets.length);
        for (uint256 i = 0; i < _packets.length; i++) {
            bytes calldata packet = _packets[i];
            packets[i] = PacketDecoder.decode(packet);
            // @dev Allows the verifier to specify the msg.value that gets passed in lzReceive.
            packets[i].value = _packetMsgValues[i];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IPreCrime } from "./interfaces/IPreCrime.sol";
import { IOAppPreCrimeSimulator, InboundPacket, Origin } from "./interfaces/IOAppPreCrimeSimulator.sol";

/**
 * @title OAppPreCrimeSimulator
 * @dev Abstract contract serving as the base for preCrime simulation functionality in an OApp.
 */
abstract contract OAppPreCrimeSimulator is IOAppPreCrimeSimulator, Ownable {
    // The address of the preCrime implementation.
    address public preCrime;

    /**
     * @dev Retrieves the address of the OApp contract.
     * @return The address of the OApp contract.
     *
     * @dev The simulator contract is the base contract for the OApp by default.
     * @dev If the simulator is a separate contract, override this function.
     */
    function oApp() external view virtual returns (address) {
        return address(this);
    }

    /**
     * @dev Sets the preCrime contract address.
     * @param _preCrime The address of the preCrime contract.
     */
    function setPreCrime(address _preCrime) public virtual onlyOwner {
        preCrime = _preCrime;
        emit PreCrimeSet(_preCrime);
    }

    /**
     * @dev Interface for pre-crime simulations. Always reverts at the end with the simulation results.
     * @param _packets An array of InboundPacket objects representing received packets to be delivered.
     *
     * @dev WARNING: MUST revert at the end with the simulation results.
     * @dev Gives the preCrime implementation the ability to mock sending packets to the lzReceive function,
     * WITHOUT actually executing them.
     */
    function lzReceiveAndRevert(InboundPacket[] calldata _packets) public payable virtual {
        for (uint256 i = 0; i < _packets.length; i++) {
            InboundPacket calldata packet = _packets[i];

            // Ignore packets that are not from trusted peers.
            if (!isPeer(packet.origin.srcEid, packet.origin.sender)) continue;

            // @dev Because a verifier is calling this function, it doesnt have access to executor params:
            //  - address _executor
            //  - bytes calldata _extraData
            // preCrime will NOT work for OApps that rely on these two parameters inside of their _lzReceive().
            // They are instead stubbed to default values, address(0) and bytes("")
            // @dev Calling this.lzReceiveSimulate removes ability for assembly return 0 callstack exit,
            // which would cause the revert to be ignored.
            this.lzReceiveSimulate{ value: packet.value }(
                packet.origin,
                packet.guid,
                packet.message,
                packet.executor,
                packet.extraData
            );
        }

        // @dev Revert with the simulation results. msg.sender must implement IPreCrime.buildSimulationResult().
        revert SimulationResult(IPreCrime(msg.sender).buildSimulationResult());
    }

    /**
     * @dev Is effectively an internal function because msg.sender must be address(this).
     * Allows resetting the call stack for 'internal' calls.
     * @param _origin The origin information containing the source endpoint and sender address.
     *  - srcEid: The source chain endpoint ID.
     *  - sender: The sender address on the src chain.
     *  - nonce: The nonce of the message.
     * @param _guid The unique identifier of the packet.
     * @param _message The message payload of the packet.
     * @param _executor The executor address for the packet.
     * @param _extraData Additional data for the packet.
     */
    function lzReceiveSimulate(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) external payable virtual {
        // @dev Ensure ONLY can be called 'internally'.
        if (msg.sender != address(this)) revert OnlySelf();
        _lzReceiveSimulate(_origin, _guid, _message, _executor, _extraData);
    }

    /**
     * @dev Internal function to handle the OAppPreCrimeSimulator simulated receive.
     * @param _origin The origin information.
     *  - srcEid: The source chain endpoint ID.
     *  - sender: The sender address from the src chain.
     *  - nonce: The nonce of the LayerZero message.
     * @param _guid The GUID of the LayerZero message.
     * @param _message The LayerZero message.
     * @param _executor The address of the off-chain executor.
     * @param _extraData Arbitrary data passed by the msg executor.
     *
     * @dev Enables the preCrime simulator to mock sending lzReceive() messages,
     * routes the msg down from the OAppPreCrimeSimulator, and back up to the OAppReceiver.
     */
    function _lzReceiveSimulate(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) internal virtual;

    /**
     * @dev checks if the specified peer is considered 'trusted' by the OApp.
     * @param _eid The endpoint Id to check.
     * @param _peer The peer to check.
     * @return Whether the peer passed is considered 'trusted' by the OApp.
     */
    function isPeer(uint32 _eid, bytes32 _peer) public view virtual returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/**
 * @title ILayerZeroComposer
 */
interface ILayerZeroComposer {
    /**
     * @notice Composes a LayerZero message from an OApp.
     * @param _from The address initiating the composition, typically the OApp where the lzReceive was called.
     * @param _guid The unique identifier for the corresponding LayerZero src/dst tx.
     * @param _message The composed message payload in bytes. NOT necessarily the same payload passed via lzReceive.
     * @param _executor The address of the executor for the composed message.
     * @param _extraData Additional arbitrary data in bytes passed by the entity who executes the lzCompose.
     */
    function lzCompose(
        address _from,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import { IMessageLibManager } from "./IMessageLibManager.sol";
import { IMessagingComposer } from "./IMessagingComposer.sol";
import { IMessagingChannel } from "./IMessagingChannel.sol";
import { IMessagingContext } from "./IMessagingContext.sol";

struct MessagingParams {
    uint32 dstEid;
    bytes32 receiver;
    bytes message;
    bytes options;
    bool payInLzToken;
}

struct MessagingReceipt {
    bytes32 guid;
    uint64 nonce;
    MessagingFee fee;
}

struct MessagingFee {
    uint256 nativeFee;
    uint256 lzTokenFee;
}

struct Origin {
    uint32 srcEid;
    bytes32 sender;
    uint64 nonce;
}

interface ILayerZeroEndpointV2 is IMessageLibManager, IMessagingComposer, IMessagingChannel, IMessagingContext {
    event PacketSent(bytes encodedPayload, bytes options, address sendLibrary);

    event PacketVerified(Origin origin, address receiver, bytes32 payloadHash);

    event PacketDelivered(Origin origin, address receiver);

    event LzReceiveAlert(
        address indexed receiver,
        address indexed executor,
        Origin origin,
        bytes32 guid,
        uint256 gas,
        uint256 value,
        bytes message,
        bytes extraData,
        bytes reason
    );

    event LzTokenSet(address token);

    event DelegateSet(address sender, address delegate);

    function quote(MessagingParams calldata _params, address _sender) external view returns (MessagingFee memory);

    function send(
        MessagingParams calldata _params,
        address _refundAddress
    ) external payable returns (MessagingReceipt memory);

    function verify(Origin calldata _origin, address _receiver, bytes32 _payloadHash) external;

    function verifiable(Origin calldata _origin, address _receiver) external view returns (bool);

    function initializable(Origin calldata _origin, address _receiver) external view returns (bool);

    function lzReceive(
        Origin calldata _origin,
        address _receiver,
        bytes32 _guid,
        bytes calldata _message,
        bytes calldata _extraData
    ) external payable;

    // oapp can burn messages partially by calling this function with its own business logic if messages are verified in order
    function clear(address _oapp, Origin calldata _origin, bytes32 _guid, bytes calldata _message) external;

    function setLzToken(address _lzToken) external;

    function lzToken() external view returns (address);

    function nativeToken() external view returns (address);

    function setDelegate(address _delegate) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import { Origin } from "./ILayerZeroEndpointV2.sol";

interface ILayerZeroReceiver {
    function allowInitializePath(Origin calldata _origin) external view returns (bool);

    function nextNonce(uint32 _eid, bytes32 _sender) external view returns (uint64);

    function lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import { SetConfigParam } from "./IMessageLibManager.sol";

enum MessageLibType {
    Send,
    Receive,
    SendAndReceive
}

interface IMessageLib is IERC165 {
    function setConfig(address _oapp, SetConfigParam[] calldata _config) external;

    function getConfig(uint32 _eid, address _oapp, uint32 _configType) external view returns (bytes memory config);

    function isSupportedEid(uint32 _eid) external view returns (bool);

    // message libs of same major version are compatible
    function version() external view returns (uint64 major, uint8 minor, uint8 endpointVersion);

    function messageLibType() external view returns (MessageLibType);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

struct SetConfigParam {
    uint32 eid;
    uint32 configType;
    bytes config;
}

interface IMessageLibManager {
    struct Timeout {
        address lib;
        uint256 expiry;
    }

    event LibraryRegistered(address newLib);
    event DefaultSendLibrarySet(uint32 eid, address newLib);
    event DefaultReceiveLibrarySet(uint32 eid, address newLib);
    event DefaultReceiveLibraryTimeoutSet(uint32 eid, address oldLib, uint256 expiry);
    event SendLibrarySet(address sender, uint32 eid, address newLib);
    event ReceiveLibrarySet(address receiver, uint32 eid, address newLib);
    event ReceiveLibraryTimeoutSet(address receiver, uint32 eid, address oldLib, uint256 timeout);

    function registerLibrary(address _lib) external;

    function isRegisteredLibrary(address _lib) external view returns (bool);

    function getRegisteredLibraries() external view returns (address[] memory);

    function setDefaultSendLibrary(uint32 _eid, address _newLib) external;

    function defaultSendLibrary(uint32 _eid) external view returns (address);

    function setDefaultReceiveLibrary(uint32 _eid, address _newLib, uint256 _gracePeriod) external;

    function defaultReceiveLibrary(uint32 _eid) external view returns (address);

    function setDefaultReceiveLibraryTimeout(uint32 _eid, address _lib, uint256 _expiry) external;

    function defaultReceiveLibraryTimeout(uint32 _eid) external view returns (address lib, uint256 expiry);

    function isSupportedEid(uint32 _eid) external view returns (bool);

    function isValidReceiveLibrary(address _receiver, uint32 _eid, address _lib) external view returns (bool);

    /// ------------------- OApp interfaces -------------------
    function setSendLibrary(address _oapp, uint32 _eid, address _newLib) external;

    function getSendLibrary(address _sender, uint32 _eid) external view returns (address lib);

    function isDefaultSendLibrary(address _sender, uint32 _eid) external view returns (bool);

    function setReceiveLibrary(address _oapp, uint32 _eid, address _newLib, uint256 _gracePeriod) external;

    function getReceiveLibrary(address _receiver, uint32 _eid) external view returns (address lib, bool isDefault);

    function setReceiveLibraryTimeout(address _oapp, uint32 _eid, address _lib, uint256 _expiry) external;

    function receiveLibraryTimeout(address _receiver, uint32 _eid) external view returns (address lib, uint256 expiry);

    function setConfig(address _oapp, address _lib, SetConfigParam[] calldata _params) external;

    function getConfig(
        address _oapp,
        address _lib,
        uint32 _eid,
        uint32 _configType
    ) external view returns (bytes memory config);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IMessagingChannel {
    event InboundNonceSkipped(uint32 srcEid, bytes32 sender, address receiver, uint64 nonce);
    event PacketNilified(uint32 srcEid, bytes32 sender, address receiver, uint64 nonce, bytes32 payloadHash);
    event PacketBurnt(uint32 srcEid, bytes32 sender, address receiver, uint64 nonce, bytes32 payloadHash);

    function eid() external view returns (uint32);

    // this is an emergency function if a message cannot be verified for some reasons
    // required to provide _nextNonce to avoid race condition
    function skip(address _oapp, uint32 _srcEid, bytes32 _sender, uint64 _nonce) external;

    function nilify(address _oapp, uint32 _srcEid, bytes32 _sender, uint64 _nonce, bytes32 _payloadHash) external;

    function burn(address _oapp, uint32 _srcEid, bytes32 _sender, uint64 _nonce, bytes32 _payloadHash) external;

    function nextGuid(address _sender, uint32 _dstEid, bytes32 _receiver) external view returns (bytes32);

    function inboundNonce(address _receiver, uint32 _srcEid, bytes32 _sender) external view returns (uint64);

    function outboundNonce(address _sender, uint32 _dstEid, bytes32 _receiver) external view returns (uint64);

    function inboundPayloadHash(
        address _receiver,
        uint32 _srcEid,
        bytes32 _sender,
        uint64 _nonce
    ) external view returns (bytes32);

    function lazyInboundNonce(address _receiver, uint32 _srcEid, bytes32 _sender) external view returns (uint64);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IMessagingComposer {
    event ComposeSent(address from, address to, bytes32 guid, uint16 index, bytes message);
    event ComposeDelivered(address from, address to, bytes32 guid, uint16 index);
    event LzComposeAlert(
        address indexed from,
        address indexed to,
        address indexed executor,
        bytes32 guid,
        uint16 index,
        uint256 gas,
        uint256 value,
        bytes message,
        bytes extraData,
        bytes reason
    );

    function composeQueue(
        address _from,
        address _to,
        bytes32 _guid,
        uint16 _index
    ) external view returns (bytes32 messageHash);

    function sendCompose(address _to, bytes32 _guid, uint16 _index, bytes calldata _message) external;

    function lzCompose(
        address _from,
        address _to,
        bytes32 _guid,
        uint16 _index,
        bytes calldata _message,
        bytes calldata _extraData
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IMessagingContext {
    function isSendingMessage() external view returns (bool);

    function getSendContext() external view returns (uint32 dstEid, address sender);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import { MessagingFee } from "./ILayerZeroEndpointV2.sol";
import { IMessageLib } from "./IMessageLib.sol";

struct Packet {
    uint64 nonce;
    uint32 srcEid;
    address sender;
    uint32 dstEid;
    bytes32 receiver;
    bytes32 guid;
    bytes message;
}

interface ISendLib is IMessageLib {
    function send(
        Packet calldata _packet,
        bytes calldata _options,
        bool _payInLzToken
    ) external returns (MessagingFee memory, bytes memory encodedPacket);

    function quote(
        Packet calldata _packet,
        bytes calldata _options,
        bool _payInLzToken
    ) external view returns (MessagingFee memory);

    function setTreasury(address _treasury) external;

    function withdrawFee(address _to, uint256 _amount) external;

    function withdrawLzTokenFee(address _lzToken, address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: LZBL-1.2

pragma solidity ^0.8.20;

library AddressCast {
    error AddressCast_InvalidSizeForAddress();
    error AddressCast_InvalidAddress();

    function toBytes32(bytes calldata _addressBytes) internal pure returns (bytes32 result) {
        if (_addressBytes.length > 32) revert AddressCast_InvalidAddress();
        result = bytes32(_addressBytes);
        unchecked {
            uint256 offset = 32 - _addressBytes.length;
            result = result >> (offset * 8);
        }
    }

    function toBytes32(address _address) internal pure returns (bytes32 result) {
        result = bytes32(uint256(uint160(_address)));
    }

    function toBytes(bytes32 _addressBytes32, uint256 _size) internal pure returns (bytes memory result) {
        if (_size == 0 || _size > 32) revert AddressCast_InvalidSizeForAddress();
        result = new bytes(_size);
        unchecked {
            uint256 offset = 256 - _size * 8;
            assembly {
                mstore(add(result, 32), shl(offset, _addressBytes32))
            }
        }
    }

    function toAddress(bytes32 _addressBytes32) internal pure returns (address result) {
        result = address(uint160(uint256(_addressBytes32)));
    }

    function toAddress(bytes calldata _addressBytes) internal pure returns (address result) {
        if (_addressBytes.length != 20) revert AddressCast_InvalidAddress();
        result = address(bytes20(_addressBytes));
    }
}

// SPDX-License-Identifier: LZBL-1.2

pragma solidity ^0.8.20;

library CalldataBytesLib {
    function toU8(bytes calldata _bytes, uint256 _start) internal pure returns (uint8) {
        return uint8(_bytes[_start]);
    }

    function toU16(bytes calldata _bytes, uint256 _start) internal pure returns (uint16) {
        unchecked {
            uint256 end = _start + 2;
            return uint16(bytes2(_bytes[_start:end]));
        }
    }

    function toU32(bytes calldata _bytes, uint256 _start) internal pure returns (uint32) {
        unchecked {
            uint256 end = _start + 4;
            return uint32(bytes4(_bytes[_start:end]));
        }
    }

    function toU64(bytes calldata _bytes, uint256 _start) internal pure returns (uint64) {
        unchecked {
            uint256 end = _start + 8;
            return uint64(bytes8(_bytes[_start:end]));
        }
    }

    function toU128(bytes calldata _bytes, uint256 _start) internal pure returns (uint128) {
        unchecked {
            uint256 end = _start + 16;
            return uint128(bytes16(_bytes[_start:end]));
        }
    }

    function toU256(bytes calldata _bytes, uint256 _start) internal pure returns (uint256) {
        unchecked {
            uint256 end = _start + 32;
            return uint256(bytes32(_bytes[_start:end]));
        }
    }

    function toAddr(bytes calldata _bytes, uint256 _start) internal pure returns (address) {
        unchecked {
            uint256 end = _start + 20;
            return address(bytes20(_bytes[_start:end]));
        }
    }

    function toB32(bytes calldata _bytes, uint256 _start) internal pure returns (bytes32) {
        unchecked {
            uint256 end = _start + 32;
            return bytes32(_bytes[_start:end]);
        }
    }
}

// SPDX-License-Identifier: MIT

// modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/BitMaps.sol
pragma solidity ^0.8.20;

type BitMap256 is uint256;

using BitMaps for BitMap256 global;

library BitMaps {
    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap256 bitmap, uint8 index) internal pure returns (bool) {
        uint256 mask = 1 << index;
        return BitMap256.unwrap(bitmap) & mask != 0;
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap256 bitmap, uint8 index) internal pure returns (BitMap256) {
        uint256 mask = 1 << index;
        return BitMap256.wrap(BitMap256.unwrap(bitmap) | mask);
    }
}

// SPDX-License-Identifier: LZBL-1.2

pragma solidity ^0.8.20;

import { CalldataBytesLib } from "../../libs/CalldataBytesLib.sol";

library ExecutorOptions {
    using CalldataBytesLib for bytes;

    uint8 internal constant WORKER_ID = 1;

    uint8 internal constant OPTION_TYPE_LZRECEIVE = 1;
    uint8 internal constant OPTION_TYPE_NATIVE_DROP = 2;
    uint8 internal constant OPTION_TYPE_LZCOMPOSE = 3;
    uint8 internal constant OPTION_TYPE_ORDERED_EXECUTION = 4;

    error Executor_InvalidLzReceiveOption();
    error Executor_InvalidNativeDropOption();
    error Executor_InvalidLzComposeOption();

    /// @dev decode the next executor option from the options starting from the specified cursor
    /// @param _options [executor_id][executor_option][executor_id][executor_option]...
    ///        executor_option = [option_size][option_type][option]
    ///        option_size = len(option_type) + len(option)
    ///        executor_id: uint8, option_size: uint16, option_type: uint8, option: bytes
    /// @param _cursor the cursor to start decoding from
    /// @return optionType the type of the option
    /// @return option the option of the executor
    /// @return cursor the cursor to start decoding the next executor option
    function nextExecutorOption(
        bytes calldata _options,
        uint256 _cursor
    ) internal pure returns (uint8 optionType, bytes calldata option, uint256 cursor) {
        unchecked {
            // skip worker id
            cursor = _cursor + 1;

            // read option size
            uint16 size = _options.toU16(cursor);
            cursor += 2;

            // read option type
            optionType = _options.toU8(cursor);

            // startCursor and endCursor are used to slice the option from _options
            uint256 startCursor = cursor + 1; // skip option type
            uint256 endCursor = cursor + size;
            option = _options[startCursor:endCursor];
            cursor += size;
        }
    }

    function decodeLzReceiveOption(bytes calldata _option) internal pure returns (uint128 gas, uint128 value) {
        if (_option.length != 16 && _option.length != 32) revert Executor_InvalidLzReceiveOption();
        gas = _option.toU128(0);
        value = _option.length == 32 ? _option.toU128(16) : 0;
    }

    function decodeNativeDropOption(bytes calldata _option) internal pure returns (uint128 amount, bytes32 receiver) {
        if (_option.length != 48) revert Executor_InvalidNativeDropOption();
        amount = _option.toU128(0);
        receiver = _option.toB32(16);
    }

    function decodeLzComposeOption(
        bytes calldata _option
    ) internal pure returns (uint16 index, uint128 gas, uint128 value) {
        if (_option.length != 18 && _option.length != 34) revert Executor_InvalidLzComposeOption();
        index = _option.toU16(0);
        gas = _option.toU128(2);
        value = _option.length == 34 ? _option.toU128(18) : 0;
    }

    function encodeLzReceiveOption(uint128 _gas, uint128 _value) internal pure returns (bytes memory) {
        return _value == 0 ? abi.encodePacked(_gas) : abi.encodePacked(_gas, _value);
    }

    function encodeNativeDropOption(uint128 _amount, bytes32 _receiver) internal pure returns (bytes memory) {
        return abi.encodePacked(_amount, _receiver);
    }

    function encodeLzComposeOption(uint16 _index, uint128 _gas, uint128 _value) internal pure returns (bytes memory) {
        return _value == 0 ? abi.encodePacked(_index, _gas) : abi.encodePacked(_index, _gas, _value);
    }
}

// SPDX-License-Identifier: LZBL-1.2

pragma solidity ^0.8.20;

import { Packet } from "../../interfaces/ISendLib.sol";
import { AddressCast } from "../../libs/AddressCast.sol";

library PacketV1Codec {
    using AddressCast for address;
    using AddressCast for bytes32;

    uint8 internal constant PACKET_VERSION = 1;

    // header (version + nonce + path)
    // version
    uint256 private constant PACKET_VERSION_OFFSET = 0;
    //    nonce
    uint256 private constant NONCE_OFFSET = 1;
    //    path
    uint256 private constant SRC_EID_OFFSET = 9;
    uint256 private constant SENDER_OFFSET = 13;
    uint256 private constant DST_EID_OFFSET = 45;
    uint256 private constant RECEIVER_OFFSET = 49;
    // payload (guid + message)
    uint256 private constant GUID_OFFSET = 81; // keccak256(nonce + path)
    uint256 private constant MESSAGE_OFFSET = 113;

    function encode(Packet memory _packet) internal pure returns (bytes memory encodedPacket) {
        encodedPacket = abi.encodePacked(
            PACKET_VERSION,
            _packet.nonce,
            _packet.srcEid,
            _packet.sender.toBytes32(),
            _packet.dstEid,
            _packet.receiver,
            _packet.guid,
            _packet.message
        );
    }

    function encodePacketHeader(Packet memory _packet) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                PACKET_VERSION,
                _packet.nonce,
                _packet.srcEid,
                _packet.sender.toBytes32(),
                _packet.dstEid,
                _packet.receiver
            );
    }

    function encodePayload(Packet memory _packet) internal pure returns (bytes memory) {
        return abi.encodePacked(_packet.guid, _packet.message);
    }

    function header(bytes calldata _packet) internal pure returns (bytes calldata) {
        return _packet[0:GUID_OFFSET];
    }

    function version(bytes calldata _packet) internal pure returns (uint8) {
        return uint8(bytes1(_packet[PACKET_VERSION_OFFSET:NONCE_OFFSET]));
    }

    function nonce(bytes calldata _packet) internal pure returns (uint64) {
        return uint64(bytes8(_packet[NONCE_OFFSET:SRC_EID_OFFSET]));
    }

    function srcEid(bytes calldata _packet) internal pure returns (uint32) {
        return uint32(bytes4(_packet[SRC_EID_OFFSET:SENDER_OFFSET]));
    }

    function sender(bytes calldata _packet) internal pure returns (bytes32) {
        return bytes32(_packet[SENDER_OFFSET:DST_EID_OFFSET]);
    }

    function senderAddressB20(bytes calldata _packet) internal pure returns (address) {
        return sender(_packet).toAddress();
    }

    function dstEid(bytes calldata _packet) internal pure returns (uint32) {
        return uint32(bytes4(_packet[DST_EID_OFFSET:RECEIVER_OFFSET]));
    }

    function receiver(bytes calldata _packet) internal pure returns (bytes32) {
        return bytes32(_packet[RECEIVER_OFFSET:GUID_OFFSET]);
    }

    function receiverB20(bytes calldata _packet) internal pure returns (address) {
        return receiver(_packet).toAddress();
    }

    function guid(bytes calldata _packet) internal pure returns (bytes32) {
        return bytes32(_packet[GUID_OFFSET:MESSAGE_OFFSET]);
    }

    function message(bytes calldata _packet) internal pure returns (bytes calldata) {
        return bytes(_packet[MESSAGE_OFFSET:]);
    }

    function payload(bytes calldata _packet) internal pure returns (bytes calldata) {
        return bytes(_packet[GUID_OFFSET:]);
    }

    function payloadHash(bytes calldata _packet) internal pure returns (bytes32) {
        return keccak256(payload(_packet));
    }
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
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC5267.sol)

pragma solidity ^0.8.0;

interface IERC5267 {
    /**
     * @dev MAY be emitted to signal that the domain could have changed.
     */
    event EIP712DomainChanged();

    /**
     * @dev returns the fields and values that describe the domain separator used by this contract for EIP-712
     * signature.
     */
    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );
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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

// EIP-2612 is Final as of 2022-11-01. This file is deprecated.

import "./ERC20Permit.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/cryptography/EIP712.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @inheritdoc IERC20Permit
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @inheritdoc IERC20Permit
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @inheritdoc IERC20Permit
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
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
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
     * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
     * that `ownerOf(tokenId)` is `a`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __unsafe_increaseBalance(address account, uint256 amount) internal {
        _balances[account] += amount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.8;

import "./ECDSA.sol";
import "../ShortStrings.sol";
import "../../interfaces/IERC5267.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * NOTE: In the upgradeable version of this contract, the cached values will correspond to the address, and the domain
 * separator of the implementation contract. This will cause the `_domainSeparatorV4` function to always rebuild the
 * separator from the immutable values, which is cheaper than accessing a cached version in cold storage.
 *
 * _Available since v3.4._
 *
 * @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
 */
abstract contract EIP712 is IERC5267 {
    using ShortStrings for *;

    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _cachedDomainSeparator;
    uint256 private immutable _cachedChainId;
    address private immutable _cachedThis;

    bytes32 private immutable _hashedName;
    bytes32 private immutable _hashedVersion;

    ShortString private immutable _name;
    ShortString private immutable _version;
    string private _nameFallback;
    string private _versionFallback;

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        _name = name.toShortStringWithFallback(_nameFallback);
        _version = version.toShortStringWithFallback(_versionFallback);
        _hashedName = keccak256(bytes(name));
        _hashedVersion = keccak256(bytes(version));

        _cachedChainId = block.chainid;
        _cachedDomainSeparator = _buildDomainSeparator();
        _cachedThis = address(this);
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _cachedThis && block.chainid == _cachedChainId) {
            return _cachedDomainSeparator;
        } else {
            return _buildDomainSeparator();
        }
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(_TYPE_HASH, _hashedName, _hashedVersion, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev See {EIP-5267}.
     *
     * _Available since v4.9._
     */
    function eip712Domain()
        public
        view
        virtual
        override
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        return (
            hex"0f", // 01111
            _name.toStringWithFallback(_nameFallback),
            _version.toStringWithFallback(_versionFallback),
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/ShortStrings.sol)

pragma solidity ^0.8.8;

import "./StorageSlot.sol";

// | string  | 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA   |
// | length  | 0x                                                              BB |
type ShortString is bytes32;

/**
 * @dev This library provides functions to convert short memory strings
 * into a `ShortString` type that can be used as an immutable variable.
 *
 * Strings of arbitrary length can be optimized using this library if
 * they are short enough (up to 31 bytes) by packing them with their
 * length (1 byte) in a single EVM word (32 bytes). Additionally, a
 * fallback mechanism can be used for every other case.
 *
 * Usage example:
 *
 * ```solidity
 * contract Named {
 *     using ShortStrings for *;
 *
 *     ShortString private immutable _name;
 *     string private _nameFallback;
 *
 *     constructor(string memory contractName) {
 *         _name = contractName.toShortStringWithFallback(_nameFallback);
 *     }
 *
 *     function name() external view returns (string memory) {
 *         return _name.toStringWithFallback(_nameFallback);
 *     }
 * }
 * ```
 */
library ShortStrings {
    // Used as an identifier for strings longer than 31 bytes.
    bytes32 private constant _FALLBACK_SENTINEL = 0x00000000000000000000000000000000000000000000000000000000000000FF;

    error StringTooLong(string str);
    error InvalidShortString();

    /**
     * @dev Encode a string of at most 31 chars into a `ShortString`.
     *
     * This will trigger a `StringTooLong` error is the input string is too long.
     */
    function toShortString(string memory str) internal pure returns (ShortString) {
        bytes memory bstr = bytes(str);
        if (bstr.length > 31) {
            revert StringTooLong(str);
        }
        return ShortString.wrap(bytes32(uint256(bytes32(bstr)) | bstr.length));
    }

    /**
     * @dev Decode a `ShortString` back to a "normal" string.
     */
    function toString(ShortString sstr) internal pure returns (string memory) {
        uint256 len = byteLength(sstr);
        // using `new string(len)` would work locally but is not memory safe.
        string memory str = new string(32);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(str, len)
            mstore(add(str, 0x20), sstr)
        }
        return str;
    }

    /**
     * @dev Return the length of a `ShortString`.
     */
    function byteLength(ShortString sstr) internal pure returns (uint256) {
        uint256 result = uint256(ShortString.unwrap(sstr)) & 0xFF;
        if (result > 31) {
            revert InvalidShortString();
        }
        return result;
    }

    /**
     * @dev Encode a string into a `ShortString`, or write it to storage if it is too long.
     */
    function toShortStringWithFallback(string memory value, string storage store) internal returns (ShortString) {
        if (bytes(value).length < 32) {
            return toShortString(value);
        } else {
            StorageSlot.getStringSlot(store).value = value;
            return ShortString.wrap(_FALLBACK_SENTINEL);
        }
    }

    /**
     * @dev Decode a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     */
    function toStringWithFallback(ShortString value, string storage store) internal pure returns (string memory) {
        if (ShortString.unwrap(value) != _FALLBACK_SENTINEL) {
            return toString(value);
        } else {
            return store;
        }
    }

    /**
     * @dev Return the length of a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     *
     * WARNING: This will return the "byte length" of the string. This may not reflect the actual length in terms of
     * actual characters as the UTF-8 encoding of a single character can span over multiple bytes.
     */
    function byteLengthWithFallback(ShortString value, string storage store) internal view returns (uint256) {
        if (ShortString.unwrap(value) != _FALLBACK_SENTINEL) {
            return byteLength(value);
        } else {
            return bytes(store).length;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Tapioca
import {INFTLoader} from "../interfaces/INFTLoader.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

/// @title ERC721 NFT Loader
/// @notice An ERC721 token that can load NFT URIs from an NFT loader contract. This helps update image URIs for NFTs.
contract ERC721NftLoader is ERC721, Ownable {
    INFTLoader public nftLoader; // NFT URI loader contract

    string public baseURI;

    constructor(string memory _name, string memory _symbol, address _owner) ERC721(_name, _symbol) {
        _transferOwnership(_owner);
    }

    /**
     * @notice Returns the token URI for a given token ID. If the NFT loader contract is not set, it returns an empty string.
     * @inheritdoc ERC721
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        // If baseURI is set, use it. Otherwise, use the NFT loader contract.
        if (bytes(baseURI).length > 0) {
            return super.tokenURI(tokenId);
        } else {
            if (address(nftLoader) == address(0)) {
                return "";
            }
            return INFTLoader(nftLoader).tokenURI(tokenId);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice Set the base URI
     */
    function setBaseURI(string memory __baseURI) external onlyOwner {
        baseURI = __baseURI;
    }

    /**
     * @notice Set the NFT loader contract
     */
    function setNftLoader(address _nftLoader) external onlyOwner {
        nftLoader = INFTLoader(_nftLoader);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Tapioca
import {IPearlmit, PearlmitHandler} from "tapioca-periph/pearlmit/PearlmitHandler.sol";
import {ERC721NftLoader} from "contracts/erc721NftLoader/ERC721NftLoader.sol";
import {ICluster} from "tapioca-periph/interfaces/periph/ICluster.sol";
import {ERC721Permit} from "tapioca-periph/utils/ERC721Permit.sol";
import {ERC721PermitStruct} from "contracts/tokens/ITapToken.sol";
import {TapToken} from "contracts/tokens/TapToken.sol";
import {TWAML} from "contracts/options/twAML.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

// Justification for data sizes:
// - 56 bits can represent over 2 billion years in seconds
// - TAP has a maximum supply of 100 million, and a precision of 10^18. Any
//   amount will therefore fit in (lg 10^26 = 87) bits.
// - The multiplier has a maximum of 1 million; dMAX = 100 * 1e4, which fits
//   in 20 bits.
// - A week is 86400 * 7 = 604800 seconds; less than 2^20. Even if we start
//   counting at the (Unix) epoch, we will run out of `expiry` before we
//   saturate the week fields.
struct Participation {
    // 1 slot
    uint256 averageMagnitude; // average magnitude of the pool at the time of locking.
    // 1 slot
    bool hasVotingPower;
    bool divergenceForce; // 0 negative, 1 positive
    bool tapReleased; // allow restaking while rewards may still accumulate
    uint56 lockedAt; // timestamp when lock was created. Since it's locked at block.timestamp, it's safe to say 56 bits will suffice
    // 1 slot
    uint56 expiry; // expiry timestamp. Big enough for over 2 billion years..
    uint88 tapAmount; // amount of TAP locked
    uint24 multiplier; // Votes = multiplier * tapAmount
    uint40 lastInactive; // One week BEFORE the staker gets a share of rewards
    uint40 lastActive; // Last week that the staker shares in rewards
}

struct TWAMLPool {
    uint256 totalParticipants;
    uint256 averageMagnitude;
    uint256 totalDeposited;
    uint256 cumulative;
}

struct WeekTotals {
    // For [0..currentWeek] this is a cumulative total: it consists of the
    // active votes in the previous week, minus the votes known to expire this
    // week. For future weeks, it is a negative number corresponding to the
    // expiring votes.
    int256 netActiveVotes;
    // rewardTokens index -> amount
    mapping(uint256 => uint256) totalDistPerVote;
}

contract TwTAP is
    TWAML,
    ERC721,
    ERC721Permit,
    ERC721Enumerable,
    Ownable,
    PearlmitHandler,
    ERC721NftLoader,
    ReentrancyGuard,
    Pausable
{
    using SafeERC20 for IERC20;

    TapToken public immutable tapOFT;

    /// ===== TWAML ======
    TWAMLPool public twAML; // sglAssetId => twAMLPool

    mapping(uint256 => Participation) public participants; // tokenId => part.

    /// @dev Virtual total amount to add to the total when computing twAML participation right. Default 10_000 * 1e18.
    uint256 public VIRTUAL_TOTAL_AMOUNT = 10_000 ether;

    uint256 public MIN_WEIGHT_FACTOR = 1000; // In BPS, default 10%
    uint256 constant dMAX = 1_000_000; // 100 * 1e4; 0% - 100% voting power multiplier
    uint256 constant dMIN = 0;
    uint256 public constant EPOCH_DURATION = 7 days;
    uint256 public constant MAX_LOCK_DURATION = 100 * 365 days; // 100 years

    // If we assume 128 bit balances for the reward token -- which fit 1e40
    // "tokens" at the most commonly used 1e18 precision -- then we can use the
    // other 128 bits to store the tokens allotted to a single vote more
    // accurately. Votes in turn are proportional to the amount of TAP locked,
    // weighted by a multiplier. This number is at most 107 bits long (see
    // definition of `Participation` struct).
    // the weight ranges from 10-100% where 1% = 1e4, so 1 million (20 bits).
    // the multiplier is at most 100% = 1M (20 bits), so votes is at most a
    // 107-bit number.
    uint256 constant DIST_PRECISION = 2 ** 128; //2 ** 128;

    IERC20[] public rewardTokens;
    mapping(IERC20 => uint256) public rewardTokenIndex; // Index 0 is reserved with 0x0 address
    uint256 public maxRewardTokens;

    // tokenId -> rewardTokens index -> amount
    mapping(uint256 => mapping(uint256 => uint256)) public claimed;

    // The current week is determined by creation, but there are values that
    // need to be updated weekly. If, for any reason whatsoever, this cannot
    // be done in time, the `lastProcessedWeek` will be behind until this is
    // done.
    uint256 public mintedTWTap;
    uint256 public creation; // Week 0 starts here
    uint256 public lastProcessedWeek;
    mapping(uint256 => WeekTotals) public weekTotals;

    ICluster public cluster;

    bool rescueMode;
    uint256 public emergencySweepCooldown = 2 days;
    uint256 public lastEmergencySweep;

    error NotAuthorized();
    error AdvanceWeekFirst();
    error NotValid();
    error Registered();
    error TokenLimitReached();
    error NotApproved(uint256 tokenId, address spender);
    error Duplicate();
    error LockNotExpired();
    error LockNotAWeek();
    error LockTooLong();
    error AdvanceEpochFirst();
    error DurationNotMultiple(); // Lock duration should be a multiple of 1 EPOCH
    error EmergencySweepCooldownNotReached();

    /// =====-------======
    constructor(address payable _tapOFT, IPearlmit _pearlmit, address _owner)
        ERC721NftLoader("Time Weighted TAP", "twTAP", _owner)
        ERC721Permit("Time Weighted TAP")
        PearlmitHandler(_pearlmit)
    {
        tapOFT = TapToken(_tapOFT);
        creation = block.timestamp;

        rewardTokens.push(IERC20(address(0x0))); // 0 index is reserved

        maxRewardTokens = 30;

        // Seed the cumulative with 1 week of magnitude
        twAML.cumulative = EPOCH_DURATION;
    }

    // ==========
    //   EVENTS
    // ==========

    event AMLDivergence(
        uint256 indexed cumulative, uint256 indexed averageMagnitude, uint256 indexed totalParticipants
    );

    event AddRewardToken(address indexed rewardTokenAddress, uint256 rewardTokenIndex);
    event DistributeReward(
        address indexed rewardTokenAddress, address indexed from, uint256 amount, uint256 rewardTokenIndex
    );
    event AdvanceEpoch(uint256 indexed newEpoch, uint256 lastEpoch);

    event ClaimReward(
        address indexed rewardTokenAddress,
        address indexed to,
        uint256 indexed twTapTokenId,
        uint256 amount,
        uint256 rewardTokenIndex
    );
    event Participate(
        address indexed participant, uint256 mintedTokenId, uint256 tapAmount, uint256 multiplier, uint256 lockDuration
    );
    event ExitPosition(uint256 indexed twTapTokenId, address indexed releasedTo, uint256 amount);

    event LogMaxRewardsLength(uint256 _oldLength, uint256 _newLength, uint256 _currentLength);
    event SetMinWeightFactor(uint256 newMinWeightFactor, uint256 oldMinWeightFactor);
    event SetVirtualTotalAmount(uint256 newVirtualTotalAmount, uint256 oldVirtualTotalAmount);
    event RescueMode(bool _rescueMode);
    event SetCluster(address _cluster);
    event EmergencySweepLocks();
    event EmergencySweepRewards();
    event SetEmergencySweepCooldown(uint256 emergencySweepCooldown);
    event ActivateEmergencySweep();

    // ==========
    //    READ
    // ==========

    /**
     * @inheritdoc ERC721NftLoader
     */
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721NftLoader) returns (string memory) {
        return ERC721NftLoader.tokenURI(tokenId);
    }

    /**
     * @notice Return the address of reward tokens.
     */
    function getRewardTokens() external view returns (IERC20[] memory) {
        return rewardTokens;
    }

    function currentWeek() public view returns (uint256) {
        return (block.timestamp - creation) / EPOCH_DURATION;
    }

    /**
     * @notice Return the total amount distributed for a reward token in a given week.
     * @param _week The week to query.
     * @param _rewardTokenId The reward token to query.
     */
    function getTotalDistPerVoteForWeek(uint256 _week, uint256 _rewardTokenId) external view returns (uint256) {
        return weekTotals[_week].totalDistPerVote[_rewardTokenId];
    }

    /// @notice Return the participation of a token. Returns 0 votes for expired tokens.
    function getParticipation(uint256 _tokenId) external view returns (Participation memory participant) {
        participant = participants[_tokenId];
        if (participant.expiry <= block.timestamp) {
            participant.multiplier = 0;
        }
        return participant;
    }

    /**
     * @notice Amount currently claimable for each reward token.
     * @dev index 0 will ALWAYS return 0, as it's used by address(0x0).
     * @dev Should be safe to claim even after position exit.
     * @return claimable amounts mapped by reward token
     */
    function claimable(uint256 _tokenId) public view returns (uint256[] memory) {
        uint256 len = rewardTokens.length;
        uint256[] memory result = new uint256[](len);

        Participation memory position = participants[_tokenId];
        uint256 votes;
        unchecked {
            // Math is safe: Types fit
            votes = uint256(position.tapAmount) * uint256(position.multiplier);
        }

        if (votes == 0) {
            return result;
        }

        // If the "last processed week" is behind the actual week, rewards
        // get processed as if it were earlier.
        uint256 week = lastProcessedWeek;
        if (week <= position.lastInactive) {
            return result;
        }
        if (position.lastActive < week) {
            week = position.lastActive;
        }

        WeekTotals storage cur = weekTotals[week];
        WeekTotals storage prev = weekTotals[position.lastInactive];

        for (uint256 i; i < len;) {
            // Math is safe (but we do the checks anyway):
            //
            // -- The `totalDistPerVote[i]` values are increasing as a
            //    function of weeks (see `advanceWeek()`), and if `week`
            //    were not greater than `position.lastInactive`, this bit
            //    of code would not be reached (see above). Therefore the
            //    subtraction in the calculation of `net` cannot underflow.
            //
            // -- `votes * net` is at most the entire reward amount given
            //    out, ever, in units of
            //
            //        (reward tokens) * DIST_PRECISION.
            //
            //    If this number were to exceed 256 bits, then
            //    `distributeReward` would revert.
            //
            // -- `claimed[_tokenId][i]` is the sum of all (the i-th values
            //    of) previous calls to the current function that were made
            //    by `_claimRewards()`. Let there be n such calls, and let
            //    r_j be `result[i]`, c_j be `claimed[_tokenId][i]`, and
            //    net_j be `net` during that j-th call. Then, up to a
            //    multiplication by votes / DIST_PRECISION:
            //
            //              c_1 = 0 <= net_1,
            //
            //    and, for n > 1:
            //
            //              c_n = r_(n-1) + r_(n-2) + ... + r_1
            //                  = r_(n-1) + c_(n-1)
            //                  = (net_(n-1) - c_(n-1) + c_(n-1)
            //                  = net_(n-1)
            //                  <= net_n,
            //
            //    so that the subtraction net_n - c_n does not underflow.
            //    (The rounding the calculation favors the greater first
            //    term).
            //
            uint256 net = cur.totalDistPerVote[i] - prev.totalDistPerVote[i];
            result[i] = ((votes * net) / DIST_PRECISION) - claimed[_tokenId][i];
            unchecked {
                ++i;
            }
        }
        return result;
    }

    /// @notice Return the Participation of a token and the claimable amounts.
    /// @param _tokenId The tokenId of the twTAP position.
    /// @return position The Participation of the token.
    /// @return claimables The claimable amounts of each reward token.
    function getPosition(uint256 _tokenId)
        external
        view
        returns (Participation memory position, uint256[] memory claimables)
    {
        position = participants[_tokenId];
        claimables = claimable(_tokenId);
    }

    /**
     * @dev Returns the hash of the struct used by the permit function.
     * @param _permitData Struct containing permit data.
     */
    function getTypedDataHash(ERC721PermitStruct calldata _permitData) public view returns (bytes32) {
        bytes32 permitTypeHash_ = keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");

        bytes32 structHash_ = keccak256(
            abi.encode(
                permitTypeHash_, _permitData.spender, _permitData.tokenId, _permitData.nonce, _permitData.deadline
            )
        );
        return _hashTypedDataV4(structHash_);
    }

    // ===========
    //    WRITE
    // ===========

    /// @notice Participate in twAML voting and mint an twTap position
    ///         Lock duration should be a multiple of 1 EPOCH, and have a minimum of 1 EPOCH.
    /// @dev Requires a Pearlmit approval for the TAP amount
    ///
    /// @param _participant The address of the participant
    /// @param _amount The amount of TAP to participate with
    /// @param _duration The duration of the lock
    function participate(address _participant, uint256 _amount, uint256 _duration)
        external
        whenNotPaused
        nonReentrant
        returns (uint256 tokenId)
    {
        if (_duration < EPOCH_DURATION) revert LockNotAWeek();
        if (_duration > MAX_LOCK_DURATION) revert LockTooLong();
        if (_duration % EPOCH_DURATION != 0) revert DurationNotMultiple();
        if (lastProcessedWeek != currentWeek()) revert AdvanceWeekFirst();

        // Transfer TAP to this contract
        {
            // tapOFT.transferFrom(msg.sender, address(this), _amount);
            bool isErr = pearlmit.transferFromERC20(msg.sender, address(this), address(tapOFT), _amount);
            if (isErr) revert NotAuthorized();
        }

        // Copy to memory
        TWAMLPool memory pool = twAML;

        uint256 magnitude = computeMagnitude(_duration, pool.cumulative);
        // Revert if the lock 4x the cumulative
        if (magnitude >= pool.cumulative * 4) revert NotValid();
        uint256 multiplier = computeTarget(dMIN, dMAX, magnitude, pool.cumulative);

        // Calculate twAML voting weight
        bool divergenceForce;
        bool hasVotingPower = _amount >= computeMinWeight(pool.totalDeposited + VIRTUAL_TOTAL_AMOUNT, MIN_WEIGHT_FACTOR);
        if (hasVotingPower) {
            pool.totalParticipants++; // Save participation
            pool.averageMagnitude = (pool.averageMagnitude + magnitude) / pool.totalParticipants; // compute new average magnitude

            // Compute and save new cumulative
            divergenceForce = _duration >= pool.cumulative;

            if (divergenceForce) {
                pool.cumulative += pool.averageMagnitude;
            } else {
                if (pool.cumulative > pool.averageMagnitude) {
                    pool.cumulative -= pool.averageMagnitude;
                } else {
                    pool.cumulative = EPOCH_DURATION;
                }
            }

            // Save new weight
            pool.totalDeposited += _amount;

            twAML = pool; // Save twAML participation
            emit AMLDivergence(pool.cumulative, pool.averageMagnitude, pool.totalParticipants);
        }

        uint256 expiry = block.timestamp + _duration;
        // Eligibility starts NEXT week, and lasts until the week that the lock
        // expires. This is guaranteed to be at least one week later by the
        // check on `_duration`.
        // If a user locks right before the current week ends, and have a
        // duration slightly over one week, straddling the two starting points,
        // then that user is eligible for the rewards during both weeks; the
        // price for this maneuver is a lower multiplier, and loss of voting
        // power in the DAO after the lock expires.
        uint256 w0 = currentWeek();
        uint256 w1 = (expiry - creation) / EPOCH_DURATION;

        // Save twAML participation
        // Casts are safe: see struct definition
        tokenId = ++mintedTWTap;
        uint256 votes = _amount * multiplier;
        participants[tokenId] = Participation({
            averageMagnitude: pool.averageMagnitude,
            hasVotingPower: hasVotingPower,
            divergenceForce: divergenceForce,
            tapReleased: false,
            lockedAt: uint56(block.timestamp),
            expiry: uint56(expiry),
            tapAmount: uint88(_amount),
            multiplier: uint24(multiplier),
            lastInactive: uint40(w0),
            lastActive: uint40(w1)
        });

        // w0 + 1 = lastInactive + 1 = first active
        // w1 + 1 = lastActive + 1 = first inactive
        // Cast is safe: `votes` is the product of a uint88 and a uint24
        weekTotals[w0 + 1].netActiveVotes += int256(votes);
        weekTotals[w1 + 1].netActiveVotes -= int256(votes);

        // Mint twTAP position
        _safeMint(_participant, tokenId);

        emit Participate(_participant, tokenId, _amount, multiplier, _duration);
    }

    /**
     * @notice claims all rewards distributed since token mint or last claim.
     * @dev Should be safe to claim even after position exit.
     *
     * @param _tokenId tokenId whose rewards to claim
     *
     * @return amounts_ Claimed amount of each reward token.
     */
    function claimRewards(uint256 _tokenId) external nonReentrant whenNotPaused returns (uint256[] memory amounts_) {
        amounts_ = _claimRewardsForToken(_tokenId);
    }

    /**
     * @notice batch claims all rewards distributed since token mint or last claim.
     * @dev Should be safe to claim even after position exit.
     *
     * @param _tokenIds tokenIds whose rewards to claim
     *
     * @return amounts_ Claimed amountsof each reward token, for each tokenId
     */
    function batchClaimRewards(uint256[] calldata _tokenIds)
        external
        nonReentrant
        whenNotPaused
        returns (uint256[][] memory amounts_)
    {
        amounts_ = new uint256[][](_tokenIds.length);
        uint256 len = _tokenIds.length;
        for (uint256 i; i < len; i++) {
            amounts_[i] = _claimRewardsForToken(_tokenIds[i]);
        }
    }

    /**
     * @notice Exit a twAML participation, delete the voting power if existing and send the TAP to `_to`.
     *
     * @param _tokenId The tokenId of the twTAP position.
     *
     * @return tapAmount_ The amount of TAP released.
     */
    function exitPosition(uint256 _tokenId) external nonReentrant whenNotPaused returns (uint256 tapAmount_) {
        address owner_ = ownerOf(_tokenId);
        tapAmount_ = _releaseTap(_tokenId, owner_);
    }

    /// @notice Indicate that (a) week(s) have passed and update running totals
    /// @notice Reverts if called in week 0. Let it.
    /// @param _limit Maximum number of weeks to process in one call
    function advanceWeek(uint256 _limit) public nonReentrant {
        if (!cluster.hasRole(msg.sender, keccak256("NEW_EPOCH"))) revert NotAuthorized();

        uint256 week = lastProcessedWeek;
        uint256 goal = currentWeek();
        unchecked {
            if (goal - week > _limit) {
                goal = week + _limit;
            }
        }
        uint256 len = rewardTokens.length;
        while (week < goal) {
            WeekTotals storage prev = weekTotals[week];
            WeekTotals storage next = weekTotals[++week];

            next.netActiveVotes += prev.netActiveVotes;
            for (uint256 i; i < len;) {
                next.totalDistPerVote[i] += prev.totalDistPerVote[i];
                unchecked {
                    ++i;
                }
            }
        }
        emit AdvanceEpoch(goal, lastProcessedWeek);
        lastProcessedWeek = goal;
    }

    /// @notice distributes a reward among all tokens, weighted by voting power
    /// @notice The reward gets allocated to all positions that have locked in
    /// @notice the current week. Fails, intentionally, if this number is zero.
    /// @notice Total rewards cannot exceed 2^128 tokens.
    /// @param _rewardTokenId index of the reward in `rewardTokens`
    /// @param _amount amount of reward token to distribute.
    function distributeReward(uint256 _rewardTokenId, uint256 _amount) external nonReentrant {
        if (lastProcessedWeek != currentWeek()) revert AdvanceWeekFirst();
        if (_amount == 0) revert NotValid();
        if (_rewardTokenId == 0) revert NotValid(); // @dev rewardTokens[0] is 0x0

        WeekTotals storage totals = weekTotals[lastProcessedWeek];
        IERC20 rewardToken = rewardTokens[_rewardTokenId];
        // If this is a DBZ then there are no positions to give the reward to.
        // Since reward eligibility starts in the week after locking, there is
        // no way to give out rewards THIS week.
        // Cast is safe: `netActiveVotes` is at most zero by construction of
        // weekly totals and the requirement that they are up to date.
        totals.totalDistPerVote[_rewardTokenId] += (_amount * DIST_PRECISION) / uint256(totals.netActiveVotes);

        rewardToken.safeTransferFrom(msg.sender, address(this), _amount);

        emit DistributeReward(address(rewardToken), msg.sender, _amount, _rewardTokenId);
    }

    // =========
    //   OWNER
    // =========
    /**
     * @notice Set the rescue mode.
     */
    function setRescueMode(bool _rescueMode) external onlyOwner {
        emit RescueMode(_rescueMode);
        rescueMode = _rescueMode;
    }

    /**
     * @notice Set the `VIRTUAL_TOTAL_AMOUNT` state variable.
     * @param _virtualTotalAmount The new state variable value.
     */
    function setVirtualTotalAmount(uint256 _virtualTotalAmount) external onlyOwner {
        emit SetVirtualTotalAmount(_virtualTotalAmount, VIRTUAL_TOTAL_AMOUNT);
        VIRTUAL_TOTAL_AMOUNT = _virtualTotalAmount;
    }

    /**
     * @notice Set the minimum weight factor.
     * @param _minWeightFactor The new minimum weight factor.
     */
    function setMinWeightFactor(uint256 _minWeightFactor) external onlyOwner {
        emit SetMinWeightFactor(_minWeightFactor, MIN_WEIGHT_FACTOR);
        MIN_WEIGHT_FACTOR = _minWeightFactor;
    }

    function setMaxRewardTokensLength(uint256 _length) external onlyOwner {
        emit LogMaxRewardsLength(maxRewardTokens, _length, rewardTokens.length);
        maxRewardTokens = _length;
    }

    /**
     * @notice Add a reward token to the list of reward tokens.
     * @param _token The address of the reward token.
     */
    function addRewardToken(IERC20 _token) external onlyOwner returns (uint256) {
        if (rewardTokenIndex[_token] != 0) revert Registered();
        if (rewardTokens.length + 1 > maxRewardTokens) {
            revert TokenLimitReached();
        }
        rewardTokens.push(_token);

        uint256 newTokenIndex = rewardTokens.length - 1;
        rewardTokenIndex[_token] = newTokenIndex;

        emit AddRewardToken(address(_token), newTokenIndex);

        return newTokenIndex;
    }

    /**
     * @notice updates the Cluster address.
     * @dev can only be called by the owner.
     * @param _cluster the new address.
     */
    function setCluster(ICluster _cluster) external onlyOwner {
        if (address(_cluster) == address(0)) revert NotValid();
        cluster = _cluster;
        emit SetCluster(address(_cluster));
    }

    /**
     * @notice Un/Pauses this contract.
     */
    function setPause(bool _pauseState) external {
        if (!cluster.hasRole(msg.sender, keccak256("PAUSABLE")) && msg.sender != owner()) revert NotAuthorized();
        if (_pauseState) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @notice Set the emergency sweep cooldown
     */
    function setEmergencySweepCooldown(uint256 _emergencySweepCooldown) external onlyOwner {
        emergencySweepCooldown = _emergencySweepCooldown;
        emit SetEmergencySweepCooldown(_emergencySweepCooldown);
    }

    /**
     * @notice Activate the emergency sweep cooldown
     */
    function activateEmergencySweep() external onlyOwner {
        lastEmergencySweep = block.timestamp;
        emit ActivateEmergencySweep();
    }

    /**
     * @notice Emergency sweep of all tokens in case of a critical issue.
     * Strategy is to sweep tokens, then recreate positions with them on a new contract.
     *
     * @dev Only the owner with role `TWTAP_EMERGENCY_SWEEP` can call this function.
     */
    function emergencySweepLocks() external onlyOwner {
        if (block.timestamp < lastEmergencySweep + emergencySweepCooldown) revert EmergencySweepCooldownNotReached();
        if (!cluster.hasRole(msg.sender, keccak256("TWTAP_EMERGENCY_SWEEP"))) revert NotAuthorized();

        tapOFT.transfer(owner(), tapOFT.balanceOf(address(this)));
    }

    /**
     * @notice Emergency sweep of all rewards in case of a critical issue.
     * Strategy is to sweep tokens, then distribute reward on a new contract.
     *
     * @dev Only the owner with role `TWTAP_EMERGENCY_SWEEP` can call this function.
     */
    function emergencySweepRewards() external onlyOwner {
        if (block.timestamp < lastEmergencySweep + emergencySweepCooldown) revert EmergencySweepCooldownNotReached();
        if (!cluster.hasRole(msg.sender, keccak256("TWTAP_EMERGENCY_SWEEP"))) revert NotAuthorized();

        uint256 len = rewardTokens.length;
        // Index starts at 1, see constructor
        for (uint256 i = 1; i < len; ++i) {
            IERC20 token = rewardTokens[i];
            if (token != IERC20(address(0x0))) {
                token.safeTransfer(owner(), token.balanceOf(address(this)));
            }
        }
    }

    // ============
    //   INTERNAL
    // ============
    function _claimRewardsForToken(uint256 _tokenId) private returns (uint256[] memory amounts_) {
        // Either the owner or a delegate can claim the rewards
        // In this case it's `TapToken` to claim the rewards on behalf of the user and send them xChain.
        address owner = _ownerOf(_tokenId);

        if (owner != msg.sender && !isERC721Approved(owner, msg.sender, address(this), _tokenId)) {
            revert NotApproved(_tokenId, msg.sender);
        }

        amounts_ = _claimRewards(_tokenId, msg.sender);
    }

    /// @notice returns week for timestamp
    function _timestampToWeek(uint256 timestamp) internal view returns (uint256) {
        return ((timestamp - creation) / EPOCH_DURATION);
    }

    /**
     * @dev Claim rewards on a token.
     * @return amounts_ Claimed amount of each reward token.
     */
    function _claimRewards(uint256 _tokenId, address _to) internal returns (uint256[] memory amounts_) {
        amounts_ = claimable(_tokenId);
        uint256 len = amounts_.length;
        unchecked {
            for (uint256 i; i < len; ++i) {
                uint256 amount = amounts_[i];
                if (amount > 0) {
                    // Math is safe: `amount` calculated safely in `claimable()`
                    claimed[_tokenId][i] += amount;
                    rewardTokens[i].safeTransfer(_to, amount);
                    emit ClaimReward(address(rewardTokens[i]), _to, _tokenId, amount, i);
                }
            }
        }
    }

    /**
     * @notice Release the TAP locked in a position whose votes have expired.
     * @dev Clean up the twAML participation and delete the voting power if existing.
     * @dev !!!!!!!!!! Make sure to verify ownership of `_tokenId` and `_to` !!!!!!!!!!
     *
     * @param _tokenId tokenId whose locked TAP to claim
     * @param _to address to receive the TAP
     */
    function _releaseTap(uint256 _tokenId, address _to) internal returns (uint256 releasedAmount) {
        Participation memory position = participants[_tokenId];

        // If in rescue mode, allow the release of the TAP even if the lock has not expired.
        if (!rescueMode) {
            if (position.expiry > block.timestamp) revert LockNotExpired();
        }

        if (position.tapReleased) {
            return 0;
        }

        releasedAmount = position.tapAmount;

        // Remove participation
        if (position.hasVotingPower) {
            TWAMLPool memory pool = twAML;
            unchecked {
                --pool.totalParticipants;
            }

            // Inverse of the participation. The participation entry tracks
            // the average magnitude as it was at the time the participant
            // entered. When going the other way around, this value matches the
            // one in the pool, but here it does not.
            if (position.divergenceForce) {
                if (pool.cumulative > position.averageMagnitude) {
                    pool.cumulative -= position.averageMagnitude;
                } else {
                    pool.cumulative = EPOCH_DURATION;
                }
            } else {
                pool.cumulative += position.averageMagnitude;
            }

            // Save new weight
            pool.totalDeposited -= position.tapAmount;

            twAML = pool; // Save twAML exit
            emit AMLDivergence(pool.cumulative, pool.averageMagnitude, pool.totalParticipants); // Register new voting power event
        }

        participants[_tokenId].tapReleased = true;
        tapOFT.transfer(_to, releasedAmount);

        emit ExitPosition(_tokenId, _to, releasedAmount);
    }

    /// @notice Checks if an element is in an array
    /// @param _check The element to check
    /// @param _array The array to check in
    function _existInArray(address _check, address[] memory _array) internal pure returns (bool) {
        uint256 len = _array.length;
        unchecked {
            for (uint256 i; i < len; ++i) {
                if (_array[i] == _check) {
                    return true;
                }
            }
        }
        return false;
    }

    /// @notice Returns the chain ID of the current network.
    /// @dev Used for dev purposes.
    function _getChainId() internal view virtual returns (uint256) {
        return block.chainid;
    }

    function _baseURI() internal view override(ERC721, ERC721NftLoader) returns (string memory) {
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize)
        internal
        virtual
        override(ERC721, ERC721Permit)
    {
        super._afterTokenTransfer(from, to, firstTokenId, batchSize);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

interface INFTLoader {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

import "tapioca-periph/interfaces/yieldbox/IYieldBox.sol";

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {BaseBoringBatchable} from "@boringcrypto/boring-solidity/contracts/BoringBatchable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Tapioca
import {IPearlmit, PearlmitHandler} from "tapioca-periph/pearlmit/PearlmitHandler.sol";
import {ERC721NftLoader} from "contracts/erc721NftLoader/ERC721NftLoader.sol";
import {ERC721Permit} from "tapioca-periph/utils/ERC721Permit.sol"; // TODO audit

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

// TODO naming
struct TapOption {
    uint128 entry; // time when the option position was created
    uint128 expiry; // timestamp, as once one wise man said, the sun will go dark before this overflows
    uint128 discount; // discount in basis points
    uint256 tOLP; // tOLP token ID
}

contract OTAP is ERC721, ERC721Permit, ERC721Enumerable, ERC721NftLoader, PearlmitHandler, BaseBoringBatchable {
    uint256 public mintedOTAP; // total number of OTAP minted
    address public broker; // address of the onlyBroker

    mapping(uint256 => TapOption) public options; // tokenId => Option

    constructor(IPearlmit _pearlmit, address _owner)
        ERC721NftLoader("Option TAP", "oTAP", _owner)
        ERC721Permit("Option TAP")
        PearlmitHandler(_pearlmit)
    {}

    // ==========
    //   EVENTS
    // ==========
    event Mint(address indexed to, uint256 indexed tokenId, TapOption indexed option);
    event Burn(address indexed from, uint256 indexed tokenId, TapOption indexed option);

    error NotAuthorized();
    error OnlyBroker();
    error OnlyOnce();

    // =========
    //    READ
    // =========

    /**
     * @inheritdoc ERC721NftLoader
     */
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721NftLoader) returns (string memory) {
        return ERC721NftLoader.tokenURI(tokenId);
    }

    function isApprovedOrOwner(address _spender, uint256 _tokenId) external view returns (bool) {
        return _isApprovedOrOwner(_spender, _tokenId)
            || isERC721Approved(_ownerOf(_tokenId), _spender, address(this), _tokenId);
    }

    /// @notice Return the owner of the tokenId and the attributes of the option.
    function attributes(uint256 _tokenId) external view returns (address, TapOption memory) {
        return (ownerOf(_tokenId), options[_tokenId]);
    }

    /// @notice Check if a token exists
    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    // ==========
    //    WRITE
    // ==========

    /// @notice mints an OTAP
    /// @param _to address to mint to
    /// @param _expiry timestamp
    /// @param _discount TAP discount in basis points
    /// @param _tOLP tOLP token ID
    function mint(address _to, uint128 _expiry, uint128 _discount, uint256 _tOLP) external returns (uint256 tokenId) {
        if (msg.sender != broker) revert OnlyBroker();

        tokenId = ++mintedOTAP;
        TapOption storage option = options[tokenId];
        option.entry = uint128(block.timestamp);
        option.expiry = _expiry;
        option.discount = _discount;
        option.tOLP = _tOLP;

        _safeMint(_to, tokenId);
        emit Mint(_to, tokenId, option);
    }

    /// @notice burns an OTAP
    /// @param _tokenId tokenId to burn
    function burn(uint256 _tokenId) external {
        if (msg.sender != broker) revert OnlyBroker();
        _burn(_tokenId);

        emit Burn(msg.sender, _tokenId, options[_tokenId]);
    }

    /// @notice tOB claim
    function brokerClaim() external {
        if (broker != address(0)) revert OnlyOnce();
        broker = msg.sender;
    }

    function _baseURI() internal view override(ERC721, ERC721NftLoader) returns (string memory) {
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize)
        internal
        virtual
        override(ERC721, ERC721Permit)
    {
        super._afterTokenTransfer(from, to, firstTokenId, batchSize);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Tapioca
import {TapiocaOptionLiquidityProvision, LockPosition, SingularityPool} from "./TapiocaOptionLiquidityProvision.sol";
import {IPearlmit, PearlmitHandler} from "tapioca-periph/pearlmit/PearlmitHandler.sol";
import {ITapiocaOracle} from "tapioca-periph/interfaces/periph/ITapiocaOracle.sol";
import {ICluster} from "tapioca-periph/interfaces/periph/ICluster.sol";
import {TapToken} from "contracts/tokens/TapToken.sol";
import {OTAP, TapOption} from "./oTAP.sol";
import {TWAML} from "./twAML.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

struct Participation {
    bool hasVotingPower;
    bool divergenceForce; // 0 negative, 1 positive
    uint256 averageMagnitude;
}

struct TWAMLPool {
    uint256 totalParticipants;
    uint256 averageMagnitude;
    uint256 totalDeposited;
    uint256 cumulative;
}

struct PaymentTokenOracle {
    ITapiocaOracle oracle;
    bytes oracleData;
}

contract TapiocaOptionBroker is Pausable, Ownable, PearlmitHandler, IERC721Receiver, TWAML, ReentrancyGuard {
    using SafeERC20 for IERC20;

    TapiocaOptionLiquidityProvision public immutable tOLP;
    bytes public tapOracleData;
    TapToken public immutable tapOFT;
    OTAP public immutable oTAP;
    ITapiocaOracle public tapOracle;

    ICluster public cluster;

    uint256 public epochTAPValuation; // TAP price for the current epoch
    uint256 public epoch; // Represents the number of weeks since the start of the contract

    mapping(uint256 => Participation) public participants; // tOLPTokenID => Participation
    mapping(uint256 => mapping(uint256 => uint256)) public oTAPCalls; // oTAPTokenID => epoch => amountExercised

    mapping(uint256 => mapping(uint256 => uint256)) public singularityGauges; // epoch => sglAssetId => availableTAP

    mapping(ERC20 => PaymentTokenOracle) public paymentTokens; // Token address => PaymentTokenOracle
    address public paymentTokenBeneficiary; // Where to collect the payment tokens

    /// ===== TWAML ======
    mapping(uint256 => TWAMLPool) public twAML; // sglAssetId => twAMLPool

    /// @dev Virtual total amount to add to the total when computing twAML participation right. Default 10_000 * 1e18.
    uint256 private VIRTUAL_TOTAL_AMOUNT = 10_000 ether;

    uint256 public MIN_WEIGHT_FACTOR = 1000; // In BPS, default 10%
    uint256 constant dMAX = 500_000; // 50 * 1e4; 0% - 50% discount
    uint256 constant dMIN = 0;
    uint256 public immutable EPOCH_DURATION; // 7 days = 604800

    /// @notice starts time for emissions
    /// @dev initialized in the constructor with block.timestamp
    uint256 public emissionsStartTime;

    /// @notice Total amount of participation per epoch
    mapping(uint256 epoch => mapping(uint256 sglAssetID => int256 netAmount)) public netDepositedForEpoch;
    /// =====-------======

    error NotEqualDurations();
    error NotAuthorized();
    error NoActiveSingularities();
    error NoLiquidity();
    error OptionExpired();
    error PaymentTokenNotSupported();
    error OneEpochCooldown();
    error TooHigh();
    error TooLong();
    error TooLow();
    error DurationTooShort();
    error PositionNotValid();
    error LockNotExpired();
    error TooSoon();
    error Failed();
    error TransferFailed();
    error SingularityInRescueMode();
    error PaymentTokenValuationNotValid();
    error LockExpired();
    error AdvanceEpochFirst();
    error DurationNotMultiple();
    error NotValid();

    constructor(
        address _tOLP,
        address _oTAP,
        address payable _tapOFT,
        address _paymentTokenBeneficiary,
        uint256 _epochDuration,
        IPearlmit _pearlmit,
        address _owner
    ) PearlmitHandler(_pearlmit) {
        paymentTokenBeneficiary = _paymentTokenBeneficiary;
        tOLP = TapiocaOptionLiquidityProvision(_tOLP);

        if (_epochDuration != TapiocaOptionLiquidityProvision(_tOLP).EPOCH_DURATION()) revert NotEqualDurations();

        tapOFT = TapToken(_tapOFT);
        oTAP = OTAP(_oTAP);
        EPOCH_DURATION = _epochDuration;

        _transferOwnership(_owner);
    }

    // ==========
    //   EVENTS
    // ==========
    event Participate(
        uint256 indexed epoch,
        uint256 indexed sglAssetId,
        uint256 totalDeposited,
        uint256 otapTokenId,
        uint256 tolpTokenId,
        uint256 discount
    );
    event AMLDivergence(uint256 indexed epoch, uint256 cumulative, uint256 averageMagnitude, uint256 totalParticipants);
    event ExerciseOption(
        uint256 indexed epoch, address indexed to, ERC20 indexed paymentToken, uint256 otapTokenId, uint256 tapAmount
    );
    event NewEpoch(uint256 indexed epoch, uint256 extractedTap, uint256 epochTapValuation);
    event ExitPosition(uint256 indexed epoch, uint256 indexed otapTokenId, uint256 tolpTokenId);
    event SetPaymentToken(ERC20 indexed paymentToken, ITapiocaOracle oracle, bytes oracleData);
    event SetTapOracle(ITapiocaOracle oracle, bytes oracleData);

    // ==========
    //    READ
    // ==========
    /// @notice Returns the current week given a timestamp
    function timestampToWeek(uint256 timestamp) external view returns (uint256) {
        if (timestamp == 0) {
            timestamp = block.timestamp;
        }
        if (timestamp < emissionsStartTime) return 0;

        return _timestampToWeek(timestamp);
    }

    /// @notice Returns the current week
    function getCurrentWeek() external view returns (uint256) {
        return _timestampToWeek(block.timestamp);
    }

    /// @notice Returns the details of an oTAP position including its tOLP lock position
    /// @param _oTAPTokenID The oTAP token ID
    /// @param epochId The epoch id of which to get the claimed TAP for - if 0, current epoch will be used
    /// @return tOLPLockPosition The tOLP lock position of the oTAP position
    /// @return oTAPPosition The details of the oTAP position
    /// @return claimedTapInEpoch The amount of TAP claimed in specified epoch
    function getOptionPosition(uint256 _oTAPTokenID, uint256 epochId)
        external
        view
        returns (LockPosition memory tOLPLockPosition, TapOption memory oTAPPosition, uint256 claimedTapInEpoch)
    {
        if (epochId == 0) {
            epochId = epoch;
        }

        (, oTAPPosition) = oTAP.attributes(_oTAPTokenID);
        tOLPLockPosition = tOLP.getLock(oTAPPosition.tOLP);
        claimedTapInEpoch = oTAPCalls[_oTAPTokenID][epochId];
    }

    /// @notice Returns the details of TOLP Singularity Pool, twAML pool and gauge for a given sglAssetId
    /// @param _singularity The singularity address
    /// @param epochId The epoch id of which to get the tap emitted for the pool - if 0, current epoch will be used
    /// @return assetId The Singularity asset id = YB asset id
    /// @return totalDeposited The total deposited amount in the pool
    /// @return weight The weight of the pool
    /// @return isInRescue True if the singularity is in rescue mode
    /// @return tapEmittedInCurrentEpoch The amount of TAP emitted in the current epoch
    /// @return twAMLPool The twAML Pool details
    function getSingularityPoolInfo(IERC20 _singularity, uint256 epochId)
        external
        view
        returns (
            uint256 assetId,
            uint256 totalDeposited,
            uint256 weight,
            bool isInRescue,
            uint256 tapEmittedInCurrentEpoch,
            TWAMLPool memory twAMLPool
        )
    {
        if (epochId == 0) {
            epochId = epoch;
        }

        (assetId, totalDeposited, weight, isInRescue) = tOLP.activeSingularities(_singularity);
        twAMLPool = twAML[assetId];
        tapEmittedInCurrentEpoch = singularityGauges[epochId][assetId];
    }

    /// @notice Returns the details of an OTC deal for a given oTAP token ID and a payment token.
    ///         The oracle uses the last peeked value, and not the latest one, so the payment amount may be different.
    /// @param _oTAPTokenID The oTAP token ID
    /// @param _paymentToken The payment token
    /// @param _tapAmount The amount of TAP to be exchanged. If 0 it will use the full amount of TAP eligible for the deal
    /// @return eligibleTapAmount The amount of TAP eligible for the deal
    /// @return paymentTokenAmount The amount of payment tokens required for the deal
    /// @return tapAmount The amount of TAP to be exchanged
    function getOTCDealDetails(uint256 _oTAPTokenID, ERC20 _paymentToken, uint256 _tapAmount)
        external
        view
        returns (uint256 eligibleTapAmount, uint256 paymentTokenAmount, uint256 tapAmount)
    {
        // Load data
        (, TapOption memory oTAPPosition) = oTAP.attributes(_oTAPTokenID);
        LockPosition memory tOLPLockPosition = tOLP.getLock(oTAPPosition.tOLP);

        {
            if (!_isPositionActive(tOLPLockPosition)) revert OptionExpired();
        }

        uint256 cachedEpoch = epoch;

        PaymentTokenOracle memory paymentTokenOracle = paymentTokens[_paymentToken];

        // Check requirements
        if (paymentTokenOracle.oracle == ITapiocaOracle(address(0))) {
            revert PaymentTokenNotSupported();
        }
        if (block.timestamp < tOLPLockPosition.lockTime + EPOCH_DURATION) {
            revert OneEpochCooldown();
        } // Can only exercise after 1 epoch duration

        // Get eligible OTC amount
        {
            uint256 gaugeTotalForEpoch = singularityGauges[cachedEpoch][tOLPLockPosition.sglAssetID];
            uint256 netAmount = uint256(netDepositedForEpoch[cachedEpoch][tOLPLockPosition.sglAssetID]);
            if (netAmount == 0) revert NoLiquidity();

            eligibleTapAmount = muldiv(tOLPLockPosition.ybShares, gaugeTotalForEpoch, netAmount);
            eligibleTapAmount -= oTAPCalls[_oTAPTokenID][cachedEpoch]; // Subtract already exercised amount
            if (eligibleTapAmount < _tapAmount) revert TooHigh();
        }

        tapAmount = _tapAmount == 0 ? eligibleTapAmount : _tapAmount;
        if (tapAmount < 1e18) revert TooLow();
        // Get TAP valuation
        uint256 otcAmountInUSD = tapAmount * epochTAPValuation; // Divided by TAP decimals
        // Get payment token valuation
        (, uint256 paymentTokenValuation) = paymentTokenOracle.oracle.peek(paymentTokenOracle.oracleData);
        // Get payment token amount
        paymentTokenAmount = _getDiscountedPaymentAmount(
            otcAmountInUSD, paymentTokenValuation, oTAPPosition.discount, _paymentToken.decimals()
        );
    }

    // ===========
    //    WRITE
    // ===========

    /// @notice Participate in twAMl voting and mint an oTAP position.
    ///         Exercising the option is not possible on participation week.
    ///         Lock duration should be a multiple of 1 EPOCH, and have a minimum of 1 EPOCH.
    /// @param _tOLPTokenID The tokenId of the tOLP position
    function participate(uint256 _tOLPTokenID) external whenNotPaused nonReentrant returns (uint256 oTAPTokenID) {
        // Compute option parameters
        LockPosition memory lock = tOLP.getLock(_tOLPTokenID);
        uint128 lockExpiry = lock.lockTime + lock.lockDuration;

        if (block.timestamp >= lockExpiry) revert LockExpired();
        if (_timestampToWeek(block.timestamp) > epoch) revert AdvanceEpochFirst();

        bool isPositionActive = _isPositionActive(lock);
        if (!isPositionActive) revert OptionExpired();

        if (lock.lockDuration < EPOCH_DURATION) revert DurationTooShort();
        if (lock.lockDuration % EPOCH_DURATION != 0) revert DurationNotMultiple();

        TWAMLPool memory pool = twAML[lock.sglAssetID];

        if (pool.cumulative == 0) {
            pool.cumulative = EPOCH_DURATION;
        }

        // Transfer tOLP position to this contract
        // tOLP.transferFrom(msg.sender, address(this), _tOLPTokenID);
        {
            bool isErr = pearlmit.transferFromERC721(msg.sender, address(this), address(tOLP), _tOLPTokenID);
            if (isErr) revert TransferFailed();
        }

        uint256 magnitude = computeMagnitude(uint256(lock.lockDuration), pool.cumulative);
        uint256 target = computeTarget(dMIN, dMAX, magnitude, pool.cumulative);

        // Revert if the lock 4x the cumulative
        if (magnitude > pool.cumulative * 4) revert TooLong();

        bool divergenceForce;
        // Participate in twAMl voting
        bool hasVotingPower =
            lock.ybShares >= computeMinWeight(pool.totalDeposited + VIRTUAL_TOTAL_AMOUNT, MIN_WEIGHT_FACTOR);
        if (hasVotingPower) {
            pool.totalParticipants++; // Save participation
            pool.averageMagnitude = (pool.averageMagnitude + magnitude) / pool.totalParticipants; // compute new average magnitude

            // Compute and save new cumulative
            divergenceForce = lock.lockDuration >= pool.cumulative;
            if (divergenceForce) {
                pool.cumulative += pool.averageMagnitude;
            } else {
                if (pool.cumulative > pool.averageMagnitude) {
                    pool.cumulative -= pool.averageMagnitude;
                } else {
                    pool.cumulative = EPOCH_DURATION;
                }
            }

            // Save new weight
            pool.totalDeposited += lock.ybShares;

            twAML[lock.sglAssetID] = pool; // Save twAML participation
            emit AMLDivergence(epoch, pool.cumulative, pool.averageMagnitude, pool.totalParticipants); // Register new voting power event
        }
        // Save twAML participation
        participants[_tOLPTokenID] = Participation(hasVotingPower, divergenceForce, pool.averageMagnitude);

        // Record amount for next epoch exercise
        netDepositedForEpoch[epoch + 1][lock.sglAssetID] += int256(uint256(lock.ybShares));

        uint256 lastEpoch = _timestampToWeek(lockExpiry);
        // And remove it from last epoch
        // Math is safe, check `_emitToGauges()`
        netDepositedForEpoch[lastEpoch + 1][lock.sglAssetID] -= int256(uint256(lock.ybShares));

        // Mint oTAP position
        oTAPTokenID = oTAP.mint(msg.sender, lockExpiry, uint128(target), _tOLPTokenID);
        emit Participate(epoch, lock.sglAssetID, pool.totalDeposited, oTAPTokenID, _tOLPTokenID, target);
    }

    /// @notice Exit a twAML participation and delete the voting power if existing
    /// @param _oTAPTokenID The tokenId of the oTAP position
    function exitPosition(uint256 _oTAPTokenID) external whenNotPaused {
        if (!oTAP.exists(_oTAPTokenID)) revert PositionNotValid();

        // Load data
        (, TapOption memory oTAPPosition) = oTAP.attributes(_oTAPTokenID);
        LockPosition memory lock = tOLP.getLock(oTAPPosition.tOLP);

        bool isSGLInRescueMode = _isSGLInRescueMode(lock);

        // If SGL is in rescue, bypass the lock expiration
        if (!isSGLInRescueMode) {
            if (block.timestamp < lock.lockTime + lock.lockDuration) {
                revert LockNotExpired();
            }
        }

        Participation memory participation = participants[oTAPPosition.tOLP];

        // Remove participation
        // If the SGL is in rescue mode, bypass the voting power removal
        if (!isSGLInRescueMode && participation.hasVotingPower) {
            TWAMLPool memory pool = twAML[lock.sglAssetID];

            if (participation.divergenceForce) {
                if (pool.cumulative > participation.averageMagnitude) {
                    pool.cumulative -= participation.averageMagnitude;
                } else {
                    pool.cumulative = EPOCH_DURATION;
                }
            } else {
                pool.cumulative += participation.averageMagnitude;
            }

            pool.totalDeposited -= lock.ybShares;

            unchecked {
                --pool.totalParticipants;
            }

            twAML[lock.sglAssetID] = pool; // Save twAML exit
            emit AMLDivergence(epoch, pool.cumulative, pool.averageMagnitude, pool.totalParticipants); // Register new voting power event
        }

        // Delete participation and burn oTAP position
        address otapOwner = oTAP.ownerOf(_oTAPTokenID);
        delete participants[oTAPPosition.tOLP];
        oTAP.burn(_oTAPTokenID);

        // Transfer position back to oTAP owner
        tOLP.transferFrom(address(this), otapOwner, oTAPPosition.tOLP);

        emit ExitPosition(epoch, _oTAPTokenID, oTAPPosition.tOLP);
    }

    /// @notice Exercise an oTAP position
    /// @param _oTAPTokenID tokenId of the oTAP position, position must be active
    /// @param _paymentToken Address of the payment token to use, must be whitelisted
    /// @param _tapAmount Amount of TAP to exercise. If 0, the full amount is exercised
    function exerciseOption(uint256 _oTAPTokenID, ERC20 _paymentToken, uint256 _tapAmount) external whenNotPaused {
        // Load data
        (address owner, TapOption memory oTAPPosition) = oTAP.attributes(_oTAPTokenID);
        LockPosition memory tOLPLockPosition = tOLP.getLock(oTAPPosition.tOLP);
        {
            bool isPositionActive = _isPositionActive(tOLPLockPosition);
            if (!isPositionActive) revert OptionExpired();
        }

        uint256 cachedEpoch = epoch;

        PaymentTokenOracle memory paymentTokenOracle = paymentTokens[_paymentToken];

        // Check requirements
        if (paymentTokenOracle.oracle == ITapiocaOracle(address(0))) {
            revert PaymentTokenNotSupported();
        }

        // Check allowance. Make sure to consume it post call
        {
            // oTAP.isApprovedOrOwner(msg.sender, _oTAPTokenID)
            if (owner != msg.sender && !isERC721Approved(owner, msg.sender, address(oTAP), _oTAPTokenID)) {
                revert NotAuthorized();
            }
        }

        if (_timestampToWeek(block.timestamp) > epoch) revert AdvanceEpochFirst();

        if (block.timestamp < oTAPPosition.entry + EPOCH_DURATION) {
            revert OneEpochCooldown();
        } // Can only exercise after 1 epoch duration

        // Get eligible OTC amount
        uint256 gaugeTotalForEpoch = singularityGauges[cachedEpoch][tOLPLockPosition.sglAssetID];
        uint256 netAmount = uint256(netDepositedForEpoch[cachedEpoch][tOLPLockPosition.sglAssetID]);
        if (netAmount == 0) revert NoLiquidity();
        uint256 eligibleTapAmount = muldiv(tOLPLockPosition.ybShares, gaugeTotalForEpoch, netAmount);
        eligibleTapAmount -= oTAPCalls[_oTAPTokenID][cachedEpoch]; // Subtract already exercised amount
        if (eligibleTapAmount < _tapAmount) revert TooHigh();

        uint256 chosenAmount = _tapAmount == 0 ? eligibleTapAmount : _tapAmount;
        if (chosenAmount < 1e18) revert TooLow();
        oTAPCalls[_oTAPTokenID][cachedEpoch] += chosenAmount; // Adds up exercised amount to current epoch

        // Finalize the deal
        _processOTCDeal(_paymentToken, paymentTokenOracle, chosenAmount, oTAPPosition.discount);

        emit ExerciseOption(cachedEpoch, msg.sender, _paymentToken, _oTAPTokenID, chosenAmount);
    }

    // TODO Check at how many SGls this function breaks. Do we need to split calls into 2+ Txs?
    /// @notice Start a new epoch, extract TAP from the TapOFT contract,
    ///         emit it to the active singularities and get the price of TAP for the epoch.
    function newEpoch() external {
        if (!cluster.hasRole(msg.sender, keccak256("NEW_EPOCH"))) revert NotAuthorized();
        if (_timestampToWeek(block.timestamp) <= epoch) revert TooSoon();

        uint256[] memory singularities = tOLP.getSingularities();
        if (singularities.length == 0) revert NoActiveSingularities();

        epoch++;

        // Extract TAP + emit to gauges
        uint256 epochTAP = tapOFT.emitForWeek();
        _emitToGauges(epochTAP);

        // Get epoch TAP valuation
        bool success;
        (success, epochTAPValuation) = tapOracle.get(tapOracleData);
        if (!success) revert Failed();
        emit NewEpoch(epoch, epochTAP, epochTAPValuation);
    }

    /// @notice Claim the Broker role of the oTAP contract. Init emissions on TOB and TapToken.
    /// @dev Can only be called once. External calls should revert if already called.
    function init() external {
        oTAP.brokerClaim();

        emissionsStartTime = block.timestamp;
        tapOFT.initEmissions();
    }

    // =========
    //   OWNER
    // =========

    /**
     * @notice Set the `VIRTUAL_TOTAL_AMOUNT` state variable.
     * @param _virtualTotalAmount The new state variable value.
     */
    function setVirtualTotalAmount(uint256 _virtualTotalAmount) external onlyOwner {
        VIRTUAL_TOTAL_AMOUNT = _virtualTotalAmount;
    }

    /**
     * @notice Set the minimum weight factor.
     * @param _minWeightFactor The new minimum weight factor.
     */
    function setMinWeightFactor(uint256 _minWeightFactor) external onlyOwner {
        MIN_WEIGHT_FACTOR = _minWeightFactor;
    }

    /// @notice Set the TapOFT Oracle address and data
    /// @param _tapOracle The new TapOFT Oracle address
    /// @param _tapOracleData The new TapOFT Oracle data
    function setTapOracle(ITapiocaOracle _tapOracle, bytes calldata _tapOracleData) external onlyOwner {
        tapOracle = _tapOracle;
        tapOracleData = _tapOracleData;

        emit SetTapOracle(_tapOracle, _tapOracleData);
    }

    /// @notice Activate or deactivate a payment token
    /// @dev set the oracle to address(0) to deactivate, expect the same decimal precision as TAP oracle
    function setPaymentToken(ERC20 _paymentToken, ITapiocaOracle _oracle, bytes calldata _oracleData)
        external
        onlyOwner
    {
        paymentTokens[_paymentToken].oracle = _oracle;
        paymentTokens[_paymentToken].oracleData = _oracleData;

        emit SetPaymentToken(_paymentToken, _oracle, _oracleData);
    }

    /// @notice Set the payment token beneficiary
    /// @param _paymentTokenBeneficiary The new payment token beneficiary
    function setPaymentTokenBeneficiary(address _paymentTokenBeneficiary) external onlyOwner {
        paymentTokenBeneficiary = _paymentTokenBeneficiary;
    }

    /// @notice Collect the payment tokens from the OTC deals
    /// @param _paymentTokens The payment tokens to collect
    function collectPaymentTokens(address[] calldata _paymentTokens) external onlyOwner nonReentrant {
        address _paymentTokenBeneficiary = paymentTokenBeneficiary;
        if (_paymentTokenBeneficiary == address(0)) {
            revert PaymentTokenNotSupported();
        }
        uint256 len = _paymentTokens.length;

        unchecked {
            for (uint256 i; i < len; ++i) {
                IERC20 paymentToken = IERC20(_paymentTokens[i]);
                paymentToken.safeTransfer(_paymentTokenBeneficiary, paymentToken.balanceOf(address(this)));
            }
        }
    }

    /**
     * @notice updates the Cluster address.
     * @dev can only be called by the owner.
     * @param _cluster the new address.
     */
    function setCluster(ICluster _cluster) external onlyOwner {
        if (address(_cluster) == address(0)) revert NotValid();
        cluster = _cluster;
    }

    /**
     * @notice Un/Pauses this contract.
     */
    function setPause(bool _pauseState) external {
        if (!cluster.hasRole(msg.sender, keccak256("PAUSABLE")) && msg.sender != owner()) revert NotAuthorized();
        if (_pauseState) {
            _pause();
        } else {
            _unpause();
        }
    }

    // ============
    //   INTERNAL
    // ============
    /// @notice returns week for timestamp
    function _timestampToWeek(uint256 timestamp) internal view returns (uint256) {
        return ((timestamp - emissionsStartTime) / EPOCH_DURATION);
    }

    /// @notice Check if a singularity is in rescue mode
    /// @param _lock The lock position
    function _isSGLInRescueMode(LockPosition memory _lock) internal view returns (bool) {
        (,,, bool rescue) = tOLP.activeSingularities(tOLP.sglAssetIDToAddress(_lock.sglAssetID));
        return rescue;
    }

    /// @notice Check if a position is active, whether it is expired or SGL is in rescue mode
    /// @dev Check if the current week is less than or equal the expiry week
    /// @param _lock The lock position
    /// @return isPositionActive True if the position is active
    function _isPositionActive(LockPosition memory _lock) internal view returns (bool isPositionActive) {
        if (_lock.lockTime == 0) revert PositionNotValid();
        if (_isSGLInRescueMode(_lock)) revert SingularityInRescueMode();

        uint256 expiryWeek = _timestampToWeek(_lock.lockTime + _lock.lockDuration);

        isPositionActive = epoch <= expiryWeek;
    }

    /// @notice Process the OTC deal, transfer the payment token to the broker and the TAP amount to the user
    /// @param _paymentToken The payment token
    /// @param _paymentTokenOracle The oracle of the payment token
    /// @param tapAmount The amount of TAP that the user has to receive
    /// @param discount The discount that the user has to apply to the OTC deal
    function _processOTCDeal(
        ERC20 _paymentToken,
        PaymentTokenOracle memory _paymentTokenOracle,
        uint256 tapAmount,
        uint256 discount
    ) internal {
        // Get TAP valuation
        uint256 otcAmountInUSD = tapAmount * epochTAPValuation;

        // Get payment token valuation
        (bool success, uint256 paymentTokenValuation) = _paymentTokenOracle.oracle.get(_paymentTokenOracle.oracleData);
        if (!success) revert Failed();

        // Calculate payment amount and initiate the transfers
        uint256 discountedPaymentAmount =
            _getDiscountedPaymentAmount(otcAmountInUSD, paymentTokenValuation, discount, _paymentToken.decimals());

        uint256 balBefore = _paymentToken.balanceOf(address(this));
        // IERC20(address(_paymentToken)).safeTransferFrom(msg.sender, address(this), discountedPaymentAmount);
        {
            bool isErr =
                pearlmit.transferFromERC20(msg.sender, address(this), address(_paymentToken), discountedPaymentAmount);
            if (isErr) revert TransferFailed();
        }
        uint256 balAfter = _paymentToken.balanceOf(address(this));
        if (balAfter - balBefore != discountedPaymentAmount) {
            revert TransferFailed();
        }

        tapOFT.extractTAP(msg.sender, tapAmount);
    }

    /// @notice Computes the discounted payment amount for a given OTC amount in USD
    /// @param _otcAmountInUSD The OTC amount in USD, 18 decimals
    /// @param _paymentTokenValuation The payment token valuation in USD, 18 decimals
    /// @param _discount The discount in BPS
    /// @param _paymentTokenDecimals The payment token decimals
    /// @return paymentAmount The discounted payment amount
    function _getDiscountedPaymentAmount(
        uint256 _otcAmountInUSD,
        uint256 _paymentTokenValuation,
        uint256 _discount,
        uint256 _paymentTokenDecimals
    ) internal pure returns (uint256 paymentAmount) {
        if (_paymentTokenValuation == 0) revert PaymentTokenValuationNotValid();

        uint256 discountedOTCAmountInUSD = _otcAmountInUSD - muldiv(_otcAmountInUSD, _discount, 100e4); // 1e4 is discount decimals, 100 is discount percentage

        // Calculate payment amount
        paymentAmount = discountedOTCAmountInUSD / _paymentTokenValuation;

        if (_paymentTokenDecimals <= 18) {
            paymentAmount = paymentAmount / (10 ** (18 - _paymentTokenDecimals));
        } else {
            paymentAmount = paymentAmount * (10 ** (_paymentTokenDecimals - 18));
        }
    }

    /// @notice Emit TAP to the gauges equitably and update the net deposited amounts for each pool
    /// @dev Assume the epoch has been updated
    function _emitToGauges(uint256 _epochTAP) internal {
        SingularityPool[] memory sglPools = tOLP.getSingularityPools();
        uint256 totalWeights = tOLP.totalSingularityPoolWeights();

        uint256 len = sglPools.length;
        unchecked {
            // For each pool
            for (uint256 i; i < len; ++i) {
                uint256 currentPoolWeight = sglPools[i].poolWeight;
                uint256 quotaPerSingularity = muldiv(currentPoolWeight, _epochTAP, totalWeights);
                uint256 sglAssetID = sglPools[i].sglAssetID;
                // Emit weekly TAP to the pool
                singularityGauges[epoch][sglAssetID] = quotaPerSingularity;

                // Update net deposited amounts
                mapping(uint256 sglAssetID => int256 netAmount) storage prev = netDepositedForEpoch[epoch - 1];
                mapping(uint256 sglAssetID => int256 netAmount) storage curr = netDepositedForEpoch[epoch];

                // Pass previous epoch net amount to the next epoch
                // Expired positions are offset, check `participate()`
                curr[sglAssetID] += prev[sglAssetID];
            }
        }
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {BaseBoringBatchable} from "@boringcrypto/boring-solidity/contracts/BoringBatchable.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC721Permit} from "tapioca-periph/utils/ERC721Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Tapioca
import {IPearlmit, PearlmitHandler} from "tapioca-periph/pearlmit/PearlmitHandler.sol";
import {ICluster} from "tapioca-periph/interfaces/periph/ICluster.sol";
import {IYieldBox} from "contracts/interfaces/IYieldBox.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

struct LockPosition {
    uint128 sglAssetID; // Singularity market YieldBox asset ID
    uint128 ybShares; // amount of YieldBox shares locked.
    uint128 lockTime; // time when the tokens were locked
    uint128 lockDuration; // duration of the lock
}

struct SingularityPool {
    uint256 sglAssetID; // Singularity market YieldBox asset ID
    uint256 totalDeposited; // total amount of YieldBox shares deposited, used for pool share calculation
    uint256 poolWeight; // Pool weight to calculate emission
    bool rescue; // If true, the pool will be used to rescue funds in case of emergency
}

contract TapiocaOptionLiquidityProvision is
    Ownable,
    PearlmitHandler,
    ERC721,
    ERC721Permit,
    ERC721Enumerable,
    BaseBoringBatchable,
    Pausable,
    ReentrancyGuard
{
    uint256 public tokenCounter; // Counter for token IDs
    mapping(uint256 => LockPosition) public lockPositions; // TokenID => LockPosition

    IYieldBox public immutable yieldBox;
    address public tapiocaOptionBroker;

    // Singularity market address => SingularityPool (YieldBox Asset ID is 0 if not active)
    mapping(IERC20 => SingularityPool) public activeSingularities;
    mapping(uint256 => IERC20) public sglAssetIDToAddress; // Singularity market YieldBox asset ID => Singularity market address
    uint256[] public singularities; // Array of active singularity asset IDs

    uint256 public rescueCooldown = 2 days; // Cooldown before a singularity pool can be put in rescue mode
    mapping(uint256 sglId => uint256 rescueTime) public sglRescueRequest; // Time when the pool was put in rescue mode

    uint256 public totalSingularityPoolWeights; // Total weight of all active singularity pools
    uint256 public immutable EPOCH_DURATION; // 7 days = 604800
    uint256 public constant MAX_LOCK_DURATION = 100 * 365 days; // 100 years

    ICluster public cluster;

    uint256 public emergencySweepCooldown = 2 days;
    uint256 public lastEmergencySweep;

    error NotRegistered();
    error InvalidSingularity();
    error DurationTooShort();
    error DurationTooLong();
    error SharesNotValid();
    error SingularityInRescueMode();
    error SingularityNotActive();
    error PositionExpired();
    error LockNotExpired();
    error AlreadyActive();
    error AssetIdNotValid();
    error DuplicateAssetId();
    error AlreadyRegistered();
    error NotAuthorized();
    error NotInRescueMode();
    error NotActive();
    error RescueCooldownNotReached();
    error TransferFailed();
    error TobIsHolder();
    error NotValid();
    error EmergencySweepCooldownNotReached();

    constructor(address _yieldBox, uint256 _epochDuration, IPearlmit _pearlmit, address _owner)
        ERC721("TapiocaOptionLiquidityProvision", "tOLP")
        ERC721Permit("TapiocaOptionLiquidityProvision")
        PearlmitHandler(_pearlmit)
    {
        yieldBox = IYieldBox(_yieldBox);
        EPOCH_DURATION = _epochDuration;
        _transferOwnership(_owner);
    }

    // ==========
    //   EVENTS
    // ==========
    event Mint(
        address indexed to,
        uint256 indexed sglAssetId,
        address sglAddress,
        uint256 tolpTokenId,
        uint128 lockDuration,
        uint128 ybShares
    );
    event Burn(address indexed from, uint256 indexed sglAssetId, address sglAddress, uint256 tolpTokenId);
    event UpdateTotalSingularityPoolWeights(uint256 totalSingularityPoolWeights);
    event SetSGLPoolWeight(uint256 indexed sglAssetId, address sglAddress, uint256 poolWeight);
    event RequestSglPoolRescue(uint256 indexed sglAssetId, uint256 timestamp);
    event ActivateSGLPoolRescue(uint256 indexed sglAssetId, address sglAddress);
    event RegisterSingularity(uint256 indexed sglAssetId, address sglAddress, uint256 poolWeight);
    event UnregisterSingularity(uint256 indexed sglAssetId, address sglAddress);
    event SetEmergencySweepCooldown(uint256 emergencySweepCooldown);
    event ActivateEmergencySweep();

    // ===============
    //    MODIFIERS
    // ===============
    modifier updateTotalSGLPoolWeights() {
        _;
        totalSingularityPoolWeights = _computeSGLPoolWeights();
        emit UpdateTotalSingularityPoolWeights(totalSingularityPoolWeights);
    }

    // =========
    //    READ
    // =========
    /// @notice Returns the lock position of a given tOLP NFT and if it's active
    /// @param _tokenId tOLP NFT ID
    function getLock(uint256 _tokenId) external view returns (LockPosition memory) {
        return lockPositions[_tokenId];
    }

    /// @notice Returns the active singularity YieldBox ID markets
    /// @return singularities Array of YieldBox asset IDs
    function getSingularities() external view returns (uint256[] memory) {
        return singularities;
    }

    /// @notice Returns the active singularity pool data, excluding the ones in rescue
    /// @return pools Array of SingularityPool
    function getSingularityPools() external view returns (SingularityPool[] memory) {
        uint256[] memory _singularities = singularities;
        uint256 len = _singularities.length;

        SingularityPool[] memory pools = new SingularityPool[](len);
        unchecked {
            for (uint256 i; i < len; ++i) {
                SingularityPool memory sgl = activeSingularities[sglAssetIDToAddress[_singularities[i]]];
                // If the pool is in rescue, don't return it
                if (sgl.rescue) {
                    continue;
                }
                pools[i] = sgl;
            }
        }
        return pools;
    }

    /// @notice Returns the total amount of locked YieldBox shares for a given singularity market
    /// @return shares Amount of YieldBox shares locked
    /// @return amount Amount of YieldBox shares locked converted in amount
    function getTotalPoolDeposited(uint256 _sglAssetId) external view returns (uint256 shares, uint256 amount) {
        shares = activeSingularities[sglAssetIDToAddress[_sglAssetId]].totalDeposited;
        amount = yieldBox.toAmount(_sglAssetId, shares, false);
    }

    /// @notice Return an approval or ownership status of a given address for a given tOLP NFT
    /// @param _spender Address to check
    /// @param _tokenId tOLP NFT ID
    function isApprovedOrOwner(address _spender, uint256 _tokenId) external view returns (bool) {
        return _isApprovedOrOwner(_spender, _tokenId);
    }

    /// @notice Returns super approve check or if the spender is approved for the tOLP NFT on Pearlmit
    function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view override returns (bool) {
        return super._isApprovedOrOwner(_spender, _tokenId)
            || isERC721Approved(_ownerOf(_tokenId), _spender, address(this), _tokenId);
    }

    // ==========
    //    WRITE
    // ==========

    /// @notice Locks YieldBox shares for a given duration
    /// @param _to Address to mint the tOLP NFT to
    /// @param _singularity Singularity market address
    /// @param _lockDuration Duration of the lock
    /// @param _ybShares Amount of YieldBox shares to lock
    /// @return tokenId The ID of the minted NFT
    function lock(address _to, IERC20 _singularity, uint128 _lockDuration, uint128 _ybShares)
        external
        nonReentrant
        whenNotPaused
        returns (uint256 tokenId)
    {
        if (_lockDuration < EPOCH_DURATION) revert DurationTooShort();
        if (_lockDuration > MAX_LOCK_DURATION) revert DurationTooLong();

        if (_ybShares == 0) revert SharesNotValid();

        SingularityPool memory sgl = activeSingularities[_singularity];
        if (sgl.rescue) revert SingularityInRescueMode();

        uint256 sglAssetID = sgl.sglAssetID;
        if (sglAssetID == 0) revert SingularityNotActive();

        // Transfer the Singularity position to this contract
        // yieldBox.transfer(msg.sender, address(this), sglAssetID, _ybShares);
        {
            bool isErr =
                pearlmit.transferFromERC1155(msg.sender, address(this), address(yieldBox), sglAssetID, _ybShares);
            if (isErr) {
                revert TransferFailed();
            }
        }
        activeSingularities[_singularity].totalDeposited += _ybShares;

        // Create the lock position
        tokenId = ++tokenCounter;
        LockPosition storage lockPosition = lockPositions[tokenId];
        lockPosition.lockTime = uint128(block.timestamp);
        lockPosition.sglAssetID = uint128(sglAssetID);
        lockPosition.lockDuration = _lockDuration;
        lockPosition.ybShares = _ybShares;

        // Mint the tOLP NFT position
        _safeMint(_to, tokenId);

        emit Mint(_to, sglAssetID, address(_singularity), tokenId, _lockDuration, _ybShares);
    }

    /// @notice Unlocks tOLP tokens
    /// @param _tokenId ID of the position to unlock
    /// @param _singularity Singularity market address
    function unlock(uint256 _tokenId, IERC20 _singularity) external whenNotPaused {
        if (!_exists(_tokenId)) revert PositionExpired();
        address tokenOwner = _ownerOf(_tokenId);
        if (tokenOwner == tapiocaOptionBroker) revert TobIsHolder(); // First unlock from broker

        LockPosition memory lockPosition = lockPositions[_tokenId];
        SingularityPool memory sgl = activeSingularities[_singularity];

        // If the singularity is in rescue, the lock can be unlocked at any time
        if (!sgl.rescue) {
            // If not, the lock must be expired
            if (block.timestamp < lockPosition.lockTime + lockPosition.lockDuration) revert LockNotExpired();
        }
        if (sgl.sglAssetID != lockPosition.sglAssetID) {
            revert InvalidSingularity();
        }

        _burn(_tokenId);
        delete lockPositions[_tokenId];

        // Transfer the YieldBox position back to the owner
        yieldBox.transfer(address(this), tokenOwner, lockPosition.sglAssetID, lockPosition.ybShares);
        activeSingularities[_singularity].totalDeposited -= lockPosition.ybShares;

        emit Burn(tokenOwner, lockPosition.sglAssetID, address(_singularity), _tokenId);
    }

    // =========
    //   OWNER
    // =========

    /**
     * @notice Sets the Tapioca Option Broker address
     */
    function setTapiocaOptionBroker(address _tob) external onlyOwner {
        tapiocaOptionBroker = _tob;
    }

    /// @notice Sets the pool weight of a given singularity market
    /// @param singularity Singularity market address
    /// @param weight Weight of the pool
    function setSGLPoolWeight(IERC20 singularity, uint256 weight) external onlyOwner updateTotalSGLPoolWeights {
        if (activeSingularities[singularity].sglAssetID == 0) {
            revert NotRegistered();
        }
        activeSingularities[singularity].poolWeight = weight;

        emit SetSGLPoolWeight(activeSingularities[singularity].sglAssetID, address(singularity), weight);
    }

    function setRescueCooldown(uint256 _rescueCooldown) external onlyOwner {
        rescueCooldown = _rescueCooldown;
    }

    /**
     * @notice Requests a singularity market to be put in rescue mode. Needs to be activated later on in `activateSGLPoolRescue()`
     * @param _sglAssetID YieldBox asset ID of the singularity market
     */
    function requestSglPoolRescue(uint256 _sglAssetID) external onlyOwner {
        if (_sglAssetID == 0) revert NotRegistered();
        if (sglRescueRequest[_sglAssetID] != 0) revert AlreadyActive();

        sglRescueRequest[_sglAssetID] = block.timestamp;

        emit RequestSglPoolRescue(_sglAssetID, block.timestamp);
    }

    /// @notice Sets the rescue status of a given singularity market
    /// @param singularity Singularity market address
    function activateSGLPoolRescue(IERC20 singularity) external onlyOwner updateTotalSGLPoolWeights {
        SingularityPool memory sgl = activeSingularities[singularity];

        if (sgl.sglAssetID == 0) revert NotRegistered();
        if (sgl.rescue) revert AlreadyActive();
        if (sglRescueRequest[sgl.sglAssetID] == 0) revert NotActive();
        if (block.timestamp < sglRescueRequest[sgl.sglAssetID] + rescueCooldown) revert RescueCooldownNotReached();

        activeSingularities[singularity].rescue = true;

        emit ActivateSGLPoolRescue(sgl.sglAssetID, address(singularity));
    }

    /// @notice Registers a new singularity market
    /// @param singularity Singularity market address
    /// @param assetID YieldBox asset ID of the singularity market
    /// @param weight Weight of the pool
    function registerSingularity(IERC20 singularity, uint256 assetID, uint256 weight)
        external
        onlyOwner
        updateTotalSGLPoolWeights
    {
        if (assetID == 0) revert AssetIdNotValid();
        if (sglAssetIDToAddress[assetID] != IERC20(address(0))) {
            revert DuplicateAssetId();
        }
        if (activeSingularities[singularity].sglAssetID != 0) {
            revert AlreadyRegistered();
        }

        activeSingularities[singularity].sglAssetID = assetID;
        activeSingularities[singularity].poolWeight = weight > 0 ? weight : 1;
        sglAssetIDToAddress[assetID] = singularity;
        singularities.push(assetID);

        emit RegisterSingularity(assetID, address(singularity), activeSingularities[singularity].poolWeight);
    }

    /// @notice Un-registers a singularity market
    /// @param singularity Singularity market address
    function unregisterSingularity(IERC20 singularity) external onlyOwner updateTotalSGLPoolWeights {
        uint256 sglAssetID = activeSingularities[singularity].sglAssetID;
        if (sglAssetID == 0) revert NotRegistered();
        if (!activeSingularities[singularity].rescue) revert NotInRescueMode();

        unchecked {
            uint256[] memory _singularities = singularities;
            uint256 sglLength = _singularities.length;
            uint256 sglLastIndex = sglLength - 1;

            for (uint256 i; i < sglLength; i++) {
                if (_singularities[i] == sglAssetID) {
                    // If in the middle, copy last element on deleted element, then pop
                    delete activeSingularities[singularity];
                    delete sglAssetIDToAddress[sglAssetID];
                    delete sglRescueRequest[sglAssetID];

                    if (i != sglLastIndex) {
                        singularities[i] = _singularities[sglLastIndex];
                    }
                    singularities.pop();
                    emit UnregisterSingularity(uint256(sglAssetID), address(singularity));
                    break;
                }
            }
        }

        emit UnregisterSingularity(uint256(sglAssetID), address(singularity));
    }

    /**
     * @notice updates the Cluster address.
     * @dev can only be called by the owner.
     * @param _cluster the new address.
     */
    function setCluster(ICluster _cluster) external onlyOwner {
        if (address(_cluster) == address(0)) revert NotValid();
        cluster = _cluster;
    }

    /**
     * @notice Un/Pauses this contract.
     */
    function setPause(bool _pauseState) external {
        if (!cluster.hasRole(msg.sender, keccak256("PAUSABLE")) && msg.sender != owner()) revert NotAuthorized();
        if (_pauseState) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @notice Set the emergency sweep cooldown
     */
    function setEmergencySweepCooldown(uint256 _emergencySweepCooldown) external onlyOwner {
        emergencySweepCooldown = _emergencySweepCooldown;
        emit SetEmergencySweepCooldown(_emergencySweepCooldown);
    }

    /**
     * @notice Activate the emergency sweep cooldown
     */
    function activateEmergencySweep() external onlyOwner {
        lastEmergencySweep = block.timestamp;
        emit ActivateEmergencySweep();
    }

    /**
     * @notice Emergency sweep of a token from the contract
     */
    function emergencySweep() external onlyOwner {
        if (block.timestamp < lastEmergencySweep + emergencySweepCooldown) revert EmergencySweepCooldownNotReached();
        if (!cluster.hasRole(msg.sender, keccak256("TOLP_EMERGENCY_SWEEP"))) revert NotAuthorized();

        uint256 len = singularities.length;
        for (uint256 i; i < len; i++) {
            SingularityPool memory sgl = activeSingularities[sglAssetIDToAddress[singularities[i]]];
            // Retrieve only the ones not in rescue
            if (!sgl.rescue) {
                // Try to sweep the funds even if one fails
                try yieldBox.transfer(
                    address(this), owner(), sgl.sglAssetID, yieldBox.balanceOf(address(this), sgl.sglAssetID)
                ) {} catch {}
            }
        }
    }

    // =========
    //  INTERNAL
    // =========

    /// @notice Compute the total pool weight of all active singularity markets, excluding the ones in rescue
    /// @return total Total weight of all active singularity markets
    function _computeSGLPoolWeights() internal view returns (uint256) {
        uint256 total;
        uint256 len = singularities.length;
        for (uint256 i; i < len; i++) {
            SingularityPool memory sgl = activeSingularities[sglAssetIDToAddress[singularities[i]]];
            if (!sgl.rescue) {
                total += sgl.poolWeight;
            }
        }

        return total;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        return bytes4(0);
    }

    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize)
        internal
        virtual
        override(ERC721, ERC721Permit)
    {
        super._afterTokenTransfer(from, to, firstTokenId, batchSize);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

abstract contract FullMath {
    // https://xn--2-umb.com/21/muldiv/
    function muldiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // Handle division by zero
            require(denominator > 0);

            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Short circuit 256 by 256 division
            // This saves gas when a * b is small, at the cost of making the
            // large case a bit more expensive. Depending on your use case you
            // may want to remove this short circuit and always go through the
            // 512 bit path.
            if (prod1 == 0) {
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Handle overflow, the result must be < 2**256
            require(prod1 < denominator);

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            // Note mulmod(_, _, 0) == 0
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1 unless denominator is zero, then twos is zero.
            uint256 twos = denominator & (~denominator + 1);
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            // If denominator is zero the inverse starts with 2
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson itteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256
            // If denominator is zero, inv is now 128

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }
}

abstract contract TWAML is FullMath {
    /// @notice Compute the minimum weight to participate in the twAML voting mechanism
    /// @param _totalWeight The total weight of the twAML system
    /// @param _minWeightFactor The minimum weight factor in BPS
    function computeMinWeight(uint256 _totalWeight, uint256 _minWeightFactor) internal pure returns (uint256) {
        uint256 mul = (_totalWeight * _minWeightFactor);
        return mul >= 1e4 ? mul / 1e4 : _totalWeight;
    }

    function computeMagnitude(uint256 _timeWeight, uint256 _cumulative) internal pure returns (uint256) {
        return sqrt(_timeWeight * _timeWeight + _cumulative * _cumulative) - _cumulative;
    }

    function computeTarget(uint256 _dMin, uint256 _dMax, uint256 _magnitude, uint256 _cumulative)
        internal
        pure
        returns (uint256)
    {
        if (_cumulative == 0) {
            return _dMax;
        }
        uint256 target = (_magnitude * _dMax) / _cumulative;
        target = target > _dMax ? _dMax : target < _dMin ? _dMin : target;
        return target;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// Tapioca
import {BaseTapiocaOmnichainEngine} from "tapioca-periph/tapiocaOmnichainEngine/BaseTapiocaOmnichainEngine.sol";
import {IPearlmit} from "tapioca-periph/interfaces/periph/IPearlmit.sol";
import {ICluster} from "tapioca-periph/interfaces/periph/ICluster.sol";
import {BaseTapTokenMsgType} from "./BaseTapTokenMsgType.sol";
import {TwTAP} from "contracts/governance/twTAP.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

abstract contract BaseTapToken is BaseTapiocaOmnichainEngine, BaseTapTokenMsgType {
    uint16 internal constant PT_LOCK_TWTAP = 870;
    uint16 internal constant PT_UNLOCK_TWTAP = 871;
    uint16 internal constant PT_CLAIM_REWARDS = 872;

    /// @dev Can't be set as constructor params because TwTAP is deployed after TapToken. TwTAP constructor needs TapOFT as param.
    TwTAP public twTap;

    constructor(
        string memory _name,
        string memory _symbol,
        address _endpoint,
        address _delegate,
        address _extExec,
        IPearlmit _pearlmit,
        ICluster _cluster
    ) BaseTapiocaOmnichainEngine(_name, _symbol, _endpoint, _delegate, _extExec, _pearlmit, _cluster) {}

    error twTapNotSet();

    modifier twTapExists() {
        if (address(twTap) == address(0)) revert twTapNotSet();
        _;
    }

    /**
     * @notice set the twTAP address, can be done only once.
     */
    function setTwTAP(address _twTap) external virtual {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

abstract contract BaseTapTokenMsgType {
    uint16 internal constant MSG_LOCK_TWTAP = 870;
    uint16 internal constant MSG_UNLOCK_TWTAP = 871;
    uint16 internal constant MSG_CLAIM_REWARDS = 872;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// Tapioca
import {
    ITapiocaOmnichainEngine,
    ERC20PermitApprovalMsg,
    ERC721PermitApprovalMsg,
    LZSendParam,
    ERC20PermitStruct,
    ERC721PermitStruct,
    ERC20PermitApprovalMsg,
    ERC721PermitApprovalMsg,
    RemoteTransferMsg
} from "tapioca-periph/interfaces/periph/ITapiocaOmnichainEngine.sol";
import {IPearlmit} from "tapioca-periph/interfaces/periph/IPearlmit.sol";
import {ICluster} from "tapioca-periph/interfaces/periph/ICluster.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

interface ITapToken is ITapiocaOmnichainEngine {
    /**
     * EVENTS
     */
    event LockTwTapReceived(address indexed user, uint96 duration, uint256 amount);
    /// @dev twTAP unlock operation received.
    event UnlockTwTapReceived(uint256 tokenId, uint256 amount);

    /**
     * ERRORS
     */
    error TwTapAlreadySet();
    error OnlyHostChain(); // Can execute an action only on host chain

    enum Module {
        NonModule, //0
        TapTokenSender,
        TapTokenReceiver
    }

    struct TapTokenConstructorData {
        uint256 epochDuration;
        address endpoint;
        address contributors;
        address earlySupporters;
        address supporters;
        address lTap;
        address dao;
        address airdrop;
        uint256 governanceEid;
        address owner;
        address tapTokenSenderModule;
        address tapTokenReceiverModule;
        address extExec;
        IPearlmit pearlmit;
        ICluster cluster;
    }
}

/// ================================
/// ========= TAP COMPOSE ==========
/// ================================

/**
 * @param user The user address to lock in the tokens.
 * @param duration The duration of the lock.
 * @param amount The amount of TAP to lock.
 */
struct LockTwTapPositionMsg {
    address user;
    uint96 duration;
    uint256 amount;
}

/**
 * @param user The user address to unlock the tokens.
 * @param tokenId The tokenId of the TwTap position to unlock.
 */
struct UnlockTwTapPositionMsg {
    uint256 tokenId;
}

/**
 * @param tokenId The tokenId of the TwTap position to claim rewards from.
 * @param sendParam The parameter for the send operation.
 */
struct ClaimTwTapRewardsMsg {
    uint256 tokenId;
    LZSendParam[] sendParam;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

// TODO move to a common file
/**
 * @title ModuleManager
 * @author TapiocaDAO
 * @notice Help to modularize a contract.
 *
 */
abstract contract ModuleManager {
    /// @notice returns whitelisted modules
    mapping(uint8 module => address moduleAddress) internal _moduleAddresses;

    error ModuleManager__ModuleNotAuthorized();

    /**
     * @notice Sets a module to the whitelist.
     * @param _module The module to add.
     * @param _moduleAddress The module address.
     */
    function _setModule(uint8 _module, address _moduleAddress) internal {
        _moduleAddresses[_module] = _moduleAddress;
    }

    /**
     * @dev Returns the module address, if whitelisted.
     * @param _module The module we wants to execute.
     */
    function _extractModule(uint8 _module) internal view returns (address) {
        address module = _moduleAddresses[_module];
        if (module == address(0)) revert ModuleManager__ModuleNotAuthorized();

        return module;
    }

    /**
     * @notice Execute an call to a given module.
     *
     * @param _module The module to execute.
     * @param _data The data to execute.
     * @param _forwardRevert If true, forward the revert message from the module.
     *
     * @return returnData The return data from the module execution, if any.
     */
    function _executeModule(uint8 _module, bytes memory _data, bool _forwardRevert)
        internal
        returns (bytes memory returnData)
    {
        bool success = true;
        address module = _extractModule(_module);

        (success, returnData) = module.delegatecall(_data);
        if (!success && !_forwardRevert) {
            revert(_getRevertMsg(returnData));
        }
    }

    /**
     * @notice Return the revert message from an external call.
     * @param _returnData The return data from the external call.
     */
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        if (_returnData.length > 1000) return "Module: reason too long";

        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Module: data";
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

//LZ
import {
    MessagingReceipt,
    OFTReceipt,
    SendParam,
    MessagingFee
} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {IMessagingChannel} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessagingChannel.sol";
import {OAppReceiver} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppReceiver.sol";
import {Origin} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import {OFTCore} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";

// External
import {ERC20Permit, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

// Tapioca
import {BaseTapiocaOmnichainEngine} from "tapioca-periph/tapiocaOmnichainEngine/BaseTapiocaOmnichainEngine.sol";
import {TapiocaOmnichainSender} from "tapioca-periph/tapiocaOmnichainEngine/TapiocaOmnichainSender.sol";
import {ERC20PermitStruct, ITapToken, LZSendParam} from "contracts/tokens/ITapToken.sol";
import {ModuleManager} from "./module/ModuleManager.sol";
import {TapTokenReceiver} from "./TapTokenReceiver.sol";
import {TwTAP} from "contracts/governance/twTAP.sol";
import {TapTokenSender} from "./TapTokenSender.sol";
import {BaseTapToken} from "./BaseTapToken.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

/// @title Tapioca OFTv2 token
/// @notice OFT compatible TAP token
/// @dev Emissions E(x)= E(x-1) - E(x-1) * D with E being total supply a x week, and D the initial decay rate
contract TapToken is BaseTapToken, ModuleManager, ERC20Permit, Pausable {
    uint256 public constant INITIAL_SUPPLY = 47_500_000 * 1e18; // Everything minus DSO
    uint256 public dso_supply = 52_500_000 * 1e18; // Emission supply for DSO

    /// @notice the a parameter used in the emission function;
    uint256 constant decay_rate = 8800000000000000; // 0.88%
    uint256 constant DECAY_RATE_DECIMAL = 1e18;

    /// @notice seconds in a week
    uint256 public immutable EPOCH_DURATION;

    /// @notice starts time for emissions
    /// @dev initialized in the constructor with block.timestamp
    uint256 public emissionsStartTime;

    /// @notice returns the amount of emitted TAP for a specific week
    /// @dev week is computed using (timestamp - emissionStartTime) / WEEK
    mapping(uint256 => uint256) public emissionForWeek;

    /// @notice returns the amount minted for a specific week
    /// @dev week is computed using (timestamp - emissionStartTime) / WEEK
    mapping(uint256 => uint256) public mintedInWeek;

    /// @notice returns the minter address
    address public minter;

    /// @notice LayerZero governance chain identifier
    uint256 public governanceEid;

    // ==========
    // *EVENTS*
    // ==========
    /// @notice event emitted when a new minter is set
    event MinterUpdated(address _old, address _new);
    /// @notice event emitted when a new emission is called
    event Emitted(uint256 indexed week, uint256 amount);
    /// @notice event emitted when new TAP is minted
    event Minted(address indexed _by, address indexed _to, uint256 _amount);
    /// @notice event emitted when new TAP is burned
    event Burned(address indexed _from, uint256 _amount);

    error OnlyHostChain();

    // ==========
    // *ERRORS*
    // ==========
    error NotValid(); // Generic error for simple functions
    error AddressWrong();
    error SupplyNotValid(); // Initial supply is not valid
    error AllowanceNotValid();
    error OnlyMinter();
    error TwTapAlreadySet();
    error InitStarted();
    error InitNotStarted();
    error InsufficientEmissions();
    error NotAuthorized();

    // ===========
    // *MODIFIERS*
    // ===========
    modifier onlyMinter() {
        if (msg.sender != minter) revert OnlyMinter();
        _;
    }

    modifier onlyHostChain() {
        if (_getChainId() != governanceEid) revert OnlyHostChain();
        _;
    }

    /**
     * @notice Creates a new TAP OFT type token
     * @dev The initial supply of 100M is not minted here as we have the wrap method
     *
     * Allocation:
     * ============
     * Contributors: 15m
     * Early supporters: 3_500_001
     * Supporters: 14,938,030.34
     * LTAP: 3989472714402321147960046
     * DAO: 6,561,968.66 + remaining for LBP
     * Airdrop: 2.5m
     * == 47.5M ==
     * DSO: 52.5m
     * == 100M ==
     *
     * @param _data.epochDuration The duration of an epoch in seconds.
     * @param _data.endpoint The layer zero address endpoint deployed on the current chain.
     * @param _data.contributors Address of the  contributors.
     * @param _data.earlySupporters Address of early supporters.
     * @param _data.supporters Address of supporters.
     * @param _data.lTap Address of the LBP redemption token, lTap.
     * @param _data.dao Address of the DAO.
     * @param _data.airdrop Address of the airdrop contract.
     * @param _data.governanceEid Governance chain endpoint ID. Should be EID of the twTAP chain.
     * @param _data.owner Address of the conservator/owner.
     * @param _data.tapTokenSenderModule Address of the TapTokenSenderModule.
     * @param _data.tapTokenReceiverModule Address of the TapTokenReceiverModule.
     * @param _data.extExec Address of the external executor.
     */
    constructor(ITapToken.TapTokenConstructorData memory _data)
        BaseTapToken("TapToken", "TAP", _data.endpoint, _data.owner, _data.extExec, _data.pearlmit, _data.cluster)
        ERC20Permit("TAP")
    {
        if (_data.endpoint == address(0)) revert AddressWrong();
        governanceEid = _data.governanceEid;

        // Initialize modules
        if (_data.tapTokenSenderModule == address(0)) revert NotValid();
        if (_data.tapTokenReceiverModule == address(0)) revert NotValid();

        _setModule(uint8(ITapToken.Module.TapTokenSender), _data.tapTokenSenderModule);
        _setModule(uint8(ITapToken.Module.TapTokenReceiver), _data.tapTokenReceiverModule);

        if (_data.epochDuration == 0) revert NotValid();
        EPOCH_DURATION = _data.epochDuration;

        // Mint only on the governance chain
        if (_getChainId() == _data.governanceEid) {
            uint256 lbpSold = 3989472714402321147960046; // LBP sold 3.9m
            uint256 lbpRemaining = (1e18 * 5_000_000) - lbpSold; // Remaining of the  LBP goes to the DAO

            _mint(_data.contributors, 1e18 * 15_000_000);
            _mint(_data.earlySupporters, 1e18 * 3_500_001);
            _mint(_data.supporters, 1e18 * 14_938_030.34);
            _mint(_data.lTap, lbpSold);
            _mint(_data.dao, (1e18 * 6_561_968.66) + lbpRemaining);
            _mint(_data.airdrop, 1e18 * 2_500_000);
            if (totalSupply() != INITIAL_SUPPLY) revert SupplyNotValid();
        }

        _transferOwnership(_data.owner);
    }

    /// =====================
    /// Module setup
    /// =====================

    /**
     * @dev Fallback function should handle calls made by endpoint, which should go to the receiver module.
     */
    fallback() external payable {
        /// @dev Call the receiver module on fallback, assume it's gonna be called by endpoint.
        _executeModule(uint8(ITapToken.Module.TapTokenReceiver), msg.data, false);
    }

    receive() external payable {}

    /**
     * @dev Slightly modified version of the OFT _lzReceive() operation.
     * The composed message is sent to `address(this)` instead of `toAddress`.
     * @dev Internal function to handle the receive on the LayerZero endpoint.
     * @param _origin The origin information.
     *  - srcEid: The source chain endpoint ID.
     *  - sender: The sender address from the src chain.
     *  - nonce: The nonce of the LayerZero message.
     * @param _guid The unique identifier for the received LayerZero message.
     * @param _message The encoded message.
     * @dev _executor The address of the executor.
     * @dev _extraData Additional data.
     */
    function lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor, // @dev unused in the default implementation.
        bytes calldata _extraData // @dev unused in the default implementation.
    ) public payable override {
        // Call the internal OApp implementation of lzReceive.
        _executeModule(
            uint8(ITapToken.Module.TapTokenReceiver),
            abi.encodeWithSelector(OAppReceiver.lzReceive.selector, _origin, _guid, _message, _executor, _extraData),
            false
        );
    }

    /**
     * @notice Execute a call to a module.
     * @dev Example on how `_data` should be encoded:
     *      - abi.encodeCall(IERC20.transfer, (to, amount));
     * @dev Use abi.encodeCall to encode the function call and its parameters with type safety.
     *
     * @param _module The module to execute.
     * @param _data The data to execute. Should be ABI encoded with the selector.
     * @param _forwardRevert If true, forward the revert message from the module.
     *
     * @return returnData The return data from the module execution, if any.
     */
    function executeModule(ITapToken.Module _module, bytes memory _data, bool _forwardRevert)
        external
        payable
        returns (bytes memory returnData)
    {
        return _executeModule(uint8(_module), _data, _forwardRevert);
    }

    /// ========================
    /// Frequently used modules
    /// ========================

    /**
     * @dev Slightly modified version of the OFT send() operation. Includes a `_msgType` parameter.
     * The `_buildMsgAndOptionsByType()` appends the packet type to the message.
     * @dev Executes the send operation.
     * @param _lzSendParam The parameters for the send operation.
     *      - _sendParam: The parameters for the send operation.
     *          - dstEid::uint32: Destination endpoint ID.
     *          - to::bytes32: Recipient address.
     *          - amountToSendLD::uint256: Amount to send in local decimals.
     *          - minAmountToCreditLD::uint256: Minimum amount to credit in local decimals.
     *      - _fee: The calculated fee for the send() operation.
     *          - nativeFee::uint256: The native fee.
     *          - lzTokenFee::uint256: The lzToken fee.
     *      - _extraOptions::bytes: Additional options for the send() operation.
     *      - refundAddress::address: The address to refund the native fee to.
     * @param _composeMsg The composed message for the send() operation. Is a combination of 1 or more TAP specific messages.
     *
     * @return msgReceipt The receipt for the send operation.
     *      - guid::bytes32: The unique identifier for the sent message.
     *      - nonce::uint64: The nonce of the sent message.
     *      - fee: The LayerZero fee incurred for the message.
     *          - nativeFee::uint256: The native fee.
     *          - lzTokenFee::uint256: The lzToken fee.
     * @return oftReceipt The OFT receipt information.
     *      - amountDebitLD::uint256: Amount of tokens ACTUALLY debited in local decimals.
     *      - amountCreditLD::uint256: Amount of tokens to be credited on the remote side.
     */
    function sendPacket(LZSendParam calldata _lzSendParam, bytes calldata _composeMsg)
        public
        payable
        whenNotPaused
        returns (
            MessagingReceipt memory msgReceipt,
            OFTReceipt memory oftReceipt,
            bytes memory message,
            bytes memory options
        )
    {
        (msgReceipt, oftReceipt, message, options) = abi.decode(
            _executeModule(
                uint8(ITapToken.Module.TapTokenSender),
                abi.encodeCall(TapiocaOmnichainSender.sendPacket, (_lzSendParam, _composeMsg)),
                false
            ),
            (MessagingReceipt, OFTReceipt, bytes, bytes)
        );
    }

    /**
     * @dev see `TapiocaOmniChainSender.sendPacketFrom`
     */
    function sendPacketFrom(address _from, LZSendParam calldata _lzSendParam, bytes calldata _composeMsg)
        public
        payable
        whenNotPaused
        returns (
            MessagingReceipt memory msgReceipt,
            OFTReceipt memory oftReceipt,
            bytes memory message,
            bytes memory options
        )
    {
        (msgReceipt, oftReceipt, message, options) = abi.decode(
            _executeModule(
                uint8(ITapToken.Module.TapTokenSender),
                abi.encodeCall(TapiocaOmnichainSender.sendPacketFrom, (_from, _lzSendParam, _composeMsg)),
                false
            ),
            (MessagingReceipt, OFTReceipt, bytes, bytes)
        );
    }

    /**
     * See `OFTCore::send()`
     * @dev override default `send` behavior to add `whenNotPaused` modifier
     */
    function send(SendParam calldata _sendParam, MessagingFee calldata _fee, address _refundAddress)
        external
        payable
        override(OFTCore)
        whenNotPaused
        returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt)
    {
        // @dev Applies the token transfers regarding this send() operation.
        // - amountSentLD is the amount in local decimals that was ACTUALLY sent/debited from the sender.
        // - amountReceivedLD is the amount in local decimals that will be received/credited to the recipient on the remote OFT instance.
        (uint256 amountSentLD, uint256 amountReceivedLD) =
            _debit(msg.sender, _sendParam.amountLD, _sendParam.minAmountLD, _sendParam.dstEid);

        // @dev Builds the options and OFT message to quote in the endpoint.
        (bytes memory message, bytes memory options) = _buildMsgAndOptions(_sendParam, amountReceivedLD);

        // @dev Sends the message to the LayerZero endpoint and returns the LayerZero msg receipt.
        msgReceipt = _lzSend(_sendParam.dstEid, message, options, _fee, _refundAddress);
        // @dev Formulate the OFT receipt.
        oftReceipt = OFTReceipt(amountSentLD, amountReceivedLD);

        emit OFTSent(msgReceipt.guid, _sendParam.dstEid, msg.sender, amountSentLD, amountReceivedLD);
    }

    /// =====================
    /// View
    /// =====================

    /**
     * @notice returns token's decimals
     */
    function decimals() public pure override returns (uint8) {
        return 18;
    }

    /**
     * @notice Returns the current week
     */
    function getCurrentWeek() external view returns (uint256) {
        return _timestampToWeek(block.timestamp);
    }

    /**
     * @notice Returns the current week emission
     */
    function getCurrentWeekEmission() external view returns (uint256) {
        return emissionForWeek[_timestampToWeek(block.timestamp)];
    }

    /**
     * @notice Returns the current week given a timestamp
     * @param timestamp The timestamp to use to compute the week
     */
    function timestampToWeek(uint256 timestamp) external view returns (uint256) {
        if (timestamp == 0) {
            timestamp = block.timestamp;
        }
        if (timestamp < emissionsStartTime) return 0;

        return _timestampToWeek(timestamp);
    }

    /**
     * @dev Returns the hash of the struct used by the permit function.
     * @param _permitData Struct containing permit data.
     */
    function getTypedDataHash(ERC20PermitStruct calldata _permitData) public view returns (bytes32) {
        bytes32 permitTypeHash_ =
            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

        bytes32 structHash_ = keccak256(
            abi.encode(
                permitTypeHash_,
                _permitData.owner,
                _permitData.spender,
                _permitData.value,
                _permitData.nonce,
                _permitData.deadline
            )
        );
        return _hashTypedDataV4(structHash_);
    }

    /// =====================
    /// External
    /// =====================

    /**
     * @notice Initializes the emissions.
     * @dev Can be called only once. By Minter.
     */
    function initEmissions() external onlyMinter {
        if (emissionsStartTime != 0) revert InitStarted();
        emissionsStartTime = block.timestamp;
    }

    /**
     * @notice Mint TAP for the current week. Follow the emission function.
     *
     * @param _to Address to send the minted TAP to
     * @param _amount TAP amount
     */
    function extractTAP(address _to, uint256 _amount) external onlyMinter whenNotPaused {
        if (_amount == 0) revert NotValid();
        uint256 week = _timestampToWeek(block.timestamp);

        uint256 boostedTAP = balanceOf(address(this));
        uint256 availableTap = emissionForWeek[week] - mintedInWeek[week];

        // Check if there are enough emissions for the current week for the requested amount.
        if (availableTap < _amount) {
            // If there are not enough emissions, check if the boosted TAP can cover the difference.
            if (availableTap + boostedTAP < _amount) {
                revert InsufficientEmissions();
            } else {
                // If the boosted TAP can cover the difference, mint the available TAP.
                if (availableTap > 0) {
                    _mint(_to, availableTap);
                    mintedInWeek[week] += availableTap;
                    _amount -= availableTap;
                }

                // And transfer from the boosted TAP.
                _transfer(address(this), _to, _amount);
                emit Minted(msg.sender, _to, _amount);
                return;
            }
        }

        // Mint the requested amount if there are enough emissions.
        _mint(_to, _amount);
        mintedInWeek[week] += _amount;
        emit Minted(msg.sender, _to, _amount);
    }

    /**
     * @notice Burns TAP.
     * @param _amount TAP amount.
     */
    function removeTAP(uint256 _amount) external whenNotPaused {
        _burn(msg.sender, _amount);
        emit Burned(msg.sender, _amount);
    }

    /// =====================
    /// Minter
    /// =====================

    /**
     * @notice Emit the TAP for the current week. Follow the emission function.
     * If there are unclaimed emissions from the previous week, they are added to the current week.
     * If there are some TAP in the contract, use it as boosted TAP.
     *
     * @return the emitted amount.
     */
    function emitForWeek() external onlyMinter onlyHostChain whenNotPaused returns (uint256) {
        if (emissionsStartTime == 0) revert InitNotStarted();

        uint256 week = _timestampToWeek(block.timestamp);
        if (emissionForWeek[week] > 0) return 0;

        // Compute unclaimed emission from last week and add it to the current week emission
        uint256 unclaimed;
        if (week > 0) {
            // Update DSO supply from last minted emissions
            dso_supply -= mintedInWeek[week - 1];

            // Push unclaimed emission from last week to the current week
            unclaimed = emissionForWeek[week - 1] - mintedInWeek[week - 1];
        }
        uint256 emission = _computeEmission();
        emission += unclaimed;

        emissionForWeek[week] = emission;
        emit Emitted(week, emission);

        return emission;
    }

    /// =====================
    /// Owner
    /// =====================

    /**
     * @notice Sets a new minter address.
     * @param _minter the new address
     */
    function setMinter(address _minter) external onlyOwner {
        if (_minter == address(0)) revert NotValid();
        minter = _minter;
        emit MinterUpdated(minter, _minter);
    }

    /**
     * @notice set the twTAP address, can be done only once.
     */
    function setTwTAP(address _twTap) external override onlyOwner onlyHostChain {
        if (address(twTap) != address(0)) {
            revert TwTapAlreadySet();
        }
        twTap = TwTAP(_twTap);
    }

    /**
     * @notice Un/Pauses this contract.
     */
    function setPause(bool _pauseState) external {
        if (!getCluster().hasRole(msg.sender, keccak256("PAUSABLE")) && msg.sender != owner()) revert NotAuthorized();
        if (_pauseState) {
            _pause();
        } else {
            _unpause();
        }
    }

    /// =====================
    /// Internal
    /// =====================

    /**
     * @dev Returns the current week given a timestamp
     * @param timestamp The timestamp to use to compute the week
     */
    function _timestampToWeek(uint256 timestamp) internal view returns (uint256) {
        return ((timestamp - emissionsStartTime) / EPOCH_DURATION);
    }

    /**
     *  @notice returns the available emissions for a given supply
     */
    function _computeEmission() internal view returns (uint256 result) {
        result = (dso_supply * decay_rate) / DECAY_RATE_DECIMAL;
    }

    /**
     * @notice Return the current chain EID.
     */
    function _getChainId() internal view override returns (uint32) {
        return IMessagingChannel(endpoint).eid();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.22;

// LZ
import {OptionsBuilder} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import {OFTMsgCodec} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTMsgCodec.sol";
import {BytesLib} from "solidity-bytes-utils/contracts/BytesLib.sol";

// Tapioca
import {
    ITapToken,
    LockTwTapPositionMsg,
    UnlockTwTapPositionMsg,
    ERC20PermitApprovalMsg,
    ERC721PermitApprovalMsg,
    LZSendParam,
    ClaimTwTapRewardsMsg,
    RemoteTransferMsg
} from "./ITapToken.sol";

import {TapiocaOmnichainEngineCodec} from "tapioca-periph/tapiocaOmnichainEngine/TapiocaOmnichainEngineCodec.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

library TapTokenCodec {
    // ***************************************
    // * Encoding & Decoding TapOFT messages *
    // ***************************************

    /**
     * @notice Encodes the message for the lockTwTapPosition() operation.
     *
     */
    function buildLockTwTapPositionMsg(LockTwTapPositionMsg memory _lockTwTapPositionMsg)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(_lockTwTapPositionMsg.user, _lockTwTapPositionMsg.duration, _lockTwTapPositionMsg.amount);
    }

    /**
     * @notice Decode an encoded message for the lockTwTapPosition() operation.
     *
     * @param _msg The encoded message. see `TapTokenCodec.buildLockTwTapPositionMsg()`
     * @return lockTwTapPositionMsg_ The data of the lock.
     *          - user::address: The user address.
     *          - duration::uint96: The duration of the lock.
     *          - amount::uint256: The amount to be locked.
     */
    function decodeLockTwpTapDstMsg(bytes memory _msg)
        internal
        pure
        returns (LockTwTapPositionMsg memory lockTwTapPositionMsg_)
    {
        // TODO bitwise operators
        // Offsets
        uint8 userOffset_ = 20;
        uint8 durationOffset_ = 32;

        // Decoded data
        address user = BytesLib.toAddress(BytesLib.slice(_msg, 0, userOffset_), 0);
        uint96 duration = BytesLib.toUint96(BytesLib.slice(_msg, userOffset_, 12), 0);
        uint256 amount = BytesLib.toUint256(BytesLib.slice(_msg, durationOffset_, 32), 0);

        // Return structured data
        lockTwTapPositionMsg_ = LockTwTapPositionMsg(user, duration, amount);
    }

    /**
     * @notice Encodes the message for the unlockTwTapPosition() operation.
     *
     */
    function buildUnlockTwTapPositionMsg(UnlockTwTapPositionMsg memory _msg) internal pure returns (bytes memory) {
        return abi.encodePacked(_msg.tokenId);
    }

    /**
     * @notice Decode an encoded message for the unlockTwTapPosition() operation.
     *
     * @param _msg The encoded message. see `TapTokenCodec.buildUnlockTwTapPositionMsg()`
     *          - user::address: The user address.
     *          - tokenId::uint256: The tokenId of the TwTap position to unlock.
     * @return unlockTwTapPositionMsg_ The needed data.
     */
    function decodeUnlockTwTapPositionMsg(bytes memory _msg)
        internal
        pure
        returns (UnlockTwTapPositionMsg memory unlockTwTapPositionMsg_)
    {
        // Return structured data
        unlockTwTapPositionMsg_ = UnlockTwTapPositionMsg(abi.decode(_msg, (uint256)));
    }

    /**
     * @notice Encodes the message for the `remoteTransfer` operation.
     * @param _remoteTransferMsg The owner + LZ send param to pass on the remote chain. (B->A)
     */
    function buildRemoteTransferMsg(RemoteTransferMsg memory _remoteTransferMsg) internal pure returns (bytes memory) {
        return abi.encode(_remoteTransferMsg);
    }

    /**
     * @notice Decode the message for the `remoteTransfer` operation.
     * @param _msg The owner + LZ send param to pass on the remote chain. (B->A)
     */
    function decodeRemoteTransferMsg(bytes memory _msg)
        internal
        pure
        returns (RemoteTransferMsg memory remoteTransferMsg_)
    {
        return abi.decode(_msg, (RemoteTransferMsg));
    }

    /**
     * @notice Encodes the message for the `claimTwpTapRewards` operation.
     * @param _claimTwTapRewardsMsg Struct of the call.
     *        - tokenId::uint256: The tokenId of the TwTap position to claim rewards from.
     *        - lzSendParams::LZSendParam[]: The LZ send params to pass on the remote chain. (B->A)
     */
    function buildClaimTwTapRewards(ClaimTwTapRewardsMsg memory _claimTwTapRewardsMsg)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(_claimTwTapRewardsMsg);
    }

    /**
     * @notice Decode the message for the `claimTwpTapRewards` operation.
     * @param _msg The LZ send params to pass on the remote chain. (B->A)
     *        - tokenId::uint256: The tokenId of the TwTap position to claim rewards from.
     *        - lzSendParams::LZSendParam[]: The LZ send params to pass on the remote chain. (B->A)
     */
    function decodeClaimTwTapRewardsMsg(bytes memory _msg)
        internal
        pure
        returns (ClaimTwTapRewardsMsg memory claimTwTapRewardsMsg_)
    {
        return abi.decode(_msg, (ClaimTwTapRewardsMsg));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// LZ
import {
    MessagingReceipt, OFTReceipt, SendParam
} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {OFTMsgCodec} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTMsgCodec.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {OFTCore} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTCore.sol";
import {Origin} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import {OFT} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";

// External
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Tapioca
import {
    ERC721PermitApprovalMsg,
    UnlockTwTapPositionMsg,
    ERC20PermitApprovalMsg,
    LockTwTapPositionMsg,
    ClaimTwTapRewardsMsg,
    RemoteTransferMsg,
    LZSendParam
} from "./ITapToken.sol";
import {TapiocaOmnichainReceiver} from "tapioca-periph/tapiocaOmnichainEngine/TapiocaOmnichainReceiver.sol";
import {IPearlmit} from "tapioca-periph/interfaces/periph/IPearlmit.sol";
import {ICluster} from "tapioca-periph/interfaces/periph/ICluster.sol";
import {ITOFT} from "tapioca-periph/interfaces/oft/ITOFT.sol";
import {TapTokenSender} from "./TapTokenSender.sol";
import {TapTokenCodec} from "./TapTokenCodec.sol";
import {BaseTapToken} from "./BaseTapToken.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

contract TapTokenReceiver is BaseTapToken, TapiocaOmnichainReceiver, ReentrancyGuard {
    using OFTMsgCodec for bytes;
    using OFTMsgCodec for bytes32;
    using SafeERC20 for IERC20;

    /**
     * @dev Used as a module for `TapToken`. Only delegate calls with `TapToken` state are used.
     * Set the Pearlmit and Cluster to address(0) because they are not used in this contract.
     */
    constructor(string memory _name, string memory _symbol, address _endpoint, address _delegate, address _extExec)
        BaseTapToken(_name, _symbol, _endpoint, _delegate, _extExec, IPearlmit(address(0)), ICluster(address(0)))
    {}

    /// @dev twTAP lock operation received.
    event LockTwTapReceived(address indexed user, uint96 duration, uint256 amount);
    /// @dev twTAP unlock operation received.
    event UnlockTwTapReceived(uint256 tokenId, uint256 amount);
    event ClaimRewardReceived(address indexed token, address indexed to, uint256 amount);

    // See `this._claimTwpTapRewardsReceiver()`. Triggered if the length of the claimed rewards are not equal to the length of the lzSendParam array.
    error InvalidSendParamLength(uint256 expectedLength, uint256 actualLength);

    // ********************* //
    // ***** RECEIVERS ***** //
    // ********************* //

    /**
     * @inheritdoc TapiocaOmnichainReceiver
     */
    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor, /*_executor*/ // @dev unused in the default implementation.
        bytes calldata _extraData /*_extraData*/ // @dev unused in the default implementation.
    ) internal virtual override(OFTCore, TapiocaOmnichainReceiver) {
        TapiocaOmnichainReceiver._lzReceive(_origin, _guid, _message, _executor, _extraData);
    }

    /**
     * @inheritdoc TapiocaOmnichainReceiver
     */
    function _toeComposeReceiver(uint16 _msgType, address _srcChainSender, bytes memory _toeComposeMsg)
        internal
        override
        nonReentrant
        returns (bool success)
    {
        if (_msgType == MSG_LOCK_TWTAP) {
            _lockTwTapPositionReceiver(_srcChainSender, _toeComposeMsg);
        } else if (_msgType == MSG_UNLOCK_TWTAP) {
            _unlockTwTapPositionReceiver(_toeComposeMsg);
        } else if (_msgType == MSG_CLAIM_REWARDS) {
            _claimTwpTapRewardsReceiver(_toeComposeMsg);
        } else {
            return false;
        }

        return true;
    }

    /**
     * @dev Locks TAP for the user in the twTAP contract.
     * @dev The user needs to have approved the TapToken contract to spend the TAP.
     *
     * @param _srcChainSender The address of the sender on the source chain.
     * @param _data The call data containing info about the lock.
     *          - user::address: Address of the user to lock the TAP for.
     *          - duration::uint96: Amount of time to lock for.
     *          - amount::uint256: Amount of TAP to lock.
     */

    // TODO sanitize the user to use approve on behalf of him
    function _lockTwTapPositionReceiver(address _srcChainSender, bytes memory _data) internal virtual twTapExists {
        LockTwTapPositionMsg memory lockTwTapPositionMsg_ = TapTokenCodec.decodeLockTwpTapDstMsg(_data);

        /// @dev xChain owner needs to have approved dst srcChain `sendPacket()` msg.sender in a previous composedMsg. Or be the same address.
        _internalTransferWithAllowance(lockTwTapPositionMsg_.user, _srcChainSender, lockTwTapPositionMsg_.amount);

        // _approve(address(this), address(twTap), lockTwTapPositionMsg_.amount);
        _approve(address(this), address(pearlmit), lockTwTapPositionMsg_.amount);
        pearlmit.approve(
            20, address(this), 0, address(twTap), uint200(lockTwTapPositionMsg_.amount), uint48(block.timestamp + 1)
        );
        twTap.participate(lockTwTapPositionMsg_.user, lockTwTapPositionMsg_.amount, lockTwTapPositionMsg_.duration);
        _approve(address(this), address(pearlmit), 0);

        emit LockTwTapReceived(lockTwTapPositionMsg_.user, lockTwTapPositionMsg_.duration, lockTwTapPositionMsg_.amount);
    }

    /**
     * @dev Unlocks TAP for the user in the twTAP contract.
     * @dev !!! The user needs to have given TwTAP allowance to this contract in order to exit  !!!
     *
     * @param _data The call data containing info about the lock.
     *          - unlockTwTapPositionMsg_::UnlockTwTapPositionMsg: Unlocking data.
     */
    function _unlockTwTapPositionReceiver(bytes memory _data) internal virtual twTapExists {
        UnlockTwTapPositionMsg memory unlockTwTapPositionMsg_ = TapTokenCodec.decodeUnlockTwTapPositionMsg(_data);

        // Send TAP to the user address.
        uint256 tapAmount_ = twTap.exitPosition(unlockTwTapPositionMsg_.tokenId);

        emit UnlockTwTapReceived(unlockTwTapPositionMsg_.tokenId, tapAmount_);
    }

    /**
     * @dev Transfers tokens from this contract to the recipient on the chain A. Flow of calls is: A->B->A.
     * @dev !!! The user needs to have given TwTAP allowance to this contract  !!!
     *
     * @param _data The call data containing info about the transfer (LZSendParam).
     */
    function _claimTwpTapRewardsReceiver(bytes memory _data) internal virtual twTapExists {
        ClaimTwTapRewardsMsg memory claimTwTapRewardsMsg_ = TapTokenCodec.decodeClaimTwTapRewardsMsg(_data);

        // Claim rewards, make sure to have approved this contract on TwTap.
        uint256[] memory claimedAmount_ = twTap.claimRewards(claimTwTapRewardsMsg_.tokenId);
        address owner = twTap.ownerOf(claimTwTapRewardsMsg_.tokenId);
        // Clear the allowance, claimRewards only does an allowance check.
        pearlmit.clearAllowance(owner, 721, address(twTap), claimTwTapRewardsMsg_.tokenId);

        // Check if the claimed amount is equal to the amount of sendParam
        if (
            (claimedAmount_.length - 1) // Remove 1 because the first index doesn't count.
                != claimTwTapRewardsMsg_.sendParam.length
        ) {
            revert InvalidSendParamLength(claimedAmount_.length, claimTwTapRewardsMsg_.sendParam.length);
        }

        // Loop over the tokens, and send them.
        IERC20[] memory rewardTokens_ = twTap.getRewardTokens();
        uint256 rewardTokensLength_ = rewardTokens_.length;

        /// @dev Reward token indexes starts at 1, 0 is reserved.
        /// The index of the claimedAmount_ array is the same as the reward token index.
        /// The index of claimTwTapRewardsMsg_.sendParam should be the same as the reward token index - 1, since it doesn't have the reserved 0 index.
        /// Take that into account when accessing the arrays.
        for (uint256 i = 1; i < rewardTokensLength_;) {
            uint256 sendParamIndex = i - 1; // Remove 1 to account for the reserved 0 index.
            address sendTo_ = OFTMsgCodec.bytes32ToAddress(claimTwTapRewardsMsg_.sendParam[sendParamIndex].sendParam.to);
            address rewardToken_ = address(rewardTokens_[i]);

            // Sanitize the amount to send
            uint256 tokenDecimalConversionRate = ITOFT(rewardToken_).decimalConversionRate();
            uint256 amountWithoutDust = (claimedAmount_[i] / tokenDecimalConversionRate) * tokenDecimalConversionRate;
            uint256 dust = claimedAmount_[i] - amountWithoutDust;

            // Send the dust back to the user locally
            if (dust > 0) {
                IERC20(rewardToken_).safeTransfer(sendTo_, dust);
            }

            // Add 1 to `claimedAmount_` index because the first index is reserved.
            claimTwTapRewardsMsg_.sendParam[sendParamIndex].sendParam.amountLD = amountWithoutDust; // Set the amount to send to the claimed amount
            claimTwTapRewardsMsg_.sendParam[sendParamIndex].sendParam.minAmountLD = amountWithoutDust; // Set the amount to send to the claimed amount

            // Send back packet
            TapTokenSender(rewardToken_).sendPacket{
                value: claimTwTapRewardsMsg_.sendParam[sendParamIndex].fee.nativeFee
            }(claimTwTapRewardsMsg_.sendParam[sendParamIndex], bytes(""));

            emit ClaimRewardReceived(rewardToken_, sendTo_, amountWithoutDust);
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// LZ
import {
    MessagingReceipt, OFTReceipt, SendParam
} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
// Tapioca
import {TapiocaOmnichainSender} from "tapioca-periph/tapiocaOmnichainEngine/TapiocaOmnichainSender.sol";
import {IPearlmit} from "tapioca-periph/interfaces/periph/IPearlmit.sol";
import {ICluster} from "tapioca-periph/interfaces/periph/ICluster.sol";
import {BaseTapToken} from "./BaseTapToken.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

contract TapTokenSender is BaseTapToken, TapiocaOmnichainSender {
    /**
     * @dev Used as a module for `TapToken`. Only delegate calls with `TapToken` state are used.
     * Set the Pearlmit and Cluster to address(0) because they are not used in this contract.
     */
    constructor(string memory _name, string memory _symbol, address _endpoint, address _delegate, address _extExec)
        BaseTapToken(_name, _symbol, _endpoint, _delegate, _extExec, IPearlmit(address(0)), ICluster(address(0)))
    {}
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

struct ICommonExternalContracts {
    address magnetar;
    address singularity;
    address bigBang;
    address marketHelper;
}

struct IDepositData {
    bool deposit;
    uint256 amount;
}

interface ICommonData {}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

interface IPermit {
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    function revoke(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external; // available on YieldBoxPermit
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

interface IPermitAll {
    function permitAll(address owner, address spender, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external; // available on YieldBoxPermit

    function revokeAll(address owner, address spender, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external; // available on YieldBoxPermit
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

interface IPermitBorrow {
    function permitBorrow(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// Tapioca
import {IExerciseOptionsData} from "../tap-token/ITapiocaOptionBroker.sol";
import {IPearlmit} from "tapioca-periph/interfaces/periph/IPearlmit.sol";
import {MagnetarWithdrawData} from "../periph/IMagnetar.sol";

import "../periph/ITapiocaOmnichainEngine.sol";
/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

interface ITOFT is ITapiocaOmnichainEngine {
    enum Module {
        NonModule, //0
        TOFTSender,
        TOFTReceiver,
        TOFTMarketReceiver,
        TOFTOptionsReceiver,
        TOFTGenericReceiver
    }

    function pearlmit() external view returns (IPearlmit);
    function decimalConversionRate() external view returns (uint256);
    function hostEid() external view returns (uint256);
    function wrap(address fromAddress, address toAddress, uint256 amount) external payable returns (uint256 minted);
    function unwrap(address _toAddress, uint256 _amount) external returns (uint256 unwrapped);
    function erc20() external view returns (address);
    function vault() external view returns (address);
    function balanceOf(address _holder) external view returns (uint256);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function extractUnderlying(uint256 _amount) external; //mTOFT
    // available in BaseTapiocaOmnichainEngine
    function removeDust(uint256 _amountLD) external view returns (uint256 amountLD);
}

interface IToftVault {
    error AmountNotRight();
    error Failed();
    error FeesAmountNotRight();
    error NotValid();
    error OwnerSet();
    error ZeroAmount();

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function _token() external view returns (address);
    function claimOwnership() external;
    function depositNative() external payable;
    function owner() external view returns (address);
    function registerFees(uint256 amount) external payable;
    function renounceOwnership() external;
    function transferFees(address to, uint256 amount) external;
    function transferOwnership(address newOwner) external;
    function viewFees() external view returns (uint256);
    function viewSupply() external view returns (uint256);
    function viewTotalSupply() external view returns (uint256);
    function withdraw(address to, uint256 amount) external;
}

/// ============================
/// ========= GENERIC ==========
/// ============================

struct TOFTInitStruct {
    string name;
    string symbol;
    address endpoint;
    address delegate;
    address yieldBox;
    address cluster;
    address erc20;
    address vault;
    uint256 hostEid;
    address extExec;
    IPearlmit pearlmit;
}

struct TOFTModulesInitStruct {
    //modules
    address tOFTSenderModule;
    address tOFTReceiverModule;
    address marketReceiverModule;
    address optionsReceiverModule;
    address genericReceiverModule;
}

/// ============================
/// ========= COMPOSE ==========
/// ============================

/**
 * @notice Encodes the message for the PT_SEND_PARAMS operation.
 */
struct SendParamsMsg {
    address receiver;
    bool unwrap;
    uint256 amount;
}

/**
 * @notice Encodes the message for the PT_TAP_EXERCISE operation.
 */
struct ExerciseOptionsMsg {
    IExerciseOptionsData optionsData;
    bool withdrawOnOtherChain;
    //@dev send back to source message params
    LZSendParam lzSendParams;
}

/**
 * @notice Encodes the message for the PT_MARKET_REMOVE_COLLATERAL operation.
 */
struct MarketRemoveCollateralMsg {
    address user;
    IRemoveParams removeParams;
    MagnetarWithdrawData withdrawParams;
    uint256 value;
}

/**
 * @notice Encodes the message for the PT_YB_SEND_SGL_BORROW operation.
 */
struct MarketBorrowMsg {
    address user;
    IBorrowParams borrowParams;
    MagnetarWithdrawData withdrawParams;
    uint256 value;
}

struct IRemoveParams {
    uint256 amount;
    address magnetar;
    address marketHelper;
    address market;
}

struct IBorrowParams {
    uint256 amount;
    uint256 borrowAmount;
    address magnetar;
    address marketHelper;
    address market;
    bool deposit;
}

struct LeverageUpActionMsg {
    address user;
    address market;
    address marketHelper;
    uint256 borrowAmount;
    uint256 supplyAmount;
    bytes executorData;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// Tapioca
import {
    ITapiocaOmnichainEngine,
    YieldBoxApproveAssetMsg,
    YieldBoxApproveAllMsg,
    MarketPermitActionMsg,
    ERC20PermitStruct,
    LZSendParam
} from "../periph/ITapiocaOmnichainEngine.sol";
import {
    IOptionsParticipateData,
    ITapiocaOptionBroker,
    IExerciseOptionsData,
    IOptionsExitData
} from "../tap-token/ITapiocaOptionBroker.sol";
import {IOptionsUnlockData, IOptionsLockData} from "../tap-token/ITapiocaOptionLiquidityProvision.sol";
import {ICommonData, ICommonExternalContracts} from "../common/ICommonData.sol";
import {IPearlmit} from "tapioca-periph/interfaces/periph/IPearlmit.sol";
import {MagnetarWithdrawData} from "../periph/IMagnetar.sol";
import {IDepositData} from "../common/ICommonData.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

interface IUsdo is ITapiocaOmnichainEngine {
    enum Module {
        NonModule,
        UsdoSender,
        UsdoReceiver,
        UsdoMarketReceiver,
        UsdoOptionReceiver,
        UsdoGenericReceiver
    }

    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    function setFlashloanHelper(address _helper) external;

    function addFlashloanFee(uint256 _fee) external; //onlyOwner

    function paused() external view returns (bool);

    // available in BaseTapiocaOmnichainEngine
    function removeDust(uint256 _amountLD) external view returns (uint256 amountLD);
}

/// ============================
/// ========= GENERIC ==========
/// ============================
struct UsdoInitStruct {
    address endpoint;
    address delegate;
    address yieldBox;
    address cluster;
    address extExec;
    IPearlmit pearlmit;
}

struct UsdoModulesInitStruct {
    //modules
    address usdoSenderModule;
    address usdoReceiverModule;
    address marketReceiverModule;
    address optionReceiverModule;
}

/// ============================
/// ========= COMPOSE ==========
/// ============================
/**
 * @notice Encodes the message for the PT_YB_SEND_SGL_LEND_OR_REPAY operation.
 */
struct MarketLendOrRepayMsg {
    address user;
    ILendOrRepayParams lendParams;
    MagnetarWithdrawData withdrawParams;
    uint256 value;
}

/**
 * @notice Encodes the message for the PT_MARKET_REMOVE_ASSET operation.
 */
struct MarketRemoveAssetMsg {
    address user;
    ICommonExternalContracts externalData;
    IRemoveAndRepay removeAndRepayData;
    uint256 value;
}

/**
 * @notice Encodes the message for the PT_TAP_EXERCISE operation.
 */
struct ExerciseOptionsMsg {
    IExerciseOptionsData optionsData;
    bool withdrawOnOtherChain;
    //@dev send back to source message params
    LZSendParam lzSendParams;
}

struct IRemoveAndRepay {
    bool removeAssetFromSGL;
    uint256 removeAmount; //slightly greater than repayAmount to cover the interest
    bool repayAssetOnBB;
    uint256 repayAmount; // on BB
    bool removeCollateralFromBB;
    uint256 collateralAmount; // from BB
    IOptionsExitData exitData;
    IOptionsUnlockData unlockData;
    MagnetarWithdrawData assetWithdrawData;
    MagnetarWithdrawData collateralWithdrawData;
}

// lend or repay
struct ILendOrRepayParams {
    bool repay;
    uint256 depositAmount;
    uint256 repayAmount;
    address marketHelper;
    address magnetar;
    address market;
    bool removeCollateral;
    uint256 removeCollateralAmount;
    IOptionsLockData lockData;
    IOptionsParticipateData participateData;
}

struct IMintData {
    bool mint;
    uint256 mintAmount;
    IDepositData collateralDepositData;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

interface ICluster {
    function isWhitelisted(uint32 lzChainId, address _addr) external view returns (bool);

    function updateContract(uint32 lzChainId, address _addr, bool _status) external;

    function batchUpdateContracts(uint32 _lzChainId, address[] memory _addresses, bool _status) external;

    function lzChainId() external view returns (uint32);

    function hasRole(address _contract, bytes32 _role) external view returns (bool);

    function setRoleForContract(address _contract, bytes32 _role, bool _hasRole) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// Tapioca
import {IOptionsLockData} from "../tap-token/ITapiocaOptionLiquidityProvision.sol";
import {ICommonExternalContracts, IDepositData} from "../common/ICommonData.sol";
import {IOptionsParticipateData} from "../tap-token/ITapiocaOptionBroker.sol";
import {LZSendParam} from "../periph/ITapiocaOmnichainEngine.sol";
import {IRemoveAndRepay, IMintData} from "../oft/IUsdo.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

struct MagnetarWithdrawData {
    address yieldBox;
    uint256 assetId;
    address receiver;
    uint256 amount;
    bool unwrap;
    bool withdraw;
    bool extractFromSender;
}

/**
 * @dev MagnetarYieldBoxModule `depositAsset` calldata
 */
struct YieldBoxDepositData {
    address yieldBox;
    uint256 assetId;
    address from;
    address to;
    uint256 amount;
    uint256 share;
}

/**
 * @dev `exitPositionAndRemoveCollateral` calldata
 */
struct ExitPositionAndRemoveCollateralData {
    address user;
    ICommonExternalContracts externalData;
    IRemoveAndRepay removeAndRepayData;
}

/**
 * @dev `depositRepayAndRemoveCollateralFromMarket` calldata
 */
struct DepositRepayAndRemoveCollateralFromMarketData {
    address market;
    address marketHelper;
    address user;
    uint256 depositAmount;
    uint256 repayAmount;
    uint256 collateralAmount;
    MagnetarWithdrawData withdrawCollateralParams;
}

/**
 * @dev `depositAddCollateralAndBorrowFromMarket` calldata
 */
struct DepositAddCollateralAndBorrowFromMarketData {
    address market;
    address marketHelper;
    address user;
    uint256 collateralAmount;
    uint256 borrowAmount;
    bool deposit;
    MagnetarWithdrawData withdrawParams;
}

/**
 * @dev `mintBBLendSGLLockTOLP` calldata
 */
struct MintFromBBAndLendOnSGLData {
    address user;
    uint256 lendAmount;
    IMintData mintData;
    IDepositData depositData;
    IOptionsLockData lockData;
    IOptionsParticipateData participateData;
    ICommonExternalContracts externalContracts;
}

struct LockAndParticipateData {
    address user;
    address tSglToken;
    address yieldBox;
    address magnetar;
    IOptionsLockData lockData;
    IOptionsParticipateData participateData;
    uint256 value;
}

struct MagnetarCall {
    uint8 id;
    address target;
    uint256 value;
    bytes call;
}

enum MagnetarAction {
    // Simple operations
    Permit, // 0 Permit singular operations.
    Wrap, // 1 Wrap/unwrap singular operations.
    Market, // 2 Market singular operations.
    TapLock, // 3 TapLock singular operations.
    TapUnlock, // 4 TapLock singular operations.
    OFT, // 5 LZ OFT singular operations.
    ExerciseOption, // 6 tOB singular operation
    // Complex operations
    CollateralModule, // 7 Collateral Singular related operations.
    MintModule, // 8 BigBang Singular related operations.
    OptionModule, // 9 Market Module related operations.
    YieldBoxModule // 10 YieldBox module related operations.

}

enum MagnetarModule {
    CollateralModule,
    MintModule,
    OptionModule,
    YieldBoxModule
}

interface IMagnetar {
    function burst(MagnetarCall[] calldata calls) external payable;
    function cluster() external view returns (address);
    function helper() external view returns (address);
}

interface IMagnetarModuleExtender {
    function isValidActionId(uint8 actionId) external view returns (bool);
    function handleAction(MagnetarCall calldata call) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

interface IPearlmit {
    struct SignatureApproval {
        uint256 tokenType; // 20 = ERC20, 721 = ERC721, 1155 = ERC1155.
        address token; // Address of the token.
        uint256 id; // ID of the token (0 if ERC20).
        uint200 amount; // Amount of the token (0 if ERC721).
        address operator; // Address of the operator to transfer the tokens to.
    }

    struct PermitBatchTransferFrom {
        SignatureApproval[] approvals; // Array of SignatureApproval structs.
        address owner; // Address of the owner of the tokens.
        uint256 nonce; // Nonce of the owner.
        uint48 sigDeadline; // Deadline for the signature.
        uint256 masterNonce; // Master nonce of the owner.
        bytes signedPermit; // Signature of the permit. (Not present in the TYPEHASH)
        address executor; // Address of the allowed executor of the permit.
        // In the case of Tapioca, it'll be the `msg.sender` from src chain, checked against `TOE` trusted `srcChainSender`.
        bytes32 hashedData; // Hashed data that comes with the permit execution. See more in Pearlmit.sol.
    }

    function approve(uint256 tokenType, address token, uint256 id, address operator, uint200 amount, uint48 expiration)
        external;

    function allowance(address owner, address operator, uint256 tokenType, address token, uint256 id)
        external
        view
        returns (uint256 allowedAmount, uint256 expiration);

    function clearAllowance(address owner, uint256 tokenType, address token, uint256 id) external;

    function permitBatchTransferFrom(PermitBatchTransferFrom calldata batch, bytes32 hashedData)
        external
        returns (bool[] memory errorStatus);

    function permitBatchApprove(PermitBatchTransferFrom calldata batch, bytes32 hashedData) external;

    function transferFromERC1155(address owner, address to, address token, uint256 id, uint256 amount)
        external
        returns (bool isError);

    function transferFromERC20(address owner, address to, address token, uint256 amount)
        external
        returns (bool isError);

    function transferFromERC721(address owner, address to, address token, uint256 id) external returns (bool isError);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// LZ
import {
    SendParam,
    MessagingFee,
    OFTReceipt,
    MessagingReceipt
} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/
interface ITapiocaOmnichainReceiveExtender {
    function isMsgTypeValid(uint16 _msgType) external view returns (bool);
    function toeComposeReceiver(uint16 _msgType, address _srcChainSender, bytes memory _toeComposeMsg)
        external
        payable;
}

interface ITapiocaOmnichainEngine {
    /**
     * =======================
     * LZ functions
     * =======================
     */
    function combineOptions(uint32 _eid, uint16 _msgType, bytes calldata _extraOptions)
        external
        view
        returns (bytes memory);

    /**
     * =======================
     * Tapioca added functions
     * =======================
     */
    function sendPacket(LZSendParam calldata _lzSendParam, bytes calldata _composeMsg)
        external
        payable
        returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt);

    function sendPacketFrom(address _from, LZSendParam calldata _lzSendParam, bytes calldata _composeMsg)
        external
        payable
        returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt);

    function getTypedDataHash(ERC20PermitStruct calldata _permitData) external view returns (bytes32);

    function quoteSendPacket(
        SendParam calldata _sendParam,
        bytes calldata _extraOptions,
        bool _payInLzToken,
        bytes calldata _composeMsg,
        bytes calldata /*_oftCmd*/ // @dev unused in the default implementation.
    ) external view returns (MessagingFee memory msgFee);
}

/// =======================
/// ========= LZ ==========
/// =======================

/**
 * @param sendParam The parameters for the send operation.
 * @param fee The calculated fee for the send() operation.
 *      - nativeFee: The native fee.
 *      - lzTokenFee: The lzToken fee.
 * @param _extraOptions Additional options for the send() operation.
 * @param refundAddress The address to refund the native fee to.
 */
struct LZSendParam {
    SendParam sendParam;
    MessagingFee fee;
    bytes extraOptions;
    address refundAddress;
}

/// ================================
/// ========= BASE COMPOSE =========
/// ================================

/**
 * @dev Used in TapTokenHelper.
 */
struct RemoteTransferMsg {
    address owner;
    LZSendParam lzSendParam;
    bytes composeMsg;
}

/**
 * Structure of an ERC20 permit message.
 */
struct ERC20PermitStruct {
    address owner;
    address spender;
    uint256 value;
    uint256 nonce;
    uint256 deadline;
}

/**
 * @notice Encodes the message for the ercPermitApproval() operation.
 */
struct ERC20PermitApprovalMsg {
    address token;
    address owner;
    address spender;
    uint256 value;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
}

/**
 * Structure of an ERC721 permit message.
 */
struct ERC721PermitStruct {
    address spender;
    uint256 tokenId;
    uint256 nonce;
    uint256 deadline;
}

/**
 * @notice Encodes the message for the ercPermitApproval() operation.
 */
struct ERC721PermitApprovalMsg {
    address token;
    address spender;
    uint256 tokenId;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
}

/**
 * @notice Encodes the message for the ybPermitAll() operation.
 */
struct YieldBoxApproveAllMsg {
    address target;
    address owner;
    address spender;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
    bool permit;
}

/**
 * @notice Encodes the message for the ybPermitAll() operation.
 */
struct YieldBoxApproveAssetMsg {
    address target;
    address owner;
    address spender;
    uint256 assetId;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
    bool permit;
}

/**
 * @notice Encodes the message for the market.permitAction() or market.permitBorrow() operations.
 */
struct MarketPermitActionMsg {
    address target;
    address owner;
    address spender;
    uint256 value;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
    bool permitAsset;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

struct ISeerQuery {
    bool useHigh; // Whether to use the high or low value
}

interface ITapiocaOracle {
    // @notice Precision of the return value.
    function decimals() external view returns (uint8);

    /// @notice Get the latest exchange rate.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(bytes calldata data) external returns (bool success, uint256 rate);

    /// @notice Check the last exchange rate without any state changes.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(bytes calldata data) external view returns (bool success, uint256 rate);

    /// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(bytes calldata data) external view returns (uint256 rate);

    /// @notice Returns a human readable (short) name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable symbol name about this oracle.
    function symbol(bytes calldata data) external view returns (string memory);

    /// @notice Returns a human readable name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable name about this oracle.
    function name(bytes calldata data) external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// Tapioca
import {ICommonData} from "../common/ICommonData.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

interface ITapiocaOptionBroker {
    function oTAP() external view returns (address);

    function tOLP() external view returns (address);

    function exerciseOption(uint256 oTAPTokenID, address paymentToken, uint256 tapAmount) external;

    function participate(uint256 tOLPTokenID) external returns (uint256 oTAPTokenID);

    function exitPosition(uint256 oTAPTokenID) external;

    function tapOFT() external view returns (address);

    function getOTCDealDetails(uint256 _oTAPTokenID, address _paymentToken, uint256 _tapAmount)
        external
        view
        returns (uint256 eligibleTapAmount, uint256 paymentTokenAmount, uint256 tapAmount);
}

struct IOptionsParticipateData {
    bool participate;
    address target;
    uint256 tOLPTokenId;
}

struct IOptionsExitData {
    bool exit;
    address target;
    uint256 oTAPTokenID;
}

struct IExerciseOptionsData {
    address from;
    address target;
    uint256 paymentTokenAmount;
    uint256 oTAPTokenID;
    uint256 tapAmount;
}

struct IExerciseLZData {
    uint16 lzDstChainId;
    address zroPaymentAddress;
    uint256 extraGas;
}

struct IExerciseLZSendTapData {
    bool withdrawOnAnotherChain;
    address tapOftAddress;
    uint16 lzDstChainId;
    uint256 amount;
    address zroPaymentAddress;
    uint256 extraGas;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

interface ITapiocaOptionLiquidityProvision is IERC721 {
    function yieldBox() external view returns (address);

    function activeSingularities(address singularity)
        external
        view
        returns (uint256 sglAssetId, uint256 totalDeposited, uint256 poolWeight, bool rescue);

    function lock(address to, address singularity, uint128 lockDuration, uint128 amount)
        external
        returns (uint256 tokenId);

    function unlock(uint256 tokenId, address singularity) external returns (uint256 sharesOut);

    function lockPositions(uint256 tokenId)
        external
        view
        returns (uint128 sglAssetID, uint128 ybShares, uint128 lockTime, uint128 lockDuration);
}

struct IOptionsLockData {
    bool lock;
    address target;
    uint128 lockDuration;
    uint128 amount; // @dev: in case of a previous `YB` deposit, this amount is replaced by the obtained shares
    uint256 fraction;
}

struct IOptionsUnlockData {
    bool unlock;
    address target;
    uint256 tokenId;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/// @title TokenType
/// @author BoringCrypto (@Boring_Crypto)
/// @notice The YieldBox can hold different types of tokens:
/// Native: These are ERC1155 tokens native to YieldBox. Protocols using YieldBox should use these is possible when simple token creation is needed.
/// ERC20: ERC20 tokens (including rebasing tokens) can be added to the YieldBox.
/// ERC1155: ERC1155 tokens are also supported. This can also be used to add YieldBox Native tokens to strategies since they are ERC1155 tokens.
enum IYieldBoxTokenType {
    Native,
    ERC20,
    ERC721,
    ERC1155,
    None
}
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.8.0. SEE SOURCE BELOW. !!

interface IYieldBox {
    error AmountTooLow();
    error AssetNotValid();
    error ForbiddenAction();
    error InvalidShortString();
    error InvalidTokenType();
    error NotSet();
    error NotWrapped();
    error RefundFailed();
    error StringTooLong(string str);
    error ZeroAddress();

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event ApprovalForAsset(address indexed sender, address indexed operator, uint256 assetId, bool approved);
    event AssetRegistered(
        uint8 indexed tokenType,
        address indexed contractAddress,
        address strategy,
        uint256 indexed tokenId,
        uint256 assetId
    );
    event Deposited(
        address indexed sender,
        address indexed from,
        address indexed to,
        uint256 assetId,
        uint256 amountIn,
        uint256 shareIn,
        uint256 amountOut,
        uint256 shareOut,
        bool isNFT
    );
    event EIP712DomainChanged();
    event OwnershipTransferred(uint256 indexed tokenId, address indexed previousOwner, address indexed newOwner);
    event TokenCreated(address indexed creator, string name, string symbol, uint8 decimals, uint256 tokenId);
    event TransferBatch(
        address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values
    );
    event TransferSingle(
        address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value
    );
    event URI(string _value, uint256 indexed _id);
    event Withdraw(
        address indexed sender,
        address indexed from,
        address indexed to,
        uint256 assetId,
        uint256 amountIn,
        uint256 shareIn,
        uint256 amountOut,
        uint256 shareOut
    );

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function amountOf(address user, uint256 assetId) external view returns (uint256 amount);

    function assetCount() external view returns (uint256);

    function assetTotals(uint256 assetId) external view returns (uint256 totalShare, uint256 totalAmount);

    function assets(uint256)
        external
        view
        returns (IYieldBoxTokenType tokenType, address contractAddress, address strategy, uint256 tokenId);

    function balanceOf(address, uint256) external view returns (uint256);

    function balanceOfBatch(address[] memory owners, uint256[] memory ids)
        external
        view
        returns (uint256[] memory balances);

    function batch(bytes[] memory calls, bool revertOnFail) external payable;

    function batchBurn(uint256 tokenId, address[] memory froms, uint256[] memory amounts) external;

    function batchMint(uint256 tokenId, address[] memory tos, uint256[] memory amounts) external;

    function batchTransfer(address from, address to, uint256[] memory assetIds_, uint256[] memory shares_) external;

    function burn(uint256 tokenId, address from, uint256 amount) external;

    function claimOwnership(uint256 tokenId) external;

    function createToken(string memory name, string memory symbol, uint8 decimals, string memory uri)
        external
        returns (uint32 tokenId);

    function decimals(uint256 assetId) external view returns (uint8);

    function deposit(
        IYieldBoxTokenType tokenType,
        address contractAddress,
        address strategy,
        uint256 tokenId,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    function depositAsset(uint256 assetId, address from, address to, uint256 amount, uint256 share)
        external
        returns (uint256 amountOut, uint256 shareOut);

    function depositETH(address strategy, address to, uint256 amount)
        external
        payable
        returns (uint256 amountOut, uint256 shareOut);

    function depositETHAsset(uint256 assetId, address to, uint256 amount)
        external
        payable
        returns (uint256 amountOut, uint256 shareOut);

    function depositNFTAsset(uint256 assetId, address from, address to)
        external
        returns (uint256 amountOut, uint256 shareOut);

    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );

    function ids(IYieldBoxTokenType tokenType, address contractAddr, address strategy, uint256 tokenId)
        external
        view
        returns (uint256);

    function isApprovedForAll(address, address) external view returns (bool);

    function isApprovedForAsset(address, address, uint256) external view returns (bool);

    function mint(uint256 tokenId, address to, uint256 amount) external;

    function name(uint256 assetId) external view returns (string memory);

    function nativeTokens(uint256)
        external
        view
        returns (string memory name, string memory symbol, uint8 decimals, string memory uri);

    function nonces(address owner) external view returns (uint256);

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory)
        external
        pure
        returns (bytes4);

    function onERC1155Received(address, address, uint256, uint256, bytes memory) external pure returns (bytes4);

    function onERC721Received(address, address, uint256, bytes memory) external pure returns (bytes4);

    function owner(uint256) external view returns (address);

    function pendingOwner(uint256) external view returns (address);

    function permit(address owner, address spender, uint256 assetId, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    function permitAll(address owner, address spender, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    function permitToken(
        address token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function registerAsset(IYieldBoxTokenType tokenType, address contractAddress, address strategy, uint256 tokenId)
        external
        returns (uint256 assetId);

    function revoke(address owner, address spender, uint256 assetId, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    function revokeAll(address owner, address spender, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) external;

    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes memory data) external;

    function setApprovalForAll(address operator, bool approved) external;

    function setApprovalForAsset(address operator, uint256 assetId, bool approved) external;

    function supportsInterface(bytes4 interfaceID) external pure returns (bool);

    function symbol(uint256 assetId) external view returns (string memory);

    function toAmount(uint256 assetId, uint256 share, bool roundUp) external view returns (uint256 amount);

    function toShare(uint256 assetId, uint256 amount, bool roundUp) external view returns (uint256 share);

    function totalSupply(uint256) external view returns (uint256);

    function transfer(address from, address to, uint256 assetId, uint256 share) external;

    function transferMultiple(address from, address[] memory tos, uint256 assetId, uint256[] memory shares) external;

    function transferOwnership(uint256 tokenId, address newOwner, bool direct, bool renounce) external;

    function uri(uint256 assetId) external view returns (string memory);

    function uriBuilder() external view returns (address);

    function withdraw(uint256 assetId, address from, address to, uint256 amount, uint256 share)
        external
        returns (uint256 amountOut, uint256 shareOut);

    function wrappedNative() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Tapioca
import {IPearlmit} from "tapioca-periph/interfaces/periph/IPearlmit.sol";

abstract contract PearlmitHandler is Ownable {
    // ************ //
    // *** VARS *** //
    // ************ //

    IPearlmit public pearlmit;

    // ************** //
    // *** EVENTS *** //
    // ************** //

    event PearlmitUpdated(IPearlmit oldPearlmit, IPearlmit newPearlmit);

    // ***************** //
    // *** CONSTRUCTOR *** //
    // ***************** //

    constructor(IPearlmit _pearlmit) {
        emit PearlmitUpdated(pearlmit, _pearlmit);
        pearlmit = _pearlmit;
    }

    /// @notice Perform an allowance check for an ERC721 token on Pearlmit.
    function isERC721Approved(address owner, address spender, address token, uint256 id) internal view returns (bool) {
        (uint256 allowedAmount,) = pearlmit.allowance(owner, spender, 721, token, id); // Returns 0 if not approved or expired
        return allowedAmount > 0;
    }

    /// @notice Perform an allowance check for an ERC20 token on Pearlmit.
    function isERC20Approved(address owner, address spender, address token, uint256 amount)
        internal
        view
        returns (bool)
    {
        (uint256 allowedAmount,) = pearlmit.allowance(owner, spender, 20, token, 0); // Returns 0 if not approved or expired
        return allowedAmount >= amount;
    }

    // ******************* //
    // *** OWNER METHODS *** //
    // ******************* //

    /**
     * @notice updates the Pearlmit address.
     * @dev can only be called by the owner.
     * @param _pearlmit the new address.
     */
    function setPearlmit(IPearlmit _pearlmit) external onlyOwner {
        emit PearlmitUpdated(pearlmit, _pearlmit);
        pearlmit = _pearlmit;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// LZ
import {IOAppMsgInspector} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/interfaces/IOAppMsgInspector.sol";
import {SendParam, MessagingFee} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {OFTMsgCodec} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTMsgCodec.sol";
import {OAppSender} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol";
import {OFT} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";

// External
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {BytesLib} from "solidity-bytes-utils/contracts/BytesLib.sol";

// Tapioca
import {ITapiocaOmnichainReceiveExtender} from "tapioca-periph/interfaces/periph/ITapiocaOmnichainEngine.sol";
import {PearlmitHandler, IPearlmit} from "tapioca-periph/pearlmit/PearlmitHandler.sol";
import {TapiocaOmnichainExtExec} from "./extension/TapiocaOmnichainExtExec.sol";
import {ICluster} from "tapioca-periph/interfaces/periph/ICluster.sol";
import {BaseToeMsgType} from "./BaseToeMsgType.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

abstract contract BaseTapiocaOmnichainEngine is OFT, PearlmitHandler, BaseToeMsgType {
    using BytesLib for bytes;
    using SafeERC20 for IERC20;
    using OFTMsgCodec for bytes;
    using OFTMsgCodec for bytes32;

    /// @dev Used to execute certain extern calls from the TapToken contract, such as ERC20Permit approvals.
    TapiocaOmnichainExtExec public toeExtExec;
    /// @dev For future use, to extend the receive() operation.
    ITapiocaOmnichainReceiveExtender public tapiocaOmnichainReceiveExtender;

    error BaseTapiocaOmnichainEngine_PearlmitNotApproved();
    error BaseTapiocaOmnichainEngine_PearlmitFailed();
    error BaseTapiocaOmnichainEngine__ZeroAddress();

    // keccak256("BaseToe.cluster.slot")
    bytes32 public constant CLUSTER_SLOT = 0x7cdf5007585d1c7d3dfb23c59fcda5f9f02da78637d692495255a57630b72162;

    constructor(
        string memory _name,
        string memory _symbol,
        address _endpoint,
        address _delegate,
        address _extExec,
        IPearlmit _pearlmit,
        ICluster _cluster
    ) OFT(_name, _symbol, _endpoint, _delegate) PearlmitHandler(_pearlmit) {
        toeExtExec = TapiocaOmnichainExtExec(_extExec);

        StorageSlot.getAddressSlot(CLUSTER_SLOT).value = address(_cluster);
    }

    /**
     * @inheritdoc OAppSender
     * @dev Overwrite to check for < values.
     */
    function _payNative(uint256 _nativeFee) internal override returns (uint256 nativeFee) {
        if (msg.value < _nativeFee) revert NotEnoughNative(msg.value);
        return msg.value;
    }

    /**
     * @dev Sets the `tapiocaOmnichainReceiveExtender` contract.
     */
    function setTapiocaOmnichainReceiveExtender(address _tapiocaOmnichainReceiveExtender) external onlyOwner {
        tapiocaOmnichainReceiveExtender = ITapiocaOmnichainReceiveExtender(_tapiocaOmnichainReceiveExtender);
    }

    /**
     * @dev Sets the `toeExtExec` contract.
     */
    function setToeExtExec(address _extExec) external onlyOwner {
        toeExtExec = TapiocaOmnichainExtExec(_extExec);
    }

    /**
     * @dev Returns the current cluster.
     */
    function getCluster() public view returns (ICluster) {
        return ICluster(StorageSlot.getAddressSlot(CLUSTER_SLOT).value);
    }

    /**
     * @dev Sets the cluster.
     */
    function setCluster(ICluster _cluster) external onlyOwner {
        StorageSlot.getAddressSlot(CLUSTER_SLOT).value = address(_cluster);
    }

    /**
     * @dev public function to remove dust from the given local decimal amount.
     * @param _amountLD The amount in local decimals.
     * @return amountLD The amount after removing dust.
     *
     * @dev Prevents the loss of dust when moving amounts between chains with different decimals.
     * @dev eg. uint(123) with a conversion rate of 100 becomes uint(100).
     */
    function removeDust(uint256 _amountLD) public view virtual returns (uint256 amountLD) {
        return _removeDust(_amountLD);
    }

    /**
     * @dev Slightly modified version of the OFT quoteSend() operation. Includes a `_msgType` parameter.
     * The `_buildMsgAndOptionsByType()` appends the packet type to the message.
     * @notice Provides a quote for the send() operation.
     * @param _sendParam The parameters for the send() operation.
     * @param _extraOptions Additional options supplied by the caller to be used in the LayerZero message.
     * @param _payInLzToken Flag indicating whether the caller is paying in the LZ token.
     * @param _composeMsg The composed message for the send() operation.
     * @dev _oftCmd The OFT command to be executed.
     * @return msgFee The calculated LayerZero messaging fee from the send() operation.
     *
     * @dev MessagingFee: LayerZero msg fee
     *  - nativeFee: The native fee.
     *  - lzTokenFee: The lzToken fee.
     */
    function quoteSendPacket(
        SendParam calldata _sendParam,
        bytes calldata _extraOptions,
        bool _payInLzToken,
        bytes calldata _composeMsg,
        bytes calldata /*_oftCmd*/ // @dev unused in the default implementation.
    ) external view virtual returns (MessagingFee memory msgFee) {
        // @dev mock the amount to credit, this is the same operation used in the send().
        // The quote is as similar as possible to the actual send() operation.
        (, uint256 amountToCreditLD) = _debitView(_sendParam.amountLD, _sendParam.minAmountLD, _sendParam.dstEid);

        // @dev Builds the options and OFT message to quote in the endpoint.
        (bytes memory message, bytes memory options) =
            _buildOFTMsgAndOptions(address(0), _sendParam, _extraOptions, _composeMsg, amountToCreditLD);

        // @dev Calculates the LayerZero fee for the send() operation.
        return _quote(_sendParam.dstEid, message, options, _payInLzToken);
    }

    /**
     * @notice Build an OFT message and option. The message contain OFT related info such as the amount to credit and the recipient.
     * It also contains the `_composeMsg`, which is 1 or more TAP specific messages. See `_buildTapMsgAndOptions()`.
     * The option is an aggregation of the OFT message as well as the TAP messages.
     *
     * @param _from The sender address. If address(0), msg.sender is used.
     * @param _sendParam: The parameters for the send operation.
     *      - dstEid::uint32: Destination endpoint ID.
     *      - to::bytes32: Recipient address.
     *      - amountToSendLD::uint256: Amount to send in local decimals.
     *      - minAmountToCreditLD::uint256: Minimum amount to credit in local decimals.
     * @param _extraOptions Additional options for the send() operation. If `_composeMsg` not empty, the `_extraOptions` should also contain the aggregation of its options.
     * @param _composeMsg The composed message for the send() operation. Is a combination of 1 or more TAP specific messages.
     * @param _amountToCreditLD The amount to credit in local decimals.
     *
     * @return message The encoded message.
     * @return options The combined LZ msgType + `_extraOptions` options.
     */
    function _buildOFTMsgAndOptions(
        address _from,
        SendParam calldata _sendParam,
        bytes calldata _extraOptions,
        bytes calldata _composeMsg,
        uint256 _amountToCreditLD
    ) internal view returns (bytes memory message, bytes memory options) {
        bool hasCompose;

        // @dev This generated message has the msg.sender encoded into the payload so the remote knows who the caller is.
        // @dev NOTE the returned message will append `msg.sender` only if the message is composed.
        // If it's the case, it'll add the `address(msg.sender)` at the `amountToCredit` offset.
        (message, hasCompose) = encode(
            _from,
            _sendParam.to,
            _toSD(_amountToCreditLD),
            // @dev Must be include a non empty bytes if you want to compose, EVEN if you don't need it on the remote.
            // EVEN if you don't require an arbitrary payload to be sent... eg. '0x01'
            _composeMsg
        );
        // @dev Change the msg type depending if its composed or not.
        uint16 _msgType = hasCompose ? SEND_AND_CALL : SEND;
        // @dev Combine the callers _extraOptions with the enforced options via the OAppOptionsType3.
        options = combineOptions(_sendParam.dstEid, _msgType, _extraOptions);

        // @dev Optionally inspect the message and options depending if the OApp owner has set a msg inspector.
        // @dev If it fails inspection, needs to revert in the implementation. ie. does not rely on return boolean
        if (msgInspector != address(0)) {
            IOAppMsgInspector(msgInspector).inspect(message, options);
        }
    }

    /**
     * @dev copy paste of OFTMsgCodec::encode(). Difference is `_from` is passed as a parameter.
     * and update the source chain sender.
     */
    function encode(address _from, bytes32 _sendTo, uint64 _amountShared, bytes memory _composeMsg)
        internal
        pure
        returns (bytes memory _msg, bool hasCompose)
    {
        hasCompose = _composeMsg.length > 0;
        // @dev Remote chains will want to know the composed function caller ie. msg.sender on the src.

        _msg = hasCompose
            ? abi.encodePacked(_sendTo, _amountShared, OFTMsgCodec.addressToBytes32(_from), _composeMsg)
            : abi.encodePacked(_sendTo, _amountShared);
    }

    /**
     * @dev Allowance check and consumption against the xChain msg sender.
     *
     * @param _owner The account to check the allowance against.
     * @param _srcChainSender The address of the sender on the source chain.
     * @param _amount The amount to check the allowance for.
     */
    function _validateAndSpendAllowance(address _owner, address _srcChainSender, uint256 _amount) internal {
        if (_owner != _srcChainSender) {
            _spendAllowance(_owner, _srcChainSender, _amount);
        }
    }

    /**
     * @dev Performs a transfer with an allowance check and consumption against the xChain msg sender.
     * @dev Can only transfer to this address.
     *
     * @param _owner The account to transfer from.
     * @param _srcChainSender The address of the sender on the source chain.
     * @param _amount The amount to transfer
     */
    function _internalTransferWithAllowance(address _owner, address _srcChainSender, uint256 _amount) internal {
        _validateAndSpendAllowance(_owner, _srcChainSender, _amount);
        _transfer(_owner, address(this), _amount);
    }

    /**
     * @dev Internal function to return the current EID.
     */
    function _getChainId() internal view virtual returns (uint32) {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

abstract contract BaseToeMsgType {
    // LZ
    uint16 public constant MSG_SEND = 1;

    // Tapioca
    uint16 internal constant MSG_APPROVALS = 500; // Use for ERC20Permit approvals
    uint16 internal constant MSG_NFT_APPROVALS = 501; // Use for ERC721Permit approvals
    uint16 internal constant MSG_PEARLMIT_APPROVAL = 502; // Use for Pearlmit approvals
    uint16 internal constant MSG_YB_APPROVE_ASSET = 503; // Use for YieldBox 'setApprovalForAsset(true)' operation
    uint16 internal constant MSG_YB_APPROVE_ALL = 504; // Use for YieldBox 'setApprovalForAll(true)' operation
    uint16 internal constant MSG_MARKET_PERMIT = 505; // Use for market.permitLend() operation
    uint16 internal constant MSG_REMOTE_TRANSFER = 700; // Use for transferring tokens from the contract from another chain
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

// Tapioca
import {
    ERC20PermitApprovalMsg,
    ERC721PermitApprovalMsg,
    YieldBoxApproveAllMsg,
    MarketPermitActionMsg,
    YieldBoxApproveAssetMsg
} from "tapioca-periph/interfaces/periph/ITapiocaOmnichainEngine.sol";
import {IPermitBorrow} from "tapioca-periph/interfaces/common/IPermitBorrow.sol";
import {TapiocaOmnichainEngineCodec} from "../TapiocaOmnichainEngineCodec.sol";
import {IPermitAll} from "tapioca-periph/interfaces/common/IPermitAll.sol";
import {IPearlmit} from "tapioca-periph/interfaces/periph/IPearlmit.sol";
import {ICluster} from "tapioca-periph/interfaces/periph/ICluster.sol";
import {IPermit} from "tapioca-periph/interfaces/common/IPermit.sol";
import {ERC721Permit} from "tapioca-periph/utils/ERC721Permit.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

/**
 * @title TapiocaOmnichainExtExec
 * @author TapiocaDAO
 * @notice Used to execute external DELEGATE calls from a TapiocaOmnichainEngine contract. So to not use TapiocaOmnichainEngine in the call context.
 */
contract TapiocaOmnichainExtExec {
    // keccak256("BaseToe.cluster.slot")
    bytes32 public constant CLUSTER_SLOT = 0x7cdf5007585d1c7d3dfb23c59fcda5f9f02da78637d692495255a57630b72162;

    error InvalidApprovalTarget(address _target);

    /**
     * @notice Executes an ERC20 permit approval.
     * @param _data The ERC20 permit approval messages. Expect an `ERC20PermitApprovalMsg[]`.
     */
    function erc20PermitApproval(bytes memory _data) public {
        ERC20PermitApprovalMsg[] memory approvals = TapiocaOmnichainEngineCodec.decodeERC20PermitApprovalMsg(_data);

        uint256 approvalsLength = approvals.length;
        for (uint256 i = 0; i < approvalsLength;) {
            _sanitizeTarget(approvals[i].token);
            try IERC20Permit(approvals[i].token).permit(
                approvals[i].owner,
                approvals[i].spender,
                approvals[i].value,
                approvals[i].deadline,
                approvals[i].v,
                approvals[i].r,
                approvals[i].s
            ) {} catch {}
            unchecked {
                ++i;
            }
        }
    }
    /**
     * @notice Executes an ERC721 permit approval.
     * @param _data The ERC721 permit approval messages. Expect an `ERC721PermitApprovalMsg[]`.
     */

    function erc721PermitApproval(bytes memory _data) public {
        ERC721PermitApprovalMsg[] memory approvals = TapiocaOmnichainEngineCodec.decodeERC721PermitApprovalMsg(_data);

        uint256 approvalsLength = approvals.length;
        for (uint256 i = 0; i < approvalsLength;) {
            _sanitizeTarget(approvals[i].token);
            try ERC721Permit(approvals[i].token).permit(
                approvals[i].spender,
                approvals[i].tokenId,
                approvals[i].deadline,
                approvals[i].v,
                approvals[i].r,
                approvals[i].s
            ) {} catch {}
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Executes a permit approval for a batch transfer from a Pearlmit contract.
     * @param _data The call data containing info about the approval. Expect a tuple of `(address, IPearlmit.PermitBatchTransferFrom)`.
     */
    function pearlmitApproval(address _srcChainSender, bytes memory _data) public {
        (address pearlmit, IPearlmit.PermitBatchTransferFrom memory batchApprovals) =
            TapiocaOmnichainEngineCodec.decodePearlmitBatchApprovalMsg(_data);

        _sanitizeTarget(pearlmit);

        batchApprovals.owner = _srcChainSender; // overwrite the owner with the src chain sender
        // Redundant security measure, just for the sake of it
        try IPearlmit(pearlmit).permitBatchApprove(batchApprovals, keccak256(abi.encode(_srcChainSender))) {} catch {}
    }

    /**
     * @notice Approves YieldBox asset via permit.
     * @param _data The call data containing info about the approvals.
     *      - token::address: Address of the YieldBox to approve.
     *      - owner::address: Address of the owner of the tokens.
     *      - spender::address: Address of the spender.
     *      - value::uint256: Amount of tokens to approve.
     *      - deadline::uint256: Deadline for the approval.
     *      - v::uint8: v value of the signature.
     *      - r::bytes32: r value of the signature.
     *      - s::bytes32: s value of the signature.
     */
    function yieldBoxPermitAsset(bytes memory _data) public {
        YieldBoxApproveAssetMsg[] memory approvals =
            TapiocaOmnichainEngineCodec.decodeArrayOfYieldBoxPermitAssetMsg(_data);

        uint256 approvalsLength = approvals.length;
        for (uint256 i = 0; i < approvalsLength;) {
            _sanitizeTarget(approvals[i].target);
            unchecked {
                ++i;
            }
        }

        _yieldBoxPermitApproveAsset(approvals);
    }

    /**
     * @notice Approves all assets on YieldBox.
     * @param _data The call data containing info about the approval.
     *      - target::address: Address of the YieldBox contract.
     *      - owner::address: Address of the owner of the tokens.
     *      - spender::address: Address of the spender.
     *      - deadline::uint256: Deadline for the approval.
     *      - v::uint8: v value of the signature.
     *      - r::bytes32: r value of the signature.
     *      - s::bytes32: s value of the signature.
     */
    function yieldBoxPermitAll(bytes memory _data) public {
        YieldBoxApproveAllMsg memory approval = TapiocaOmnichainEngineCodec.decodeYieldBoxApproveAllMsg(_data);
        _sanitizeTarget(approval.target);

        if (approval.permit) {
            _yieldBoxPermitApproveAll(approval);
        } else {
            _yieldBoxPermitRevokeAll(approval);
        }
    }

    /**
     * @notice Approves Market lend/borrow via permit.
     * @param _data The call data containing info about the approval.
     *      - token::address: Address of the YieldBox to approve.
     *      - owner::address: Address of the owner of the tokens.
     *      - spender::address: Address of the spender.
     *      - value::uint256: Amount of tokens to approve.
     *      - deadline::uint256: Deadline for the approval.
     *      - v::uint8: v value of the signature.
     *      - r::bytes32: r value of the signature.
     *      - s::bytes32: s value of the signature.
     */
    function marketPermit(bytes memory _data) public {
        MarketPermitActionMsg memory approval = TapiocaOmnichainEngineCodec.decodeMarketPermitApprovalMsg(_data);
        _sanitizeTarget(approval.target);

        if (approval.permitAsset) {
            _marketPermitAssetApproval(approval);
        } else {
            _marketPermitCollateralApproval(approval);
        }
    }

    // ********************** //
    // ****** INTERNAL ****** //
    // ********************** //

    /**
     * @notice Executes YieldBox setApprovalForAsset(true) operations.
     * @dev similar to IERC20Permit
     * @param _approvals The approvals message.
     */
    function _yieldBoxPermitApproveAsset(YieldBoxApproveAssetMsg[] memory _approvals) internal {
        uint256 approvalsLength = _approvals.length;
        for (uint256 i = 0; i < approvalsLength;) {
            // @dev token is YieldBox
            if (!_approvals[i].permit) {
                try IPermit(_approvals[i].target).revoke(
                    _approvals[i].owner,
                    _approvals[i].spender,
                    _approvals[i].assetId,
                    _approvals[i].deadline,
                    _approvals[i].v,
                    _approvals[i].r,
                    _approvals[i].s
                ) {} catch {}
            } else {
                try IPermit(_approvals[i].target).permit(
                    _approvals[i].owner,
                    _approvals[i].spender,
                    _approvals[i].assetId,
                    _approvals[i].deadline,
                    _approvals[i].v,
                    _approvals[i].r,
                    _approvals[i].s
                ) {} catch {}
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Executes YieldBox setApprovalForAll(true) operation.
     * @param _approval The approval message.
     */
    function _yieldBoxPermitApproveAll(YieldBoxApproveAllMsg memory _approval) internal {
        try IPermitAll(_approval.target).permitAll(
            _approval.owner, _approval.spender, _approval.deadline, _approval.v, _approval.r, _approval.s
        ) {} catch {}
    }

    /**
     * @notice Executes YieldBox setApprovalForAll(false) operation.
     * @param _approval The approval message.
     */
    function _yieldBoxPermitRevokeAll(YieldBoxApproveAllMsg memory _approval) internal {
        try IPermitAll(_approval.target).revokeAll(
            _approval.owner, _approval.spender, _approval.deadline, _approval.v, _approval.r, _approval.s
        ) {} catch {}
    }

    /**
     * @notice Executes SGL/BB permitLend operation.
     * @param _approval The approval message.
     */
    function _marketPermitAssetApproval(MarketPermitActionMsg memory _approval) internal {
        try IPermit(_approval.target).permit(
            _approval.owner,
            _approval.spender,
            _approval.value,
            _approval.deadline,
            _approval.v,
            _approval.r,
            _approval.s
        ) {} catch {}
    }

    /**
     * @notice Executes SGL/BB permitBorrow operation.
     * @param _approval The approval message.
     */
    function _marketPermitCollateralApproval(MarketPermitActionMsg memory _approval) internal {
        try IPermitBorrow(_approval.target).permitBorrow(
            _approval.owner,
            _approval.spender,
            _approval.value,
            _approval.deadline,
            _approval.v,
            _approval.r,
            _approval.s
        ) {} catch {}
    }

    function _sanitizeTarget(address target) private view {
        ICluster cluster = ICluster(StorageSlot.getAddressSlot(CLUSTER_SLOT).value);
        if (!cluster.isWhitelisted(0, target)) {
            revert InvalidApprovalTarget(target);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.22;

// LZ
import {OptionsBuilder} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import {OFTMsgCodec} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTMsgCodec.sol";
import {BytesLib} from "solidity-bytes-utils/contracts/BytesLib.sol";

// Tapioca
import {
    ITapiocaOmnichainEngine,
    ERC20PermitApprovalMsg,
    ERC721PermitApprovalMsg,
    LZSendParam,
    RemoteTransferMsg,
    YieldBoxApproveAllMsg,
    MarketPermitActionMsg,
    YieldBoxApproveAssetMsg
} from "tapioca-periph/interfaces/periph/ITapiocaOmnichainEngine.sol";
import {IPearlmit} from "tapioca-periph/interfaces/periph/IPearlmit.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

library TapiocaOmnichainEngineCodec {
    /**
     * @dev Option Builder offsets
     *
     * @dev !!!! The options are prepend by the `OptionBuilder.newOptions()` IF it's the first option.
     *
     * ------------------------------------------------------------- *
     * Name            | type     | start | end                      *
     * ------------------------------------------------------------- *
     * NEW_OPTION      | uint16   | 0     | 2                        *
     * ------------------------------------------------------------- *
     *
     * Single option structure, see `OptionsBuilder.addExecutorLzComposeOption`
     * ------------------------------------------------------------- *
     * Name            | type     | start | end  | comment           *
     * ------------------------------------------------------------- *
     * WORKER_ID       | uint8    | 2     | 3    |                   *
     * ------------------------------------------------------------- *
     * OPTION_LENGTH   | uint16   | 3     | 5    |                   *
     * ------------------------------------------------------------- *
     * OPTION_TYPE     | uint8    | 5     | 6    |                   *
     * ------------------------------------------------------------- *
     * INDEX           | uint16   | 6     | 8    |                   *
     * ------------------------------------------------------------- *
     * GAS             | uint128  | 8     | 24   |                   *
     * ------------------------------------------------------------- *
     * VALUE           | uint128  | 24    | 40   | Can be not packed *
     * ------------------------------------------------------------- *
     */
    uint16 internal constant OP_BLDR_EXECUTOR_WORKER_ID_ = 1; // ExecutorOptions.WORKER_ID
    uint16 internal constant OP_BLDR_WORKER_ID_OFFSETS = 2;
    uint16 internal constant OP_BLDR_OPTION_LENGTH_OFFSET = 3;
    uint16 internal constant OP_BLDR_OPTIONS_TYPE_OFFSET = 5;
    uint16 internal constant OP_BLDR_INDEX_OFFSET = 6;
    uint16 internal constant OP_BLDR_GAS_OFFSET = 8;
    uint16 internal constant OP_BLDR_VALUE_OFFSET = 24;

    // LZ message offsets
    uint8 internal constant LZ_COMPOSE_SENDER = 32;

    // TapToken receiver message offsets
    uint8 internal constant MSG_TYPE_OFFSET = 2;
    uint8 internal constant MSG_LENGTH_OFFSET = 4;
    uint8 internal constant MSG_INDEX_OFFSET = 6;

    /**
     *
     * @param _msgType The message type, either custom ones with `PT_` as a prefix, or default OFT ones.
     * @param _msgIndex The index of the compose message to encode.
     * @param _msg The Tap composed message.
     * @return _tapComposedMsg The encoded message. Empty bytes if it's the end of compose message.
     */
    function encodeToeComposeMsg(bytes memory _msg, uint16 _msgType, uint16 _msgIndex, bytes memory _tapComposedMsg)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(_tapComposedMsg, _msgType, uint16(_msg.length), _msgIndex, _msg);
    }

    /**
     * @notice Decodes a TapToken composed message. Used by the TapToken receiver.
     *
     *           *    TapToken message packet   *
     * ------------------------------------------------------------- *
     * Name          | type      | start | end                       *
     * ------------------------------------------------------------- *
     * msgType       | uint16    | 0     | 2                         *
     * ------------------------------------------------------------- *
     * msgLength     | uint16    | 2     | 4                         *
     * ------------------------------------------------------------- *
     * msgIndex      | uint16    | 4     | 6                         *
     * ------------------------------------------------------------- *
     * tapComposeMsg | bytes     | 6     | msglength + 6             *
     * ------------------------------------------------------------- *
     *
     * @param _msg The composed message for the send() operation.
     * @return msgType_ The message type. (TapOFT proprietary `PT_` packets or LZ defaults).
     * @return msgLength_ The length of the message.
     * @return msgIndex_ The index of the current message.
     * @return tapComposeMsg_ The TapOFT composed message, which is the actual message.
     * @return nextMsg_ The next composed message. If the message is not composed, it'll be empty.
     */
    function decodeToeComposeMsg(bytes memory _msg)
        internal
        pure
        returns (
            uint16 msgType_,
            uint16 msgLength_,
            uint16 msgIndex_,
            bytes memory tapComposeMsg_,
            bytes memory nextMsg_
        )
    {
        msgType_ = BytesLib.toUint16(BytesLib.slice(_msg, 0, 2), 0);
        msgLength_ = BytesLib.toUint16(BytesLib.slice(_msg, MSG_TYPE_OFFSET, 2), 0);

        msgIndex_ = BytesLib.toUint16(BytesLib.slice(_msg, MSG_LENGTH_OFFSET, 2), 0);
        tapComposeMsg_ = BytesLib.slice(_msg, MSG_INDEX_OFFSET, msgLength_);

        uint256 tapComposeOffset_ = MSG_INDEX_OFFSET + msgLength_;
        nextMsg_ = BytesLib.slice(_msg, tapComposeOffset_, _msg.length - (tapComposeOffset_));
    }

    /**
     * @notice Decodes the index of a TapToken composed message.
     *
     * @param _msg The composed message for the send() operation.
     * @return msgIndex_ The index of the current message.
     */
    function decodeIndexOfToeComposeMsg(bytes memory _msg) internal pure returns (uint16 msgIndex_) {
        return BytesLib.toUint16(BytesLib.slice(_msg, MSG_LENGTH_OFFSET, 2), 0);
    }

    /**
     * @notice Decodes the next message of a TapToken composed message, if any.
     * @param _msg The composed message for the send() operation.
     * @return nextMsg_ The next composed message. If the message is not composed, it'll be empty.
     */
    function decodeNextMsgOfToeCompose(bytes memory _msg) internal pure returns (bytes memory nextMsg_) {
        uint16 msgLength_ = BytesLib.toUint16(BytesLib.slice(_msg, MSG_TYPE_OFFSET, 2), 0);

        uint256 tapComposeOffset_ = MSG_INDEX_OFFSET + msgLength_;
        nextMsg_ = BytesLib.slice(_msg, tapComposeOffset_, _msg.length - (tapComposeOffset_));
    }

    /**
     * @dev Decode LzCompose extra options message built by `OptionBuilder.addExecutorLzComposeOption()`.
     * @dev !!! IMPORTANT !!! It only works for options built only by `OptionBuilder.addExecutorLzComposeOption()`.
     *
     * @dev !!!! The options are prepend by the `OptionBuilder.newOptions()` IF it's the first option.
     * ------------------------------------------------------------- *
     * Name            | type     | start | end                      *
     * ------------------------------------------------------------- *
     * NEW_OPTION      | uint16   | 0     | 2                        *
     * ------------------------------------------------------------- *
     *
     * Single option structure, see `OptionsBuilder.addExecutorLzComposeOption`
     * ------------------------------------------------------------- *
     * Name            | type     | start | end  | comment           *
     * ------------------------------------------------------------- *
     * WORKER_ID       | uint8    | 2     | 3    |                   *
     * ------------------------------------------------------------- *
     * OPTION_LENGTH   | uint16   | 3     | 5    |                   *
     * ------------------------------------------------------------- *
     * OPTION_TYPE     | uint8    | 5     | 6    |                   *
     * ------------------------------------------------------------- *
     * INDEX           | uint16   | 6     | 8    |                   *
     * ------------------------------------------------------------- *
     * GAS             | uint128  | 8     | 24   |                   *
     * ------------------------------------------------------------- *
     * VALUE           | uint128  | 24    | 40   | Can be not packed *
     * ------------------------------------------------------------- *
     *
     * @param _options The extra options to be sanitized.
     */
    function decodeExtraOptions(bytes memory _options)
        internal
        pure
        returns (
            uint16 workerId_,
            uint16 optionLength_,
            uint16 optionType_,
            uint16 index_,
            uint128 gas_,
            uint128 value_,
            bytes memory nextMsg_
        )
    {
        workerId_ = BytesLib.toUint8(BytesLib.slice(_options, OP_BLDR_WORKER_ID_OFFSETS, 1), 0);
        // If the workerId is not decoded correctly, it means option index != 0.
        if (workerId_ != OP_BLDR_EXECUTOR_WORKER_ID_) {
            // add the new options prefix
            _options = abi.encodePacked(OptionsBuilder.newOptions(), _options);
            workerId_ = OP_BLDR_EXECUTOR_WORKER_ID_;
        }

        /// @dev Option length is not the size of the actual `_options`, but the size of the option
        /// starting from `OPTION_TYPE`.
        optionLength_ = BytesLib.toUint16(BytesLib.slice(_options, OP_BLDR_OPTION_LENGTH_OFFSET, 2), 0);
        optionType_ = BytesLib.toUint8(BytesLib.slice(_options, OP_BLDR_OPTIONS_TYPE_OFFSET, 1), 0);
        index_ = BytesLib.toUint16(BytesLib.slice(_options, OP_BLDR_INDEX_OFFSET, 2), 0);
        gas_ = BytesLib.toUint128(BytesLib.slice(_options, OP_BLDR_GAS_OFFSET, 16), 0);

        /// @dev `value_` is not encoded if it's 0, check LZ `OptionBuilder.addExecutorLzComposeOption()`
        /// and `ExecutorOptions.encodeLzComposeOption()` for more info.
        /// 19 = OptionType (1) + Index (8) + Gas (16)
        if (optionLength_ == 19) {
            uint16 nextMsgOffset = OP_BLDR_VALUE_OFFSET; // 24
            if (_options.length > nextMsgOffset) {
                nextMsg_ = BytesLib.slice(_options, nextMsgOffset, _options.length - nextMsgOffset);
            }
        }
        /// 35 = OptionType (1) + Index (8) + Gas (16) + Value (16)
        if (optionLength_ == 35) {
            value_ = BytesLib.toUint128(BytesLib.slice(_options, OP_BLDR_VALUE_OFFSET, 16), 0);

            uint16 nextMsgOffset = OP_BLDR_VALUE_OFFSET + 16; // 24 + 16 = 40
            if (_options.length > nextMsgOffset) {
                nextMsg_ = BytesLib.slice(_options, nextMsgOffset, _options.length - nextMsgOffset);
            }
        }
    }

    /**
     * @notice Decodes an encoded message for the `TOFTReceiver.erc20PermitApprovalReceiver()` operation.
     *
     *                    *   message packet   *
     * ------------------------------------------------------------- *
     * Name          | type      | start | end                       *
     * ------------------------------------------------------------- *
     * token         | address   | 0     | 20                        *
     * ------------------------------------------------------------- *
     * owner         | address   | 20    | 40                        *
     * ------------------------------------------------------------- *
     * spender       | address   | 40    | 60                        *
     * ------------------------------------------------------------- *
     * value         | uint256   | 60    | 92                        *
     * ------------------------------------------------------------- *
     * deadline      | uint256   | 92    | 124                       *
     * ------------------------------------------------------------- *
     * v             | uint8     | 124   | 125                       *
     * ------------------------------------------------------------- *
     * r             | bytes32   | 125   | 157                       *
     * ------------------------------------------------------------- *
     * s             | bytes32   | 157   | 189                       *
     * ------------------------------------------------------------- *
     *
     * @param _msg The encoded message. see `TOFTMsgCodec.buildERC20PermitApprovalMsg()`
     */
    struct __offsets {
        uint8 tokenOffset;
        uint8 ownerOffset;
        uint8 spenderOffset;
        uint8 valueOffset;
        uint8 deadlineOffset;
        uint8 vOffset;
        uint8 rOffset;
        uint8 sOffset;
    }

    /**
     * @notice Encodes the message for the `PT_YB_APPROVE_ASSET` operation.
     */
    function buildYieldBoxPermitAssetMsg(YieldBoxApproveAssetMsg memory _approvalMsg)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            _approvalMsg.target,
            _approvalMsg.owner,
            _approvalMsg.spender,
            _approvalMsg.assetId,
            _approvalMsg.deadline,
            _approvalMsg.v,
            _approvalMsg.r,
            _approvalMsg.s,
            _approvalMsg.permit
        );
    }

    function decodeYieldBoxApprovalAssetMsg(bytes memory _msg)
        internal
        pure
        returns (YieldBoxApproveAssetMsg memory approvalMsg_)
    {
        __offsets memory offsets_ = __offsets({
            tokenOffset: 20,
            ownerOffset: 40,
            spenderOffset: 60,
            valueOffset: 92,
            deadlineOffset: 124,
            vOffset: 125,
            rOffset: 157,
            sOffset: 189
        });

        // Decoded data
        address target = BytesLib.toAddress(BytesLib.slice(_msg, 0, offsets_.tokenOffset), 0);
        address owner = BytesLib.toAddress(BytesLib.slice(_msg, offsets_.tokenOffset, 20), 0);
        address spender = BytesLib.toAddress(BytesLib.slice(_msg, offsets_.ownerOffset, 20), 0);
        uint256 value = BytesLib.toUint256(BytesLib.slice(_msg, offsets_.spenderOffset, 32), 0);
        uint256 deadline = BytesLib.toUint256(BytesLib.slice(_msg, offsets_.valueOffset, 32), 0);
        uint8 v = uint8(BytesLib.toUint8(BytesLib.slice(_msg, offsets_.deadlineOffset, 1), 0));
        bytes32 r = BytesLib.toBytes32(BytesLib.slice(_msg, offsets_.vOffset, 32), 0);
        bytes32 s = BytesLib.toBytes32(BytesLib.slice(_msg, offsets_.rOffset, 32), 0);
        bool permit = _msg[offsets_.sOffset] != 0;

        // Return structured data
        approvalMsg_ = YieldBoxApproveAssetMsg(target, owner, spender, value, deadline, v, r, s, permit);
    }

    /**
     * @dev Decode an array of encoded messages for the `TOFTReceiver.erc20PermitApprovalReceiver()` operation.
     * @dev The message length must be a multiple of 189.
     *
     * @param _msg The encoded message. see `TOFTReceiver.buildERC20PermitApprovalMsg()`
     */
    function decodeArrayOfYieldBoxPermitAssetMsg(bytes memory _msg)
        internal
        pure
        returns (YieldBoxApproveAssetMsg[] memory)
    {
        /// @dev see `this.decodeERC20PermitApprovalMsg()`, token + owner + spender + value + deadline + v + r + s length = 189.
        uint256 msgCount_ = _msg.length / 190;

        YieldBoxApproveAssetMsg[] memory approvalMsgs_ = new YieldBoxApproveAssetMsg[](msgCount_);

        uint256 msgIndex_;
        for (uint256 i; i < msgCount_;) {
            approvalMsgs_[i] = decodeYieldBoxApprovalAssetMsg(BytesLib.slice(_msg, msgIndex_, 190));
            unchecked {
                msgIndex_ += 190;
                ++i;
            }
        }

        return approvalMsgs_;
    }

    /**
     * @notice Encodes the message for the `TOFTReceiver._yieldBoxRevokeAllReceiver()` operation.
     */
    function buildYieldBoxApproveAllMsg(YieldBoxApproveAllMsg memory _yieldBoxApprovalAllMsg)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            _yieldBoxApprovalAllMsg.target,
            _yieldBoxApprovalAllMsg.owner,
            _yieldBoxApprovalAllMsg.spender,
            _yieldBoxApprovalAllMsg.deadline,
            _yieldBoxApprovalAllMsg.v,
            _yieldBoxApprovalAllMsg.r,
            _yieldBoxApprovalAllMsg.s,
            _yieldBoxApprovalAllMsg.permit
        );
    }

    /**
     * @notice Encodes the message for the `TOFTReceiver._yieldBoxMarketPermitActionReceiver()` operation.
     */
    function buildMarketPermitApprovalMsg(MarketPermitActionMsg memory _marketApprovalMsg)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            _marketApprovalMsg.target,
            _marketApprovalMsg.owner,
            _marketApprovalMsg.spender,
            _marketApprovalMsg.value,
            _marketApprovalMsg.deadline,
            _marketApprovalMsg.v,
            _marketApprovalMsg.r,
            _marketApprovalMsg.s,
            _marketApprovalMsg.permitAsset
        );
    }

    struct __marketOffsets {
        uint8 targetOffset;
        uint8 ownerOffset;
        uint8 spenderOffset;
        uint8 valueOffset;
        uint8 deadlineOffset;
        uint8 vOffset;
        uint8 rOffset;
        uint8 sOffset;
    }

    /**
     * @notice Decodes an encoded message for the `TOFTReceiver.marketPermitActionReceiver()` operation.
     *
     *                    *   message packet   *
     * ------------------------------------------------------------- *
     * Name          | type      | start | end                       *
     * ------------------------------------------------------------- *
     * target        | address   | 0     | 20                        *
     * ------------------------------------------------------------- *
     * owner         | address   | 20    | 40                        *
     * ------------------------------------------------------------- *
     * spender       | address   | 40    | 60                        *
     * ------------------------------------------------------------- *
     * value         | address   | 60    | 92                        *
     * ------------------------------------------------------------- *
     * deadline      | uint256   | 92   | 124                        *
     * ------------------------------------------------------------- *
     * v             | uint8     | 124  | 125                        *
     * ------------------------------------------------------------- *
     * r             | bytes32   | 125  | 157                        *
     * ------------------------------------------------------------- *
     * s             | bytes32   | 157  | 189                        *
     * ------------------------------------------------------------- *
     * ------------------------------------------------------------- *
     * permitLend    | bool      | 189  | 190                        *
     * ------------------------------------------------------------- *
     *
     * @param _msg The encoded message. see `TOFTMsgCodec.buildMarketPermitApprovalMsg()`
     */
    function decodeMarketPermitApprovalMsg(bytes memory _msg)
        internal
        pure
        returns (MarketPermitActionMsg memory marketPermitActionMsg_)
    {
        __marketOffsets memory offsets_ = __marketOffsets({
            targetOffset: 20,
            ownerOffset: 40,
            spenderOffset: 60,
            valueOffset: 92,
            deadlineOffset: 124,
            vOffset: 125,
            rOffset: 157,
            sOffset: 189
        });

        // Decoded data
        address target = BytesLib.toAddress(BytesLib.slice(_msg, 0, offsets_.targetOffset), 0);

        address owner = BytesLib.toAddress(BytesLib.slice(_msg, offsets_.targetOffset, 20), 0);

        address spender = BytesLib.toAddress(BytesLib.slice(_msg, offsets_.ownerOffset, 20), 0);

        uint256 value = BytesLib.toUint256(BytesLib.slice(_msg, offsets_.spenderOffset, 32), 0);

        uint256 deadline = BytesLib.toUint256(BytesLib.slice(_msg, offsets_.valueOffset, 32), 0);

        uint8 v = uint8(BytesLib.toUint8(BytesLib.slice(_msg, offsets_.deadlineOffset, 1), 0));

        bytes32 r = BytesLib.toBytes32(BytesLib.slice(_msg, offsets_.vOffset, 32), 0);

        bytes32 s = BytesLib.toBytes32(BytesLib.slice(_msg, offsets_.rOffset, 32), 0);

        bool permitLend = _msg[offsets_.sOffset] != 0;

        // Return structured data
        marketPermitActionMsg_ = MarketPermitActionMsg(target, owner, spender, value, deadline, v, r, s, permitLend);
    }

    struct __ybOffsets {
        uint8 targetOffset;
        uint8 ownerOffset;
        uint8 spenderOffset;
        uint8 deadlineOffset;
        uint8 vOffset;
        uint8 rOffset;
        uint8 sOffset;
    }

    /**
     * @notice Decodes an encoded message for the `TOFTReceiver.ybPermitAll()` operation.
     *
     *                    *   message packet   *
     * ------------------------------------------------------------- *
     * Name          | type      | start | end                       *
     * ------------------------------------------------------------- *
     * target        | address   | 0     | 20                        *
     * ------------------------------------------------------------- *
     * owner         | address   | 20    | 40                        *
     * ------------------------------------------------------------- *
     * spender       | address   | 40    | 60                        *
     * ------------------------------------------------------------- *
     * deadline      | uint256   | 60   | 92                         *
     * ------------------------------------------------------------- *
     * v             | uint8     | 92   | 93                         *
     * ------------------------------------------------------------- *
     * r             | bytes32   | 93   | 125                        *
     * ------------------------------------------------------------- *
     * s             | bytes32   | 125   | 157                       *
     * ------------------------------------------------------------- *
     * permit        | bool      | 157   | 158                       *
     * ------------------------------------------------------------- *
     *
     * @param _msg The encoded message. see `TOFTMsgCodec.buildYieldBoxPermitAll()`
     */
    function decodeYieldBoxApproveAllMsg(bytes memory _msg)
        internal
        pure
        returns (YieldBoxApproveAllMsg memory ybPermitAllMsg_)
    {
        __ybOffsets memory offsets_ = __ybOffsets({
            targetOffset: 20,
            ownerOffset: 40,
            spenderOffset: 60,
            deadlineOffset: 92,
            vOffset: 93,
            rOffset: 125,
            sOffset: 157
        });

        // Decoded data
        address target = BytesLib.toAddress(BytesLib.slice(_msg, 0, offsets_.targetOffset), 0);
        address owner = BytesLib.toAddress(BytesLib.slice(_msg, offsets_.targetOffset, 20), 0);
        address spender = BytesLib.toAddress(BytesLib.slice(_msg, offsets_.ownerOffset, 20), 0);
        uint256 deadline = BytesLib.toUint256(BytesLib.slice(_msg, offsets_.spenderOffset, 32), 0);
        uint8 v = uint8(BytesLib.toUint8(BytesLib.slice(_msg, offsets_.deadlineOffset, 1), 0));
        bytes32 r = BytesLib.toBytes32(BytesLib.slice(_msg, offsets_.vOffset, 32), 0);
        bytes32 s = BytesLib.toBytes32(BytesLib.slice(_msg, offsets_.rOffset, 32), 0);

        bool permit = _msg[offsets_.sOffset] != 0;

        // Return structured data
        ybPermitAllMsg_ = YieldBoxApproveAllMsg(target, owner, spender, deadline, v, r, s, permit);
    }

    // /**
    //  * @notice Decodes the next message of extra options, if any.
    //  */
    // function decodeNextMsgOfExtraOptions(bytes memory _options) internal view returns (bytes memory nextMsg_) {
    //     uint16 OP_BLDR_GAS_OFFSET = 8;
    //     uint16 OP_BLDR_VALUE_OFFSET = 24;

    //     uint16 optionLength_ = decodeLengthOfExtraOptions(_options);
    //     console.log("optionLength_", optionLength_);

    //     /// @dev Value can be omitted if it's 0.
    //     /// check LZ `OptionBuilder.addExecutorLzComposeOption()` and `ExecutorOptions.encodeLzComposeOption()`
    //     /// 19 = OptionType (1) + Index (8) + Gas (16)
    //     if (optionLength_ == 19) {
    //         uint16 nextMsgOffset = OP_BLDR_GAS_OFFSET + 16; // 8 + 16 = 24
    //         console.log(nextMsgOffset);
    //         if (_options.length > nextMsgOffset) {
    //             nextMsg_ = BytesLib.slice(_options, nextMsgOffset, _options.length - nextMsgOffset);
    //         }
    //     }
    //     /// 35 = OptionType (1) + Index (8) + Gas (16) + Value (16)
    //     if (optionLength_ == 35) {
    //         uint16 nextMsgOffset = OP_BLDR_VALUE_OFFSET + 16; // 24 + 16 = 40
    //         if (_options.length > nextMsgOffset) {
    //             nextMsg_ = BytesLib.slice(_options, nextMsgOffset, _options.length - nextMsgOffset);
    //         }
    //     }
    // }

    /**
     * @notice Decode an OFT `_lzReceive()` message.
     *
     *          *    LzCompose message packet    *
     * ------------------------------------------------------------- *
     * Name           | type      | start | end                      *
     * ------------------------------------------------------------- *
     * composeSender  | bytes32   | 0     | 32                       *
     * ------------------------------------------------------------- *
     * oftComposeMsg_ | bytes     | 32    | _msg.Length              *
     * ------------------------------------------------------------- *
     *
     * @param _msg The composed message for the send() operation.
     * @return composeSender_ The address of the compose sender. (dst OApp).
     * @return oftComposeMsg_ The TapOFT composed message, which is the actual message.
     */
    function decodeLzComposeMsg(bytes memory _msg)
        internal
        pure
        returns (address composeSender_, bytes memory oftComposeMsg_)
    {
        composeSender_ = OFTMsgCodec.bytes32ToAddress(bytes32(BytesLib.slice(_msg, 0, LZ_COMPOSE_SENDER)));

        oftComposeMsg_ = BytesLib.slice(_msg, LZ_COMPOSE_SENDER, _msg.length - LZ_COMPOSE_SENDER);
    }

    /**
     *          *    LzCompose message packet    *
     * ------------------------------------------------------------- *
     * Name           | type      | start | end                      *
     * ------------------------------------------------------------- *
     * composeSender  | bytes32   | 0     | 32                       *
     * ------------------------------------------------------------- *
     * oftComposeMsg_ | bytes     | 32    | _msg.Length              *
     * ------------------------------------------------------------- *
     *
     *
     * @param _options  The option to decompose.
     */
    function decodeExecutorLzComposeOption(bytes memory _options) internal pure returns (address executor_) {
        return OFTMsgCodec.bytes32ToAddress(bytes32(BytesLib.slice(_options, 0, 32)));
    }

    /**
     * @notice Encodes the message for the `remoteTransfer` operation.
     * @param _remoteTransferMsg The owner + LZ send param to pass on the remote chain. (B->A)
     */
    function buildRemoteTransferMsg(RemoteTransferMsg memory _remoteTransferMsg) internal pure returns (bytes memory) {
        return abi.encode(_remoteTransferMsg);
    }

    /**
     * @notice Decode the message for the `remoteTransfer` operation.
     * @param _msg The owner + LZ send param to pass on the remote chain. (B->A)
     */
    function decodeRemoteTransferMsg(bytes memory _msg)
        internal
        pure
        returns (RemoteTransferMsg memory remoteTransferMsg_)
    {
        return abi.decode(_msg, (RemoteTransferMsg));
    }

    // ***************************************
    // * Encoding & Decoding TapOFT messages *
    // ***************************************

    /**
     * @notice Encodes the message for the `TapTokenReceiver._erc20PermitApprovalReceiver()` operation.
     */
    function encodeERC20PermitApprovalMsg(ERC20PermitApprovalMsg[] memory _erc20PermitApprovalMsg)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(_erc20PermitApprovalMsg);
    }

    function decodeERC20PermitApprovalMsg(bytes memory _msg)
        internal
        pure
        returns (ERC20PermitApprovalMsg[] memory erc20PermitApprovalMsg_)
    {
        return abi.decode(_msg, (ERC20PermitApprovalMsg[]));
    }

    /**
     * @notice Encodes the message for the `TapTokenReceiver._erc721PermitApprovalReceiver()` operation.
     */
    function encodeERC721PermitApprovalMsg(ERC721PermitApprovalMsg[] memory _erc721PermitApprovalMsg)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(_erc721PermitApprovalMsg);
    }

    /**
     * @notice Decodes an encoded message for the `TapTokenReceiver.erc721PermitApprovalReceiver()` operation.
     */
    function decodeERC721PermitApprovalMsg(bytes memory _msg)
        internal
        pure
        returns (ERC721PermitApprovalMsg[] memory)
    {
        return abi.decode(_msg, (ERC721PermitApprovalMsg[]));
    }

    function encodePearlmitApprovalMsg(
        address pearlmit,
        IPearlmit.PermitBatchTransferFrom memory _permitBatchTransferFrom
    ) internal pure returns (bytes memory) {
        return abi.encode(pearlmit, _permitBatchTransferFrom);
    }

    function decodePearlmitBatchApprovalMsg(bytes memory _msg)
        internal
        pure
        returns (address pearlmit, IPearlmit.PermitBatchTransferFrom memory _permitBatchTransferFrom)
    {
        return abi.decode(_msg, (address, IPearlmit.PermitBatchTransferFrom));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// LZ
import {
    MessagingReceipt, OFTReceipt, SendParam
} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {IOAppMsgInspector} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/interfaces/IOAppMsgInspector.sol";
import {IOAppComposer} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/interfaces/IOAppComposer.sol";
import {OFTMsgCodec} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTMsgCodec.sol";
import {Origin} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import {OFT} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";

// Tapioca
import {
    ITapiocaOmnichainReceiveExtender,
    ERC721PermitApprovalMsg,
    ERC20PermitApprovalMsg,
    RemoteTransferMsg,
    LZSendParam
} from "tapioca-periph/interfaces/periph/ITapiocaOmnichainEngine.sol";
import {TapiocaOmnichainExtExec} from "./extension/TapiocaOmnichainExtExec.sol";
import {TapiocaOmnichainEngineCodec} from "./TapiocaOmnichainEngineCodec.sol";
import {BaseTapiocaOmnichainEngine} from "./BaseTapiocaOmnichainEngine.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

abstract contract TapiocaOmnichainReceiver is BaseTapiocaOmnichainEngine, IOAppComposer {
    using OFTMsgCodec for bytes;
    using OFTMsgCodec for bytes32;

    /**
     *  @dev Triggered if the address of the composer doesn't match current contract in `lzCompose`.
     * Compose caller and receiver are the same address, which is this.
     */
    error InvalidComposer(address composer);
    error InvalidCaller(address caller); // Should be the endpoint address
    error InvalidMsgType(uint16 msgType); // Triggered if the msgType is invalid on an `_lzCompose`.
    error ExtExecFailed(string signature);

    /// @dev Compose received.
    event ComposeReceived(uint16 indexed msgType, bytes32 indexed guid, bytes composeMsg);
    /// @dev twTAP unlock operation received.
    event RemoteTransferReceived(address indexed owner, uint256 indexed dstEid, address indexed to, uint256 amount);

    /**
     * @dev !!! FIRST ENTRYPOINT, COMPOSE MSG ARE TO BE BUILT HERE  !!!
     *
     * @dev Slightly modified version of the OFT _lzReceive() operation.
     * The composed message is sent to `address(this)` instead of `toAddress`.
     * @dev Internal function to handle the receive on the LayerZero endpoint.
     * @dev Caller is verified on the public function. See `OAppReceiver.lzReceive()`.
     *
     * @param _origin The origin information.
     *  - srcEid: The source chain endpoint ID.
     *  - sender: The sender address from the src chain.
     *  - nonce: The nonce of the LayerZero message.
     * @param _guid The unique identifier for the received LayerZero message.
     * @param _message The encoded message.
     * _executor The address of the executor.
     * _extraData Additional data.
     */
    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address, /*_executor*/ // @dev unused in the default implementation.
        bytes calldata /*_extraData*/ // @dev unused in the default implementation.
    ) internal virtual override {
        // @dev The src sending chain doesn't know the address length on this chain (potentially non-evm)
        // Thus everything is bytes32() encoded in flight.
        address toAddress = _message.sendTo().bytes32ToAddress();
        // @dev Convert the amount to credit into local decimals.
        uint256 amountToCreditLD = _toLD(_message.amountSD());
        // @dev Credit the amount to the recipient and return the ACTUAL amount the recipient received in local decimals
        uint256 amountReceivedLD = _credit(toAddress, amountToCreditLD, _origin.srcEid);

        if (_message.isComposed()) {
            // @dev Stores the lzCompose payload that will be executed in a separate tx.
            // Standardizes functionality for executing arbitrary contract invocation on some non-evm chains.
            // @dev The off-chain executor will listen and process the msg based on the src-chain-callers compose options passed.
            // @dev The index is used when a OApp needs to compose multiple msgs on lzReceive.
            // For default OFT implementation there is only 1 compose msg per lzReceive, thus its always 0.
            endpoint.sendCompose(
                address(this), // Updated from default `toAddress`
                _guid,
                0, /* the index of the composed message*/
                _message
            );
        }

        emit OFTReceived(_guid, _origin.srcEid, toAddress, amountReceivedLD);
    }

    /**
     * @dev !!! SECOND ENTRYPOINT, CALLER NEEDS TO BE VERIFIED !!!
     *
     * @notice Composes a LayerZero message from an OApp.
     * @dev The message comes in form:
     *      - [composeSender::address][oftComposeMsg::bytes]
     *                                          |
     *                                          |
     *                        [msgType::uint16, composeMsg::bytes]
     * @dev The composeSender is the user that initiated the `sendPacket()` call on the srcChain.
     *
     * @param _from The address initiating the composition, typically the OApp where the lzReceive was called.
     * @param _guid The unique identifier for the corresponding LayerZero src/dst tx.
     * @param _message The composed message payload in bytes. NOT necessarily the same payload passed via lzReceive.
     */
    function lzCompose(
        address _from,
        bytes32 _guid,
        bytes calldata _message,
        address, //executor
        bytes calldata //extra Data
    ) external payable override {
        // Validate the from and the caller.
        if (_from != address(this)) {
            revert InvalidComposer(_from);
        }
        if (msg.sender != address(endpoint)) {
            revert InvalidCaller(msg.sender);
        }

        // Decode LZ compose message.
        (address srcChainSender_, bytes memory oftComposeMsg_) =
            TapiocaOmnichainEngineCodec.decodeLzComposeMsg(_message.composeMsg());
        // Execute the composed message.
        _lzCompose(srcChainSender_, _guid, oftComposeMsg_);
    }

    /**
     * @dev Modifier behavior of composed calls to be executed as a single Tx.
     * Since composed msgs and approval
     */
    function _lzCompose(address srcChainSender_, bytes32 _guid, bytes memory oftComposeMsg_) internal {
        // Decode OFT compose message.
        (uint16 msgType_,,, bytes memory tapComposeMsg_, bytes memory nextMsg_) =
            TapiocaOmnichainEngineCodec.decodeToeComposeMsg(oftComposeMsg_);

        // Call Permits/approvals if the msg type is a permit/approval.
        // If the msg type is not a permit/approval, it will call the other receivers.
        if (msgType_ == MSG_REMOTE_TRANSFER) {
            _remoteTransferReceiver(srcChainSender_, tapComposeMsg_);
        } else if (!_extExec(msgType_, srcChainSender_, tapComposeMsg_)) {
            // Check if the TOE extender is set and the msg type is valid. If so, call the TOE extender to handle msg.
            if (
                address(tapiocaOmnichainReceiveExtender) != address(0)
                    && tapiocaOmnichainReceiveExtender.isMsgTypeValid(msgType_)
            ) {
                bytes memory callData = abi.encodeWithSelector(
                    ITapiocaOmnichainReceiveExtender.toeComposeReceiver.selector,
                    msgType_,
                    srcChainSender_,
                    tapComposeMsg_
                );
                (bool success, bytes memory returnData) =
                    address(tapiocaOmnichainReceiveExtender).delegatecall(callData);
                if (!success) {
                    revert(_getTOEExtenderRevertMsg(returnData));
                }
            } else {
                // If no TOE extender is set or msg type doesn't match extender, try to call the internal receiver.
                if (!_toeComposeReceiver(msgType_, srcChainSender_, tapComposeMsg_)) {
                    revert InvalidMsgType(msgType_);
                }
            }
        }

        emit ComposeReceived(msgType_, _guid, tapComposeMsg_);
        if (nextMsg_.length > 0) {
            _lzCompose(srcChainSender_, _guid, nextMsg_);
        }
    }

    // ********************* //
    // ***** RECEIVERS ***** //
    // ********************* //

    /**
     * @dev Meant to be override by TOE contracts, such as tOFT or TapToken, to handle their own msg types.
     *
     * @param _msgType is the msgType of the composed message. See `TapiocaOmnichainEngineCodec.decodeToeComposeMsg()`.
     * See `BaseTapiocaOmnichainEngine` to see the default TOE messages types.
     * @param _srcChainSender The address of the sender on the source chain.
     * @param _toeComposeMsg is the composed message payload, of whatever the _msgType handler is expecting.
     * @return success is the success of the composed message handler. If no handler is found, it should return false to trigger `InvalidMsgType()`.
     */
    function _toeComposeReceiver(uint16 _msgType, address _srcChainSender, bytes memory _toeComposeMsg)
        internal
        virtual
        returns (bool success)
    {}

    /**
     * @dev Transfers tokens AND composed messages from this contract to the recipient on the chain A. Flow of calls is: A->B->A.
     * @dev The user needs to have approved the TapToken contract to spend the TAP.
     *
     * @param _srcChainSender The address of the sender on the source chain.
     * @param _data The call data containing info about the transfer (LZSendParam).
     */
    function _remoteTransferReceiver(address _srcChainSender, bytes memory _data) internal virtual {
        RemoteTransferMsg memory remoteTransferMsg_ = TapiocaOmnichainEngineCodec.decodeRemoteTransferMsg(_data);

        /// @dev xChain owner needs to have approved dst srcChain `sendPacket()` msg.sender in a previous composedMsg. Or be the same address.
        _internalTransferWithAllowance(
            remoteTransferMsg_.owner, _srcChainSender, remoteTransferMsg_.lzSendParam.sendParam.amountLD
        );

        // Make the internal transfer, burn the tokens from this contract and send them to the recipient on the other chain.
        _internalRemoteTransferSendPacket(
            _srcChainSender, remoteTransferMsg_.lzSendParam, remoteTransferMsg_.composeMsg, remoteTransferMsg_.owner
        );

        emit RemoteTransferReceived(
            remoteTransferMsg_.owner,
            remoteTransferMsg_.lzSendParam.sendParam.dstEid,
            OFTMsgCodec.bytes32ToAddress(remoteTransferMsg_.lzSendParam.sendParam.to),
            remoteTransferMsg_.lzSendParam.sendParam.amountLD
        );
    }

    /**
     *
     * @dev Slightly modified version of the OFT _sendPacket() operation. To accommodate the `srcChainSender` parameter and potential dust.
     * @dev !!! IMPORTANT !!! made ONLY for the `_remoteTransferReceiver()` operation.
     */
    function _internalRemoteTransferSendPacket(
        address _srcChainSender,
        LZSendParam memory _lzSendParam,
        bytes memory _composeMsg,
        address _owner
    ) internal returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt) {
        // Burn tokens from this contract
        (uint256 amountDebitedLD_, uint256 amountToCreditLD_) = _debitView(
            _lzSendParam.sendParam.amountLD, _lzSendParam.sendParam.minAmountLD, _lzSendParam.sendParam.dstEid
        );
        _burn(address(this), amountToCreditLD_);

        _lzSendParam.sendParam.amountLD = amountToCreditLD_;
        _lzSendParam.sendParam.minAmountLD = amountToCreditLD_;

        // If the srcChain amount request is bigger than the debited one, overwrite the amount to credit with the amount debited and send the difference back to the user.
        if (_lzSendParam.sendParam.amountLD > amountDebitedLD_) {
            // Send the difference back to the user
            _transfer(address(this), _owner, _lzSendParam.sendParam.amountLD - amountDebitedLD_);

            // Overwrite the amount to credit with the amount debited
            _lzSendParam.sendParam.amountLD = amountDebitedLD_;
            _lzSendParam.sendParam.minAmountLD = _removeDust(amountDebitedLD_);
        }
        // Builds the options and OFT message to quote in the endpoint.
        (bytes memory message, bytes memory options) = _buildOFTMsgAndOptionsMemory(
            _lzSendParam.sendParam, _lzSendParam.extraOptions, _composeMsg, amountToCreditLD_, _srcChainSender
        ); // msgSender is the sender of the composed message. We keep context by passing `_srcChainSender`.

        // Sends the message to the LayerZero endpoint and returns the LayerZero msg receipt.
        msgReceipt =
            _lzSend(_lzSendParam.sendParam.dstEid, message, options, _lzSendParam.fee, _lzSendParam.refundAddress);
        // Formulate the OFT receipt.
        oftReceipt = OFTReceipt(amountDebitedLD_, amountToCreditLD_);

        emit OFTSent(
            msgReceipt.guid, _lzSendParam.sendParam.dstEid, _srcChainSender, amountDebitedLD_, amountToCreditLD_
        );
    }

    /**
     * @notice Sends a permit/approval call to the `tapiocaOmnichainReceiveExtender` contract.
     * @param _msgType The type of the message.
     * @param _data The call data containing info about the message.
     * @return success is the success of the composed message handler. If no handler is found, it should return false to trigger `InvalidMsgType()`.
     */
    function _extExec(uint16 _msgType, address _srcChainSender, bytes memory _data) internal returns (bool) {
        string memory signature = "";
        address sender = address(0);
        if (_msgType == MSG_APPROVALS) {
            // toeExtExec.erc20PermitApproval(_data);
            signature = "erc20PermitApproval(bytes)";
        } else if (_msgType == MSG_NFT_APPROVALS) {
            // toeExtExec.erc721PermitApproval(_data);
            signature = "erc721PermitApproval(bytes)";
        } else if (_msgType == MSG_PEARLMIT_APPROVAL) {
            // toeExtExec.pearlmitApproval(_srcChainSender,_data);
            signature = "pearlmitApproval(address,bytes)";
            sender = _srcChainSender;
        } else if (_msgType == MSG_YB_APPROVE_ALL) {
            // toeExtExec.yieldBoxPermitAll(_data);
            signature = "yieldBoxPermitAll(bytes)";
        } else if (_msgType == MSG_YB_APPROVE_ASSET) {
            // toeExtExec.yieldBoxPermitAsset(_data);
            signature = "yieldBoxPermitAsset(bytes)";
        } else if (_msgType == MSG_MARKET_PERMIT) {
            // toeExtExec.marketPermit(_data);
            signature = "marketPermit(bytes)";
        } else {
            return false;
        }

        bool success;
        if (sender == address(0)) {
            (success,) = address(toeExtExec).delegatecall(abi.encodeWithSignature(signature, _data));
        } else {
            (success,) = address(toeExtExec).delegatecall(abi.encodeWithSignature(signature, sender, _data));
        }
        if (!success) revert ExtExecFailed(signature);
        return true;
    }

    // ***************** //
    // ***** UTILS ***** //
    // ***************** //

    /**
     * @dev For details about this function, check `BaseTapiocaOmnichainEngine._buildOFTMsgAndOptions()`.
     * @dev !!!! IMPORTANT !!!! The differences are:
     *      - memory instead of calldata for parameters.
     *      - `_msgSender` is used instead of using context `msg.sender`, to preserve context of the OFT call and use `msg.sender` of the source chain.
     *      - Does NOT combine options, make sure to pass valid options to cover gas costs/value transfers.
     */
    function _buildOFTMsgAndOptionsMemory(
        SendParam memory _sendParam,
        bytes memory _extraOptions,
        bytes memory _composeMsg,
        uint256 _amountToCreditLD,
        address _msgSender
    ) internal view returns (bytes memory message, bytes memory options) {
        bool hasCompose = _composeMsg.length > 0;

        message = hasCompose
            ? abi.encodePacked(
                _sendParam.to, _toSD(_amountToCreditLD), OFTMsgCodec.addressToBytes32(_msgSender), _composeMsg
            )
            : abi.encodePacked(_sendParam.to, _toSD(_amountToCreditLD));
        options = _extraOptions;

        if (msgInspector != address(0)) {
            IOAppMsgInspector(msgInspector).inspect(message, options);
        }
    }

    /**
     * @notice Return the revert message from an external call.
     * @param _returnData The return data from the external call.
     */
    function _getTOEExtenderRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        if (_returnData.length > 1000) return "Module: reason too long";

        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Module: data";
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// LZ
import {
    MessagingReceipt, OFTReceipt, SendParam
} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";

// Tapioca
import {LZSendParam} from "tapioca-periph/interfaces/periph/ITapiocaOmnichainEngine.sol";
import {BaseTapiocaOmnichainEngine} from "./BaseTapiocaOmnichainEngine.sol";
import {ICluster} from "tapioca-periph/interfaces/periph/ICluster.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

abstract contract TapiocaOmnichainSender is BaseTapiocaOmnichainEngine {
    error TapiocaOmnichainSender__ClusterRoleNotApproved();

    /**
     * @notice Sends TapToken messages.
     *
     * @dev Slightly modified version of the OFT send() operation. Includes a `_msgType` parameter.
     * The `_buildMsgAndOptionsByType()` appends the packet type to the message.
     * @dev !!! IMPORTANT !!! Use it externally only. Do not use it on a compose receive operation as the `msg.sender` will be the LZ executor.
     * @dev !!! IMPORTANT !!! If you want to send a message without sending amounts, set both `amountToSendLD` and `minAmountToCreditLD` to 0.
     *
     * @param _lzSendParam The parameters for the send operation.
     *      - _sendParam: The parameters for the send operation.
     *          - dstEid::uint32: Destination endpoint ID.
     *          - to::bytes32: Recipient address.
     *          - amountToSendLD::uint256: Amount to send in local decimals.
     *          - minAmountToCreditLD::uint256: Minimum amount to credit in local decimals.
     *      - _fee: The calculated fee for the send() operation.
     *          - nativeFee::uint256: The native fee.
     *          - lzTokenFee::uint256: The lzToken fee.
     *      - _extraOptions::bytes: Additional options for the send() operation.
     *      - refundAddress::address: The address to refund the native fee to.
     * @param _composeMsg The composed message for the send() operation. Is a combination of 1 or more TAP specific messages.
     *
     * @return msgReceipt The receipt for the send operation.
     *      - guid::bytes32: The unique identifier for the sent message.
     *      - nonce::uint64: The nonce of the sent message.
     *      - fee: The LayerZero fee incurred for the message.
     *          - nativeFee::uint256: The native fee.
     *          - lzTokenFee::uint256: The lzToken fee.
     * @return oftReceipt The OFT receipt information.
     *      - amountDebitLD::uint256: Amount of tokens ACTUALLY debited in local decimals.
     *      - amountCreditLD::uint256: Amount of tokens to be credited on the remote side.
     */
    function sendPacket(LZSendParam calldata _lzSendParam, bytes calldata _composeMsg)
        external
        payable
        returns (
            MessagingReceipt memory msgReceipt,
            OFTReceipt memory oftReceipt,
            bytes memory message,
            bytes memory options
        )
    {
        // @dev Applies the token transfers regarding this send() operation.
        // - amountDebitedLD is the amount in local decimals that was ACTUALLY debited from the sender.
        // - amountToCreditLD is the amount in local decimals that will be credited to the recipient on the remote OFT instance.
        (uint256 amountDebitedLD, uint256 amountToCreditLD) = _debit(
            msg.sender,
            _lzSendParam.sendParam.amountLD,
            _lzSendParam.sendParam.minAmountLD,
            _lzSendParam.sendParam.dstEid
        );

        // @dev Builds the options and OFT message to quote in the endpoint.
        (message, options) = _buildOFTMsgAndOptions(
            msg.sender, _lzSendParam.sendParam, _lzSendParam.extraOptions, _composeMsg, amountToCreditLD
        );

        // @dev Sends the message to the LayerZero endpoint and returns the LayerZero msg receipt.
        msgReceipt =
            _lzSend(_lzSendParam.sendParam.dstEid, message, options, _lzSendParam.fee, _lzSendParam.refundAddress);
        // @dev Formulate the OFT receipt.
        oftReceipt = OFTReceipt(amountDebitedLD, amountToCreditLD);

        emit OFTSent(msgReceipt.guid, _lzSendParam.sendParam.dstEid, msg.sender, amountDebitedLD, amountToCreditLD);
    }

    /**
     * @dev Same as `sendPacket`, with the addition of `_from`, the address of the sender.
     * The caller must have the TOE role in the Cluster contract.
     */
    function sendPacketFrom(address _from, LZSendParam calldata _lzSendParam, bytes calldata _composeMsg)
        external
        payable
        returns (
            MessagingReceipt memory msgReceipt,
            OFTReceipt memory oftReceipt,
            bytes memory message,
            bytes memory options
        )
    {
        if (_from == address(0)) {
            revert BaseTapiocaOmnichainEngine__ZeroAddress();
        }

        // Verify if caller has Cluster TOE role
        {
            ICluster cluster = getCluster();
            if (!cluster.hasRole(msg.sender, keccak256("TOE"))) {
                revert TapiocaOmnichainSender__ClusterRoleNotApproved();
            }
        }

        // @dev Applies the token transfers regarding this send() operation.
        // - amountDebitedLD is the amount in local decimals that was ACTUALLY debited from the sender.
        // - amountToCreditLD is the amount in local decimals that will be credited to the recipient on the remote OFT instance.
        (uint256 amountDebitedLD, uint256 amountToCreditLD) = _debit(
            msg.sender,
            _lzSendParam.sendParam.amountLD,
            _lzSendParam.sendParam.minAmountLD,
            _lzSendParam.sendParam.dstEid
        );

        // @dev Builds the options and OFT message to quote in the endpoint.
        (message, options) = _buildOFTMsgAndOptions(
            _from, _lzSendParam.sendParam, _lzSendParam.extraOptions, _composeMsg, amountToCreditLD
        );

        // @dev Sends the message to the LayerZero endpoint and returns the LayerZero msg receipt.
        msgReceipt =
            _lzSend(_lzSendParam.sendParam.dstEid, message, options, _lzSendParam.fee, _lzSendParam.refundAddress);
        // @dev Formulate the OFT receipt.
        oftReceipt = OFTReceipt(amountDebitedLD, amountToCreditLD);

        emit OFTSent(msgReceipt.guid, _lzSendParam.sendParam.dstEid, msg.sender, amountDebitedLD, amountToCreditLD);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * Modification of the OpenZeppelin ERC20Permit contract to support ERC721 tokens.
 * OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/extensions/draft-ERC20Permit.sol).
 *
 * @dev Implementation of the ERC-4494 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-4494[EIP-4494].
 *
 * Adds the {permit} method, which can be used to change an account's ERC721 allowance (see {IERC721-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC721-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
abstract contract ERC721Permit is ERC721, EIP712 {
    using Counters for Counters.Counter;

    mapping(uint256 => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC721 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    function permit(address spender, uint256 tokenId, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual {
        require(block.timestamp <= deadline, "ERC721Permit: expired deadline");

        address owner = ownerOf(tokenId);
        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, spender, tokenId, _useNonce(tokenId), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC721Permit: invalid signature");

        _approve(spender, tokenId);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(uint256 _tokenId) public view virtual returns (uint256) {
        return _nonces[_tokenId].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     */
    function _useNonce(uint256 _tokenId) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[_tokenId];
        current = nonce.current();
        nonce.increment();
    }

    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize)
        internal
        virtual
        override
    {
        _useNonce(firstTokenId);
        super._afterTokenTransfer(from, to, firstTokenId, batchSize);
    }
}