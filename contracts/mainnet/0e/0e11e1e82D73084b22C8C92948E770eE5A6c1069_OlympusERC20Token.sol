pragma solidity 0.7.5;
import "../contracts/mocks/interfaces/ICamelotRouter.sol";
import "../contracts/mocks/interfaces/ICamelotPair.sol";
import "../contracts/mocks/interfaces/ICamelotFactory.sol";

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

      // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
      // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

      bytes32 lastvalue = set._values[lastIndex];

      // Move the last value to the index where the value to delete is
      set._values[toDeleteIndex] = lastvalue;
      // Update the index for the moved value
      set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
  function _contains(
    Set storage set,
    bytes32 value
  ) private view returns (bool) {
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
    require(set._values.length > index, "EnumerableSet: index out of bounds");
    return set._values[index];
  }

  function _getValues(
    Set storage set_
  ) private view returns (bytes32[] storage) {
    return set_._values;
  }

  // TODO needs insert function that maintains order.
  // TODO needs NatSpec documentation comment.
  /**
   * Inserts new value by moving existing value at provided index to end of array and setting provided value at provided index
   */
  function _insert(
    Set storage set_,
    uint256 index_,
    bytes32 valueToInsert_
  ) private returns (bool) {
    require(set_._values.length > index_);
    require(
      !_contains(set_, valueToInsert_),
      "Remove value you wish to insert if you wish to reorder array."
    );
    bytes32 existingValue_ = _at(set_, index_);
    set_._values[index_] = valueToInsert_;
    return _add(set_, existingValue_);
  }

  struct Bytes4Set {
    Set _inner;
  }

  /**
   * @dev Add a value to a set. O(1).
   *
   * Returns true if the value was added to the set, that is if it was not
   * already present.
   */
  function add(Bytes4Set storage set, bytes4 value) internal returns (bool) {
    return _add(set._inner, value);
  }

  /**
   * @dev Removes a value from a set. O(1).
   *
   * Returns true if the value was removed from the set, that is if it was
   * present.
   */
  function remove(Bytes4Set storage set, bytes4 value) internal returns (bool) {
    return _remove(set._inner, value);
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
   */
  function contains(
    Bytes4Set storage set,
    bytes4 value
  ) internal view returns (bool) {
    return _contains(set._inner, value);
  }

  /**
   * @dev Returns the number of values on the set. O(1).
   */
  function length(Bytes4Set storage set) internal view returns (uint256) {
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
  function at(
    Bytes4Set storage set,
    uint256 index
  ) internal view returns (bytes4) {
    return bytes4(_at(set._inner, index));
  }

  function getValues(
    Bytes4Set storage set_
  ) internal view returns (bytes4[] memory) {
    bytes4[] memory bytes4Array_;
    for (
      uint256 iteration_ = 0;
      _length(set_._inner) > iteration_;
      iteration_++
    ) {
      bytes4Array_[iteration_] = bytes4(_at(set_._inner, iteration_));
    }
    return bytes4Array_;
  }

  function insert(
    Bytes4Set storage set_,
    uint256 index_,
    bytes4 valueToInsert_
  ) internal returns (bool) {
    return _insert(set_._inner, index_, valueToInsert_);
  }

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
  function remove(
    Bytes32Set storage set,
    bytes32 value
  ) internal returns (bool) {
    return _remove(set._inner, value);
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
   */
  function contains(
    Bytes32Set storage set,
    bytes32 value
  ) internal view returns (bool) {
    return _contains(set._inner, value);
  }

  /**
   * @dev Returns the number of values on the set. O(1).
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
  function at(
    Bytes32Set storage set,
    uint256 index
  ) internal view returns (bytes32) {
    return _at(set._inner, index);
  }

  function getValues(
    Bytes32Set storage set_
  ) internal view returns (bytes4[] memory) {
    bytes4[] memory bytes4Array_;

    for (
      uint256 iteration_ = 0;
      _length(set_._inner) >= iteration_;
      iteration_++
    ) {
      bytes4Array_[iteration_] = bytes4(at(set_, iteration_));
    }

    return bytes4Array_;
  }

  function insert(
    Bytes32Set storage set_,
    uint256 index_,
    bytes32 valueToInsert_
  ) internal returns (bool) {
    return _insert(set_._inner, index_, valueToInsert_);
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
    return _add(set._inner, bytes32(uint256(value)));
  }

  /**
   * @dev Removes a value from a set. O(1).
   *
   * Returns true if the value was removed from the set, that is if it was
   * present.
   */
  function remove(
    AddressSet storage set,
    address value
  ) internal returns (bool) {
    return _remove(set._inner, bytes32(uint256(value)));
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
   */
  function contains(
    AddressSet storage set,
    address value
  ) internal view returns (bool) {
    return _contains(set._inner, bytes32(uint256(value)));
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
  function at(
    AddressSet storage set,
    uint256 index
  ) internal view returns (address) {
    return address(uint256(_at(set._inner, index)));
  }

  /**
   * TODO Might require explicit conversion of bytes32[] to address[].
   *  Might require iteration.
   */
  function getValues(
    AddressSet storage set_
  ) internal view returns (address[] memory) {
    address[] memory addressArray;

    for (
      uint256 iteration_ = 0;
      _length(set_._inner) >= iteration_;
      iteration_++
    ) {
      addressArray[iteration_] = at(set_, iteration_);
    }

    return addressArray;
  }

  function insert(
    AddressSet storage set_,
    uint256 index_,
    address valueToInsert_
  ) internal returns (bool) {
    return _insert(set_._inner, index_, bytes32(uint256(valueToInsert_)));
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
  function contains(
    UintSet storage set,
    uint256 value
  ) internal view returns (bool) {
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
  function at(
    UintSet storage set,
    uint256 index
  ) internal view returns (uint256) {
    return uint256(_at(set._inner, index));
  }

  struct UInt256Set {
    Set _inner;
  }

  /**
   * @dev Add a value to a set. O(1).
   *
   * Returns true if the value was added to the set, that is if it was not
   * already present.
   */
  function add(UInt256Set storage set, uint256 value) internal returns (bool) {
    return _add(set._inner, bytes32(value));
  }

  /**
   * @dev Removes a value from a set. O(1).
   *
   * Returns true if the value was removed from the set, that is if it was
   * present.
   */
  function remove(
    UInt256Set storage set,
    uint256 value
  ) internal returns (bool) {
    return _remove(set._inner, bytes32(value));
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
   */
  function contains(
    UInt256Set storage set,
    uint256 value
  ) internal view returns (bool) {
    return _contains(set._inner, bytes32(value));
  }

  /**
   * @dev Returns the number of values on the set. O(1).
   */
  function length(UInt256Set storage set) internal view returns (uint256) {
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
  function at(
    UInt256Set storage set,
    uint256 index
  ) internal view returns (uint256) {
    return uint256(_at(set._inner, index));
  }
}

interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(
    address owner,
    address spender
  ) external view returns (uint256);

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
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

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
}

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }

  function sqrrt(uint256 a) internal pure returns (uint256 c) {
    if (a > 3) {
      c = a;
      uint256 b = add(div(a, 2), 1);
      while (b < c) {
        c = b;
        b = div(add(div(a, b), b), 2);
      }
    } else if (a != 0) {
      c = 1;
    }
  }

  function percentageAmount(
    uint256 total_,
    uint8 percentage_
  ) internal pure returns (uint256 percentAmount_) {
    return div(mul(total_, percentage_), 1000);
  }

  function substractPercentage(
    uint256 total_,
    uint8 percentageToSub_
  ) internal pure returns (uint256 result_) {
    return sub(total_, div(mul(total_, percentageToSub_), 1000));
  }

  function percentageOfTotal(
    uint256 part_,
    uint256 total_
  ) internal pure returns (uint256 percent_) {
    return div(mul(part_, 100), total_);
  }

  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b) / 2 can overflow, so we distribute
    return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
  }

  function quadraticPricing(
    uint256 payment_,
    uint256 multiplier_
  ) internal pure returns (uint256) {
    return sqrrt(mul(multiplier_, payment_));
  }

  function bondingCurve(
    uint256 supply_,
    uint256 multiplier_
  ) internal pure returns (uint256) {
    return mul(multiplier_, supply_);
  }
}

library Address {
  function isContract(address account) internal view returns (bool) {
    // This method relies in extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    uint256 size;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}("");
    require(
      success,
      "Address: unable to send value, recipient may have reverted"
    );
  }

  function functionCall(
    address target,
    bytes memory data
  ) internal returns (bytes memory) {
    return functionCall(target, data, "Address: low-level call failed");
  }

  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return _functionCallWithValue(target, data, 0, errorMessage);
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
        "Address: low-level call with value failed"
      );
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(
      address(this).balance >= value,
      "Address: insufficient balance for call"
    );
    require(isContract(target), "Address: call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function _functionCallWithValue(
    address target,
    bytes memory data,
    uint256 weiValue,
    string memory errorMessage
  ) private returns (bytes memory) {
    require(isContract(target), "Address: call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{value: weiValue}(
      data
    );
    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly

        // solhint-disable-next-line no-inline-assembly
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }

  function functionStaticCall(
    address target,
    bytes memory data
  ) internal view returns (bytes memory) {
    return
      functionStaticCall(target, data, "Address: low-level static call failed");
  }

  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    require(isContract(target), "Address: static call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.staticcall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function functionDelegateCall(
    address target,
    bytes memory data
  ) internal returns (bytes memory) {
    return
      functionDelegateCall(
        target,
        data,
        "Address: low-level delegate call failed"
      );
  }

  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), "Address: delegate call to non-contract");
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function _verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) private pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      if (returndata.length > 0) {
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }

  function addressToString(
    address _address
  ) internal pure returns (string memory) {
    bytes32 _bytes = bytes32(uint256(_address));
    bytes memory HEX = "0123456789abcdef";
    bytes memory _addr = new bytes(42);

    _addr[0] = "0";
    _addr[1] = "x";

    for (uint256 i = 0; i < 20; i++) {
      _addr[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
      _addr[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
    }

    return string(_addr);
  }
}

abstract contract ERC20 is IERC20 {
  using SafeMath for uint256;

  // TODO comment actual hash value.
  bytes32 private constant ERC20TOKEN_ERC1820_INTERFACE_ID =
    keccak256("ERC20Token");

  // Present in ERC777
  mapping(address => uint256) internal _balances;

  // Present in ERC777
  mapping(address => mapping(address => uint256)) internal _allowances;

  // Present in ERC777
  uint256 internal _totalSupply;

  // Present in ERC777
  string internal _name;

  // Present in ERC777
  string internal _symbol;

  // Present in ERC777
  uint8 internal _decimals;

  constructor(string memory name_, string memory symbol_, uint8 decimals_) {
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function decimals() public view returns (uint8) {
    return _decimals;
  }

  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(
    address account
  ) public view virtual override returns (uint256) {
    return _balances[account];
  }

  function transfer(
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  function allowance(
    address owner,
    address spender
  ) public view virtual override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(
    address spender,
    uint256 amount
  ) public virtual override returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      msg.sender,
      _allowances[sender][msg.sender].sub(
        amount,
        "ERC20: transfer amount exceeds allowance"
      )
    );
    return true;
  }

  function increaseAllowance(
    address spender,
    uint256 addedValue
  ) public virtual returns (bool) {
    _approve(
      msg.sender,
      spender,
      _allowances[msg.sender][spender].add(addedValue)
    );
    return true;
  }

  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  ) public virtual returns (bool) {
    _approve(
      msg.sender,
      spender,
      _allowances[msg.sender][spender].sub(
        subtractedValue,
        "ERC20: decreased allowance below zero"
      )
    );
    return true;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender].sub(
      amount,
      "ERC20: transfer amount exceeds balance"
    );
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _mint(address account_, uint256 amount_) internal virtual {
    require(account_ != address(0), "ERC20: mint to the zero address");
    _beforeTokenTransfer(address(this), account_, amount_);
    _totalSupply = _totalSupply.add(amount_);
    _balances[account_] = _balances[account_].add(amount_);
    emit Transfer(address(this), account_, amount_);
  }

  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    _balances[account] = _balances[account].sub(
      amount,
      "ERC20: burn amount exceeds balance"
    );
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

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

  function _beforeTokenTransfer(
    address from_,
    address to_,
    uint256 amount_
  ) internal virtual {}

  function _spendAllowance(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    uint256 currentAllowance = allowance(owner, spender);
    if (currentAllowance != type(uint256).max) {
      require(currentAllowance >= amount, "ERC20: insufficient allowance");
      _approve(owner, spender, currentAllowance - amount);
    }
  }
}

