// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { SnarkConstants } from "./SnarkConstants.sol";

library PoseidonT3 {
    function poseidon(uint256[2] memory input) public pure returns (uint256) {}
}

library PoseidonT4 {
    function poseidon(uint256[3] memory input) public pure returns (uint256) {}
}

library PoseidonT5 {
    function poseidon(uint256[4] memory input) public pure returns (uint256) {}
}

library PoseidonT6 {
    function poseidon(uint256[5] memory input) public pure returns (uint256) {}
}

/*
 * A SHA256 hash function for any number of input elements, and Poseidon hash
 * functions for 2, 3, 4, 5, and 12 input elements.
 */
contract Hasher is SnarkConstants {
    function sha256Hash(uint256[] memory array) public pure returns (uint256) {
        return uint256(sha256(abi.encodePacked(array))) % SNARK_SCALAR_FIELD;
    }

    function hash2(uint256[2] memory array) public pure returns (uint256) {
        return PoseidonT3.poseidon(array);
    }

    function hash3(uint256[3] memory array) public pure returns (uint256) {
        return PoseidonT4.poseidon(array);
    }

    function hash4(uint256[4] memory array) public pure returns (uint256) {
        return PoseidonT5.poseidon(array);
    }

    function hash5(uint256[5] memory array) public pure returns (uint256) {
        return PoseidonT6.poseidon(array);
    }

    function hashLeftRight(uint256 _left, uint256 _right)
    public
    pure
    returns (uint256)
    {
        uint256[2] memory input;
        input[0] = _left;
        input[1] = _right;
        return hash2(input);
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

// 2019 OKIMS

pragma solidity ^0.8.10;

library Pairing {

    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct G1Point {
        uint256 x;
        uint256 y;
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] x;
        uint256[2] y;
    }

    /*
     * @return The negation of p, i.e. p.plus(p.negate()) should be zero. 
     */
    function negate(G1Point memory p) internal pure returns (G1Point memory) {

        // The prime q in the base field F_q for G1
        if (p.x == 0 && p.y == 0) {
            return G1Point(0, 0);
        } else {
            return G1Point(p.x, PRIME_Q - (p.y % PRIME_Q));
        }
    }

    /*
     * @return The sum of two points of G1
     */
    function plus(
        G1Point memory p1,
        G1Point memory p2
    ) internal view returns (G1Point memory r) {

        uint256[4] memory input;
        input[0] = p1.x;
        input[1] = p1.y;
        input[2] = p2.x;
        input[3] = p2.y;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success,"pairing-add-failed");
    }

    /*
     * @return The product of a point on G1 and a scalar, i.e.
     *         p == p.scalar_mul(1) and p.plus(p) == p.scalar_mul(2) for all
     *         points p.
     */
    function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {

        uint256[3] memory input;
        input[0] = p.x;
        input[1] = p.y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }

    /* @return The result of computing the pairing check
     *         e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
     *         For example,
     *         pairing([P1(), P1().negate()], [P2(), P2()]) should return true.
     */
    function pairing(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    ) internal view returns (bool) {

        G1Point[4] memory p1 = [a1, b1, c1, d1];
        G2Point[4] memory p2 = [a2, b2, c2, d2];

        uint256 inputSize = 24;
        uint256[] memory input = new uint256[](inputSize);

        for (uint256 i = 0; i < 4; i++) {
            uint256 j = i * 6;
            input[j + 0] = p1[i].x;
            input[j + 1] = p1[i].y;
            input[j + 2] = p2[i].x[0];
            input[j + 3] = p2[i].x[1];
            input[j + 4] = p2[i].y[0];
            input[j + 5] = p2[i].y[1];
        }

        uint256[1] memory out;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success, "pairing-opcode-failed");

        return out[0] != 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import { Pairing } from "./Pairing.sol";

contract SnarkCommon {
    struct VerifyingKey {
        Pairing.G1Point alpha1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] ic;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract SnarkConstants {
    // The scalar field
    uint256 internal constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    // The public key here is the first Pedersen base
    // point from iden3's circomlib implementation of the Pedersen hash.
    // Since it is generated using a hash-to-curve function, we are
    // confident that no-one knows the private key associated with this
    // public key. See:
    // https://github.com/iden3/circomlib/blob/d5ed1c3ce4ca137a6b3ca48bec4ac12c1b38957a/src/pedersen_printbases.js
    // Its hash should equal
    // 6769006970205099520508948723718471724660867171122235270773600567925038008762.
    uint256 internal constant PAD_PUBKEY_X = 10457101036533406547632367118273992217979173478358440826365724437999023779287;
    uint256 internal constant PAD_PUBKEY_Y = 19824078218392094440610104313265183977899662750282163392862422243483260492317;
    // The Keccack256 hash of 'Maci'
    uint256 internal constant NOTHING_UP_MY_SLEEVE = 8370432830353022751713833565135785980866757267633941821328460903436894336785;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { Pairing } from "./Pairing.sol";
import { SnarkConstants } from "./SnarkConstants.sol";
import { SnarkCommon } from "./SnarkCommon.sol";

abstract contract IVerifier is SnarkCommon {
    function verify(
        uint256[8] memory,
        VerifyingKey memory,
        uint256
    ) virtual public view returns (bool);
}

contract MockVerifier is IVerifier, SnarkConstants {
    bool result = true;
    function verify(
        uint256[8] memory,
        VerifyingKey memory,
        uint256
    ) override public view returns (bool) {
        return result;
    }
}

contract Verifier is IVerifier, SnarkConstants {
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }

    using Pairing for *;

    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    string constant ERROR_PROOF_Q = "VE1";
    string constant ERROR_INPUT_VAL = "VE2";

    /*
     * @returns Whether the proof is valid given the verifying key and public
     *          input. Note that this function only supports one public input.
     *          Refer to the Semaphore source code for a verifier that supports
     *          multiple public inputs.
     */
    function verify(
        uint256[8] memory _proof,
        VerifyingKey memory vk,
        uint256 input
    ) override public view returns (bool) {
        Proof memory proof;
        proof.a = Pairing.G1Point(_proof[0], _proof[1]);
        proof.b = Pairing.G2Point(
            [_proof[2], _proof[3]],
            [_proof[4], _proof[5]]
        );
        proof.c = Pairing.G1Point(_proof[6], _proof[7]);

        // Make sure that proof.A, B, and C are each less than the prime q
        require(proof.a.x < PRIME_Q, ERROR_PROOF_Q);
        require(proof.a.y < PRIME_Q, ERROR_PROOF_Q);

        require(proof.b.x[0] < PRIME_Q, ERROR_PROOF_Q);
        require(proof.b.y[0] < PRIME_Q, ERROR_PROOF_Q);

        require(proof.b.x[1] < PRIME_Q, ERROR_PROOF_Q);
        require(proof.b.y[1] < PRIME_Q, ERROR_PROOF_Q);

        require(proof.c.x < PRIME_Q, ERROR_PROOF_Q);
        require(proof.c.y < PRIME_Q, ERROR_PROOF_Q);

        // Make sure that the input is less than the snark scalar field
        require(input < SNARK_SCALAR_FIELD, ERROR_INPUT_VAL);

        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);

        vk_x = Pairing.plus(
            vk_x,
            Pairing.scalar_mul(vk.ic[1], input)
        );

        vk_x = Pairing.plus(vk_x, vk.ic[0]);

        return Pairing.pairing(
            Pairing.negate(proof.a),
            proof.b,
            vk.alpha1,
            vk.beta2,
            vk_x,
            vk.gamma2,
            proof.c,
            vk.delta2
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Hasher} from "./crypto/Hasher.sol";

contract IPubKey {
    struct PubKey {
        uint256 x;
        uint256 y;
    }
}

contract IMessage {
    uint8 constant MESSAGE_DATA_LENGTH = 10;

    struct Message {
        uint256 msgType; // 1: vote message (size 10), 2: topup message (size 2)
        uint256[MESSAGE_DATA_LENGTH] data; // data length is padded to size 10
    }
}

contract DomainObjs is IMessage, Hasher, IPubKey {
    struct StateLeaf {
        PubKey pubKey;
        uint256 voiceCreditBalance;
        uint256 timestamp;
    }

    function hashStateLeaf(StateLeaf memory _stateLeaf)
        public
        pure
        returns (uint256)
    {
        uint256[4] memory plaintext;
        plaintext[0] = _stateLeaf.pubKey.x;
        plaintext[1] = _stateLeaf.pubKey.y;
        plaintext[2] = _stateLeaf.voiceCreditBalance;
        plaintext[3] = _stateLeaf.timestamp;

        return hash4(plaintext);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import { VkRegistry } from "./VkRegistry.sol";
import { AccQueue } from "./trees/AccQueue.sol";

interface IMACI {
    function stateTreeDepth() external view returns (uint8);
    function vkRegistry() external view returns (VkRegistry);
    function getStateAqRoot() external view returns (uint256);
    function mergeStateAqSubRoots(uint256 _numSrQueueOps, uint256 _pollId) external;
    function mergeStateAq(uint256 _pollId) external returns (uint256);
    function numSignUps() external view returns (uint256);
    function stateAq() external view returns (AccQueue);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {AccQueue} from "./trees/AccQueue.sol";
import {IMACI} from "./IMACI.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Poll} from "./Poll.sol";
import {SnarkCommon} from "./crypto/SnarkCommon.sol";
import {Hasher} from "./crypto/Hasher.sol";
import {CommonUtilities} from "./utilities/Utility.sol";
import {Verifier} from "./crypto/Verifier.sol";
import {VkRegistry} from "./VkRegistry.sol";

/**
 * @title MessageProcessor
 * @dev MessageProcessor is used to process messages published by signup users
 * it will process message by batch due to large size of messages
 * after it finishes processing, the sbCommitment will be used for Tally and Subsidy contracts
 */
contract MessageProcessor is Ownable, SnarkCommon, CommonUtilities, Hasher {

    error NoMoreMessages();
    error StateAqNotMerged();
    error MessageAqNotMerged();
    error InvalidProcessMessageProof();
    error VkNotSet();
    error MaxVoteOptionsTooLarge();
    error NumSignUpsTooLarge();
    error CurrentMessageBatchIndexTooLarge();
    error BatchEndIndexTooLarge();

    // Whether there are unprocessed messages left
    bool public processingComplete;
    // The number of batches processed
    uint256 public numBatchesProcessed;
    // The current message batch index. When the coordinator runs
    // processMessages(), this action relates to messages
    // currentMessageBatchIndex to currentMessageBatchIndex + messageBatchSize.
    uint256 public currentMessageBatchIndex;
   // The commitment to the state and ballot roots
    uint256 public sbCommitment;

    Verifier public verifier;

    constructor(Verifier _verifier) {
        verifier = _verifier;
    }


    /**
     * Update the Poll's currentSbCommitment if the proof is valid.
     * @param _poll The poll to update
     * @param _newSbCommitment The new state root and ballot root commitment
     *                         after all messages are processed
     * @param _proof The zk-SNARK proof
     */
    function processMessages(
        Poll _poll,
        uint256 _newSbCommitment,
        uint256[8] memory _proof
    ) external onlyOwner {
        _votingPeriodOver(_poll);
        // There must be unprocessed messages
        if (processingComplete) {
            revert NoMoreMessages();
        }

        // The state AccQueue must be merged
        if (!_poll.stateAqMerged()) {
            revert StateAqNotMerged();
        }

        // Retrieve stored vals
        (, , uint8 messageTreeDepth, ) = _poll.treeDepths();
        (uint256 messageBatchSize, , ) = _poll.batchSizes();

        AccQueue messageAq;
        (, , messageAq, ) = _poll.extContracts();

        // Require that the message queue has been merged
        uint256 messageRoot = messageAq.getMainRoot(messageTreeDepth);
        if (messageRoot == 0) {
            revert MessageAqNotMerged();
        }

        // Copy the state and ballot commitment and set the batch index if this
        // is the first batch to process
        if (numBatchesProcessed == 0) {
            uint256 currentSbCommitment = _poll.currentSbCommitment();
            sbCommitment = currentSbCommitment;
            (, uint256 numMessages) = _poll.numSignUpsAndMessages();
            uint256 r = numMessages % messageBatchSize;

            if (r == 0) {
                currentMessageBatchIndex =
                    (numMessages / messageBatchSize) *
                    messageBatchSize;
            } else {
                currentMessageBatchIndex = numMessages;
            }

            if (currentMessageBatchIndex > 0) {
                if (r == 0) {
                    currentMessageBatchIndex -= messageBatchSize;
                } else {
                    currentMessageBatchIndex -= r;
                }
            }
        }

        bool isValid = verifyProcessProof(
            _poll,
            currentMessageBatchIndex,
            messageRoot,
            sbCommitment,
            _newSbCommitment,
            _proof
        );
        if (!isValid) {
            revert InvalidProcessMessageProof();
        }

        {
            (, uint256 numMessages) = _poll.numSignUpsAndMessages();
            // Decrease the message batch start index to ensure that each
            // message batch is processed in order
            if (currentMessageBatchIndex > 0) {
                currentMessageBatchIndex -= messageBatchSize;
            }

            updateMessageProcessingData(
                _newSbCommitment,
                currentMessageBatchIndex,
                numMessages <= messageBatchSize * (numBatchesProcessed + 1)
            );
        }
    }

    function verifyProcessProof(
        Poll _poll,
        uint256 _currentMessageBatchIndex,
        uint256 _messageRoot,
        uint256 _currentSbCommitment,
        uint256 _newSbCommitment,
        uint256[8] memory _proof
    ) internal view returns (bool) {
        (, , uint8 messageTreeDepth, uint8 voteOptionTreeDepth) = _poll
            .treeDepths();
        (uint256 messageBatchSize, , ) = _poll.batchSizes();
        (uint256 numSignUps, ) = _poll.numSignUpsAndMessages();
        (VkRegistry vkRegistry, IMACI maci, , ) = _poll.extContracts();

        if (address(vkRegistry) == address(0)) {
            revert VkNotSet();
        }

        // Calculate the public input hash (a SHA256 hash of several values)
        uint256 publicInputHash = genProcessMessagesPublicInputHash(
            _poll,
            _currentMessageBatchIndex,
            _messageRoot,
            numSignUps,
            _currentSbCommitment,
            _newSbCommitment
        );

        // Get the verifying key from the VkRegistry
        VerifyingKey memory vk = vkRegistry.getProcessVk(
            maci.stateTreeDepth(),
            messageTreeDepth,
            voteOptionTreeDepth,
            messageBatchSize
        );

        return verifier.verify(_proof, vk, publicInputHash);
    }

    /**
     * @notice Returns the SHA256 hash of the packed values (see
     * genProcessMessagesPackedVals), the hash of the coordinator's public key,
     * the message root, and the commitment to the current state root and
     * ballot root. By passing the SHA256 hash of these values to the circuit
     * as a single public input and the preimage as private inputs, we reduce
     * its verification gas cost though the number of constraints will be
     * higher and proving time will be higher.
     * @param _poll: contract address 
     * @param _currentMessageBatchIndex: batch index of current message batch
     * @param _numSignUps: number of users that signup
     * @param _currentSbCommitment: current sbCommitment
     * @param _newSbCommitment: new sbCommitment after we update this message batch
     * @return returns the SHA256 hash of the packed values 
     */
    function genProcessMessagesPublicInputHash(
        Poll _poll,
        uint256 _currentMessageBatchIndex,
        uint256 _messageRoot,
        uint256 _numSignUps,
        uint256 _currentSbCommitment,
        uint256 _newSbCommitment
    ) public view returns (uint256) {
        uint256 coordinatorPubKeyHash = _poll.coordinatorPubKeyHash();

        uint256 packedVals = genProcessMessagesPackedVals(
            _poll,
            _currentMessageBatchIndex,
            _numSignUps
        );

        (uint256 deployTime, uint256 duration) = _poll
            .getDeployTimeAndDuration();

        uint256[] memory input = new uint256[](6);
        input[0] = packedVals;
        input[1] = coordinatorPubKeyHash;
        input[2] = _messageRoot;
        input[3] = _currentSbCommitment;
        input[4] = _newSbCommitment;
        input[5] = deployTime + duration;
        uint256 inputHash = sha256Hash(input);

        return inputHash;
    }

    /**
     * One of the inputs to the ProcessMessages circuit is a 250-bit
     * representation of four 50-bit values. This function generates this
     * 250-bit value, which consists of the maximum number of vote options, the
     * number of signups, the current message batch index, and the end index of
     * the current batch.
     * @param _poll: the poll contract
     * @param _currentMessageBatchIndex: batch index of current message batch
     * @param _numSignUps: number of users that signup
     */
    function genProcessMessagesPackedVals(
        Poll _poll,
        uint256 _currentMessageBatchIndex,
        uint256 _numSignUps
    ) public view returns (uint256) {
        (, uint256 maxVoteOptions) = _poll.maxValues();
        (, uint256 numMessages) = _poll.numSignUpsAndMessages();
        (uint24 mbs, , ) = _poll.batchSizes();
        uint256 messageBatchSize = uint256(mbs);

        uint256 batchEndIndex = _currentMessageBatchIndex + messageBatchSize;
        if (batchEndIndex > numMessages) {
            batchEndIndex = numMessages;
        }

        if (maxVoteOptions >= 2**50) revert MaxVoteOptionsTooLarge();
        if (_numSignUps >= 2**50) revert NumSignUpsTooLarge();
        if (_currentMessageBatchIndex >= 2**50) revert CurrentMessageBatchIndexTooLarge();
        if (batchEndIndex >= 2**50) revert BatchEndIndexTooLarge();

        uint256 result = maxVoteOptions +
            (_numSignUps << 50) +
            (_currentMessageBatchIndex << 100) +
            (batchEndIndex << 150);

        return result;
    }

    /**
     * @notice update message processing state variables
     * @param _newSbCommitment: sbCommitment to be updated
     * @param _currentMessageBatchIndex: currentMessageBatchIndex to be updated
     * @param _processingComplete: update flag that indicate processing is finished or not
     */
    function updateMessageProcessingData(
        uint256 _newSbCommitment,
        uint256 _currentMessageBatchIndex,
        bool _processingComplete
    ) internal {
        sbCommitment = _newSbCommitment;
        processingComplete = _processingComplete;
        currentMessageBatchIndex = _currentMessageBatchIndex;
        numBatchesProcessed++;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Params {
    // This structs help to reduce the number of parameters to the constructor
    // and avoid a stack overflow error during compilation
    struct TreeDepths {
        uint8 intStateTreeDepth;
        uint8 messageTreeSubDepth;
        uint8 messageTreeDepth;
        uint8 voteOptionTreeDepth;
    }

    struct BatchSizes {
        uint24 messageBatchSize;
        uint24 tallyBatchSize;
        uint24 subsidyBatchSize;
    }

    struct MaxValues {
        uint256 maxMessages;
        uint256 maxVoteOptions;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IMACI} from "./IMACI.sol";
import {Params} from "./Params.sol";
import {SnarkCommon} from "./crypto/SnarkCommon.sol";
import {DomainObjs, IPubKey, IMessage} from "./DomainObjs.sol";
import {AccQueue, AccQueueQuinaryMaci} from "./trees/AccQueue.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {VkRegistry} from "./VkRegistry.sol";
import {Verifier} from "./crypto/Verifier.sol";
import {EmptyBallotRoots} from "./trees/EmptyBallotRoots.sol";
import {TopupCredit} from "./TopupCredit.sol";
import {Utilities} from "./utilities/Utility.sol";
import {MessageProcessor} from "./MessageProcessor.sol";

contract PollDeploymentParams {
    struct ExtContracts {
        VkRegistry vkRegistry;
        IMACI maci;
        AccQueue messageAq;
        TopupCredit topupCredit;
    }
}

/*
 * A factory contract which deploys Poll contracts. It allows the MACI contract
 * size to stay within the limit set by EIP-170.
 */
contract PollFactory is
    Params,
    IPubKey,
    Ownable,
    PollDeploymentParams
{
    error InvalidMaxValues();

    /*
     * Deploy a new Poll contract and AccQueue contract for messages.
     */
    function deploy(
        uint256 _duration,
        MaxValues memory _maxValues,
        TreeDepths memory _treeDepths,
        BatchSizes memory _batchSizes,
        PubKey memory _coordinatorPubKey,
        VkRegistry _vkRegistry,
        IMACI _maci,
        TopupCredit _topupCredit,
        address _pollOwner
    ) public returns (Poll) {
        uint256 treeArity = 5;

        // Validate _maxValues
        // NOTE: these checks may not be necessary. Removing them will save
        // 0.28 Kb of bytecode.

        // maxVoteOptions must be less than 2 ** 50 due to circuit limitations;
        // it will be packed as a 50-bit value along with other values as one
        // of the inputs (aka packedVal)
        if (
            _maxValues.maxMessages > treeArity**uint256(_treeDepths.messageTreeDepth) ||
            _maxValues.maxMessages < _batchSizes.messageBatchSize ||
            _maxValues.maxMessages % _batchSizes.messageBatchSize != 0 ||
            _maxValues.maxVoteOptions > treeArity**uint256(_treeDepths.voteOptionTreeDepth) ||
            _maxValues.maxVoteOptions >= (2**50)
        ) {
            revert InvalidMaxValues();
        }

        AccQueue messageAq = new AccQueueQuinaryMaci(_treeDepths.messageTreeSubDepth);

        ExtContracts memory extContracts;

        // TODO: remove _vkRegistry; only PollProcessorAndTallyer needs it
        extContracts.vkRegistry = _vkRegistry;
        extContracts.maci = _maci;
        extContracts.messageAq = messageAq;
        extContracts.topupCredit = _topupCredit;

        Poll poll = new Poll(
            _duration,
            _maxValues,
            _treeDepths,
            _batchSizes,
            _coordinatorPubKey,
            extContracts
        );

        // Make the Poll contract own the messageAq contract, so only it can
        // run enqueue/merge
        messageAq.transferOwnership(address(poll));

        // init messageAq 
        poll.init();

        // TODO: should this be _maci.owner() instead?
        poll.transferOwnership(_pollOwner);

        return poll;
    }
}

/*
 * Do not deploy this directly. Use PollFactory.deploy() which performs some
 * checks on the Poll constructor arguments.
 */
contract Poll is
    Params,
    Utilities,
    SnarkCommon,
    Ownable,
    PollDeploymentParams,
    EmptyBallotRoots
{
    using SafeERC20 for ERC20;

    bool internal isInit = false;
    // The coordinator's public key
    PubKey public coordinatorPubKey;

    uint256 public mergedStateRoot;
    uint256 public coordinatorPubKeyHash;

    // TODO: to reduce the Poll bytecode size, consider storing deployTime and
    // duration in a mapping in the MACI contract

    // The timestamp of the block at which the Poll was deployed
    uint256 internal deployTime;

    // The duration of the polling period, in seconds
    uint256 internal duration;

    function getDeployTimeAndDuration() public view returns (uint256, uint256) {
        return (deployTime, duration);
    }

    // Whether the MACI contract's stateAq has been merged by this contract
    bool public stateAqMerged;

    // The commitment to the state leaves and the ballots. This is
    // hash3(stateRoot, ballotRoot, salt).
    // Its initial value should be
    // hash(maciStateRootSnapshot, emptyBallotRoot, 0)
    // Each successful invocation of processMessages() should use a different
    // salt to update this value, so that an external observer cannot tell in
    // the case that none of the messages are valid.
    uint256 public currentSbCommitment;

    uint256 internal numMessages;

    function numSignUpsAndMessages() public view returns (uint256, uint256) {
        uint256 numSignUps = extContracts.maci.numSignUps();
        return (numSignUps, numMessages);
    }

    MaxValues public maxValues;
    TreeDepths public treeDepths;
    BatchSizes public batchSizes;

    // errors 
    error VotingPeriodOver();
    error VotingPeriodNotOver();
    error PollAlreadyInit();
    error TooManyMessages();
    error MaciPubKeyLargerThanSnarkFieldSize();
    error StateAqAlreadyMerged();
    error StateAqSubtreesNeedMerge();

    event PublishMessage(Message _message, PubKey _encPubKey);
    event TopupMessage(Message _message);
    event MergeMaciStateAqSubRoots(uint256 _numSrQueueOps);
    event MergeMaciStateAq(uint256 _stateRoot);
    event MergeMessageAqSubRoots(uint256 _numSrQueueOps);
    event MergeMessageAq(uint256 _messageRoot);

    ExtContracts public extContracts;

    /*
     * Each MACI instance can have multiple Polls.
     * When a Poll is deployed, its voting period starts immediately.
     */
    constructor(
        uint256 _duration,
        MaxValues memory _maxValues,
        TreeDepths memory _treeDepths,
        BatchSizes memory _batchSizes,
        PubKey memory _coordinatorPubKey,
        ExtContracts memory _extContracts
    ) {
        extContracts = _extContracts;

        coordinatorPubKey = _coordinatorPubKey;
        coordinatorPubKeyHash = hashLeftRight(
            _coordinatorPubKey.x,
            _coordinatorPubKey.y
        );
        duration = _duration;
        maxValues = _maxValues;
        batchSizes = _batchSizes;
        treeDepths = _treeDepths;

        // Record the current timestamp
        deployTime = block.timestamp;
    }

    /*
     * A modifier that causes the function to revert if the voting period is
     * not over.
     */
    modifier isAfterVotingDeadline() {
        uint256 secondsPassed = block.timestamp - deployTime;
        if (secondsPassed <= duration) revert VotingPeriodNotOver();
        _;
    }

    modifier isWithinVotingDeadline() {
        uint256 secondsPassed = block.timestamp - deployTime;
        if (secondsPassed >= duration) revert VotingPeriodOver();
        _;
    }

    // should be called immediately after Poll creation and messageAq ownership transferred
    function init() public {
        if (isInit) revert PollAlreadyInit();
        // set to true so it cannot be called again
        isInit = true;

        unchecked {
            numMessages++;
        }

        // init messageAq here by inserting placeholderLeaf
        uint256[2] memory dat;
        dat[0] = NOTHING_UP_MY_SLEEVE;
        dat[1] = 0;
        (Message memory _message, PubKey memory _padKey, uint256 placeholderLeaf) = padAndHashMessage(dat, 1); 
        extContracts.messageAq.enqueue(placeholderLeaf);
        
        emit PublishMessage(_message, _padKey); 
    }

    /*
    * Allows to publish a Topup message
    * @param stateIndex The index of user in the state queue
    * @param amount The amount of credits to topup
    */
    function topup(uint256 stateIndex, uint256 amount) public isWithinVotingDeadline {
        if (numMessages > maxValues.maxMessages) revert TooManyMessages();

        unchecked {
            numMessages++;
        }

        extContracts.topupCredit.transferFrom(
            msg.sender,
            address(this),
            amount
        );
        uint256[2] memory dat;
        dat[0] = stateIndex;
        dat[1] = amount;
        (Message memory _message, ,  uint256 messageLeaf) = padAndHashMessage(dat, 2);
        extContracts.messageAq.enqueue(messageLeaf);
        
        emit TopupMessage(_message);
    }

    /*
     * Allows anyone to publish a message (an encrypted command and signature).
     * This function also enqueues the message.
     * @param _message The message to publish
     * @param _encPubKey An epheremal public key which can be combined with the
     *     coordinator's private key to generate an ECDH shared key with which
     *     to encrypt the message.
     */
    function publishMessage(Message memory _message, PubKey memory _encPubKey)
        public isWithinVotingDeadline
    {
        if (numMessages == maxValues.maxMessages) revert TooManyMessages();

        if (_encPubKey.x >= SNARK_SCALAR_FIELD || _encPubKey.y >= SNARK_SCALAR_FIELD) {
            revert MaciPubKeyLargerThanSnarkFieldSize();
        }

        unchecked {
            numMessages++;
        }

        _message.msgType = 1;
        uint256 messageLeaf = hashMessageAndEncPubKey(_message, _encPubKey);
        extContracts.messageAq.enqueue(messageLeaf);

        emit PublishMessage(_message, _encPubKey);
    }

    
    /*
     * The first step of merging the MACI state AccQueue. This allows the
     * ProcessMessages circuit to access the latest state tree and ballots via
     * currentSbCommitment.
     */
    function mergeMaciStateAqSubRoots(uint256 _numSrQueueOps, uint256 _pollId)
        public
        onlyOwner
        isAfterVotingDeadline
    {
        // This function cannot be called after the stateAq was merged
        if (stateAqMerged) revert StateAqAlreadyMerged();

        if (!extContracts.maci.stateAq().subTreesMerged()) {
            extContracts.maci.mergeStateAqSubRoots(_numSrQueueOps, _pollId);
        }

        emit MergeMaciStateAqSubRoots(_numSrQueueOps);
    }

    /*
     * The second step of merging the MACI state AccQueue. This allows the
     * ProcessMessages circuit to access the latest state tree and ballots via
     * currentSbCommitment.
     * @param _pollId The ID of the Poll 
     */
    function mergeMaciStateAq(uint256 _pollId)
        public
        onlyOwner
        isAfterVotingDeadline
    {
        // This function can only be called once per Poll after the voting
        // deadline
        if (stateAqMerged) revert StateAqAlreadyMerged();

        stateAqMerged = true;

        if (!extContracts.maci.stateAq().subTreesMerged()) revert StateAqSubtreesNeedMerge();
        
        mergedStateRoot = extContracts.maci.mergeStateAq(_pollId);

        // Set currentSbCommitment
        uint256[3] memory sb;
        sb[0] = mergedStateRoot;
        sb[1] = emptyBallotRoots[treeDepths.voteOptionTreeDepth - 1];
        sb[2] = uint256(0);

        currentSbCommitment = hash3(sb);
        emit MergeMaciStateAq(mergedStateRoot);
    }

    /*
     * The first step in merging the message AccQueue so that the
     * ProcessMessages circuit can access the message root.
     */
    function mergeMessageAqSubRoots(uint256 _numSrQueueOps)
        public
        onlyOwner
        isAfterVotingDeadline
    {
        extContracts.messageAq.mergeSubRoots(_numSrQueueOps);
        emit MergeMessageAqSubRoots(_numSrQueueOps);
    }

    /*
     * The second step in merging the message AccQueue so that the
     * ProcessMessages circuit can access the message root.
     */
    function mergeMessageAq() public onlyOwner isAfterVotingDeadline {
        uint256 root = extContracts.messageAq.merge(
            treeDepths.messageTreeDepth
        );
        emit MergeMessageAq(root);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TopupCredit is ERC20, Ownable {
    uint8 private constant _decimals = 1;
    uint256 public constant MAXIMUM_AIRDROP_AMOUNT = 100000 * 10**_decimals;

    constructor() ERC20("TopupCredit", "TopupCredit") {
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function airdropTo(address account, uint256 amount) public onlyOwner {
        require(amount < MAXIMUM_AIRDROP_AMOUNT);
        _mint(account, amount);
    }

    function airdrop(uint256 amount) public onlyOwner {
        require(amount < MAXIMUM_AIRDROP_AMOUNT, "amount exceed maximum limit");
        _mint(msg.sender, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { PoseidonT3, PoseidonT6, Hasher } from "../crypto/Hasher.sol";
import { MerkleZeros as MerkleBinary0 } from "./zeros/MerkleBinary0.sol";
import { MerkleZeros as MerkleBinaryMaci } from "./zeros/MerkleBinaryMaci.sol";
import { MerkleZeros as MerkleQuinary0 } from "./zeros/MerkleQuinary0.sol";
import { MerkleZeros as MerkleQuinaryMaci } from "./zeros/MerkleQuinaryMaci.sol";
import { MerkleZeros as MerkleQuinaryBlankSl } from "./zeros/MerkleQuinaryBlankSl.sol";
import { MerkleZeros as MerkleQuinaryMaciWithSha256 } from "./zeros/MerkleQuinaryMaciWithSha256.sol";

/**
 * This contract defines a Merkle tree where each leaf insertion only updates a
 * subtree. To obtain the main tree root, the contract owner must merge the
 * subtrees together. Merging subtrees requires at least 2 operations:
 * mergeSubRoots(), and merge(). To get around the gas limit,
 * the mergeSubRoots() can be performed in multiple transactions.
 */
abstract contract AccQueue is Ownable, Hasher {

    // The maximum tree depth
    uint256 constant MAX_DEPTH = 32;

    // A Queue is a 2D array of Merkle roots and indices which represents nodes
    // in a Merkle tree while it is progressively updated.
    struct Queue {
        // IMPORTANT: the following declares an array of b elements of type T: T[b]
        // And the following declares an array of b elements of type T[a]: T[a][b]
        // As such, the following declares an array of MAX_DEPTH+1 arrays of
        // uint256[4] arrays, **not the other way round**:
        uint256[4][MAX_DEPTH + 1] levels;

        uint256[MAX_DEPTH + 1] indices;
    }

    // The depth of each subtree
    uint256 internal immutable subDepth;

    // The number of elements per hash operation. Should be either 2 (for
    // binary trees) or 5 (quinary trees). The limit is 5 because that is the
    // maximum supported number of inputs for the EVM implementation of the
    // Poseidon hash function
    uint256 internal immutable hashLength;

    // hashLength ** subDepth
    uint256 internal immutable subTreeCapacity;

    // True hashLength == 2, false if hashLength == 5
    bool internal isBinary;

    // The index of the current subtree. e.g. the first subtree has index 0, the
    // second has 1, and so on
    uint256 internal currentSubtreeIndex;

    // Tracks the current subtree.
    Queue internal leafQueue;

    // Tracks the smallest tree of subroots
    Queue internal subRootQueue;

    // Subtree roots
    mapping(uint256 => uint256) internal subRoots;

    // Merged roots
    uint256[MAX_DEPTH + 1] internal mainRoots;

    // Whether the subtrees have been merged
    bool public subTreesMerged;

    // Whether entire merkle tree has been merged
    bool public treeMerged;

    // The root of the shortest possible tree which fits all current subtree
    // roots
    uint256 internal smallSRTroot;

    // Tracks the next subroot to queue
    uint256 internal nextSubRootIndex;

    // The number of leaves inserted across all subtrees so far
    uint256 public numLeaves;

    error SubDepthCannotBeZero();
    error SubdepthTooLarge(uint256 _subDepth, uint256 max);
    error InvalidHashLength();
    error DepthCannotBeZero();
    error SubTreesAlreadyMerged();
    error NothingToMerge();
    error SubTreesNotMerged();
    error DepthTooLarge(uint256 _depth, uint256 max);
    error DepthTooSmall(uint256 _depth, uint256 min);
    error InvalidIndex(uint256 _index);
    
    constructor(
        uint256 _subDepth,
        uint256 _hashLength
    ) {
        if (_subDepth == 0) revert SubDepthCannotBeZero();
        if (_subDepth > MAX_DEPTH) revert SubdepthTooLarge(_subDepth, MAX_DEPTH);
        if (_hashLength != 2 && _hashLength != 5) revert InvalidHashLength();

        isBinary = _hashLength == 2;
        subDepth = _subDepth;
        hashLength = _hashLength;
        subTreeCapacity = _hashLength ** _subDepth;
    }

    /**
     * Hash the contents of the specified level and the specified leaf.
     * This is a virtual function as the hash function which the overriding
     * contract uses will be either hashLeftRight or hash5, which require
     * different input array lengths.
     * @param _level The level to hash.
     * @param _leaf The leaf include with the level.
     */
    function hashLevel(uint256 _level, uint256 _leaf)
        virtual internal returns (uint256) {}

    function hashLevelLeaf(uint256 _level, uint256 _leaf)
        virtual view public returns (uint256) {}

    /**
     * Returns the zero leaf at a specified level.
     * This is a virtual function as the hash function which the overriding
     * contract uses will be either hashLeftRight or hash5, which will produce
     * different zero values (e.g. hashLeftRight(0, 0) vs
     * hash5([0, 0, 0, 0, 0]). Moreover, the zero value may be a
     * nothing-up-my-sleeve value.
     */
    function getZero(uint256 _level) internal virtual returns (uint256) {}

    /**
     * Add a leaf to the queue for the current subtree.
     * @param _leaf The leaf to add.
     */
    function enqueue(uint256 _leaf) public onlyOwner returns (uint256) {
        uint256 leafIndex = numLeaves;
        // Recursively queue the leaf
        _enqueue(_leaf, 0);
        
        // Update the leaf counter
        numLeaves = leafIndex + 1;

        // Now that a new leaf has been added, mainRoots and smallSRTroot are
        // obsolete
        delete mainRoots;
        delete smallSRTroot;
        subTreesMerged = false;

        // If a subtree is full
        if (numLeaves % subTreeCapacity == 0) {
            // Store the subroot
            subRoots[currentSubtreeIndex] = leafQueue.levels[subDepth][0];

            // Increment the index
            currentSubtreeIndex ++;

            // Delete ancillary data
            delete leafQueue.levels[subDepth][0];
            delete leafQueue.indices;
        }

        return leafIndex;
    }

    /**
     * Updates the queue at a given level and hashes any subroots that need to
     * be hashed.
     * @param _leaf The leaf to add.
     * @param _level The level at which to queue the leaf.
     */
    function _enqueue(uint256 _leaf, uint256 _level) internal {
        require(_level <= subDepth, "AccQueue: invalid level");

        while (true) {
            uint256 n = leafQueue.indices[_level];

            if (n != hashLength - 1) {
                // Just store the leaf
                leafQueue.levels[_level][n] = _leaf;

                if (_level != subDepth) {
                    // Update the index
                    leafQueue.indices[_level]++;
                }

                return;
            }

            // Hash the leaves to next level
            _leaf = hashLevel(_level, _leaf);

            // Reset the index for this level
            delete leafQueue.indices[_level];

            // Queue the hash of the leaves into to the next level
            _level++;
        }
    }

    /**
     * Fill any empty leaves of the current subtree with zeros and store the
     * resulting subroot.
     */
    function fill() public onlyOwner {
        if (numLeaves % subTreeCapacity == 0) {
            // If the subtree is completely empty, then the subroot is a
            // precalculated zero value
            subRoots[currentSubtreeIndex] = getZero(subDepth);
        } else {
            // Otherwise, fill the rest of the subtree with zeros
            _fill(0);

            // Store the subroot
            subRoots[currentSubtreeIndex] = leafQueue.levels[subDepth][0];

            // Reset the subtree data
            delete leafQueue.levels;

            // Reset the merged roots
            delete mainRoots;
        }

        // Increment the subtree index
        uint256 curr = currentSubtreeIndex + 1;
        currentSubtreeIndex = curr;

        // Update the number of leaves
        numLeaves = curr * subTreeCapacity;

        // Reset the subroot tree root now that it is obsolete
        delete smallSRTroot;

        subTreesMerged = false;
    }

    /**
     * A function that queues zeros to the specified level, hashes,
     * the level, and enqueues the hash to the next level.
     * @param _level The level at which to queue zeros.
     */
    function _fill(uint256 _level) virtual internal {}

    /**
     * Insert a subtree. Used for batch enqueues.
     */
    function insertSubTree(uint256 _subRoot) public onlyOwner {
        subRoots[currentSubtreeIndex] = _subRoot;

        // Increment the subtree index
        currentSubtreeIndex ++;

        // Update the number of leaves
        numLeaves += subTreeCapacity;

        // Reset the subroot tree root now that it is obsolete
        delete smallSRTroot;

        subTreesMerged = false;
    }

    /*
     * Calculate the lowest possible height of a tree with all the subroots
     * merged together.
     */
    function calcMinHeight() public view returns (uint256) {
        uint256 depth = 1;
        while (true) {
            if (hashLength ** depth >= currentSubtreeIndex) {
                break;
            }
            depth ++;
        }

        return depth;
    }

    /**
     * Merge all subtrees to form the shortest possible tree.
     * This function can be called either once to merge all subtrees in a
     * single transaction, or multiple times to do the same in multiple
     * transactions. If _numSrQueueOps is set to 0, this function will attempt
     * to merge all subtrees in one go. If it is set to a number greater than
     * 0, it will perform up to that number of queueSubRoot() operations.
     * @param _numSrQueueOps The number of times this function will call
     *                       queueSubRoot(), up to the maximum number of times
     *                       is necessary. If it is set to 0, it will call
     *                       queueSubRoot() as many times as is necessary. Set
     *                       this to a low number and call this function
     *                       multiple times if there are many subroots to
     *                       merge, or a single transaction would run out of
     *                       gas.
     */
    function mergeSubRoots(
        uint256 _numSrQueueOps
    ) public onlyOwner {
        // This function can only be called once unless a new subtree is created
        if (subTreesMerged) revert SubTreesAlreadyMerged();

        // There must be subtrees to merge
        if (numLeaves == 0) revert NothingToMerge();

        // Fill any empty leaves in the current subtree with zeros ony if the
        // current subtree is not full
        if (numLeaves % subTreeCapacity != 0) {
            fill();
        }

        // If there is only 1 subtree, use its root
        if (currentSubtreeIndex == 1) {
            smallSRTroot = getSubRoot(0);
            subTreesMerged = true;
            return;
        }

        uint256 depth = calcMinHeight();

        uint256 queueOpsPerformed = 0;
        for (uint256 i = nextSubRootIndex; i < currentSubtreeIndex; i ++) {
            if (_numSrQueueOps != 0 && queueOpsPerformed == _numSrQueueOps) {
                // If the limit is not 0, stop if the limit has been reached
                return;
            }

            // Queue the next subroot
            queueSubRoot(
                getSubRoot(nextSubRootIndex),
                0,
                depth
            );

            // Increment the next subroot counter
            nextSubRootIndex ++;

            // Increment the ops counter
            queueOpsPerformed ++;
        }
        
        // The height of the tree of subroots
        uint256 m = hashLength ** depth;

        // Queue zeroes to fill out the SRT
        if (nextSubRootIndex == currentSubtreeIndex) {
            uint256 z = getZero(subDepth);
            for (uint256 i = currentSubtreeIndex; i < m; i ++) {
                queueSubRoot(z, 0, depth);
            }
        }

        // Store the smallest main root
        smallSRTroot = subRootQueue.levels[depth][0];
        subTreesMerged = true;
    }

    /*
     * Queues a subroot into the subroot tree.
     * @param _leaf The value to queue.
     * @param _level The level at which to queue _leaf.
     * @param _maxDepth The depth of the tree.
     */
    function queueSubRoot(uint256 _leaf, uint256 _level, uint256 _maxDepth) internal {
        if (_level > _maxDepth) {
            return;
        }

        uint256 n = subRootQueue.indices[_level];

        if (n != hashLength - 1) {
            // Just store the leaf
            subRootQueue.levels[_level][n] = _leaf;
            subRootQueue.indices[_level] ++;
        } else {
            // Hash the elements in this level and queue it in the next level
            uint256 hashed;
            if (isBinary) {
                uint256[2] memory inputs;
                inputs[0] = subRootQueue.levels[_level][0];
                inputs[1] = _leaf;
                hashed = hash2(inputs);
            } else {
                uint256[5] memory inputs;
                for (uint8 i = 0; i < n; i ++) {
                    inputs[i] = subRootQueue.levels[_level][i];
                }
                inputs[n] = _leaf;
                hashed = hash5(inputs);
            }

            // TODO: change recursion to a while loop
            // Recurse
            delete subRootQueue.indices[_level];
            queueSubRoot(hashed, _level + 1, _maxDepth);
        }
    }

    /**
     * Merge all subtrees to form a main tree with a desired depth.
     * @param _depth The depth of the main tree. It must fit all the leaves or
     *               this function will revert.
     */
    function merge(uint256 _depth) public onlyOwner returns (uint256) {
        // The tree depth must be more than 0
        if (_depth == 0) revert DepthCannotBeZero();

        // Ensure that the subtrees have been merged
        if (!subTreesMerged) revert SubTreesNotMerged();

        // Check the depth
        if (_depth > MAX_DEPTH) revert DepthTooLarge(_depth, MAX_DEPTH);

        // Calculate the SRT depth
        uint256 srtDepth = subDepth;
        while (true) {
            if (hashLength ** srtDepth >= numLeaves) {
                break;
            }
            srtDepth ++;
        }

        if (_depth < srtDepth) revert DepthTooSmall(_depth, srtDepth);

        // If the depth is the same as the SRT depth, just use the SRT root
        if (_depth == srtDepth) {
            mainRoots[_depth] = smallSRTroot;
            treeMerged = true;
            return smallSRTroot;
        } else {

            uint256 root = smallSRTroot;

            // Calculate the main root

            for (uint256 i = srtDepth; i < _depth; i ++) {

                uint256 z = getZero(i);

                if (isBinary) {
                    uint256[2] memory inputs;
                    inputs[0] = root;
                    inputs[1] = z;
                    root = hash2(inputs);
                } else {
                    uint256[5] memory inputs;
                    inputs[0] = root;
                    inputs[1] = z;
                    inputs[2] = z;
                    inputs[3] = z;
                    inputs[4] = z;
                    root = hash5(inputs);
                }
            }

            mainRoots[_depth] = root;
            treeMerged = true;
            return root;
        }
    }

    /*
     * Returns the subroot at the specified index. Reverts if the index refers
     * to a subtree which has not been filled yet.
     * @param _index The subroot index.
     */
    function getSubRoot(uint256 _index) public view returns (uint256) {
        if (currentSubtreeIndex <= _index) revert InvalidIndex(_index);
        return subRoots[_index];
    }

    /*
     * Returns the subroot tree (SRT) root. Its value must first be computed
     * using mergeSubRoots.
     */
    function getSmallSRTroot() public view returns (uint256) {
        if (!subTreesMerged) revert SubTreesNotMerged();
        return smallSRTroot;
    }

    /*
     * Return the merged Merkle root of all the leaves at a desired depth.
     * merge() or merged(_depth) must be called first.
     * @param _depth The depth of the main tree. It must first be computed
     *               using mergeSubRoots() and merge(). 
     */
    function getMainRoot(uint256 _depth) public view returns (uint256) {
        if (hashLength ** _depth < numLeaves) revert DepthTooSmall(_depth, numLeaves);

        return mainRoots[_depth];
    }

    function getSrIndices() public view returns (uint256, uint256) {
        return (nextSubRootIndex, currentSubtreeIndex);
    }
}

abstract contract AccQueueBinary is AccQueue {
    constructor(uint256 _subDepth) AccQueue(_subDepth, 2) {}

    function hashLevel(uint256 _level, uint256 _leaf) override internal returns (uint256) {
        uint256 hashed = hashLeftRight(leafQueue.levels[_level][0], _leaf);

        // Free up storage slots to refund gas.
        delete leafQueue.levels[_level][0];

        return hashed;
    }

    function hashLevelLeaf(uint256 _level, uint256 _leaf) override view public returns (uint256) {
        uint256 hashed = hashLeftRight(leafQueue.levels[_level][0], _leaf);
        return hashed;
    }

    function _fill(uint256 _level) override internal {
        while (_level < subDepth) {
            uint256 n = leafQueue.indices[_level];

            if (n != 0) {
                // Fill the subtree level with zeros and hash the level
                uint256 hashed;

                uint256[2] memory inputs;
                uint256 z = getZero(_level);
                inputs[0] = leafQueue.levels[_level][0];
                inputs[1] = z;
                hashed = hash2(inputs);

                // Update the subtree from the next level onwards with the new leaf
                _enqueue(hashed, _level + 1);
            }

            // Reset the current level
            delete leafQueue.indices[_level];

            _level++;
        }
    }
}

abstract contract AccQueueQuinary is AccQueue {

    constructor(uint256 _subDepth) AccQueue(_subDepth, 5) {}

    function hashLevel(uint256 _level, uint256 _leaf) override internal returns (uint256) {
        uint256[5] memory inputs;
        inputs[0] = leafQueue.levels[_level][0];
        inputs[1] = leafQueue.levels[_level][1];
        inputs[2] = leafQueue.levels[_level][2];
        inputs[3] = leafQueue.levels[_level][3];
        inputs[4] = _leaf;
        uint256 hashed = hash5(inputs);

        // Free up storage slots to refund gas. Note that using a loop here
        // would result in lower gas savings.
        delete leafQueue.levels[_level];

        return hashed;
    }

    function hashLevelLeaf(uint256 _level, uint256 _leaf) override view public returns (uint256) {
        uint256[5] memory inputs;
        inputs[0] = leafQueue.levels[_level][0];
        inputs[1] = leafQueue.levels[_level][1];
        inputs[2] = leafQueue.levels[_level][2];
        inputs[3] = leafQueue.levels[_level][3];
        inputs[4] = _leaf;
        uint256 hashed = hash5(inputs);

        return hashed;
    }

    function _fill(uint256 _level) override internal {
        while (_level < subDepth) {
            uint256 n = leafQueue.indices[_level];

            if (n != 0) {
                // Fill the subtree level with zeros and hash the level
                uint256 hashed;

                uint256[5] memory inputs;
                uint256 z = getZero(_level);
                uint8 i = 0;
                for (; i < n; i ++) {
                    inputs[i] = leafQueue.levels[_level][i];
                }

                for (; i < hashLength; i ++) {
                    inputs[i] = z;
                }
                hashed = hash5(inputs);

                // Update the subtree from the next level onwards with the new leaf
                _enqueue(hashed, _level + 1);
            }

            // Reset the current level
            delete leafQueue.indices[_level];

            _level++;
        }
    }
}

contract AccQueueBinary0 is AccQueueBinary, MerkleBinary0 {
    constructor(uint256 _subDepth) AccQueueBinary(_subDepth) {}
    function getZero(uint256 _level) internal view override returns (uint256) { return zeros[_level]; }
}

contract AccQueueBinaryMaci is AccQueueBinary, MerkleBinaryMaci {
    constructor(uint256 _subDepth) AccQueueBinary(_subDepth) {}
    function getZero(uint256 _level) internal view override returns (uint256) { return zeros[_level]; }
}

contract AccQueueQuinary0 is AccQueueQuinary, MerkleQuinary0 {
    constructor(uint256 _subDepth) AccQueueQuinary(_subDepth) {}
    function getZero(uint256 _level) internal view override returns (uint256) { return zeros[_level]; }
}

contract AccQueueQuinaryMaci is AccQueueQuinary, MerkleQuinaryMaci {
    constructor(uint256 _subDepth) AccQueueQuinary(_subDepth) {}
    function getZero(uint256 _level) internal view override returns (uint256) { return zeros[_level]; }
}

contract AccQueueQuinaryBlankSl is AccQueueQuinary, MerkleQuinaryBlankSl {
    constructor(uint256 _subDepth) AccQueueQuinary(_subDepth) {}
    function getZero(uint256 _level) internal view override returns (uint256) { return zeros[_level]; }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract EmptyBallotRoots {
    // emptyBallotRoots contains the roots of Ballot trees of five leaf
    // configurations.
    // Each tree has a depth of 10, which is the hardcoded state tree depth.
    // Each leaf is an empty ballot. A configuration refers to the depth of the
    // voice option tree for that ballot.

    // The leaf for the root at index 0 contains hash(0, root of a VO tree with
    // depth 1 and zero-value 0)

    // The leaf for the root at index 1 contains hash(0, root of a VO tree with
    // depth 2 and zero-value 0)

    // ... and so on.

    // The first parameter to the hash function is the nonce, which is 0.

    uint256[5] internal emptyBallotRoots;

    constructor() {
        emptyBallotRoots[0] = uint256(4904028317433377177773123885584230878115556059208431880161186712332781831975);
        emptyBallotRoots[1] = uint256(344732312350052944041104345325295111408747975338908491763817872057138864163);
        emptyBallotRoots[2] = uint256(19445814455012978799483892811950396383084183210860279923207176682490489907069);
        emptyBallotRoots[3] = uint256(10621810780690303482827422143389858049829670222244900617652404672125492013328);
        emptyBallotRoots[4] = uint256(17077690379337026179438044602068085690662043464643511544329656140997390498741);

    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract MerkleZeros {
    uint256[33] internal zeros;

    // Binary tree zeros (0)
    constructor() {
        zeros[0] = uint256(0);
        zeros[1] = uint256(14744269619966411208579211824598458697587494354926760081771325075741142829156);
        zeros[2] = uint256(7423237065226347324353380772367382631490014989348495481811164164159255474657);
        zeros[3] = uint256(11286972368698509976183087595462810875513684078608517520839298933882497716792);
        zeros[4] = uint256(3607627140608796879659380071776844901612302623152076817094415224584923813162);
        zeros[5] = uint256(19712377064642672829441595136074946683621277828620209496774504837737984048981);
        zeros[6] = uint256(20775607673010627194014556968476266066927294572720319469184847051418138353016);
        zeros[7] = uint256(3396914609616007258851405644437304192397291162432396347162513310381425243293);
        zeros[8] = uint256(21551820661461729022865262380882070649935529853313286572328683688269863701601);
        zeros[9] = uint256(6573136701248752079028194407151022595060682063033565181951145966236778420039);
        zeros[10] = uint256(12413880268183407374852357075976609371175688755676981206018884971008854919922);
        zeros[11] = uint256(14271763308400718165336499097156975241954733520325982997864342600795471836726);
        zeros[12] = uint256(20066985985293572387227381049700832219069292839614107140851619262827735677018);
        zeros[13] = uint256(9394776414966240069580838672673694685292165040808226440647796406499139370960);
        zeros[14] = uint256(11331146992410411304059858900317123658895005918277453009197229807340014528524);
        zeros[15] = uint256(15819538789928229930262697811477882737253464456578333862691129291651619515538);
        zeros[16] = uint256(19217088683336594659449020493828377907203207941212636669271704950158751593251);
        zeros[17] = uint256(21035245323335827719745544373081896983162834604456827698288649288827293579666);
        zeros[18] = uint256(6939770416153240137322503476966641397417391950902474480970945462551409848591);
        zeros[19] = uint256(10941962436777715901943463195175331263348098796018438960955633645115732864202);
        zeros[20] = uint256(15019797232609675441998260052101280400536945603062888308240081994073687793470);
        zeros[21] = uint256(11702828337982203149177882813338547876343922920234831094975924378932809409969);
        zeros[22] = uint256(11217067736778784455593535811108456786943573747466706329920902520905755780395);
        zeros[23] = uint256(16072238744996205792852194127671441602062027943016727953216607508365787157389);
        zeros[24] = uint256(17681057402012993898104192736393849603097507831571622013521167331642182653248);
        zeros[25] = uint256(21694045479371014653083846597424257852691458318143380497809004364947786214945);
        zeros[26] = uint256(8163447297445169709687354538480474434591144168767135863541048304198280615192);
        zeros[27] = uint256(14081762237856300239452543304351251708585712948734528663957353575674639038357);
        zeros[28] = uint256(16619959921569409661790279042024627172199214148318086837362003702249041851090);
        zeros[29] = uint256(7022159125197495734384997711896547675021391130223237843255817587255104160365);
        zeros[30] = uint256(4114686047564160449611603615418567457008101555090703535405891656262658644463);
        zeros[31] = uint256(12549363297364877722388257367377629555213421373705596078299904496781819142130);
        zeros[32] = uint256(21443572485391568159800782191812935835534334817699172242223315142338162256601);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract MerkleZeros {
    uint256[33] internal zeros;

    // Binary tree zeros (Keccak hash of 'Maci')
    constructor() {
        zeros[0] = uint256(8370432830353022751713833565135785980866757267633941821328460903436894336785);
        zeros[1] = uint256(13883108378505681706501741077199723943829197421795883447299356576923144768890);
        zeros[2] = uint256(15419121528227002346615807695865368688447806543310218580451656713665933966440);
        zeros[3] = uint256(6318262337906428951291657677634338300639543013249211096760913778778957055324);
        zeros[4] = uint256(17768974272065709481357540291486641669761745417382244600494648537227290564775);
        zeros[5] = uint256(1030673773521289386438564854581137730704523062376261329171486101180288653537);
        zeros[6] = uint256(2456832313683926177308273721786391957119973242153180895324076357329047000368);
        zeros[7] = uint256(8719489529991410281576768848178751308798998844697260960510058606396118487868);
        zeros[8] = uint256(1562826620410077272445821684229580081819470607145780146992088471567204924361);
        zeros[9] = uint256(2594027261737512958249111386518678417918764295906952540494120924791242533396);
        zeros[10] = uint256(7454652670930646290900416353463196053308124896106736687630886047764171239135);
        zeros[11] = uint256(5636576387316613237724264020484439958003062686927585603917058282562092206685);
        zeros[12] = uint256(6668187911340361678685285736007075111202281125695563765600491898900267193410);
        zeros[13] = uint256(11734657993452490720698582048616543923742816272311967755126326688155661525563);
        zeros[14] = uint256(13463263143201754346725031241082259239721783038365287587742190796879610964010);
        zeros[15] = uint256(7428603293293611296009716236093531014060986236553797730743998024965500409844);
        zeros[16] = uint256(3220236805148173410173179641641444848417275827082321553459407052920864882112);
        zeros[17] = uint256(5702296734156546101402281555025360809782656712426280862196339683480526959100);
        zeros[18] = uint256(18054517726590450486276822815339944904333304893252063892146748222745553261079);
        zeros[19] = uint256(15845875411090302918698896692858436856780638250734551924718281082237259235021);
        zeros[20] = uint256(15856603049544947491266127020967880429380981635456797667765381929897773527801);
        zeros[21] = uint256(16947753390809968528626765677597268982507786090032633631001054889144749318212);
        zeros[22] = uint256(4409871880435963944009375001829093050579733540305802511310772748245088379588);
        zeros[23] = uint256(3999924973235726549616800282209401324088787314476870617570702819461808743202);
        zeros[24] = uint256(5910085476731597359542102744346894725393370185329725031545263392891885548800);
        zeros[25] = uint256(8329789525184689042321668445575725185257025982565085347238469712583602374435);
        zeros[26] = uint256(21731745958669991600655184668442493750937309130671773804712887133863507145115);
        zeros[27] = uint256(13908786229946466860099145463206281117295829828306413881947857340025780878375);
        zeros[28] = uint256(2746378384965515118858350021060497341885459652705230422460541446030288889144);
        zeros[29] = uint256(4024247518003740702537513711866227003187955635058512298109553363285388770811);
        zeros[30] = uint256(13465368596069181921705381841358161201578991047593533252870698635661853557810);
        zeros[31] = uint256(1901585547727445451328488557530824986692473576054582208711800336656801352314);
        zeros[32] = uint256(3444131905730490180878137209421656122704458854785641062326389124060978485990);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract MerkleZeros {
    uint256[33] internal zeros;

    // Quinary tree zeros (0)
    constructor() {
        zeros[0] = uint256(0);
        zeros[1] = uint256(14655542659562014735865511769057053982292279840403315552050801315682099828156);
        zeros[2] = uint256(19261153649140605024552417994922546473530072875902678653210025980873274131905);
        zeros[3] = uint256(21526503558325068664033192388586640128492121680588893182274749683522508994597);
        zeros[4] = uint256(20017764101928005973906869479218555869286328459998999367935018992260318153770);
        zeros[5] = uint256(16998355316577652097112514691750893516081130026395813155204269482715045879598);
        zeros[6] = uint256(2612442706402737973181840577010736087708621987282725873936541279764292204086);
        zeros[7] = uint256(17716535433480122581515618850811568065658392066947958324371350481921422579201);
        zeros[8] = uint256(17437916409890180001398333108882255895598851862997171508841759030332444017770);
        zeros[9] = uint256(20806704410832383274034364623685369279680495689837539882650535326035351322472);
        zeros[10] = uint256(6821382292698461711184253213986441870942786410912797736722948342942530789476);
        zeros[11] = uint256(5916648769022832355861175588931687601652727028178402815013820610204855544893);
        zeros[12] = uint256(8979092375429814404031883906996857902016801693563521316025319397481362525766);
        zeros[13] = uint256(2921214989930864339537708350754648834701757280474461132621735242274490553963);
        zeros[14] = uint256(8930183771974746972686153669144011224662017420905079900118160414492327314176);
        zeros[15] = uint256(235368305313252659057202520253547068193638476511860624369389264358598810396);
        zeros[16] = uint256(11594802086624841314469980089838552727386894436467147447204224403068085066609);
        zeros[17] = uint256(6527402365840056202903190531155009847198979121365335038364206235405082926579);
        zeros[18] = uint256(7890267294950363768070024023123773394579161137981585347919627664365669195485);
        zeros[19] = uint256(7743021844925994795008658518659888250339967931662466893787320922384170613250);
        zeros[20] = uint256(3315762791558236426429898223445373782079540514426385620818139644150484427120);
        zeros[21] = uint256(12047412166753578299610528762227103229354276396579409944098869901020016693788);
        zeros[22] = uint256(7346375653460369101190037700418084792046605818930533590372465301789036536);
        zeros[23] = uint256(16686328169837855831280640081580124364395471639440725186157725609010405016551);
        zeros[24] = uint256(19105160640579355001844872723857900201603625359252284777965070378555675817865);
        zeros[25] = uint256(17054399483511247964029303840879817843788388567881464290309597953132679359256);
        zeros[26] = uint256(5296258093842160235704190490839277292290579093574356735268980000023915581697);
        zeros[27] = uint256(8993437003863084469472897416707962588904917898547964184966432920162387360131);
        zeros[28] = uint256(7234267096117283161039619077058835089667467648437312224957703988301725566335);
        zeros[29] = uint256(21640448288319814375882234036901598260365718394023649234526744669922384765526);
        zeros[30] = uint256(1595567811792178436811872247033324109773732075641399161664435302467654689847);
        zeros[31] = uint256(15291095622175285816966181294098521638815701170497062413595539727181544870101);
        zeros[32] = uint256(15837036953038489303182430773663047564827202645548797032627170282475341436016);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract MerkleZeros {
    uint256[33] internal zeros;

    // Quinary tree zeros (hash of a blank state leaf)
    constructor() {
        zeros[0] = uint256(6769006970205099520508948723718471724660867171122235270773600567925038008762);
        zeros[1] = uint256(1817443256073160983037956906834195537015546107754139333779374752610409243040);
        zeros[2] = uint256(5025334324706345710800763986625066818722194863275454698142520938431664775139);
        zeros[3] = uint256(14192954438167108345302805021925904074255585459982294518284934685870159779036);
        zeros[4] = uint256(20187882570958996766847085412101405873580281668670041750401431925441526137696);
        zeros[5] = uint256(19003337309269317766726592380821628773167513668895143249995308839385810331053);
        zeros[6] = uint256(8492845964288036916491732908697290386617362835683911619537012952509890847451);
        zeros[7] = uint256(21317322053785868903775560086424946986124609731059541056518805391492871868814);
        zeros[8] = uint256(4256218134522031233385262696416028085306220785615095518146227774336224649500);
        zeros[9] = uint256(20901832483812704342876390942522900825096860186886589193649848721504734341597);
        zeros[10] = uint256(9267454486648593048583319961333207622177969074484816717792204743506543655505);
        zeros[11] = uint256(7650747654726613674993974917452464536868175649563857452207429547024788245109);
        zeros[12] = uint256(12795449162487060618571749226308575208199045387848354123797521555997299022426);
        zeros[13] = uint256(2618557044910497521493457299926978327841926538380467450910611798747947773417);
        zeros[14] = uint256(4921285654960018268026585535199462620025474147042548993648101553653712920841);
        zeros[15] = uint256(3955171118947393404895230582611078362154691627898437205118006583966987624963);
        zeros[16] = uint256(14699122743207261418107167543163571550551347592030521489185842204376855027947);
        zeros[17] = uint256(19194001556311522650950142975587831061973644651464593103195262630226529549573);
        zeros[18] = uint256(6797319293744791648201295415173228627305696583566554220235084234134847845566);
        zeros[19] = uint256(1267384159070923114421683251804507954363252272096341442482679590950570779538);
        zeros[20] = uint256(3856223245980092789300785214737986268213218594679123772901587106666007826613);
        zeros[21] = uint256(18676489457897260843888223351978541467312325190019940958023830749320128516742);
        zeros[22] = uint256(1264182110328471160091364892521750324454825019784514769029658712768604765832);
        zeros[23] = uint256(2656996430278859489720531694992812241970377217691981498421470018287262214836);
        zeros[24] = uint256(18383091906017498328025573868990834275527351249551450291689105976789994000945);
        zeros[25] = uint256(13529005048172217954112431586843818755284974925259175262114689118374272942448);
        zeros[26] = uint256(12992932230018177961399273443546858115054107741258772159002781102941121463198);
        zeros[27] = uint256(2863122912185356538647249583178796893334871904920344676880115119793539219810);
        zeros[28] = uint256(21225940722224750787686036600289689346822264717843340643526494987845938066724);
        zeros[29] = uint256(10287710058152238258370855601473179390407624438853416678054122418589867334291);
        zeros[30] = uint256(19473882726731003241332772446613588021823731071450664115530121948154136765165);
        zeros[31] = uint256(5317840242664832852914696563734700089268851122527105938301831862363938018455);
        zeros[32] = uint256(16560004488485252485490851383643926099553282582813695748927880827248594395952);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract MerkleZeros {
    uint256[33] internal zeros;

    // Quinary tree zeros (Keccak hash of 'Maci')
    constructor() {
        zeros[0] = uint256(8370432830353022751713833565135785980866757267633941821328460903436894336785);
        zeros[1] = uint256(12915444503621073454579416579430905206970714557680052030066757042249102605307);
        zeros[2] = uint256(15825388848727206932541662858173052318786639683743459477657913288690190505308);
        zeros[3] = uint256(20672917177817295069558894035958266756825295443848082659014905185716743537191);
        zeros[4] = uint256(448586013948167251740855715259393055429962470693972912240018559200278204556);
        zeros[5] = uint256(3228865992178886480410396198366133115832717015233640381802715479176981303177);
        zeros[6] = uint256(19116532419590876304532847271428641103751206695152259493043279205958851263600);
        zeros[7] = uint256(13531983203936271379763604150672239370281863210813769735936250692178889682484);
        zeros[8] = uint256(8276490051100115441938424474671329955897359239518198952109759468777824929104);
        zeros[9] = uint256(1234816188709792521426066175633785051600533236493067959807265450339481920006);
        zeros[10] = uint256(14253963034950198848796956783804665963745244419038717333683296599064556174281);
        zeros[11] = uint256(6367560368479067766970398112009211893636892126125767203198799843543931913172);
        zeros[12] = uint256(9086778412328290069463938062555298073857321633960448227011862356090607842391);
        zeros[13] = uint256(1440983698234119608650157588008070947531139377294971527360643096251396484622);
        zeros[14] = uint256(3957599085599383799297196095384587366602816424699353871878382158004571037876);
        zeros[15] = uint256(2874250189355749385170216620368454832544508482778847425177457138604069991955);
        zeros[16] = uint256(21009179226085449764156117702096359546848859855915028677582017987249294772778);
        zeros[17] = uint256(11639371146919469643603772238908032714588430905217730187804009793768292270213);
        zeros[18] = uint256(6279313411277883478350325643881386249374023631847602720184182017599127173896);
        zeros[19] = uint256(21059196126634383551994255775761712285020874549906884292741523421591865338509);
        zeros[20] = uint256(9444544622817172574621750245792527383369133221167610044960147559319164808325);
        zeros[21] = uint256(5374570219497355452080912323548395721574511162814862844226178635172695078543);
        zeros[22] = uint256(4155904241440251764630449308160227499466701168124519106689866311729092343061);
        zeros[23] = uint256(15881609944326576145786405158479503217901875433072026818450276983706463215155);
        zeros[24] = uint256(20831546672064137588434602157208687297579005252478070660473540633558666587287);
        zeros[25] = uint256(3209071488384365842993449718919243416332014108747571544339190291353564426179);
        zeros[26] = uint256(10030934989297780221224272248227257782450689603145083016739151821673604746295);
        zeros[27] = uint256(16504852316033851373501270056537918974469380446508638487151124538300880427080);
        zeros[28] = uint256(5226137093551352657015038416264755428944140743893702595442932837011856178457);
        zeros[29] = uint256(18779994066356991319291039019820482828679702085087990978933303018673869446075);
        zeros[30] = uint256(12037506572124351893114409509086276299115869080424687624451184925646292710978);
        zeros[31] = uint256(12049750997011422639258622747494178076018128204515149991024639355149614767606);
        zeros[32] = uint256(3171463916443906096008599541392648187002297410622977814790586531203175805057);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract MerkleZeros {
    uint256[33] internal zeros;

    // Quinary tree (with SHA256) zeros (Keccak hash of 'Maci')
    constructor() {
        zeros[0] = uint256(8370432830353022751713833565135785980866757267633941821328460903436894336785);
        zeros[1] = uint256(15325010760924867811060011598468731160102892305643597546418886993209427402124);
        zeros[2] = uint256(5333436556486022924864323600267292046975057763731162279859756425998760869639);
        zeros[3] = uint256(10977687713725258236554818575005054118245377800202335296681050076688083648086);
        zeros[4] = uint256(17224613048028572295675465280070534343823303585304562923867790579733480935264);
        zeros[5] = uint256(17706041913665507482150667409133417574717160680803140264120398284023956076290);
        zeros[6] = uint256(9653598640710890037650186704093119545289422499247280741743943320819000499646);
        zeros[7] = uint256(3206708589682338778875464217516564639886138074743860970529166723769308693331);
        zeros[8] = uint256(20534426109262125257001376157024458165019301442070720434223770308413031897106);
        zeros[9] = uint256(20045595674714290179477944839500625050021328745176742196691278453734645214461);
        zeros[10] = uint256(1990443879384407462884849355600260727579259402554912319388203567178699099823);
        zeros[11] = uint256(15030670756630149022405255264285307614365927334767433095054187593088567423357);
        zeros[12] = uint256(18151643848963813172699123574112664048044995742942448148573079318091374187889);
        zeros[13] = uint256(12716797128662011430654728594886216826078433472768452754660103993065334317074);
        zeros[14] = uint256(1778668013271642889777963040449750701990462149853502233417669847457236064652);
        zeros[15] = uint256(5310295518327181913512672840814534597220436900477241678956359474542866650820);
        zeros[16] = uint256(13698756698956924170299002904918188137369325655270855940405108330875686641692);
        zeros[17] = uint256(16978698509212058134355374823422776609466830925429320593002017159097039391798);
        zeros[18] = uint256(21122904167710384374017181343962526230952584354459613272526061056824616537143);
        zeros[19] = uint256(5985710021335277534018076016950505662155095700842597825798268278683684529911);
        zeros[20] = uint256(12532916265365969493430834411976825909479396013951866588908395278818546013433);
        zeros[21] = uint256(8930761113974965197874653050290197596753921117163820694764716198465769499045);
        zeros[22] = uint256(7923291528963393397483250836756011061887097780645138922028359275174896145293);
        zeros[23] = uint256(3165523255399386676797999966015195343651238663671903081942130824893771740953);
        zeros[24] = uint256(16498953853801480907823499768835003172991697981391001961022924988055514153444);
        zeros[25] = uint256(4646652977614280202033130495149148518982017582438403557846318228188699893314);
        zeros[26] = uint256(16063634456514132367413661909718374200540548246284043795891576706199387111176);
        zeros[27] = uint256(6432449679436816515158314256021560028822839412197804709124582783531979581762);
        zeros[28] = uint256(16549548229658147491856279832226477385154640474741924661165993652668688816447);
        zeros[29] = uint256(17839947633190642328550610337345984157351952156869520211179465702618934306508);
        zeros[30] = uint256(12740635476725314448365579529753493622477881762096050379151557051600454293132);
        zeros[31] = uint256(14450546044445547667240670175592035046062311068467905405735885913523641104070);
        zeros[32] = uint256(16649881337797029358598450172037019406882299786178038601098631221224645092238);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import {DomainObjs, IPubKey, IMessage} from "../DomainObjs.sol";
import {Hasher} from "../crypto/Hasher.sol";
import {SnarkConstants} from "../crypto/SnarkConstants.sol";
import {Poll} from "../Poll.sol";


contract CommonUtilities {
     error VOTING_PERIOD_NOT_PASSED();
    // common function for MessageProcessor, Tally and Subsidy
    function _votingPeriodOver(Poll _poll) internal view {
        (uint256 deployTime, uint256 duration) = _poll
            .getDeployTimeAndDuration();
        // Require that the voting period is over
        uint256 secondsPassed = block.timestamp - deployTime;
        if (secondsPassed <= duration ) {
            revert VOTING_PERIOD_NOT_PASSED();
        }
    }
}

contract Utilities is SnarkConstants, Hasher, IPubKey, IMessage {
    function padAndHashMessage(
        uint256[2] memory dataToPad, // we only need two for now
        uint256 msgType
    ) public pure returns (Message memory, PubKey memory, uint256) {
        uint256[10] memory dat;
        dat[0] = dataToPad[0];
        dat[1] = dataToPad[1];
        for(uint i = 2; i< 10;) {
            dat[i] = 0;
            unchecked {
                ++i;
            }
        }
        PubKey memory _padKey = PubKey(PAD_PUBKEY_X, PAD_PUBKEY_Y);
        Message memory _message = Message({msgType: msgType, data: dat});
        return (_message, _padKey, hashMessageAndEncPubKey(_message, _padKey));
    }

    function hashMessageAndEncPubKey(
        Message memory _message,
        PubKey memory _encPubKey
    ) public pure returns (uint256) {
        require(_message.data.length == 10, "Invalid message");
        uint256[5] memory n;
        n[0] = _message.data[0];
        n[1] = _message.data[1];
        n[2] = _message.data[2];
        n[3] = _message.data[3];
        n[4] = _message.data[4];

        uint256[5] memory m;
        m[0] = _message.data[5];
        m[1] = _message.data[6];
        m[2] = _message.data[7];
        m[3] = _message.data[8];
        m[4] = _message.data[9];

        return
            hash5(
                [
                    _message.msgType,
                    hash5(n),
                    hash5(m),
                    _encPubKey.x,
                    _encPubKey.y
                ]
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { SnarkCommon } from "./crypto/SnarkCommon.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/*
 * Stores verifying keys for the circuits.
 * Each circuit has a signature which is its compile-time constants represented
 * as a uint256.
 */
contract VkRegistry is Ownable, SnarkCommon {

    mapping (uint256 => VerifyingKey) internal processVks; 
    mapping (uint256 => bool) internal processVkSet; 

    mapping (uint256 => VerifyingKey) internal tallyVks; 
    mapping (uint256 => bool) internal tallyVkSet; 

    mapping (uint256 => VerifyingKey) internal subsidyVks; 
    mapping (uint256 => bool) internal subsidyVkSet; 

    event ProcessVkSet(uint256 _sig);
    event TallyVkSet(uint256 _sig);
    event SubsidyVkSet(uint256 _sig);

    error ProcessVkAlreadySet();
    error TallyVkAlreadySet();
    error SubsidyVkAlreadySet();
    error ProcessVkNotSet();
    error TallyVkNotSet();
    error SubsidyVkNotSet();

    function isProcessVkSet(uint256 _sig) public view returns (bool) {
        return processVkSet[_sig];
    }

    function isTallyVkSet(uint256 _sig) public view returns (bool) {
        return tallyVkSet[_sig];
    }

    function isSubsidyVkSet(uint256 _sig) public view returns (bool) {
        return subsidyVkSet[_sig];
    }

    function genProcessVkSig(
        uint256 _stateTreeDepth,
        uint256 _messageTreeDepth,
        uint256 _voteOptionTreeDepth,
        uint256 _messageBatchSize
    ) public pure returns (uint256) {
        return 
            (_messageBatchSize << 192) +
            (_stateTreeDepth << 128) +
            (_messageTreeDepth << 64) +
            _voteOptionTreeDepth;
    }

    function genTallyVkSig(
        uint256 _stateTreeDepth,
        uint256 _intStateTreeDepth,
        uint256 _voteOptionTreeDepth
    ) public pure returns (uint256) {
        return 
            (_stateTreeDepth << 128) +
            (_intStateTreeDepth << 64) +
            _voteOptionTreeDepth;
    }

    function genSubsidyVkSig(
        uint256 _stateTreeDepth,
        uint256 _intStateTreeDepth,
        uint256 _voteOptionTreeDepth
    ) public pure returns (uint256) {
        return 
            (_stateTreeDepth << 128) +
            (_intStateTreeDepth << 64) +
            _voteOptionTreeDepth;
    }

    function setVerifyingKeys(
        uint256 _stateTreeDepth,
        uint256 _intStateTreeDepth,
        uint256 _messageTreeDepth,
        uint256 _voteOptionTreeDepth,
        uint256 _messageBatchSize,
        VerifyingKey memory _processVk,
        VerifyingKey memory _tallyVk
    ) public onlyOwner {

        uint256 processVkSig = genProcessVkSig(
            _stateTreeDepth,
            _messageTreeDepth,
            _voteOptionTreeDepth,
            _messageBatchSize
        );

        if (processVkSet[processVkSig]) revert ProcessVkAlreadySet();

        uint256 tallyVkSig = genTallyVkSig(
            _stateTreeDepth,
            _intStateTreeDepth,
            _voteOptionTreeDepth
        );

        if (tallyVkSet[tallyVkSig]) revert TallyVkAlreadySet();

        VerifyingKey storage processVk = processVks[processVkSig];
        processVk.alpha1 = _processVk.alpha1;
        processVk.beta2 = _processVk.beta2;
        processVk.gamma2 = _processVk.gamma2;
        processVk.delta2 = _processVk.delta2;
        for (uint8 i = 0; i < _processVk.ic.length; i ++) {
            processVk.ic.push(_processVk.ic[i]);
        }

        processVkSet[processVkSig] = true;

        VerifyingKey storage tallyVk = tallyVks[tallyVkSig];
        tallyVk.alpha1 = _tallyVk.alpha1;
        tallyVk.beta2 = _tallyVk.beta2;
        tallyVk.gamma2 = _tallyVk.gamma2;
        tallyVk.delta2 = _tallyVk.delta2;
        for (uint8 i = 0; i < _tallyVk.ic.length; i ++) {
            tallyVk.ic.push(_tallyVk.ic[i]);
        }
        tallyVkSet[tallyVkSig] = true;

        emit TallyVkSet(tallyVkSig);
        emit ProcessVkSet(processVkSig);
    }

    function setSubsidyKeys(
        uint256 _stateTreeDepth,
        uint256 _intStateTreeDepth,
        uint256 _voteOptionTreeDepth,
        VerifyingKey memory _subsidyVk
    ) public onlyOwner {

        uint256 subsidyVkSig = genSubsidyVkSig(
            _stateTreeDepth,
            _intStateTreeDepth,
            _voteOptionTreeDepth
        );

        if (subsidyVkSet[subsidyVkSig]) revert SubsidyVkAlreadySet();

        VerifyingKey storage subsidyVk = subsidyVks[subsidyVkSig];
        subsidyVk.alpha1 = _subsidyVk.alpha1;
        subsidyVk.beta2 = _subsidyVk.beta2;
        subsidyVk.gamma2 = _subsidyVk.gamma2;
        subsidyVk.delta2 = _subsidyVk.delta2;
        for (uint8 i = 0; i < _subsidyVk.ic.length; i ++) {
            subsidyVk.ic.push(_subsidyVk.ic[i]);
        }
        subsidyVkSet[subsidyVkSig] = true;

        emit SubsidyVkSet(subsidyVkSig);
    }

    function hasProcessVk(
        uint256 _stateTreeDepth,
        uint256 _messageTreeDepth,
        uint256 _voteOptionTreeDepth,
        uint256 _messageBatchSize
    ) public view returns (bool) {
        uint256 sig = genProcessVkSig(
            _stateTreeDepth,
            _messageTreeDepth,
            _voteOptionTreeDepth,
            _messageBatchSize
        );
        return processVkSet[sig];
    }

    function getProcessVkBySig(
        uint256 _sig
    ) public view returns (VerifyingKey memory) {
        if (!processVkSet[_sig]) revert ProcessVkNotSet();

        return processVks[_sig];
    }

    function getProcessVk(
        uint256 _stateTreeDepth,
        uint256 _messageTreeDepth,
        uint256 _voteOptionTreeDepth,
        uint256 _messageBatchSize
    ) public view returns (VerifyingKey memory) {
        uint256 sig = genProcessVkSig(
            _stateTreeDepth,
            _messageTreeDepth,
            _voteOptionTreeDepth,
            _messageBatchSize
        );

        return getProcessVkBySig(sig);
    }

    function hasTallyVk(
        uint256 _stateTreeDepth,
        uint256 _intStateTreeDepth,
        uint256 _voteOptionTreeDepth
    ) public view returns (bool) {
        uint256 sig = genTallyVkSig(
            _stateTreeDepth,
            _intStateTreeDepth,
            _voteOptionTreeDepth
        );

        return tallyVkSet[sig];
    }

    function getTallyVkBySig(
        uint256 _sig
    ) public view returns (VerifyingKey memory) {
        if (!tallyVkSet[_sig]) revert TallyVkNotSet();

        return tallyVks[_sig];
    }

    function getTallyVk(
        uint256 _stateTreeDepth,
        uint256 _intStateTreeDepth,
        uint256 _voteOptionTreeDepth
    ) public view returns (VerifyingKey memory) {
        uint256 sig = genTallyVkSig(
            _stateTreeDepth,
            _intStateTreeDepth,
            _voteOptionTreeDepth
        );

        return getTallyVkBySig(sig);
    }

    function hasSubsidyVk(
        uint256 _stateTreeDepth,
        uint256 _intStateTreeDepth,
        uint256 _voteOptionTreeDepth
    ) public view returns (bool) {
        uint256 sig = genSubsidyVkSig(
            _stateTreeDepth,
            _intStateTreeDepth,
            _voteOptionTreeDepth
        );

        return subsidyVkSet[sig];
    }

    function getSubsidyVkBySig(
        uint256 _sig
    ) public view returns (VerifyingKey memory) {
        if (!subsidyVkSet[_sig]) revert SubsidyVkNotSet();

        return subsidyVks[_sig];
    }

    function getSubsidyVk(
        uint256 _stateTreeDepth,
        uint256 _intStateTreeDepth,
        uint256 _voteOptionTreeDepth
    ) public view returns (VerifyingKey memory) {
        uint256 sig = genSubsidyVkSig(
            _stateTreeDepth,
            _intStateTreeDepth,
            _voteOptionTreeDepth
        );

        return getSubsidyVkBySig(sig);
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