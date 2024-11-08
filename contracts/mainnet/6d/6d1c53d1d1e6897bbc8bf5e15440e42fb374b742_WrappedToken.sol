// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;

import {Token} from "./Token.sol";
import {SafeTransferLib, ERC20} from "solmate/utils/SafeTransferLib.sol";

/// @title WrappedToken Contract
/// @notice This contract wraps the rebasing Token contract into a non-rebasing ERC20 token.
/// @dev The wrapped token balance is equivalent to shares in the original token.
contract WrappedToken is ERC20 {
    error Paused();
    error NotWhitelisted();

    Token public immutable token;

    modifier notPaused() {
        if (token.paused()) revert Paused();
        _;
    }

    modifier onlyWhitelisted(address account) {
        if (!token.isWhitelisted(account)) revert NotWhitelisted();
        _;
    }

    constructor(Token _token) ERC20("", "", _token.decimals()) {
        token = _token;
        updateName();
    }

    /// @notice Updates the wrapped token name and symbol to match the original token.
    function updateName() public {
        name = string.concat("Wrapped ", token.name());
        symbol = string.concat("w", token.symbol());
    }

    /// @notice Wraps a specified amount of the original token into wrapped tokens.
    /// @param amount The amount of the original token to wrap.
    /// @return shares The amount of wrapped tokens minted.
    function wrap(uint256 amount) external returns (uint256 shares) {
        token.transferFrom(msg.sender, address(this), amount);
        shares = token.getSharesForTokenAmount(amount);
        _mint(msg.sender, shares);
    }

    /// @notice Unwraps a specified amount of the wrapped token into the original token.
    /// @param amount The amount of "shares" to unwrap.
    /// @return tokenAmount The amount of the original token received.
    function unwrap(uint256 amount) external returns (uint256 tokenAmount) {
        _burn(msg.sender, amount);
        return token.transferShares(msg.sender, amount);
    }

    /// @dev Overrides transfer function to check if the recipient is whitelisted and the token is not paused.
    function transfer(address to, uint256 amount) public override onlyWhitelisted(to) notPaused returns (bool) {
        return super.transfer(to, amount);
    }

    /// @dev Overrides transferFrom function to check if the recipient is whitelisted and the token is not paused.
    function transferFrom(address from, address to, uint256 amount)
        public
        override
        onlyWhitelisted(to)
        notPaused
        returns (bool)
    {
        return super.transferFrom(from, to, amount);
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;

import {RebasingToken} from "./RebasingToken.sol";
import {Whitelist} from "../management/Whitelist.sol";
import {Owned} from "solmate/auth/Owned.sol";

/// @title Token contract extending RebasingToken and Owned.
/// @notice This contract adds pausing, whitelisting and ownership functionalities to RebasingToken.
contract Token is RebasingToken, Owned {
    Whitelist public whitelist;
    bool public paused;

    event SetName(string name, string symbol);
    event SetWhitelist(address indexed whitelist);
    event Pause();
    event UnPause();

    error Paused();
    error NotWhitelisted();

    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    modifier onlyWhitelisted(address account) {
        if (!isWhitelisted(account)) revert NotWhitelisted();
        _;
    }

    constructor(Whitelist _whitelist, string memory name, string memory symbol, uint8 decimals)
        RebasingToken(name, symbol, decimals)
        Owned(msg.sender)
    {
        whitelist = _whitelist;
        emit SetName(name, symbol);
        emit SetWhitelist(address(_whitelist));
    }

    /// @notice Checks if an address is whitelisted.
    /// @param account The address to check.
    /// @return True if the address is whitelisted, false otherwise.
    function isWhitelisted(address account) public view returns (bool) {
        return whitelist.isWhitelisted(account);
    }

    /// @notice Sets the name and symbol of the token.
    /// @param _name The new name of the token.
    /// @param _symbol The new symbol of the token.
    function setName(string memory _name, string memory _symbol) external onlyOwner {
        name = _name;
        symbol = _symbol;
        emit SetName(_name, _symbol);
    }

    /// @notice Sets the Whitelist contract for the token.
    /// @param _whitelist The new Whitelist contract.
    function setWhitelist(Whitelist _whitelist) external onlyOwner {
        whitelist = _whitelist;
        emit SetWhitelist(address(_whitelist));
    }

    /// @notice Pauses all token transfers.
    function pause() external onlyOwner {
        paused = true;
        emit Pause();
    }

    /// @notice Unpauses all token transfers.
    function unpause() external onlyOwner {
        paused = false;
        emit UnPause();
    }

    /// @notice Sets the parameters for a rebase.
    /// @param change The change rate for the rebase.
    /// @param startTime The start time for the rebase.
    /// @param endTime The end time for the rebase.
    function setRebase(uint32 change, uint32 startTime, uint32 endTime) external onlyOwner {
        _setRebase(change, startTime, endTime);
    }

    /// @notice Mints tokens to a whitelisted address.
    /// @param to The address to mint tokens to.
    /// @param amount The amount of tokens to mint.
    /// @return sharesMinted The number of shares minted.
    function mint(address to, uint256 amount) external onlyOwner onlyWhitelisted(to) returns (uint256 sharesMinted) {
        return _mint(to, amount);
    }

    /// @notice Burns tokens from a user.
    /// @param user The address to burn tokens from.
    /// @param amount The amount of tokens to burn.
    /// @return sharesBurned The number of shares burned.
    function burn(address user, uint256 amount) external onlyOwner returns (uint256 sharesBurned) {
        return _burn(user, amount);
    }

    /// @notice Burns tokens from the caller.
    /// @param amount The amount of tokens to burn.
    /// @return sharesBurned The number of shares burned.
    function burn(uint256 amount) external returns (uint256 sharesBurned) {
        return _burn(msg.sender, amount);
    }

    /// @dev Internal function to handle token transfers, overriding the base implementation.
    /// @param from The address to transfer from.
    /// @param to The address to transfer to.
    /// @param amount The amount to transfer.
    function _transfer(address from, address to, uint256 amount) internal override whenNotPaused onlyWhitelisted(to) {
        super._transfer(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Caution! This library won't check that a token has code, responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(4, from) // Append the "from" argument.
            mstore(36, to) // Append the "to" argument.
            mstore(68, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because that's the total length of our calldata (4 + 32 * 3)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 100, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(4, to) // Append the "to" argument.
            mstore(36, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because that's the total length of our calldata (4 + 32 * 2)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 68, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(4, to) // Append the "to" argument.
            mstore(36, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because that's the total length of our calldata (4 + 32 * 2)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 68, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";
import {Math} from "../libraries/Math.sol";
import {RebaseConstants as RC} from "../libraries/RebaseConstants.sol";
import {Base} from "./Base.sol";

/// @title RebasingToken
/// @dev An abstract contract for rebasing token logic, extending Base contract.
abstract contract RebasingToken is Base {
    using SafeCastLib for uint256;

    /// @dev Stores rebase information.
    struct Rebase {
        uint128 totalShares;
        uint128 lastTotalSupply;
        uint32 change;
        uint32 startTime;
        uint32 endTime;
    }

    event SetRebase(uint32 change, uint32 startTime, uint32 endTime);

    error InvalidTimeFrame();
    error InvalidRebase();

    Rebase internal _rebase =
        Rebase({totalShares: 0, lastTotalSupply: 0, change: uint32(RC.CHANGE_PRECISION), startTime: 0, endTime: 0});

    /// @notice User's shares.
    mapping(address => uint256) public sharesOf;

    constructor(string memory name, string memory symbol, uint8 decimals) Base(name, symbol, decimals) {}

    /// @notice Gets current rebase settings.
    /// @return A Rebase struct with current rebase settings.
    function getRebase() external view returns (Rebase memory) {
        return _rebase;
    }

    /// @notice Calculates the total supply of the token, considering the rebase.
    /// @return The total supply.
    function totalSupply() public view override returns (uint256) {
        return _rebase.lastTotalSupply * rebaseProgress() / RC.CHANGE_PRECISION;
    }

    /// @notice Computes the rebase progress based on current time.
    /// @return The relative change so far.
    function rebaseProgress() public view returns (uint256) {
        uint256 currentTime = block.timestamp;
        if (currentTime <= _rebase.startTime) {
            return RC.CHANGE_PRECISION;
        } else if (currentTime <= _rebase.endTime) {
            return Math.interpolate(
                RC.CHANGE_PRECISION,
                _rebase.change,
                currentTime - _rebase.startTime,
                _rebase.endTime - _rebase.startTime
            );
        } else {
            return _rebase.change;
        }
    }

    /// @notice Total shares of the token.
    function totalShares() public view returns (uint256) {
        return _rebase.totalShares;
    }

    /// @notice Converts token amount to shares.
    /// @param amount The amount of tokens.
    /// @return The equivalent shares.
    function getSharesForTokenAmount(uint256 amount) public view returns (uint256) {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) return amount;
        return amount * totalShares() / _totalSupply;
    }

    /// @notice Converts shares to token amount.
    /// @param shares The number of shares.
    /// @return The equivalent token amount.
    function getTokenAmountForShares(uint256 shares) public view returns (uint256) {
        uint256 _totalShares = totalShares();
        if (_totalShares == 0) return shares;
        return shares * totalSupply() / _totalShares;
    }

    /// @notice Gets the balance of an account considering rebase.
    /// @param account Address of the account.
    /// @return The balance of the account.
    function balanceOf(address account) public view override returns (uint256) {
        return getTokenAmountForShares(sharesOf[account]);
    }

    /// @notice Transfers shares between addresses.
    /// @param to Destination address.
    /// @param shares Number of shares to transfer.
    /// @return amountTransfered The amount of tokens transferred.
    function transferShares(address to, uint256 shares) public returns (uint256 amountTransfered) {
        amountTransfered = getTokenAmountForShares(shares);
        sharesOf[msg.sender] -= shares;
        unchecked {
            sharesOf[to] += shares;
        }
        emit Transfer(msg.sender, to, amountTransfered);
    }

    /// @dev Internal function to handle token transfers.
    /// @param from The address to transfer from.
    /// @param to The address to transfer to.
    /// @param amount The amount to transfer.
    function _transfer(address from, address to, uint256 amount) internal virtual override {
        uint256 shares = getSharesForTokenAmount(amount);
        sharesOf[from] -= shares;
        unchecked {
            sharesOf[to] += shares;
        }
        emit Transfer(from, to, amount);
    }

    /// @dev Internal function to set rebase parameters.
    /// @param change The change rate.
    /// @param startTime The start time of the rebase.
    /// @param endTime The end time of the rebase.
    function _setRebase(uint32 change, uint32 startTime, uint32 endTime) internal {
        if (endTime - startTime < RC.MIN_DURATION) {
            revert InvalidTimeFrame();
        }
        uint256 _totalSupply = totalSupply();
        if (
            change > RC.MAX_INCREASE || change < RC.MAX_DECREASE
                || _totalSupply * change / RC.CHANGE_PRECISION > type(uint128).max
        ) {
            revert InvalidRebase();
        }
        _rebase.lastTotalSupply = _totalSupply.safeCastTo128();
        _rebase.change = change;
        _rebase.startTime = startTime;
        _rebase.endTime = endTime;
        emit SetRebase(change, startTime, endTime);
    }

    /// @dev Internal function for minting tokens.
    /// @param to The address to mint tokens to.
    /// @param amount The amount to mint.
    /// @return shares The number of shares minted.
    function _mint(address to, uint256 amount) internal override returns (uint256 shares) {
        shares = getSharesForTokenAmount(amount);
        _rebase.totalShares += shares.safeCastTo128();
        _rebase.lastTotalSupply += _principalAmount(amount).safeCastTo128();
        unchecked {
            sharesOf[to] += shares;
        }
        emit Transfer(address(0), to, amount);
    }

    /// @dev Internal function for burning tokens.
    /// @param from The address to burn tokens from.
    /// @param amount The amount to burn.
    /// @return shares The number of shares burned.
    function _burn(address from, uint256 amount) internal override returns (uint256 shares) {
        shares = getSharesForTokenAmount(amount);
        _rebase.totalShares -= shares.safeCastTo128();
        _rebase.lastTotalSupply -= _principalAmount(amount).safeCastTo128();
        sharesOf[from] -= shares;
        emit Transfer(from, address(0), amount);
    }

    /// @dev Calculates the principal amount before rebase adjustment.
    /// @param amount The amount to adjust.
    /// @return The principal amount.
    function _principalAmount(uint256 amount) internal view returns (uint256) {
        return amount * RC.CHANGE_PRECISION / rebaseProgress();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Owned} from "solmate/auth/Owned.sol";
import {MerkleProofLib} from "solmate/utils/MerkleProofLib.sol";

contract Whitelist is Owned {
    mapping(address => bool) public isWhitelisted;

    bytes32 public merkleRoot;

    event Whitelisted(address indexed account, bool whitelisted);

    error InvalidProof();
    error MisMatchArrayLength();

    constructor() Owned(msg.sender) {}

    function verify(bytes32[] calldata proof, address user) public view returns (bool) {
        return MerkleProofLib.verify(proof, merkleRoot, keccak256(abi.encodePacked(user)));
    }

    function whitelistAddress(bytes32[] calldata proof, address user) external {
        if (!verify(proof, user)) revert InvalidProof();
        isWhitelisted[user] = true;
        emit Whitelisted(user, true);
    }

    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    function setDirectWhitelist(address account, bool whitelisted) external onlyOwner {
        isWhitelisted[account] = whitelisted;
        emit Whitelisted(account, whitelisted);
    }

    function setDirectWhitelists(address[] calldata accounts, bool[] calldata whitelisted) external onlyOwner {
        if (accounts.length != whitelisted.length) revert MisMatchArrayLength();
        for (uint256 i = 0; i < accounts.length; i++) {
            isWhitelisted[accounts[i]] = whitelisted[i];
            emit Whitelisted(accounts[i], whitelisted[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Safe unsigned integer casting library that reverts on overflow.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeCastLib.sol)
library SafeCastLib {
    function safeCastTo248(uint256 x) internal pure returns (uint248 y) {
        require(x < 1 << 248);

        y = uint248(x);
    }

    function safeCastTo224(uint256 x) internal pure returns (uint224 y) {
        require(x < 1 << 224);

        y = uint224(x);
    }

    function safeCastTo192(uint256 x) internal pure returns (uint192 y) {
        require(x < 1 << 192);

        y = uint192(x);
    }

    function safeCastTo160(uint256 x) internal pure returns (uint160 y) {
        require(x < 1 << 160);

        y = uint160(x);
    }

    function safeCastTo128(uint256 x) internal pure returns (uint128 y) {
        require(x < 1 << 128);

        y = uint128(x);
    }

    function safeCastTo96(uint256 x) internal pure returns (uint96 y) {
        require(x < 1 << 96);

        y = uint96(x);
    }

    function safeCastTo64(uint256 x) internal pure returns (uint64 y) {
        require(x < 1 << 64);

        y = uint64(x);
    }

    function safeCastTo32(uint256 x) internal pure returns (uint32 y) {
        require(x < 1 << 32);

        y = uint32(x);
    }

    function safeCastTo8(uint256 x) internal pure returns (uint8 y) {
        require(x < 1 << 8);

        y = uint8(x);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Math {
    function diff(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : b - a;
    }

    function interpolate(uint256 a, uint256 b, uint256 numerator, uint256 denominator)
        internal
        pure
        returns (uint256)
    {
        uint256 difference = diff(a, b);
        difference = difference * numerator / denominator;
        return a < b ? a + difference : a - difference;
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

library RebaseConstants {
    uint256 internal constant CHANGE_PRECISION = 100_000_000;
    uint256 internal constant MAX_CHANGE = CHANGE_PRECISION / 10; // 10%
    uint256 internal constant MAX_INCREASE = CHANGE_PRECISION + MAX_CHANGE;
    uint256 internal constant MAX_DECREASE = CHANGE_PRECISION - MAX_CHANGE;
    uint256 internal constant MIN_DURATION = 1 hours;
}

// SPDX-License-Identifier: Unlicense
// Adapted from solmate's ERC20 contract
pragma solidity ^0.8.0;

/// @title RebasingToken
/// @dev Stub ERC20 contract, to be extended by RebasingToken.
abstract contract Base {
    error PermitExpired();
    error InvalidSigner();

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    uint256 internal immutable INITIAL_CHAIN_ID;
    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    string public name;
    string public symbol;
    uint8 public immutable decimals;

    mapping(address => uint256) public nonces;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    function totalSupply() public view virtual returns (uint256);

    function balanceOf(address account) public view virtual returns (uint256);

    function _transfer(address from, address to, uint256 amount) internal virtual;

    function _mint(address to, uint256 amount) internal virtual returns (uint256);

    function _burn(address from, uint256 amount) internal virtual returns (uint256);

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;
        _transfer(from, to, amount);
        return true;
    }

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        public
    {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Gas optimized merkle proof verification library.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/MerkleProofLib.sol)
library MerkleProofLib {
    function verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool isValid) {
        assembly {
            let computedHash := leaf // The hash starts as the leaf hash.

            // Initialize data to the offset of the proof in the calldata.
            let data := proof.offset

            // Iterate over proof elements to compute root hash.
            for {
                // Left shifting by 5 is like multiplying by 32.
                let end := add(data, shl(5, proof.length))
            } lt(data, end) {
                data := add(data, 32) // Shift 1 word per cycle.
            } {
                // Load the current proof element.
                let loadedData := calldataload(data)

                // Slot where computedHash should be put in scratch space.
                // If computedHash > loadedData: slot 32, otherwise: slot 0.
                let computedHashSlot := shl(5, gt(computedHash, loadedData))

                // Store elements to hash contiguously in scratch space.
                // The xor puts loadedData in whichever slot computedHash is
                // not occupying, so 0 if computedHashSlot is 32, 32 otherwise.
                mstore(computedHashSlot, computedHash)
                mstore(xor(computedHashSlot, 32), loadedData)

                computedHash := keccak256(0, 64) // Hash both slots of scratch space.
            }

            isValid := eq(computedHash, root) // The proof is valid if the roots match.
        }
    }
}