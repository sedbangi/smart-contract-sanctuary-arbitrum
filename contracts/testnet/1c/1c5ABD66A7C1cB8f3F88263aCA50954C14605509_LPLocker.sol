/**
 *Submitted for verification at Arbiscan on 2023-07-12
*/

pragma solidity 0.6.12;





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
 * ```
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
 */
library EnumerableSet {









    struct Set {

        bytes32[] _values;



        mapping (bytes32 => uint256) _indexes;
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

        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)




            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;




            bytes32 lastvalue = set._values[lastIndex];


            set._values[toDeleteIndex] = lastvalue;

            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based


            set._values.pop();


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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}





/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {



        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}









/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}





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











    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {

        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");


        _status = _ENTERED;

        _;



        _status = _NOT_ENTERED;
    }
}





library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

}



interface IERCBurn {
    function burn(uint256 _amount) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}



interface IFactory {
    function getPair(address tokenA, address tokenB) external view returns (address);
}



interface IPair {
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
}


interface IMigrator {
    function migrate(address lpToken, uint256 amount, uint256 unlockDate, address owner) external returns (bool);
}


contract LPLocker is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    IFactory public _factory;

    struct UserInfo {
        EnumerableSet.AddressSet lockedTokens; // records all tokens the user has locked
        mapping(address => uint256[]) locksForToken; // map erc20 address to lock id for that token
    }

    struct TokenLock {
        uint256 lockDate; // the date the token was locked
        uint256 amount; // the amount of tokens still locked (initialAmount minus withdrawls)
        uint256 initialAmount; // the initial lock amount
        uint256 unlockDate; // the date the token can be withdrawn
        uint256 lockID; // lockID nonce per  pair
        address owner;
    }

    mapping(address => UserInfo) private users;

    EnumerableSet.AddressSet private lockedTokens;
    mapping(address => TokenLock[]) public tokenLocks; //map pair to all its locks

    struct FeeStruct {
        uint256 ethFee; // Small eth fee to prevent spam on the platform
        IERCBurn secondaryFeeToken;
        uint256 secondaryTokenFee; // optional
        uint256 secondaryTokenDiscount; // discount on liquidity fee for burning secondaryToken
        uint256 liquidityFee; // fee on liquidity tokens
        uint256 referralPercent; // fee for referrals
        IERCBurn referralToken; // token the referrer must hold to qualify as a referrer
        uint256 referralHold; // balance the referrer must hold to qualify as a referrer
        uint256 referralDiscount; // discount on flat rate fees for using a valid referral address
    }

    FeeStruct public gFees;
    EnumerableSet.AddressSet private feeWhitelist;

    address payable devaddr;

    IMigrator migrator;

    event onDeposit(address lpToken, address user, uint256 amount, uint256 lockDate, uint256 unlockDate);
    event onWithdraw(address lpToken, uint256 amount);

    constructor(IFactory factory) public {
        devaddr = msg.sender;
        gFees.referralPercent = 250; // 25%
        gFees.ethFee = 1e18;
        gFees.secondaryTokenFee = 100e18;
        gFees.secondaryTokenDiscount = 200; // 20%
        gFees.liquidityFee = 10; // 1%
        gFees.referralHold = 10e18;
        gFees.referralDiscount = 100; // 10%
        _factory = factory;
    }

    function setDev(address payable _devaddr) public onlyOwner {
        devaddr = _devaddr;
    }

    /**
     * @notice set the migrator contract which allows locked lp tokens to be migrated
   */
    function setMigrator(IMigrator _migrator) public onlyOwner {
        migrator = _migrator;
    }

    function setSecondaryFeeToken(address _secondaryFeeToken) public onlyOwner {
        gFees.secondaryFeeToken = IERCBurn(_secondaryFeeToken);
    }

    /**
     * @notice referrers need to hold the specified token and hold amount to be elegible for referral fees
   */
    function setReferralTokenAndHold(IERCBurn _referralToken, uint256 _hold) public onlyOwner {
        gFees.referralToken = _referralToken;
        gFees.referralHold = _hold;
    }

    function setFees(uint256 _referralPercent, uint256 _referralDiscount, uint256 _ethFee, uint256 _secondaryTokenFee, uint256 _secondaryTokenDiscount, uint256 _liquidityFee) public onlyOwner {
        gFees.referralPercent = _referralPercent;
        gFees.referralDiscount = _referralDiscount;
        gFees.ethFee = _ethFee;
        gFees.secondaryTokenFee = _secondaryTokenFee;
        gFees.secondaryTokenDiscount = _secondaryTokenDiscount;
        gFees.liquidityFee = _liquidityFee;
    }

    /**
     * @notice whitelisted accounts dont pay flatrate fees on locking
   */
    function whitelistFeeAccount(address _user, bool _add) public onlyOwner {
        if (_add) {
            feeWhitelist.add(_user);
        } else {
            feeWhitelist.remove(_user);
        }
    }

    /**
     * @notice Creates a new lock
   * @param _lpToken the token address
   * @param _amount amount of LP tokens to lock
   * @param _unlock_date the timestamp (in seconds) until unlock
   * @param _referral the referrer address if any or address(0) for none
   * @param _fee_in_eth fees can be paid in eth or in a secondary token such as UNCX with a discount on tokens
   * @param _withdrawer the user who can withdraw liquidity once the lock expires.
   */
    function lockLPToken (address _lpToken, uint256 _amount, uint256 _unlock_date, address payable _referral, bool _fee_in_eth, address payable _withdrawer) external payable nonReentrant {
        require(_unlock_date < 10000000000, 'TIMESTAMP INVALID'); // prevents errors when timestamp entered in milliseconds
        require(_amount > 0, 'INSUFFICIENT');

        // ensure this pair is a pair by querying the factory
        IPair lpair = IPair(address(_lpToken));
        address factoryPairAddress = _factory.getPair(lpair.token0(), lpair.token1());
        require(factoryPairAddress == address(_lpToken), 'NOT LP');

        TransferHelper.safeTransferFrom(_lpToken, address(msg.sender), address(this), _amount);

        if (_referral != address(0) && address(gFees.referralToken) != address(0)) {
            require(gFees.referralToken.balanceOf(_referral) >= gFees.referralHold, 'INADEQUATE BALANCE');
        }

        // flatrate fees
        if (!feeWhitelist.contains(msg.sender)) {
            if (_fee_in_eth) { // charge fee in eth
                uint256 ethFee = gFees.ethFee;
                if (_referral != address(0)) {
                    ethFee = ethFee.mul(1000 - gFees.referralDiscount).div(1000);
                }
                require(msg.value == ethFee, 'FEE NOT MET');
                uint256 devFee = ethFee;
                if (ethFee != 0 && _referral != address(0)) { // referral fee
                    uint256 referralFee = devFee.mul(gFees.referralPercent).div(1000);
                    _referral.transfer(referralFee);
                    devFee = devFee.sub(referralFee);
                }
                devaddr.transfer(devFee);
            } else { // charge fee in token
                uint256 burnFee = gFees.secondaryTokenFee;
                if (_referral != address(0)) {
                    burnFee = burnFee.mul(1000 - gFees.referralDiscount).div(1000);
                }
                TransferHelper.safeTransferFrom(address(gFees.secondaryFeeToken), address(msg.sender), address(this), burnFee);
                if (gFees.referralPercent != 0 && _referral != address(0)) { // referral fee
                    uint256 referralFee = burnFee.mul(gFees.referralPercent).div(1000);
                    TransferHelper.safeApprove(address(gFees.secondaryFeeToken), _referral, referralFee);
                    TransferHelper.safeTransfer(address(gFees.secondaryFeeToken), _referral, referralFee);
                    burnFee = burnFee.sub(referralFee);
                }
                gFees.secondaryFeeToken.burn(burnFee);
            }
        } else if (msg.value > 0){
            // refund eth if a whitelisted member sent it by mistake
            msg.sender.transfer(msg.value);
        }

        // percent fee
        uint256 liquidityFee = _amount.mul(gFees.liquidityFee).div(1000);
        if (!_fee_in_eth && !feeWhitelist.contains(msg.sender)) { // fee discount for large lockers using secondary token
            liquidityFee = liquidityFee.mul(1000 - gFees.secondaryTokenDiscount).div(1000);
        }
        TransferHelper.safeTransfer(_lpToken, devaddr, liquidityFee);
        uint256 amountLocked = _amount.sub(liquidityFee);

        TokenLock memory token_lock;
        token_lock.lockDate = block.timestamp;
        token_lock.amount = amountLocked;
        token_lock.initialAmount = amountLocked;
        token_lock.unlockDate = _unlock_date;
        token_lock.lockID = tokenLocks[_lpToken].length;
        token_lock.owner = _withdrawer;

        // record the lock for the pair
        tokenLocks[_lpToken].push(token_lock);
        lockedTokens.add(_lpToken);

        // record the lock for the user
        UserInfo storage user = users[_withdrawer];
        user.lockedTokens.add(_lpToken);
        uint256[] storage user_locks = user.locksForToken[_lpToken];
        user_locks.push(token_lock.lockID);

        emit onDeposit(_lpToken, msg.sender, token_lock.amount, token_lock.lockDate, token_lock.unlockDate);
    }

    /**
     * @notice extend a lock with a new unlock date, _index and _lockID ensure the correct lock is changed
   * this prevents errors when a user performs multiple tx per block possibly with varying gas prices
   */
    function relock (address _lpToken, uint256 _index, uint256 _lockID, uint256 _unlock_date) external nonReentrant {
        require(_unlock_date < 10000000000, 'TIMESTAMP INVALID'); // prevents errors when timestamp entered in milliseconds
        uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
        TokenLock storage userLock = tokenLocks[_lpToken][lockID];
        require(lockID == _lockID && userLock.owner == msg.sender, 'LOCK MISMATCH'); // ensures correct lock is affected
        require(userLock.unlockDate < _unlock_date, 'UNLOCK BEFORE');

        uint256 liquidityFee = userLock.amount.mul(gFees.liquidityFee).div(1000);
        uint256 amountLocked = userLock.amount.sub(liquidityFee);

        userLock.amount = amountLocked;
        userLock.unlockDate = _unlock_date;

        // send pair fee to dev address
        TransferHelper.safeTransfer(_lpToken, devaddr, liquidityFee);
    }

    /**
     * @notice withdraw a specified amount from a lock. _index and _lockID ensure the correct lock is changed
   * this prevents errors when a user performs multiple tx per block possibly with varying gas prices
   */
    function withdraw (address _lpToken, uint256 _index, uint256 _lockID, uint256 _amount) external nonReentrant {
        require(_amount > 0, 'ZERO WITHDRAWL');
        uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
        TokenLock storage userLock = tokenLocks[_lpToken][lockID];
        require(lockID == _lockID && userLock.owner == msg.sender, 'LOCK MISMATCH'); // ensures correct lock is affected
        require(userLock.unlockDate < block.timestamp, 'NOT YET');
        userLock.amount = userLock.amount.sub(_amount);

        // clean user storage
        if (userLock.amount == 0) {
            uint256[] storage userLocks = users[msg.sender].locksForToken[_lpToken];
            userLocks[_index] = userLocks[userLocks.length-1];
            userLocks.pop();
            if (userLocks.length == 0) {
                users[msg.sender].lockedTokens.remove(_lpToken);
            }
        }

        TransferHelper.safeTransfer(_lpToken, msg.sender, _amount);
        emit onWithdraw(_lpToken, _amount);
    }

    /**
     * @notice increase the amount of tokens per a specific lock, this is preferable to creating a new lock, less fees, and faster loading on our live block explorer
   */
    function incrementLock (address _lpToken, uint256 _index, uint256 _lockID, uint256 _amount) external nonReentrant {
        require(_amount > 0, 'ZERO AMOUNT');
        uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
        TokenLock storage userLock = tokenLocks[_lpToken][lockID];
        require(lockID == _lockID && userLock.owner == msg.sender, 'LOCK MISMATCH'); // ensures correct lock is affected

        TransferHelper.safeTransferFrom(_lpToken, address(msg.sender), address(this), _amount);

        // send pair fee to dev address
        uint256 liquidityFee = _amount.mul(gFees.liquidityFee).div(1000);
        TransferHelper.safeTransfer(_lpToken, devaddr, liquidityFee);
        uint256 amountLocked = _amount.sub(liquidityFee);

        userLock.amount = userLock.amount.add(amountLocked);

        emit onDeposit(_lpToken, msg.sender, amountLocked, userLock.lockDate, userLock.unlockDate);
    }

    /**
     * @notice split a lock into two seperate locks, useful when a lock is about to expire and youd like to relock a portion
   * and withdraw a smaller portion
   */
    function splitLock (address _lpToken, uint256 _index, uint256 _lockID, uint256 _amount) external payable nonReentrant {
        require(_amount > 0, 'ZERO AMOUNT');
        uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
        TokenLock storage userLock = tokenLocks[_lpToken][lockID];
        require(lockID == _lockID && userLock.owner == msg.sender, 'LOCK MISMATCH'); // ensures correct lock is affected

        require(msg.value == gFees.ethFee, 'FEE NOT MET');
        devaddr.transfer(gFees.ethFee);

        userLock.amount = userLock.amount.sub(_amount);

        TokenLock memory token_lock;
        token_lock.lockDate = userLock.lockDate;
        token_lock.amount = _amount;
        token_lock.initialAmount = _amount;
        token_lock.unlockDate = userLock.unlockDate;
        token_lock.lockID = tokenLocks[_lpToken].length;
        token_lock.owner = msg.sender;

        // record the lock for the pair
        tokenLocks[_lpToken].push(token_lock);

        // record the lock for the user
        UserInfo storage user = users[msg.sender];
        uint256[] storage user_locks = user.locksForToken[_lpToken];
        user_locks.push(token_lock.lockID);
    }

    /**
     * @notice transfer a lock to a new owner, e.g. presale project -> project owner
   */
    function transferLockOwnership (address _lpToken, uint256 _index, uint256 _lockID, address payable _newOwner) external {
        require(msg.sender != _newOwner, 'OWNER');
        uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
        TokenLock storage transferredLock = tokenLocks[_lpToken][lockID];
        require(lockID == _lockID && transferredLock.owner == msg.sender, 'LOCK MISMATCH'); // ensures correct lock is affected

        // record the lock for the new Owner
        UserInfo storage user = users[_newOwner];
        user.lockedTokens.add(_lpToken);
        uint256[] storage user_locks = user.locksForToken[_lpToken];
        user_locks.push(transferredLock.lockID);

        // remove the lock from the old owner
        uint256[] storage userLocks = users[msg.sender].locksForToken[_lpToken];
        userLocks[_index] = userLocks[userLocks.length-1];
        userLocks.pop();
        if (userLocks.length == 0) {
            users[msg.sender].lockedTokens.remove(_lpToken);
        }
        transferredLock.owner = _newOwner;
    }

    /**
     * @notice migrates liquidity to new version
   */
    function migrate (address _lpToken, uint256 _index, uint256 _lockID, uint256 _amount) external nonReentrant {
        require(address(migrator) != address(0), "NOT SET");
        require(_amount > 0, 'ZERO MIGRATION');

        uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
        TokenLock storage userLock = tokenLocks[_lpToken][lockID];
        require(lockID == _lockID && userLock.owner == msg.sender, 'LOCK MISMATCH'); // ensures correct lock is affected
        userLock.amount = userLock.amount.sub(_amount);

        // clean user storage
        if (userLock.amount == 0) {
            uint256[] storage userLocks = users[msg.sender].locksForToken[_lpToken];
            userLocks[_index] = userLocks[userLocks.length-1];
            userLocks.pop();
            if (userLocks.length == 0) {
                users[msg.sender].lockedTokens.remove(_lpToken);
            }
        }

        TransferHelper.safeApprove(_lpToken, address(migrator), _amount);
        migrator.migrate(_lpToken, _amount, userLock.unlockDate, msg.sender);
    }

    function getNumLocksForToken (address _lpToken) external view returns (uint256) {
        return tokenLocks[_lpToken].length;
    }

    function getNumLockedTokens () external view returns (uint256) {
        return lockedTokens.length();
    }

    function getLockedTokenAtIndex (uint256 _index) external view returns (address) {
        return lockedTokens.at(_index);
    }

    // user functions
    function getUserNumLockedTokens (address _user) external view returns (uint256) {
        UserInfo storage user = users[_user];
        return user.lockedTokens.length();
    }

    function getUserLockedTokenAtIndex (address _user, uint256 _index) external view returns (address) {
        UserInfo storage user = users[_user];
        return user.lockedTokens.at(_index);
    }

    function getUserNumLocksForToken (address _user, address _lpToken) external view returns (uint256) {
        UserInfo storage user = users[_user];
        return user.locksForToken[_lpToken].length;
    }

    function getUserLockForTokenAtIndex (address _user, address _lpToken, uint256 _index) external view
    returns (uint256, uint256, uint256, uint256, uint256, address) {
        uint256 lockID = users[_user].locksForToken[_lpToken][_index];
        TokenLock storage tokenLock = tokenLocks[_lpToken][lockID];
        return (tokenLock.lockDate, tokenLock.amount, tokenLock.initialAmount, tokenLock.unlockDate, tokenLock.lockID, tokenLock.owner);
    }

    // whitelist
    function getWhitelistedUsersLength () external view returns (uint256) {
        return feeWhitelist.length();
    }

    function getWhitelistedUserAtIndex (uint256 _index) external view returns (address) {
        return feeWhitelist.at(_index);
    }

    function getUserWhitelistStatus (address _user) external view returns (bool) {
        return feeWhitelist.contains(_user);
    }
}