// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

abstract contract ERC20 {

    uint256 private _totalSupply;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /*
   * Internal Functions for ERC20 standard logics
   */

    function _transfer(address from, address to, uint256 amount)
        internal
        returns (bool success)
    {
        _balances[from] = _balances[from] - amount;
        _balances[to] = _balances[to] + amount;
        emit Transfer(from, to, amount);
        success = true;
    }

    function _approve(address owner, address spender, uint256 amount)
        internal
        returns (bool success)
    {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        success = true;
    }

    function _mint(address recipient, uint256 amount)
        internal
        returns (bool success)
    {
        _totalSupply = _totalSupply + amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(address(0), recipient, amount);
        success = true;
    }

    function _burn(address burned, uint256 amount)
        internal
        returns (bool success)
    {
        _balances[burned] = _balances[burned] - amount;
        _totalSupply = _totalSupply - amount;
        emit Transfer(burned, address(0), amount);
        success = true;
    }

    /*
   * public view functions to view common data
   */

    function totalSupply() external view returns (uint256 total) {
        total = _totalSupply;
    }
    function balanceOf(address owner) external view returns (uint256 balance) {
        balance = _balances[owner];
    }

    function allowance(address owner, address spender)
        external
        view
        returns (uint256 remaining)
    {
        remaining = _allowances[owner][spender];
    }

    /*
   * External view Function Interface to implement on final contract
   */
    function name() virtual external view returns (string memory tokenName);
    function symbol() virtual external view returns (string memory tokenSymbol);
    function decimals() virtual external view returns (uint8 tokenDecimals);

    /*
   * External Function Interface to implement on final contract
   */
    function transfer(address to, uint256 amount)
        virtual
        external
        returns (bool success);
    function transferFrom(address from, address to, uint256 amount)
        virtual
        external
        returns (bool success);
    function approve(address spender, uint256 amount)
        virtual
        external
        returns (bool success);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./ERC20.sol";

abstract contract ERC20Burnable is ERC20 {
    event Burn(address indexed burned, uint256 amount);

    function burn(uint256 amount) external returns (bool success) {
        success = _burn(msg.sender, amount);
        emit Burn(msg.sender, amount);
        success = true;
    }

    function burnFrom(
        address burned,
        uint256 amount
    ) external returns (bool success) {
        _burn(burned, amount);
        emit Burn(burned, amount);
        success = _approve(
            burned,
            msg.sender,
            _allowances[burned][msg.sender] - amount
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./ERC20.sol";

abstract contract ERC20Lockable is ERC20 {
    struct LockInfo {
        uint256 amount;
        uint256 due;
    }

    mapping(address => LockInfo[]) internal _locks;
    mapping(address => uint256) internal _totalLocked;

    event Lock(address indexed from, uint256 amount, uint256 due);
    event Unlock(address indexed from, uint256 amount);

    modifier checkLock(address from, uint256 amount) {
        require(
            _balances[from] >= _totalLocked[from] + amount,
            "ERC20Lockable/Cannot send more than unlocked amount"
        );
        _;
    }

    function _lock(
        address from,
        uint256 amount,
        uint256 due
    ) internal returns (bool success) {
        require(
            due > block.timestamp,
            "ERC20Lockable/lock : Cannot set due to past"
        );
        require(
            _balances[from] >= amount + _totalLocked[from],
            "ERC20Lockable/lock : locked total should be smaller than balance"
        );
        _totalLocked[from] = _totalLocked[from] + amount;
        _locks[from].push(LockInfo(amount, due));
        emit Lock(from, amount, due);
        success = true;
    }

    function _unlock(
        address from,
        uint256 index
    ) internal returns (bool success) {
        LockInfo storage lock = _locks[from][index];
        _totalLocked[from] = _totalLocked[from] - lock.amount;
        emit Unlock(from, lock.amount);
        _locks[from][index] = _locks[from][_locks[from].length - 1];
        _locks[from].pop();
        success = true;
    }

    function unlock(address from, uint256 idx) external returns (bool success) {
        require(
            _locks[from][idx].due < block.timestamp,
            "ERC20Lockable/unlock: cannot unlock before due"
        );
        return _unlock(from, idx);
    }

    function unlockAll(address from) external returns (bool success) {
        for (uint256 i = _locks[from].length; i > 0; i--) {
            if (_locks[from][i - 1].due < block.timestamp) {
                _unlock(from, i - 1);
            }
        }
        success = true;
    }

    function lockInfo(
        address locked,
        uint256 index
    ) external view returns (uint256 amount, uint256 due) {
        LockInfo memory lock = _locks[locked][index];
        amount = lock.amount;
        due = lock.due;
    }

    function totalLocked(
        address locked
    ) external view returns (uint256 amount, uint256 length) {
        amount = _totalLocked[locked];
        length = _locks[locked].length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Lockable.sol";
import "./Ownable.sol";

contract ERC20Token is ERC20, ERC20Burnable, ERC20Lockable, Ownable {
    string private constant _name = "HIPPOP";
    string private constant _symbol = "HIP";
    uint8 private constant _decimals = 18;

    constructor() {
        _mint(msg.sender, 1250000000 ether);
    }

    /* ======================================================= */
    /* ===================== ERC20 Method ==================== */
    /* ======================================================= */

    function transfer(
        address to,
        uint256 amount
    ) external override checkLock(msg.sender, amount) returns (bool success) {
        require(to != address(0), "transfer : Should not send to zero address");
        _transfer(msg.sender, to, amount);
        success = true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override checkLock(from, amount) returns (bool success) {
        require(
            to != address(0),
            "transferFrom : Should not send to zero address"
        );
        _transfer(from, to, amount);
        _approve(from, msg.sender, _allowances[from][msg.sender] - amount);
        success = true;
    }

    function approve(
        address spender,
        uint256 amount
    ) external override returns (bool success) {
        require(
            spender != address(0),
            "approve : Should not approve zero address"
        );
        _approve(msg.sender, spender, amount);
        success = true;
    }

    /* ======================================================= */
    /* =================== Lockable Method =================== */
    /* ======================================================= */

    function releaseLock(
        address from
    ) external onlyOwner returns (bool success) {
        for (uint256 i = 0; i < _locks[from].length; ) {
            i++;
            if (_unlock(from, i - 1)) {
                i--;
            }
        }
        success = true;
    }

    function transferWithLockUp(
        address recipient,
        uint256 amount,
        uint256 due
    ) external onlyOwner returns (bool success) {
        require(
            recipient != address(0),
            "ERC20Lockable/transferWithLockUp : Cannot send to zero address"
        );
        _transfer(msg.sender, recipient, amount);
        _lock(recipient, amount, due);
        success = true;
    }

    /* ======================================================= */
    /* ================== Token Information ================== */
    /* ======================================================= */

    function name() external pure override returns (string memory tokenName) {
        tokenName = _name;
    }

    function symbol()
        external
        pure
        override
        returns (string memory tokenSymbol)
    {
        tokenSymbol = _symbol;
    }

    function decimals() external pure override returns (uint8 tokenDecimals) {
        tokenDecimals = _decimals;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed currentOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(
            msg.sender == _owner,
            "Ownable : Function called by unauthorized user."
        );
        _;
    }

    function owner() external view returns (address ownerAddress) {
        ownerAddress = _owner;
    }

    function transferOwnership(address newOwner)
        public
        onlyOwner
        returns (bool success)
    {
        require(newOwner != address(0), "Ownable/transferOwnership : cannot transfer ownership to zero address");
        success = _transferOwnership(newOwner);
    }

    function renounceOwnership() external onlyOwner returns (bool success) {
        success = _transferOwnership(address(0));
    }

    function _transferOwnership(address newOwner) internal returns (bool success) {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
        success = true;
    }
}