// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0;

import {SignatureValidator} from "../base/SignatureValidator.sol";
import {ISafe} from "../interfaces/ISafe.sol";
import {P256, WebAuthn} from "../libraries/WebAuthn.sol";

/**
 * @title Safe WebAuthn Shared Signer
 * @dev A contract for verifying WebAuthn signatures shared by all Safe accounts. This contract uses
 * storage from the Safe account itself for full ERC-4337 compatibility.
 */
contract SafeWebAuthnSharedSigner is SignatureValidator {
    /**
     * @notice Data associated with a WebAuthn signer. It represents the X and Y coordinates of the
     * signer's public key as well as the P256 verifiers to use. This is stored in account storage
     * starting at the storage slot {SIGNER_SLOT}.
     */
    struct Signer {
        uint256 x;
        uint256 y;
        P256.Verifiers verifiers;
    }

    /**
     * @notice The storage slot of the mapping from shared WebAuthn signer address to signer data.
     * @custom:computed-as keccak256("SafeWebAuthnSharedSigner.signer") - 1
     * @dev This value is intentionally computed to be a hash -1 as a precaution to avoid any
     * potential issues from unintended hash collisions, and have enough space for all the signer
     * fields. Also, this is the slot of a `mapping(address self => Signer)` to ensure that multiple
     * {SafeWebAuthnSharedSigner} instances can coexist with the same account.
     */
    uint256 private constant _SIGNER_MAPPING_SLOT = 0x2e0aed53485dc2290ceb5ce14725558ad3e3a09d38c69042410ad15c2b4ea4e8;

    /**
     * @notice An error indicating a `CALL` to a function that should only be `DELEGATECALL`-ed.
     */
    error NotDelegateCalled();

    /**
     * @notice Address of the shared signer contract itself.
     * @dev This is used for determining whether or not the contract is being `DELEGATECALL`-ed when
     * setting signer data.
     */
    address private immutable _SELF;

    /**
     * @notice The starting storage slot on the account containing the signer data.
     */
    uint256 public immutable SIGNER_SLOT;

    /**
     * @notice Create a new shared WebAuthn signer instance.
     */
    constructor() {
        _SELF = address(this);
        SIGNER_SLOT = uint256(keccak256(abi.encode(address(this), _SIGNER_MAPPING_SLOT)));
    }

    /**
     * @notice Validates the call is done via `DELEGATECALL`.
     */
    modifier onlyDelegateCall() {
        if (address(this) == _SELF) {
            revert NotDelegateCalled();
        }
        _;
    }

    /**
     * @notice Return the signer configuration for the specified account.
     * @dev The calling account must be a Safe, as the signer data is stored in the Safe's storage
     * and must be read with the {StorageAccessible} support from the Safe.
     * @param account The account to request signer data for.
     */
    function getConfiguration(address account) public view returns (Signer memory signer) {
        bytes memory getStorageAtData = abi.encodeCall(ISafe(account).getStorageAt, (SIGNER_SLOT, 3));

        // Call the {StorageAccessible.getStorageAt} with assembly. This allows us to return a
        // zeroed out signer configuration instead of reverting for `account`s that are not Safes.
        // We also, expect the implementation to behave **exactly** like the Safe's - that is it
        // should encode the return data using a standard ABI encoding:
        // - The first 32 bytes is the offset of the values bytes array, always `0x20`
        // - The second 32 bytes is the length of the values bytes array, always `0x60`
        // - the following 3 words (96 bytes) are the values of the signer configuration.

        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            // Note that Yul expressions are evaluated in reverse order, so the `staticcall` is the
            // first thing to be evaluated in the nested `and` expression.
            if and(
                and(
                    // The offset of the ABI encoded bytes is 0x20, this should always be the case
                    // for standard ABI encoding of `(bytes)` tuple that `getStorageAt` returns.
                    eq(mload(0x00), 0x20),
                    // The length of the encoded bytes is exactly 0x60 bytes (i.e. 3 words, which is
                    // exactly how much we read from the Safe's storage in the `getStorageAt` call).
                    eq(mload(0x20), 0x60)
                ),
                and(
                    // The length of the return data should be exactly 0xa0 bytes, which should
                    // always be the case for the Safe's `getStorageAt` implementation.
                    eq(returndatasize(), 0xa0),
                    // The call succeeded. We write the first two words of the return data into the
                    // scratch space, as we need to inspect them before copying the signer
                    // signer configuration to our `signer` memory pointer.
                    staticcall(gas(), account, add(getStorageAtData, 0x20), mload(getStorageAtData), 0x00, 0x40)
                )
            ) {
                // Copy only the storage values from the return data to our `signer` memory address.
                // This only happens on success, so the `signer` value will be zeroed out if any of
                // the above conditions fail, indicating that no signer is configured.
                returndatacopy(signer, 0x40, 0x60)
            }
        }
    }

    /**
     * @notice Sets the signer configuration for the calling account.
     * @dev The Safe must call this function with a `DELEGATECALL`, as the signer data is stored in
     * the Safe account's storage.
     * @param signer The new signer data to set for the calling account.
     */
    function configure(Signer memory signer) external onlyDelegateCall {
        uint256 signerSlot = SIGNER_SLOT;
        Signer storage signerStorage;

        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            signerStorage.slot := signerSlot
        }

        signerStorage.x = signer.x;
        signerStorage.y = signer.y;
        signerStorage.verifiers = signer.verifiers;
    }

    /**
     * @inheritdoc SignatureValidator
     */
    function _verifySignature(bytes32 message, bytes calldata signature) internal view virtual override returns (bool isValid) {
        Signer memory signer = getConfiguration(msg.sender);

        // Make sure that the signer is configured in the first place.
        if (P256.Verifiers.unwrap(signer.verifiers) == 0) {
            return false;
        }

        isValid = WebAuthn.verifySignature(message, signature, WebAuthn.USER_VERIFICATION, signer.x, signer.y, signer.verifiers);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC1271} from "../libraries/ERC1271.sol";

