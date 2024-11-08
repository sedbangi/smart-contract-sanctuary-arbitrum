// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./auth/OwnableRoles.sol";

contract AlignIdRegistry is OwnableRoles {
  // ids
  mapping(address owner => uint256 alignId) public idOf;
  error IdExists();
  error NoId();
  error IncorrectId();
  error IncorrectAmount();
  error SourceHasNoId();
  error DestinationHasId();
  error NotOwner();
  error Paused();
  error NoTreasurySet();

  // Role constants
  uint256 public constant PAUSER_ROLE = 1 << 0;
  uint256 public constant WITHDRAWER_ROLE = 1 << 1;
  uint256 public constant FEE_SETTER_ROLE = 1 << 2;

  // Treasury
  address public treasury;

  bool public paused;

  uint256 public idCounter;
  uint256 public protocolFee;

  /// @notice Emitted when a new ID is registered
  /// @param to The address of the user being registered
  /// @param id The unique ID assigned to the user
  event AlignIdRegistered(address indexed to, uint256 indexed id);

  /// @notice Emitted when a new ID is transferred
  /// @param id The unique ID assigned to the user
  /// @param from The address of the user being transferred
  /// @param to The address of the user being transferred
  event Transfer(uint256 indexed id, address indexed from, address indexed to);

  /// @notice Emitted when the protocol fee is updated
  /// @param newFee The new protocol fee in wei
  event ProtocolFeeUpdated(uint256 newFee);

  /// @notice Emitted when the contract is paused or unpaused
  event PausedState(bool paused);

  /// @notice Emitted when funds are withdrawn
  /// @param amount The amount of funds withdrawn
  event Withdrawn(uint256 amount);

  /// @notice Emitted when the treasury address is updated
  /// @param newTreasury The new treasury address
  event TreasuryUpdated(address newTreasury);

  constructor(uint256 _initialFee, address _treasury) {
    _initializeOwner(msg.sender);
    protocolFee = _initialFee;
    treasury = _treasury;
  }

  /// @notice Registers a new ID for a user
  /// @return alignId The new unique ID assigned to the user
  /// @dev Emits a `Register` event upon successful registration
  function register() public payable returns (uint256 alignId) {
    if (paused) revert Paused();

    if (msg.value != protocolFee) {
      revert IncorrectAmount();
    }
    if (idOf[msg.sender] != 0) {
      revert IdExists();
    }

    alignId = ++idCounter;

    idOf[msg.sender] = alignId;

    emit AlignIdRegistered(msg.sender, alignId);
  }

  /// @notice Registers a new ID for a user on behalf of another address
  /// @param to The address to register the ID for
  /// @return alignId The new unique ID assigned to the user
  /// @dev Emits a `AlignIdRegistered` event upon successful registration
  function registerTo(address to) public payable returns (uint256 alignId) {
    if (paused) revert Paused();

    if (msg.value != protocolFee) {
      revert IncorrectAmount();
    }
    if (idOf[to] != 0) {
      revert IdExists();
    }

    alignId = ++idCounter;

    idOf[to] = alignId;

    emit AlignIdRegistered(to, alignId);
  }

  /// @notice Retrieves or assigns an ID for a given address
  /// @param to The address to retrieve or assign an ID for
  /// @return alignId The ID of the given address
  function readId(address to) public view returns (uint256 alignId) {
    // if no id, then revert
    alignId = idOf[to];
    if (alignId == 0) revert NoId();
  }

  function transfer(address from, address to) public {
    if (idOf[from] == 0) revert SourceHasNoId();

    if (idOf[to] != 0) revert DestinationHasId();

    if (msg.sender != from) revert NotOwner();

    uint256 idToTransfer = idOf[from];

    idOf[to] = idToTransfer;
    delete idOf[from];

    emit Transfer(idToTransfer, from, to);
  }

  /// @notice Allows the owner to update the protocol fee
  /// @param newFee The new protocol fee in wei
  function setProtocolFee(uint256 newFee) public onlyRolesOrOwner(FEE_SETTER_ROLE) {
    protocolFee = newFee;
    emit ProtocolFeeUpdated(newFee);
  }

  /// @notice Allows the owner to set the treasury address
  /// @param newTreasury The new treasury address
  function setTreasury(address newTreasury) public onlyOwner {
    if (newTreasury == address(0)) revert NoTreasurySet();
    treasury = newTreasury;
    emit TreasuryUpdated(newTreasury);
  }

  /// @notice Allows the owner to withdraw collected fees
  function withdraw() public onlyRolesOrOwner(WITHDRAWER_ROLE) {
    if (treasury == address(0)) {
      revert NoTreasurySet();
    }
    (bool success, ) = payable(treasury).call{ value: address(this).balance }("");
    require(success, "Withdraw failed");
  }

  /// @notice Allows the owner or pauser to pause or unpause the contract
  function setPaused(bool _paused) public onlyRolesOrOwner(PAUSER_ROLE) {
    paused = _paused;
    emit PausedState(paused);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { Ownable } from "./Ownable.sol";

/// @notice Simple single owner and multiroles authorization mixin.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/auth/Ownable.sol)
/// @dev While the ownable portion follows [EIP-173](https://eips.ethereum.org/EIPS/eip-173)
/// for compatibility, the nomenclature for the 2-step ownership handover and roles
/// may be unique to this codebase.
abstract contract OwnableRoles is Ownable {
  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           EVENTS                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @dev The `user`'s roles is updated to `roles`.
  /// Each bit of `roles` represents whether the role is set.
  event RolesUpdated(address indexed user, uint256 indexed roles);

  /// @dev `keccak256(bytes("RolesUpdated(address,uint256)"))`.
  uint256 private constant _ROLES_UPDATED_EVENT_SIGNATURE =
    0x715ad5ce61fc9595c7b415289d59cf203f23a94fa06f04af7e489a0a76e1fe26;

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                          STORAGE                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @dev The role slot of `user` is given by:
  /// ```
  ///     mstore(0x00, or(shl(96, user), _ROLE_SLOT_SEED))
  ///     let roleSlot := keccak256(0x00, 0x20)
  /// ```
  /// This automatically ignores the upper bits of the `user` in case
  /// they are not clean, as well as keep the `keccak256` under 32-bytes.
  ///
  /// Note: This is equivalent to `uint32(bytes4(keccak256("_OWNER_SLOT_NOT")))`.
  uint256 private constant _ROLE_SLOT_SEED = 0x8b78c6d8;

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                     INTERNAL FUNCTIONS                     */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @dev Overwrite the roles directly without authorization guard.
  function _setRoles(address user, uint256 roles) internal virtual {
    /// @solidity memory-safe-assembly
    assembly {
      mstore(0x0c, _ROLE_SLOT_SEED)
      mstore(0x00, user)
      // Store the new value.
      sstore(keccak256(0x0c, 0x20), roles)
      // Emit the {RolesUpdated} event.
      log3(0, 0, _ROLES_UPDATED_EVENT_SIGNATURE, shr(96, mload(0x0c)), roles)
    }
  }

  /// @dev Updates the roles directly without authorization guard.
  /// If `on` is true, each set bit of `roles` will be turned on,
  /// otherwise, each set bit of `roles` will be turned off.
  function _updateRoles(address user, uint256 roles, bool on) internal virtual {
    /// @solidity memory-safe-assembly
    assembly {
      mstore(0x0c, _ROLE_SLOT_SEED)
      mstore(0x00, user)
      let roleSlot := keccak256(0x0c, 0x20)
      // Load the current value.
      let current := sload(roleSlot)
      // Compute the updated roles if `on` is true.
      let updated := or(current, roles)
      // Compute the updated roles if `on` is false.
      // Use `and` to compute the intersection of `current` and `roles`,
      // `xor` it with `current` to flip the bits in the intersection.
      if iszero(on) {
        updated := xor(current, and(current, roles))
      }
      // Then, store the new value.
      sstore(roleSlot, updated)
      // Emit the {RolesUpdated} event.
      log3(0, 0, _ROLES_UPDATED_EVENT_SIGNATURE, shr(96, mload(0x0c)), updated)
    }
  }

  /// @dev Grants the roles directly without authorization guard.
  /// Each bit of `roles` represents the role to turn on.
  function _grantRoles(address user, uint256 roles) internal virtual {
    _updateRoles(user, roles, true);
  }

  /// @dev Removes the roles directly without authorization guard.
  /// Each bit of `roles` represents the role to turn off.
  function _removeRoles(address user, uint256 roles) internal virtual {
    _updateRoles(user, roles, false);
  }

  /// @dev Throws if the sender does not have any of the `roles`.
  function _checkRoles(uint256 roles) internal view virtual {
    /// @solidity memory-safe-assembly
    assembly {
      // Compute the role slot.
      mstore(0x0c, _ROLE_SLOT_SEED)
      mstore(0x00, caller())
      // Load the stored value, and if the `and` intersection
      // of the value and `roles` is zero, revert.
      if iszero(and(sload(keccak256(0x0c, 0x20)), roles)) {
        mstore(0x00, 0x82b42900) // `Unauthorized()`.
        revert(0x1c, 0x04)
      }
    }
  }

  /// @dev Throws if the sender is not the owner,
  /// and does not have any of the `roles`.
  /// Checks for ownership first, then lazily checks for roles.
  function _checkOwnerOrRoles(uint256 roles) internal view virtual {
    /// @solidity memory-safe-assembly
    assembly {
      // If the caller is not the stored owner.
      // Note: `_ROLE_SLOT_SEED` is equal to `_OWNER_SLOT_NOT`.
      if iszero(eq(caller(), sload(not(_ROLE_SLOT_SEED)))) {
        // Compute the role slot.
        mstore(0x0c, _ROLE_SLOT_SEED)
        mstore(0x00, caller())
        // Load the stored value, and if the `and` intersection
        // of the value and `roles` is zero, revert.
        if iszero(and(sload(keccak256(0x0c, 0x20)), roles)) {
          mstore(0x00, 0x82b42900) // `Unauthorized()`.
          revert(0x1c, 0x04)
        }
      }
    }
  }

  /// @dev Throws if the sender does not have any of the `roles`,
  /// and is not the owner.
  /// Checks for roles first, then lazily checks for ownership.
  function _checkRolesOrOwner(uint256 roles) internal view virtual {
    /// @solidity memory-safe-assembly
    assembly {
      // Compute the role slot.
      mstore(0x0c, _ROLE_SLOT_SEED)
      mstore(0x00, caller())
      // Load the stored value, and if the `and` intersection
      // of the value and `roles` is zero, revert.
      if iszero(and(sload(keccak256(0x0c, 0x20)), roles)) {
        // If the caller is not the stored owner.
        // Note: `_ROLE_SLOT_SEED` is equal to `_OWNER_SLOT_NOT`.
        if iszero(eq(caller(), sload(not(_ROLE_SLOT_SEED)))) {
          mstore(0x00, 0x82b42900) // `Unauthorized()`.
          revert(0x1c, 0x04)
        }
      }
    }
  }

  /// @dev Convenience function to return a `roles` bitmap from an array of `ordinals`.
  /// This is meant for frontends like Etherscan, and is therefore not fully optimized.
  /// Not recommended to be called on-chain.
  /// Made internal to conserve bytecode. Wrap it in a public function if needed.
  function _rolesFromOrdinals(uint8[] memory ordinals) internal pure returns (uint256 roles) {
    /// @solidity memory-safe-assembly
    assembly {
      for {
        let i := shl(5, mload(ordinals))
      } i {
        i := sub(i, 0x20)
      } {
        // We don't need to mask the values of `ordinals`, as Solidity
        // cleans dirty upper bits when storing variables into memory.
        roles := or(shl(mload(add(ordinals, i)), 1), roles)
      }
    }
  }

  /// @dev Convenience function to return an array of `ordinals` from the `roles` bitmap.
  /// This is meant for frontends like Etherscan, and is therefore not fully optimized.
  /// Not recommended to be called on-chain.
  /// Made internal to conserve bytecode. Wrap it in a public function if needed.
  function _ordinalsFromRoles(uint256 roles) internal pure returns (uint8[] memory ordinals) {
    /// @solidity memory-safe-assembly
    assembly {
      // Grab the pointer to the free memory.
      ordinals := mload(0x40)
      let ptr := add(ordinals, 0x20)
      let o := 0
      // The absence of lookup tables, De Bruijn, etc., here is intentional for
      // smaller bytecode, as this function is not meant to be called on-chain.
      for {
        let t := roles
      } 1 {

      } {
        mstore(ptr, o)
        // `shr` 5 is equivalent to multiplying by 0x20.
        // Push back into the ordinals array if the bit is set.
        ptr := add(ptr, shl(5, and(t, 1)))
        o := add(o, 1)
        t := shr(o, roles)
        if iszero(t) {
          break
        }
      }
      // Store the length of `ordinals`.
      mstore(ordinals, shr(5, sub(ptr, add(ordinals, 0x20))))
      // Allocate the memory.
      mstore(0x40, ptr)
    }
  }

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                  PUBLIC UPDATE FUNCTIONS                   */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @dev Allows the owner to grant `user` `roles`.
  /// If the `user` already has a role, then it will be an no-op for the role.
  function grantRoles(address user, uint256 roles) public payable virtual onlyOwner {
    _grantRoles(user, roles);
  }

  /// @dev Allows the owner to remove `user` `roles`.
  /// If the `user` does not have a role, then it will be an no-op for the role.
  function revokeRoles(address user, uint256 roles) public payable virtual onlyOwner {
    _removeRoles(user, roles);
  }

  /// @dev Allow the caller to remove their own roles.
  /// If the caller does not have a role, then it will be an no-op for the role.
  function renounceRoles(uint256 roles) public payable virtual {
    _removeRoles(msg.sender, roles);
  }

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                   PUBLIC READ FUNCTIONS                    */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @dev Returns the roles of `user`.
  function rolesOf(address user) public view virtual returns (uint256 roles) {
    /// @solidity memory-safe-assembly
    assembly {
      // Compute the role slot.
      mstore(0x0c, _ROLE_SLOT_SEED)
      mstore(0x00, user)
      // Load the stored value.
      roles := sload(keccak256(0x0c, 0x20))
    }
  }

  /// @dev Returns whether `user` has any of `roles`.
  function hasAnyRole(address user, uint256 roles) public view virtual returns (bool) {
    return rolesOf(user) & roles != 0;
  }

  /// @dev Returns whether `user` has all of `roles`.
  function hasAllRoles(address user, uint256 roles) public view virtual returns (bool) {
    return rolesOf(user) & roles == roles;
  }

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                         MODIFIERS                          */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @dev Marks a function as only callable by an account with `roles`.
  modifier onlyRoles(uint256 roles) virtual {
    _checkRoles(roles);
    _;
  }

  /// @dev Marks a function as only callable by the owner or by an account
  /// with `roles`. Checks for ownership first, then lazily checks for roles.
  modifier onlyOwnerOrRoles(uint256 roles) virtual {
    _checkOwnerOrRoles(roles);
    _;
  }

  /// @dev Marks a function as only callable by an account with `roles`
  /// or the owner. Checks for roles first, then lazily checks for ownership.
  modifier onlyRolesOrOwner(uint256 roles) virtual {
    _checkRolesOrOwner(roles);
    _;
  }

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                       ROLE CONSTANTS                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  // IYKYK

  uint256 internal constant _ROLE_0 = 1 << 0;
  uint256 internal constant _ROLE_1 = 1 << 1;
  uint256 internal constant _ROLE_2 = 1 << 2;
  uint256 internal constant _ROLE_3 = 1 << 3;
  uint256 internal constant _ROLE_4 = 1 << 4;
  uint256 internal constant _ROLE_5 = 1 << 5;
  uint256 internal constant _ROLE_6 = 1 << 6;
  uint256 internal constant _ROLE_7 = 1 << 7;
  uint256 internal constant _ROLE_8 = 1 << 8;
  uint256 internal constant _ROLE_9 = 1 << 9;
  uint256 internal constant _ROLE_10 = 1 << 10;
  uint256 internal constant _ROLE_11 = 1 << 11;
  uint256 internal constant _ROLE_12 = 1 << 12;
  uint256 internal constant _ROLE_13 = 1 << 13;
  uint256 internal constant _ROLE_14 = 1 << 14;
  uint256 internal constant _ROLE_15 = 1 << 15;
  uint256 internal constant _ROLE_16 = 1 << 16;
  uint256 internal constant _ROLE_17 = 1 << 17;
  uint256 internal constant _ROLE_18 = 1 << 18;
  uint256 internal constant _ROLE_19 = 1 << 19;
  uint256 internal constant _ROLE_20 = 1 << 20;
  uint256 internal constant _ROLE_21 = 1 << 21;
  uint256 internal constant _ROLE_22 = 1 << 22;
  uint256 internal constant _ROLE_23 = 1 << 23;
  uint256 internal constant _ROLE_24 = 1 << 24;
  uint256 internal constant _ROLE_25 = 1 << 25;
  uint256 internal constant _ROLE_26 = 1 << 26;
  uint256 internal constant _ROLE_27 = 1 << 27;
  uint256 internal constant _ROLE_28 = 1 << 28;
  uint256 internal constant _ROLE_29 = 1 << 29;
  uint256 internal constant _ROLE_30 = 1 << 30;
  uint256 internal constant _ROLE_31 = 1 << 31;
  uint256 internal constant _ROLE_32 = 1 << 32;
  uint256 internal constant _ROLE_33 = 1 << 33;
  uint256 internal constant _ROLE_34 = 1 << 34;
  uint256 internal constant _ROLE_35 = 1 << 35;
  uint256 internal constant _ROLE_36 = 1 << 36;
  uint256 internal constant _ROLE_37 = 1 << 37;
  uint256 internal constant _ROLE_38 = 1 << 38;
  uint256 internal constant _ROLE_39 = 1 << 39;
  uint256 internal constant _ROLE_40 = 1 << 40;
  uint256 internal constant _ROLE_41 = 1 << 41;
  uint256 internal constant _ROLE_42 = 1 << 42;
  uint256 internal constant _ROLE_43 = 1 << 43;
  uint256 internal constant _ROLE_44 = 1 << 44;
  uint256 internal constant _ROLE_45 = 1 << 45;
  uint256 internal constant _ROLE_46 = 1 << 46;
  uint256 internal constant _ROLE_47 = 1 << 47;
  uint256 internal constant _ROLE_48 = 1 << 48;
  uint256 internal constant _ROLE_49 = 1 << 49;
  uint256 internal constant _ROLE_50 = 1 << 50;
  uint256 internal constant _ROLE_51 = 1 << 51;
  uint256 internal constant _ROLE_52 = 1 << 52;
  uint256 internal constant _ROLE_53 = 1 << 53;
  uint256 internal constant _ROLE_54 = 1 << 54;
  uint256 internal constant _ROLE_55 = 1 << 55;
  uint256 internal constant _ROLE_56 = 1 << 56;
  uint256 internal constant _ROLE_57 = 1 << 57;
  uint256 internal constant _ROLE_58 = 1 << 58;
  uint256 internal constant _ROLE_59 = 1 << 59;
  uint256 internal constant _ROLE_60 = 1 << 60;
  uint256 internal constant _ROLE_61 = 1 << 61;
  uint256 internal constant _ROLE_62 = 1 << 62;
  uint256 internal constant _ROLE_63 = 1 << 63;
  uint256 internal constant _ROLE_64 = 1 << 64;
  uint256 internal constant _ROLE_65 = 1 << 65;
  uint256 internal constant _ROLE_66 = 1 << 66;
  uint256 internal constant _ROLE_67 = 1 << 67;
  uint256 internal constant _ROLE_68 = 1 << 68;
  uint256 internal constant _ROLE_69 = 1 << 69;
  uint256 internal constant _ROLE_70 = 1 << 70;
  uint256 internal constant _ROLE_71 = 1 << 71;
  uint256 internal constant _ROLE_72 = 1 << 72;
  uint256 internal constant _ROLE_73 = 1 << 73;
  uint256 internal constant _ROLE_74 = 1 << 74;
  uint256 internal constant _ROLE_75 = 1 << 75;
  uint256 internal constant _ROLE_76 = 1 << 76;
  uint256 internal constant _ROLE_77 = 1 << 77;
  uint256 internal constant _ROLE_78 = 1 << 78;
  uint256 internal constant _ROLE_79 = 1 << 79;
  uint256 internal constant _ROLE_80 = 1 << 80;
  uint256 internal constant _ROLE_81 = 1 << 81;
  uint256 internal constant _ROLE_82 = 1 << 82;
  uint256 internal constant _ROLE_83 = 1 << 83;
  uint256 internal constant _ROLE_84 = 1 << 84;
  uint256 internal constant _ROLE_85 = 1 << 85;
  uint256 internal constant _ROLE_86 = 1 << 86;
  uint256 internal constant _ROLE_87 = 1 << 87;
  uint256 internal constant _ROLE_88 = 1 << 88;
  uint256 internal constant _ROLE_89 = 1 << 89;
  uint256 internal constant _ROLE_90 = 1 << 90;
  uint256 internal constant _ROLE_91 = 1 << 91;
  uint256 internal constant _ROLE_92 = 1 << 92;
  uint256 internal constant _ROLE_93 = 1 << 93;
  uint256 internal constant _ROLE_94 = 1 << 94;
  uint256 internal constant _ROLE_95 = 1 << 95;
  uint256 internal constant _ROLE_96 = 1 << 96;
  uint256 internal constant _ROLE_97 = 1 << 97;
  uint256 internal constant _ROLE_98 = 1 << 98;
  uint256 internal constant _ROLE_99 = 1 << 99;
  uint256 internal constant _ROLE_100 = 1 << 100;
  uint256 internal constant _ROLE_101 = 1 << 101;
  uint256 internal constant _ROLE_102 = 1 << 102;
  uint256 internal constant _ROLE_103 = 1 << 103;
  uint256 internal constant _ROLE_104 = 1 << 104;
  uint256 internal constant _ROLE_105 = 1 << 105;
  uint256 internal constant _ROLE_106 = 1 << 106;
  uint256 internal constant _ROLE_107 = 1 << 107;
  uint256 internal constant _ROLE_108 = 1 << 108;
  uint256 internal constant _ROLE_109 = 1 << 109;
  uint256 internal constant _ROLE_110 = 1 << 110;
  uint256 internal constant _ROLE_111 = 1 << 111;
  uint256 internal constant _ROLE_112 = 1 << 112;
  uint256 internal constant _ROLE_113 = 1 << 113;
  uint256 internal constant _ROLE_114 = 1 << 114;
  uint256 internal constant _ROLE_115 = 1 << 115;
  uint256 internal constant _ROLE_116 = 1 << 116;
  uint256 internal constant _ROLE_117 = 1 << 117;
  uint256 internal constant _ROLE_118 = 1 << 118;
  uint256 internal constant _ROLE_119 = 1 << 119;
  uint256 internal constant _ROLE_120 = 1 << 120;
  uint256 internal constant _ROLE_121 = 1 << 121;
  uint256 internal constant _ROLE_122 = 1 << 122;
  uint256 internal constant _ROLE_123 = 1 << 123;
  uint256 internal constant _ROLE_124 = 1 << 124;
  uint256 internal constant _ROLE_125 = 1 << 125;
  uint256 internal constant _ROLE_126 = 1 << 126;
  uint256 internal constant _ROLE_127 = 1 << 127;
  uint256 internal constant _ROLE_128 = 1 << 128;
  uint256 internal constant _ROLE_129 = 1 << 129;
  uint256 internal constant _ROLE_130 = 1 << 130;
  uint256 internal constant _ROLE_131 = 1 << 131;
  uint256 internal constant _ROLE_132 = 1 << 132;
  uint256 internal constant _ROLE_133 = 1 << 133;
  uint256 internal constant _ROLE_134 = 1 << 134;
  uint256 internal constant _ROLE_135 = 1 << 135;
  uint256 internal constant _ROLE_136 = 1 << 136;
  uint256 internal constant _ROLE_137 = 1 << 137;
  uint256 internal constant _ROLE_138 = 1 << 138;
  uint256 internal constant _ROLE_139 = 1 << 139;
  uint256 internal constant _ROLE_140 = 1 << 140;
  uint256 internal constant _ROLE_141 = 1 << 141;
  uint256 internal constant _ROLE_142 = 1 << 142;
  uint256 internal constant _ROLE_143 = 1 << 143;
  uint256 internal constant _ROLE_144 = 1 << 144;
  uint256 internal constant _ROLE_145 = 1 << 145;
  uint256 internal constant _ROLE_146 = 1 << 146;
  uint256 internal constant _ROLE_147 = 1 << 147;
  uint256 internal constant _ROLE_148 = 1 << 148;
  uint256 internal constant _ROLE_149 = 1 << 149;
  uint256 internal constant _ROLE_150 = 1 << 150;
  uint256 internal constant _ROLE_151 = 1 << 151;
  uint256 internal constant _ROLE_152 = 1 << 152;
  uint256 internal constant _ROLE_153 = 1 << 153;
  uint256 internal constant _ROLE_154 = 1 << 154;
  uint256 internal constant _ROLE_155 = 1 << 155;
  uint256 internal constant _ROLE_156 = 1 << 156;
  uint256 internal constant _ROLE_157 = 1 << 157;
  uint256 internal constant _ROLE_158 = 1 << 158;
  uint256 internal constant _ROLE_159 = 1 << 159;
  uint256 internal constant _ROLE_160 = 1 << 160;
  uint256 internal constant _ROLE_161 = 1 << 161;
  uint256 internal constant _ROLE_162 = 1 << 162;
  uint256 internal constant _ROLE_163 = 1 << 163;
  uint256 internal constant _ROLE_164 = 1 << 164;
  uint256 internal constant _ROLE_165 = 1 << 165;
  uint256 internal constant _ROLE_166 = 1 << 166;
  uint256 internal constant _ROLE_167 = 1 << 167;
  uint256 internal constant _ROLE_168 = 1 << 168;
  uint256 internal constant _ROLE_169 = 1 << 169;
  uint256 internal constant _ROLE_170 = 1 << 170;
  uint256 internal constant _ROLE_171 = 1 << 171;
  uint256 internal constant _ROLE_172 = 1 << 172;
  uint256 internal constant _ROLE_173 = 1 << 173;
  uint256 internal constant _ROLE_174 = 1 << 174;
  uint256 internal constant _ROLE_175 = 1 << 175;
  uint256 internal constant _ROLE_176 = 1 << 176;
  uint256 internal constant _ROLE_177 = 1 << 177;
  uint256 internal constant _ROLE_178 = 1 << 178;
  uint256 internal constant _ROLE_179 = 1 << 179;
  uint256 internal constant _ROLE_180 = 1 << 180;
  uint256 internal constant _ROLE_181 = 1 << 181;
  uint256 internal constant _ROLE_182 = 1 << 182;
  uint256 internal constant _ROLE_183 = 1 << 183;
  uint256 internal constant _ROLE_184 = 1 << 184;
  uint256 internal constant _ROLE_185 = 1 << 185;
  uint256 internal constant _ROLE_186 = 1 << 186;
  uint256 internal constant _ROLE_187 = 1 << 187;
  uint256 internal constant _ROLE_188 = 1 << 188;
  uint256 internal constant _ROLE_189 = 1 << 189;
  uint256 internal constant _ROLE_190 = 1 << 190;
  uint256 internal constant _ROLE_191 = 1 << 191;
  uint256 internal constant _ROLE_192 = 1 << 192;
  uint256 internal constant _ROLE_193 = 1 << 193;
  uint256 internal constant _ROLE_194 = 1 << 194;
  uint256 internal constant _ROLE_195 = 1 << 195;
  uint256 internal constant _ROLE_196 = 1 << 196;
  uint256 internal constant _ROLE_197 = 1 << 197;
  uint256 internal constant _ROLE_198 = 1 << 198;
  uint256 internal constant _ROLE_199 = 1 << 199;
  uint256 internal constant _ROLE_200 = 1 << 200;
  uint256 internal constant _ROLE_201 = 1 << 201;
  uint256 internal constant _ROLE_202 = 1 << 202;
  uint256 internal constant _ROLE_203 = 1 << 203;
  uint256 internal constant _ROLE_204 = 1 << 204;
  uint256 internal constant _ROLE_205 = 1 << 205;
  uint256 internal constant _ROLE_206 = 1 << 206;
  uint256 internal constant _ROLE_207 = 1 << 207;
  uint256 internal constant _ROLE_208 = 1 << 208;
  uint256 internal constant _ROLE_209 = 1 << 209;
  uint256 internal constant _ROLE_210 = 1 << 210;
  uint256 internal constant _ROLE_211 = 1 << 211;
  uint256 internal constant _ROLE_212 = 1 << 212;
  uint256 internal constant _ROLE_213 = 1 << 213;
  uint256 internal constant _ROLE_214 = 1 << 214;
  uint256 internal constant _ROLE_215 = 1 << 215;
  uint256 internal constant _ROLE_216 = 1 << 216;
  uint256 internal constant _ROLE_217 = 1 << 217;
  uint256 internal constant _ROLE_218 = 1 << 218;
  uint256 internal constant _ROLE_219 = 1 << 219;
  uint256 internal constant _ROLE_220 = 1 << 220;
  uint256 internal constant _ROLE_221 = 1 << 221;
  uint256 internal constant _ROLE_222 = 1 << 222;
  uint256 internal constant _ROLE_223 = 1 << 223;
  uint256 internal constant _ROLE_224 = 1 << 224;
  uint256 internal constant _ROLE_225 = 1 << 225;
  uint256 internal constant _ROLE_226 = 1 << 226;
  uint256 internal constant _ROLE_227 = 1 << 227;
  uint256 internal constant _ROLE_228 = 1 << 228;
  uint256 internal constant _ROLE_229 = 1 << 229;
  uint256 internal constant _ROLE_230 = 1 << 230;
  uint256 internal constant _ROLE_231 = 1 << 231;
  uint256 internal constant _ROLE_232 = 1 << 232;
  uint256 internal constant _ROLE_233 = 1 << 233;
  uint256 internal constant _ROLE_234 = 1 << 234;
  uint256 internal constant _ROLE_235 = 1 << 235;
  uint256 internal constant _ROLE_236 = 1 << 236;
  uint256 internal constant _ROLE_237 = 1 << 237;
  uint256 internal constant _ROLE_238 = 1 << 238;
  uint256 internal constant _ROLE_239 = 1 << 239;
  uint256 internal constant _ROLE_240 = 1 << 240;
  uint256 internal constant _ROLE_241 = 1 << 241;
  uint256 internal constant _ROLE_242 = 1 << 242;
  uint256 internal constant _ROLE_243 = 1 << 243;
  uint256 internal constant _ROLE_244 = 1 << 244;
  uint256 internal constant _ROLE_245 = 1 << 245;
  uint256 internal constant _ROLE_246 = 1 << 246;
  uint256 internal constant _ROLE_247 = 1 << 247;
  uint256 internal constant _ROLE_248 = 1 << 248;
  uint256 internal constant _ROLE_249 = 1 << 249;
  uint256 internal constant _ROLE_250 = 1 << 250;
  uint256 internal constant _ROLE_251 = 1 << 251;
  uint256 internal constant _ROLE_252 = 1 << 252;
  uint256 internal constant _ROLE_253 = 1 << 253;
  uint256 internal constant _ROLE_254 = 1 << 254;
  uint256 internal constant _ROLE_255 = 1 << 255;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Simple single owner authorization mixin.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/auth/Ownable.sol)
///
/// @dev Note:
/// This implementation does NOT auto-initialize the owner to `msg.sender`.
/// You MUST call the `_initializeOwner` in the constructor / initializer.
///
/// While the ownable portion follows
/// [EIP-173](https://eips.ethereum.org/EIPS/eip-173) for compatibility,
/// the nomenclature for the 2-step ownership handover may be unique to this codebase.
abstract contract Ownable {
  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                       CUSTOM ERRORS                        */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @dev The caller is not authorized to call the function.
  error Unauthorized();

  /// @dev The `newOwner` cannot be the zero address.
  error NewOwnerIsZeroAddress();

  /// @dev The `pendingOwner` does not have a valid handover request.
  error NoHandoverRequest();

  /// @dev Cannot double-initialize.
  error AlreadyInitialized();

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           EVENTS                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @dev The ownership is transferred from `oldOwner` to `newOwner`.
  /// This event is intentionally kept the same as OpenZeppelin's Ownable to be
  /// compatible with indexers and [EIP-173](https://eips.ethereum.org/EIPS/eip-173),
  /// despite it not being as lightweight as a single argument event.
  event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

  /// @dev An ownership handover to `pendingOwner` has been requested.
  event OwnershipHandoverRequested(address indexed pendingOwner);

  /// @dev The ownership handover to `pendingOwner` has been canceled.
  event OwnershipHandoverCanceled(address indexed pendingOwner);

  /// @dev `keccak256(bytes("OwnershipTransferred(address,address)"))`.
  uint256 private constant _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE =
    0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0;

  /// @dev `keccak256(bytes("OwnershipHandoverRequested(address)"))`.
  uint256 private constant _OWNERSHIP_HANDOVER_REQUESTED_EVENT_SIGNATURE =
    0xdbf36a107da19e49527a7176a1babf963b4b0ff8cde35ee35d6cd8f1f9ac7e1d;

  /// @dev `keccak256(bytes("OwnershipHandoverCanceled(address)"))`.
  uint256 private constant _OWNERSHIP_HANDOVER_CANCELED_EVENT_SIGNATURE =
    0xfa7b8eab7da67f412cc9575ed43464468f9bfbae89d1675917346ca6d8fe3c92;

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                          STORAGE                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @dev The owner slot is given by:
  /// `bytes32(~uint256(uint32(bytes4(keccak256("_OWNER_SLOT_NOT")))))`.
  /// It is intentionally chosen to be a high value
  /// to avoid collision with lower slots.
  /// The choice of manual storage layout is to enable compatibility
  /// with both regular and upgradeable contracts.
  bytes32 internal constant _OWNER_SLOT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff74873927;

  /// The ownership handover slot of `newOwner` is given by:
  /// ```
  ///     mstore(0x00, or(shl(96, user), _HANDOVER_SLOT_SEED))
  ///     let handoverSlot := keccak256(0x00, 0x20)
  /// ```
  /// It stores the expiry timestamp of the two-step ownership handover.
  uint256 private constant _HANDOVER_SLOT_SEED = 0x389a75e1;

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                     INTERNAL FUNCTIONS                     */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @dev Override to return true to make `_initializeOwner` prevent double-initialization.
  function _guardInitializeOwner() internal pure virtual returns (bool guard) {}

  /// @dev Initializes the owner directly without authorization guard.
  /// This function must be called upon initialization,
  /// regardless of whether the contract is upgradeable or not.
  /// This is to enable generalization to both regular and upgradeable contracts,
  /// and to save gas in case the initial owner is not the caller.
  /// For performance reasons, this function will not check if there
  /// is an existing owner.
  function _initializeOwner(address newOwner) internal virtual {
    if (_guardInitializeOwner()) {
      /// @solidity memory-safe-assembly
      assembly {
        let ownerSlot := _OWNER_SLOT
        if sload(ownerSlot) {
          mstore(0x00, 0x0dc149f0) // `AlreadyInitialized()`.
          revert(0x1c, 0x04)
        }
        // Clean the upper 96 bits.
        newOwner := shr(96, shl(96, newOwner))
        // Store the new value.
        sstore(ownerSlot, or(newOwner, shl(255, iszero(newOwner))))
        // Emit the {OwnershipTransferred} event.
        log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, 0, newOwner)
      }
    } else {
      /// @solidity memory-safe-assembly
      assembly {
        // Clean the upper 96 bits.
        newOwner := shr(96, shl(96, newOwner))
        // Store the new value.
        sstore(_OWNER_SLOT, newOwner)
        // Emit the {OwnershipTransferred} event.
        log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, 0, newOwner)
      }
    }
  }

  /// @dev Sets the owner directly without authorization guard.
  function _setOwner(address newOwner) internal virtual {
    if (_guardInitializeOwner()) {
      /// @solidity memory-safe-assembly
      assembly {
        let ownerSlot := _OWNER_SLOT
        // Clean the upper 96 bits.
        newOwner := shr(96, shl(96, newOwner))
        // Emit the {OwnershipTransferred} event.
        log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, sload(ownerSlot), newOwner)
        // Store the new value.
        sstore(ownerSlot, or(newOwner, shl(255, iszero(newOwner))))
      }
    } else {
      /// @solidity memory-safe-assembly
      assembly {
        let ownerSlot := _OWNER_SLOT
        // Clean the upper 96 bits.
        newOwner := shr(96, shl(96, newOwner))
        // Emit the {OwnershipTransferred} event.
        log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, sload(ownerSlot), newOwner)
        // Store the new value.
        sstore(ownerSlot, newOwner)
      }
    }
  }

  /// @dev Throws if the sender is not the owner.
  function _checkOwner() internal view virtual {
    /// @solidity memory-safe-assembly
    assembly {
      // If the caller is not the stored owner, revert.
      if iszero(eq(caller(), sload(_OWNER_SLOT))) {
        mstore(0x00, 0x82b42900) // `Unauthorized()`.
        revert(0x1c, 0x04)
      }
    }
  }

  /// @dev Returns how long a two-step ownership handover is valid for in seconds.
  /// Override to return a different value if needed.
  /// Made internal to conserve bytecode. Wrap it in a public function if needed.
  function _ownershipHandoverValidFor() internal view virtual returns (uint64) {
    return 48 * 3600;
  }

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                  PUBLIC UPDATE FUNCTIONS                   */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @dev Allows the owner to transfer the ownership to `newOwner`.
  function transferOwnership(address newOwner) public payable virtual onlyOwner {
    /// @solidity memory-safe-assembly
    assembly {
      if iszero(shl(96, newOwner)) {
        mstore(0x00, 0x7448fbae) // `NewOwnerIsZeroAddress()`.
        revert(0x1c, 0x04)
      }
    }
    _setOwner(newOwner);
  }

  /// @dev Allows the owner to renounce their ownership.
  function renounceOwnership() public payable virtual onlyOwner {
    _setOwner(address(0));
  }

  /// @dev Request a two-step ownership handover to the caller.
  /// The request will automatically expire in 48 hours (172800 seconds) by default.
  function requestOwnershipHandover() public payable virtual {
    unchecked {
      uint256 expires = block.timestamp + _ownershipHandoverValidFor();
      /// @solidity memory-safe-assembly
      assembly {
        // Compute and set the handover slot to `expires`.
        mstore(0x0c, _HANDOVER_SLOT_SEED)
        mstore(0x00, caller())
        sstore(keccak256(0x0c, 0x20), expires)
        // Emit the {OwnershipHandoverRequested} event.
        log2(0, 0, _OWNERSHIP_HANDOVER_REQUESTED_EVENT_SIGNATURE, caller())
      }
    }
  }

  /// @dev Cancels the two-step ownership handover to the caller, if any.
  function cancelOwnershipHandover() public payable virtual {
    /// @solidity memory-safe-assembly
    assembly {
      // Compute and set the handover slot to 0.
      mstore(0x0c, _HANDOVER_SLOT_SEED)
      mstore(0x00, caller())
      sstore(keccak256(0x0c, 0x20), 0)
      // Emit the {OwnershipHandoverCanceled} event.
      log2(0, 0, _OWNERSHIP_HANDOVER_CANCELED_EVENT_SIGNATURE, caller())
    }
  }

  /// @dev Allows the owner to complete the two-step ownership handover to `pendingOwner`.
  /// Reverts if there is no existing ownership handover requested by `pendingOwner`.
  function completeOwnershipHandover(address pendingOwner) public payable virtual onlyOwner {
    /// @solidity memory-safe-assembly
    assembly {
      // Compute and set the handover slot to 0.
      mstore(0x0c, _HANDOVER_SLOT_SEED)
      mstore(0x00, pendingOwner)
      let handoverSlot := keccak256(0x0c, 0x20)
      // If the handover does not exist, or has expired.
      if gt(timestamp(), sload(handoverSlot)) {
        mstore(0x00, 0x6f5e8818) // `NoHandoverRequest()`.
        revert(0x1c, 0x04)
      }
      // Set the handover slot to 0.
      sstore(handoverSlot, 0)
    }
    _setOwner(pendingOwner);
  }

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                   PUBLIC READ FUNCTIONS                    */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @dev Returns the owner of the contract.
  function owner() public view virtual returns (address result) {
    /// @solidity memory-safe-assembly
    assembly {
      result := sload(_OWNER_SLOT)
    }
  }

  /// @dev Returns the expiry timestamp for the two-step ownership handover to `pendingOwner`.
  function ownershipHandoverExpiresAt(address pendingOwner) public view virtual returns (uint256 result) {
    /// @solidity memory-safe-assembly
    assembly {
      // Compute the handover slot.
      mstore(0x0c, _HANDOVER_SLOT_SEED)
      mstore(0x00, pendingOwner)
      // Load the handover slot.
      result := sload(keccak256(0x0c, 0x20))
    }
  }

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                         MODIFIERS                          */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @dev Marks a function as only callable by the owner.
  modifier onlyOwner() virtual {
    _checkOwner();
    _;
  }
}