library Counters {
  using SafeMath for uint256;

  struct Counter {
    uint256 _value; // default: 0
  }

  function current(Counter storage counter) internal view returns (uint256) {
    return counter._value;
  }

  function increment(Counter storage counter) internal {
    counter._value += 1;
  }

  function decrement(Counter storage counter) internal {
    counter._value = counter._value.sub(1);
  }
}

interface IERC2612Permit {
  function permit(
    address owner,
    address spender,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function nonces(address owner) external view returns (uint256);
}

abstract contract ERC20Permit is ERC20, IERC2612Permit {
  using Counters for Counters.Counter;

  mapping(address => Counters.Counter) private _nonces;

  // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes32 public constant PERMIT_TYPEHASH =
    0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

  bytes32 public DOMAIN_SEPARATOR;

  constructor() {
    uint256 chainID;
    assembly {
      chainID := chainid()
    }

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256(
          "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        ),
        keccak256(bytes(name())),
        keccak256(bytes("1")), // Version
        chainID,
        address(this)
      )
    );
  }

  function permit(
    address owner,
    address spender,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public virtual override {
    require(block.timestamp <= deadline, "Permit: expired deadline");

    bytes32 hashStruct = keccak256(
      abi.encode(
        PERMIT_TYPEHASH,
        owner,
        spender,
        amount,
        _nonces[owner].current(),
        deadline
      )
    );

    bytes32 _hash = keccak256(
      abi.encodePacked(uint16(0x1901), DOMAIN_SEPARATOR, hashStruct)
    );

    address signer = ecrecover(_hash, v, r, s);
    require(
      signer != address(0) && signer == owner,
      "ZeroSwapPermit: Invalid signature"
    );

    _nonces[owner].increment();
    _approve(owner, spender, amount);
  }

  function nonces(address owner) public view override returns (uint256) {
    return _nonces[owner].current();
  }
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

interface IOwnable {
  function owner() external view returns (address);

  function renounceOwnership() external;

  function transferOwnership(address newOwner_) external;
}

contract Ownable is IOwnable, Context {
  address internal _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  function owner() public view override returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public virtual override onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(
    address newOwner_
  ) public virtual override onlyOwner {
    require(newOwner_ != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner_);
    _owner = newOwner_;
  }
}

contract VaultOwned is Ownable {
  address internal _vault;

  function setVault(address vault_) external onlyOwner returns (bool) {
    _vault = vault_;

    return true;
  }

  function vault() public view returns (address) {
    return _vault;
  }

  modifier onlyVault() {
    require(_vault == msg.sender, "VaultOwned: caller is not the Vault");
    _;
  }
}

interface IWETH is IERC20 {
  function deposit() external payable;

  function withdraw(uint256) external;
}

contract OlympusERC20Token is ERC20Permit, VaultOwned {
  using SafeMath for uint256;

  using Address for address payable;

  uint256 public maxTxAmount;
  uint256 public maxWallet;
  bool public swapEnabled = true;

  bool public inSwap;
  modifier swapping() {
    inSwap = true;
    _;
    inSwap = false;
  }

  mapping(address => bool) public isFeeExempt;
  mapping(address => bool) public isTxLimitExempt;
  mapping(address => bool) public canAddLiquidityBeforeLaunch;

  uint256 private jackpotFee;
  uint256 private marketingFee;
  uint256 private devFee;
  uint256 private totalFee;
  uint256 public feeDenominator = 10000;

  // Buy Fees
  uint256 public jackpotFeeBuy = 300;
  uint256 public marketingFeeBuy = 200;
  uint256 public devFeeBuy = 200;
  uint256 public totalFeeBuy = 700;
  // Sell Fees
  uint256 public jackpotFeeSell = 300;
  uint256 public marketingFeeSell = 200;
  uint256 public devFeeSell = 200;
  uint256 public totalFeeSell = 700;

  // Fees receivers
  address payable private marketingWallet;
  address payable public jackpotWallet;
  address payable private devWallet;

  uint256 public launchedAt;
  uint256 public launchedAtTimestamp;
  bool private initialized;

  ICamelotFactory private factory =
    ICamelotFactory(0x6EcCab422D763aC031210895C81787E87B43A652);
  ICamelotRouter private swapRouter =
    ICamelotRouter(0xc873fEcbd354f5A56E00E710B90EF4201db2448d);
  IWETH private WETH = IWETH(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
  address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
  address private constant ZERO = 0x0000000000000000000000000000000000000000;

  address public pair;
  address public stakeAddress;
  address public treasuryAddress;
  address public stakeHelperAddress;
  address[] noMaxWallet;

  constructor(
    address _marketingWallet,
    address _jackpotWallet,
    address _devWallet
  ) ERC20("SHIELD", "SHIELD", 9) {
    _totalSupply = 4000 * 1e9;
    maxTxAmount = (_totalSupply * 2) / 100; //2%
    maxWallet = (_totalSupply * 2) / 100; //2%
    marketingWallet = payable(_marketingWallet);
    jackpotWallet = payable(_jackpotWallet);
    devWallet = payable(_devWallet);
    canAddLiquidityBeforeLaunch[_msgSender()] = true;
    canAddLiquidityBeforeLaunch[address(this)] = true;
    isFeeExempt[msg.sender] = true;
    isTxLimitExempt[msg.sender] = true;
    isFeeExempt[address(this)] = true;
    isTxLimitExempt[address(this)] = true;
    stakeAddress = DEAD;
    _mint(_msgSender(), _totalSupply);
  }

  function launch() public onlyOwner {
    require(launchedAt == 0, "Already launched");
    launchedAt = block.number;
    launchedAtTimestamp = block.timestamp;
  }

  function initializePair() public onlyOwner {
    require(!initialized, "Already initialized");
    pair = factory.createPair(address(WETH), address(this));
    initialized = true;
  }

  function mint(address account_, uint256 amount_) external onlyVault {
    _mint(account_, amount_);
  }

  function burn(uint256 amount) public virtual {
    _burn(msg.sender, amount);
  }

  function burnFrom(address account_, uint256 amount_) public virtual {
    _burnFrom(account_, amount_);
  }

  function _burnFrom(address account_, uint256 amount_) public virtual {
    uint256 decreasedAllowance_ = allowance(account_, msg.sender).sub(
      amount_,
      "ERC20: burn amount exceeds allowance"
    );

    _approve(account_, msg.sender, decreasedAllowance_);
    _burn(account_, amount_);
  }

  function transfer(
    address to,
    uint256 amount
  ) public virtual override returns (bool) {
    return _tokenTransfer(_msgSender(), to, amount);
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    address spender = _msgSender();
    _spendAllowance(sender, spender, amount);
    return _tokenTransfer(sender, recipient, amount);
  }

  function _tokenTransfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal returns (bool) {
    if (inSwap) {
      _transfer(sender, recipient, amount);
      return true;
    }
    if (!canAddLiquidityBeforeLaunch[sender]) {
      require(launched(), "Trading not open yet");
    }
    checkWalletLimit(recipient, amount);
    checkTxLimit(sender, amount);

    bool isPair = false;

    if (sender == pair) {
      isPair = true;
      buyFees();
    }
    if (recipient == pair) {
      isPair = true;
      sellFees();
    }
    if (shouldSwapBack(isPair, recipient)) {
      swapBack();
    }
    uint256 amountReceived = shouldTakeFee(isPair, sender, recipient)
      ? takeFee(sender, amount)
      : amount;
    _transfer(sender, recipient, amountReceived);
    return true;
  }

  function shouldSwapBack(
    bool isPair,
    address recipient
  ) internal view returns (bool) {
    return
      isPair &&
      !inSwap &&
      swapEnabled &&
      launched() &&
      balanceOf(address(this)) > 0 &&
      _msgSender() != pair &&
      recipient != stakeAddress;
  }

  function shouldTakeFee(
    bool isPair,
    address sender,
    address recipient
  ) internal view returns (bool) {
    return
      isPair && !isFeeExempt[sender] && launched() && recipient != stakeAddress;
  }

  function swapBack() internal swapping {
    uint256 taxAmount = balanceOf(address(this));
    _approve(address(this), address(swapRouter), taxAmount);

    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = address(WETH);

    uint256 balanceBefore = address(this).balance;

    swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
      taxAmount,
      0,
      path,
      address(this),
      ZERO,
      block.timestamp
    );

    uint256 amountETH = address(this).balance - balanceBefore;

    uint256 amountETHJackpot = (amountETH * jackpotFee) / totalFee;
    uint256 amountETHMarketing = (amountETH * marketingFee) / totalFee;
    uint256 amountETHDevOne = (amountETH * devFee) / totalFee;
    jackpotWallet.sendValue(amountETHJackpot);
    marketingWallet.sendValue(amountETHMarketing);
    devWallet.sendValue(amountETHDevOne);
  }

  function launched() internal view returns (bool) {
    return launchedAt != 0;
  }

  function buyFees() internal {
    jackpotFee = jackpotFeeBuy;
    marketingFee = marketingFeeBuy;
    devFee = devFeeBuy;
    totalFee = totalFeeBuy;
  }

  function sellFees() internal {
    jackpotFee = jackpotFeeSell;
    marketingFee = marketingFeeSell;
    devFee = devFeeSell;
    totalFee = totalFeeSell;
  }

  function takeFee(address sender, uint256 amount) internal returns (uint256) {
    uint256 feeAmount = (amount * totalFee) / feeDenominator;
    _transfer(sender, address(this), feeAmount);
    return amount - feeAmount;
  }

  function checkWalletLimit(address recipient, uint256 amount) internal view {
    if (
      recipient != owner() &&
      recipient != address(this) &&
      recipient != address(DEAD) &&
      recipient != pair &&
      recipient != stakeAddress &&
      recipient != treasuryAddress &&
      !isAddressInArray(recipient, noMaxWallet)
    ) {
      uint256 heldTokens = balanceOf(recipient);
      require(
        (heldTokens + amount) <= maxWallet,
        "Total Holding is currently limited, you can not buy that much."
      );
    }
  }

  function checkTxLimit(address sender, uint256 amount) internal view {
    require(
      amount <= maxTxAmount || isTxLimitExempt[sender],
      "TX Limit Exceeded"
    );
  }

  // Stuck Balances Functions
  function rescueToken(address tokenAddress) external onlyOwner {
    IERC20(tokenAddress).transferFrom(
      address(this),
      msg.sender,
      IERC20(tokenAddress).balanceOf(address(this))
    );
  }

  function clearStuckBalance() external onlyOwner {
    uint256 amountETH = address(this).balance;
    payable(_msgSender()).sendValue(amountETH);
  }

  function setBuyFees(
    uint256 _jackpotFee,
    uint256 _marketingFee,
    uint256 _devFee
  ) external onlyOwner {
    jackpotFeeBuy = _jackpotFee;
    marketingFeeBuy = _marketingFee;
    devFeeBuy = _devFee;
    totalFeeBuy = (_jackpotFee) + (_marketingFee) + (_devFee);
  }

  function setSellFees(
    uint256 _jackpotFee,
    uint256 _marketingFee,
    uint256 _devFee
  ) external onlyOwner {
    jackpotFeeSell = _jackpotFee;
    marketingFeeSell = _marketingFee;
    devFeeSell = _devFee;
    totalFeeSell = (_jackpotFee) + (_marketingFee) + (_devFee);
  }

  function setFeeReceivers(
    address _marketingWallet,
    address _jackpotWallet,
    address _devWallet
  ) external onlyOwner {
    marketingWallet = payable(_marketingWallet);
    jackpotWallet = payable(_jackpotWallet);
    devWallet = payable(_devWallet);
  }

  function setMaxWallet(uint256 amount) external onlyOwner {
    require(amount >= totalSupply() / 100);
    maxWallet = amount;
  }

  function setTxLimit(uint256 amount) external onlyOwner {
    require(amount >= totalSupply() / 100);
    maxTxAmount = amount;
  }

  function setLimits(uint256 amount) public onlyOwner {
    maxTxAmount = (totalSupply() * amount) / 100;
    maxWallet = (totalSupply() * amount) / 100;
  }

  function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
    isFeeExempt[holder] = exempt;
  }

  function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
    isTxLimitExempt[holder] = exempt;
  }

