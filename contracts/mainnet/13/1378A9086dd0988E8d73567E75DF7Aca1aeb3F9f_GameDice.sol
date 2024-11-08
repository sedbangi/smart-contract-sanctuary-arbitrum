// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
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
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
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
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
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

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

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
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IERC20BackwardsCompatible.sol";
import "../interfaces/IGame.sol";
import "../interfaces/IConsole.sol";
import "../interfaces/IHouse.sol";
import "../interfaces/IRNG.sol";
import "../interfaces/IUSDTVault.sol";

abstract contract Game is IGame, Ownable {
    error InvalidRolls(uint256 max, uint256 rolls);
    error MinBet(uint256 minRate, uint256 stake);

    IERC20BackwardsCompatible public usdtToken;
    IUSDTVault public usdtVault;
    IConsole public consoleInst;
    IHouse public house;
    IRNG public rng;
    uint256 id;
    uint256 public maxRoll;
    uint256 public numbersPerRoll;
    uint256 public minBetRate;
    
    event GameStart(uint256 indexed betId, uint256 _bet, uint256[50] _data);
    event GameEnd(uint256 indexed betId, uint256[] _randomNumbers, uint256[] _rolls, uint256 _bet, uint256 _stake, uint256 wins, uint256 losses, uint256 _payout, address indexed _account, uint256 indexed _timestamp);

    constructor (address _usdt, address _vault, address _console, address _house, address _rng, uint256 _id, uint256 _numbersPerRoll) {
        usdtToken = IERC20BackwardsCompatible(_usdt);
        usdtVault = IUSDTVault(_vault);
        consoleInst = IConsole(_console);
        house = IHouse(_house);
        rng = IRNG(_rng);
        id = _id;
        numbersPerRoll = _numbersPerRoll;
        maxRoll = 1;
        minBetRate = 0; //(10 ** 16); // 0.01 USDT
    }

    function getMaxPayout(uint256 _bet, uint256[50] memory _data) public virtual view returns (uint256);
    function finalize(uint256 _betId, uint256[] memory _randomNumbers) internal virtual returns (uint256);

    function updateMaxRoll(uint256 _newValue) external onlyOwner {
        require(maxRoll != _newValue, "Already Set");
        maxRoll = _newValue;
    }

    function updateMinBetRate(uint256 _newValue) external onlyOwner {
        require(minBetRate != _newValue, "Already Set");
        minBetRate = _newValue;
    }

    function play(uint256 _rolls, uint256 _bet, uint256[50] memory _data, uint256 _stake) external override {// gas: 871654 for roulette
        uint256 betId;
        uint256 betAmountWithFee;

        if (maxRoll > 0 && _rolls > maxRoll) {
            revert InvalidRolls(maxRoll, _rolls);
        }

        require(_stake > 0, "Please bet some coins");

        if (_stake * (10 ** 18) / (10 ** ERC20(address(usdtToken)).decimals()) < minBetRate) {
            revert MinBet(minBetRate, _stake);
        }

        (betId, betAmountWithFee) = house.openWager(msg.sender, id, _rolls, _bet, _data, _stake, getMaxPayout(_bet, _data)); // gas: 525635

        uint256[] memory ra = rng.generateMultiple(_rolls * numbersPerRoll); // gas: 23646
        uint256 payout = finalize(betId, ra); // gas: 59437

        house.closeWager(betId, msg.sender, id, payout); // gas: 154535

        usdtVault.finalizeGame(msg.sender, payout, betAmountWithFee - _rolls * _stake); // gas: 66308
    }

    function getId() external view returns (uint256) {
        return id;
    }

    function getLive() external view returns (bool) {
        Types.Game memory _game = consoleInst.getGame(id);
        return _game.live;
    }

    function getEdge() public view returns (uint256) {
        Types.Game memory _game = consoleInst.getGame(id);
        return _game.edge;
    }

    function getName() external view returns (string memory) {
        Types.Game memory _game = consoleInst.getGame(id);
        return _game.name;
    }

    function getDate() external view returns (uint256) {
        Types.Game memory _game = consoleInst.getGame(id);
        return _game.date;
    }

    function setUSDTToken(address _newUSDT) external onlyOwner {
        require(address(usdtToken) != _newUSDT, "Already Set");
        usdtToken = IERC20BackwardsCompatible(_newUSDT);
    }

    function setUSDTVault(address _newVault) external onlyOwner {
        require(address(usdtVault) != _newVault, "Already Set");
        usdtVault = IUSDTVault(_newVault);
    }

    function setConsoleInst(address _newConsole) external onlyOwner {
        require(address(consoleInst) != _newConsole, "Already Set");
        consoleInst = IConsole(_newConsole);
    }

    function setHouse(address _newHouse) external onlyOwner {
        require(address(house) != _newHouse, "Already Set");
        house = IHouse(_newHouse);
    }

    function setRNG(address _newRNG) external onlyOwner {
        require(address(rng) != _newRNG, "Already Set");
        rng = IRNG(_newRNG);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Game.sol";

contract GameDice is Game {
    error InvalidBet(uint256 bet);

    constructor (address _usdt, address _vault, address _console, address _house, address _rng, uint256 _id, uint256 _numbersPerRoll)
        Game(_usdt, _vault, _console, _house, _rng, _id, _numbersPerRoll)
    {}
    
    function finalize(uint256 _betId, uint256[] memory _randomNumbers) internal virtual override returns (uint256) {
        Types.Bet memory _bet = house.getBet(_betId);
        uint256 _betNum = _bet.betNum;
        uint256 _payout;
        uint256[] memory _rolls = new uint256[](_bet.rolls);

        emit GameStart(_betId, _betNum, _bet.data);

        Types.Game memory ga = consoleInst.getGame(id);
        if (_betNum < ga.edge || _betNum + ga.edge > 100) {
            revert InvalidBet(_betNum);
        }

        uint256 payoutRatio = getMaxPayout(_betNum, _bet.data);
        uint256 wins = 0;
        uint256 losses = 0;

        for (uint256 _i = 0; _i < _bet.rolls; _i++) {
            uint256 _roll = rng.getModulo(_randomNumbers[_i], 0, 100);
            if(_roll > _betNum) {
                _payout += _bet.stake * payoutRatio / PAYOUT_AMPLIFIER;
                wins ++;
            } else {
                losses ++;
            }
            _rolls[_i] = _roll;
        }
        
        emit GameEnd(_betId, _randomNumbers, _rolls, _betNum, _bet.stake, wins, losses, _payout, _bet.player, block.timestamp);

        return _payout;
    }

    function getMaxPayout(uint256 _bet, uint256[50] memory) public virtual override view returns (uint256) {
        Types.Game memory ga = consoleInst.getGame(id);
        return ((100 - ga.edge) * PAYOUT_AMPLIFIER) / (100 - _bet);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Types.sol";

interface IConsole {
    function getGame(uint256 _id) external view returns (Types.Game memory);
    function getGameByImpl(address _impl) external view returns (Types.Game memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity >=0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20BackwardsCompatible {
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
    function transfer(address to, uint256 amount) external;

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
    function approve(address spender, uint256 amount) external;

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGame {
    function play(uint256 _rolls, uint256 _bet, uint256[50] memory _data, uint256 _stake) external;
    function getMaxPayout(uint256 _bet, uint256[50] memory _data) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Types.sol";

interface IHouse {
    function openWager(address _account, uint256 _game, uint256 _rolls, uint256 _bet, uint256[50] calldata _data, uint256 _betSize, uint256 _maxPayout) external returns (uint256, uint256);
    function closeWager(uint256 betId, address _account, uint256 _gameId, uint256 _payout) external returns (bool);
    function getBet(uint256 _id) external view returns (Types.Bet memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRNG {
    function generateNextRandomVariable() external returns (uint256);
    function generateModulo(uint256 lo, uint256 hi) external returns (uint256);
    function shuffleRandomNumbers() external;
    function generateMultiple(uint256 count) external returns (uint256[] memory);
    function getModulo(uint256 val, uint256 lo, uint256 hi) external pure returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUSDTVault {
    function finalizeGame(address _player, uint256 _prize, uint256 _fee) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

uint256 constant RESOLUTION = 10000;
uint256 constant PAYOUT_AMPLIFIER = 10 ** 24;

library Types {
    struct Bet {
        uint256 globalBetId;
        uint256 playerBetId;
        uint256 gameId;
        uint256 rolls;
        uint256 betNum;
        uint256 stake;
        uint256 payout;
        bool complete;
        uint256 opened;
        uint256 closed;
        uint256[50] data;
        address player;
    }

    struct Game {
        uint256 id;
        bool live;
        uint256 edge;
        uint256 date;
        address impl;
        string name;
    }

    struct HouseGame {
        uint256 betCount;
        uint256[] betIds;
    }

    struct PlayerGame {
        uint256 betCount;
        uint256 wagers;
        uint256 profits;
        uint256 wins;
        uint256 losses;
    }

    struct Player {
        uint256 betCount;
        uint256[] betIds;

        uint256 wagers;
        uint256 profits;

        uint256 wins;
        uint256 losses;
    }

    struct Player2 {
        Player info;
        mapping (uint256 => PlayerGame) games;
    }
}

/*
pragma solidity ^0.8.0;

uint256 constant RESOLUTION = 10000;
uint256 constant PAYOUT_AMPLIFIER = 10 ** 24;

type BETCOUNT is uint32;
type GAMECOUNT is uint16;
type DATAVALUE is uint128;
type ROLLCOUNT is uint16;
type BETNUM is uint32;
type TOKENAMOUNT is uint128;
type TIMESTAMP is uint32;
type EDGEAMOUNT is uint16;

library Types {

    function add(BETCOUNT a, uint256 b) internal pure returns (BETCOUNT) {
        return BETCOUNT.wrap(uint32(uint256(BETCOUNT.unwrap(a)) + b));
    }

    function toUint256(BETCOUNT a) internal pure returns (uint256) {
        return uint256(BETCOUNT.unwrap(a));
    }

    function add(GAMECOUNT a, uint256 b) internal pure returns (GAMECOUNT) {
        return GAMECOUNT.wrap(uint16(uint256(GAMECOUNT.unwrap(a)) + b));
    }

    struct Bet {
        BETCOUNT globalBetId;
        BETCOUNT playerBetId;
        GAMECOUNT gameId;
        ROLLCOUNT rolls;
        BETNUM betNum;
        TOKENAMOUNT stake;
        TOKENAMOUNT payout;
        bool complete;
        TIMESTAMP opened;
        TIMESTAMP closed;
        DATAVALUE[50] data;
        address player;
    }

    struct Game {
        GAMECOUNT id;
        bool live;
        EDGEAMOUNT edge;
        TIMESTAMP date;
        address impl;
        string name;
    }

    struct HouseGame {
        BETCOUNT betCount;
        BETCOUNT[] betIds;
    }

    struct PlayerGame {
        BETCOUNT betCount;
        TOKENAMOUNT wagers;
        TOKENAMOUNT profits;
        BETCOUNT wins;
        BETCOUNT losses;
    }

    struct Player {
        BETCOUNT betCount;
        BETCOUNT[] betIds;

        TOKENAMOUNT wagers;
        TOKENAMOUNT profits;

        BETCOUNT wins;
        BETCOUNT losses;

        mapping (GAMECOUNT => PlayerGame) games;
    }
}
*/