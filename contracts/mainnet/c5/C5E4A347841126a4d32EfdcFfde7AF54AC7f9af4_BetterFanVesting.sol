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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract BetterFanVesting is Ownable, Pausable {
    uint256 public totalLocked;
    uint256 public totalReleased;
    uint256 public totalUsers;

    // Struct to store vesting information
    struct VestingInfo {
        uint256 percentage;
        uint256 claimTime;
    }

    // Admin management
    mapping(address => bool) public admin;

    // Whitelist management
    mapping(address => bool) public whitelist;

    // Vesting information
    VestingInfo[] private vestings;

    mapping(address => uint256) private locked;
    mapping(address => uint256) private released;

    // Token IDO (to be distributed after IDO ends)
    IERC20 public idoToken;

    // Events
    event WhitelisterAdded(address indexed user, uint256 amount);
    event Claimed(
        address indexed account,
        uint256 amount,
        uint256 time,
        address paymentCurrency
    );
    event VestingCreatedOrUpdated(VestingInfo[] vestings);

    modifier onlyAdmin() {
        require(admin[_msgSender()], "You are not an admin");
        _;
    }

    constructor() {
        admin[_msgSender()] = true;
    }

    function setAdmin(
        address[] calldata users,
        bool remove
    ) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            admin[users[i]] = !remove;
        }
    }

    function setAllocations(
        address[] calldata users,
        uint256[] calldata amounts
    ) external onlyAdmin {
        require(users.length > 0, "Wrong parameters");
        require(users.length == amounts.length, "Wrong parameters");

        for (uint16 i = 0; i < users.length; i++) {
            if (locked[users[i]] == 0) {
                totalUsers += 1;
            }

            totalLocked = totalLocked - locked[users[i]] + amounts[i];
            locked[users[i]] = amounts[i];

            whitelist[users[i]] = true;

            emit WhitelisterAdded(users[i], amounts[i]);
        }
    }

    function initData(
        address[] calldata users,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(users.length > 0, "Wrong parameters");
        require(users.length == amounts.length, "Wrong parameters");

        for (uint16 i = 0; i < users.length; i++) {
            totalReleased = totalReleased + amounts[i];
            released[users[i]] = amounts[i];
        }
    }

    function createOrUpdateVestingInfo(
        VestingInfo[] memory _vestings
    ) external onlyAdmin {
        require(_vestings.length > 0, "Vesting array cannot be empty");
        // if (vestings.length > 0 && vestings[0].claimTime <= block.timestamp) {
        //     revert("Can not update Vesting info");
        // }

        uint256 checkPercents = 0;

        for (uint256 i = 0; i < _vestings.length; i++) {
            require(
                _vestings[i].percentage <= 10000,
                "Percentage must be less than 10000"
            );
            // require(
            //     _vestings[i].claimTime > block.timestamp,
            //     "Claim time must be in the future"
            // );

            if (i != _vestings.length - 1) {
                require(
                    _vestings[i].claimTime < _vestings[i + 1].claimTime,
                    "Claim time must be in ascending order"
                );
            }
            checkPercents += _vestings[i].percentage;
        }
        require(checkPercents == 10000, "Total percentage must be 10000");

        delete vestings;
        for (uint256 i = 0; i < _vestings.length; i++) {
            vestings.push(_vestings[i]);
        }

        emit VestingCreatedOrUpdated(_vestings);
    }

    /* For FE
        0: isWhitelister
        1: locked amount
        2: released amount
        3: claimable amount
    */
    function infoWallet(
        address user
    ) public view returns (bool, uint256, uint256, uint256) {
        return (
            whitelist[user],
            locked[user],
            released[user],
            _claimableAmount(user)
        );
    }

    function getVestingInfo() external view returns (VestingInfo[] memory) {
        return vestings;
    }

    function setIdoTokenAddress(address tokenAddress) external onlyAdmin {
        idoToken = IERC20(tokenAddress);
    }

    function withdraw(
        address _rewardAddress,
        uint256 _amount,
        address to
    ) external onlyOwner {
        IERC20(_rewardAddress).transfer(to, _amount);
    }

    function claim() external whenNotPaused {
        require(idoToken != IERC20(address(0)), "Have not set idoToken");
        require(locked[_msgSender()] > released[_msgSender()], "No locked");

        uint256 amount = _claimableAmount(_msgSender());
        require(amount > 0, "Nothing to claim");

        released[_msgSender()] += amount;

        idoToken.transfer(_msgSender(), amount);

        totalLocked -= amount;
        totalReleased += amount;

        emit Claimed(_msgSender(), amount, block.timestamp, address(idoToken));
    }

    function _claimableAmount(address account) private view returns (uint256) {
        uint256 totalPercents = 0;
        for (uint256 i = 0; i < vestings.length; i++) {
            if (block.timestamp < vestings[i].claimTime) {
                break;
            }
            totalPercents += vestings[i].percentage;
        }
        return (locked[account] * totalPercents) / 10000 - released[account];
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}