/**
 * @title Signature Validator Base Contract
 * @dev A interface for smart contract Safe owners that supports multiple ERC-1271 `isValidSignature` versions.
 * @custom:security-contact [email protected]
 */
abstract contract SignatureValidator {
    /**
     * @dev Validates the signature for the given data.
     * @param data The signed data bytes.
     * @param signature The signature to be validated.
     * @return magicValue The magic value indicating the validity of the signature.
     */
    function isValidSignature(bytes memory data, bytes calldata signature) external view returns (bytes4 magicValue) {
        if (_verifySignature(keccak256(data), signature)) {
            magicValue = ERC1271.LEGACY_MAGIC_VALUE;
        }
    }

    /**
     * @dev Validates the signature for a given data hash.
     * @param message The signed message.
     * @param signature The signature to be validated.
     * @return magicValue The magic value indicating the validity of the signature.
     */
    function isValidSignature(bytes32 message, bytes calldata signature) external view returns (bytes4 magicValue) {
        if (_verifySignature(message, signature)) {
            magicValue = ERC1271.MAGIC_VALUE;
        }
    }

    /**
     * @dev Verifies a signature.
     * @param message The signed message.
     * @param signature The signature to be validated.
     * @return success Whether the signature is valid.
     */
    function _verifySignature(bytes32 message, bytes calldata signature) internal view virtual returns (bool success);
}

// SPDX-License-Identifier: LGPL-3.0-only
/* solhint-disable payable-fallback */
pragma solidity ^0.8.0;

/**
 * @title P-256 Elliptic Curve Verifier.
 * @dev P-256 verifier contract that follows the EIP-7212 EC verify precompile interface. For more
 * details, refer to the EIP-7212 specification: <https://eips.ethereum.org/EIPS/eip-7212>
 * @custom:security-contact [email protected]
 */
