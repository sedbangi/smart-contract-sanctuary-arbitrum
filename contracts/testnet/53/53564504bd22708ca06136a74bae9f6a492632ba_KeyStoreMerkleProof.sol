pragma solidity ^0.8.17;

import {IMerkleRoot} from "./interfaces/IMerkleRoot.sol";
import {IKeyStoreProof} from "../../keystore/interfaces/IKeyStoreProof.sol";

contract KeyStoreMerkleProof is IKeyStoreProof {
    mapping(bytes32 => bytes32) public l1SlotToSigningKey;
    mapping(bytes32 => bytes) public l1SlotToRawOwners;
    mapping(bytes32 => uint256) public lastProofBlock;

    address public immutable MERKLE_ROOT_HISTORY;

    event L1KeyStoreProved(bytes32 l1Slot, bytes32 signingKey);

    constructor(address _merkleRootHistory) {
        MERKLE_ROOT_HISTORY = _merkleRootHistory;
    }

    function proveKeyStoreData(
        bytes32 l1Slot,
        bytes32 merkleRoot,
        bytes32 newSigningKey,
        bytes memory rawOwners,
        uint256 blockNumber,
        uint256 index,
        bytes32[] memory proof
    ) external {
        require(newSigningKey == keccak256(rawOwners), "invalid raw owner data");
        require(IMerkleRoot(MERKLE_ROOT_HISTORY).isKnownRoot(merkleRoot), "unkown merkle root");
        uint256 lastProofBlockNumber = lastProofBlock[l1Slot];
        require(blockNumber > lastProofBlockNumber, "block too old");
        require(proof.length == 32, "invalid proof length");
        bytes32 leaf = keccak256(abi.encodePacked(l1Slot, newSigningKey, blockNumber));
        require(verify(proof, merkleRoot, leaf, index), "invalid proof");
        l1SlotToSigningKey[l1Slot] = newSigningKey;
        lastProofBlock[l1Slot] = blockNumber;
        l1SlotToRawOwners[l1Slot] = rawOwners;
        emit L1KeyStoreProved(l1Slot, newSigningKey);
    }

    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf, uint256 index) public pure returns (bool) {
        bytes32 hash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if ((index & 1) == 1) {
                hash = keccak256(abi.encodePacked(proofElement, hash));
            } else {
                hash = keccak256(abi.encodePacked(hash, proofElement));
            }

            index = index / 2;
        }
        return hash == root;
    }

    function keyStoreBySlot(bytes32 l1Slot) external view returns (bytes32 signingKey) {
        return (l1SlotToSigningKey[l1Slot]);
    }

    function rawOwnersBySlot(bytes32 l1Slot) external view override returns (bytes memory owners) {
        return l1SlotToRawOwners[l1Slot];
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

interface IMerkleRoot {
    function isKnownRoot(bytes32 _root) external view returns (bool);

    event L1MerkleRootSynced(bytes32 indexed _root);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

/**
 * @title Key Store Proof Interface
 * @dev This interface provides methods to retrieve the keystore signing key hash and raw owners based on a slot.
 */
interface IKeyStoreProof {
    /**
     * @dev Returns the signing key hash associated with a given L1 slot.
     * @param l1Slot The L1 slot
     * @return signingKeyHash The hash of the signing key associated with the L1 slot
     */
    function keyStoreBySlot(bytes32 l1Slot) external view returns (bytes32 signingKeyHash);

    /**
     * @dev Returns the raw owners associated with a given L1 slot.
     * @param l1Slot The L1 slot
     * @return owners The raw owner data associated with the L1 slot
     */
    function rawOwnersBySlot(bytes32 l1Slot) external view returns (bytes memory owners);
}