  function setSwapBackSettings(bool _enabled) external onlyOwner {
    swapEnabled = _enabled;
  }

  function setStakeAddress(address _stakeAddress) external onlyOwner {
    stakeAddress = _stakeAddress;
  }

  function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
    treasuryAddress = _treasuryAddress;
  }

  function addNoMaxWallet(address wallet) external onlyOwner {
    require(wallet != address(0), "Invalid wallet address");
    noMaxWallet.push(wallet);
  }

  function isAddressInArray(
    address addr,
    address[] memory arr
  ) internal pure returns (bool) {
    for (uint256 i = 0; i < arr.length; i++) {
      if (addr == arr[i]) {
        return true;
      }
    }
    return false;
  }

  receive() external payable {}
}

pragma solidity 0.7.5;

interface ICamelotRouter {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    address referrer,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    address referrer,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    address referrer,
    uint256 deadline
  ) external;
}

pragma solidity 0.7.5;

interface ICamelotPair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(
    address indexed sender,
    uint256 amount0,
    uint256 amount1,
    address indexed to
  );
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint16 token0feePercent,
      uint16 token1FeePercent
    );

  function getAmountOut(uint256 amountIn, address tokenIn)
    external
    view
    returns (uint256);

  function kLast() external view returns (uint256);

  function setFeePercent(uint16 token0FeePercent, uint16 token1FeePercent)
    external;

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data,
    address referrer
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

pragma solidity 0.7.5;

interface ICamelotFactory {
  event PairCreated(
    address indexed token0,
    address indexed token1,
    address pair,
    uint256
  );

  function owner() external view returns (address);

  function feePercentOwner() external view returns (address);

  function setStableOwner() external view returns (address);

  function feeTo() external view returns (address);

  function ownerFeeShare() external view returns (uint256);

  function referrersFeeShare(address) external view returns (uint256);

  function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function allPairsLength() external view returns (uint256);

  function createPair(address tokenA, address tokenB)
    external
    returns (address pair);

  function setFeeTo(address) external;

  function feeInfo()
    external
    view
    returns (uint256 _ownerFeeShare, address _feeTo);
}