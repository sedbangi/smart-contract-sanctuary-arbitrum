# SPDX-License-Identifier: AGPL-3.0

event Set:
    name: bytes32
    meta: bytes32
    data: bytes32
    key:  bytes32

struct Value:
    meta: bytes32
    data: bytes32

LOCK: public(constant(uint256)) = 1

map: HashMap[bytes32, Value]

@external
@view
def get(key: bytes32) -> Value:
    return self.map[key]

@external
def set(name: bytes32, meta: bytes32, data: bytes32):
    key: bytes32 = keccak256(_abi_encode(msg.sender, name))
    if convert(self.map[key].meta, uint256) & 1 == LOCK: raise "LOCKED"
    self.map[key] = Value({meta: meta, data: data})
    log Set(name, meta, data, key)

@external
def key(name: bytes32) -> bytes32:
    return keccak256(_abi_encode(msg.sender, name))