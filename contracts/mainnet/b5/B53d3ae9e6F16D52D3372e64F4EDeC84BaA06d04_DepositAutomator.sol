// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IStargateReceiver {
    function sgReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma abicoder v2;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../../interfaces/IERC173.sol';

interface IOwnable is IERC173 {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from '../../interfaces/IERC173Internal.sol';

interface IOwnableInternal is IERC173Internal {
    error Ownable__NotOwner();
    error Ownable__NotTransitiveOwner();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IOwnable } from './IOwnable.sol';

interface ISafeOwnable is IOwnable {
    /**
     * @notice get the nominated owner who has permission to call acceptOwnership
     */
    function nomineeOwner() external view returns (address);

    /**
     * @notice accept transfer of contract ownership
     */
    function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IOwnableInternal } from './IOwnableInternal.sol';

interface ISafeOwnableInternal is IOwnableInternal {
    error SafeOwnable__NotNomineeOwner();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../../interfaces/IERC173.sol';
import { IOwnable } from './IOwnable.sol';
import { OwnableInternal } from './OwnableInternal.sol';

/**
 * @title Ownership access control based on ERC173
 */
abstract contract Ownable is IOwnable, OwnableInternal {
    /**
     * @inheritdoc IERC173
     */
    function owner() public view virtual returns (address) {
        return _owner();
    }

    /**
     * @inheritdoc IERC173
     */
    function transferOwnership(address account) public virtual onlyOwner {
        _transferOwnership(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../../interfaces/IERC173.sol';
import { AddressUtils } from '../../utils/AddressUtils.sol';
import { IOwnableInternal } from './IOwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

abstract contract OwnableInternal is IOwnableInternal {
    using AddressUtils for address;

    modifier onlyOwner() {
        if (msg.sender != _owner()) revert Ownable__NotOwner();
        _;
    }

    modifier onlyTransitiveOwner() {
        if (msg.sender != _transitiveOwner())
            revert Ownable__NotTransitiveOwner();
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transitiveOwner() internal view virtual returns (address owner) {
        owner = _owner();

        while (owner.isContract()) {
            try IERC173(owner).owner() returns (address transitiveOwner) {
                owner = transitiveOwner;
            } catch {
                break;
            }
        }
    }

    function _transferOwnership(address account) internal virtual {
        _setOwner(account);
    }

    function _setOwner(address account) internal virtual {
        OwnableStorage.Layout storage l = OwnableStorage.layout();
        emit OwnershipTransferred(l.owner, account);
        l.owner = account;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Ownable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { Ownable } from './Ownable.sol';
import { ISafeOwnable } from './ISafeOwnable.sol';
import { OwnableInternal } from './OwnableInternal.sol';
import { SafeOwnableInternal } from './SafeOwnableInternal.sol';

/**
 * @title Ownership access control based on ERC173 with ownership transfer safety check
 */
abstract contract SafeOwnable is ISafeOwnable, Ownable, SafeOwnableInternal {
    /**
     * @inheritdoc ISafeOwnable
     */
    function nomineeOwner() public view virtual returns (address) {
        return _nomineeOwner();
    }

    /**
     * @inheritdoc ISafeOwnable
     */
    function acceptOwnership() public virtual onlyNomineeOwner {
        _acceptOwnership();
    }

    function _transferOwnership(
        address account
    ) internal virtual override(OwnableInternal, SafeOwnableInternal) {
        super._transferOwnership(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ISafeOwnableInternal } from './ISafeOwnableInternal.sol';
import { OwnableInternal } from './OwnableInternal.sol';
import { SafeOwnableStorage } from './SafeOwnableStorage.sol';

abstract contract SafeOwnableInternal is ISafeOwnableInternal, OwnableInternal {
    modifier onlyNomineeOwner() {
        if (msg.sender != _nomineeOwner())
            revert SafeOwnable__NotNomineeOwner();
        _;
    }

    /**
     * @notice get the nominated owner who has permission to call acceptOwnership
     */
    function _nomineeOwner() internal view virtual returns (address) {
        return SafeOwnableStorage.layout().nomineeOwner;
    }

    /**
     * @notice accept transfer of contract ownership
     */
    function _acceptOwnership() internal virtual {
        _setOwner(msg.sender);
        delete SafeOwnableStorage.layout().nomineeOwner;
    }

    /**
     * @notice set nominee owner, granting permission to call acceptOwnership
     */
    function _transferOwnership(address account) internal virtual override {
        SafeOwnableStorage.layout().nomineeOwner = account;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library SafeOwnableStorage {
    struct Layout {
        address nomineeOwner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.SafeOwnable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Map implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableMap {
    error EnumerableMap__IndexOutOfBounds();
    error EnumerableMap__NonExistentKey();

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        MapEntry[] _entries;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct AddressToAddressMap {
        Map _inner;
    }

    struct UintToAddressMap {
        Map _inner;
    }

    function at(
        AddressToAddressMap storage map,
        uint256 index
    ) internal view returns (address, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);

        return (
            address(uint160(uint256(key))),
            address(uint160(uint256(value)))
        );
    }

    function at(
        UintToAddressMap storage map,
        uint256 index
    ) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    function contains(
        AddressToAddressMap storage map,
        address key
    ) internal view returns (bool) {
        return _contains(map._inner, bytes32(uint256(uint160(key))));
    }

    function contains(
        UintToAddressMap storage map,
        uint256 key
    ) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    function length(
        AddressToAddressMap storage map
    ) internal view returns (uint256) {
        return _length(map._inner);
    }

    function length(
        UintToAddressMap storage map
    ) internal view returns (uint256) {
        return _length(map._inner);
    }

    function get(
        AddressToAddressMap storage map,
        address key
    ) internal view returns (address) {
        return
            address(
                uint160(
                    uint256(_get(map._inner, bytes32(uint256(uint160(key)))))
                )
            );
    }

    function get(
        UintToAddressMap storage map,
        uint256 key
    ) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    function set(
        AddressToAddressMap storage map,
        address key,
        address value
    ) internal returns (bool) {
        return
            _set(
                map._inner,
                bytes32(uint256(uint160(key))),
                bytes32(uint256(uint160(value)))
            );
    }

    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    function remove(
        AddressToAddressMap storage map,
        address key
    ) internal returns (bool) {
        return _remove(map._inner, bytes32(uint256(uint160(key))));
    }

    function remove(
        UintToAddressMap storage map,
        uint256 key
    ) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    function toArray(
        AddressToAddressMap storage map
    )
        internal
        view
        returns (address[] memory keysOut, address[] memory valuesOut)
    {
        uint256 len = map._inner._entries.length;

        keysOut = new address[](len);
        valuesOut = new address[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                keysOut[i] = address(
                    uint160(uint256(map._inner._entries[i]._key))
                );
                valuesOut[i] = address(
                    uint160(uint256(map._inner._entries[i]._value))
                );
            }
        }
    }

    function toArray(
        UintToAddressMap storage map
    )
        internal
        view
        returns (uint256[] memory keysOut, address[] memory valuesOut)
    {
        uint256 len = map._inner._entries.length;

        keysOut = new uint256[](len);
        valuesOut = new address[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                keysOut[i] = uint256(map._inner._entries[i]._key);
                valuesOut[i] = address(
                    uint160(uint256(map._inner._entries[i]._value))
                );
            }
        }
    }

    function keys(
        AddressToAddressMap storage map
    ) internal view returns (address[] memory keysOut) {
        uint256 len = map._inner._entries.length;

        keysOut = new address[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                keysOut[i] = address(
                    uint160(uint256(map._inner._entries[i]._key))
                );
            }
        }
    }

    function keys(
        UintToAddressMap storage map
    ) internal view returns (uint256[] memory keysOut) {
        uint256 len = map._inner._entries.length;

        keysOut = new uint256[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                keysOut[i] = uint256(map._inner._entries[i]._key);
            }
        }
    }

    function values(
        AddressToAddressMap storage map
    ) internal view returns (address[] memory valuesOut) {
        uint256 len = map._inner._entries.length;

        valuesOut = new address[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                valuesOut[i] = address(
                    uint160(uint256(map._inner._entries[i]._value))
                );
            }
        }
    }

    function values(
        UintToAddressMap storage map
    ) internal view returns (address[] memory valuesOut) {
        uint256 len = map._inner._entries.length;

        valuesOut = new address[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                valuesOut[i] = address(
                    uint160(uint256(map._inner._entries[i]._value))
                );
            }
        }
    }

    function _at(
        Map storage map,
        uint256 index
    ) private view returns (bytes32, bytes32) {
        if (index >= map._entries.length)
            revert EnumerableMap__IndexOutOfBounds();

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    function _contains(
        Map storage map,
        bytes32 key
    ) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) revert EnumerableMap__NonExistentKey();
        unchecked {
            return map._entries[keyIndex - 1]._value;
        }
    }

    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) {
            map._entries.push(MapEntry({ _key: key, _value: value }));
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            unchecked {
                map._entries[keyIndex - 1]._value = value;
            }
            return false;
        }
    }

    function _remove(Map storage map, bytes32 key) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) {
            unchecked {
                MapEntry storage last = map._entries[map._entries.length - 1];

                // move last entry to now-vacant index
                map._entries[keyIndex - 1] = last;
                map._indexes[last._key] = keyIndex;
            }

            // clear last index
            map._entries.pop();
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    error EnumerableSet__IndexOutOfBounds();

    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(
        Bytes32Set storage set,
        uint256 index
    ) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    function at(
        AddressSet storage set,
        uint256 index
    ) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(
        UintSet storage set,
        uint256 index
    ) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    function contains(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function contains(
        AddressSet storage set,
        address value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(
        UintSet storage set,
        uint256 value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, value);
    }

    function indexOf(
        AddressSet storage set,
        address value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(
        UintSet storage set,
        uint256 value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _add(set._inner, value);
    }

    function add(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function remove(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(
        UintSet storage set,
        uint256 value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function toArray(
        Bytes32Set storage set
    ) internal view returns (bytes32[] memory) {
        return set._inner._values;
    }

    function toArray(
        AddressSet storage set
    ) internal view returns (address[] memory) {
        bytes32[] storage values = set._inner._values;
        address[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function toArray(
        UintSet storage set
    ) internal view returns (uint256[] memory) {
        bytes32[] storage values = set._inner._values;
        uint256[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function _at(
        Set storage set,
        uint256 index
    ) private view returns (bytes32) {
        if (index >= set._values.length)
            revert EnumerableSet__IndexOutOfBounds();
        return set._values[index];
    }

    function _contains(
        Set storage set,
        bytes32 value
    ) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _indexOf(
        Set storage set,
        bytes32 value
    ) private view returns (uint256) {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            status = true;
        }
    }

    function _remove(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            unchecked {
                bytes32 last = set._values[set._values.length - 1];

                // move last value to now-vacant index

                set._values[valueIndex - 1] = last;
                set._indexes[last] = valueIndex;
            }
            // clear last index

            set._values.pop();
            delete set._indexes[value];

            status = true;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165Internal } from './IERC165Internal.sol';

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 is IERC165Internal {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165Internal } from './IERC165Internal.sol';

/**
 * @title ERC165 interface registration interface
 */
interface IERC165Internal {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from './IERC173Internal.sol';

/**
 * @title Contract ownership standard interface
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173 is IERC173Internal {
    /**
     * @notice get the ERC173 contract owner
     * @return conrtact owner
     */
    function owner() external view returns (address);

    /**
     * @notice transfer contract ownership to new account
     * @param account address of new owner
     */
    function transferOwnership(address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC173 interface needed by internal functions
 */
interface IERC173Internal {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Internal } from './IERC20Internal.sol';

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 is IERC20Internal {
    /**
     * @notice query the total minted token supply
     * @return token supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice query the token balance of given account
     * @param account address to query
     * @return token balance
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice query the allowance granted from given holder to given spender
     * @param holder approver of allowance
     * @param spender recipient of allowance
     * @return token allowance
     */
    function allowance(
        address holder,
        address spender
    ) external view returns (uint256);

    /**
     * @notice grant approval to spender to spend tokens
     * @dev prefer ERC20Extended functions to avoid transaction-ordering vulnerability (see https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
     * @param spender recipient of allowance
     * @param amount quantity of tokens approved for spending
     * @return success status (always true; otherwise function should revert)
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice transfer tokens to given recipient
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice transfer tokens to given recipient on behalf of given holder
     * @param holder holder of tokens prior to transfer
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC20 interface needed by internal functions
 */
interface IERC20Internal {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from './IERC165.sol';
import { IERC721Internal } from './IERC721Internal.sol';

/**
 * @title ERC721 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721 is IERC721Internal, IERC165 {
    /**
     * @notice query the balance of given address
     * @return balance quantity of tokens held
     */
    function balanceOf(address account) external view returns (uint256 balance);

    /**
     * @notice query the owner of given token
     * @param tokenId token to query
     * @return owner token owner
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @notice transfer token between given addresses, without checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice grant approval to given account to spend token
     * @param operator address to be approved
     * @param tokenId token to approve
     */
    function approve(address operator, uint256 tokenId) external payable;

    /**
     * @notice get approval status for given token
     * @param tokenId token to query
     * @return operator address approved to spend token
     */
    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    /**
     * @notice grant approval to or revoke approval from given account to spend all tokens held by sender
     * @param operator address to be approved
     * @param status approval status
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return status whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool status);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC721 interface needed by internal functions
 */
interface IERC721Internal {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed operator,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from '../../../interfaces/IERC165.sol';
import { IERC165Base } from './IERC165Base.sol';
import { ERC165BaseInternal } from './ERC165BaseInternal.sol';
import { ERC165BaseStorage } from './ERC165BaseStorage.sol';

/**
 * @title ERC165 implementation
 */
abstract contract ERC165Base is IERC165Base, ERC165BaseInternal {
    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return _supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165BaseInternal } from './IERC165BaseInternal.sol';
import { ERC165BaseStorage } from './ERC165BaseStorage.sol';

/**
 * @title ERC165 implementation
 */
abstract contract ERC165BaseInternal is IERC165BaseInternal {
    /**
     * @notice indicates whether an interface is already supported based on the interfaceId
     * @param interfaceId id of interface to check
     * @return bool indicating whether interface is supported
     */
    function _supportsInterface(
        bytes4 interfaceId
    ) internal view returns (bool) {
        return ERC165BaseStorage.layout().supportedInterfaces[interfaceId];
    }

    /**
     * @notice sets status of interface support
     * @param interfaceId id of interface to set status for
     * @param status boolean indicating whether interface will be set as supported
     */
    function _setSupportsInterface(bytes4 interfaceId, bool status) internal {
        if (interfaceId == 0xffffffff) revert ERC165Base__InvalidInterfaceId();
        ERC165BaseStorage.layout().supportedInterfaces[interfaceId] = status;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC165BaseStorage {
    struct Layout {
        mapping(bytes4 => bool) supportedInterfaces;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC165Base');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165 } from '../../../interfaces/IERC165.sol';
import { IERC165BaseInternal } from './IERC165BaseInternal.sol';

interface IERC165Base is IERC165, IERC165BaseInternal {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165Internal } from '../../../interfaces/IERC165Internal.sol';

interface IERC165BaseInternal is IERC165Internal {
    error ERC165Base__InvalidInterfaceId();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Diamond proxy introspection interface
 * @dev see https://eips.ethereum.org/EIPS/eip-2535
 */
interface IDiamondReadable {
    struct Facet {
        address target;
        bytes4[] selectors;
    }

    /**
     * @notice get all facets and their selectors
     * @return diamondFacets array of structured facet data
     */
    function facets() external view returns (Facet[] memory diamondFacets);

    /**
     * @notice get all selectors for given facet address
     * @param facet address of facet to query
     * @return selectors array of function selectors
     */
    function facetFunctionSelectors(
        address facet
    ) external view returns (bytes4[] memory selectors);

    /**
     * @notice get addresses of all facets used by diamond
     * @return addresses array of facet addresses
     */
    function facetAddresses()
        external
        view
        returns (address[] memory addresses);

    /**
     * @notice get the address of the facet associated with given selector
     * @param selector function selector to query
     * @return facet facet address (zero address if not found)
     */
    function facetAddress(
        bytes4 selector
    ) external view returns (address facet);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IProxy {
    error Proxy__ImplementationIsNotContract();

    fallback() external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { AddressUtils } from '../utils/AddressUtils.sol';
import { IProxy } from './IProxy.sol';

/**
 * @title Base proxy contract
 */
abstract contract Proxy is IProxy {
    using AddressUtils for address;

    /**
     * @notice delegate all calls to implementation contract
     * @dev reverts if implementation address contains no code, for compatibility with metamorphic contracts
     * @dev memory location in use by assembly may be unsafe in other contexts
     */
    fallback() external payable virtual {
        address implementation = _getImplementation();

        if (!implementation.isContract())
            revert Proxy__ImplementationIsNotContract();

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @notice get logic implementation address
     * @return implementation address
     */
    function _getImplementation() internal virtual returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { PausableInternal } from './PausableInternal.sol';

/**
 * @title Pausable security control module.
 */
abstract contract Pausable is PausableInternal {
    function paused() external view virtual returns (bool) {
        return _paused();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { PausableStorage } from './PausableStorage.sol';

/**
 * @title Internal functions for Pausable security control module.
 */
abstract contract PausableInternal {
    error Pausable__Paused();
    error Pausable__NotPaused();

    event Paused(address account);
    event Unpaused(address account);

    modifier whenNotPaused() {
        if (_paused()) revert Pausable__Paused();
        _;
    }

    modifier whenPaused() {
        if (!_paused()) revert Pausable__NotPaused();
        _;
    }

    /**
     * @notice query the contracts paused state.
     * @return true if paused, false if unpaused.
     */
    function _paused() internal view virtual returns (bool) {
        return PausableStorage.layout().paused;
    }

    /**
     * @notice Triggers paused state, when contract is unpaused.
     */
    function _pause() internal virtual whenNotPaused {
        PausableStorage.layout().paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Triggers unpaused state, when contract is paused.
     */
    function _unpause() internal virtual whenPaused {
        PausableStorage.layout().paused = false;
        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library PausableStorage {
    struct Layout {
        bool paused;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Pausable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721 } from '../../../interfaces/IERC721.sol';
import { IERC721Base } from './IERC721Base.sol';
import { ERC721BaseInternal } from './ERC721BaseInternal.sol';

/**
 * @title Base ERC721 implementation, excluding optional extensions
 */
abstract contract ERC721Base is IERC721Base, ERC721BaseInternal {
    /**
     * @inheritdoc IERC721
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balanceOf(account);
    }

    /**
     * @inheritdoc IERC721
     */
    function ownerOf(uint256 tokenId) external view returns (address) {
        return _ownerOf(tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function getApproved(uint256 tokenId) external view returns (address) {
        return _getApproved(tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool) {
        return _isApprovedForAll(account, operator);
    }

    /**
     * @inheritdoc IERC721
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable {
        _transferFrom(from, to, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable {
        _safeTransferFrom(from, to, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external payable {
        _safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @inheritdoc IERC721
     */
    function approve(address operator, uint256 tokenId) external payable {
        _approve(operator, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function setApprovalForAll(address operator, bool status) external {
        _setApprovalForAll(operator, status);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721Receiver } from '../../../interfaces/IERC721Receiver.sol';
import { EnumerableMap } from '../../../data/EnumerableMap.sol';
import { EnumerableSet } from '../../../data/EnumerableSet.sol';
import { AddressUtils } from '../../../utils/AddressUtils.sol';
import { IERC721BaseInternal } from './IERC721BaseInternal.sol';
import { ERC721BaseStorage } from './ERC721BaseStorage.sol';

/**
 * @title Base ERC721 internal functions
 */
abstract contract ERC721BaseInternal is IERC721BaseInternal {
    using AddressUtils for address;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using EnumerableSet for EnumerableSet.UintSet;

    function _balanceOf(
        address account
    ) internal view virtual returns (uint256) {
        if (account == address(0)) revert ERC721Base__BalanceQueryZeroAddress();
        return ERC721BaseStorage.layout().holderTokens[account].length();
    }

    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        address owner = ERC721BaseStorage.layout().tokenOwners.get(tokenId);
        if (owner == address(0)) revert ERC721Base__InvalidOwner();
        return owner;
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return ERC721BaseStorage.layout().tokenOwners.contains(tokenId);
    }

    function _getApproved(
        uint256 tokenId
    ) internal view virtual returns (address) {
        if (!_exists(tokenId)) revert ERC721Base__NonExistentToken();

        return ERC721BaseStorage.layout().tokenApprovals[tokenId];
    }

    function _isApprovedForAll(
        address account,
        address operator
    ) internal view virtual returns (bool) {
        return ERC721BaseStorage.layout().operatorApprovals[account][operator];
    }

    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        if (!_exists(tokenId)) revert ERC721Base__NonExistentToken();

        address owner = _ownerOf(tokenId);

        return (spender == owner ||
            _getApproved(tokenId) == spender ||
            _isApprovedForAll(owner, spender));
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        if (to == address(0)) revert ERC721Base__MintToZeroAddress();
        if (_exists(tokenId)) revert ERC721Base__TokenAlreadyMinted();

        _beforeTokenTransfer(address(0), to, tokenId);

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();

        l.holderTokens[to].add(tokenId);
        l.tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, '');
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        if (!_checkOnERC721Received(address(0), to, tokenId, data))
            revert ERC721Base__ERC721ReceiverNotImplemented();
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = _ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();

        l.holderTokens[owner].remove(tokenId);
        l.tokenOwners.remove(tokenId);

        l.tokenApprovals[tokenId] = address(0);

        emit Approval(owner, address(0), tokenId);
        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        address owner = _ownerOf(tokenId);

        if (owner != from) revert ERC721Base__NotTokenOwner();
        if (to == address(0)) revert ERC721Base__TransferToZeroAddress();

        _beforeTokenTransfer(from, to, tokenId);

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();

        l.holderTokens[from].remove(tokenId);
        l.holderTokens[to].add(tokenId);
        l.tokenOwners.set(tokenId, to);
        l.tokenApprovals[tokenId] = address(0);

        emit Approval(owner, address(0), tokenId);
        emit Transfer(from, to, tokenId);
    }

    function _transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        _handleTransferMessageValue(from, to, tokenId, msg.value);
        if (!_isApprovedOrOwner(msg.sender, tokenId))
            revert ERC721Base__NotOwnerOrApproved();
        _transfer(from, to, tokenId);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, data))
            revert ERC721Base__ERC721ReceiverNotImplemented();
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        _safeTransferFrom(from, to, tokenId, '');
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _handleTransferMessageValue(from, to, tokenId, msg.value);
        if (!_isApprovedOrOwner(msg.sender, tokenId))
            revert ERC721Base__NotOwnerOrApproved();
        _safeTransfer(from, to, tokenId, data);
    }

    function _approve(address operator, uint256 tokenId) internal virtual {
        _handleApproveMessageValue(operator, tokenId, msg.value);

        address owner = _ownerOf(tokenId);

        if (operator == owner) revert ERC721Base__SelfApproval();
        if (msg.sender != owner && !_isApprovedForAll(owner, msg.sender))
            revert ERC721Base__NotOwnerOrApproved();

        ERC721BaseStorage.layout().tokenApprovals[tokenId] = operator;
        emit Approval(owner, operator, tokenId);
    }

    function _setApprovalForAll(
        address operator,
        bool status
    ) internal virtual {
        if (operator == msg.sender) revert ERC721Base__SelfApproval();
        ERC721BaseStorage.layout().operatorApprovals[msg.sender][
            operator
        ] = status;
        emit ApprovalForAll(msg.sender, operator, status);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual returns (bool) {
        if (!to.isContract()) {
            return true;
        }

        bytes memory returnData = to.functionCall(
            abi.encodeWithSelector(
                IERC721Receiver(to).onERC721Received.selector,
                msg.sender,
                from,
                tokenId,
                data
            ),
            'ERC721: transfer to non ERC721Receiver implementer'
        );

        bytes4 returnValue = abi.decode(returnData, (bytes4));
        return returnValue == type(IERC721Receiver).interfaceId;
    }

    /**
     * @notice ERC721 hook, called before externally called approvals for processing of included message value
     * @param operator beneficiary of approval
     * @param tokenId id of transferred token
     * @param value message value
     */
    function _handleApproveMessageValue(
        address operator,
        uint256 tokenId,
        uint256 value
    ) internal virtual {}

    /**
     * @notice ERC721 hook, called before externally called transfers for processing of included message value
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId id of transferred token
     * @param value message value
     */
    function _handleTransferMessageValue(
        address from,
        address to,
        uint256 tokenId,
        uint256 value
    ) internal virtual {}

    /**
     * @notice ERC721 hook, called before all transfers including mint and burn
     * @dev function should be overridden and new implementation must call super
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId id of transferred token
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { EnumerableMap } from '../../../data/EnumerableMap.sol';
import { EnumerableSet } from '../../../data/EnumerableSet.sol';

library ERC721BaseStorage {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC721Base');

    struct Layout {
        EnumerableMap.UintToAddressMap tokenOwners;
        mapping(address => EnumerableSet.UintSet) holderTokens;
        mapping(uint256 => address) tokenApprovals;
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721 } from '../../../interfaces/IERC721.sol';
import { IERC721BaseInternal } from './IERC721BaseInternal.sol';

/**
 * @title ERC721 base interface
 */
interface IERC721Base is IERC721BaseInternal, IERC721 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721Internal } from '../../../interfaces/IERC721Internal.sol';

/**
 * @title ERC721 base interface
 */
interface IERC721BaseInternal is IERC721Internal {
    error ERC721Base__NotOwnerOrApproved();
    error ERC721Base__SelfApproval();
    error ERC721Base__BalanceQueryZeroAddress();
    error ERC721Base__ERC721ReceiverNotImplemented();
    error ERC721Base__InvalidOwner();
    error ERC721Base__MintToZeroAddress();
    error ERC721Base__NonExistentToken();
    error ERC721Base__NotTokenOwner();
    error ERC721Base__TokenAlreadyMinted();
    error ERC721Base__TransferToZeroAddress();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { EnumerableMap } from '../../../data/EnumerableMap.sol';
import { EnumerableSet } from '../../../data/EnumerableSet.sol';
import { ERC721BaseStorage } from '../base/ERC721BaseStorage.sol';
import { IERC721Enumerable } from './IERC721Enumerable.sol';
import { ERC721EnumerableInternal } from './ERC721EnumerableInternal.sol';

abstract contract ERC721Enumerable is
    IERC721Enumerable,
    ERC721EnumerableInternal
{
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @inheritdoc IERC721Enumerable
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply();
    }

    /**
     * @inheritdoc IERC721Enumerable
     */
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) public view returns (uint256) {
        return _tokenOfOwnerByIndex(owner, index);
    }

    /**
     * @inheritdoc IERC721Enumerable
     */
    function tokenByIndex(uint256 index) public view returns (uint256) {
        return _tokenByIndex(index);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { EnumerableMap } from '../../../data/EnumerableMap.sol';
import { EnumerableSet } from '../../../data/EnumerableSet.sol';
import { ERC721BaseStorage } from '../base/ERC721BaseStorage.sol';

abstract contract ERC721EnumerableInternal {
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @notice TODO
     */
    function _totalSupply() internal view returns (uint256) {
        return ERC721BaseStorage.layout().tokenOwners.length();
    }

    /**
     * @notice TODO
     */
    function _tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) internal view returns (uint256) {
        return ERC721BaseStorage.layout().holderTokens[owner].at(index);
    }

    /**
     * @notice TODO
     */
    function _tokenByIndex(
        uint256 index
    ) internal view returns (uint256 tokenId) {
        (tokenId, ) = ERC721BaseStorage.layout().tokenOwners.at(index);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IERC721Enumerable {
    /**
     * @notice get total token supply
     * @return total supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice get token of given owner at given internal storage index
     * @param owner token holder to query
     * @param index position in owner's token list to query
     * @return tokenId id of retrieved token
     */
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view returns (uint256 tokenId);

    /**
     * @notice get token at given internal storage index
     * @param index position in global token list to query
     * @return tokenId id of retrieved token
     */
    function tokenByIndex(
        uint256 index
    ) external view returns (uint256 tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721Base } from './base/IERC721Base.sol';
import { IERC721Enumerable } from './enumerable/IERC721Enumerable.sol';
import { IERC721Metadata } from './metadata/IERC721Metadata.sol';

interface ISolidStateERC721 is IERC721Base, IERC721Enumerable, IERC721Metadata {
    error SolidStateERC721__PayableApproveNotSupported();
    error SolidStateERC721__PayableTransferNotSupported();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ERC721MetadataInternal } from './ERC721MetadataInternal.sol';
import { IERC721Metadata } from './IERC721Metadata.sol';

/**
 * @title ERC721 metadata extensions
 */
abstract contract ERC721Metadata is IERC721Metadata, ERC721MetadataInternal {
    /**
     * @notice inheritdoc IERC721Metadata
     */
    function name() external view virtual returns (string memory) {
        return _name();
    }

    /**
     * @notice inheritdoc IERC721Metadata
     */
    function symbol() external view virtual returns (string memory) {
        return _symbol();
    }

    /**
     * @notice inheritdoc IERC721Metadata
     */
    function tokenURI(
        uint256 tokenId
    ) external view virtual returns (string memory) {
        return _tokenURI(tokenId);
    }

    /**
     * @inheritdoc ERC721MetadataInternal
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from '../../../utils/UintUtils.sol';
import { ERC721BaseStorage } from '../base/ERC721BaseStorage.sol';
import { ERC721BaseInternal } from '../base/ERC721Base.sol';
import { IERC721MetadataInternal } from './IERC721MetadataInternal.sol';
import { ERC721MetadataStorage } from './ERC721MetadataStorage.sol';
import { ERC721MetadataInternal } from './ERC721MetadataInternal.sol';

/**
 * @title ERC721Metadata internal functions
 */
abstract contract ERC721MetadataInternal is
    IERC721MetadataInternal,
    ERC721BaseInternal
{
    using UintUtils for uint256;

    /**
     * @notice get token name
     * @return token name
     */
    function _name() internal view virtual returns (string memory) {
        return ERC721MetadataStorage.layout().name;
    }

    /**
     * @notice get token symbol
     * @return token symbol
     */
    function _symbol() internal view virtual returns (string memory) {
        return ERC721MetadataStorage.layout().symbol;
    }

    /**
     * @notice get generated URI for given token
     * @return token URI
     */
    function _tokenURI(
        uint256 tokenId
    ) internal view virtual returns (string memory) {
        if (!_exists(tokenId)) revert ERC721Metadata__NonExistentToken();

        ERC721MetadataStorage.Layout storage l = ERC721MetadataStorage.layout();

        string memory tokenIdURI = l.tokenURIs[tokenId];
        string memory baseURI = l.baseURI;

        if (bytes(baseURI).length == 0) {
            return tokenIdURI;
        } else if (bytes(tokenIdURI).length > 0) {
            return string(abi.encodePacked(baseURI, tokenIdURI));
        } else {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        }
    }

    /**
     * @notice ERC721 hook: clear per-token URI data on burn
     * @inheritdoc ERC721BaseInternal
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (to == address(0)) {
            delete ERC721MetadataStorage.layout().tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC721MetadataStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC721Metadata');

    struct Layout {
        string name;
        string symbol;
        string baseURI;
        mapping(uint256 => string) tokenURIs;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721MetadataInternal } from './IERC721MetadataInternal.sol';

/**
 * @title ERC721Metadata interface
 */
interface IERC721Metadata is IERC721MetadataInternal {
    /**
     * @notice get token name
     * @return token name
     */
    function name() external view returns (string memory);

    /**
     * @notice get token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice get generated URI for given token
     * @return token URI
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721BaseInternal } from '../base/IERC721BaseInternal.sol';

/**
 * @title ERC721Metadata internal interface
 */
interface IERC721MetadataInternal is IERC721BaseInternal {
    error ERC721Metadata__NonExistentToken();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ERC165Base } from '../../introspection/ERC165/base/ERC165Base.sol';
import { ERC721Base, ERC721BaseInternal } from './base/ERC721Base.sol';
import { ERC721Enumerable } from './enumerable/ERC721Enumerable.sol';
import { ERC721Metadata } from './metadata/ERC721Metadata.sol';
import { ISolidStateERC721 } from './ISolidStateERC721.sol';

/**
 * @title SolidState ERC721 implementation, including recommended extensions
 */
abstract contract SolidStateERC721 is
    ISolidStateERC721,
    ERC721Base,
    ERC721Enumerable,
    ERC721Metadata,
    ERC165Base
{
    /**
     * @notice ERC721 hook: revert if value is included in external approve function call
     * @inheritdoc ERC721BaseInternal
     */
    function _handleApproveMessageValue(
        address operator,
        uint256 tokenId,
        uint256 value
    ) internal virtual override {
        if (value > 0) revert SolidStateERC721__PayableApproveNotSupported();
        super._handleApproveMessageValue(operator, tokenId, value);
    }

    /**
     * @notice ERC721 hook: revert if value is included in external transfer function call
     * @inheritdoc ERC721BaseInternal
     */
    function _handleTransferMessageValue(
        address from,
        address to,
        uint256 tokenId,
        uint256 value
    ) internal virtual override {
        if (value > 0) revert SolidStateERC721__PayableTransferNotSupported();
        super._handleTransferMessageValue(from, to, tokenId, value);
    }

    /**
     * @inheritdoc ERC721BaseInternal
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721BaseInternal, ERC721Metadata) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    error AddressUtils__InsufficientBalance();
    error AddressUtils__NotContract();
    error AddressUtils__SendValueFailed();

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        if (!success) revert AddressUtils__SendValueFailed();
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        if (value > address(this).balance)
            revert AddressUtils__InsufficientBalance();
        return _functionCallWithValue(target, data, value, error);
    }

    /**
     * @notice execute arbitrary external call with limited gas usage and amount of copied return data
     * @dev derived from https://github.com/nomad-xyz/ExcessivelySafeCall (MIT License)
     * @param target recipient of call
     * @param gasAmount gas allowance for call
     * @param value native token value to include in call
     * @param maxCopy maximum number of bytes to copy from return data
     * @param data encoded call data
     * @return success whether call is successful
     * @return returnData copied return data
     */
    function excessivelySafeCall(
        address target,
        uint256 gasAmount,
        uint256 value,
        uint16 maxCopy,
        bytes memory data
    ) internal returns (bool success, bytes memory returnData) {
        returnData = new bytes(maxCopy);

        assembly {
            // execute external call via assembly to avoid automatic copying of return data
            success := call(
                gasAmount,
                target,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )

            // determine whether to limit amount of data to copy
            let toCopy := returndatasize()

            if gt(toCopy, maxCopy) {
                toCopy := maxCopy
            }

            // store the length of the copied bytes
            mstore(returnData, toCopy)

            // copy the bytes from returndata[0:toCopy]
            returndatacopy(add(returnData, 0x20), 0, toCopy)
        }
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        if (!isContract(target)) revert AddressUtils__NotContract();

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ReentrancyGuardStorage } from './ReentrancyGuardStorage.sol';

/**
 * @title Utility contract for preventing reentrancy attacks
 */
abstract contract ReentrancyGuard {
    error ReentrancyGuard__ReentrantCall();

    modifier nonReentrant() {
        ReentrancyGuardStorage.Layout storage l = ReentrancyGuardStorage
            .layout();
        if (l.status == 2) revert ReentrancyGuard__ReentrantCall();
        l.status = 2;
        _;
        l.status = 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ReentrancyGuardStorage {
    struct Layout {
        uint256 status;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ReentrancyGuard');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20 } from '../interfaces/IERC20.sol';
import { AddressUtils } from './AddressUtils.sol';

/**
 * @title Safe ERC20 interaction library
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library SafeERC20 {
    using AddressUtils for address;

    error SafeERC20__ApproveFromNonZeroToNonZero();
    error SafeERC20__DecreaseAllowanceBelowZero();
    error SafeERC20__OperationFailed();

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev safeApprove (like approve) should only be called when setting an initial allowance or when resetting it to zero; otherwise prefer safeIncreaseAllowance and safeDecreaseAllowance
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        if ((value != 0) && (token.allowance(address(this), spender) != 0))
            revert SafeERC20__ApproveFromNonZeroToNonZero();

        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            if (oldAllowance < value)
                revert SafeERC20__DecreaseAllowanceBelowZero();
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    /**
     * @notice send transaction data and check validity of return value, if present
     * @param token ERC20 token interface
     * @param data transaction data
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            'SafeERC20: low-level call failed'
        );

        if (returndata.length > 0) {
            if (!abi.decode(returndata, (bool)))
                revert SafeERC20__OperationFailed();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    error UintUtils__InsufficientHexLength();

    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function add(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? sub(a, -b) : a + uint256(b);
    }

    function sub(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? add(a, -b) : a - uint256(b);
    }

    function toString(uint256 value) internal pure returns (string memory) {
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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        if (value != 0) revert UintUtils__InsufficientHexLength();

        return string(buffer);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IUniswapV3PoolImmutables} from './pool/IUniswapV3PoolImmutables.sol';
import {IUniswapV3PoolState} from './pool/IUniswapV3PoolState.sol';
import {IUniswapV3PoolDerivedState} from './pool/IUniswapV3PoolDerivedState.sol';
import {IUniswapV3PoolActions} from './pool/IUniswapV3PoolActions.sol';
import {IUniswapV3PoolOwnerActions} from './pool/IUniswapV3PoolOwnerActions.sol';
import {IUniswapV3PoolErrors} from './pool/IUniswapV3PoolErrors.sol';
import {IUniswapV3PoolEvents} from './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolErrors,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Errors emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolErrors {
    error LOK();
    error TLU();
    error TLM();
    error TUM();
    error AI();
    error M0();
    error M1();
    error AS();
    error IIA();
    error L();
    error F0();
    error F1();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// @return observationIndex The index of the last oracle observation that was written,
    /// @return observationCardinality The current maximum number of observations stored in the pool,
    /// @return observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// @return feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    /// @return The liquidity at the current price of the pool
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper
    /// @return liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// @return feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// @return feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// @return tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// @return secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// @return secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// @return initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return liquidity The amount of liquidity in the position,
    /// @return feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// @return feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// @return tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// @return tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// @return tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// @return secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// @return initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';
import { SafeERC20 } from '@solidstate/contracts/utils/SafeERC20.sol';
import { AddressUtils } from '@solidstate/contracts/utils/AddressUtils.sol';

import { Registry } from './registry/Registry.sol';
import { RegistryStorage } from './registry/RegistryStorage.sol';
import { VaultBaseExternal } from './vault-base/VaultBaseExternal.sol';
import { IAggregatorV3Interface } from './interfaces/IAggregatorV3Interface.sol';
import { IValioCustomAggregator } from './aggregators/IValioCustomAggregator.sol';
import { IValuer } from './valuers/IValuer.sol';

import { Constants } from './lib/Constants.sol';

contract Accountant {
    using AddressUtils for address;

    Registry registry;

    constructor(address _registry) {
        require(_registry != address(0), 'Invalid registry');
        registry = Registry(_registry);
    }

    function isSupportedAsset(address asset) external view returns (bool) {
        return registry.valuers(asset) != address(0);
    }

    function isDeprecated(address asset) external view returns (bool) {
        return registry.deprecatedAssets(asset);
    }

    function isHardDeprecated(address asset) external view returns (bool) {
        return _isHardDeprecated(asset);
    }

    function getVaultValue(
        address vault
    )
        external
        view
        returns (uint minValue, uint maxValue, bool hasHardDeprecatedAsset)
    {
        address[] memory activeAssets = VaultBaseExternal(payable(vault))
            .assetsWithBalances();
        for (uint i = 0; i < activeAssets.length; i++) {
            if (_isHardDeprecated(activeAssets[i])) {
                hasHardDeprecatedAsset = true;
            }
            (uint minAssetValue, uint maxAssetValue) = _assetValueOfVault(
                activeAssets[i],
                vault
            );
            minValue += minAssetValue;
            maxValue += maxAssetValue;
        }
    }

    function assetValueOfVault(
        address asset,
        address vault
    ) external view returns (uint minValue, uint maxValue) {
        return _assetValueOfVault(asset, vault);
    }

    function assetIsActive(
        address asset,
        address vault
    ) external view returns (bool) {
        return _assetIsActive(asset, vault);
    }

    function assetValue(
        address asset,
        uint amount
    ) external view returns (uint minValue, uint maxValue) {
        int256 unitPrice = _getUSDPrice(asset);
        address valuer = registry.valuers(asset);
        require(valuer != address(0), 'No valuer');
        return IValuer(valuer).getAssetValue(amount, asset, unitPrice);
    }

    function assetBreakDownOfVault(
        address vault
    ) external view returns (IValuer.AssetValue[] memory) {
        address[] memory activeAssets = VaultBaseExternal(payable(vault))
            .assetsWithBalances();
        IValuer.AssetValue[] memory ava = new IValuer.AssetValue[](
            activeAssets.length
        );
        for (uint i = 0; i < activeAssets.length; i++) {
            // Hard deprecated assets have 0 value, but they can be traded out of
            bool hardDeprecated = registry.hardDeprecatedAssets(
                activeAssets[i]
            );

            int256 unitPrice = hardDeprecated
                ? int256(0)
                : _getUSDPrice(activeAssets[i]);
            address valuer = registry.valuers(activeAssets[i]);
            require(valuer != address(0), 'No valuer');
            ava[i] = IValuer(valuer).getAssetBreakdown(
                vault,
                activeAssets[i],
                unitPrice
            );
        }
        return ava;
    }

    function _assetValueOfVault(
        address asset,
        address vault
    ) internal view returns (uint minValue, uint maxValue) {
        // Hard deprecated assets have 0 value, but they can be traded out of
        if (registry.hardDeprecatedAssets(asset)) {
            return (0, 0);
        }
        int256 unitPrice = _getUSDPrice(asset);
        address valuer = registry.valuers(asset);
        require(valuer != address(0), 'No valuer');
        return IValuer(valuer).getVaultValue(vault, asset, unitPrice);
    }

    function _assetIsActive(
        address asset,
        address vault
    ) internal view returns (bool) {
        address valuer = registry.valuers(asset);
        require(valuer != address(0), 'No valuer');
        return IValuer(valuer).getAssetActive(vault, asset);
    }

    function _getUSDPrice(address asset) internal view returns (int256 price) {
        uint256 updatedAt;

        RegistryStorage.AggregatorType aggregatorType = registry
            .assetAggregatorType(asset);

        if (aggregatorType == RegistryStorage.AggregatorType.ChainlinkV3USD) {
            IAggregatorV3Interface chainlinkAggregator = registry
                .chainlinkV3USDAggregators(asset);
            require(
                address(chainlinkAggregator) != address(0),
                'No cl aggregator'
            );
            (, price, , updatedAt, ) = chainlinkAggregator.latestRoundData();
        } else if (
            aggregatorType == RegistryStorage.AggregatorType.UniswapV3Twap ||
            aggregatorType == RegistryStorage.AggregatorType.VelodromeV2Twap
        ) {
            IValioCustomAggregator valioAggregator = registry
                .valioCustomUSDAggregators(aggregatorType);

            require(address(valioAggregator) != address(0), 'No vl aggregator');
            (price, updatedAt) = valioAggregator.latestRoundData(asset);
        } else if (aggregatorType == RegistryStorage.AggregatorType.None) {
            return 0;
        } else {
            revert('Unsupported aggregator type');
        }

        require(
            updatedAt + registry.chainlinkTimeout() >= block.timestamp,
            'Price expired'
        );

        require(price > 0, 'Price not available');

        price = price * (int(Constants.VAULT_PRECISION) / 10 ** 8);
    }

    function _isHardDeprecated(address asset) internal view returns (bool) {
        return registry.hardDeprecatedAssets(asset);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IValioCustomAggregator {
    function description() external view returns (string memory);

    function decimals() external view returns (uint8);

    function latestRoundData(
        address asset
    ) external view returns (int256 answer, uint256 updatedAt);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import { CPITStorage } from './CPITStorage.sol';
import { Constants } from '../lib/Constants.sol';

contract CPIT {
    uint256 constant WINDOW_SIZE = 6 hours; // window size for rolling 24 hours

    function _updatePriceImpact(
        uint preTransactionValue,
        uint postTransactionValue,
        uint max24HourCPITBips
    ) internal returns (uint priceImpactBips) {
        CPITStorage.Layout storage l = CPITStorage.layout();
        // calculate price impact in BIPs
        priceImpactBips = _calculatePriceImpact(
            preTransactionValue,
            postTransactionValue
        );

        if (priceImpactBips == 0) {
            return priceImpactBips;
        }

        uint currentWindow = _getCurrentWindow();

        // update priceImpact for current window
        l.deviation[currentWindow] += priceImpactBips;

        uint cumulativePriceImpact = _calculateCumulativePriceImpact(
            currentWindow
        );

        // check if 24 hour cumulative price impact threshold is exceeded
        if (cumulativePriceImpact > max24HourCPITBips) {
            revert('CPIT: price impact exceeded');
        }
    }

    function _getCurrentCpit() internal view returns (uint256) {
        return _calculateCumulativePriceImpact(_getCurrentWindow());
    }

    function _getCurrentWindow() internal view returns (uint256 currentWindow) {
        currentWindow = block.timestamp / WINDOW_SIZE;
    }

    // calculate the 24 hour cumulative price impact
    function _calculateCumulativePriceImpact(
        uint currentWindow
    ) internal view returns (uint cumulativePriceImpact) {
        CPITStorage.Layout storage l = CPITStorage.layout();
        uint windowsInDay = 24 hours / WINDOW_SIZE;
        uint startWindow = currentWindow - (windowsInDay - 1);
        for (uint256 i = startWindow; i <= currentWindow; i++) {
            cumulativePriceImpact += l.deviation[i];
        }
    }

    function _calculatePriceImpact(
        uint oldValue,
        uint newValue
    ) internal pure returns (uint priceImpactBips) {
        if (newValue >= oldValue) {
            return 0;
        }
        // Calculate the deviation between the old and new values
        uint deviation = oldValue - newValue;
        // Calculate the impact on price in basis points (BIPs)
        priceImpactBips = ((deviation * Constants.BASIS_POINTS_DIVISOR) /
            oldValue);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library CPITStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256('valio.storage.CPIT');

    // solhint-disable-next-line ordering
    struct Layout {
        uint256 DEPRECATED_lockedUntil; // timestamp of when vault is locked until
        mapping(uint256 => uint) deviation; // deviation for each window
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';
import { SafeERC20 } from '@solidstate/contracts/utils/SafeERC20.sol';
import { SafeOwnable } from '@solidstate/contracts/access/ownable/SafeOwnable.sol';

import { Registry } from '../registry/Registry.sol';
import { DepositAutomatorStorage } from './DepositAutomatorStorage.sol';
import { VaultParent } from '../vault-parent/VaultParent.sol';
import { VaultParentInvestor } from '../vault-parent/VaultParentInvestor.sol';

import { Constants } from '../lib/Constants.sol';

contract DepositAutomator is SafeOwnable {
    event DepositSyncInitiated(address vault);
    event QueuedDeposit(DepositAutomatorStorage.QueuedDeposit queuedDeposit);
    event QueuedDepositExecuted(
        DepositAutomatorStorage.QueuedDeposit queuedDeposit
    );

    function queueDepositAndSync(
        VaultParent vault,
        uint tokenId,
        IERC20 depositAsset,
        uint depositAmount,
        uint maxUnitPrice,
        uint expiry,
        uint[] memory lzSyncFees
    ) external payable {
        uint totalSyncFees;

        for (uint i = 0; i < lzSyncFees.length; i++) {
            totalSyncFees += lzSyncFees[i];
        }
        vault.requestTotalValueUpdateMultiChain{ value: totalSyncFees }(
            lzSyncFees
        );
        emit DepositSyncInitiated(address(vault));

        _queueDeposit(
            vault,
            msg.sender,
            tokenId,
            depositAsset,
            depositAmount,
            maxUnitPrice,
            expiry,
            msg.value - totalSyncFees
        );
    }

    function queueDeposit(
        VaultParent vault,
        uint tokenId,
        IERC20 depositAsset,
        uint depositAmount,
        uint maxUnitPrice,
        uint expiry
    ) external payable {
        _queueDeposit(
            vault,
            msg.sender,
            tokenId,
            depositAsset,
            depositAmount,
            maxUnitPrice,
            expiry,
            msg.value
        );
    }

    function executeDeposit(address vault, uint index) external {
        DepositAutomatorStorage.QueuedDeposit memory qDeposit = _queuedDeposit(
            vault,
            index
        );
        require(block.timestamp <= qDeposit.expiryTime, 'expired Deposit');

        // Remove queued Deposit
        _removeQueuedDeposit(vault, qDeposit.depositor, index);

        (, uint maxCurrentUnitPrice) = qDeposit.vault.unitPrice();

        require(
            maxCurrentUnitPrice <= qDeposit.maxUnitPrice,
            'entry price too high'
        );

        qDeposit.depositAsset.transferFrom(
            qDeposit.depositor,
            address(this),
            qDeposit.depositAmount
        );

        qDeposit.depositAsset.approve(
            address(qDeposit.vault),
            qDeposit.depositAmount
        );

        qDeposit.vault.depositFor(
            qDeposit.depositor,
            qDeposit.tokenId,
            address(qDeposit.depositAsset),
            qDeposit.depositAmount
        );

        // Pay Keeper
        (bool keeprSent, ) = msg.sender.call{ value: qDeposit.keeperFee }('');
        require(keeprSent, 'Failed to pay keeper');

        DepositAutomatorStorage
        .layout()
        .executedDepositsByVaultByDepositor[vault][qDeposit.depositor].push(
                qDeposit
            );

        emit QueuedDepositExecuted(qDeposit);
    }

    // There is no incentive for anyone except the depositor to call this function
    // As the keeper fee is refunded to the original depositor
    // Though if the queuedDeposit has expired anyone can call this function
    // They wont receive any benefit though
    function removeQueuedDeposit(address vault, uint index) external {
        DepositAutomatorStorage.QueuedDeposit memory qDeposit = _queuedDeposit(
            vault,
            index
        );

        if (qDeposit.expiryTime > block.timestamp) {
            require(qDeposit.depositor == msg.sender, 'not owner');
        }

        _removeQueuedDeposit(vault, qDeposit.depositor, index);

        // Refund the tokenOwner the keeper fee
        (bool sent, ) = qDeposit.depositor.call{ value: qDeposit.keeperFee }(
            ''
        );
        require(sent, 'Failed to refund');
    }

    function setKeeperFee(uint _keeperFee) external onlyOwner {
        DepositAutomatorStorage.layout().keeperFee = _keeperFee;
    }

    function keeperFee() external view returns (uint) {
        return DepositAutomatorStorage.layout().keeperFee;
    }

    function canExecute(
        address vault,
        uint index
    ) external view returns (bool, string memory) {
        DepositAutomatorStorage.QueuedDeposit memory qDeposit = _queuedDeposit(
            address(vault),
            index
        );

        if (block.timestamp > qDeposit.expiryTime) {
            return (false, 'expired');
        }

        if (
            qDeposit.depositAsset.allowance(qDeposit.depositor, address(this)) <
            qDeposit.depositAmount
        ) {
            return (false, 'insufficient allowance');
        }

        if (
            qDeposit.depositAsset.balanceOf(qDeposit.depositor) <
            qDeposit.depositAmount
        ) {
            return (false, 'insufficient balance');
        }

        try qDeposit.vault.unitPrice() returns (
            uint,
            uint maxCurrentUnitPrice
        ) {
            if (maxCurrentUnitPrice > qDeposit.maxUnitPrice) {
                return (false, 'price to high');
            }
        } catch {
            return (false, 'vault not synced');
        }

        return (true, '');
    }

    function executedDepositsByVaultByDepositor(
        address vault,
        address depositor
    ) external view returns (DepositAutomatorStorage.QueuedDeposit[] memory) {
        return
            DepositAutomatorStorage.layout().executedDepositsByVaultByDepositor[
                vault
            ][depositor];
    }

    function getSyncLzFees(
        VaultParent vault
    ) external view returns (uint[] memory lzFees, uint256 totalSendFee) {
        return
            vault.getLzFeesMultiChain(
                vault.requestTotalValueUpdateMultiChain.selector
            );
    }

    function queuedDepositIndexesByVaultByDepositor(
        address vault,
        address depositor
    ) external view returns (uint[] memory) {
        return
            DepositAutomatorStorage
                .layout()
                .queuedDepositIndexesByVaultByDepositor[vault][depositor];
    }

    function queuedDepositByVaultByIndex(
        address vault,
        uint index
    ) external view returns (DepositAutomatorStorage.QueuedDeposit memory) {
        return _queuedDeposit(vault, index);
    }

    function numberOfQueuedDepositsByVault(
        address vault
    ) external view returns (uint) {
        return
            DepositAutomatorStorage
                .layout()
                .queuedDepositsByVault[vault]
                .length;
    }

    function queuedDepositsByVault(
        address vault
    ) external view returns (DepositAutomatorStorage.QueuedDeposit[] memory) {
        return DepositAutomatorStorage.layout().queuedDepositsByVault[vault];
    }

    function _queueDeposit(
        VaultParent vault,
        address depositor,
        uint tokenId,
        IERC20 depositAsset,
        uint depositAmount,
        uint maxUnitPrice,
        uint expiry,
        uint feesPaid
    ) internal {
        require(depositAmount > 0, 'deposit amount 0');
        // Don't use queueDeposit if the vault does not require sync. Deposit Directly.
        require(vault.requiresSyncForDeposit(), 'no sync needed');
        // At the moment we only allow one holding per depositor
        // We add this safety check here so that it doesn't fail when depositing
        if (tokenId == 0) {
            require(vault.balanceOf(depositor) == 0, 'already owns holding');
        } else {
            // Safety check to make sure users don't deposit into someone elses holding
            require(vault.ownerOf(tokenId) == depositor, 'not owner');
        }

        // The expiry has to be at least 10 minutes so that the sync has time to complete
        require(expiry > block.timestamp + 10 minutes, 'expiry to short');

        // Note: this contract only takes the funds when the deposit is executed.
        // The funds are transient and never held in this contract
        require(
            depositAsset.allowance(depositor, address(this)) >= depositAmount,
            'insufficient allowance'
        );

        require(
            depositAsset.balanceOf(depositor) >= depositAmount,
            'insufficient balance'
        );

        DepositAutomatorStorage.Layout storage l = DepositAutomatorStorage
            .layout();

        require(feesPaid >= l.keeperFee, 'insufficient fee');

        DepositAutomatorStorage.QueuedDeposit
            memory qDeposit = DepositAutomatorStorage.QueuedDeposit({
                vault: vault,
                depositor: depositor,
                tokenId: tokenId,
                depositAsset: depositAsset,
                depositAmount: depositAmount,
                maxUnitPrice: maxUnitPrice,
                keeperFee: l.keeperFee,
                expiryTime: expiry,
                createdAtTime: block.timestamp,
                nonce: l.nonce++
            });

        DepositAutomatorStorage.QueuedDeposit[] storage _queuedDeposits = l
            .queuedDepositsByVault[address(vault)];

        uint[] storage _queuedDepositIndexes = l
            .queuedDepositIndexesByVaultByDepositor[address(vault)][depositor];

        // Later we can support multiple queued Deposits per depositor
        require(_queuedDepositIndexes.length == 0, '1 queue per depositor');

        _queuedDepositIndexes.push(_queuedDeposits.length);
        _queuedDeposits.push(qDeposit);

        emit QueuedDeposit(qDeposit);
    }

    function _removeQueuedDeposit(
        address vault,
        address depositor,
        uint index
    ) internal {
        DepositAutomatorStorage.Layout storage l = DepositAutomatorStorage
            .layout();

        DepositAutomatorStorage.QueuedDeposit[] storage queuedDeposits = l
            .queuedDepositsByVault[vault];
        // The last element is moved to the index being removed
        uint lastIndex = queuedDeposits.length - 1;
        // Remove queued Deposit
        _removeFromArray(
            DepositAutomatorStorage.layout().queuedDepositsByVault[vault],
            index
        );

        // The mapping for the vault -> tokenId -> index needs to be updated
        _updateMovedDepositorIndex(queuedDeposits, vault, lastIndex, index);

        // Remove the index for the vault -> depositor mapping
        uint[] storage _queuedDepositIndexes = l
            .queuedDepositIndexesByVaultByDepositor[address(vault)][depositor];

        for (uint i = 0; i < _queuedDepositIndexes.length; i++) {
            if (_queuedDepositIndexes[i] == index) {
                _removeFromArray(_queuedDepositIndexes, i);
                return;
            }
        }
    }

    function _updateMovedDepositorIndex(
        DepositAutomatorStorage.QueuedDeposit[] storage queuedDeposits,
        address vault,
        uint oldIndex,
        uint newIndex
    ) internal {
        if (newIndex < queuedDeposits.length) {
            DepositAutomatorStorage.QueuedDeposit
                memory atIndex = queuedDeposits[newIndex];

            uint[]
                storage queuedDepositIndexesForDepositor = DepositAutomatorStorage
                    .layout()
                    .queuedDepositIndexesByVaultByDepositor[address(vault)][
                        atIndex.depositor
                    ];
            for (uint i = 0; i < queuedDepositIndexesForDepositor.length; i++) {
                if (queuedDepositIndexesForDepositor[i] == oldIndex) {
                    queuedDepositIndexesForDepositor[i] = newIndex;
                }
            }
        }
    }

    function _removeFromArray(
        DepositAutomatorStorage.QueuedDeposit[] storage array,
        uint index
    ) internal {
        require(index < array.length);
        array[index] = array[array.length - 1];
        array.pop();
    }

    function _removeFromArray(uint[] storage array, uint index) internal {
        require(index < array.length);
        array[index] = array[array.length - 1];
        array.pop();
    }

    function _queuedDeposit(
        address vault,
        uint index
    ) internal view returns (DepositAutomatorStorage.QueuedDeposit memory) {
        return
            DepositAutomatorStorage.layout().queuedDepositsByVault[vault][
                index
            ];
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { Registry } from '../registry/Registry.sol';
import { VaultParent } from '../vault-parent/VaultParent.sol';

import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';
import { ILayerZeroEndpoint } from '@layerzerolabs/solidity-examples/contracts/interfaces/ILayerZeroEndpoint.sol';

library DepositAutomatorStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('valio.storage.DespositAutomator');

    // solhint-disable-next-line ordering
    struct QueuedDeposit {
        VaultParent vault;
        address depositor;
        uint tokenId;
        IERC20 depositAsset;
        uint depositAmount;
        uint maxUnitPrice;
        uint keeperFee;
        uint expiryTime;
        uint createdAtTime;
        uint nonce;
    }

    // solhint-disable-next-line ordering
    struct Layout {
        uint keeperFee;
        // Vault -> QueuedDeposit
        mapping(address => QueuedDeposit[]) queuedDepositsByVault;
        // Vault -> depositor -> QueuedDepositIndexes
        mapping(address => mapping(address => uint[])) queuedDepositIndexesByVaultByDepositor;
        // Vault -> depositor -> Completed QueuedDeposits
        mapping(address => mapping(address => QueuedDeposit[])) executedDepositsByVaultByDepositor;
        uint nonce;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ExecutorIntegration, ExecutorAction, IExecutorEvents } from './IExecutorEvents.sol';

interface IExecutor is IExecutorEvents {
    function requiresCPIT() external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

enum ExecutorIntegration {
    ZeroX,
    GMX,
    SnxPerpsV2,
    GMXOrderBook
}

enum ExecutorAction {
    Swap,
    PerpLongIncrease,
    PerpShortIncrease,
    PerpLongDecrease,
    PerpShortDecrease
}

interface IExecutorEvents {
    event ExecutedManagerAction(
        ExecutorIntegration indexed integration,
        ExecutorAction indexed action,
        address inputToken,
        uint inputTokenAmount,
        address outputToken,
        uint outputTokenAmount,
        uint price
    );

    event ExecutedCallback(
        ExecutorIntegration indexed integration,
        ExecutorAction indexed action,
        address inputToken,
        address outputToken,
        bool wasExecuted,
        uint executionPrice
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IGmxRouter } from './interfaces/IGmxRouter.sol';
import { IGmxVault } from './interfaces/IGmxVault.sol';
import { IGmxOrderBook } from './interfaces/IGmxOrderBook.sol';
import { IGmxPositionRouter } from './interfaces/IGmxPositionRouter.sol';

contract GmxConfig {
    IGmxRouter public immutable router;
    IGmxPositionRouter public immutable positionRouter;
    IGmxVault public immutable vault;
    IGmxOrderBook public immutable orderBook;
    bytes32 public immutable referralCode;
    uint public immutable maxPositions = 2;
    // The number of unexecuted requests a vault can have open at a time.
    uint public immutable maxOpenRequests = 2;
    // The number of unexecuted decrease orders a vault can have open at a time.
    uint public immutable maxOpenDecreaseOrders = 2;
    uint public immutable acceptablePriceDeviationBasisPoints = 200; // 2%

    constructor(
        address _gmxRouter,
        address _gmxPositionRouter,
        address _gmxVault,
        address _gmxOrderBook,
        bytes32 _gmxReferralCode
    ) {
        router = IGmxRouter(_gmxRouter);
        positionRouter = IGmxPositionRouter(_gmxPositionRouter);
        vault = IGmxVault(_gmxVault);
        orderBook = IGmxOrderBook(_gmxOrderBook);
        referralCode = _gmxReferralCode;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IntegrationDataTrackerStorage, Integration } from './IntegrationDataTrackerStorage.sol';

// This contract is a general store for when we need to store data that is relevant to an integration
// For example with GMX we must track what positions are open for each vault

contract IntegrationDataTracker {
    /**
     * @notice record new raw data
     * @param _integration used as the namespace for the data
     * @param _data the data track data to be recorded in storage
     */
    function pushData(Integration _integration, bytes memory _data) external {
        _pushData(_integration, msg.sender, _data);
    }

    /**
     * @notice record new raw data
     * @param _integration used as the namespace for the data
     * @param _data the data track data to be recorded in storage
     */
    function pushData(bytes32 _integration, bytes memory _data) external {
        _pushData(_integration, msg.sender, _data);
    }

    /**
     * @notice delete data
     * @param _integration used as the namespace for the data
     * @param _index data index to be removed from storage
     */
    function removeData(Integration _integration, uint256 _index) external {
        _removeData(_integration, msg.sender, _index);
    }

    /**
     * @notice delete data
     * @param _integration used as the namespace for the data
     * @param _index data index to be removed from storage
     */
    function removeData(bytes32 _integration, uint256 _index) external {
        _removeData(_integration, msg.sender, _index);
    }

    /**
     * @notice returns tracked data by index
     * @param _integration used as the namespace for the data
     * @param _vault the vaultAddress
     * @param _index the index of data track data
     * @return data the data track data of given NFT_TYPE & poolLogic & index
     */
    function getData(
        Integration _integration,
        address _vault,
        uint256 _index
    ) external view returns (bytes memory) {
        return
            IntegrationDataTrackerStorage.layout().trackedData[
                bytes32(uint(_integration))
            ][_vault][_index];
    }

    /**
     * @notice returns tracked data by index
     * @param _integration used as the namespace for the data
     * @param _vault the vaultAddress
     * @param _index the index of data track data
     * @return data the data track data of given NFT_TYPE & poolLogic & index
     */
    function getData(
        bytes32 _integration,
        address _vault,
        uint256 _index
    ) external view returns (bytes memory) {
        return
            IntegrationDataTrackerStorage.layout().trackedData[_integration][
                _vault
            ][_index];
    }

    /**
     * @notice returns all tracked datas by NFT_TYPE & poolLogic
     * @param _integration used as the namespace for the data
     * @param _vault the vaultAddress
     * @return data all tracked datas of given NFT_TYPE & poolLogic
     */
    function getAllData(
        Integration _integration,
        address _vault
    ) public view returns (bytes[] memory) {
        return
            IntegrationDataTrackerStorage.layout().trackedData[
                bytes32(uint(_integration))
            ][_vault];
    }

    /**
     * @notice returns all tracked datas by NFT_TYPE & poolLogic
     * @param _integration used as the namespace for the data
     * @param _vault the vaultAddress
     * @return data all tracked datas of given NFT_TYPE & poolLogic
     */
    function getAllData(
        bytes32 _integration,
        address _vault
    ) public view returns (bytes[] memory) {
        return
            IntegrationDataTrackerStorage.layout().trackedData[_integration][
                _vault
            ];
    }

    /**
     * @notice returns all tracked datas by NFT_TYPE & poolLogic
     * @param _integration used as the namespace for the data
     * @param _vault the vaultAddress
     * @return count all tracked datas count of given NFT_TYPE & poolLogic
     */
    function getDataCount(
        Integration _integration,
        address _vault
    ) public view returns (uint256) {
        return
            IntegrationDataTrackerStorage
            .layout()
            .trackedData[bytes32(uint(_integration))][_vault].length;
    }

    /**
     * @notice returns all tracked datas by NFT_TYPE & poolLogic
     * @param _integration used as the namespace for the data
     * @param _vault the vaultAddress
     * @return count all tracked datas count of given NFT_TYPE & poolLogic
     */
    function getDataCount(
        bytes32 _integration,
        address _vault
    ) public view returns (uint256) {
        return
            IntegrationDataTrackerStorage
            .layout()
            .trackedData[_integration][_vault].length;
    }

    /**
     * @notice record new raw data
     * @param _integration used as the namespace for the data
     * @param _vault the vaultAddress
     * @param _data the data track data to be recorded in storage
     */
    function _pushData(
        bytes32 _integration,
        address _vault,
        bytes memory _data
    ) private {
        IntegrationDataTrackerStorage
        .layout()
        .trackedData[_integration][_vault].push(_data);
    }

    /**
     * @notice record new raw data
     * @param _integration used as the namespace for the data
     * @param _vault the vaultAddress
     * @param _data the data track data to be recorded in storage
     */
    function _pushData(
        Integration _integration,
        address _vault,
        bytes memory _data
    ) private {
        IntegrationDataTrackerStorage
        .layout()
        .trackedData[bytes32(uint(_integration))][_vault].push(_data);
    }

    /**
     * @notice delete data
     * @param _integration used as the namespace for the data
     * @param _vault the vaultAddress
     * @param _index data index to be removed from storage
     */
    function _removeData(
        bytes32 _integration,
        address _vault,
        uint256 _index
    ) private {
        IntegrationDataTrackerStorage.Layout
            storage l = IntegrationDataTrackerStorage.layout();
        uint256 length = l.trackedData[_integration][_vault].length;
        require(_index < length, 'invalid index');

        l.trackedData[_integration][_vault][_index] = l.trackedData[
            _integration
        ][_vault][length - 1];
        l.trackedData[_integration][_vault].pop();
    }

    /**
     * @notice delete data
     * @param _integration used as the namespace for the data
     * @param _vault the vaultAddress
     * @param _index data index to be removed from storage
     */
    function _removeData(
        Integration _integration,
        address _vault,
        uint256 _index
    ) private {
        IntegrationDataTrackerStorage.Layout
            storage l = IntegrationDataTrackerStorage.layout();
        bytes32 key = bytes32(uint(_integration));
        uint256 length = l.trackedData[key][_vault].length;
        require(_index < length, 'invalid index');

        l.trackedData[key][_vault][_index] = l.trackedData[key][_vault][
            length - 1
        ];
        l.trackedData[key][_vault].pop();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

// Not sure if we should use an enum here because the integrations are not fixed
// We could use a keccak("IntegrationName") instead, this contract will have to be upgraded if we add a new integration
// Because solidity validates enum params at runtime
enum Integration {
    GMXRequests,
    GMXPositions,
    GMXDecreaseOrders
}

library IntegrationDataTrackerStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('valio.storage.IntegationDataTracker');

    // solhint-disable-next-line ordering
    struct Layout {
        // Integration -> vault -> data[]
        mapping(bytes32 => mapping(address => bytes[])) trackedData;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IAggregatorV3Interface {
    function description() external view returns (string memory);

    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

// solhint-disable ordering
interface IGmxOrderBook {
    function minExecutionFee() external view returns (uint256);

    function decreaseOrdersIndex(address) external view returns (uint256);

    function getSwapOrder(
        address _account,
        uint256 _orderIndex
    )
        external
        view
        returns (
            address path0,
            address path1,
            address path2,
            uint256 amountIn,
            uint256 minOut,
            uint256 triggerRatio,
            bool triggerAboveThreshold,
            bool shouldUnwrap,
            uint256 executionFee
        );

    function getIncreaseOrder(
        address _account,
        uint256 _orderIndex
    )
        external
        view
        returns (
            address purchaseToken,
            uint256 purchaseTokenAmount,
            address collateralToken,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold,
            uint256 executionFee
        );

    function getDecreaseOrder(
        address _account,
        uint256 _orderIndex
    )
        external
        view
        returns (
            address collateralToken,
            uint256 collateralDelta,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold,
            uint256 executionFee
        );

    function executeSwapOrder(address, uint256, address payable) external;

    function executeDecreaseOrder(address, uint256, address payable) external;

    function executeIncreaseOrder(address, uint256, address payable) external;

    function createDecreaseOrder(
        address _indexToken,
        uint256 _sizeDelta,
        address _collateralToken,
        uint256 _collateralDelta,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external payable;

    function updateDecreaseOrder(
        uint256 _orderIndex,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external;

    function cancelDecreaseOrder(uint256 _orderIndex) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// solhint-disable ordering
interface IGmxPositionRouter {
    struct IncreasePositionRequest {
        address account;
        address[] path;
        address indexToken;
        uint256 amountIn;
        uint256 minOut;
        uint256 sizeDelta;
        bool isLong;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 blockNumber;
        uint256 blockTime;
        bool hasCollateralInETH;
        address callbackTarget;
    }

    struct DecreasePositionRequest {
        address account;
        address[] path;
        address indexToken;
        uint256 collateralDelta;
        uint256 sizeDelta;
        bool isLong;
        address receiver;
        uint256 acceptablePrice;
        uint256 minOut;
        uint256 executionFee;
        uint256 blockNumber;
        uint256 blockTime;
        bool withdrawETH;
        address callbackTarget;
    }

    function setPositionKeeper(address _account, bool _isActive) external;

    function executeIncreasePosition(
        bytes32 _key,
        address payable _executionFeeReceiver
    ) external returns (bool);

    function executeDecreasePosition(
        bytes32 _key,
        address payable _executionFeeReceiver
    ) external returns (bool);

    function createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable returns (bytes32);

    function createDecreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        bool _withdrawETH,
        address _callbackTarget
    ) external payable returns (bytes32);

    function minExecutionFee() external view returns (uint256);

    function getRequestKey(
        address _account,
        uint256 _index
    ) external pure returns (bytes32);

    function cancelIncreasePosition(
        bytes32 _key,
        address payable _executionFeeReceiver
    ) external returns (bool);

    function cancelDecreasePosition(
        bytes32 _key,
        address payable _executionFeeReceiver
    ) external returns (bool);

    function executeIncreasePositions(
        uint256 _count,
        address payable _executionFeeReceiver
    ) external;

    function executeDecreasePositions(
        uint256 _count,
        address payable _executionFeeReceiver
    ) external;

    function increasePositionRequestKeysStart() external view returns (uint256);

    function decreasePositionRequestKeysStart() external view returns (uint256);

    function increasePositionsIndex(
        address account
    ) external view returns (uint256);

    function increasePositionRequests(
        bytes32 key
    )
        external
        view
        returns (
            address account,
            // address[] memory path,
            address indexToken,
            uint256 amountIn,
            uint256 minOut,
            uint256 sizeDelta,
            bool isLong,
            uint256 acceptablePrice,
            uint256 executionFee,
            uint256 blockNumber,
            uint256 blockTime,
            bool hasCollateralInETH,
            address callbackTarget
        );

    function getIncreasePositionRequestPath(
        bytes32 _key
    ) external view returns (address[] memory);

    function getDecreasePositionRequestPath(
        bytes32 _key
    ) external view returns (address[] memory);

    function decreasePositionsIndex(
        address account
    ) external view returns (uint256);

    function vault() external view returns (address);

    function admin() external view returns (address);

    function getRequestQueueLengths()
        external
        view
        returns (uint256, uint256, uint256, uint256);

    function decreasePositionRequests(
        bytes32
    )
        external
        view
        returns (
            address account,
            address indexToken,
            uint256 collateralDelta,
            uint256 sizeDelta,
            bool isLong,
            address receiver,
            uint256 acceptablePrice,
            uint256 minOut,
            uint256 executionFee,
            uint256 blockNumber,
            uint256 blockTime,
            bool withdrawETH,
            address callbackTarget
        );
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IGmxPositionRouterCallbackReceiver {
    function gmxPositionCallback(
        bytes32 positionKey,
        bool isExecuted,
        bool isIncrease
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IGmxRouter {
    function addPlugin(address _plugin) external;

    function pluginTransfer(
        address _token,
        address _account,
        address _receiver,
        uint256 _amount
    ) external;

    function pluginIncreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external;

    function pluginDecreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) external returns (uint256);

    function swap(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        address _receiver
    ) external;

    function directPoolDeposit(address _token, uint256 _amount) external;

    function approvePlugin(address) external;

    function decreasePosition(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _price
    ) external;

    function swapETHToTokens(
        address[] memory _path,
        uint256 _minOut,
        address _receiver
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// solhint-disable ordering
interface IGmxVault {
    function maxGasPrice() external view returns (uint256);

    function approvedRouters(
        address _account,
        address _router
    ) external view returns (bool);

    function isLiquidator(address _account) external view returns (bool);

    function isManager(address _account) external view returns (bool);

    function minProfitBasisPoints(
        address _token
    ) external view returns (uint256);

    function tokenBalances(address _token) external view returns (uint256);

    function lastFundingTimes(address _token) external view returns (uint256);

    function setLiquidator(address _liquidator, bool _isActive) external;

    function setFundingRate(
        uint256 _fundingInterval,
        uint256 _fundingRateFactor,
        uint256 _stableFundingRateFactor
    ) external;

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external;

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _redemptionBps,
        uint256 _minProfitBps,
        uint256 _maxUsdgAmount,
        bool _isStable,
        bool _isShortable
    ) external;

    function setPriceFeed(address _aggregatorAddress) external;

    function withdrawFees(
        address _token,
        address _receiver
    ) external returns (uint256);

    function directPoolDeposit(address _token) external;

    function buyUSDG(
        address _token,
        address _receiver
    ) external returns (uint256);

    function sellUSDG(
        address _token,
        address _receiver
    ) external returns (uint256);

    function swap(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    ) external returns (uint256);

    function increasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external;

    function decreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) external returns (uint256);

    function validateLiquidation(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        bool _raise
    ) external view returns (uint256, uint256);

    function liquidatePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        address _feeReceiver
    ) external;

    function tokenToUsdMin(
        address _token,
        uint256 _tokenAmount
    ) external view returns (uint256);

    function usdToTokenMax(
        address _token,
        uint256 _usdAmount
    ) external view returns (uint256);

    function priceFeed() external view returns (address);

    function fundingRateFactor() external view returns (uint256);

    function stableFundingRateFactor() external view returns (uint256);

    function cumulativeFundingRates(
        address _token
    ) external view returns (uint256);

    function getNextFundingRate(address _token) external view returns (uint256);

    function getFeeBasisPoints(
        address _token,
        uint256 _usdgDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);

    function liquidationFeeUsd() external view returns (uint256);

    function taxBasisPoints() external view returns (uint256);

    function stableTaxBasisPoints() external view returns (uint256);

    function mintBurnFeeBasisPoints() external view returns (uint256);

    function swapFeeBasisPoints() external view returns (uint256);

    function stableSwapFeeBasisPoints() external view returns (uint256);

    function marginFeeBasisPoints() external view returns (uint256);

    function allWhitelistedTokensLength() external view returns (uint256);

    function allWhitelistedTokens(uint256) external view returns (address);

    function whitelistedTokens(address _token) external view returns (bool);

    function stableTokens(address _token) external view returns (bool);

    function shortableTokens(address _token) external view returns (bool);

    function feeReserves(address _token) external view returns (uint256);

    function globalShortSizes(address _token) external view returns (uint256);

    function globalShortAveragePrices(
        address _token
    ) external view returns (uint256);

    function maxGlobalShortSizes(
        address _token
    ) external view returns (uint256);

    function tokenDecimals(address _token) external view returns (uint256);

    function tokenWeights(address _token) external view returns (uint256);

    function guaranteedUsd(address _token) external view returns (uint256);

    function poolAmounts(address _token) external view returns (uint256);

    function bufferAmounts(address _token) external view returns (uint256);

    function reservedAmounts(address _token) external view returns (uint256);

    function usdgAmounts(address _token) external view returns (uint256);

    function maxUsdgAmounts(address _token) external view returns (uint256);

    function getRedemptionAmount(
        address _token,
        uint256 _usdgAmount
    ) external view returns (uint256);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) external view returns (bool, uint256);

    function getPositionDelta(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (bool, uint256);

    function getPositionKey(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external pure returns (bytes32);

    function getPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    )
        external
        view
        returns (
            uint256 size,
            uint256 collateral,
            uint256 averagePrice,
            uint256 entryFundingRate,
            uint256 reserveAmount,
            uint256 realisedPnl,
            bool hasRealisedProfit,
            uint256 lastIncreasedTime
        );

    function getFundingFee(
        address _token,
        uint256 _size,
        uint256 _entryFundingRate
    ) external view returns (uint256);

    function getPositionFee(uint256 _sizeDelta) external view returns (uint256);

    function PRICE_PRECISION() external view returns (uint256);

    function BASIS_POINTS_DIVISOR() external view returns (uint256);

    function setError(uint256 _errorCode, string calldata _error) external;

    function isInitialized() external view returns (bool);

    function isSwapEnabled() external view returns (bool);

    function isLeverageEnabled() external view returns (bool);

    function router() external view returns (address);

    function usdg() external view returns (address);

    function gov() external view returns (address);

    function whitelistedTokenCount() external view returns (uint256);

    function maxLeverage() external view returns (uint256);

    function minProfitTime() external view returns (uint256);

    function hasDynamicFees() external view returns (bool);

    function fundingInterval() external view returns (uint256);

    function totalTokenWeights() external view returns (uint256);

    function getTargetUsdgAmount(
        address _token
    ) external view returns (uint256);

    function inManagerMode() external view returns (bool);

    function inPrivateLiquidationMode() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISnxAddressResolver {
    function importAddresses(
        bytes32[] calldata names,
        address[] calldata destinations
    ) external;

    function rebuildCaches(address[] calldata destinations) external;

    function owner() external view returns (address);

    function getSynth(bytes32 key) external view returns (address);

    function getAddress(bytes32 name) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Bubbles up errors from delegatecall
library Call {
    function _delegate(address to, bytes memory data) internal {
        (bool success, bytes memory result) = to.delegatecall(data);

        if (!success) {
            if (result.length < 68) revert();
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }
    }

    function _call(address to, bytes memory data) internal {
        (bool success, bytes memory result) = to.call(data);

        if (!success) {
            if (result.length < 68) revert('call failed');
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library Constants {
    uint internal constant VAULT_PRECISION = 10 ** 8;
    uint internal constant BASIS_POINTS_DIVISOR = 10000;
    uint internal constant PORTION_DIVISOR = 10 ** 18;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IRedeemerEvents } from './IRedeemerEvents.sol';

interface IRedeemer is IRedeemerEvents {
    // For some assets, closing a portion directly to the user is not possible
    // Or some assets only allow the claiming all rewards to the owner (you can't claim a portion of the rewards)
    // In this case these operations have to happen first, returning those assets to the vault
    // And then being distributed to the withdrawer during normal erc20 withdraw processing
    // A good example of this is with GMX, where sometimes we will have to close the entire position to the vault
    // And then distribute a portion of the proceeds downstream to the withdrawer.
    // The function of having preWithdraw saves us the drama of having to try and ORDER asset withdraws.
    function preWithdraw(
        uint tokenId,
        address asset,
        address withdrawer,
        uint portion
    ) external payable;

    function withdraw(
        uint tokenId,
        address asset,
        address withdrawer,
        uint portion
    ) external payable;

    function hasPreWithdraw() external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IRedeemerEvents {
    event Redeemed(
        uint tokenId,
        address indexed asset,
        address to,
        address redeemedAs,
        uint amount
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import { Accountant } from '../Accountant.sol';
import { ITransport } from '../transport/ITransport.sol';
import { ExecutorIntegration } from '../executors/IExecutor.sol';
import { IntegrationDataTracker } from '../integration-data-tracker/IntegrationDataTracker.sol';
import { RegistryStorage } from './RegistryStorage.sol';
import { GmxConfig } from '../GmxConfig.sol';
import { SnxConfig } from '../SnxConfig.sol';
import { Transport } from '../transport/Transport.sol';
import { Constants } from '../lib/Constants.sol';
import { VaultRiskProfile } from '../vault-base/IVaultRiskProfile.sol';
import { SafeOwnable } from '@solidstate/contracts/access/ownable/SafeOwnable.sol';

import { IAggregatorV3Interface } from '../interfaces/IAggregatorV3Interface.sol';
import { IValioCustomAggregator } from '../aggregators/IValioCustomAggregator.sol';

import { ILayerZeroEndpoint } from '@layerzerolabs/solidity-examples/contracts/interfaces/ILayerZeroEndpoint.sol';

import { Pausable } from '@solidstate/contracts/security/Pausable.sol';

import { VaultRiskProfile } from '../vault-base/IVaultRiskProfile.sol';

import { IUniswapV3Pool } from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

contract Registry is SafeOwnable, Pausable {
    // Emit event that informs that the other event was emitted on the target address
    event EventEmitted(address target);

    event AssetTypeChanged(address asset, RegistryStorage.AssetType assetType);
    event AssetDeprecationChanged(address asset, bool deprecated);
    event AssetHardDeprecationChanged(address asset, bool deprecated);

    modifier onlyTransport() {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        require(address(l.transport) == msg.sender, 'not transport');
        _;
    }

    modifier onlyVault() {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        require(
            l.parentVaults[msg.sender] || l.childVaults[msg.sender],
            'not vault'
        );
        _;
    }

    function initialize(
        uint16 _chainId,
        address _protocolTreasury,
        address payable _transport,
        address _parentVaultDiamond,
        address _childVaultDiamond,
        address _accountant,
        address _integrationDataTracker
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        require(l.chainId == 0, 'Already initialized');
        l.chainId = _chainId;
        l.protocolTreasury = _protocolTreasury;
        l.transport = Transport(_transport);
        l.parentVaultDiamond = _parentVaultDiamond;
        l.childVaultDiamond = _childVaultDiamond;
        l.accountant = Accountant(_accountant);
        l.integrationDataTracker = IntegrationDataTracker(
            _integrationDataTracker
        );
        l.chainlinkTimeout = 24 hours;
    }

    /// MODIFIERS

    function emitEvent() external {
        _emitEvent(msg.sender);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function addVaultParent(address vault) external onlyTransport {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.parentVaults[vault] = true;
        l.parentVaultList.push(vault);
    }

    function addVaultChild(address vault) external onlyTransport {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.childVaults[vault] = true;
        l.childVaultList.push(vault);
    }

    function setDeprecatedAsset(
        address asset,
        bool deprecated
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.deprecatedAssets[asset] = deprecated;
        emit AssetDeprecationChanged(asset, deprecated);
        _emitEvent(address(this));
    }

    function setHardDeprecatedAsset(
        address asset,
        bool deprecated
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.hardDeprecatedAssets[asset] = deprecated;
        emit AssetHardDeprecationChanged(asset, deprecated);
        _emitEvent(address(this));
    }

    function setAssetType(
        address asset,
        RegistryStorage.AssetType _assetType
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.assetTypes[asset] = _assetType;
        l.assetList.push(asset);
        emit AssetTypeChanged(asset, _assetType);
        _emitEvent(address(this));
    }

    function setValuer(
        RegistryStorage.AssetType _assetType,
        address valuer
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.valuers[_assetType] = valuer;
    }

    function setRedeemer(
        RegistryStorage.AssetType _assetType,
        address redeemer
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.redeemers[_assetType] = redeemer;
    }

    function setChainlinkV3USDAggregator(
        address asset,
        IAggregatorV3Interface aggregator
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.chainlinkV3USDAggregators[asset] = aggregator;
    }

    function setValioCustomUSDAggregator(
        RegistryStorage.AggregatorType _aggregatorType,
        IValioCustomAggregator _customAggregator
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.valioCustomUSDAggregators[_aggregatorType] = _customAggregator;
    }

    function setAccountant(address _accountant) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.accountant = Accountant(_accountant);
    }

    function setTransport(address payable _transport) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.transport = Transport(_transport);
    }

    function setProtocolTreasury(address payable _treasury) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.protocolTreasury = (_treasury);
    }

    function setProtocolFeeBips(uint256 _protocolFeeBips) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.protocolFeeBips = _protocolFeeBips;
    }

    function setIntegrationDataTracker(
        address _integrationDataTracker
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.integrationDataTracker = IntegrationDataTracker(
            _integrationDataTracker
        );
    }

    function setZeroXExchangeRouter(
        address _zeroXExchangeRouter
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.zeroXExchangeRouter = _zeroXExchangeRouter;
    }

    function setExecutor(
        ExecutorIntegration integration,
        address executor
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.executors[integration] = executor;
    }

    function setDepositLockupTime(uint _depositLockupTime) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.depositLockupTime = _depositLockupTime;
    }

    function setMaxActiveAssets(uint _maxActiveAssets) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.maxActiveAssets = _maxActiveAssets;
    }

    function setCanChangeManager(bool _canChangeManager) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.canChangeManager = _canChangeManager;
    }

    function setGmxConfig(address _gmxConfig) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.gmxConfig = GmxConfig(_gmxConfig);
    }

    function setLivelinessThreshold(
        uint256 _livelinessThreshold
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.livelinessThreshold = _livelinessThreshold;
    }

    function setMaxCpitBips(
        VaultRiskProfile riskProfile,
        uint256 _maxCpitBips
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.maxCpitBips[riskProfile] = _maxCpitBips;
    }

    function setMinDepositAmount(uint256 _minDepositAmount) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.minDepositAmount = _minDepositAmount;
    }

    function setMaxDepositAmount(uint256 _maxDepositAmount) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.maxDepositAmount = _maxDepositAmount;
    }

    function setCanChangeManagerFees(
        bool _canChangeManagerFees
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.canChangeManagerFees = _canChangeManagerFees;
    }

    function setDepositAsset(
        address _depositAsset,
        bool canDeposit
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.depositAssets[_depositAsset] = canDeposit;
    }

    function setVaultValueCap(uint256 _vaultValueCap) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.vaultValueCap = _vaultValueCap;
    }

    function setWithdrawAutomator(
        address _withdrawAutomator
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.withdrawAutomator = _withdrawAutomator;
    }

    function setDepositAutomator(address _depositAutomator) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.depositAutomator = _depositAutomator;
    }

    function setAssetAggregatorType(
        address asset,
        RegistryStorage.AggregatorType aggregatorType
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.assetAggregatorType[asset] = aggregatorType;
    }

    function setSnxConfig(address _snxConfig) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.snxConfig = SnxConfig(_snxConfig);
    }

    function setSnxPerpsV2Erc20WrapperDiamond(
        address _snxPerpsV2Erc20WrapperDiamond
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.snxPerpsV2Erc20WrapperDiamond = _snxPerpsV2Erc20WrapperDiamond;
    }

    function setCustomVaultValueCap(
        address vault,
        uint256 _customVaultValueCap
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.customVaultValueCaps[vault] = _customVaultValueCap;
    }

    // Allows us to store All wrappers for offchain use
    function addSnxPerpsV2Erc20Wrapper(
        address wrapperAddress
    ) external onlyVault {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.snxPerpsV2Erc20WrapperList.push(wrapperAddress);
    }

    function setV3Pool(address asset, IUniswapV3Pool pool) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        address pairToken = pool.token0();
        if (asset == pairToken) {
            pairToken = pool.token1();
        }
        // Must have a chainlink aggregator for the pairedToken
        require(
            address(l.chainlinkV3USDAggregators[pairToken]) != address(0),
            'no pair aggregator'
        );

        l.assetToUniV3PoolConfig[asset] = RegistryStorage.V3PoolConfig(
            pool,
            pairToken
        );
    }

    /// VIEWS

    function v3PoolConfig(
        address asset
    ) external view returns (RegistryStorage.V3PoolConfig memory) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.assetToUniV3PoolConfig[asset];
    }

    function snxPerpsV2Erc20WrapperList()
        external
        view
        returns (address[] memory)
    {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.snxPerpsV2Erc20WrapperList;
    }

    function customVaultValueCap(
        address vault
    ) external view returns (uint256) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.customVaultValueCaps[vault];
    }

    function protocolFeeBips() external view returns (uint256) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.protocolFeeBips;
    }

    function depositAutomator() external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.depositAutomator;
    }

    function withdrawAutomator() external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.withdrawAutomator;
    }

    function vaultValueCap() external view returns (uint256) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.vaultValueCap;
    }

    function maxCpitBips(
        VaultRiskProfile riskProfile
    ) external view returns (uint256) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.maxCpitBips[riskProfile];
    }

    function parentVaultDiamond() external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.parentVaultDiamond;
    }

    function childVaultDiamond() external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.childVaultDiamond;
    }

    function chainId() external view returns (uint16) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.chainId;
    }

    function protocolTreasury() external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.protocolTreasury;
    }

    function isVault(address vault) external view returns (bool) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.parentVaults[vault] || l.childVaults[vault];
    }

    function isVaultParent(address vault) external view returns (bool) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.parentVaults[vault];
    }

    function isVaultChild(address vault) external view returns (bool) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.childVaults[vault];
    }

    function executors(
        ExecutorIntegration integration
    ) external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.executors[integration];
    }

    function redeemers(address asset) external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.redeemers[l.assetTypes[asset]];
    }

    function redeemerByType(
        RegistryStorage.AssetType _assetType
    ) external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.redeemers[_assetType];
    }

    function valuers(address asset) external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.valuers[l.assetTypes[asset]];
    }

    function valuerByType(
        RegistryStorage.AssetType _assetType
    ) external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.valuers[_assetType];
    }

    function deprecatedAssets(address asset) external view returns (bool) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.deprecatedAssets[asset];
    }

    function hardDeprecatedAssets(address asset) external view returns (bool) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.hardDeprecatedAssets[asset];
    }

    function depositAssets(address asset) external view returns (bool) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.depositAssets[asset];
    }

    function chainlinkV3USDAggregators(
        address asset
    ) external view returns (IAggregatorV3Interface) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.chainlinkV3USDAggregators[asset];
    }

    function valioCustomUSDAggregators(
        RegistryStorage.AggregatorType aggregatorType
    ) external view returns (IValioCustomAggregator) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.valioCustomUSDAggregators[aggregatorType];
    }

    function maxActiveAssets() external view returns (uint256) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.maxActiveAssets;
    }

    function chainlinkTimeout() external view returns (uint256) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.chainlinkTimeout;
    }

    function depositLockupTime() external view returns (uint256) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.depositLockupTime;
    }

    function minDepositAmount() external view returns (uint256) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.minDepositAmount;
    }

    function maxDepositAmount() external view returns (uint256) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.maxDepositAmount;
    }

    function canChangeManager() external view returns (bool) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.canChangeManager;
    }

    function canChangeManagerFees() external view returns (bool) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.canChangeManagerFees;
    }

    function livelinessThreshold() external view returns (uint256) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.livelinessThreshold;
    }

    function zeroXExchangeRouter() external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.zeroXExchangeRouter;
    }

    function vaultParentList() external view returns (address[] memory) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.parentVaultList;
    }

    function vaultChildList() external view returns (address[] memory) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.childVaultList;
    }

    function assetList() external view returns (address[] memory) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.assetList;
    }

    function assetAggregatorType(
        address asset
    ) external view returns (RegistryStorage.AggregatorType) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.assetAggregatorType[asset];
    }

    function assetType(
        address asset
    ) external view returns (RegistryStorage.AssetType) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.assetTypes[asset];
    }

    // Contracts

    function integrationDataTracker()
        external
        view
        returns (IntegrationDataTracker)
    {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.integrationDataTracker;
    }

    function snxPerpsV2Erc20WrapperDiamond() external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.snxPerpsV2Erc20WrapperDiamond;
    }

    function gmxConfig() external view returns (GmxConfig) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.gmxConfig;
    }

    function snxConfig() external view returns (SnxConfig) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.snxConfig;
    }

    function accountant() external view returns (Accountant) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.accountant;
    }

    function transport() external view returns (Transport) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.transport;
    }

    function VAULT_PRECISION() external pure returns (uint256) {
        return Constants.VAULT_PRECISION;
    }

    function _emitEvent(address caller) internal {
        emit EventEmitted(caller);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { Accountant } from '../Accountant.sol';
import { Transport } from '../transport/Transport.sol';
import { ExecutorIntegration } from '../executors/IExecutor.sol';

import { VaultRiskProfile } from '../vault-base/IVaultRiskProfile.sol';

import { IntegrationDataTracker } from '../integration-data-tracker/IntegrationDataTracker.sol';
import { GmxConfig } from '../GmxConfig.sol';
import { SnxConfig } from '../SnxConfig.sol';
import { ILayerZeroEndpoint } from '@layerzerolabs/solidity-examples/contracts/interfaces/ILayerZeroEndpoint.sol';
import { IAggregatorV3Interface } from '../interfaces/IAggregatorV3Interface.sol';
import { IValioCustomAggregator } from '../aggregators/IValioCustomAggregator.sol';

import { IUniswapV3Pool } from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

library RegistryStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('valio.storage.Registry');

    // Cannot use struct with diamond storage,
    // as adding any extra storage slots will break the following already declared members
    // solhint-disable-next-line ordering
    struct VaultSettings {
        bool ___deprecated;
        uint ____deprecated;
        uint _____deprecated;
        uint ______deprecated;
    }

    // solhint-disable-next-line ordering
    enum AssetType {
        None,
        GMX,
        Erc20,
        SnxPerpsV2
    }

    // solhint-disable-next-line ordering
    enum AggregatorType {
        ChainlinkV3USD,
        UniswapV3Twap,
        VelodromeV2Twap,
        None // Things like gmx return a value in usd so no aggregator is needed
    }

    struct V3PoolConfig {
        IUniswapV3Pool pool;
        address pairToken;
    }

    // solhint-disable-next-line ordering
    struct Layout {
        uint16 chainId;
        address protocolTreasury;
        address parentVaultDiamond;
        address childVaultDiamond;
        mapping(address => bool) parentVaults;
        mapping(address => bool) childVaults;
        VaultSettings _deprecated;
        Accountant accountant;
        Transport transport;
        IntegrationDataTracker integrationDataTracker;
        GmxConfig gmxConfig;
        mapping(ExecutorIntegration => address) executors;
        // Price get will revert if the price hasn't be updated in the below time
        uint256 chainlinkTimeout;
        mapping(AssetType => address) valuers;
        mapping(AssetType => address) redeemers;
        mapping(address => AssetType) assetTypes;
        // All must return USD price and be 8 decimals
        mapping(address => IAggregatorV3Interface) chainlinkV3USDAggregators;
        mapping(address => bool) deprecatedAssets; // Assets that cannot be traded into, only out of
        address zeroXExchangeRouter;
        uint DEPRECATED_zeroXMaximumSingleSwapPriceImpactBips;
        bool canChangeManager;
        // The number of assets that can be active at once for a vault
        // This is important so withdraw processing doesn't consume > max gas
        uint maxActiveAssets;
        uint depositLockupTime;
        uint livelinessThreshold;
        mapping(VaultRiskProfile => uint) maxCpitBips;
        uint DEPRECATED_maxSingleActionImpactBips;
        uint minDepositAmount;
        bool canChangeManagerFees;
        // Assets that can be deposited into the vault
        mapping(address => bool) depositAssets;
        uint vaultValueCap;
        bool DEPRECATED_managerWhitelistEnabled;
        mapping(address => bool) DEPRECATED_allowedManagers;
        bool DEPRECATED_investorWhitelistEnabled;
        mapping(address => bool) DEPRECATED_allowedInvestors;
        address withdrawAutomator;
        mapping(address => IValioCustomAggregator) DEPRECATED_valioCustomUSDAggregators;
        address[] parentVaultList;
        address[] childVaultList;
        address[] assetList;
        uint maxDepositAmount;
        uint protocolFeeBips;
        mapping(address => AggregatorType) assetAggregatorType;
        // All must return USD price and be 8 decimals
        mapping(AggregatorType => IValioCustomAggregator) valioCustomUSDAggregators;
        address depositAutomator;
        SnxConfig snxConfig;
        address snxPerpsV2Erc20WrapperDiamond;
        mapping(address => uint) customVaultValueCaps;
        address[] snxPerpsV2Erc20WrapperList;
        // hardDeprecatedAssets Assets will return a value of 0
        // hardDeprecatedAssets Assets that cannot be traded into, only out of
        // A vault holding hardDeprecatedAssets will not be able be deposited into
        mapping(address => bool) hardDeprecatedAssets;
        mapping(address => V3PoolConfig) assetToUniV3PoolConfig;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { ISnxAddressResolver } from './interfaces/ISnxAddressResolver.sol';

contract SnxConfig {
    bytes32 public immutable trackingCode;
    ISnxAddressResolver public immutable addressResolver;
    address public immutable perpsV2MarketData;
    uint8 public immutable maxPerpPositions;

    constructor(
        address _addressResolver,
        address _perpsV2MarketData,
        bytes32 _snxTrackingCode,
        uint8 _maxPerpPositions
    ) {
        addressResolver = ISnxAddressResolver(_addressResolver);
        // https://github.com/Synthetixio/synthetix/blob/master/contracts/PerpsV2MarketData.sol
        perpsV2MarketData = _perpsV2MarketData;
        trackingCode = _snxTrackingCode;
        maxPerpPositions = _maxPerpPositions;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IStargateRouter } from '@layerzerolabs/solidity-examples/contracts/interfaces/IStargateRouter.sol';
import { VaultRiskProfile } from '../vault-base/IVaultRiskProfile.sol';

enum GasFunctionType {
    standardNoReturnMessage,
    createChildRequiresReturnMessage,
    getVaultValueRequiresReturnMessage,
    withdrawRequiresReturnMessage,
    sgReceiveRequiresReturnMessage,
    sendBridgeApprovalNoReturnMessage,
    childCreatedNoReturnMessage
}

interface ITransport {
    struct SGReceivePayload {
        address dstVault;
        address srcVault;
        uint16 parentChainId;
        address parentVault;
    }

    struct SGBridgedAssetReceivedAcknoledgementRequest {
        uint16 parentChainId;
        address parentVault;
        uint16 receivingChainId;
    }

    struct ChildVault {
        uint16 chainId;
        address vault;
    }

    struct VaultChildCreationRequest {
        address parentVault;
        uint16 parentChainId;
        uint16 newChainId;
        address manager;
        VaultRiskProfile riskProfile;
        ChildVault[] children;
    }

    struct ChildCreatedRequest {
        address parentVault;
        uint16 parentChainId;
        ChildVault newChild;
    }

    struct AddVaultSiblingRequest {
        ChildVault child;
        ChildVault newSibling;
    }

    struct BridgeApprovalRequest {
        uint16 approvedChainId;
        address approvedVault;
    }

    struct BridgeApprovalCancellationRequest {
        uint16 parentChainId;
        address parentVault;
        address requester;
    }

    struct ValueUpdateRequest {
        uint16 parentChainId;
        address parentVault;
        ChildVault child;
    }

    struct ValueUpdatedRequest {
        uint16 parentChainId;
        address parentVault;
        ChildVault child;
        uint time;
        uint minValue;
        uint maxValue;
        bool hasHardDepreactedAsset;
    }

    struct WithdrawRequest {
        uint16 parentChainId;
        address parentVault;
        ChildVault child;
        uint tokenId;
        address withdrawer;
        uint portion;
    }

    struct WithdrawComplete {
        uint16 parentChainId;
        address parentVault;
    }

    struct ChangeManagerRequest {
        ChildVault child;
        address newManager;
    }

    event VaultChildCreated(address target);
    event VaultParentCreated(address target);

    receive() external payable;

    function addSibling(AddVaultSiblingRequest memory request) external;

    function bridgeApproval(BridgeApprovalRequest memory request) external;

    function bridgeApprovalCancellation(
        BridgeApprovalCancellationRequest memory request
    ) external;

    function bridgeAsset(
        uint16 dstChainId,
        address dstVault,
        uint16 parentChainId,
        address parentVault,
        address bridgeToken,
        uint256 amount,
        uint256 minAmountOut
    ) external payable;

    function childCreated(ChildCreatedRequest memory request) external;

    function createVaultChild(
        VaultChildCreationRequest memory request
    ) external;

    function createParentVault(
        string memory name,
        string memory symbol,
        address manager,
        uint streamingFee,
        uint performanceFee,
        VaultRiskProfile riskProfile
    ) external payable returns (address deployment);

    function sendChangeManagerRequest(
        ChangeManagerRequest memory request
    ) external payable;

    function sendAddSiblingRequest(
        AddVaultSiblingRequest memory request
    ) external;

    function sendBridgeApproval(
        BridgeApprovalRequest memory request
    ) external payable;

    function sendBridgeApprovalCancellation(
        BridgeApprovalCancellationRequest memory request
    ) external payable;

    function sendVaultChildCreationRequest(
        VaultChildCreationRequest memory request
    ) external payable;

    function sendWithdrawRequest(
        WithdrawRequest memory request
    ) external payable;

    function sendValueUpdateRequest(
        ValueUpdateRequest memory request
    ) external payable;

    function updateVaultValue(ValueUpdatedRequest memory request) external;

    function getLzFee(
        GasFunctionType gasFunctionType,
        uint16 dstChainId
    ) external returns (uint256 sendFee, bytes memory adapterParams);

    // onlyThis
    function changeManager(ChangeManagerRequest memory request) external;

    function withdraw(WithdrawRequest memory request) external;

    function withdrawComplete(WithdrawComplete memory request) external;

    function getVaultValue(ValueUpdateRequest memory request) external;

    function sgBridgedAssetReceived(
        SGBridgedAssetReceivedAcknoledgementRequest memory request
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import { TransportReceive } from './TransportReceive.sol';
import { TransportStargate } from './TransportStargate.sol';

contract Transport is TransportReceive, TransportStargate {}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import { ITransport } from './ITransport.sol';
import { VaultParentProxy } from '../vault-parent/VaultParentProxy.sol';
import { VaultParent } from '../vault-parent/VaultParent.sol';

import { VaultBaseExternal } from '../vault-base/VaultBaseExternal.sol';
import { VaultRiskProfile } from '../vault-base/IVaultRiskProfile.sol';
import { Accountant } from '../Accountant.sol';
import { Registry } from '../registry/Registry.sol';
import { TransportStorage } from './TransportStorage.sol';
import { GasFunctionType } from './ITransport.sol';

import { ILayerZeroEndpoint } from '@layerzerolabs/solidity-examples/contracts/interfaces/ILayerZeroEndpoint.sol';

import { SafeOwnable } from '@solidstate/contracts/access/ownable/SafeOwnable.sol';

import { Call } from '../lib/Call.sol';

abstract contract TransportBase is SafeOwnable, ITransport {
    modifier onlyVault() {
        require(_registry().isVault(msg.sender), 'not child vault');
        _;
    }

    modifier whenNotPaused() {
        require(!_registry().paused(), 'paused');
        _;
    }

    receive() external payable {}

    function initialize(
        address __registry,
        address __lzEndpoint,
        address __stargateRouter
    ) external onlyOwner {
        TransportStorage.Layout storage l = TransportStorage.layout();
        l.registry = Registry(__registry);
        l.lzEndpoint = ILayerZeroEndpoint(__lzEndpoint);
        l.stargateRouter = __stargateRouter;
    }

    function createParentVault(
        string memory name,
        string memory symbol,
        address manager,
        uint streamingFee,
        uint performanceFee,
        VaultRiskProfile riskProfile
    ) external payable whenNotPaused returns (address deployment) {
        require(msg.value >= _vaultCreationFee(), 'insufficient fee');
        (bool sent, ) = _registry().protocolTreasury().call{ value: msg.value }(
            ''
        );
        require(sent, 'Failed to process create vault fee');
        return
            _createParentVault(
                name,
                symbol,
                manager,
                streamingFee,
                performanceFee,
                riskProfile
            );
    }

    function setTrustedRemoteAddress(
        uint16 _remoteChainId,
        bytes calldata _remoteAddress
    ) external onlyOwner {
        TransportStorage.Layout storage l = TransportStorage.layout();
        l.trustedRemoteLookup[_remoteChainId] = abi.encodePacked(
            _remoteAddress,
            address(this)
        );
    }

    function setSGAssetToSrcPoolId(
        address asset,
        uint poolId
    ) external onlyOwner {
        TransportStorage.Layout storage l = TransportStorage.layout();
        l.stargateAssetToSrcPoolId[asset] = poolId;
    }

    function setSGAssetToDstPoolId(
        uint16 chainId,
        address asset,
        uint poolId
    ) external onlyOwner {
        TransportStorage.Layout storage l = TransportStorage.layout();
        l.stargateAssetToDstPoolId[chainId][asset] = poolId;
    }

    function setGasUsage(
        uint16 chainId,
        GasFunctionType gasUsageType,
        uint gas
    ) external onlyOwner {
        TransportStorage.Layout storage l = TransportStorage.layout();
        l.gasUsage[chainId][gasUsageType] = gas;
    }

    function setReturnMessageCost(uint16 chainId, uint cost) external {
        TransportStorage.Layout storage l = TransportStorage.layout();
        l.returnMessageCosts[chainId] = cost;
    }

    function setBridgeApprovalCancellationTime(uint time) external onlyOwner {
        TransportStorage.Layout storage l = TransportStorage.layout();
        l.bridgeApprovalCancellationTime = time;
    }

    function setVaultCreationFee(uint fee) external onlyOwner {
        TransportStorage.Layout storage l = TransportStorage.layout();
        l.vaultCreationFee = fee;
    }

    function registry() external view returns (Registry) {
        return _registry();
    }

    function bridgeApprovalCancellationTime() external view returns (uint256) {
        return _bridgeApprovalCancellationTime();
    }

    function lzEndpoint() external view returns (ILayerZeroEndpoint) {
        return _lzEndpoint();
    }

    function trustedRemoteLookup(
        uint16 remoteChainId
    ) external view returns (bytes memory) {
        return _trustedRemoteLookup(remoteChainId);
    }

    function stargateRouter() external view returns (address) {
        return _stargateRouter();
    }

    function stargateAssetToDstPoolId(
        uint16 dstChainId,
        address srcBridgeToken
    ) external view returns (uint256) {
        return _stargateAssetToDstPoolId(dstChainId, srcBridgeToken);
    }

    function stargateAssetToSrcPoolId(
        address bridgeToken
    ) external view returns (uint256) {
        return _stargateAssetToSrcPoolId(bridgeToken);
    }

    function getGasUsage(
        uint16 chainId,
        GasFunctionType gasFunctionType
    ) external view returns (uint) {
        return _destinationGasUsage(chainId, gasFunctionType);
    }

    function returnMessageCost(uint16 chainId) external view returns (uint) {
        return _returnMessageCost(chainId);
    }

    function vaultCreationFee() external view returns (uint) {
        return _vaultCreationFee();
    }

    // For backwards compatibility use to be a constant
    function CREATE_VAULT_FEE() external view returns (uint) {
        return _vaultCreationFee();
    }

    /// Create Parent Vault
    function _createParentVault(
        string memory name,
        string memory symbol,
        address manager,
        uint streamingFee,
        uint performanceFee,
        VaultRiskProfile riskProfile
    ) internal returns (address deployment) {
        require(
            _registry().parentVaultDiamond() != address(0),
            'not parent chain'
        );

        deployment = address(
            new VaultParentProxy(_registry().parentVaultDiamond())
        );

        VaultParent(payable(deployment)).initialize(
            name,
            symbol,
            manager,
            streamingFee,
            performanceFee,
            riskProfile,
            _registry()
        );

        _registry().addVaultParent(deployment);

        emit VaultParentCreated(deployment);
        _registry().emitEvent();
    }

    function _stargateAssetToSrcPoolId(
        address bridgeToken
    ) internal view returns (uint256) {
        TransportStorage.Layout storage l = TransportStorage.layout();
        return l.stargateAssetToSrcPoolId[bridgeToken];
    }

    function _stargateAssetToDstPoolId(
        uint16 dstChainId,
        address srcBridgeToken
    ) internal view returns (uint256) {
        TransportStorage.Layout storage l = TransportStorage.layout();
        return l.stargateAssetToDstPoolId[dstChainId][srcBridgeToken];
    }

    function _bridgeApprovalCancellationTime() internal view returns (uint256) {
        TransportStorage.Layout storage l = TransportStorage.layout();
        return l.bridgeApprovalCancellationTime;
    }

    function _trustedRemoteLookup(
        uint16 remoteChainId
    ) internal view returns (bytes memory) {
        TransportStorage.Layout storage l = TransportStorage.layout();
        return l.trustedRemoteLookup[remoteChainId];
    }

    function _lzEndpoint() internal view returns (ILayerZeroEndpoint) {
        TransportStorage.Layout storage l = TransportStorage.layout();
        return l.lzEndpoint;
    }

    function _stargateRouter() internal view returns (address) {
        TransportStorage.Layout storage l = TransportStorage.layout();
        return l.stargateRouter;
    }

    function _destinationGasUsage(
        uint16 chainId,
        GasFunctionType gasFunctionType
    ) internal view returns (uint) {
        TransportStorage.Layout storage l = TransportStorage.layout();
        return l.gasUsage[chainId][gasFunctionType];
    }

    function _registry() internal view returns (Registry) {
        TransportStorage.Layout storage l = TransportStorage.layout();
        return l.registry;
    }

    function _returnMessageCost(uint16 chainId) internal view returns (uint) {
        TransportStorage.Layout storage l = TransportStorage.layout();
        return l.returnMessageCosts[chainId];
    }

    function _vaultCreationFee() internal view returns (uint) {
        TransportStorage.Layout storage l = TransportStorage.layout();
        return l.vaultCreationFee;
    }

    function _getTrustedRemoteDestination(
        uint16 dstChainId
    ) internal view returns (address dstAddr) {
        bytes memory trustedRemote = _trustedRemoteLookup(dstChainId);
        require(
            trustedRemote.length != 0,
            'LzApp: destination chain is not a trusted source'
        );
        assembly {
            dstAddr := mload(add(trustedRemote, 20))
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import { VaultChildProxy } from '../vault-child/VaultChildProxy.sol';
import { VaultChild } from '../vault-child/VaultChild.sol';
import { VaultParent } from '../vault-parent/VaultParent.sol';
import { VaultRiskProfile } from '../vault-base/IVaultRiskProfile.sol';

import { ILayerZeroReceiver } from '@layerzerolabs/solidity-examples/contracts/interfaces/ILayerZeroReceiver.sol';

import { TransportBase, ITransport } from './TransportBase.sol';
import { TransportSend } from './TransportSend.sol';

import { Call } from '../lib/Call.sol';

abstract contract TransportReceive is TransportSend, ILayerZeroReceiver {
    modifier onlyThis() {
        require(address(this) == msg.sender, 'not this');
        _;
    }

    function lzReceive(
        uint16 srcChainId,
        bytes calldata srcAddress,
        uint64, // nonce
        bytes calldata payload
    ) external {
        require(
            msg.sender == address(_lzEndpoint()),
            'LzApp: invalid endpoint caller'
        );

        bytes memory trustedRemote = _trustedRemoteLookup(srcChainId);
        require(
            srcAddress.length == trustedRemote.length &&
                keccak256(srcAddress) == keccak256(trustedRemote),
            'LzApp: invalid source sending contract'
        );
        Call._call(address(this), payload);
    }

    ///
    /// Message received callbacks - public onlyThis
    ///

    function bridgeApprovalCancellation(
        BridgeApprovalCancellationRequest memory request
    ) public onlyThis {
        VaultParent(payable(request.parentVault))
            .receiveBridgeApprovalCancellation(request.requester);
    }

    function bridgeApproval(
        BridgeApprovalRequest memory request
    ) public onlyThis {
        VaultChild(payable(request.approvedVault)).receiveBridgeApproval();
    }

    function withdraw(WithdrawRequest memory request) public onlyThis {
        VaultChild(payable(request.child.vault)).receiveWithdrawRequest(
            request.tokenId,
            request.withdrawer,
            request.portion
        );

        sendWithdrawComplete(
            ITransport.WithdrawComplete({
                parentChainId: request.parentChainId,
                parentVault: request.parentVault
            })
        );
    }

    function withdrawComplete(WithdrawComplete memory request) public onlyThis {
        VaultParent(payable(request.parentVault)).receiveWithdrawComplete();
    }

    function getVaultValue(ValueUpdateRequest memory request) public onlyThis {
        uint256 gasRemaining = gasleft();
        try
            // This would fail if for instance chainlink feed is stale
            // If a callback fails the message is deemed failed to deliver by LZ and is queued
            // Retrying it will likely not result in a better outcome and will block message delivery
            // For other vaults
            VaultChild(payable(request.child.vault)).getVaultValue()
        returns (uint _minValue, uint _maxValue, bool _hasHardDeprecatedAsset) {
            _sendValueUpdatedRequest(
                ValueUpdatedRequest({
                    parentChainId: request.parentChainId,
                    parentVault: request.parentVault,
                    child: request.child,
                    time: block.timestamp,
                    minValue: _minValue,
                    maxValue: _maxValue,
                    hasHardDepreactedAsset: _hasHardDeprecatedAsset
                })
            );
        } catch {
            // github.com/vertex-protocol/vertex-contracts
            // /blob/3258d58eb1e56ece0513b3efcc468cc09a7414c4/contracts/Endpoint.sol#L333
            // we need to differentiate between a revert and an out of gas
            // the expectation is that because 63/64 * gasRemaining is forwarded
            // we should be able to differentiate based on whether
            // gasleft() >= gasRemaining / 64. however, experimentally
            // even more gas can be remaining, and i don't have a clear
            // understanding as to why. as a result we just err on the
            // conservative side and provide two conservative
            // asserts that should cover all cases
            // As above in practice more than 1/64th of the gas is remaining
            // The code that executes after the try { // here } requires more than 100k gas anyway
            if (gasleft() <= 100_000 || gasleft() <= gasRemaining / 16) {
                // If we revert the message will fail to deliver and need to be retried
                // In the case of out of gas we want this message to be retried by our keeper
                revert('getVaultValue out of gas');
            }
        }
    }

    function updateVaultValue(
        ValueUpdatedRequest memory request
    ) public onlyThis {
        VaultParent(payable(request.parentVault)).receiveChildValue(
            request.child.chainId,
            request.minValue,
            request.maxValue,
            request.time,
            request.hasHardDepreactedAsset
        );
    }

    function createVaultChild(
        VaultChildCreationRequest memory request
    ) public onlyThis {
        address child = _deployChild(
            request.parentChainId,
            request.parentVault,
            request.manager,
            request.riskProfile,
            request.children
        );
        _sendChildCreatedRequest(
            ChildCreatedRequest({
                parentVault: request.parentVault,
                parentChainId: request.parentChainId,
                newChild: ChildVault({
                    chainId: _registry().chainId(),
                    vault: child
                })
            })
        );
    }

    function childCreated(ChildCreatedRequest memory request) public onlyThis {
        VaultParent(payable(request.parentVault)).receiveChildCreated(
            request.newChild.chainId,
            request.newChild.vault
        );
    }

    function addSibling(AddVaultSiblingRequest memory request) public onlyThis {
        VaultChild(payable(request.child.vault)).receiveAddSibling(
            request.newSibling.chainId,
            request.newSibling.vault
        );
    }

    function changeManager(
        ChangeManagerRequest memory request
    ) public onlyThis {
        VaultChild(payable(request.child.vault)).receiveManagerChange(
            request.newManager
        );
    }

    function sgBridgedAssetReceived(
        SGBridgedAssetReceivedAcknoledgementRequest memory request
    ) public onlyThis {
        VaultParent(payable(request.parentVault))
            .receiveBridgedAssetAcknowledgement(request.receivingChainId);
    }

    /// Deploy Child

    function _deployChild(
        uint16 parentChainId,
        address parentVault,
        address manager,
        VaultRiskProfile riskProfile,
        ITransport.ChildVault[] memory children
    ) internal whenNotPaused returns (address deployment) {
        deployment = address(
            new VaultChildProxy(_registry().childVaultDiamond())
        );
        VaultChild(payable(deployment)).initialize(
            parentChainId,
            parentVault,
            manager,
            riskProfile,
            _registry(),
            children
        );
        _registry().addVaultChild(deployment);

        emit VaultChildCreated(deployment);
        _registry().emitEvent();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import { GasFunctionType } from './ITransport.sol';
import { VaultRiskProfile } from '../vault-base/IVaultRiskProfile.sol';
import { TransportBase } from './TransportBase.sol';
import { ITransport } from './ITransport.sol';

abstract contract TransportSend is TransportBase {
    modifier onlyVaultParent() {
        require(_registry().isVaultParent(msg.sender), 'not parent vault');
        _;
    }

    modifier onlyVaultChild() {
        require(_registry().isVaultChild(msg.sender), 'not child vault');
        _;
    }

    function getLzFee(
        GasFunctionType gasFunctionType,
        uint16 dstChainId
    ) external view returns (uint256 sendFee, bytes memory adapterParams) {
        return _getLzFee(gasFunctionType, dstChainId);
    }

    ///
    /// Message senders
    ///
    // solhint-disable-next-line ordering
    function sendChangeManagerRequest(
        ChangeManagerRequest memory request
    ) external payable onlyVaultParent whenNotPaused {
        _send(
            request.child.chainId,
            abi.encodeWithSelector(ITransport.changeManager.selector, request),
            msg.value,
            _getAdapterParams(
                request.child.chainId,
                GasFunctionType.standardNoReturnMessage
            )
        );
    }

    function sendWithdrawRequest(
        WithdrawRequest memory request
    ) external payable onlyVaultParent whenNotPaused {
        _send(
            request.child.chainId,
            abi.encodeWithSelector(ITransport.withdraw.selector, request),
            msg.value,
            _getAdapterParams(
                request.child.chainId,
                GasFunctionType.withdrawRequiresReturnMessage
            )
        );
    }

    function sendBridgeApproval(
        BridgeApprovalRequest memory request
    ) external payable onlyVaultParent whenNotPaused {
        _send(
            request.approvedChainId,
            abi.encodeWithSelector(ITransport.bridgeApproval.selector, request),
            msg.value,
            _getAdapterParams(
                request.approvedChainId,
                GasFunctionType.sendBridgeApprovalNoReturnMessage
            )
        );
    }

    function sendBridgeApprovalCancellation(
        BridgeApprovalCancellationRequest memory request
    ) external payable onlyVaultChild whenNotPaused {
        _send(
            request.parentChainId,
            abi.encodeWithSelector(
                ITransport.bridgeApprovalCancellation.selector,
                request
            ),
            msg.value,
            _getAdapterParams(
                request.parentChainId,
                GasFunctionType.standardNoReturnMessage
            )
        );
    }

    function sendValueUpdateRequest(
        ValueUpdateRequest memory request
    ) external payable onlyVault whenNotPaused {
        _send(
            request.child.chainId,
            abi.encodeWithSelector(ITransport.getVaultValue.selector, request),
            msg.value,
            _getAdapterParams(
                request.child.chainId,
                GasFunctionType.getVaultValueRequiresReturnMessage
            )
        );
    }

    function sendVaultChildCreationRequest(
        VaultChildCreationRequest memory request
    ) external payable onlyVaultParent whenNotPaused {
        require(
            _getTrustedRemoteDestination(request.newChainId) != address(0),
            'unsupported destination chain'
        );
        _send(
            request.newChainId,
            abi.encodeWithSelector(
                ITransport.createVaultChild.selector,
                request
            ),
            msg.value,
            _getAdapterParams(
                request.newChainId,
                GasFunctionType.createChildRequiresReturnMessage
            )
        );
    }

    /// Return/Reply message senders

    function sendAddSiblingRequest(
        AddVaultSiblingRequest memory request
    ) external onlyVaultParent whenNotPaused {
        (uint fee, bytes memory adapterParams) = _getLzFee(
            GasFunctionType.standardNoReturnMessage,
            request.child.chainId
        );
        _send(
            request.child.chainId,
            abi.encodeWithSelector(ITransport.addSibling.selector, request),
            fee,
            adapterParams
        );
    }

    function sendWithdrawComplete(WithdrawComplete memory request) internal {
        (uint fee, bytes memory adapterParams) = _getLzFee(
            GasFunctionType.standardNoReturnMessage,
            request.parentChainId
        );
        _send(
            request.parentChainId,
            abi.encodeWithSelector(
                ITransport.withdrawComplete.selector,
                request
            ),
            fee,
            adapterParams
        );
    }

    function _sendValueUpdatedRequest(
        ValueUpdatedRequest memory request
    ) internal {
        (uint fee, bytes memory adapterParams) = _getLzFee(
            GasFunctionType.standardNoReturnMessage,
            request.parentChainId
        );
        _send(
            request.parentChainId,
            abi.encodeWithSelector(
                ITransport.updateVaultValue.selector,
                request
            ),
            fee,
            adapterParams
        );
    }

    function _sendSGBridgedAssetAcknowledment(
        SGBridgedAssetReceivedAcknoledgementRequest memory request
    ) internal {
        (uint fee, bytes memory adapterParams) = _getLzFee(
            GasFunctionType.standardNoReturnMessage,
            request.parentChainId
        );
        _send(
            request.parentChainId,
            abi.encodeWithSelector(
                ITransport.sgBridgedAssetReceived.selector,
                request
            ),
            fee,
            adapterParams
        );
    }

    function _sendChildCreatedRequest(
        ChildCreatedRequest memory request
    ) internal {
        (uint fee, bytes memory adapterParams) = _getLzFee(
            GasFunctionType.childCreatedNoReturnMessage,
            request.parentChainId
        );
        _send(
            request.parentChainId,
            abi.encodeWithSelector(ITransport.childCreated.selector, request),
            fee,
            adapterParams
        );
    }

    /// Internal

    function _send(
        uint16 dstChainId,
        bytes memory payload,
        uint sendFee,
        bytes memory adapterParams
    ) internal {
        require(
            address(this).balance >= sendFee,
            'Transport: insufficient balance'
        );
        _lzEndpoint().send{ value: sendFee }(
            dstChainId,
            _trustedRemoteLookup(dstChainId),
            payload,
            payable(address(this)),
            payable(address(this)),
            adapterParams
        );
    }

    function _getLzFee(
        GasFunctionType gasFunctionType,
        uint16 dstChainId
    ) internal view returns (uint256 sendFee, bytes memory adapterParams) {
        // We just use the largest message for now
        ChildVault memory childVault = ChildVault({
            chainId: 0,
            vault: address(0)
        });
        ChildVault[] memory childVaults = new ChildVault[](2);
        childVaults[0] = childVault;
        childVaults[1] = childVault;

        VaultChildCreationRequest memory request = VaultChildCreationRequest({
            parentVault: address(0),
            parentChainId: 0,
            newChainId: 0,
            manager: address(0),
            riskProfile: VaultRiskProfile.low,
            children: childVaults
        });

        bytes memory payload = abi.encodeWithSelector(
            this.sendVaultChildCreationRequest.selector,
            request
        );

        address dstAddr = _getTrustedRemoteDestination(dstChainId);

        adapterParams = _getAdapterParams(dstChainId, gasFunctionType);

        (sendFee, ) = _lzEndpoint().estimateFees(
            dstChainId,
            dstAddr,
            payload,
            false,
            adapterParams
        );
    }

    function _requiresReturnMessage(
        GasFunctionType gasFunctionType
    ) internal pure returns (bool) {
        if (
            gasFunctionType == GasFunctionType.standardNoReturnMessage ||
            gasFunctionType ==
            GasFunctionType.sendBridgeApprovalNoReturnMessage ||
            gasFunctionType == GasFunctionType.childCreatedNoReturnMessage
        ) {
            return false;
        }
        return true;
    }

    function _getAdapterParams(
        uint16 dstChainId,
        GasFunctionType gasFunctionType
    ) internal view returns (bytes memory) {
        bool requiresReturnMessage = _requiresReturnMessage(gasFunctionType);
        return
            abi.encodePacked(
                uint16(2),
                // The amount of gas the destination consumes when it receives the messaage
                _destinationGasUsage(dstChainId, gasFunctionType),
                // Amount to Airdrop to the remote transport
                requiresReturnMessage ? _returnMessageCost(dstChainId) : 0,
                // Gas Receiver
                requiresReturnMessage
                    ? _getTrustedRemoteDestination(dstChainId)
                    : address(0)
            );
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';
import { SafeERC20 } from '@solidstate/contracts/utils/SafeERC20.sol';
import { VaultBaseExternal } from '../vault-base/VaultBaseExternal.sol';

import { IStargateRouter } from '@layerzerolabs/solidity-examples/contracts/interfaces/IStargateRouter.sol';
import { IStargateReceiver } from '@layerzerolabs/solidity-examples/contracts/interfaces/IStargateReceiver.sol';

import { TransportReceive } from './TransportReceive.sol';
import { ITransport, GasFunctionType } from './ITransport.sol';

abstract contract TransportStargate is TransportReceive, IStargateReceiver {
    using SafeERC20 for IERC20;

    // sgReceive() - the destination contract must implement this function to receive the tokens and payload
    // Does not currently support weth
    function sgReceive(
        uint16, // _srcChainId,
        bytes memory, // _srcAddress
        uint, // _nonce
        address _token,
        uint amountLD,
        bytes memory _payload
    ) external override {
        require(
            msg.sender == address(_stargateRouter()),
            'only stargate router can call sgReceive!'
        );
        SGReceivePayload memory payload = abi.decode(
            _payload,
            (SGReceivePayload)
        );
        // send transfer _token/amountLD to _toAddr
        IERC20(_token).transfer(payload.dstVault, amountLD);
        VaultBaseExternal(payable(payload.dstVault)).receiveBridgedAsset(
            _token
        );
        // Already on the parent chain - no need to send a message
        if (_registry().chainId() == payload.parentChainId) {
            this.sgBridgedAssetReceived(
                SGBridgedAssetReceivedAcknoledgementRequest({
                    parentChainId: payload.parentChainId,
                    parentVault: payload.parentVault,
                    receivingChainId: payload.parentChainId
                })
            );
        } else {
            _sendSGBridgedAssetAcknowledment(
                SGBridgedAssetReceivedAcknoledgementRequest({
                    parentChainId: payload.parentChainId,
                    parentVault: payload.parentVault,
                    receivingChainId: _registry().chainId()
                })
            );
        }
    }

    function bridgeAsset(
        uint16 dstChainId, // Stargate/LayerZero chainId
        address dstVault, // the address to send the destination tokens to
        uint16 parentChainId,
        address parentVault,
        address bridgeToken, // the address of the native ERC20 to swap() - *must* be the token for the poolId
        uint amount,
        uint minAmountOut
    ) external payable onlyVault whenNotPaused {
        require(amount > 0, 'error: swap() requires amount > 0');
        address dstAddr = _getTrustedRemoteDestination(dstChainId);

        uint srcPoolId = _stargateAssetToSrcPoolId(bridgeToken);
        uint dstPoolId = _stargateAssetToDstPoolId(dstChainId, bridgeToken);
        require(srcPoolId != 0, 'no srcPoolId');
        require(dstPoolId != 0, 'no dstPoolId');

        // encode payload data to send to destination contract, which it will handle with sgReceive()
        bytes memory data = abi.encode(
            SGReceivePayload({
                dstVault: dstVault,
                srcVault: msg.sender,
                parentChainId: parentChainId,
                parentVault: parentVault
            })
        );

        IStargateRouter.lzTxObj memory lzTxObj = _getStargateTxObj(
            dstChainId,
            dstAddr,
            parentChainId
        );

        IERC20(bridgeToken).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(bridgeToken).safeApprove(address(_stargateRouter()), amount);

        // Stargate's Router.swap() function sends the tokens to the destination chain.
        IStargateRouter(_stargateRouter()).swap{ value: msg.value }(
            dstChainId, // the destination chain id
            srcPoolId, // the source Stargate poolId
            dstPoolId, // the destination Stargate poolId
            payable(address(this)), // refund adddress. if msg.sender pays too much gas, return extra eth
            amount, // total tokens to send to destination chain
            minAmountOut, // min amount allowed out
            lzTxObj, // default lzTxObj
            abi.encodePacked(dstAddr), // destination address, the sgReceive() implementer
            data // bytes payload
        );
    }

    function getBridgeAssetQuote(
        uint16 dstChainId, // Stargate/LayerZero chainId
        address dstVault, // the address to send the destination tokens to
        uint16 parentChainId,
        address parentVault
    ) external view returns (uint fee) {
        address dstAddr = _getTrustedRemoteDestination(dstChainId);

        // Mock payload for quote
        bytes memory data = abi.encode(
            SGReceivePayload({
                dstVault: dstVault,
                srcVault: msg.sender,
                parentChainId: parentChainId,
                parentVault: parentVault
            })
        );

        IStargateRouter.lzTxObj memory lzTxObj = _getStargateTxObj(
            dstChainId,
            dstAddr,
            parentChainId
        );

        (fee, ) = IStargateRouter(_stargateRouter()).quoteLayerZeroFee(
            dstChainId,
            1, // function type: see Stargate Bridge.sol for all types
            abi.encodePacked(dstAddr), // destination contract. it must implement sgReceive()
            data,
            lzTxObj
        );
    }

    function _getStargateTxObj(
        uint16 dstChainId, // Stargate/LayerZero chainId
        address dstTransportAddress, // the address to send the destination tokens to
        uint16 parentChainId
    ) internal view returns (IStargateRouter.lzTxObj memory lzTxObj) {
        uint DST_GAS = _destinationGasUsage(
            dstChainId,
            GasFunctionType.sgReceiveRequiresReturnMessage
        );
        return
            IStargateRouter.lzTxObj({
                ///
                /// This needs to be enough for the sgReceive to execute successfully on the remote
                /// We will need to accurately access how much the Transport.sgReceive function needs
                ///
                dstGasForCall: DST_GAS,
                // Once the receiving vault receives the bridge the transport sends a message to the parent
                // If the dstChain is the parentChain no return message is required
                dstNativeAmount: dstChainId == parentChainId
                    ? 0
                    : _returnMessageCost(dstChainId),
                dstNativeAddr: abi.encodePacked(dstTransportAddress)
            });
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { Registry } from '../registry/Registry.sol';
import { ILayerZeroEndpoint } from '@layerzerolabs/solidity-examples/contracts/interfaces/ILayerZeroEndpoint.sol';

import { GasFunctionType } from './ITransport.sol';

library TransportStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('valio.storage.Transport');

    // solhint-disable-next-line ordering
    struct Layout {
        Registry registry;
        ILayerZeroEndpoint lzEndpoint;
        mapping(address => bool) isVault;
        mapping(uint16 => bytes) trustedRemoteLookup;
        address stargateRouter;
        mapping(address => uint) stargateAssetToSrcPoolId;
        // (chainId => (asset => poolId))
        mapping(uint16 => mapping(address => uint)) stargateAssetToDstPoolId;
        uint bridgeApprovalCancellationTime;
        mapping(GasFunctionType => uint) DEPRECATED_gasUsage;
        mapping(uint16 => uint) returnMessageCosts;
        // ChainId => (GasFunctionType => gasUsage)
        // The amount of gas needed for delivery on the destination can change
        // Based on the max number of assets that can be enabled in a vault on that chain
        mapping(uint16 => mapping(GasFunctionType => uint)) gasUsage;
        uint vaultCreationFee;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IValuer {
    struct AssetValue {
        address asset;
        uint256 totalMinValue;
        uint256 totalMaxValue;
        AssetBreakDown[] breakDown;
    }

    struct AssetBreakDown {
        address asset;
        uint256 balance;
        uint256 minValue;
        uint256 maxValue;
    }

    function getVaultValue(
        address vault,
        address asset,
        int256 unitPrice
    ) external view returns (uint256 minValue, uint256 maxValue);

    function getAssetValue(
        uint amount,
        address asset,
        int256 unitPrice
    ) external view returns (uint256 minValue, uint256 maxValue);

    // This returns an array because later on we may support assets that have multiple tokens
    // Or we may want to break GMX down into individual positions
    function getAssetBreakdown(
        address vault,
        address asset,
        int256 unitPrice
    ) external view returns (AssetValue memory);

    function getAssetActive(
        address vault,
        address asset
    ) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

enum VaultRiskProfile {
    low,
    medium,
    high
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { Registry } from '../registry/Registry.sol';
import { IGmxPositionRouterCallbackReceiver } from '../interfaces/IGmxPositionRouterCallbackReceiver.sol';
import { VaultBaseInternal } from './VaultBaseInternal.sol';
import { ExecutorIntegration } from '../executors/IExecutor.sol';
import { VaultBaseStorage } from './VaultBaseStorage.sol';
import { VaultRiskProfile } from './IVaultRiskProfile.sol';

contract VaultBaseExternal is
    IGmxPositionRouterCallbackReceiver,
    VaultBaseInternal
{
    receive() external payable {}

    function receiveBridgedAsset(address asset) external onlyTransport {
        _receiveBridgedAsset(asset);
    }

    // The Executor runs as the Vault. I'm not sure this is ideal but it makes writing executors easy
    // Other solutions are
    // 1. The executor returns transactions to be executed which are then assembly called by the this
    // 2. We write the executor code in the vault
    function execute(
        ExecutorIntegration integration,
        bytes memory encodedWithSelectorPayload
    ) external payable onlyManager whenNotPaused nonReentrant {
        _execute(integration, encodedWithSelectorPayload);
    }

    function gmxPositionCallback(
        bytes32 positionKey,
        bool isExecuted,
        bool isIncrease
    ) external nonReentrant {
        _gmxPositionCallback(positionKey, isExecuted, isIncrease);
    }

    function registry() external view returns (Registry) {
        return _registry();
    }

    function manager() external view returns (address) {
        return _manager();
    }

    function vaultId() external view returns (bytes32) {
        return _vaultId();
    }

    function getVaultValue()
        external
        view
        returns (uint minValue, uint maxValue, bool hasHardDeprecatedAsset)
    {
        return _getVaultValue();
    }

    function getCurrentCpit() external view returns (uint256) {
        return _getCurrentCpit();
    }

    function riskProfile() external view returns (VaultRiskProfile) {
        return _riskProfile();
    }

    function enabledAssets(address asset) external view returns (bool) {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        return l.enabledAssets[asset];
    }

    // This should not be called assetsWithBalances, but should be called enabledAssets;
    // Some assets are enabled even though their balance 0
    // Any example is that the collateralAsset for gmx is enabled for the life of the perp position
    // Becaues the perp can get liquidated and the vault receive the collateral asset without notification.
    function assetsWithBalances() external view returns (address[] memory) {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        return l.assets;
    }

    function assetLocks(address asset) external view returns (uint256) {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        return l.assetLocks[asset];
    }

    function hardDeprecatedAssets()
        external
        view
        returns (address[] memory hdeprecatedAssets)
    {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        hdeprecatedAssets = new address[](l.assets.length);
        uint count;
        for (uint i = 0; i < l.assets.length; i++) {
            if (l.registry.hardDeprecatedAssets(l.assets[i])) {
                count++;
                hdeprecatedAssets[i] = (l.assets[i]);
            }
        }

        uint256 reduceLength = l.assets.length - count;
        assembly {
            mstore(
                hdeprecatedAssets,
                sub(mload(hdeprecatedAssets), reduceLength)
            )
        }
    }

    // This can be called by the executors to update the vaults active assets after a tx
    function addActiveAsset(address asset) public onlyThis {
        _addAsset(asset);
    }

    // This can be called by the executors to update the vaults active assets after a tx
    function updateActiveAsset(address asset) public onlyThis {
        _updateActiveAsset(asset);
    }

    // This can be called by the executors
    function addAssetLock(address asset) public onlyThis {
        _addAssetLock(asset);
    }

    // This can be called by the executors
    function removeAssetLock(address asset) public onlyThis {
        _removeAssetLock(asset);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { Registry } from '../registry/Registry.sol';
import { Constants } from '../lib/Constants.sol';
import { VaultRiskProfile } from '../vault-base/IVaultRiskProfile.sol';
import { IGmxPositionRouterCallbackReceiver } from '../interfaces/IGmxPositionRouterCallbackReceiver.sol';
import { ExecutorIntegration, IExecutor } from '../executors/IExecutor.sol';
import { IRedeemer } from '../redeemers/IRedeemer.sol';
import { Call } from '../lib/Call.sol';
import { VaultBaseStorage } from './VaultBaseStorage.sol';
import { CPIT } from '../cpit/CPIT.sol';

import { ReentrancyGuard } from '@solidstate/contracts/utils/ReentrancyGuard.sol';
import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';
import { SafeERC20 } from '@solidstate/contracts/utils/SafeERC20.sol';

contract VaultBaseInternal is ReentrancyGuard, CPIT {
    using SafeERC20 for IERC20;

    event Withdraw(
        uint tokenId,
        address withdrawer,
        uint portion,
        address[] assets
    );
    event AssetAdded(address asset);
    event AssetRemoved(address asset);
    event BridgeReceived(address asset);
    event BridgeSent(
        uint16 dstChainId,
        address dstVault,
        address asset,
        uint amount
    );

    modifier whenNotPaused() {
        require(!_registry().paused(), 'paused');
        _;
    }

    modifier onlyTransport() {
        require(
            address(_registry().transport()) == msg.sender,
            'not transport'
        );
        _;
    }

    modifier onlyThis() {
        require(address(this) == msg.sender, 'not this');
        _;
    }

    modifier onlyManager() {
        require(_manager() == msg.sender, 'not manager');
        _;
    }

    function initialize(
        Registry registry,
        address manager,
        VaultRiskProfile riskProfile
    ) internal {
        require(manager != address(0), 'invalid _manager');
        require(address(registry) != address(0), 'invalid _registry');

        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        l.registry = Registry(registry);
        l.manager = manager;
        l.riskProfile = riskProfile;
    }

    // The Executor runs as the Vault. I'm not sure this is ideal but it makes writing executors easy
    // Other solutions are
    // 1. The executor returns transactions to be executed which are then assembly called by the this
    // 2. We write the executor code in the vault (executor then has access to all storage)
    function _execute(
        ExecutorIntegration integration,
        bytes memory encodedWithSelectorPayload
    ) internal {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        address executor = l.registry.executors(integration);
        require(executor != address(0), 'no executor');

        // During withdraw we use to check if each asset was still active
        // But this is gas intesive an withdraws are crosschain.
        _updateAllActiveAssets();

        bool requiresCPIT = IExecutor(executor).requiresCPIT();

        // Get value before manager execution, for CPIT
        (uint minVaultValue, , ) = requiresCPIT
            ? _getVaultValue()
            : (0, 0, false);

        // Make the external call
        Call._delegate(executor, encodedWithSelectorPayload);

        // Get value after for CPIT
        // We use max value here to exclude gmx exit fees from calculation
        if (requiresCPIT) {
            (uint minVaultValueAfter, , ) = _getVaultValue();
            _updatePriceImpact(
                minVaultValue,
                minVaultValueAfter,
                _registry().maxCpitBips(l.riskProfile)
            );
        }
    }

    // The Redeemer runs as the Vault. I'm not sure this is ideal but it makes writing Redeemers easy
    // Other solutions are
    // 1. The Redeemer returns transactions to be executed which are then assembly called by the this
    // 2. We write the Redeemer code in the vault
    function _withdraw(
        uint tokenId,
        address withdrawer,
        uint portion
    ) internal {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();

        for (uint i = 0; i < l.assets.length; i++) {
            address redeemer = l.registry.redeemers(l.assets[i]);
            require(redeemer != address(0), 'no redeemer');
            if (IRedeemer(redeemer).hasPreWithdraw()) {
                Call._delegate(
                    redeemer,
                    abi.encodeWithSelector(
                        IRedeemer.preWithdraw.selector,
                        tokenId,
                        l.assets[i],
                        withdrawer,
                        portion
                    )
                );
            }
        }

        // We need to take a memory refence as we remove assets that are fully withdrawn
        // And this means that the assets array will change length
        // This should not be moved before preWithdraw because preWithdraw can add active assets
        address[] memory assets = l.assets;

        for (uint i = 0; i < assets.length; i++) {
            address redeemer = l.registry.redeemers(assets[i]);
            Call._delegate(
                redeemer,
                abi.encodeWithSelector(
                    IRedeemer.withdraw.selector,
                    tokenId,
                    assets[i],
                    withdrawer,
                    portion
                )
            );
        }

        emit Withdraw(tokenId, withdrawer, portion, assets);
        _registry().emitEvent();
    }

    function _updateAllActiveAssets() internal {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        for (uint i = 0; i < l.assets.length; i++) {
            _updateActiveAsset(l.assets[i]);
        }
    }

    function _updateActiveAsset(address asset) internal {
        if (_isActive(asset)) {
            _addAsset(asset);
        } else {
            _removeAsset(asset);
        }
    }

    function _receiveBridgedAsset(address asset) internal {
        // Force flag is set to true, because we must receive the bridged asset
        _addAsset(asset, true);
        emit BridgeReceived(asset);
        _registry().emitEvent();
    }

    function _bridgeAsset(
        uint16 dstChainId,
        address dstVault,
        uint16 parentChainId,
        address vaultParent,
        address asset,
        uint amount,
        uint minAmountOut,
        uint lzFee
    ) internal {
        // The max slippage the stargate ui shows is 1%
        // check minAmountOut is within this threshold
        uint internalMinAmountOut = (amount * 99) / 100;
        require(minAmountOut >= internalMinAmountOut, 'minAmountOut too low');

        IERC20(asset).safeApprove(address(_registry().transport()), amount);
        _registry().transport().bridgeAsset{ value: lzFee }(
            dstChainId,
            dstVault,
            parentChainId,
            vaultParent,
            asset,
            amount,
            minAmountOut
        );
        emit BridgeSent(dstChainId, dstVault, asset, amount);
        _registry().emitEvent();
        _updateActiveAsset(asset);
    }

    function _gmxPositionCallback(
        bytes32 positionKey,
        bool isExecuted,
        bool isIncrease
    ) internal {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        require(
            msg.sender == address(l.registry.gmxConfig().positionRouter()),
            'not gmx'
        );
        address executor = l.registry.executors(ExecutorIntegration.GMX);
        require(executor != address(0), 'no executor');
        Call._delegate(
            executor,
            abi.encodeWithSelector(
                IGmxPositionRouterCallbackReceiver.gmxPositionCallback.selector,
                positionKey,
                isExecuted,
                isIncrease
            )
        );
    }

    function _addAssetLock(address asset) internal {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        require(l.enabledAssets[asset], 'lock: asset not enabled');
        l.assetLocks[asset] += 1;
    }

    function _removeAssetLock(address asset) internal {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        if (l.assetLocks[asset] > 0) {
            l.assetLocks[asset] -= 1;
        }
    }

    function _removeAsset(address asset) internal {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        if (l.assetLocks[asset] > 0) {
            return;
        }
        if (l.enabledAssets[asset]) {
            for (uint i = 0; i < l.assets.length; i++) {
                if (l.assets[i] == asset) {
                    _removeFromArray(l.assets, i);
                    l.enabledAssets[asset] = false;

                    emit AssetRemoved(asset);
                    _registry().emitEvent();
                }
            }
        }
    }

    function _addAsset(address asset) internal {
        _addAsset(asset, false);
    }

    // The force flag is used when assets are bridged and we must receive them
    // We can't stop the user from the src chain from bridging based on the number of assets the dst vault has
    function _addAsset(address asset, bool force) internal {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        require(
            l.registry.accountant().isSupportedAsset(asset),
            'asset not supported'
        );
        if (!l.enabledAssets[asset]) {
            l.enabledAssets[asset] = true;
            l.assets.push(asset);
            require(
                force || l.assets.length <= l.registry.maxActiveAssets(),
                'too many assets'
            );

            emit AssetAdded(asset);
            _registry().emitEvent();
        }
    }

    function _removeFromArray(address[] storage array, uint index) internal {
        require(index < array.length);
        array[index] = array[array.length - 1];
        array.pop();
    }

    function _changeManager(address newManager) internal {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        l.manager = newManager;
    }

    function _setVaultId(bytes32 vaultId) internal {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        l.vaultId = vaultId;
    }

    function _registry() internal view returns (Registry) {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        return l.registry;
    }

    function _riskProfile() internal view returns (VaultRiskProfile) {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        return l.riskProfile;
    }

    function _manager() internal view returns (address) {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        return l.manager;
    }

    function _vaultId() internal view returns (bytes32) {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        return l.vaultId;
    }

    function _getVaultValue()
        internal
        view
        returns (uint minValue, uint maxValue, bool hasHardDeprecatedAsset)
    {
        return _registry().accountant().getVaultValue(address(this));
    }

    function _isActive(address asset) internal view returns (bool) {
        return _registry().accountant().assetIsActive(asset, address(this));
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { Registry } from '../registry/Registry.sol';

import { VaultRiskProfile } from '../vault-base/IVaultRiskProfile.sol';

library VaultBaseStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('valio.storage.VaultBase');

    // solhint-disable-next-line ordering
    struct Layout {
        Registry registry;
        address manager;
        address[] assets;
        mapping(address => bool) enabledAssets;
        VaultRiskProfile riskProfile;
        bytes32 vaultId;
        // For instance a GMX position can get liquidated at anytime and any collateral
        // remaining is returned to the vault. But the vault is not notified.
        // In this case the collateralToken might not be tracked by the vault anymore
        // To resolve this: A GmxPosition will increament the assetLock for the collateralToken, meaning that it cannot
        // be removed from enabledAssets until the lock for the asset reaches 0
        // Any code that adds a lock is responsible for removing the lock
        mapping(address => uint256) assetLocks;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ITransport, GasFunctionType } from '../transport/ITransport.sol';
import { VaultBaseInternal } from '../vault-base/VaultBaseInternal.sol';
import { VaultBaseExternal } from '../vault-base/VaultBaseExternal.sol';
import { VaultRiskProfile } from '../vault-base/IVaultRiskProfile.sol';
import { Registry } from '../registry/Registry.sol';
import { RegistryStorage } from '../registry/RegistryStorage.sol';
import { VaultChildStorage } from './VaultChildStorage.sol';

import { IRedeemerEvents } from '../redeemers/IRedeemerEvents.sol';
import { IExecutorEvents } from '../executors/IExecutorEvents.sol';

import { IStargateRouter } from '@layerzerolabs/solidity-examples/contracts/interfaces/IStargateRouter.sol';

contract VaultChild is
    VaultBaseInternal,
    VaultBaseExternal,
    IRedeemerEvents,
    IExecutorEvents
{
    event BridgeApprovalReceived(uint time);

    modifier bridgingApproved() {
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();

        require(l.bridgeApproved, 'bridge not approved');
        _;
    }

    function initialize(
        uint16 _parentChainId,
        address _vaultParentAddress,
        address _manager,
        VaultRiskProfile _riskProfile,
        Registry _registry,
        ITransport.ChildVault[] memory _existingSiblings
    ) external {
        require(_vaultId() == 0, 'already initialized');

        VaultChildStorage.Layout storage l = VaultChildStorage.layout();
        VaultBaseInternal.initialize(_registry, _manager, _riskProfile);
        require(_parentChainId != 0, 'invalid _parentChainId');
        require(
            _vaultParentAddress != address(0),
            'invalid _vaultParentAddress'
        );

        bytes32 vaultId = keccak256(
            abi.encodePacked(_parentChainId, _vaultParentAddress)
        );
        _setVaultId(vaultId);

        l.parentChainId = _parentChainId;
        l.vaultParent = _vaultParentAddress;
        for (uint8 i = 0; i < _existingSiblings.length; i++) {
            l.siblingChains.push(_existingSiblings[i].chainId);
            l.siblings[_existingSiblings[i].chainId] = _existingSiblings[i]
                .vault;
        }
    }

    ///
    /// Receivers/CallBacks
    ///

    // called by the dstChain via lz to federate a new sibling
    function receiveAddSibling(
        uint16 siblingChainId,
        address siblingVault
    ) external onlyTransport {
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();

        l.siblings[siblingChainId] = siblingVault;
        l.siblingChains.push(siblingChainId);
    }

    function receiveBridgeApproval() external onlyTransport {
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();

        l.bridgeApproved = true;
        l.bridgeApprovalTime = block.timestamp;
        _registry().emitEvent();
        emit BridgeApprovalReceived(block.timestamp);
    }

    function receiveWithdrawRequest(
        uint tokenId,
        address withdrawer,
        uint portion
    ) external onlyTransport nonReentrant {
        _withdraw(tokenId, withdrawer, portion);
    }

    function receiveManagerChange(address newManager) external onlyTransport {
        _changeManager(newManager);
    }

    ///
    /// Cross Chain Requests
    ///

    // Allows anyone to unlock the bridge lock on the parent after 5 minutes
    function requestBridgeApprovalCancellation(
        uint lzFee
    ) external payable whenNotPaused {
        require(msg.value >= lzFee, 'insufficient fee');
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();

        require(l.bridgeApproved, 'must be already approved');
        uint timeout = _registry().transport().bridgeApprovalCancellationTime();

        if (msg.sender != _manager()) {
            require(
                l.bridgeApprovalTime + timeout < block.timestamp,
                'cannot cancel yet'
            );
        }

        l.bridgeApproved = false;
        l.bridgeApprovalTime = 0;
        _registry().transport().sendBridgeApprovalCancellation{ value: lzFee }(
            ITransport.BridgeApprovalCancellationRequest({
                parentChainId: l.parentChainId,
                parentVault: l.vaultParent,
                requester: msg.sender
            })
        );
    }

    function requestBridgeToChain(
        uint16 dstChainId,
        address asset,
        uint amount,
        uint minAmountOut,
        uint lzFee
    ) external payable onlyManager whenNotPaused bridgingApproved {
        require(msg.value >= lzFee, 'insufficient fee');
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();

        address dstVault;
        if (dstChainId == l.parentChainId) {
            dstVault = l.vaultParent;
        } else {
            dstVault = l.siblings[dstChainId];
        }

        require(dstVault != address(0), 'no dst vault');

        l.bridgeApproved = false;
        l.bridgeApprovalTime = 0;
        _bridgeAsset(
            dstChainId,
            dstVault,
            l.parentChainId,
            l.vaultParent,
            asset,
            amount,
            minAmountOut,
            lzFee
        );
    }

    ///
    /// Views
    ///

    function parentChainId() external view returns (uint16) {
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();

        return l.parentChainId;
    }

    function parentVault() external view returns (address) {
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();

        return l.vaultParent;
    }

    function allSiblingChainIds() external view returns (uint16[] memory) {
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();
        return l.siblingChains;
    }

    function siblings(uint16 chainId) external view returns (address) {
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();
        return l.siblings[chainId];
    }

    function bridgeApproved() external view returns (bool) {
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();
        return l.bridgeApproved;
    }

    function bridgeApprovalTime() external view returns (uint) {
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();
        return l.bridgeApprovalTime;
    }

    function getLzFee(
        bytes4 funcHash,
        uint16 chainId
    ) public view returns (uint fee) {
        if (funcHash == this.requestBridgeToChain.selector) {
            fee = _bridgeQuote(chainId);
        } else {
            (fee, ) = _registry().transport().getLzFee(
                GasFunctionType.standardNoReturnMessage,
                chainId
            );
        }
    }

    function _bridgeQuote(uint16 dstChainId) internal view returns (uint fee) {
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();

        address dstVault;
        if (dstChainId == l.parentChainId) {
            dstVault = l.vaultParent;
        } else {
            dstVault = l.siblings[dstChainId];
        }

        require(dstVault != address(0), 'no dst vault');

        fee = _registry().transport().getBridgeAssetQuote(
            dstChainId,
            dstVault,
            l.parentChainId,
            l.vaultParent
        );
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { Proxy } from '@solidstate/contracts/proxy/Proxy.sol';
import { IDiamondReadable } from '@solidstate/contracts/proxy/diamond/readable/IDiamondReadable.sol';

contract VaultChildProxy is Proxy {
    address private immutable DIAMOND;

    constructor(address diamond) {
        DIAMOND = diamond;
    }

    function _getImplementation() internal view override returns (address) {
        return IDiamondReadable(DIAMOND).facetAddress(msg.sig);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library VaultChildStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('valio.storage.VaultChild');

    // solhint-disable-next-line ordering
    struct Layout {
        bytes32 _deprecated_vaultId;
        uint16 parentChainId;
        address vaultParent;
        bool bridgeApproved;
        uint bridgeApprovalTime;
        uint16[] siblingChains;
        mapping(uint16 => address) siblings;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { VaultFeesStorage } from './VaultFeesStorage.sol';
import { Constants } from '../lib/Constants.sol';

contract VaultFees {
    uint internal constant _STEAMING_FEE_DURATION = 365 days;

    uint internal constant _MAX_STREAMING_FEE_BASIS_POINTS = 500; // 5%
    uint internal constant _MAX_STREAMING_FEE_BASIS_POINTS_STEP = 50; // 0.5%
    uint internal constant _MAX_PERFORMANCE_FEE_BASIS_POINTS = 4000; // 40%
    uint internal constant _MAX_PERFORMANCE_FEE_BASIS_POINTS_STEP = 1000; // 10%
    uint internal constant _FEE_ANNOUNCE_WINDOW = 30 days;

    event FeeIncreaseAnnounced(uint streamingFee, uint performanceFee);
    event FeeIncreaseCommitted(uint streamingFee, uint performanceFee);
    event FeeIncreaseRenounced();

    function initialize(
        uint _managerStreamingFeeBasisPoints,
        uint _managerPerformanceFeeBasisPoints
    ) internal {
        VaultFeesStorage.Layout storage l = VaultFeesStorage.layout();
        require(
            _managerStreamingFeeBasisPoints <= _MAX_STREAMING_FEE_BASIS_POINTS,
            'streamingFee to high'
        );
        require(
            _managerPerformanceFeeBasisPoints <=
                _MAX_PERFORMANCE_FEE_BASIS_POINTS,
            'performanceFee to high'
        );
        l.managerStreamingFee = _managerStreamingFeeBasisPoints;
        l.managerPerformanceFee = _managerPerformanceFeeBasisPoints;
    }

    function _announceFeeIncrease(
        uint256 newStreamingFee,
        uint256 newPerformanceFee
    ) internal {
        require(
            newStreamingFee <= _MAX_STREAMING_FEE_BASIS_POINTS,
            'streamingFee to high'
        );

        VaultFeesStorage.Layout storage l = VaultFeesStorage.layout();

        require(
            newStreamingFee <=
                l.managerStreamingFee + _MAX_STREAMING_FEE_BASIS_POINTS_STEP,
            'streamingFee step exceeded'
        );
        require(
            newPerformanceFee <= _MAX_PERFORMANCE_FEE_BASIS_POINTS,
            'performanceFee to high'
        );
        require(
            newPerformanceFee <=
                l.managerPerformanceFee +
                    _MAX_PERFORMANCE_FEE_BASIS_POINTS_STEP,
            'performanceFee step exceeded'
        );

        l.announcedFeeIncreaseTimestamp = block.timestamp;
        l.announcedManagerStreamingFee = newStreamingFee;
        l.announcedManagerPerformanceFee = newPerformanceFee;
        emit FeeIncreaseAnnounced(newStreamingFee, newPerformanceFee);
    }

    function _renounceFeeIncrease() internal {
        VaultFeesStorage.Layout storage l = VaultFeesStorage.layout();

        require(
            l.announcedFeeIncreaseTimestamp != 0,
            'no fee increase announced'
        );

        l.announcedFeeIncreaseTimestamp = 0;
        l.announcedManagerStreamingFee = 0;
        l.announcedManagerPerformanceFee = 0;

        emit FeeIncreaseRenounced();
    }

    function _commitFeeIncrease() internal {
        VaultFeesStorage.Layout storage l = VaultFeesStorage.layout();

        require(
            l.announcedFeeIncreaseTimestamp != 0,
            'no fee increase announced'
        );
        require(
            block.timestamp >=
                l.announcedFeeIncreaseTimestamp + _FEE_ANNOUNCE_WINDOW,
            'fee delay active'
        );

        l.managerStreamingFee = l.announcedManagerStreamingFee;
        l.managerPerformanceFee = l.announcedManagerPerformanceFee;

        l.announcedFeeIncreaseTimestamp = 0;
        l.announcedManagerStreamingFee = 0;
        l.announcedManagerPerformanceFee = 0;

        emit FeeIncreaseCommitted(
            l.managerStreamingFee,
            l.managerPerformanceFee
        );
    }

    function _managerPerformanceFee() internal view returns (uint) {
        VaultFeesStorage.Layout storage l = VaultFeesStorage.layout();

        return l.managerPerformanceFee;
    }

    function _managerStreamingFee() internal view returns (uint) {
        VaultFeesStorage.Layout storage l = VaultFeesStorage.layout();

        return l.managerStreamingFee;
    }

    function _announcedManagerPerformanceFee() internal view returns (uint) {
        VaultFeesStorage.Layout storage l = VaultFeesStorage.layout();

        return l.announcedManagerPerformanceFee;
    }

    function _announcedManagerStreamingFee() internal view returns (uint) {
        VaultFeesStorage.Layout storage l = VaultFeesStorage.layout();
        return l.announcedManagerStreamingFee;
    }

    function _announcedFeeIncreaseTimestamp() internal view returns (uint) {
        VaultFeesStorage.Layout storage l = VaultFeesStorage.layout();

        return l.announcedFeeIncreaseTimestamp;
    }

    function _streamingFee(
        uint fee,
        uint discount,
        uint lastFeeTime,
        uint totalShares,
        uint timeNow
    ) internal pure returns (uint tokensOwed) {
        if (lastFeeTime >= timeNow) {
            return 0;
        }

        uint discountAdjustment = Constants.BASIS_POINTS_DIVISOR - discount;
        uint timeSinceLastFee = timeNow - lastFeeTime;
        tokensOwed =
            (totalShares * fee * timeSinceLastFee * discountAdjustment) /
            _STEAMING_FEE_DURATION /
            Constants.BASIS_POINTS_DIVISOR /
            Constants.BASIS_POINTS_DIVISOR;
    }

    function _performanceFee(
        uint fee,
        uint discount,
        uint totalShares,
        uint tokenPriceStart,
        uint tokenPriceFinish
    ) internal pure returns (uint tokensOwed) {
        if (tokenPriceFinish <= tokenPriceStart) {
            return 0;
        }

        uint discountAdjustment = Constants.BASIS_POINTS_DIVISOR - discount;
        uint priceIncrease = tokenPriceFinish - (tokenPriceStart);
        tokensOwed =
            (priceIncrease * fee * totalShares * discountAdjustment) /
            tokenPriceStart /
            Constants.BASIS_POINTS_DIVISOR /
            Constants.BASIS_POINTS_DIVISOR;
    }

    function _protocolFee(
        uint managerFees,
        uint protocolFeeBips
    ) internal pure returns (uint) {
        return (managerFees * protocolFeeBips) / Constants.BASIS_POINTS_DIVISOR;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library VaultFeesStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('valio.storage.VaultFees');

    // solhint-disable-next-line ordering
    struct Layout {
        uint managerStreamingFee;
        uint managerPerformanceFee;
        uint announcedFeeIncreaseTimestamp;
        uint announcedManagerStreamingFee;
        uint announcedManagerPerformanceFee;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { VaultFees } from '../vault-fees/VaultFees.sol';
import { VaultOwnershipStorage } from './VaultOwnershipStorage.sol';

import { IERC165 } from '@solidstate/contracts/interfaces/IERC165.sol';
import { IERC721 } from '@solidstate/contracts/interfaces/IERC721.sol';
import { ERC721BaseInternal, ERC165Base } from '@solidstate/contracts/token/ERC721/SolidStateERC721.sol';

import { ERC165BaseStorage } from '@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol';

import { ERC721MetadataStorage } from '@solidstate/contracts/token/ERC721/metadata/ERC721MetadataStorage.sol';

import { Constants } from '../lib/Constants.sol';

contract VaultOwnershipInternal is
    ERC721BaseInternal, //ERC165BaseInternal causes Linearization issue in vaultParentErc721
    VaultFees
{
    uint internal constant _MANAGER_TOKEN_ID = 0;
    uint internal constant _PROTOCOL_TOKEN_ID = 1;

    uint internal constant BURN_LOCK_TIME = 24 hours;

    event FeesLevied(
        uint tokenId,
        uint streamingFees,
        uint performanceFees,
        uint currentUnitPrice
    );

    function initialize(
        string memory _name,
        string memory _symbol,
        address _manager,
        uint _managerStreamingFeeBasisPoints,
        uint _managerPerformanceFeeBasisPoints,
        address _protocolAddress
    ) internal {
        super.initialize(
            _managerStreamingFeeBasisPoints,
            _managerPerformanceFeeBasisPoints
        );
        ERC721MetadataStorage.Layout storage l = ERC721MetadataStorage.layout();
        l.name = _name;
        l.symbol = _symbol;

        _createManagerHolding(_manager);
        _createProtocolHolding(_protocolAddress);
    }

    function _mint(address to) internal returns (uint256 tokenId) {
        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();
        tokenId = l._tokenIdCounter;
        _safeMint(to, tokenId);
        l._tokenIdCounter++;
    }

    function _createManagerHolding(address manager) internal {
        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();

        require(
            _exists(_MANAGER_TOKEN_ID) == false,
            'manager holding already exists'
        );
        require(
            l._tokenIdCounter == _MANAGER_TOKEN_ID,
            'manager holding must be token 0'
        );
        _mint(manager);
    }

    function _createProtocolHolding(address protocolTreasury) internal {
        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();

        require(
            _exists(_PROTOCOL_TOKEN_ID) == false,
            'protcool holding already exists'
        );
        require(
            l._tokenIdCounter == _PROTOCOL_TOKEN_ID,
            'protocol holding must be token 1'
        );
        _mint(protocolTreasury);
    }

    function _issueShares(
        uint tokenId,
        address owner,
        uint shares,
        uint currentUnitPrice,
        uint lockupTime,
        uint protocolFeeBips
    ) internal returns (uint) {
        // Managers cannot deposit directly into their holding, they can only accrue fees there.
        // Users or the Manger can pass tokenId == 0 and it will create a new holding for them.
        require(_exists(tokenId), 'token does not exist');

        if (tokenId == _MANAGER_TOKEN_ID) {
            tokenId = _mint(owner);
        }

        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();
        VaultOwnershipStorage.Holding storage holding = l.holdings[tokenId];

        if (holding.totalShares == 0) {
            holding.streamingFee = _managerStreamingFee();
            holding.performanceFee = _managerPerformanceFee();
            holding.lastStreamingFeeTime = block.timestamp;
            holding.lastPerformanceFeeUnitPrice = currentUnitPrice;
            holding.averageEntryPrice = currentUnitPrice;
        } else {
            _levyFees(tokenId, currentUnitPrice, protocolFeeBips);
            holding.averageEntryPrice = _calculateAverageEntryPrice(
                holding.totalShares,
                holding.averageEntryPrice,
                shares,
                currentUnitPrice
            );
        }

        l.totalShares += shares;
        holding.unlockTime = block.timestamp + lockupTime;
        holding.totalShares += shares;

        return tokenId;
    }

    function _burnShares(
        uint tokenId,
        uint shares,
        uint currentUnitPrice,
        uint protocolFeeBips
    ) internal {
        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();

        VaultOwnershipStorage.Holding storage holding = l.holdings[tokenId];
        require(!_holdingLocked(tokenId), 'locked');
        _levyFees(tokenId, currentUnitPrice, protocolFeeBips);
        require(shares <= holding.totalShares, 'not enough shares');
        holding.lastBurnTime = block.timestamp;
        holding.totalShares -= shares;
        l.totalShares -= shares;
    }

    function _levyFees(
        uint tokenId,
        uint currentUnitPrice,
        uint protocolFeeBips
    ) internal {
        if (isSystemToken(tokenId)) {
            return;
        }

        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();

        (uint streamingFees, uint performanceFees) = _levyFeesOnHolding(
            tokenId,
            _managerStreamingFee(),
            _managerPerformanceFee(),
            currentUnitPrice
        );

        emit FeesLevied(
            tokenId,
            streamingFees,
            performanceFees,
            currentUnitPrice
        );

        uint totalManagerFees = streamingFees + performanceFees;

        uint protocolFees = _protocolFee(
            streamingFees + performanceFees,
            protocolFeeBips
        );
        uint managerFees = totalManagerFees - protocolFees;
        require(protocolFees + managerFees == totalManagerFees, 'fee math');

        l.holdings[_PROTOCOL_TOKEN_ID].totalShares += protocolFees;
        l.holdings[_MANAGER_TOKEN_ID].totalShares += managerFees;
    }

    function _levyFeesOnHolding(
        uint tokenId,
        uint newStreamingFee,
        uint newPerformanceFee,
        uint currentUnitPrice
    ) internal returns (uint streamingFees, uint performanceFees) {
        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();
        VaultOwnershipStorage.Holding storage holding = l.holdings[tokenId];

        uint initialTotalShares = holding.totalShares;

        holding.lastManagerFeeLevyTime = block.timestamp;

        (streamingFees, performanceFees) = _calculateUnpaidFees(
            tokenId,
            currentUnitPrice
        );

        if (streamingFees > 0 || holding.streamingFee != newStreamingFee) {
            holding.lastStreamingFeeTime = block.timestamp;
        }

        if (
            performanceFees > 0 ||
            (holding.performanceFee != newPerformanceFee &&
                currentUnitPrice > holding.lastPerformanceFeeUnitPrice)
        ) {
            holding.lastPerformanceFeeUnitPrice = currentUnitPrice;
        }

        holding.totalShares -= streamingFees + performanceFees;

        if (holding.streamingFee != newStreamingFee) {
            holding.streamingFee = newStreamingFee;
        }

        if (holding.performanceFee != newPerformanceFee) {
            holding.performanceFee = newPerformanceFee;
        }

        require(
            holding.totalShares + streamingFees + performanceFees ==
                initialTotalShares,
            'check failed'
        );

        return (streamingFees, performanceFees);
    }

    function _setDiscountForHolding(
        uint tokenId,
        uint streamingFeeDiscount,
        uint performanceFeeDiscount
    ) internal {
        require(
            streamingFeeDiscount <= Constants.BASIS_POINTS_DIVISOR,
            'invalid streamingFeeDiscount'
        );
        require(
            performanceFeeDiscount <= Constants.BASIS_POINTS_DIVISOR,
            'invalid performanceFeeDiscount'
        );

        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();
        VaultOwnershipStorage.Holding storage holding = l.holdings[tokenId];

        holding.streamingFeeDiscount = streamingFeeDiscount;
        holding.performanceFeeDiscount = performanceFeeDiscount;
    }

    function _holdings(
        uint tokenId
    ) internal view returns (VaultOwnershipStorage.Holding memory) {
        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();
        return l.holdings[tokenId];
    }

    function _holdingLocked(uint tokenId) internal view returns (bool) {
        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();

        VaultOwnershipStorage.Holding storage holding = l.holdings[tokenId];
        if (block.timestamp < holding.unlockTime) {
            return true;
        }

        // Not needed anymore because we support consecutive withdraws
        // if (block.timestamp < holding.lastBurnTime + BURN_LOCK_TIME) {
        //     return true;
        // }

        return false;
    }

    function _totalShares() internal view returns (uint) {
        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();
        return l.totalShares;
    }

    function _calculateUnpaidFees(
        uint tokenId,
        uint currentUnitPrice
    ) internal view returns (uint streamingFees, uint performanceFees) {
        if (isSystemToken(tokenId)) {
            return (0, 0);
        }

        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();
        VaultOwnershipStorage.Holding storage holding = l.holdings[tokenId];

        uint initialTotalShares = holding.totalShares;

        streamingFees = _streamingFee(
            holding.streamingFee,
            holding.streamingFeeDiscount,
            holding.lastStreamingFeeTime,
            initialTotalShares,
            block.timestamp
        );

        performanceFees = _performanceFee(
            holding.performanceFee,
            holding.performanceFeeDiscount,
            // We levy performance fees after levying streamingFees
            initialTotalShares - streamingFees,
            holding.lastPerformanceFeeUnitPrice,
            currentUnitPrice
        );
    }

    function _calculateAverageEntryPrice(
        uint currentShares,
        uint previousPrice,
        uint newShares,
        uint newPrice
    ) internal pure returns (uint) {
        return
            ((currentShares * previousPrice) + (newShares * newPrice)) /
            (currentShares + newShares);
    }

    function isSystemToken(uint tokenId) internal pure returns (bool) {
        return tokenId == _PROTOCOL_TOKEN_ID || tokenId == _MANAGER_TOKEN_ID;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library VaultOwnershipStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('valio.storage.VaultOwnership');

    // TODO: Move to interface
    // solhint-disable-next-line ordering
    struct Holding {
        uint totalShares;
        uint lastStreamingFeeTime;
        uint lastPerformanceFeeUnitPrice;
        uint streamingFeeDiscount;
        uint performanceFeeDiscount;
        uint streamingFee;
        uint performanceFee;
        uint unlockTime;
        uint averageEntryPrice;
        uint lastManagerFeeLevyTime;
        uint lastBurnTime;
    }

    // solhint-disable-next-line ordering
    struct Layout {
        // The manager is issued token 0; The protocol is issued token 1; all other tokens are issued to investors
        // All fees are levied to token 0 and a portion to token 1;
        // tokenId to Holding
        mapping(uint => Holding) holdings;
        uint totalShares;
        uint256 _tokenIdCounter;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IVaultParentInvestor {
    function withdrawMultiChain(
        uint tokenId,
        uint amount,
        uint[] memory lzFees
    ) external;

    function withdrawAllMultiChain(uint tokenId, uint[] memory lzFees) external;

    function requestTotalValueUpdateMultiChain(uint[] memory lzFees) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IVaultParentManager {
    function requestBridgeToChain(
        uint16 dstChainId,
        address asset,
        uint256 amount,
        uint256 minAmountOut,
        uint lzFee
    ) external payable;

    function requestCreateChild(uint16 newChainId, uint lzFee) external payable;

    function sendBridgeApproval(uint16 dstChainId, uint lzFee) external payable;

    function changeManagerMultiChain(
        address newManager,
        uint[] memory lzFees
    ) external payable;

    function setDiscountForHolding(
        uint256 tokenId,
        uint256 streamingFeeDiscount,
        uint256 performanceFeeDiscount
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { VaultParentTransport } from './VaultParentTransport.sol';
import { VaultParentInvestor } from './VaultParentInvestor.sol';
import { VaultParentManager } from './VaultParentManager.sol';
import { VaultParentErc721 } from './VaultParentErc721.sol';
import { VaultParentInternal } from './VaultParentInternal.sol';
import { VaultBaseExternal } from '../vault-base/VaultBaseExternal.sol';
import { IRedeemerEvents } from '../redeemers/IRedeemerEvents.sol';
import { IExecutorEvents } from '../executors/IExecutorEvents.sol';

import { ERC721BaseInternal } from '@solidstate/contracts/token/ERC721/SolidStateERC721.sol';

import { SolidStateERC721 } from '@solidstate/contracts/token/ERC721/SolidStateERC721.sol';
import { ERC721BaseInternal, ERC165Base } from '@solidstate/contracts/token/ERC721/SolidStateERC721.sol';

// Not deployed directly as It's to large
// ONLY used to generate the ABI and for test interface
contract VaultParent is
    VaultParentInvestor,
    VaultParentErc721,
    VaultParentManager,
    VaultParentTransport,
    VaultBaseExternal,
    IRedeemerEvents,
    IExecutorEvents
{
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(VaultParentErc721, VaultParentInternal) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @notice ERC721 hook: revert if value is included in external approve function call
     * @inheritdoc ERC721BaseInternal
     */
    function _handleApproveMessageValue(
        address operator,
        uint256 tokenId,
        uint256 value
    ) internal virtual override(VaultParentErc721, ERC721BaseInternal) {
        if (value > 0) revert SolidStateERC721__PayableApproveNotSupported();
        super._handleApproveMessageValue(operator, tokenId, value);
    }

    /**
     * @notice ERC721 hook: revert if value is included in external transfer function call
     * @inheritdoc ERC721BaseInternal
     */
    function _handleTransferMessageValue(
        address from,
        address to,
        uint256 tokenId,
        uint256 value
    ) internal virtual override(VaultParentErc721, ERC721BaseInternal) {
        if (value > 0) revert SolidStateERC721__PayableTransferNotSupported();
        super._handleTransferMessageValue(from, to, tokenId, value);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { VaultParentInternal } from './VaultParentInternal.sol';

import { Constants } from '../lib/Constants.sol';

import { SolidStateERC721, ERC721BaseInternal } from '@solidstate/contracts/token/ERC721/SolidStateERC721.sol';

import { ITransport } from '../transport/ITransport.sol';
import { Registry } from '../registry/Registry.sol';
import { RegistryStorage } from '../registry/RegistryStorage.sol';
import { VaultParentStorage } from './VaultParentStorage.sol';
import { VaultParentInternal } from './VaultParentInternal.sol';
import { VaultBaseInternal } from '../vault-base/VaultBaseInternal.sol';
import { VaultOwnershipInternal } from '../vault-ownership/VaultOwnershipInternal.sol';
import { VaultRiskProfile } from '../vault-base/IVaultRiskProfile.sol';

import { IERC165 } from '@solidstate/contracts/interfaces/IERC165.sol';
import { IERC721 } from '@solidstate/contracts/interfaces/IERC721.sol';

contract VaultParentErc721 is SolidStateERC721, VaultParentInternal {
    function initialize(
        string memory _name,
        string memory _symbol,
        address _manager,
        uint _managerStreamingFeeBasisPoints,
        uint _managerPerformanceFeeBasisPoints,
        VaultRiskProfile _riskProfile,
        Registry _registry
    ) external {
        require(_vaultId() == 0, 'already initialized');

        bytes32 vaultId = keccak256(
            abi.encodePacked(_registry.chainId(), address(this))
        );
        _setVaultId(vaultId);
        VaultBaseInternal.initialize(_registry, _manager, _riskProfile);
        VaultOwnershipInternal.initialize(
            _name,
            _symbol,
            _manager,
            _managerStreamingFeeBasisPoints,
            _managerPerformanceFeeBasisPoints,
            _registry.protocolTreasury()
        );

        _setSupportsInterface(type(IERC165).interfaceId, true);
        _setSupportsInterface(type(IERC721).interfaceId, true);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(SolidStateERC721, VaultParentInternal) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @notice ERC721 hook: revert if value is included in external approve function call
     * @inheritdoc ERC721BaseInternal
     */
    function _handleApproveMessageValue(
        address operator,
        uint256 tokenId,
        uint256 value
    ) internal virtual override(SolidStateERC721, ERC721BaseInternal) {
        if (value > 0) revert SolidStateERC721__PayableApproveNotSupported();
        super._handleApproveMessageValue(operator, tokenId, value);
    }

    /**
     * @notice ERC721 hook: revert if value is included in external transfer function call
     * @inheritdoc ERC721BaseInternal
     */
    function _handleTransferMessageValue(
        address from,
        address to,
        uint256 tokenId,
        uint256 value
    ) internal virtual override(SolidStateERC721, ERC721BaseInternal) {
        if (value > 0) revert SolidStateERC721__PayableTransferNotSupported();
        super._handleTransferMessageValue(from, to, tokenId, value);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { VaultBaseInternal } from '../vault-base/VaultBaseInternal.sol';
import { VaultOwnershipInternal } from '../vault-ownership/VaultOwnershipInternal.sol';
import { Registry } from '../registry/Registry.sol';
import { VaultParentStorage } from './VaultParentStorage.sol';
import { IVaultParentManager } from './IVaultParentManager.sol';
import { IVaultParentInvestor } from './IVaultParentInvestor.sol';

import { ITransport, GasFunctionType } from '../transport/ITransport.sol';

import { Constants } from '../lib/Constants.sol';

contract VaultParentInternal is VaultOwnershipInternal, VaultBaseInternal {
    modifier noBridgeInProgress() {
        require(!_bridgeInProgress(), 'bridge in progress');
        _;
    }

    modifier vaultNotClosed() {
        require(!_vaultClosed(), 'vault closed');
        _;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        // If minting just return
        if (from == address(0)) {
            return;
        }
        // When using changeManager(), allow transfer to new manager
        if (tokenId == _MANAGER_TOKEN_ID) {
            require(to == _manager(), 'must use changeManager');
            return;
        }

        revert('transfers disabled');
    }

    function _withdrawInProgress() internal view returns (bool) {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        return l.withdrawsInProgress > 0;
    }

    function _bridgeInProgress() internal view returns (bool) {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();
        return l.bridgeInProgress;
    }

    function _bridgeApprovedFor() internal view returns (uint16) {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();
        return l.bridgeApprovedFor;
    }

    function _hasActiveChildren() internal view returns (bool) {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        for (uint8 i = 0; i < l.childChains.length; i++) {
            if (!_childIsInactive(l.childChains[i])) {
                return true;
            }
        }
        return false;
    }

    function _getLzFee(
        bytes4 sigHash,
        uint16 chainId
    ) internal view returns (uint fee) {
        if (sigHash == IVaultParentManager.requestBridgeToChain.selector) {
            fee = _bridgeQuote(chainId);
        } else if (sigHash == IVaultParentManager.requestCreateChild.selector) {
            (fee, ) = _registry().transport().getLzFee(
                GasFunctionType.createChildRequiresReturnMessage,
                chainId
            );
        } else if (
            sigHash ==
            IVaultParentInvestor.requestTotalValueUpdateMultiChain.selector
        ) {
            if (_childIsInactive(chainId)) {
                return 0;
            }
            (fee, ) = _registry().transport().getLzFee(
                GasFunctionType.getVaultValueRequiresReturnMessage,
                chainId
            );
        } else if (
            sigHash == IVaultParentInvestor.withdrawMultiChain.selector ||
            sigHash == IVaultParentInvestor.withdrawAllMultiChain.selector
        ) {
            if (_childIsInactive(chainId)) {
                return 0;
            }
            (fee, ) = _registry().transport().getLzFee(
                GasFunctionType.withdrawRequiresReturnMessage,
                chainId
            );
        } else if (sigHash == IVaultParentManager.sendBridgeApproval.selector) {
            (fee, ) = _registry().transport().getLzFee(
                GasFunctionType.sendBridgeApprovalNoReturnMessage,
                chainId
            );
        } else {
            (fee, ) = _registry().transport().getLzFee(
                GasFunctionType.standardNoReturnMessage,
                chainId
            );
        }
    }

    function _getLzFeesMultiChain(
        bytes4 sigHash,
        uint16[] memory chainIds
    ) internal view returns (uint[] memory fees, uint256 totalSendFee) {
        fees = new uint[](chainIds.length);
        for (uint i = 0; i < chainIds.length; i++) {
            fees[i] = _getLzFee(sigHash, chainIds[i]);
            totalSendFee += fees[i];
        }
    }

    function _bridgeQuote(uint16 dstChainId) internal view returns (uint fee) {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        address dstVault = l.children[dstChainId];
        require(dstVault != address(0), 'no dst vault');

        fee = _registry().transport().getBridgeAssetQuote(
            dstChainId,
            dstVault,
            _registry().chainId(),
            address(this)
        );
    }

    function _childIsInactive(uint16 chainId) internal view returns (bool) {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        return l.childIsInactive[chainId];
    }

    function _inSync() internal view returns (bool) {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        for (uint8 i = 0; i < l.childChains.length; i++) {
            if (_childIsInactive(l.childChains[i])) {
                continue;
            }
            if (_isNotStale(l.chainTotalValues[l.childChains[i]].lastUpdate)) {
                continue;
            } else {
                return false;
            }
        }
        return true;
    }

    function _totalValueAcrossAllChains()
        internal
        view
        returns (uint minValue, uint maxValue, bool hasHardDeprecatedAsset)
    {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        (minValue, maxValue, hasHardDeprecatedAsset) = _getVaultValue();

        for (uint8 i = 0; i < l.childChains.length; i++) {
            if (_childIsInactive(l.childChains[i])) {
                continue;
            }
            require(
                _isNotStale(l.chainTotalValues[l.childChains[i]].lastUpdate),
                'stale'
            );
            minValue += l.chainTotalValues[l.childChains[i]].minValue;
            maxValue += l.chainTotalValues[l.childChains[i]].maxValue;
            if (l.chainTotalValues[l.childChains[i]].hasHardDeprecatedAsset) {
                hasHardDeprecatedAsset = true;
            }
        }
    }

    function _unitPrice() internal view returns (uint minPrice, uint maxPrice) {
        (uint minValue, uint maxValue, ) = _totalValueAcrossAllChains();
        minPrice = _unitPrice(minValue, _totalShares());
        maxPrice = _unitPrice(maxValue, _totalShares());
    }

    function _childChains(uint index) internal view returns (uint16 chainId) {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        return l.childChains[index];
    }

    function _allChildChains() internal view returns (uint16[] memory) {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        return l.childChains;
    }

    function _children(uint16 chainId) internal view returns (address) {
        return VaultParentStorage.layout().children[chainId];
    }

    function _timeUntilExpiry() internal view returns (uint) {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();
        uint timeTillExpiry;
        for (uint8 i = 0; i < l.childChains.length; i++) {
            uint expiryTime = _timeUntilExpiry(
                l.chainTotalValues[l.childChains[i]].lastUpdate
            );
            // The shortest expiry time is the time until expiry
            if (expiryTime == 0) {
                return 0;
            } else {
                if (expiryTime < timeTillExpiry || timeTillExpiry == 0) {
                    timeTillExpiry = expiryTime;
                }
            }
        }
        return timeTillExpiry;
    }

    function _vaultClosed() internal view returns (bool) {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        return l.vaultClosed;
    }

    function _timeUntilExpiry(uint lastUpdate) internal view returns (uint) {
        uint expiry = lastUpdate + _registry().livelinessThreshold();
        if (expiry > block.timestamp) {
            return expiry - block.timestamp;
        } else {
            return 0;
        }
    }

    function _isNotStale(uint lastUpdate) internal view returns (bool) {
        return lastUpdate > block.timestamp - _registry().livelinessThreshold();
    }

    function _requiresSyncForFees(uint tokenId) internal view returns (bool) {
        if (!_hasActiveChildren() || !_requiresUnitPrice(tokenId)) {
            return false;
        }
        return true;
    }

    function _requiresUnitPrice(uint tokenId) internal view returns (bool) {
        if (isSystemToken(tokenId)) {
            return false;
        }
        if (
            (_managerPerformanceFee() == 0 &&
                _holdings(tokenId).performanceFee == 0)
        ) {
            return false;
        }

        return true;
    }

    function _unitPrice(
        uint totalValueAcrossAllChains,
        uint totalShares
    ) internal pure returns (uint price) {
        price =
            (totalValueAcrossAllChains * Constants.VAULT_PRECISION) /
            totalShares;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ITransport } from '../transport/ITransport.sol';
import { Registry } from '../registry/Registry.sol';
import { Constants } from '../lib/Constants.sol';
import { RegistryStorage } from '../registry/RegistryStorage.sol';
import { VaultParentStorage } from './VaultParentStorage.sol';
import { VaultParentInternal } from './VaultParentInternal.sol';
import { VaultBaseInternal } from '../vault-base/VaultBaseInternal.sol';
import { VaultOwnershipInternal } from '../vault-ownership/VaultOwnershipInternal.sol';
import { VaultRiskProfile } from '../vault-base/IVaultRiskProfile.sol';

import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';
import { SafeERC20 } from '@solidstate/contracts/utils/SafeERC20.sol';

contract VaultParentInvestor is VaultParentInternal {
    using SafeERC20 for IERC20;

    event Deposit(
        address depositer,
        uint tokenId,
        address asset,
        uint amount,
        uint currentUnitPrice,
        uint shares
    );

    event WithdrawMultiChain(
        address withdrawer,
        uint tokenId,
        uint portion,
        uint currentUnitPrice,
        uint shares
    );

    modifier isInSync() {
        require(_inSync(), 'not synced');
        _;
    }

    modifier noWithdrawInProgress() {
        require(!_withdrawInProgress(), 'withdraw in progress');
        _;
    }

    function requestTotalValueUpdateMultiChain(
        uint[] memory lzFees
    ) external payable noBridgeInProgress noWithdrawInProgress whenNotPaused {
        _requestTotalValueUpdateMultiChain(lzFees);
    }

    // This allows our DepositAutomator to call deposit on behalf of the depositor
    function depositFor(
        address owner,
        uint tokenId,
        address asset,
        uint amount
    )
        external
        vaultNotClosed
        noBridgeInProgress
        isInSync
        whenNotPaused
        nonReentrant
    {
        _deposit(owner, tokenId, asset, amount);
    }

    function deposit(
        uint tokenId,
        address asset,
        uint amount
    )
        external
        vaultNotClosed
        noBridgeInProgress
        isInSync
        whenNotPaused
        nonReentrant
    {
        _deposit(msg.sender, tokenId, asset, amount);
    }

    function withdrawMultiChain(
        uint tokenId,
        uint amount,
        uint[] memory lzFees
    ) external payable noBridgeInProgress whenNotPaused nonReentrant {
        _withdrawMultiChain(tokenId, amount, lzFees);
    }

    function withdrawAllMultiChain(
        uint tokenId,
        uint[] memory lzFees
    ) external payable noBridgeInProgress whenNotPaused nonReentrant {
        _withdrawAll(tokenId, lzFees);
    }

    function getLzFee(
        bytes4 sigHash,
        uint16 chainId
    ) external view returns (uint fee) {
        return _getLzFee(sigHash, chainId);
    }

    function getLzFeesMultiChain(
        bytes4 sigHash
    ) external view returns (uint[] memory lzFees, uint256 totalSendFee) {
        return _getLzFeesMultiChain(sigHash, _allChildChains());
    }

    function childChains(uint index) external view returns (uint16) {
        return _childChains(index);
    }

    function children(uint16 chainId) external view returns (address) {
        return _children(chainId);
    }

    function allChildChains() external view returns (uint16[] memory) {
        return _allChildChains();
    }

    function totalValueAcrossAllChains()
        external
        view
        returns (uint minValue, uint maxValue, bool hasHardDeprecatedAsset)
    {
        return _totalValueAcrossAllChains();
    }

    function inSync() external view returns (bool) {
        return _inSync();
    }

    function withdrawInProgress() external view returns (bool) {
        return _withdrawInProgress();
    }

    function requiresSyncForWithdraw(
        uint tokenId
    ) external view returns (bool) {
        return _requiresSyncForFees(tokenId);
    }

    function requiresSyncForDeposit() external view returns (bool) {
        return _requiresSyncForDeposit();
    }

    // Returns the number of seconds until the totalValueSync expires
    function timeUntilExpiry() external view returns (uint) {
        return _timeUntilExpiry();
    }

    function holdingLocked(uint tokenId) external view returns (bool) {
        return _holdingLocked(tokenId);
    }

    ///
    /// Internal
    ///

    function _deposit(
        address owner,
        uint tokenId,
        address asset,
        uint amount
    ) internal {
        require(_registry().depositAssets(asset), 'not deposit asset');

        // Hack for now to limit each user to 1 holding accept the manager
        // Who can have fee holding + another holding
        // transferring of tokens is currently disabled
        if (tokenId == 0) {
            uint numHoldings = _balanceOf(owner);
            if (owner == _manager()) {
                require(numHoldings < 2, 'manager already owns holdings');
            } else {
                require(numHoldings < 1, 'already owns holding');
            }
        }
        // Vaults that have hard deprecated assets cannot be valued accurately
        // Therefore deposits are blocked until the manager trades out of the asset
        (
            ,
            uint maxVaultValue,
            bool hasHardDeprecatedAsset
        ) = _totalValueAcrossAllChains();

        require(!hasHardDeprecatedAsset, 'holds hard deprecated asset');

        uint totalShares = _totalShares();

        if (totalShares > 0 && maxVaultValue == 0) {
            // This means all the shares issue are currently worthless
            // We can't issue anymore shares
            revert('vault closed');
        }
        (uint depositValueInUSD, ) = _registry().accountant().assetValue(
            asset,
            amount
        );

        uint customCapForVault = _registry().customVaultValueCap(address(this));

        if (customCapForVault > 0) {
            require(
                maxVaultValue + depositValueInUSD <= customCapForVault,
                'vault will exceed custom cap'
            );
        } else {
            require(
                maxVaultValue + depositValueInUSD <=
                    _registry().vaultValueCap(),
                'vault will exceed cap'
            );
        }

        // if tokenId == 0 means were creating a new holding
        if (tokenId == 0) {
            require(
                depositValueInUSD >= _registry().minDepositAmount(),
                'min deposit not met'
            );
        }

        // Note: that we are taking the deposit asset from the msg.sender not owner
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        _updateActiveAsset(asset);

        uint shares;
        uint currentUnitPrice;
        if (totalShares == 0) {
            shares = depositValueInUSD;
            // We should debate if the base unit of the vaults is to be 10**18 or 10**8.
            // 10**8 is the natural unit for USD (which is what the unitPrice is denominated in),
            // but 10**18 gives us more precision when it comes to leveling fees.
            currentUnitPrice = _unitPrice(depositValueInUSD, shares);
        } else {
            shares = (depositValueInUSD * totalShares) / maxVaultValue;
            // Don't used unitPrice() because it will encorporate the deposited funds, but shares haven't been issue yet
            currentUnitPrice = _unitPrice(maxVaultValue, totalShares);
        }

        uint issuedToTokenId = _issueShares(
            tokenId,
            owner,
            shares,
            currentUnitPrice,
            _registry().depositLockupTime(),
            _registry().protocolFeeBips()
        );

        uint holdingTotalShares = _holdings(issuedToTokenId).totalShares;
        uint holdingTotalValue = (currentUnitPrice * holdingTotalShares) /
            Constants.VAULT_PRECISION;

        // If the vault has a custom cap
        // there is not holding maxDepositAmount
        require(
            customCapForVault > 0 ||
                holdingTotalValue <= _registry().maxDepositAmount(),
            'exceeds max deposit'
        );

        emit Deposit(
            owner,
            issuedToTokenId,
            asset,
            amount,
            currentUnitPrice,
            shares
        );
        _registry().emitEvent();
    }

    function _withdrawAll(uint tokenId, uint[] memory lzFees) internal {
        _levyFees(
            tokenId,
            _getFeeLevyUnitPrice(tokenId),
            _registry().protocolFeeBips()
        );
        _withdrawMultiChain(tokenId, _holdings(tokenId).totalShares, lzFees);
    }

    function _withdrawMultiChain(
        uint tokenId,
        uint amount,
        uint[] memory lzFees
    ) internal {
        address owner = _ownerOf(tokenId);
        require(
            msg.sender == owner ||
                msg.sender == _registry().withdrawAutomator(),
            'not allowed'
        );

        uint portion = (amount * Constants.PORTION_DIVISOR) / _totalShares();
        uint minUnitPrice = _getFeeLevyUnitPrice(tokenId);

        _burnShares(
            tokenId,
            amount,
            minUnitPrice,
            _registry().protocolFeeBips()
        );
        _withdraw(tokenId, owner, portion);
        _adjustCachedChainTotalValues(portion);
        _sendWithdrawRequestsToChildrenMultiChain(
            tokenId,
            owner,
            portion,
            lzFees
        );

        emit WithdrawMultiChain(owner, tokenId, portion, minUnitPrice, amount);
        _registry().emitEvent();
    }

    // We want to allow multiple withdraws to be processed at once.
    // And not block deposits during withdraw.
    // Because we are burning shares, during withdraw
    // We must adjusted the cached values for all the child vaults proportionally
    // Otherwise the unitPrice will be incorrect
    // Because these values are taken before the withdraw is processed on the destination
    // We block requestTotalValueUpdateMultiChain & receiveChildValue until all withdraws are 100% complete.
    function _adjustCachedChainTotalValues(uint withdrawnPortion) internal {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        for (uint8 i = 0; i < l.childChains.length; i++) {
            if (_childIsInactive(l.childChains[i])) {
                continue;
            }

            l.chainTotalValues[l.childChains[i]].minValue -=
                (l.chainTotalValues[l.childChains[i]].minValue *
                    withdrawnPortion) /
                Constants.PORTION_DIVISOR;
            l.chainTotalValues[l.childChains[i]].maxValue -=
                (l.chainTotalValues[l.childChains[i]].maxValue *
                    withdrawnPortion) /
                Constants.PORTION_DIVISOR;
        }
    }

    ///
    /// Cross Chain Requests
    ///

    function _requestTotalValueUpdateMultiChain(uint[] memory lzFees) internal {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        uint totalFees;

        for (uint8 i = 0; i < l.childChains.length; i++) {
            if (_childIsInactive(l.childChains[i])) {
                require(lzFees[i] == 0, 'no fee required');
                continue;
            }
            totalFees += lzFees[i];
            uint16 childChainId = l.childChains[i];

            _registry().transport().sendValueUpdateRequest{ value: lzFees[i] }(
                ITransport.ValueUpdateRequest({
                    parentChainId: _registry().chainId(),
                    parentVault: address(this),
                    child: ITransport.ChildVault({
                        vault: l.children[childChainId],
                        chainId: childChainId
                    })
                })
            );
        }

        require(msg.value >= totalFees, 'insufficient fee sent');
    }

    function _sendWithdrawRequestsToChildrenMultiChain(
        uint tokenId,
        address withdrawer,
        uint portion,
        uint[] memory lzFees
    ) internal {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();
        uint totalFees;
        for (uint8 i = 0; i < l.childChains.length; i++) {
            if (_childIsInactive(l.childChains[i])) {
                require(lzFees[i] == 0, 'no fee required');
                continue;
            }
            totalFees += lzFees[i];
            _sendWithdrawRequest(
                l.childChains[i],
                tokenId,
                withdrawer,
                portion,
                lzFees[i]
            );
        }
        require(msg.value >= totalFees, 'insufficient fee');
    }

    function _sendWithdrawRequest(
        uint16 dstChainId,
        uint tokenId,
        address withdrawer,
        uint portion,
        uint sendFee
    ) internal {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();
        l.withdrawsInProgress++;
        _registry().transport().sendWithdrawRequest{ value: sendFee }(
            ITransport.WithdrawRequest({
                parentChainId: _registry().chainId(),
                parentVault: address(this),
                child: ITransport.ChildVault({
                    chainId: dstChainId,
                    vault: l.children[dstChainId]
                }),
                tokenId: tokenId,
                withdrawer: withdrawer,
                portion: portion
            })
        );
    }

    function _getFeeLevyUnitPrice(uint tokenId) internal view returns (uint) {
        // If a Manager is not charging a performance fee we do not need the currentUnitPrice
        // to process a withdraw, because all withdraws are porpotional.
        // In addition if the tokendId is System Token (manager, protocol). We don't levy fees on these tokens.
        // I don't really like smuggling this logic in here at this level
        // But it means that if a manager isn't charging a performanceFee then we don't have to impose a totalValueSync
        uint minUnitPrice;
        if (!_inSync() && !_requiresUnitPrice(tokenId)) {
            minUnitPrice = 0;
        } else {
            // This will revert if the vault is not in sync
            // We are discarding hasHardDeprecatedAsset because we don't want to block withdraws
            (minUnitPrice, ) = _unitPrice();
        }

        return minUnitPrice;
    }

    function _requiresSyncForDeposit() internal view returns (bool) {
        if (_hasActiveChildren()) {
            return true;
        }
        return false;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ITransport } from '../transport/ITransport.sol';
import { IStargateRouter } from '@layerzerolabs/solidity-examples/contracts/interfaces/IStargateRouter.sol';
import { VaultParentStorage } from './VaultParentStorage.sol';
import { VaultParentInternal } from './VaultParentInternal.sol';
import { IVaultParentManager } from './IVaultParentManager.sol';
import { Constants } from '../lib/Constants.sol';
import { VaultOwnershipStorage } from '../vault-ownership/VaultOwnershipStorage.sol';

import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';
import { SafeERC20 } from '@solidstate/contracts/utils/SafeERC20.sol';

contract VaultParentManager is VaultParentInternal, IVaultParentManager {
    using SafeERC20 for IERC20;

    uint public constant CLOSE_FEE = 0.027 ether;

    event FundClosed();

    function closeVault()
        external
        payable
        vaultNotClosed
        onlyManager
        whenNotPaused
    {
        require(msg.value >= CLOSE_FEE, 'insufficient fee');
        (bool sent, ) = _registry().protocolTreasury().call{ value: msg.value }(
            ''
        );
        require(sent, 'Failed to process close fee');
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        l.vaultClosed = true;
        _registry().emitEvent();
        emit FundClosed();
    }

    function setDiscountForHolding(
        uint tokenId,
        uint streamingFeeDiscount,
        uint performanceFeeDiscount
    ) external onlyManager whenNotPaused {
        _setDiscountForHolding(
            tokenId,
            streamingFeeDiscount,
            performanceFeeDiscount
        );
    }

    function levyFeesOnHoldings(
        uint[] memory tokenIds
    ) external onlyManager whenNotPaused {
        uint minUnitPrice;
        bool isInSync = _inSync();
        if (isInSync) {
            (minUnitPrice, ) = _unitPrice();
        }

        for (uint i = 0; i < tokenIds.length; i++) {
            require(
                block.timestamp >=
                    _holdings(tokenIds[i]).lastManagerFeeLevyTime + 24 hours,
                'already levied this period'
            );
            // If the manager has performance fees enabled and its a multichain
            // vault we must sync the vault before levying fees so we have the correct unitPrice
            if (!isInSync && _requiresSyncForFees(tokenIds[i])) {
                revert('vault not in sync');
            }
            _levyFees(tokenIds[i], minUnitPrice, _registry().protocolFeeBips());
        }
        _registry().emitEvent();
    }

    /// Fees

    function announceFeeIncrease(
        uint256 newStreamingFee,
        uint256 newPerformanceFee
    ) external onlyManager whenNotPaused {
        require(_registry().canChangeManagerFees(), 'fee change disabled');
        _announceFeeIncrease(newStreamingFee, newPerformanceFee);
        _registry().emitEvent();
    }

    function commitFeeIncrease() external onlyManager whenNotPaused {
        _commitFeeIncrease();
        _registry().emitEvent();
    }

    function renounceFeeIncrease() external onlyManager whenNotPaused {
        _renounceFeeIncrease();
        _registry().emitEvent();
    }

    // Manager Actions

    function sendBridgeApproval(
        uint16 dstChainId,
        uint lzFee
    )
        external
        payable
        onlyManager
        noBridgeInProgress
        whenNotPaused
        nonReentrant
    {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();
        require(msg.value >= lzFee, 'insufficient fee');
        // If the bridge approval is cancelled the manager is block from initiating another for 1 hour
        // This protects users from being ddos'd and not being able to withdraw
        // because the manager keeps applying a bridge lock
        require(
            l.lastBridgeCancellation + 1 hours < block.timestamp,
            'bridge approval timeout'
        );
        address dstVault = l.children[dstChainId];
        require(dstVault != address(0), 'no dst vault');
        l.bridgeInProgress = true;
        l.bridgeApprovedFor = dstChainId;

        _registry().transport().sendBridgeApproval{ value: lzFee }(
            ITransport.BridgeApprovalRequest({
                approvedChainId: dstChainId,
                approvedVault: dstVault
            })
        );
    }

    function requestBridgeToChain(
        uint16 dstChainId,
        address asset,
        uint amount,
        uint minAmountOut,
        uint lzFee
    )
        external
        payable
        onlyManager
        noBridgeInProgress
        whenNotPaused
        nonReentrant
    {
        require(msg.value >= lzFee, 'insufficient fee');
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        address dstVault = l.children[dstChainId];
        require(dstVault != address(0), 'no dst vault');
        l.bridgeInProgress = true;
        // Once the manager has bridged we must include the childChains in our total value
        l.childIsInactive[dstChainId] = false;
        _bridgeAsset(
            dstChainId,
            dstVault,
            _registry().chainId(),
            address(this),
            asset,
            amount,
            minAmountOut,
            lzFee
        );
    }

    function requestCreateChild(
        uint16 newChainId,
        uint lzFee
    ) external payable onlyManager whenNotPaused nonReentrant {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();
        require(msg.value >= lzFee, 'insufficient fee');

        require(!l.childCreationInProgress, 'sibling creation inprogress');
        require(l.children[newChainId] == address(0), 'sibling exists');
        require(newChainId != _registry().chainId(), 'not same chain');
        l.childCreationInProgress = true;
        ITransport.ChildVault[]
            memory existingChildren = new ITransport.ChildVault[](
                l.childChains.length
            );

        for (uint8 i = 0; i < l.childChains.length; i++) {
            existingChildren[i].chainId = l.childChains[i];
            existingChildren[i].vault = l.children[l.childChains[i]];
        }
        _registry().transport().sendVaultChildCreationRequest{ value: lzFee }(
            ITransport.VaultChildCreationRequest({
                parentVault: address(this),
                parentChainId: _registry().chainId(),
                newChainId: newChainId,
                manager: _manager(),
                riskProfile: _riskProfile(),
                children: existingChildren
            })
        );
    }

    function changeManagerMultiChain(
        address newManager,
        uint[] memory lzFees
    ) external payable onlyManager whenNotPaused nonReentrant {
        require(_registry().canChangeManager(), 'manager change disabled');
        require(newManager != address(0), 'invalid newManager');
        address oldManager = _manager();
        _changeManager(newManager);
        _transfer(oldManager, newManager, _MANAGER_TOKEN_ID);
        _sendChangeManagerRequestToChildren(newManager, lzFees);
    }

    function hasActiveChildren() external view returns (bool) {
        return _hasActiveChildren();
    }

    function totalShares() external view returns (uint) {
        return _totalShares();
    }

    function unitPrice() external view returns (uint minPrice, uint maxPrice) {
        return _unitPrice();
    }

    function holdings(
        uint tokenId
    ) external view returns (VaultOwnershipStorage.Holding memory) {
        return _holdings(tokenId);
    }

    function bridgeInProgress() external view returns (bool) {
        return _bridgeInProgress();
    }

    function bridgeApprovedFor() external view returns (uint16) {
        return _bridgeApprovedFor();
    }

    function calculateUnpaidFees(
        uint tokenId,
        uint currentUnitPrice
    ) external view returns (uint streamingFees, uint performanceFees) {
        return _calculateUnpaidFees(tokenId, currentUnitPrice);
    }

    function vaultClosed() external view returns (bool) {
        return _vaultClosed();
    }

    function requiresSyncForFees(uint tokenId) external view returns (bool) {
        return _requiresSyncForFees(tokenId);
    }

    /// Fees

    function managerPerformanceFee() external view returns (uint) {
        return _managerPerformanceFee();
    }

    function managerStreamingFee() external view returns (uint) {
        return _managerStreamingFee();
    }

    function announcedManagerPerformanceFee() external view returns (uint) {
        return _announcedManagerPerformanceFee();
    }

    function announcedManagerStreamingFee() external view returns (uint) {
        return _announcedManagerStreamingFee();
    }

    function announcedFeeIncreaseTimestamp() external view returns (uint) {
        return _announcedFeeIncreaseTimestamp();
    }

    function protocolFee(uint managerFees) external view returns (uint) {
        return _protocolFee(managerFees, _registry().protocolFeeBips());
    }

    function VAULT_PRECISION() external pure returns (uint) {
        return Constants.VAULT_PRECISION;
    }

    function performanceFee(
        uint fee,
        uint discount,
        uint _totalShares,
        uint tokenPriceStart,
        uint tokenPriceFinish
    ) external pure returns (uint tokensOwed) {
        return
            _performanceFee(
                fee,
                discount,
                _totalShares,
                tokenPriceStart,
                tokenPriceFinish
            );
    }

    function streamingFee(
        uint fee,
        uint discount,
        uint lastFeeTime,
        uint _totalShares,
        uint timeNow
    ) external pure returns (uint tokensOwed) {
        return _streamingFee(fee, discount, lastFeeTime, _totalShares, timeNow);
    }

    function FEE_ANNOUNCE_WINDOW() external pure returns (uint) {
        return _FEE_ANNOUNCE_WINDOW;
    }

    function MAX_STREAMING_FEE_BASIS_POINTS() external pure returns (uint) {
        return _MAX_STREAMING_FEE_BASIS_POINTS;
    }

    function MAX_STREAMING_FEE_BASIS_POINTS_STEP()
        external
        pure
        returns (uint)
    {
        return _MAX_STREAMING_FEE_BASIS_POINTS_STEP;
    }

    function MAX_PERFORMANCE_FEE_BASIS_POINTS() external pure returns (uint) {
        return _MAX_PERFORMANCE_FEE_BASIS_POINTS;
    }

    function STEAMING_FEE_DURATION() external pure returns (uint) {
        return _STEAMING_FEE_DURATION;
    }

    function MANAGER_TOKEN_ID() external pure returns (uint) {
        return _MANAGER_TOKEN_ID;
    }

    function PROTOCOL_TOKEN_ID() external pure returns (uint) {
        return _PROTOCOL_TOKEN_ID;
    }

    function MAX_PERFORMANCE_FEE_BASIS_POINTS_STEP()
        external
        pure
        returns (uint)
    {
        return _MAX_PERFORMANCE_FEE_BASIS_POINTS_STEP;
    }

    function _sendChangeManagerRequestToChildren(
        address newManager,
        uint[] memory lzFees
    ) internal {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();
        uint totalFees;
        for (uint8 i = 0; i < l.childChains.length; i++) {
            totalFees += lzFees[i];
            _sendChangeManagerRequest(l.childChains[i], newManager, lzFees[i]);
        }
        require(msg.value >= totalFees, 'insufficient fee');
    }

    function _sendChangeManagerRequest(
        uint16 dstChainId,
        address newManager,
        uint sendFee
    ) internal {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        _registry().transport().sendChangeManagerRequest{ value: sendFee }(
            ITransport.ChangeManagerRequest({
                child: ITransport.ChildVault({
                    chainId: dstChainId,
                    vault: l.children[dstChainId]
                }),
                newManager: newManager
            })
        );
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { Proxy } from '@solidstate/contracts/proxy/Proxy.sol';
import { IDiamondReadable } from '@solidstate/contracts/proxy/diamond/readable/IDiamondReadable.sol';

contract VaultParentProxy is Proxy {
    address private immutable DIAMOND;

    constructor(address diamond) {
        DIAMOND = diamond;
    }

    function _getImplementation() internal view override returns (address) {
        return IDiamondReadable(DIAMOND).facetAddress(msg.sig);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library VaultParentStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('valio.storage.vaultParent');

    // solhint-disable-next-line ordering
    struct ChainValue {
        uint minValue;
        uint lastUpdate;
        uint maxValue;
        bool hasHardDeprecatedAsset;
    }

    // solhint-disable-next-line ordering
    struct Layout {
        bytes32 _deprecated_vaultId;
        bool childCreationInProgress;
        bool bridgeInProgress;
        uint lastBridgeCancellation;
        uint withdrawsInProgress;
        uint16[] childChains;
        // chainId => childVault address
        mapping(uint16 => address) children;
        mapping(uint16 => ChainValue) chainTotalValues;
        uint16 bridgeApprovedFor;
        // Not a big fan of inverted flags, but some vaults were already deployed.
        // Would have preferred to have childIsActive
        mapping(uint16 => bool) childIsInactive;
        bool vaultClosed;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ITransport } from '../transport/ITransport.sol';
import { VaultParentInternal } from '../vault-parent/VaultParentInternal.sol';
import { VaultParentStorage } from './VaultParentStorage.sol';

contract VaultParentTransport is VaultParentInternal {
    event ReceivedChildValue();
    event ReceivedWithdrawComplete(uint withdrawsStillInProgress);
    event ReceivedChildCreated(uint16 childChainId, address childVault);

    ///
    /// Receivers/CallBacks
    ///

    function receiveWithdrawComplete() external onlyTransport {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        l.withdrawsInProgress--;
        _registry().emitEvent();
        emit ReceivedWithdrawComplete(l.withdrawsInProgress);
    }

    // Callback for once the sibling has been created on the dstChain
    function receiveChildCreated(
        uint16 childChainId,
        address childVault
    ) external onlyTransport {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        if (l.children[childChainId] == address(0)) {
            l.childCreationInProgress = false;
            l.childIsInactive[childChainId] = true;
            for (uint8 i = 0; i < l.childChains.length; i++) {
                // Federate the new sibling to the other children
                _registry().transport().sendAddSiblingRequest(
                    ITransport.AddVaultSiblingRequest({
                        // The existing child
                        child: ITransport.ChildVault({
                            vault: l.children[l.childChains[i]],
                            chainId: l.childChains[i]
                        }),
                        // The new Sibling
                        newSibling: ITransport.ChildVault({
                            vault: childVault,
                            chainId: childChainId
                        })
                    })
                );
            }
            // It's important these are here and not before the for loop
            // We only want to iterate over the existing children
            l.children[childChainId] = childVault;
            l.childChains.push(childChainId);

            _registry().emitEvent();
            emit ReceivedChildCreated(childChainId, childVault);
        }
    }

    // Callback to notify the parent the bridge has taken place
    function receiveBridgedAssetAcknowledgement(
        uint16 receivingChainId
    ) external onlyTransport {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();
        // While a bridge is underway everything is locked (deposits/withdraws etc)
        // Once the bridge is complete we need to clear the stale values we have for the childVaults
        // If a requestTotalSync completes (which is valid for 10 mins),
        // then a bridge takes place from a child to the parent and completes within 10 mins,
        // then the parent will have stale values for the childVaults but the extra value from the bridge
        // This enforces that a requestTotalSync must happen after a bridge completes.
        for (uint8 i = 0; i < l.childChains.length; i++) {
            l.chainTotalValues[l.childChains[i]].lastUpdate = 0;
        }
        // Update the childChain to be active
        l.childIsInactive[receivingChainId] = false;
        l.bridgeInProgress = false;
        l.bridgeApprovedFor = 0;
    }

    // Allows the bridge approval to be cancelled by the receiver
    // after a period of time if the bridge doesn't take place
    function receiveBridgeApprovalCancellation(
        address requester
    ) external onlyTransport {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        l.bridgeInProgress = false;
        l.bridgeApprovedFor = 0;
        if (requester != _manager()) {
            l.lastBridgeCancellation = block.timestamp;
        }
    }

    // Callback to receive value/supply updates
    function receiveChildValue(
        uint16 childChainId,
        uint minValue,
        uint maxValue,
        uint time,
        bool hasHardDeprecatedAsset
    ) external onlyTransport {
        // We don't accept value updates while WithdrawInProgress
        // As the value could be stale (from before the withdraw is executed)
        // We also don't allow requestTotalValueUpdateMultiChain to be called
        // until all withdraw processing on all chains is complete.
        // We adjust the min and maxValues proportionally after each withdraw
        if (!_withdrawInProgress()) {
            VaultParentStorage.Layout storage l = VaultParentStorage.layout();

            l.chainTotalValues[childChainId] = VaultParentStorage.ChainValue({
                minValue: minValue,
                maxValue: maxValue,
                lastUpdate: time,
                hasHardDeprecatedAsset: hasHardDeprecatedAsset
            });

            _registry().emitEvent();
            emit ReceivedChildValue();
        }
    }
}