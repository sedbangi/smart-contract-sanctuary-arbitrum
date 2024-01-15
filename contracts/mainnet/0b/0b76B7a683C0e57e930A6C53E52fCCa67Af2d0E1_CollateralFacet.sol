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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
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
 * ```solidity
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
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;

import {ICollateral} from "../interfaces/ICollateral.sol";
import {IGetters} from "../interfaces/IGetters.sol";
import {IYGFacetZaynFi} from "../interfaces/IYGFacetZaynFi.sol";

import {LibFundStorage} from "../libraries/LibFundStorage.sol";
import {LibTermStorage} from "../libraries/LibTermStorage.sol";
import {LibCollateral} from "../libraries/LibCollateral.sol";
import {LibCollateralStorage} from "../libraries/LibCollateralStorage.sol";
import {LibYieldGeneration} from "../libraries/LibYieldGeneration.sol";
import {LibYieldGenerationStorage} from "../libraries/LibYieldGenerationStorage.sol";
import {LibTermOwnership} from "../libraries/LibTermOwnership.sol";

/// @title Takaturn Collateral
/// @author Aisha El Allam
/// @notice This is used to operate the Takaturn collateral
/// @dev v3.0 (Diamond)
contract CollateralFacet is ICollateral {
    event OnCollateralStateChanged(
        uint indexed termId,
        LibCollateralStorage.CollateralStates indexed oldState,
        LibCollateralStorage.CollateralStates indexed newState
    );
    event OnCollateralWithdrawal(
        uint indexed termId,
        address indexed user,
        address receiver,
        uint indexed collateralAmount
    );
    event OnReimbursementWithdrawn(
        uint indexed termId,
        address indexed participant,
        address receiver,
        uint indexed amount
    );
    event OnCollateralLiquidated(uint indexed termId, address indexed user, uint indexed amount);
    event OnFrozenMoneyPotLiquidated(
        uint indexed termId,
        address indexed user,
        uint indexed amount
    );
    event OnYieldClaimed(
        uint indexed termId,
        address indexed user,
        address receiver,
        uint indexed amount
    ); // Emits when a user claims their yield

    /// @param termId term id
    /// @param _state collateral state
    modifier atState(uint termId, LibCollateralStorage.CollateralStates _state) {
        _atState(termId, _state);
        _;
    }

    modifier onlyTermOwner(uint termId) {
        LibTermOwnership._ensureTermOwner(termId);
        _;
    }

    /// @notice Called from Fund contract when someone defaults
    /// @dev Check EnumerableMap (openzeppelin) for arrays that are being accessed from Fund contract
    /// @param defaulters Addressess of all defaulters of the current cycle
    /// @return expellants array of addresses that were expelled
    function requestContribution(
        LibTermStorage.Term memory term,
        address[] calldata defaulters
    )
        external
        atState(term.termId, LibCollateralStorage.CollateralStates.CycleOngoing)
        returns (address[] memory)
    {
        LibCollateralStorage.Collateral storage collateral = LibCollateralStorage
            ._collateralStorage()
            .collaterals[term.termId];
        LibFundStorage.Fund storage fund = LibFundStorage._fundStorage().funds[term.termId];
        require(msg.sender == address(this));

        (uint collateralToDistribute, address[] memory expellants) = _solveDefaulters(
            collateral,
            term,
            fund,
            defaulters
        );

        (uint nonBeneficiaryCounter, address[] memory nonBeneficiaries) = _findNonBeneficiaries(
            collateral,
            fund
        );

        if (nonBeneficiaryCounter > 0) {
            // This case can only happen when what?
            // Exempt non beneficiaries from paying an early expellant's cycle
            uint expellantsLength = expellants.length;
            for (uint i; i < expellantsLength; ) {
                _exemptNonBeneficiariesFromPaying(
                    fund,
                    expellants[i],
                    nonBeneficiaryCounter,
                    nonBeneficiaries
                );

                unchecked {
                    ++i;
                }
            }

            // Finally, divide the share equally among non-beneficiaries
            collateralToDistribute = collateralToDistribute / nonBeneficiaryCounter;
            for (uint i; i < nonBeneficiaryCounter; ) {
                collateral.collateralPaymentBank[nonBeneficiaries[i]] += collateralToDistribute;

                unchecked {
                    ++i;
                }
            }
        }
        return (expellants);
    }

    /// @notice Called to exempt users from needing to pay
    /// @param _fund Fund storage
    /// @param _expellant The expellant in question
    /// @param _nonBeneficiaries All non-beneficiaries at this time
    function _exemptNonBeneficiariesFromPaying(
        LibFundStorage.Fund storage _fund,
        address _expellant,
        uint _nonBeneficiaryCounter,
        address[] memory _nonBeneficiaries
    ) internal {
        if (!_fund.isBeneficiary[_expellant]) {
            uint expellantBeneficiaryCycle;

            uint beneficiariesLength = _fund.beneficiariesOrder.length;
            for (uint i; i < beneficiariesLength; ) {
                if (_expellant == _fund.beneficiariesOrder[i]) {
                    expellantBeneficiaryCycle = i + 1;
                    break;
                }
                unchecked {
                    ++i;
                }
            }

            for (uint i; i < _nonBeneficiaryCounter; ) {
                _fund.isExemptedOnCycle[expellantBeneficiaryCycle].exempted[
                    _nonBeneficiaries[i]
                ] = true;
                unchecked {
                    ++i;
                }
            }
        }
    }

    /// @notice Called by each member after during or at the end of the term to withraw collateral
    /// @dev This follows the pull-over-push pattern.
    /// @param termId term id
    function withdrawCollateral(uint termId) external {
        _withdrawCollateral(termId, msg.sender);
    }

    /// @notice Called by each member after during or at the end of the term to withraw collateral
    /// @dev This follows the pull-over-push pattern.
    /// @param termId term id
    /// @param receiver receiver address
    function withdrawCollateralToAnotherAddress(uint termId, address receiver) external {
        LibFundStorage.Fund storage fund = LibFundStorage._fundStorage().funds[termId];

        address[] memory participants = fund.beneficiariesOrder;
        uint participantsLength = participants.length;
        bool canCall;

        for (uint i; i < participantsLength; ) {
            if (participants[i] == msg.sender) {
                canCall = true;
                break;
            }

            unchecked {
                ++i;
            }
        }

        require(canCall, "The caller must be a participant");

        _withdrawCollateral(termId, receiver);
    }

    /// @param termId term id
    function releaseCollateral(uint termId) external {
        LibFundStorage.Fund storage fund = LibFundStorage._fundStorage().funds[termId];
        require(fund.currentState == LibFundStorage.FundStates.FundClosed, "Wrong state");
        LibCollateral._setState(termId, LibCollateralStorage.CollateralStates.ReleasingCollateral);
    }

    /// @notice allow the owner to empty the Collateral after 180 days
    /// @param termId The term id
    function emptyCollateralAfterEnd(
        uint termId
    )
        external
        onlyTermOwner(termId)
        atState(termId, LibCollateralStorage.CollateralStates.ReleasingCollateral)
    {
        LibCollateralStorage.Collateral storage collateral = LibCollateralStorage
            ._collateralStorage()
            .collaterals[termId];
        LibYieldGenerationStorage.YieldGeneration storage yield = LibYieldGenerationStorage
            ._yieldStorage()
            .yields[termId];

        (, , , , , uint fundEnd, , ) = IGetters(address(this)).getFundSummary(termId);
        require(block.timestamp > fundEnd + 180 days, "Can't empty yet");

        uint totalToWithdraw;
        uint depositorsLength = collateral.depositors.length;
        for (uint i; i < depositorsLength; ) {
            address depositor = collateral.depositors[i];
            uint amount = collateral.collateralMembersBank[depositor];
            uint paymentAmount = collateral.collateralPaymentBank[depositor];

            collateral.collateralMembersBank[depositor] = 0;
            collateral.collateralPaymentBank[depositor] = 0;
            uint withdrawnYield = _withdrawFromYield(termId, depositor, amount, yield);

            totalToWithdraw += (amount + paymentAmount + withdrawnYield);

            unchecked {
                ++i;
            }
        }
        LibCollateral._setState(termId, LibCollateralStorage.CollateralStates.Closed);

        (bool success, ) = payable(msg.sender).call{value: totalToWithdraw}("");
        require(success);
    }

    /// @notice Called by each member after during or at the end of the term to withraw collateral
    /// @dev This follows the pull-over-push pattern.
    /// @param _termId term id
    /// @param _receiver receiver address
    function _withdrawCollateral(uint _termId, address _receiver) internal {
        LibFundStorage.Fund storage fund = LibFundStorage._fundStorage().funds[_termId];

        LibCollateralStorage.Collateral storage collateral = LibCollateralStorage
            ._collateralStorage()
            .collaterals[_termId];

        LibYieldGenerationStorage.YieldGeneration storage yield = LibYieldGenerationStorage
            ._yieldStorage()
            .yields[_termId];

        LibTermStorage.Term memory term = LibTermStorage._termStorage().terms[_termId];

        uint userCollateral = collateral.collateralMembersBank[msg.sender];
        require(userCollateral > 0, "Collateral empty");

        bool success;
        bool expelledBeforeBeneficiary = fund.expelledBeforeBeneficiary[msg.sender];
        // Withdraw all the user has.
        if (
            collateral.state == LibCollateralStorage.CollateralStates.ReleasingCollateral ||
            expelledBeforeBeneficiary
        ) {
            // First case: The collateral is released or the user was expelled before being a beneficiary
            collateral.collateralMembersBank[msg.sender] = 0;

            if (term.state != LibTermStorage.TermStates.ExpiredTerm) {
                _withdrawFromYield(_termId, msg.sender, userCollateral, yield);
            }

            (success, ) = payable(_receiver).call{value: userCollateral}("");

            if (collateral.state == LibCollateralStorage.CollateralStates.ReleasingCollateral) {
                --collateral.counterMembers;
            }

            emit OnCollateralWithdrawal(_termId, msg.sender, _receiver, userCollateral);
        }
        // Or withdraw partially
        else if (collateral.state == LibCollateralStorage.CollateralStates.CycleOngoing) {
            // Second case: The term is on an ongoing cycle, the user has not been expelled
            // Everything above 1.5 X remaining cycles contribution (RCC) can be withdrawn
            uint minRequiredCollateral = (IGetters(address(this)).getRemainingCyclesContributionWei(
                _termId
            ) * 15) / 10; // 1.5 X RCC in wei

            // Collateral must be higher than 1.5 X RCC
            if (userCollateral > minRequiredCollateral) {
                uint allowedWithdrawal = userCollateral - minRequiredCollateral; // We allow to withdraw the positive difference
                collateral.collateralMembersBank[msg.sender] -= allowedWithdrawal;

                _withdrawFromYield(_termId, msg.sender, allowedWithdrawal, yield);

                (success, ) = payable(_receiver).call{value: allowedWithdrawal}("");

                emit OnCollateralWithdrawal(_termId, msg.sender, _receiver, allowedWithdrawal);
            }
        }

        require(success, "Withdraw failed");
        if (yield.hasOptedIn[msg.sender] && yield.availableYield[msg.sender] > 0) {
            LibYieldGeneration._claimAvailableYield(_termId, msg.sender, _receiver);
        }
    }

    /// @param _collateral Collateral storage
    /// @param _term Term storage
    /// @param _defaulters Defaulters array
    /// @return share The total amount of collateral to be divided among non-beneficiaries
    /// @return expellants array of addresses that were expelled
    function _solveDefaulters(
        LibCollateralStorage.Collateral storage _collateral,
        LibTermStorage.Term memory _term,
        LibFundStorage.Fund storage _fund,
        address[] memory _defaulters
    ) internal returns (uint, address[] memory) {
        // require(_defaulters.length > 0, "No defaulters");

        address[] memory expellants = new address[](_defaulters.length);
        uint expellantsCounter;
        uint distributedCollateral;

        uint contributionAmountWei = IGetters(address(this)).getToCollateralConversionRate(
            _term.contributionAmount * 10 ** 18
        );

        // Determine who will be expelled and who will just pay the contribution from their collateral.
        for (uint i; i < _defaulters.length; ) {
            LibCollateralStorage.DefaulterState memory defaulterState;
            defaulterState.isBeneficiary = _fund.isBeneficiary[_defaulters[i]];
            uint collateralAmount = _collateral.collateralMembersBank[_defaulters[i]];
            if (defaulterState.isBeneficiary) {
                // Has the user been beneficiary?
                if (LibCollateral._isUnderCollaterized(_term.termId, _defaulters[i])) {
                    // Is the collateral below 1.0 X RCC?
                    if (_fund.beneficiariesFrozenPool[_defaulters[i]]) {
                        // Is the pool currently frozen?
                        if (collateralAmount >= contributionAmountWei) {
                            // Does the user's collateral cover a cycle?
                            defaulterState.payWithCollateral = true; // Pay with collateral
                            defaulterState.payWithFrozenPool = false; // Does not pay with frozen pool
                            defaulterState.gettingExpelled = false; // Not expelled
                        } else {
                            // We don't have to check exact amounts because the pool would always be deducted by consistent amounts
                            if (_fund.beneficiariesPool[_defaulters[i]] > 0) {
                                // Does the frozen stable token portion of the pool contain anything?
                                defaulterState.payWithCollateral = false; // Do not pay with collateral
                                defaulterState.payWithFrozenPool = true; // Pay with frozen pool
                                defaulterState.gettingExpelled = false; // Not expelled
                            } else {
                                // Is whatever is left from the collateral + received collateral portion of money pool below 1.0 X RCC?
                                if (
                                    collateralAmount +
                                        _collateral.collateralPaymentBank[_defaulters[i]] >=
                                    IGetters(address(this)).getRemainingCyclesContributionWei(
                                        _term.termId
                                    )
                                ) {
                                    defaulterState.payWithCollateral = true; // Pay with collateral
                                    defaulterState.payWithFrozenPool = true; // Pay with frozen pool
                                    defaulterState.gettingExpelled = false; // Not expelled
                                } else {
                                    defaulterState.payWithCollateral = true; // Pay with collateral
                                    defaulterState.payWithFrozenPool = true; // Pay with frozen pool
                                    defaulterState.gettingExpelled = true; // Expelled
                                }
                            }
                        }
                    } else {
                        defaulterState.payWithCollateral = true; // Pay with collateral
                        defaulterState.payWithFrozenPool = false; // Does not pay with frozen pool
                        defaulterState.gettingExpelled = true; // Expelled
                    }
                } else {
                    defaulterState.payWithCollateral = true; // Pay with collateral
                    defaulterState.payWithFrozenPool = false; // Does not pay with frozen pool
                    defaulterState.gettingExpelled = false; // Not expelled
                }
            } else {
                if (collateralAmount >= contributionAmountWei) {
                    defaulterState.payWithCollateral = true; // Pay with collateral
                    defaulterState.payWithFrozenPool = false; // Does not pay with frozen pool
                    defaulterState.gettingExpelled = false; // Not expelled
                } else {
                    defaulterState.payWithCollateral = false; // Pay with collateral
                    defaulterState.payWithFrozenPool = false; // Does not pay with frozen pool
                    defaulterState.gettingExpelled = true; // Expelled
                }
            }

            distributedCollateral += _payDefaulterContribution(
                _collateral,
                _fund,
                _term,
                _defaulters[i],
                contributionAmountWei,
                defaulterState
            );

            if (defaulterState.gettingExpelled) {
                expellants[expellantsCounter] = _defaulters[i];
                _fund.cycleOfExpulsion[expellants[expellantsCounter]] = _fund.currentCycle;

                unchecked {
                    ++expellantsCounter;
                }
            }

            unchecked {
                ++i;
            }
        }

        return (distributedCollateral, expellants);
    }

    /// @notice called internally to pay defaulter contribution
    function _payDefaulterContribution(
        LibCollateralStorage.Collateral storage _collateral,
        LibFundStorage.Fund storage _fund,
        LibTermStorage.Term memory _term,
        address _defaulter,
        uint _contributionAmountWei,
        LibCollateralStorage.DefaulterState memory _defaulterState
    ) internal returns (uint distributedCollateral) {
        LibYieldGenerationStorage.YieldGeneration storage yield = LibYieldGenerationStorage
            ._yieldStorage()
            .yields[_term.termId];

        address beneficiary = IGetters(address(this)).getCurrentBeneficiary(_term.termId);
        if (_defaulterState.payWithCollateral && !_defaulterState.payWithFrozenPool) {
            if (_defaulterState.gettingExpelled) {
                if (_defaulterState.isBeneficiary) {
                    uint remainingCollateral = _collateral.collateralMembersBank[_defaulter];
                    _withdrawFromYield(_term.termId, _defaulter, remainingCollateral, yield);

                    distributedCollateral += remainingCollateral; // This will be distributed later
                    _collateral.collateralMembersBank[_defaulter] = 0;
                    emit OnCollateralLiquidated(_term.termId, _defaulter, remainingCollateral);
                }

                // Expelled
                _collateral.isCollateralMember[_defaulter] = false;
            } else {
                _withdrawFromYield(_term.termId, _defaulter, _contributionAmountWei, yield);

                // Subtract contribution from defaulter and add to beneficiary.
                _collateral.collateralMembersBank[_defaulter] -= _contributionAmountWei;
                _collateral.collateralPaymentBank[beneficiary] += _contributionAmountWei;

                emit OnCollateralLiquidated(_term.termId, _defaulter, _contributionAmountWei);
            }
        }
        if (_defaulterState.payWithFrozenPool && !_defaulterState.payWithCollateral) {
            _fund.beneficiariesPool[_defaulter] -= _term.contributionAmount * 10 ** 6;
            _fund.beneficiariesPool[beneficiary] += _term.contributionAmount * 10 ** 6;

            emit OnFrozenMoneyPotLiquidated(_term.termId, _defaulter, _term.contributionAmount);
        }
        if (_defaulterState.payWithCollateral && _defaulterState.payWithFrozenPool) {
            uint remainingCollateral = _collateral.collateralMembersBank[_defaulter];
            uint remainingCollateralFromPayments = _collateral.collateralPaymentBank[_defaulter];
            uint contributionAmountWei = IGetters(address(this)).getToCollateralConversionRate(
                _term.contributionAmount * 10 ** 18
            );

            if (remainingCollateral > 0) {
                _withdrawFromYield(_term.termId, _defaulter, remainingCollateral, yield);

                emit OnCollateralLiquidated(_term.termId, _defaulter, remainingCollateral);
            }
            if (_defaulterState.gettingExpelled) {
                distributedCollateral += (remainingCollateral + remainingCollateralFromPayments);
                _collateral.collateralMembersBank[_defaulter] = 0;
                _collateral.collateralPaymentBank[_defaulter] = 0;
                emit OnFrozenMoneyPotLiquidated(
                    _term.termId,
                    _defaulter,
                    remainingCollateralFromPayments
                );
            } else {
                // Remaining collateral is always less than contribution amount if/when we reach this
                if (remainingCollateral > 0) {
                    // Remove any last remaining collateral
                    uint toDeductFromPayments = contributionAmountWei - remainingCollateral;
                    _collateral.collateralMembersBank[_defaulter] = 0;
                    _collateral.collateralPaymentBank[_defaulter] -= toDeductFromPayments;
                    emit OnFrozenMoneyPotLiquidated(
                        _term.termId,
                        _defaulter,
                        remainingCollateralFromPayments
                    );
                } else {
                    _collateral.collateralPaymentBank[_defaulter] -= contributionAmountWei;
                    emit OnFrozenMoneyPotLiquidated(
                        _term.termId,
                        _defaulter,
                        contributionAmountWei
                    );
                }

                _collateral.collateralPaymentBank[beneficiary] += _contributionAmountWei;
            }
        }
    }

    /// @param _collateral Collateral storage
    /// @param _fund Fund storage
    /// @return nonBeneficiaryCounter The total amount of collateral to be divided among non-beneficiaries
    /// @return nonBeneficiaries array of addresses that were expelled
    function _findNonBeneficiaries(
        LibCollateralStorage.Collateral storage _collateral,
        LibFundStorage.Fund storage _fund
    ) internal view returns (uint, address[] memory) {
        address currentDepositor;
        address[] memory nonBeneficiaries = new address[](_collateral.depositors.length);
        uint nonBeneficiaryCounter;

        // Check beneficiaries
        uint depositorsLength = _collateral.depositors.length;
        for (uint i; i < depositorsLength; ) {
            currentDepositor = _collateral.depositors[i];
            if (
                !_fund.isBeneficiary[currentDepositor] &&
                _collateral.isCollateralMember[currentDepositor]
            ) {
                nonBeneficiaries[nonBeneficiaryCounter] = currentDepositor;
                nonBeneficiaryCounter++;
            }
            unchecked {
                ++i;
            }
        }

        return (nonBeneficiaryCounter, nonBeneficiaries);
    }

    function _withdrawFromYield(
        uint _termId,
        address _user,
        uint _amount,
        LibYieldGenerationStorage.YieldGeneration storage _yieldStorage
    ) internal returns (uint withdrawnYield) {
        if (_yieldStorage.hasOptedIn[_user]) {
            uint amountToWithdraw;
            if (_amount > _yieldStorage.depositedCollateralByUser[_user]) {
                amountToWithdraw = _yieldStorage.depositedCollateralByUser[_user];
            } else {
                amountToWithdraw = _amount;
            }
            withdrawnYield = LibYieldGeneration._withdrawYG(_termId, amountToWithdraw, _user);
        } else {
            withdrawnYield = 0;
        }
    }

    function _atState(uint _termId, LibCollateralStorage.CollateralStates _state) internal view {
        LibCollateralStorage.CollateralStates state = LibCollateralStorage
            ._collateralStorage()
            .collaterals[_termId]
            .state;
        if (state != _state) revert FunctionInvalidAtThisState();
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;

/// @title Takaturn Collateral Interface
/// @author Aisha EL Allam
/// @notice This is used to allow fund to easily communicate with collateral
/// @dev v2.0 (post-deploy)

import {LibCollateralStorage} from "../libraries/LibCollateralStorage.sol";
import {LibTermStorage} from "../libraries/LibTermStorage.sol";

interface ICollateral {
    // Function cannot be called at this time.
    error FunctionInvalidAtThisState();

    /// @notice Called from Fund contract when someone defaults
    /// @dev Check EnumerableMap (openzeppelin) for arrays that are being accessed from Fund contract
    /// @param term the term object
    /// @param defaulters Address that was randomly selected for the current cycle
    function requestContribution(
        LibTermStorage.Term memory term,
        address[] calldata defaulters
    ) external returns (address[] memory);

    /// @notice Called by each member after the end of the cycle to withraw collateral
    /// @dev This follows the pull-over-push pattern.
    /// @param termId The term id
    function withdrawCollateral(uint termId) external;

    /// @param termId The term id
    function releaseCollateral(uint termId) external;

    /// @notice allow the owner to empty the Collateral after 180 days
    function emptyCollateralAfterEnd(uint termId) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {LibTermStorage} from "../libraries/LibTermStorage.sol";
import {LibCollateralStorage} from "../libraries/LibCollateralStorage.sol";
import {LibFundStorage} from "../libraries/LibFundStorage.sol";

interface IGetters {
    // TERM GETTERS

    /// @notice Gets the current and next term id
    /// @return current termID
    /// @return next termID
    function getTermsId() external view returns (uint, uint);

    /// @notice Must return 0 before starting the fund
    /// @param termId the id of the term
    /// @return remaining registration time in seconds
    function getRemainingRegistrationTime(uint termId) external view returns (uint);

    /// @notice Get current information of a term
    /// @param termId the id of the term
    /// @return Term Struct, see LibTermStorage.sol
    function getTermSummary(uint termId) external view returns (LibTermStorage.Term memory);

    /// @notice Gets all terms a user has previously joined
    /// @param participant address
    /// @return List of termIDs
    function getAllJoinedTerms(address participant) external view returns (uint[] memory);

    /// @notice Gets all terms a user has previously joined based on the specefied term state
    /// @param participant address
    /// @param state, can be InitializingTerm, ActiveTerm, ExpiredTerm, ClosedTerm
    /// @return List of termIDs
    function getJoinedTermsByState(
        address participant,
        LibTermStorage.TermStates state
    ) external view returns (uint[] memory);

    /// @notice Gets all terms a user was previously expelled from
    /// @param participant address
    /// @return List of termIDs
    function getExpelledTerms(address participant) external view returns (uint[] memory);

    /// @notice Gets all remaining cycles of a term
    /// @param termId the id of the term
    /// @return remaining cycles
    function getRemainingCycles(uint termId) external view returns (uint);

    /// @notice Must be 0 before starting a new cycle
    /// @param termId the id of the term
    /// @return remaining cycle time in seconds
    function getRemainingCycleTime(uint termId) external view returns (uint);

    /// @notice Gets the expected remaining contribution amount for users in a term
    /// @param termId the id of the term
    /// @return total remaining contribution in wei
    function getRemainingCyclesContributionWei(uint termId) external view returns (uint);

    /// @notice a function to get the needed allowance
    /// @param user the user address
    /// @return the needed allowance
    function getNeededAllowance(address user) external view returns (uint);

    // COLLATERAL GETTERS

    /// @notice Gets a users collateral summary
    /// @param depositor address
    /// @param termId the id of the term
    /// @return if the user is a true member of the term
    /// @return current users locked collateral balance in wei
    /// @return current users unlocked collateral balance in wei
    /// @return initial users deposit in wei
    /// @return expulsion limit
    function getDepositorCollateralSummary(
        address depositor,
        uint termId
    ) external view returns (bool, uint, uint, uint, uint);

    /// @notice Gets the collateral summary of a term
    /// @param termId the id of the term
    /// @return if collateral is initialized
    /// @return current state of the collateral, see States struct in LibCollateralStorage.sol
    /// @return time of first deposit in seconds, 0 if no deposit occured yet
    /// @return current member count
    /// @return list of depositors
    function getCollateralSummary(
        uint termId
    )
        external
        view
        returns (bool, LibCollateralStorage.CollateralStates, uint, uint, address[] memory);

    /// @notice Gets the required minimum collateral deposit based on the position
    /// @param termId the term id
    /// @param depositorIndex the index of the depositor
    /// @return required minimum in wei
    function minCollateralToDeposit(uint termId, uint depositorIndex) external view returns (uint);

    /// @notice Called to check how much collateral a user can withdraw
    /// @param termId term id
    /// @param user depositor address
    /// @return allowedWithdrawal amount the amount of collateral the depositor can withdraw
    function getWithdrawableUserBalance(
        uint termId,
        address user
    ) external view returns (uint allowedWithdrawal);

    /// @notice Checks if a user has a collateral below 1.0x of total contribution amount
    /// @dev This will revert if called during ReleasingCollateral or after
    /// @param termId The term id
    /// @param member The user to check for
    /// @return Bool check if member is below 1.0x of collateralDeposit
    function isUnderCollaterized(uint termId, address member) external view returns (bool);

    // FUND GETTERS
    /// @notice Gets the fund summary of a term
    /// @param termId the id of the term
    /// @return if fund is initialized
    /// @return current state of the fund, see States struct in LibFund.sol
    /// @return stablecoin address used
    /// @return list for order of beneficiaries
    /// @return when the fund started in seconds
    /// @return when the fund ended in seconds, 0 otherwise
    /// @return current cycle of fund
    /// @return total amount of cycles in this fund/term
    function getFundSummary(
        uint termId
    )
        external
        view
        returns (bool, LibFundStorage.FundStates, IERC20, address[] memory, uint, uint, uint, uint);

    /// @notice Gets the current beneficiary of a term
    /// @param termId the id of the term
    /// @return user address
    function getCurrentBeneficiary(uint termId) external view returns (address);

    /// @notice Gets if a user is expelled from a specefic term
    /// @param termId the id of the term
    /// @param user address
    /// @return true or false
    function wasExpelled(uint termId, address user) external view returns (bool);

    /// @notice Gets if a user is exempted from paying for a specefic cycle
    /// @param termId the id of the term
    /// @param cycle number
    /// @param user address
    /// @return true or false
    function isExempted(uint termId, uint cycle, address user) external view returns (bool);

    /// @notice Gets a user information of in a fund
    /// @param participant address
    /// @param termId the id of the term
    /// @return if the user is a true member of the fund/term
    /// @return if the user was beneficiary in the past
    /// @return if the user paid for the current cycle
    /// @return if the user has autopay enabled
    /// @return users money pot balance
    function getParticipantFundSummary(
        address participant,
        uint termId
    ) external view returns (bool, bool, bool, bool, uint, bool);

    /// @notice Must return 0 before closing a contribution period
    /// @param termId the id of the term
    /// @return remaining contribution time in seconds
    function getRemainingContributionTime(uint termId) external view returns (uint);

    /// @param termId the id of the term
    /// @param beneficiary the address of the participant to check
    /// @return true if the participant is a beneficiary
    function isBeneficiary(uint termId, address beneficiary) external view returns (bool);

    /// @param termId the id of the term
    /// @param user the address of the participant to check
    /// @return true if the participant is expelled before being a beneficiary
    function expelledBeforeBeneficiary(uint termId, address user) external view returns (bool);

    // CONVERSION GETTERS

    function getToCollateralConversionRate(uint USDAmount) external view returns (uint);

    function getToStableConversionRate(uint ethAmount) external view returns (uint);

    // YIELD GENERATION GETTERS

    function userHasoptedInYG(uint termId, address user) external view returns (bool);

    function userAPY(uint termId, address user) external view returns (uint256);

    function termAPY(uint termId) external view returns (uint256);

    function totalYieldGenerated(uint termId) external view returns (uint);

    /// @param user the depositor address
    /// @param termId the collateral id
    /// @return hasOptedIn
    /// @return withdrawnYield
    /// @return withdrawnCollateral
    /// @return availableYield
    /// @return depositedCollateralByUser
    /// @return yieldDistributed
    function getUserYieldSummary(
        address user,
        uint termId
    ) external view returns (bool, uint, uint, uint, uint, uint);

    /// @param termId the collateral id
    /// @return initialized
    /// @return startTimeStamp
    /// @return totalDeposit
    /// @return currentTotalDeposit
    /// @return totalShares
    /// @return yieldUsers
    /// @return vaultAddress
    /// @return zapAddress
    function getYieldSummary(
        uint termId
    ) external view returns (bool, uint, uint, uint, uint, address[] memory, address, address);

    function getYieldLockState() external view returns (bool);

    /// @notice This function return the current constant values for oracles and yield providers
    /// @param firstAggregator The name of the first aggregator. Example: "ETH/USD"
    /// @param secondAggregator The name of the second aggregator. Example: "USDC/USD"
    /// @param zapAddress The name of the zap address. Example: "ZaynZap"
    /// @param vaultAddress The name of the vault address. Example: "ZaynVault"
    function getConstants(
        string memory firstAggregator,
        string memory secondAggregator,
        string memory zapAddress,
        string memory vaultAddress
    ) external view returns (address, address, address, address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;

import {LibTermStorage} from "../libraries/LibTermStorage.sol";

interface IYGFacetZaynFi {
    /// @notice This function allows a user to claim the current available yield
    /// @param termId The term id for which the yield is being claimed
    /// @param receiver The address of the user who will receive the yield
    function claimAvailableYield(uint termId, address receiver) external;

    /// @notice This function allows a user to toggle their yield generation
    /// @dev only allowed before the term starts
    /// @param termId The term id for which the yield is being claimed
    function toggleOptInYG(uint termId) external;

    /// @notice This function allows the owner to update the global variable for new yield provider
    /// @param providerString The provider string for which the address is being updated
    /// @param providerAddress The new address of the provider
    function updateYieldProvider(string memory providerString, address providerAddress) external;

    /// @notice This function allows the owner to disable the yield generation feature in case of emergency
    function toggleYieldLock() external returns (bool);

    /// @notice To be used in case of emergency, when the provider needs to change the zap or the vault
    /// @param termId The term id for which the yield is being claimed
    /// @param providerString The provider string for which the address is being updated
    /// @param providerAddress The new address of the provider
    function updateProviderAddressOnTerms(
        uint termId,
        string memory providerString,
        address providerAddress
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

interface IZaynVaultV2TakaDao {
    function totalSupply() external view returns (uint256);

    function depositZap(uint256 _amount, uint256 _term) external;

    function withdrawZap(uint256 _shares, uint256 _term) external;

    function want() external view returns (address);

    function balance() external view returns (uint256);

    function strategy() external view returns (address);

    function balanceOf(uint256 term) external view returns (uint256);

    function getPricePerFullShare() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

interface IZaynZapV2TakaDAO {
    function zapInEth(address vault, uint256 termID) external payable;

    function zapOutETH(address vault, uint256 _shares, uint256 termID) external returns (uint);

    function toggleTrustedSender(address _trustedSender, bool _allow) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {IGetters} from "../interfaces/IGetters.sol";

import {LibCollateralStorage} from "./LibCollateralStorage.sol";
import {LibFundStorage} from "./LibFundStorage.sol";

library LibCollateral {
    event OnCollateralStateChanged(
        uint indexed termId,
        LibCollateralStorage.CollateralStates indexed oldState,
        LibCollateralStorage.CollateralStates indexed newState
    );
    event OnReimbursementWithdrawn(
        uint indexed termId,
        address indexed participant,
        address receiver,
        uint indexed amount
    );

    /// @param _termId term id
    /// @param _newState collateral state
    function _setState(uint _termId, LibCollateralStorage.CollateralStates _newState) internal {
        LibCollateralStorage.Collateral storage collateral = LibCollateralStorage
            ._collateralStorage()
            .collaterals[_termId];
        LibCollateralStorage.CollateralStates oldState = collateral.state;
        collateral.state = _newState;
        emit OnCollateralStateChanged(_termId, oldState, _newState);
    }

    /// @param _termId term id
    /// @param _participant Address of the depositor
    function _withdrawReimbursement(
        uint _termId,
        address _participant,
        address _receiver
    ) internal {
        require(LibFundStorage._fundExists(_termId), "Fund does not exists");
        LibCollateralStorage.Collateral storage collateral = LibCollateralStorage
            ._collateralStorage()
            .collaterals[_termId];

        uint amount = collateral.collateralPaymentBank[_participant];
        require(amount > 0, "Nothing to claim");
        collateral.collateralPaymentBank[_participant] = 0;

        (bool success, ) = payable(_receiver).call{value: amount}("");
        require(success);

        emit OnReimbursementWithdrawn(_termId, _participant, _receiver, amount);
    }

    /// @notice Checks if a user has a collateral below 1.0x of total contribution amount
    /// @dev This will revert if called during ReleasingCollateral or after
    /// @param _termId The fund id
    /// @param _member The user to check for
    /// @return Bool check if member is below 1.0x of collateralDeposit
    function _isUnderCollaterized(uint _termId, address _member) internal view returns (bool) {
        LibCollateralStorage.Collateral storage collateral = LibCollateralStorage
            ._collateralStorage()
            .collaterals[_termId];

        uint collateralLimit;
        uint memberCollateral = collateral.collateralMembersBank[_member];

        if (!LibFundStorage._fundExists(_termId)) {
            // Only check here when starting the term
            (, , , , collateralLimit) = IGetters(address(this)).getDepositorCollateralSummary(
                _member,
                _termId
            );
        } else {
            collateralLimit = IGetters(address(this)).getRemainingCyclesContributionWei(_termId);
        }

        return (memberCollateral < collateralLimit);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

library LibCollateralStorage {
    bytes32 constant COLLATERAL_STORAGE_POSITION = keccak256("diamond.standard.collateral.storage");

    enum CollateralStates {
        AcceptingCollateral, // Initial state where collateral are deposited
        CycleOngoing, // Triggered when a fund instance is created, no collateral can be accepted
        ReleasingCollateral, // Triggered when the fund closes
        Closed // Triggered when all depositors withdraw their collaterals
    }

    struct DefaulterState {
        bool payWithCollateral;
        bool payWithFrozenPool;
        bool gettingExpelled;
        bool isBeneficiary;
    }

    struct Collateral {
        bool initialized;
        CollateralStates state;
        uint firstDepositTime;
        uint counterMembers;
        address[] depositors;
        mapping(address => bool) isCollateralMember; // Determines if a depositor is a valid user
        mapping(address => uint) collateralMembersBank; // Users main balance
        mapping(address => uint) collateralPaymentBank; // Users reimbursement balance after someone defaults
        mapping(address => uint) collateralDepositByUser; // Depends on the depositors index
    }

    struct CollateralStorage {
        mapping(uint => Collateral) collaterals; // termId => Collateral struct
    }

    function _collateralExists(uint termId) internal view returns (bool) {
        return _collateralStorage().collaterals[termId].initialized;
    }

    function _collateralStorage()
        internal
        pure
        returns (CollateralStorage storage collateralStorage)
    {
        bytes32 position = COLLATERAL_STORAGE_POSITION;
        assembly {
            collateralStorage.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library LibFundStorage {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 constant FUND_POSITION = keccak256("diamond.standard.fund");
    bytes32 constant FUND_STORAGE_POSITION = keccak256("diamond.standard.fund.storage");

    enum FundStates {
        InitializingFund, // Time before the first cycle has started
        AcceptingContributions, // Triggers at the start of a cycle
        AwardingBeneficiary, // Contributions are closed, beneficiary is chosen, people default etc.
        CycleOngoing, // Time after beneficiary is chosen, up till the start of the next cycle
        FundClosed // Triggers at the end of the last contribution period, no state changes after this
    }

    struct PayExemption {
        mapping(address => bool) exempted; // Mapping to keep track of if someone is exempted from paying
    }

    struct Fund {
        bool initialized;
        FundStates currentState; // Variable to keep track of the different FundStates
        IERC20 stableToken; // Instance of the stable token
        address[] beneficiariesOrder; // The correct order of who gets to be next beneficiary, determined by collateral contract
        uint fundStart; // Timestamp of the start of the fund
        uint fundEnd; // Timestamp of the end of the fund
        uint currentCycle; // Index of current cycle
        mapping(address => bool) isParticipant; // Mapping to keep track of who's a participant or not
        mapping(address => bool) isBeneficiary; // Mapping to keep track of who's a beneficiary or not
        mapping(address => bool) paidThisCycle; // Mapping to keep track of who paid for this cycle
        mapping(address => bool) autoPayEnabled; // Wheter to attempt to automate payments at the end of the contribution period
        mapping(address => uint) beneficiariesPool; // Mapping to keep track on how much each beneficiary can claim. Six decimals
        mapping(address => bool) beneficiariesFrozenPool; // Frozen pool by beneficiaries, it can claim when his collateral is at least 1.1 X RCC
        mapping(address => uint) cycleOfExpulsion; // Mapping to keep track on which cycle a user was expelled
        mapping(uint => PayExemption) isExemptedOnCycle; // Mapping to keep track of if someone is exempted from paying this cycle
        EnumerableSet.AddressSet _participants; // Those who have not been beneficiaries yet and have not defaulted this cycle
        EnumerableSet.AddressSet _beneficiaries; // Those who have been beneficiaries and have not defaulted this cycle
        EnumerableSet.AddressSet _defaulters; // Both participants and beneficiaries who have defaulted this cycle
        uint expelledParticipants; // Total amount of participants that have been expelled so far
        uint totalAmountOfCycles;
        mapping(address => bool) expelledBeforeBeneficiary; // Mapping to keep track of who has been expelled before being a beneficiary
    }

    struct FundStorage {
        mapping(uint => Fund) funds; // termId => Fund struct
    }

    function _fundExists(uint termId) internal view returns (bool) {
        return _fundStorage().funds[termId].initialized;
    }

    function _fundStorage() internal pure returns (FundStorage storage fundStorage) {
        bytes32 position = FUND_STORAGE_POSITION;
        assembly {
            fundStorage.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {LibTermStorage} from "../libraries/LibTermStorage.sol";

library LibTermOwnership {
    /**
     * @dev Throws if the sender is not the term owner.
     * @dev Used for internal calls
     */
    function _ensureTermOwner(uint termId) internal view {
        require(
            LibTermStorage._termStorage().terms[termId].termOwner == msg.sender,
            "TermOwnable: caller is not the owner"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

library LibTermStorage {
    bytes32 constant TERM_CONSTS_POSITION = keccak256("diamond.standard.term.consts");
    bytes32 constant TERM_STORAGE_POSITION = keccak256("diamond.standard.term.storage");

    enum TermStates {
        InitializingTerm,
        ActiveTerm,
        ExpiredTerm,
        ClosedTerm
    }

    struct TermConsts {
        mapping(string => address) aggregatorsAddresses; // "ETH/USD" => address , "USDC/USD" => address
    }

    struct Term {
        bool initialized;
        TermStates state;
        address termOwner;
        uint creationTime;
        uint termId;
        uint registrationPeriod; // Time for registration (seconds)
        uint totalParticipants; // Max number of participants
        uint cycleTime; // Time for single cycle (seconds)
        uint contributionAmount; // Amount user must pay per cycle (USD)
        uint contributionPeriod; // The portion of cycle user must make payment
        address stableTokenAddress;
    }

    struct TermStorage {
        uint nextTermId;
        mapping(uint => Term) terms; // termId => Term struct
        mapping(address => uint[]) participantToTermId; // userAddress => [termId1, termId2, ...]
    }

    function _termExists(uint termId) internal view returns (bool) {
        return _termStorage().terms[termId].initialized;
    }

    function _termConsts() internal pure returns (TermConsts storage termConsts) {
        bytes32 position = TERM_CONSTS_POSITION;
        assembly {
            termConsts.slot := position
        }
    }

    function _termStorage() internal pure returns (TermStorage storage termStorage) {
        bytes32 position = TERM_STORAGE_POSITION;
        assembly {
            termStorage.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {IZaynZapV2TakaDAO} from "../interfaces/IZaynZapV2TakaDAO.sol";
import {IZaynVaultV2TakaDao} from "../interfaces/IZaynVaultV2TakaDao.sol";

import {LibYieldGenerationStorage} from "../libraries/LibYieldGenerationStorage.sol";

library LibYieldGeneration {
    event OnYieldClaimed(
        uint indexed termId,
        address indexed user,
        address receiver,
        uint indexed amount
    ); // Emits when a user claims their yield

    /// @notice This function is used to deposit collateral for yield generation
    /// @param _termId The term id for which the collateral is being deposited
    /// @param _ethAmount The amount of collateral being deposited
    function _depositYG(uint _termId, uint _ethAmount) internal {
        LibYieldGenerationStorage.YieldGeneration storage yield = LibYieldGenerationStorage
            ._yieldStorage()
            .yields[_termId];

        yield.totalDeposit = _ethAmount;
        yield.currentTotalDeposit = _ethAmount;

        address vaultAddress = yield.providerAddresses["ZaynVault"];

        IZaynZapV2TakaDAO(yield.providerAddresses["ZaynZap"]).zapInEth{value: _ethAmount}(
            vaultAddress,
            _termId
        );

        yield.totalShares = IZaynVaultV2TakaDao(vaultAddress).balanceOf(_termId);
    }

    /// @notice This function is used to withdraw collateral from the yield generation protocol
    /// @param _termId The term id for which the collateral is being withdrawn
    /// @param _collateralAmount The amount of collateral being withdrawn
    /// @param _user The user address that is withdrawing the collateral
    function _withdrawYG(
        uint _termId,
        uint256 _collateralAmount,
        address _user
    ) internal returns (uint) {
        LibYieldGenerationStorage.YieldGeneration storage yield = LibYieldGenerationStorage
            ._yieldStorage()
            .yields[_termId];

        uint neededShares = _ethToShares(_collateralAmount, yield);

        yield.withdrawnCollateral[_user] += _collateralAmount;
        yield.currentTotalDeposit -= _collateralAmount;

        address zapAddress = yield.providerAddresses["ZaynZap"];
        address vaultAddress = yield.providerAddresses["ZaynVault"];

        uint withdrawnAmount = IZaynZapV2TakaDAO(zapAddress).zapOutETH(
            vaultAddress,
            neededShares,
            _termId
        );

        if (withdrawnAmount < _collateralAmount) {
            return 0;
        } else {
            uint withdrawnYield = withdrawnAmount - _collateralAmount;
            yield.withdrawnYield[_user] += withdrawnYield;
            yield.availableYield[_user] += withdrawnYield;

            return withdrawnYield;
        }
    }

    /// @notice Conversion from shares to eth
    /// @param _termId The term id
    /// @param _yield The yield generation struct
    function _sharesToEth(
        uint _termId,
        LibYieldGenerationStorage.YieldGeneration storage _yield
    ) internal view returns (uint) {
        uint termBalance = IZaynVaultV2TakaDao(_yield.providerAddresses["ZaynVault"]).balanceOf(
            _termId
        );

        uint pricePerShare = IZaynVaultV2TakaDao(_yield.providerAddresses["ZaynVault"])
            .getPricePerFullShare();

        return (termBalance * pricePerShare) / 10 ** 18;
    }

    /// @notice Conversion from eth to shares
    /// @param _collateralAmount The amount of collateral to withdraw
    /// @param _yield The yield generation struct
    function _ethToShares(
        uint _collateralAmount,
        LibYieldGenerationStorage.YieldGeneration storage _yield
    ) internal view returns (uint) {
        uint pricePerShare = IZaynVaultV2TakaDao(_yield.providerAddresses["ZaynVault"])
            .getPricePerFullShare();

        return ((_collateralAmount * 10 ** 18) / pricePerShare);
    }

    /// @notice This function is used to get the current total yield generated for a term
    /// @param _termId The term id for which the yield is being calculated
    /// @return The total yield generated for the term
    function _currentYieldGenerated(uint _termId) internal view returns (uint) {
        LibYieldGenerationStorage.YieldGeneration storage yield = LibYieldGenerationStorage
            ._yieldStorage()
            .yields[_termId];

        uint termBalance = IZaynVaultV2TakaDao(yield.providerAddresses["ZaynVault"]).balanceOf(
            _termId
        );
        uint pricePerShare = IZaynVaultV2TakaDao(yield.providerAddresses["ZaynVault"])
            .getPricePerFullShare();

        uint sharesInEth = (termBalance * pricePerShare) / 10 ** 18;
        if (sharesInEth > yield.currentTotalDeposit) {
            return sharesInEth - yield.currentTotalDeposit;
        } else {
            return 0;
        }
    }

    /// @notice This function is used to get the yield distribution ratio for a user
    /// @param _termId The term id for which the ratio is being calculated
    /// @param _user The user for which the ratio is being calculated
    /// @return The yield distribution ratio for the user
    function _yieldDistributionRatio(uint _termId, address _user) internal view returns (uint256) {
        LibYieldGenerationStorage.YieldGeneration storage yield = LibYieldGenerationStorage
            ._yieldStorage()
            .yields[_termId];

        if (yield.currentTotalDeposit == 0) {
            return 0;
        } else {
            return
                ((yield.depositedCollateralByUser[_user] - yield.withdrawnCollateral[_user]) *
                    10 ** 18) / yield.currentTotalDeposit;
        }
    }

    /// @notice This function is used to get the total yield generated for a user
    /// @param termId The term id for which the yield is being calculated
    /// @param user The user for which the yield is being calculated
    /// @return The total yield generated for the user
    function _unwithdrawnUserYieldGenerated(
        uint termId,
        address user
    ) internal view returns (uint) {
        uint yieldDistributed = (_currentYieldGenerated(termId) *
            _yieldDistributionRatio(termId, user)) / 10 ** 18;

        return yieldDistributed;
    }

    function _claimAvailableYield(uint _termId, address _user, address _receiver) internal {
        LibYieldGenerationStorage.YieldGeneration storage yield = LibYieldGenerationStorage
            ._yieldStorage()
            .yields[_termId];

        uint availableYield = yield.availableYield[_user];

        require(availableYield > 0, "No yield to withdraw");

        yield.availableYield[_user] = 0;
        (bool success, ) = payable(_receiver).call{value: availableYield}("");
        require(success);

        emit OnYieldClaimed(_termId, _user, _receiver, availableYield);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

library LibYieldGenerationStorage {
    bytes32 constant YIELD_PROVIDERS_POSITION = keccak256("diamond.standard.yield.providers");
    bytes32 constant YIELD_STORAGE_POSITION = keccak256("diamond.standard.yield.storage");
    bytes32 constant YIELD_LOCK_POSITION = keccak256("diamond.standard.yield.lock");

    enum YGProviders {
        InHouse,
        ZaynFi
    }

    struct YieldLock {
        bool yieldLock;
    }

    // Both index 0 are reserved for ZaynFi
    struct YieldProviders {
        mapping(string => address) providerAddresses;
    }

    struct YieldGeneration {
        bool initialized;
        YGProviders provider;
        mapping(string => address) providerAddresses;
        uint startTimeStamp;
        uint totalDeposit;
        uint currentTotalDeposit;
        uint totalShares;
        address[] yieldUsers;
        mapping(address => bool) hasOptedIn;
        mapping(address => uint256) withdrawnYield;
        mapping(address => uint256) withdrawnCollateral;
        mapping(address => uint256) availableYield;
        mapping(address => uint256) depositedCollateralByUser;
    }

    struct YieldStorage {
        mapping(uint => YieldGeneration) yields; // termId => YieldGeneration struct
    }

    function _yieldExists(uint termId) internal view returns (bool) {
        return _yieldStorage().yields[termId].initialized;
    }

    function _yieldLock() internal pure returns (YieldLock storage yieldLock) {
        bytes32 position = YIELD_LOCK_POSITION;
        assembly {
            yieldLock.slot := position
        }
    }

    function _yieldProviders() internal pure returns (YieldProviders storage yieldProviders) {
        bytes32 position = YIELD_PROVIDERS_POSITION;
        assembly {
            yieldProviders.slot := position
        }
    }

    function _yieldStorage() internal pure returns (YieldStorage storage yieldStorage) {
        bytes32 position = YIELD_STORAGE_POSITION;
        assembly {
            yieldStorage.slot := position
        }
    }
}