interface IP256Verifier {
    /**
     * @notice  A fallback function that takes the following input format and returns a result
     * indicating whether the signature is valid or not:
     * - `input[  0: 32]`: message
     * - `input[ 32: 64]`: signature r
     * - `input[ 64: 96]`: signature s
     * - `input[ 96:128]`: public key x
     * - `input[128:160]`: public key y
     *
     * The output is either:
     * - `abi.encode(1)` bytes for a valid signature.
     * - `""` empty bytes for an invalid signature or error.
     *
     * Note that this function does not follow the Solidity ABI format (in particular, it does not
     * have a 4-byte selector), which is why it requires a fallback function and not regular
     * Solidity function. Additionally, it has `view` function semantics, and is expected to be
     * called with `STATICCALL` opcode.
     *
     * @param input The encoded input parameters.
     * @return output The encoded signature verification result.
     */
    fallback(bytes calldata input) external returns (bytes memory output);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title Safe Smart Account
 * @dev Minimal interface of a Safe smart account. This only includes functions that are used by
 * this project.
 * @custom:security-contact [email protected]
 */
interface ISafe {
    /**
     * @notice Sets an initial storage of the Safe contract.
     * @dev This method can only be called once. If a proxy was created without setting up, anyone
     * can call setup and claim the proxy.
     * @param owners List of Safe owners.
     * @param threshold Number of required confirmations for a Safe transaction.
     * @param to Contract address for optional delegate call.
     * @param data Data payload for optional delegate call.
     * @param fallbackHandler Handler for fallback calls to this contract
     * @param paymentToken Token that should be used for the payment (0 is ETH)
     * @param payment Value that should be paid
     * @param paymentReceiver Address that should receive the payment (or 0 if tx.origin)
     */
    function setup(
        address[] calldata owners,
        uint256 threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external;

    /**
     * @notice Reads `length` bytes of storage in the currents contract
     * @param offset - the offset in the current contract's storage in words to start reading from
     * @param length - the number of words (32 bytes) of data to read
     * @return the bytes that were read.
     */
    function getStorageAt(uint256 offset, uint256 length) external view returns (bytes memory);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title ERC-1271 Magic Values
 * @dev Library that defines constants for ERC-1271 related magic values.
 * @custom:security-contact [email protected]
 */
library ERC1271 {
    /**
     * @notice ERC-1271 magic value returned on valid signatures.
     * @dev Value is derived from `bytes4(keccak256("isValidSignature(bytes32,bytes)")`.
     */
    bytes4 internal constant MAGIC_VALUE = 0x1626ba7e;

    /**
     * @notice Legacy EIP-1271 magic value returned on valid signatures.
     * @dev This value was used in previous drafts of the EIP-1271 standard, but replaced by
     * {MAGIC_VALUE} in the final version.
     *
     * Value is derived from `bytes4(keccak256("isValidSignature(bytes,bytes)")`.
     */
    bytes4 internal constant LEGACY_MAGIC_VALUE = 0x20c13b0b;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import {IP256Verifier} from "../interfaces/IP256Verifier.sol";

/**
 * @title P-256 Elliptic Curve Verification Library.
 * @dev Library P-256 verification with contracts that follows the EIP-7212 EC verify precompile
 * interface. See <https://eips.ethereum.org/EIPS/eip-7212>.
 * @custom:security-contact [email protected]
 */
library P256 {
    /**
     * @notice P-256 curve order n divided by 2 for the signature malleability check.
     * @dev By convention, non-malleable signatures must have an `s` value that is less than half of
     * the curve order.
     */
    uint256 internal constant _N_DIV_2 = 57896044605178124381348723474703786764998477612067880171211129530534256022184;

    /**
     * @notice P-256 precompile and fallback verifiers.
     * @dev This is the packed `uint16(precompile) | uint160(fallback)` addresses to use for the
     * verifiers. This allows both a precompile and a fallback Solidity implementation of the P-256
     * curve to be specified. For networks where the P-256 precompile is planned to be enabled but
     * not yet available, this allows for a verifier to seamlessly start using the precompile once
     * it becomes available.
     */
    type Verifiers is uint176;

    /**
     * @notice Verifies the signature of a message using the P256 elliptic curve with signature
     * malleability check.
     * @dev Note that a signature is valid for both `+s` and `-s`, making it trivial to, given a
     * signature, generate another valid signature by flipping the sign of the `s` value in the
     * prime field defined by the P-256 curve order `n`. This signature verification method checks
     * that `1 <= s <= n/2` to prevent malleability, such that there is a unique `s` value that is
     * accepted for a given signature. Note that for many protocols, signature malleability is not
     * an issue, so the use of {verifySignatureAllowMalleability} as long as only that the signature
     * is valid is important, and not its actual value.
     * @param verifier The P-256 verifier.
     * @param message The signed message.
     * @param r The r component of the signature.
     * @param s The s component of the signature.
     * @param x The x coordinate of the public key.
     * @param y The y coordinate of the public key.
     * @return success A boolean indicating whether the signature is valid or not.
     */
    function verifySignature(
        IP256Verifier verifier,
        bytes32 message,
        uint256 r,
        uint256 s,
        uint256 x,
        uint256 y
    ) internal view returns (bool success) {
        if (s > _N_DIV_2) {
            return false;
        }

        success = verifySignatureAllowMalleability(verifier, message, r, s, x, y);
    }

    /**
     * @notice Verifies the signature of a message using the P256 elliptic curve with signature
     * malleability check.
     * @param verifiers The P-256 verifiers to use.
     * @param message The signed message.
     * @param r The r component of the signature.
     * @param s The s component of the signature.
     * @param x The x coordinate of the public key.
     * @param y The y coordinate of the public key.
     * @return success A boolean indicating whether the signature is valid or not.
     */
    function verifySignature(
        Verifiers verifiers,
        bytes32 message,
        uint256 r,
        uint256 s,
        uint256 x,
        uint256 y
    ) internal view returns (bool success) {
        if (s > _N_DIV_2) {
            return false;
        }

        success = verifySignatureAllowMalleability(verifiers, message, r, s, x, y);
    }

    /**
     * @notice Verifies the signature of a message using P256 elliptic curve, without signature
     * malleability check.
     * @param verifier The P-256 verifier.
     * @param message The signed message.
     * @param r The r component of the signature.
     * @param s The s component of the signature.
     * @param x The x coordinate of the public key.
     * @param y The y coordinate of the public key.
     * @return success A boolean indicating whether the signature is valid or not.
     */
    function verifySignatureAllowMalleability(
        IP256Verifier verifier,
        bytes32 message,
        uint256 r,
        uint256 s,
        uint256 x,
        uint256 y
    ) internal view returns (bool success) {
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            // Prepare input for staticcall
            let input := mload(0x40) // Free memory pointer
            mstore(input, message)
            mstore(add(input, 32), r)
            mstore(add(input, 64), s)
            mstore(add(input, 96), x)
            mstore(add(input, 128), y)

            // Perform staticcall and check result, note that Yul evaluates expressions from right
            // to left. See <https://docs.soliditylang.org/en/v0.8.24/yul.html#function-calls>.
            mstore(0, 0)
            success := and(
                and(
                    // Return data is exactly 32-bytes long
                    eq(returndatasize(), 32),
                    // Return data is exactly the value 0x00..01
                    eq(mload(0), 1)
                ),
                // Call does not revert
                staticcall(gas(), verifier, input, 160, 0, 32)
            )
        }
    }

    /**
     * @notice Verifies the signature of a message using P256 elliptic curve, without signature
     * malleability check.
     * @param verifiers The P-256 verifiers to use.
     * @param message The signed message.
     * @param r The r component of the signature.
     * @param s The s component of the signature.
     * @param x The x coordinate of the public key.
     * @param y The y coordinate of the public key.
     * @return success A boolean indicating whether the signature is valid or not.
     */
    function verifySignatureAllowMalleability(
        Verifiers verifiers,
        bytes32 message,
        uint256 r,
        uint256 s,
        uint256 x,
        uint256 y
    ) internal view returns (bool success) {
        address precompileVerifier = address(uint160(uint256(Verifiers.unwrap(verifiers)) >> 160));
        address fallbackVerifier = address(uint160(Verifiers.unwrap(verifiers)));
        if (precompileVerifier != address(0)) {
            success = verifySignatureAllowMalleability(IP256Verifier(precompileVerifier), message, r, s, x, y);
        }

        // If the precompile verification was not successful, fallback to a configured Solidity {IP256Verifier}
        // implementation. Note that this means that invalid signatures are potentially checked twice, once with the
        // precompile and once with the fallback verifier. This is intentional as there is no reliable way to
        // distinguish between the precompile being unavailable and the signature being invalid, as in both cases the
        // `STATICCALL` to the precompile contract will return empty bytes.
        if (!success && fallbackVerifier != address(0)) {
            success = verifySignatureAllowMalleability(IP256Verifier(fallbackVerifier), message, r, s, x, y);
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import {P256} from "./P256.sol";

/**
 * @title WebAuthn Signature Verification
 * @dev Library for verifying WebAuthn signatures for public key credentials using the ES256
 * algorithm with the P-256 curve.
 * @custom:security-contact [email protected]
 */
library WebAuthn {
    using P256 for P256.Verifiers;

    /**
     * @notice The WebAuthn signature data format.
     * @dev WebAuthn signatures are expected to be the ABI-encoded bytes of the following structure.
     * @param authenticatorData The authenticator data from the WebAuthn credential assertion.
     * @param clientDataFields The additional fields from the client data JSON. This is the comma
     * separated fields as they appear in the client data JSON from the WebAuthn credential
     * assertion after the leading {type} and {challenge} fields.
     * @param r The ECDSA signature's R component.
     * @param s The ECDSA signature's S component.
     */
    struct Signature {
        bytes authenticatorData;
        string clientDataFields;
        uint256 r;
        uint256 s;
    }

    /**
     * @notice A WebAuthn authenticator bit-flags
     * @dev Represents flags that are included in a WebAuthn assertion's authenticator data and can
     * be used to check on-chain how the user was authorized by the device when signing.
     */
    type AuthenticatorFlags is bytes1;

    /**
     * @notice Authenticator data flag indicating user presence (UP).
     * @dev A test of user presence is a simple form of authorization gesture and technical process
     * where a user interacts with an authenticator by (typically) simply touching it (other
     * modalities may also exist), yielding a Boolean result. Note that this does not constitute
     * user verification because a user presence test, by definition, is not capable of biometric
     * recognition, nor does it involve the presentation of a shared secret such as a password or
     * PIN.
     *
     * See <https://www.w3.org/TR/webauthn-2/#test-of-user-presence>.
     */
    AuthenticatorFlags internal constant USER_PRESENCE = AuthenticatorFlags.wrap(0x01);

    /**
     * @notice Authenticator data flag indicating user verification (UV).
     * @dev The technical process by which an authenticator locally authorizes the invocation of the
     * authenticatorMakeCredential and authenticatorGetAssertion operations. User verification MAY
     * be instigated through various authorization gesture modalities; for example, through a touch
     * plus pin code, password entry, or biometric recognition (e.g., presenting a fingerprint). The
     * intent is to distinguish individual users.
     *
     * Note that user verification does not give the Relying Party a concrete identification of the
     * user, but when 2 or more ceremonies with user verification have been done with that
     * credential it expresses that it was the same user that performed all of them. The same user
     * might not always be the same natural person, however, if multiple natural persons share
     * access to the same authenticator.
     *
     * See <https://www.w3.org/TR/webauthn-2/#user-verification>.
     */
    AuthenticatorFlags internal constant USER_VERIFICATION = AuthenticatorFlags.wrap(0x04);

    /**
     * @notice Casts calldata bytes to a WebAuthn signature data structure.
     * @param signature The calldata bytes of the WebAuthn signature.
     * @return isValid Whether or not the encoded signature bytes is valid.
     * @return data A pointer to the signature data in calldata.
     * @dev This method casts the dynamic bytes array to a signature calldata pointer with some
     * additional verification. Specifically, we ensure that the signature bytes encoding is no
     * larger than standard ABI encoding form, to prevent attacks where valid signatures are padded
     * with 0s in order to increase signature verifications the costs for ERC-4337 user operations.
     */
    function castSignature(bytes calldata signature) internal pure returns (bool isValid, Signature calldata data) {
        uint256 authenticatorDataLength;
        uint256 clientDataFieldsLength;

        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            data := signature.offset

            // Read the lengths of the dynamic byte arrays in assembly. This is done because
            // Solidity generates calldata bounds checks which aren't required for the security of
            // the signature verification, as it can only lead to _shorter_ signatures which are
            // are less gas expensive anyway.
            authenticatorDataLength := calldataload(add(data, calldataload(data)))
            clientDataFieldsLength := calldataload(add(data, calldataload(add(data, 0x20))))
        }

        // Use of unchecked math as any overflows in dynamic length computations would cause
        // out-of-gas reverts when computing the WebAuthn signing message.
        unchecked {
            // Allow for signature encodings where the dynamic bytes are aligned to 32-byte
            // boundaries. This allows for high interoperability (as this is how Solidity and most
            // tools `abi.encode`s the `Signature` struct) while setting a strict upper bound to how
            // many additional padding bytes can be added to the signature, increasing gas costs.
            // Note that we compute the aligned lengths with the formula: `l + 0x1f & ~0x1f`, which
            // rounds `l` up to the next 32-byte boundary.
            uint256 alignmentMask = ~uint256(0x1f);
            uint256 authenticatorDataAlignedLength = (authenticatorDataLength + 0x1f) & alignmentMask;
            uint256 clientDataFieldsAlignedLength = (clientDataFieldsLength + 0x1f) & alignmentMask;

            // The fixed parts of the signature length are 6 32-byte words for a total of 192 bytes:
            // - offset of the `authenticatorData` bytes
            // - offset of the `clientDataFields` string
            // - signature `r` value
            // - signature `s` value
            // - length of the `authenticatorData` bytes
            // - length of the `clientDataFields` string
            //
            // This implies that the signature length must be less than or equal to:
            //      192 + authenticatorDataAlignedLength + clientDataFieldsAlignedLength
            // which is equivalent to strictly less than:
            //      193 + authenticatorDataAlignedLength + clientDataFieldsAlignedLength
            isValid = signature.length < 193 + authenticatorDataAlignedLength + clientDataFieldsAlignedLength;
        }
    }

    /**
     * @notice Encodes the client data JSON string from the specified challenge, and additional
     * client data fields.
     * @dev The client data JSON follows a very specific encoding process outlined in the Web
     * Authentication standard. See <https://w3c.github.io/webauthn/#clientdatajson-serialization>.
     * @param challenge The WebAuthn challenge used for the credential assertion.
     * @param clientDataFields Client data fields.
     * @return clientDataJson The encoded client data JSON.
     */
    function encodeClientDataJson(
        bytes32 challenge,
        string calldata clientDataFields
    ) internal pure returns (string memory clientDataJson) {
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            // The length of the encoded JSON string. This is always 82 plus the length of the
            // additional client data fields:
            // - 36 bytes for: `{"type":"webauthn.get","challenge":"`
            // - 43 bytes for base-64 encoding of 32 bytes of data
            // - 2 bytes for: `",`
            // - `clientDataFields.length` bytes for the additional client data JSON fields
            // - 1 byte for: `}`
            let encodedLength := add(82, clientDataFields.length)

            // Set `clientDataJson` return parameter to point to the start of the free memory.
            // This is where the encoded JSON will be stored.
            clientDataJson := mload(0x40)

            // Write the constant bytes of the encoded client data JSON string as per the JSON
            // serialization specification. Note that we write the data backwards, this is to avoid
            // overwriting previously written data with zeros. Offsets are computed to account for
            // both the leading 32-byte length and leading zeros from the constants.
            mstore(add(clientDataJson, encodedLength), 0x7d) // }
            mstore(add(clientDataJson, 81), 0x222c) // ",
            mstore(add(clientDataJson, 36), 0x2c226368616c6c656e6765223a22) // ,"challenge":"
            mstore(add(clientDataJson, 22), 0x7b2274797065223a22776562617574686e2e67657422) // {"type":"webauthn.get"
            mstore(clientDataJson, encodedLength)

            // Copy the client data fields from calldata to their reserved space in memory.
            calldatacopy(add(clientDataJson, 113), clientDataFields.offset, clientDataFields.length)

            // Store the base-64 URL character lookup table into the scratch and free memory pointer
            // space in memory [^1]. The table is split into two 32-byte parts and stored in memory
            // from address 0x1f to 0x5e. Note that the offset is chosen in such a way that the
            // least significant byte of `mload(x)` is the base-64 ASCII character for the 6-bit
            // value `x`. We will write the free memory pointer at address `0x40` before leaving the
            // assembly block accounting for the allocation of `clientDataJson`.
            //
            // - [^1](https://docs.soliditylang.org/en/stable/internals/layout_in_memory.html).
            mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
            mstore(0x3f, "ghijklmnopqrstuvwxyz0123456789-_")

            // Initialize a pointer for writing the base-64 encoded challenge.
            let ptr := add(clientDataJson, 68)

            // Base-64 encode the challenge to its reserved space in memory.
            //
            // To minimize stack and jump operations, we partially unroll the loop. With full 6
            // iterations of the loop, we need to encode seven 6-bit groups and one 4-bit group. In
            // total, it encodes 6 iterations * 7 groups * 6 bits = 252 bits. The remaining 4-bit
            // group is encoded after the loop. `i` is initialized to 250, which is the number of
            // bits by which we need to shift the data to get the first 6-bit group, and then we
            // subtract 6 to get the next 6-bit group.
            //
            // We want to exit when all full 6 bits groups are encoded. After 6 iterations, `i` will
            // be -2 and the **signed** comparison with 0 will break the loop.
            for {
                let i := 250
            } sgt(i, 0) {
                // Advance the pointer by the number of bytes written (7 bytes in this case).
                ptr := add(ptr, 7)
                // Move `i` by 42 = 6 bits * 7 (groups processed in each iteration).
                i := sub(i, 42)
            } {
                // Encode 6-bit groups into characters by looking them up in the character table.
                // 0x3f is a mask to get the last 6 bits so that we can index directly to the
                // base-64 lookup table.
                mstore8(ptr, mload(and(shr(i, challenge), 0x3f)))
                mstore8(add(ptr, 1), mload(and(shr(sub(i, 6), challenge), 0x3f)))
                mstore8(add(ptr, 2), mload(and(shr(sub(i, 12), challenge), 0x3f)))
                mstore8(add(ptr, 3), mload(and(shr(sub(i, 18), challenge), 0x3f)))
                mstore8(add(ptr, 4), mload(and(shr(sub(i, 24), challenge), 0x3f)))
                mstore8(add(ptr, 5), mload(and(shr(sub(i, 30), challenge), 0x3f)))
                mstore8(add(ptr, 6), mload(and(shr(sub(i, 36), challenge), 0x3f)))
            }

            // Encode the final 4-bit group, where 0x0f is a mask to get the last 4 bits.
            mstore8(ptr, mload(shl(2, and(challenge, 0x0f))))

            // Update the free memory pointer to point to the end of the encoded string.
            // Store the length of the encoded string at the beginning of `result`.
            mstore(0x40, and(add(clientDataJson, add(encodedLength, 0x3f)), not(0x1f)))
        }
    }

    /**
     * @notice Encodes the message that is signed in a WebAuthn assertion.
     * @dev The signing message is defined to be the concatenation of the authenticator data bytes
     * with the 32-byte SHA-256 digest of the client data JSON. The hashing algorithm used on the
     * signing message itself depends on the public key algorithm that was selected on WebAuthn
     * credential creation.
     * @param challenge The WebAuthn challenge used for the credential assertion.
     * @param authenticatorData Authenticator data.
     * @param clientDataFields Client data fields.
     * @return message Signing message bytes.
     */
    function encodeSigningMessage(
        bytes32 challenge,
        bytes calldata authenticatorData,
        string calldata clientDataFields
    ) internal view returns (bytes memory message) {
        string memory clientDataJson = encodeClientDataJson(challenge, clientDataFields);
        bytes32 clientDataHash = _sha256(bytes(clientDataJson));

        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            // The length of the signing message, this is the length of the authenticator data plus
            // the 32-byte hash of the client data JSON.
            let messageLength := add(authenticatorData.length, 32)

            // Allocate the encoded signing `message` at the start of the free memory. Note that we
            // pad the allocation to 32-byte boundary as Solidity typically does.
            message := mload(0x40)
            mstore(0x40, and(add(message, add(messageLength, 0x3f)), not(0x1f)))
            mstore(message, messageLength)

            // The actual message data is written to 32 bytes past the start of the allocation, as
            // the first 32 bytes contains the length of the byte array.
            let messagePtr := add(message, 32)

            // Copy the authenticator from calldata to the start of the `message` buffer that was
            // allocated. Note that we start copying 32 bytes after the start of the allocation to
            // account for the length.
            calldatacopy(messagePtr, authenticatorData.offset, authenticatorData.length)

            // Finally, write the client data JSON hash to the end of the `message`.
            mstore(add(messagePtr, authenticatorData.length), clientDataHash)
        }
    }

    /**
     * @notice Checks that the required authenticator data flags are set.
     * @param authenticatorData The authenticator data.
     * @param authenticatorFlags The authenticator flags to check for.
     * @return success Whether the authenticator data flags are set.
     */
    function checkAuthenticatorFlags(
        bytes calldata authenticatorData,
        AuthenticatorFlags authenticatorFlags
    ) internal pure returns (bool success) {
        success = authenticatorData[32] & AuthenticatorFlags.unwrap(authenticatorFlags) == AuthenticatorFlags.unwrap(authenticatorFlags);
    }

    /**
     * @notice Verifies a WebAuthn signature.
     * @param challenge The WebAuthn challenge used in the credential assertion.
     * @param signature The encoded WebAuthn signature bytes.
     * @param authenticatorFlags The authenticator data flags that must be set.
     * @param x The x-coordinate of the credential's public key.
     * @param y The y-coordinate of the credential's public key.
     * @param verifiers The P-256 verifier configuration to use.
     * @return success Whether the signature is valid.
     */
    function verifySignature(
        bytes32 challenge,
        bytes calldata signature,
        AuthenticatorFlags authenticatorFlags,
        uint256 x,
        uint256 y,
        P256.Verifiers verifiers
    ) internal view returns (bool success) {
        Signature calldata signatureStruct;
        (success, signatureStruct) = castSignature(signature);
        if (success) {
            success = verifySignature(challenge, signatureStruct, authenticatorFlags, x, y, verifiers);
        }
    }

    /**
     * @notice Verifies a WebAuthn signature.
     * @param challenge The WebAuthn challenge used in the credential assertion.
     * @param signature The WebAuthn signature data.
     * @param authenticatorFlags The authenticator data flags that must be set.
     * @param x The x-coordinate of the credential's public key.
     * @param y The y-coordinate of the credential's public key.
     * @param verifiers The P-256 verifier configuration to use.
     * @return success Whether the signature is valid.
     */
    function verifySignature(
        bytes32 challenge,
        Signature calldata signature,
        AuthenticatorFlags authenticatorFlags,
        uint256 x,
        uint256 y,
        P256.Verifiers verifiers
    ) internal view returns (bool success) {
        // The order of operations here is slightly counter-intuitive (in particular, you do not
        // need to encode the signing message if the expected authenticator flags are missing).
        // However, ordering things this way helps the Solidity compiler generate meaningfully more
        // optimal code for the "happy path" when Yul optimizations are turned on.
        bytes memory message = encodeSigningMessage(challenge, signature.authenticatorData, signature.clientDataFields);
        if (checkAuthenticatorFlags(signature.authenticatorData, authenticatorFlags)) {
            success = verifiers.verifySignatureAllowMalleability(_sha256(message), signature.r, signature.s, x, y);
        }
    }

    /**
     * @notice Compute the SHA-256 hash of the input bytes.
     * @dev The Solidity compiler sometimes generates a memory copy loop for the call to the SHA-256
     * precompile, even if the input is already in memory. Force this not to happen by manually
     * implementing the call to the SHA-256 precompile.
     * @param input The input bytes to hash.
     * @return digest The SHA-256 digest of the input bytes.
     */
    function _sha256(bytes memory input) private view returns (bytes32 digest) {
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            // The SHA-256 precompile is at address 0x0002. Note that we don't check the whether or
            // not the precompile reverted or if the return data size is 32 bytes, which is a
            // reasonable assumption for the precompile, as it is specified to always return the
            // SHA-256 of its input bytes.
            pop(staticcall(gas(), 0x0002, add(input, 0x20), mload(input), 0, 32))
            digest := mload(0)
        }
    }
}