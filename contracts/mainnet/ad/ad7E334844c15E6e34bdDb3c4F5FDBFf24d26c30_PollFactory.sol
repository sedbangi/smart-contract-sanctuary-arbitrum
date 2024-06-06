// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "./IERC20.sol";
import {IERC20Metadata} from "./extensions/IERC20Metadata.sol";
import {Context} from "../../utils/Context.sol";
import {IERC20Errors} from "../../interfaces/draft-IERC6093.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
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
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
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
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
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
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     * ```
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     *
     * CAUTION: See Security Considerations above.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";
import {IERC20Permit} from "../extensions/IERC20Permit.sol";
import {Address} from "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

// @note This code was taken from
// https://github.com/yondonfu/sol-baby-jubjub/blob/master/contracts/CurveBabyJubJub.sol
// Thanks to yondonfu for the code
// Implementation cited on baby-jubjub's paper
// https://eips.ethereum.org/EIPS/eip-2494#implementation

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library CurveBabyJubJub {
  // Curve parameters
  // E: 168700x^2 + y^2 = 1 + 168696x^2y^2
  // A = 168700
  uint256 public constant A = 0x292FC;
  // D = 168696
  uint256 public constant D = 0x292F8;
  // Prime Q = 21888242871839275222246405745257275088548364400416034343698204186575808495617
  uint256 public constant Q = 0x30644E72E131A029B85045B68181585D2833E84879B9709143E1F593F0000001;

  /**
   * @dev Add 2 points on baby jubjub curve
   * Formula for adding 2 points on a twisted Edwards curve:
   * x3 = (x1y2 + y1x2) / (1 + dx1x2y1y2)
   * y3 = (y1y2 - ax1x2) / (1 - dx1x2y1y2)
   */
  function pointAdd(uint256 _x1, uint256 _y1, uint256 _x2, uint256 _y2) internal view returns (uint256 x3, uint256 y3) {
    if (_x1 == 0 && _y1 == 0) {
      return (_x2, _y2);
    }

    if (_x2 == 0 && _y1 == 0) {
      return (_x1, _y1);
    }

    uint256 x1x2 = mulmod(_x1, _x2, Q);
    uint256 y1y2 = mulmod(_y1, _y2, Q);
    uint256 dx1x2y1y2 = mulmod(D, mulmod(x1x2, y1y2, Q), Q);
    uint256 x3Num = addmod(mulmod(_x1, _y2, Q), mulmod(_y1, _x2, Q), Q);
    uint256 y3Num = submod(y1y2, mulmod(A, x1x2, Q), Q);

    x3 = mulmod(x3Num, inverse(addmod(1, dx1x2y1y2, Q)), Q);
    y3 = mulmod(y3Num, inverse(submod(1, dx1x2y1y2, Q)), Q);
  }

  /**
   * @dev Double a point on baby jubjub curve
   * Doubling can be performed with the same formula as addition
   */
  function pointDouble(uint256 _x1, uint256 _y1) internal view returns (uint256 x2, uint256 y2) {
    return pointAdd(_x1, _y1, _x1, _y1);
  }

  /**
   * @dev Multiply a point on baby jubjub curve by a scalar
   * Use the double and add algorithm
   */
  function pointMul(uint256 _x1, uint256 _y1, uint256 _d) internal view returns (uint256 x2, uint256 y2) {
    uint256 remaining = _d;

    uint256 px = _x1;
    uint256 py = _y1;
    uint256 ax = 0;
    uint256 ay = 0;

    while (remaining != 0) {
      if ((remaining & 1) != 0) {
        // Binary digit is 1 so add
        (ax, ay) = pointAdd(ax, ay, px, py);
      }

      (px, py) = pointDouble(px, py);

      remaining = remaining / 2;
    }

    x2 = ax;
    y2 = ay;
  }

  /**
   * @dev Check if a given point is on the curve
   * (168700x^2 + y^2) - (1 + 168696x^2y^2) == 0
   */
  function isOnCurve(uint256 _x, uint256 _y) internal pure returns (bool) {
    uint256 xSq = mulmod(_x, _x, Q);
    uint256 ySq = mulmod(_y, _y, Q);
    uint256 lhs = addmod(mulmod(A, xSq, Q), ySq, Q);
    uint256 rhs = addmod(1, mulmod(mulmod(D, xSq, Q), ySq, Q), Q);
    return submod(lhs, rhs, Q) == 0;
  }

  /**
   * @dev Perform modular subtraction
   */
  function submod(uint256 _a, uint256 _b, uint256 _mod) internal pure returns (uint256) {
    uint256 aNN = _a;

    if (_a <= _b) {
      aNN += _mod;
    }

    return addmod(aNN - _b, 0, _mod);
  }

  /**
   * @dev Compute modular inverse of a number
   */
  function inverse(uint256 _a) internal view returns (uint256) {
    // We can use Euler's theorem instead of the extended Euclidean algorithm
    // Since m = Q and Q is prime we have: a^-1 = a^(m - 2) (mod m)
    return expmod(_a, Q - 2, Q);
  }

  /**
   * @dev Helper function to call the bigModExp precompile
   */
  function expmod(uint256 _b, uint256 _e, uint256 _m) internal view returns (uint256 o) {
    assembly {
      let memPtr := mload(0x40)
      mstore(memPtr, 0x20) // Length of base _b
      mstore(add(memPtr, 0x20), 0x20) // Length of exponent _e
      mstore(add(memPtr, 0x40), 0x20) // Length of modulus _m
      mstore(add(memPtr, 0x60), _b) // Base _b
      mstore(add(memPtr, 0x80), _e) // Exponent _e
      mstore(add(memPtr, 0xa0), _m) // Modulus _m

      // The bigModExp precompile is at 0x05
      let success := staticcall(gas(), 0x05, memPtr, 0xc0, memPtr, 0x20)
      switch success
      case 0 {
        revert(0x0, 0x0)
      }
      default {
        o := mload(memPtr)
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { SnarkConstants } from "./SnarkConstants.sol";
import { PoseidonT3 } from "./PoseidonT3.sol";
import { PoseidonT4 } from "./PoseidonT4.sol";
import { PoseidonT5 } from "./PoseidonT5.sol";
import { PoseidonT6 } from "./PoseidonT6.sol";

/// @notice A SHA256 hash function for any number of input elements, and Poseidon hash
/// functions for 2, 3, 4, 5, and 12 input elements.
contract Hasher is SnarkConstants {
  /// @notice Computes the SHA256 hash of an array of uint256 elements.
  /// @param array The array of uint256 elements.
  /// @return result The SHA256 hash of the array.
  function sha256Hash(uint256[] memory array) public pure returns (uint256 result) {
    result = uint256(sha256(abi.encodePacked(array))) % SNARK_SCALAR_FIELD;
  }

  /// @notice Computes the Poseidon hash of two uint256 elements.
  /// @param array An array of two uint256 elements.
  /// @return result The Poseidon hash of the two elements.
  function hash2(uint256[2] memory array) public pure returns (uint256 result) {
    result = PoseidonT3.poseidon(array);
  }

  /// @notice Computes the Poseidon hash of three uint256 elements.
  /// @param array An array of three uint256 elements.
  /// @return result The Poseidon hash of the three elements.
  function hash3(uint256[3] memory array) public pure returns (uint256 result) {
    result = PoseidonT4.poseidon(array);
  }

  /// @notice Computes the Poseidon hash of four uint256 elements.
  /// @param array An array of four uint256 elements.
  /// @return result The Poseidon hash of the four elements.
  function hash4(uint256[4] memory array) public pure returns (uint256 result) {
    result = PoseidonT5.poseidon(array);
  }

  /// @notice Computes the Poseidon hash of five uint256 elements.
  /// @param array An array of five uint256 elements.
  /// @return result The Poseidon hash of the five elements.
  function hash5(uint256[5] memory array) public pure returns (uint256 result) {
    result = PoseidonT6.poseidon(array);
  }

  /// @notice Computes the Poseidon hash of two uint256 elements.
  /// @param left the first element to hash.
  /// @param right the second element to hash.
  /// @return result The Poseidon hash of the two elements.
  function hashLeftRight(uint256 left, uint256 right) public pure returns (uint256 result) {
    uint256[2] memory input;
    input[0] = left;
    input[1] = right;
    result = hash2(input);
  }
}

// SPDX-License-Identifier: MIT
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

// 2019 OKIMS

pragma solidity ^0.8.20;

/// @title Pairing
/// @notice A library implementing the alt_bn128 elliptic curve operations.
library Pairing {
  uint256 public constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

  struct G1Point {
    uint256 x;
    uint256 y;
  }

  // Encoding of field elements is: X[0] * z + X[1]
  struct G2Point {
    uint256[2] x;
    uint256[2] y;
  }

  /// @notice custom errors
  error PairingAddFailed();
  error PairingMulFailed();
  error PairingOpcodeFailed();

  /// @notice The negation of p, i.e. p.plus(p.negate()) should be zero.
  function negate(G1Point memory p) internal pure returns (G1Point memory) {
    // The prime q in the base field F_q for G1
    if (p.x == 0 && p.y == 0) {
      return G1Point(0, 0);
    } else {
      return G1Point(p.x, PRIME_Q - (p.y % PRIME_Q));
    }
  }

  /// @notice r Returns the sum of two points of G1.
  function plus(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
    uint256[4] memory input;
    input[0] = p1.x;
    input[1] = p1.y;
    input[2] = p2.x;
    input[3] = p2.y;
    bool success;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
      // Use "invalid" to make gas estimation work
      switch success
      case 0 {
        invalid()
      }
    }

    if (!success) {
      revert PairingAddFailed();
    }
  }

  /// @notice r Return the product of a point on G1 and a scalar, i.e.
  ///         p == p.scalarMul(1) and p.plus(p) == p.scalarMul(2) for all
  ///         points p.
  function scalarMul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
    uint256[3] memory input;
    input[0] = p.x;
    input[1] = p.y;
    input[2] = s;
    bool success;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
      // Use "invalid" to make gas estimation work
      switch success
      case 0 {
        invalid()
      }
    }

    if (!success) {
      revert PairingMulFailed();
    }
  }

  /// @return isValid The result of computing the pairing check
  ///         e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
  ///        For example,
  ///        pairing([P1(), P1().negate()], [P2(), P2()]) should return true.
  function pairing(
    G1Point memory a1,
    G2Point memory a2,
    G1Point memory b1,
    G2Point memory b2,
    G1Point memory c1,
    G2Point memory c2,
    G1Point memory d1,
    G2Point memory d2
  ) internal view returns (bool isValid) {
    G1Point[4] memory p1;
    p1[0] = a1;
    p1[1] = b1;
    p1[2] = c1;
    p1[3] = d1;

    G2Point[4] memory p2;
    p2[0] = a2;
    p2[1] = b2;
    p2[2] = c2;
    p2[3] = d2;

    uint256 inputSize = 24;
    uint256[] memory input = new uint256[](inputSize);

    for (uint8 i = 0; i < 4; ) {
      uint8 j = i * 6;
      input[j + 0] = p1[i].x;
      input[j + 1] = p1[i].y;
      input[j + 2] = p2[i].x[0];
      input[j + 3] = p2[i].x[1];
      input[j + 4] = p2[i].y[0];
      input[j + 5] = p2[i].y[1];

      unchecked {
        i++;
      }
    }

    uint256[1] memory out;
    bool success;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
      // Use "invalid" to make gas estimation work
      switch success
      case 0 {
        invalid()
      }
    }

    if (!success) {
      revert PairingOpcodeFailed();
    }

    isValid = out[0] != 0;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice A library which provides functions for computing Pedersen hashes.
library PoseidonT3 {
  // solhint-disable-next-line no-empty-blocks
  function poseidon(uint256[2] memory input) public pure returns (uint256) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice A library which provides functions for computing Pedersen hashes.
library PoseidonT4 {
  // solhint-disable-next-line no-empty-blocks
  function poseidon(uint256[3] memory input) public pure returns (uint256) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice A library which provides functions for computing Pedersen hashes.
library PoseidonT5 {
  // solhint-disable-next-line no-empty-blocks
  function poseidon(uint256[4] memory input) public pure returns (uint256) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice A library which provides functions for computing Pedersen hashes.
library PoseidonT6 {
  // solhint-disable-next-line no-empty-blocks
  function poseidon(uint256[5] memory input) public pure returns (uint256) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import { Pairing } from "./Pairing.sol";

/// @title SnarkCommon
/// @notice a Contract which holds a struct
/// representing a Groth16 verifying key
contract SnarkCommon {
  /// @notice a struct representing a Groth16 verifying key
  struct VerifyingKey {
    Pairing.G1Point alpha1;
    Pairing.G2Point beta2;
    Pairing.G2Point gamma2;
    Pairing.G2Point delta2;
    Pairing.G1Point[] ic;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title SnarkConstants
/// @notice This contract contains constants related to the SNARK
/// components of MACI.
contract SnarkConstants {
  /// @notice The scalar field
  uint256 internal constant SNARK_SCALAR_FIELD =
    21888242871839275222246405745257275088548364400416034343698204186575808495617;

  /// @notice The public key here is the first Pedersen base
  /// point from iden3's circomlib implementation of the Pedersen hash.
  /// Since it is generated using a hash-to-curve function, we are
  /// confident that no-one knows the private key associated with this
  /// public key. See:
  /// https://github.com/iden3/circomlib/blob/d5ed1c3ce4ca137a6b3ca48bec4ac12c1b38957a/src/pedersen_printbases.js
  /// Its hash should equal
  /// 6769006970205099520508948723718471724660867171122235270773600567925038008762.
  uint256 internal constant PAD_PUBKEY_X =
    10457101036533406547632367118273992217979173478358440826365724437999023779287;
  uint256 internal constant PAD_PUBKEY_Y =
    19824078218392094440610104313265183977899662750282163392862422243483260492317;

  /// @notice The Keccack256 hash of 'Maci'
  uint256 internal constant NOTHING_UP_MY_SLEEVE =
    8370432830353022751713833565135785980866757267633941821328460903436894336785;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { AccQueue } from "../trees/AccQueue.sol";

/// @title IMACI
/// @notice MACI interface
interface IMACI {
  /// @notice Get the depth of the state tree
  /// @return The depth of the state tree
  function stateTreeDepth() external view returns (uint8);

  /// @notice Return the main root of the StateAq contract
  /// @return The Merkle root
  function getStateAqRoot() external view returns (uint256);

  /// @notice Allow Poll contracts to merge the state subroots
  /// @param _numSrQueueOps Number of operations
  /// @param _pollId The ID of the active Poll
  function mergeStateAqSubRoots(uint256 _numSrQueueOps, uint256 _pollId) external;

  /// @notice Allow Poll contracts to merge the state root
  /// @param _pollId The active Poll ID
  /// @return The calculated Merkle root
  function mergeStateAq(uint256 _pollId) external returns (uint256);

  /// @notice Get the number of signups
  /// @return numsignUps The number of signups
  function numSignUps() external view returns (uint256);

  /// @notice Get the state AccQueue
  /// @return The state AccQueue
  function stateAq() external view returns (AccQueue);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { DomainObjs } from "../utilities/DomainObjs.sol";
import { IMACI } from "./IMACI.sol";
import { AccQueue } from "../trees/AccQueue.sol";
import { TopupCredit } from "../TopupCredit.sol";

/// @title IPoll
/// @notice Poll interface
interface IPoll {
  /// @notice The number of messages which have been processed and the number of signups
  /// @return numSignups The number of signups
  /// @return numMsgs The number of messages sent by voters
  function numSignUpsAndMessages() external view returns (uint256 numSignups, uint256 numMsgs);

  /// @notice Allows to publish a Topup message
  /// @param stateIndex The index of user in the state queue
  /// @param amount The amount of credits to topup
  function topup(uint256 stateIndex, uint256 amount) external;

  /// @notice Allows anyone to publish a message (an encrypted command and signature).
  /// This function also enqueues the message.
  /// @param _message The message to publish
  /// @param _encPubKey An epheremal public key which can be combined with the
  /// coordinator's private key to generate an ECDH shared key with which
  /// to encrypt the message.
  function publishMessage(DomainObjs.Message memory _message, DomainObjs.PubKey calldata _encPubKey) external;

  /// @notice The first step of merging the MACI state AccQueue. This allows the
  /// ProcessMessages circuit to access the latest state tree and ballots via
  /// currentSbCommitment.
  /// @param _numSrQueueOps Number of operations
  /// @param _pollId The ID of the active Poll
  function mergeMaciStateAqSubRoots(uint256 _numSrQueueOps, uint256 _pollId) external;

  /// @notice The second step of merging the MACI state AccQueue. This allows the
  /// ProcessMessages circuit to access the latest state tree and ballots via
  /// currentSbCommitment.
  /// @param _pollId The ID of the active Poll
  function mergeMaciStateAq(uint256 _pollId) external;

  /// @notice The first step in merging the message AccQueue so that the
  /// ProcessMessages circuit can access the message root.
  /// @param _numSrQueueOps The number of subroot queue operations to perform
  function mergeMessageAqSubRoots(uint256 _numSrQueueOps) external;

  /// @notice The second step in merging the message AccQueue so that the
  /// ProcessMessages circuit can access the message root.
  function mergeMessageAq() external;

  /// @notice Returns the Poll's deploy time and duration
  /// @return _deployTime The deployment timestamp
  /// @return _duration The duration of the poll
  function getDeployTimeAndDuration() external view returns (uint256 _deployTime, uint256 _duration);

  /// @notice Get the result of whether the MACI contract's stateAq has been merged by this contract
  /// @return Whether the MACI contract's stateAq has been merged by this contract
  function stateAqMerged() external view returns (bool);

  /// @notice Get the depths of the merkle trees
  /// @return intStateTreeDepth The depth of the state tree
  /// @return messageTreeSubDepth The subdepth of the message tree
  /// @return messageTreeDepth The depth of the message tree
  /// @return voteOptionTreeDepth The subdepth of the vote option tree
  function treeDepths()
    external
    view
    returns (uint8 intStateTreeDepth, uint8 messageTreeSubDepth, uint8 messageTreeDepth, uint8 voteOptionTreeDepth);

  /// @notice Get the max values for the poll
  /// @return maxMessages The maximum number of messages
  /// @return maxVoteOptions The maximum number of vote options
  function maxValues() external view returns (uint256 maxMessages, uint256 maxVoteOptions);

  /// @notice Get the external contracts
  /// @return maci The IMACI contract
  /// @return messageAq The AccQueue contract
  /// @return topupCredit The TopupCredit contract
  function extContracts() external view returns (IMACI maci, AccQueue messageAq, TopupCredit topupCredit);

  /// @notice Get the hash of coordinator's public key
  /// @return _coordinatorPubKeyHash the hash of coordinator's public key
  function coordinatorPubKeyHash() external view returns (uint256 _coordinatorPubKeyHash);

  /// @notice Get the commitment to the state leaves and the ballots. This is
  /// hash3(stateRoot, ballotRoot, salt).
  /// Its initial value should be
  /// hash(maciStateRootSnapshot, emptyBallotRoot, 0)
  /// Each successful invocation of processMessages() should use a different
  /// salt to update this value, so that an external observer cannot tell in
  /// the case that none of the messages are valid.
  /// @return The commitment to the state leaves and the ballots
  function currentSbCommitment() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { TopupCredit } from "../TopupCredit.sol";
import { Params } from "../utilities/Params.sol";
import { DomainObjs } from "../utilities/DomainObjs.sol";

/// @title IPollFactory
/// @notice PollFactory interface
interface IPollFactory {
  /// @notice Deploy a new Poll contract and AccQueue contract for messages.
  /// @param _duration The duration of the poll
  /// @param _maxValues The max values for the poll
  /// @param _treeDepths The depths of the merkle trees
  /// @param _coordinatorPubKey The coordinator's public key
  /// @param _maci The MACI contract interface reference
  /// @param _topupCredit The TopupCredit contract
  /// @param _pollOwner The owner of the poll
  /// @return The deployed Poll contract
  function deploy(
    uint256 _duration,
    Params.MaxValues memory _maxValues,
    Params.TreeDepths memory _treeDepths,
    DomainObjs.PubKey memory _coordinatorPubKey,
    address _maci,
    TopupCredit _topupCredit,
    address _pollOwner
  ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Params } from "./utilities/Params.sol";
import { SnarkCommon } from "./crypto/SnarkCommon.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { EmptyBallotRoots } from "./trees/EmptyBallotRoots.sol";
import { IPoll } from "./interfaces/IPoll.sol";
import { Utilities } from "./utilities/Utilities.sol";
import { CurveBabyJubJub } from "./crypto/BabyJubJub.sol";

/// @title Poll
/// @notice A Poll contract allows voters to submit encrypted messages
/// which can be either votes, key change messages or topup messages.
/// @dev Do not deploy this directly. Use PollFactory.deploy() which performs some
/// checks on the Poll constructor arguments.
contract Poll is Params, Utilities, SnarkCommon, Ownable(msg.sender), EmptyBallotRoots, IPoll {
  using SafeERC20 for ERC20;

  /// @notice Whether the Poll has been initialized
  bool internal isInit;

  /// @notice The coordinator's public key
  PubKey public coordinatorPubKey;

  /// @notice Hash of the coordinator's public key
  uint256 public immutable coordinatorPubKeyHash;

  /// @notice the state root of the state merkle tree
  uint256 public mergedStateRoot;

  // The timestamp of the block at which the Poll was deployed
  uint256 internal immutable deployTime;

  // The duration of the polling period, in seconds
  uint256 internal immutable duration;

  /// @notice Whether the MACI contract's stateAq has been merged by this contract
  bool public stateAqMerged;

  /// @notice Get the commitment to the state leaves and the ballots. This is
  /// hash3(stateRoot, ballotRoot, salt).
  /// Its initial value should be
  /// hash(maciStateRootSnapshot, emptyBallotRoot, 0)
  /// Each successful invocation of processMessages() should use a different
  /// salt to update this value, so that an external observer cannot tell in
  /// the case that none of the messages are valid.
  uint256 public currentSbCommitment;

  /// @notice The number of messages that have been published
  uint256 public numMessages;

  /// @notice The number of signups that have been processed
  /// before the Poll ended (stateAq merged)
  uint256 public numSignups;

  /// @notice Max values for the poll
  MaxValues public maxValues;

  /// @notice Depths of the merkle trees
  TreeDepths public treeDepths;

  /// @notice The contracts used by the Poll
  ExtContracts public extContracts;

  error VotingPeriodOver();
  error VotingPeriodNotOver();
  error PollAlreadyInit();
  error TooManyMessages();
  error InvalidPubKey();
  error StateAqAlreadyMerged();
  error StateAqSubtreesNeedMerge();
  error InvalidBatchLength();

  event PublishMessage(Message _message, PubKey _encPubKey);
  event TopupMessage(Message _message);
  event MergeMaciStateAqSubRoots(uint256 indexed _numSrQueueOps);
  event MergeMaciStateAq(uint256 indexed _stateRoot, uint256 indexed _numSignups);
  event MergeMessageAqSubRoots(uint256 indexed _numSrQueueOps);
  event MergeMessageAq(uint256 indexed _messageRoot);

  /// @notice Each MACI instance can have multiple Polls.
  /// When a Poll is deployed, its voting period starts immediately.
  /// @param _duration The duration of the voting period, in seconds
  /// @param _maxValues The maximum number of messages and vote options
  /// @param _treeDepths The depths of the merkle trees
  /// @param _coordinatorPubKey The coordinator's public key
  /// @param _extContracts The external contracts
  constructor(
    uint256 _duration,
    MaxValues memory _maxValues,
    TreeDepths memory _treeDepths,
    PubKey memory _coordinatorPubKey,
    ExtContracts memory _extContracts
  ) payable {
    // check that the coordinator public key is valid
    if (!CurveBabyJubJub.isOnCurve(_coordinatorPubKey.x, _coordinatorPubKey.y)) {
      revert InvalidPubKey();
    }

    // store the pub key as object then calculate the hash
    coordinatorPubKey = _coordinatorPubKey;
    // we hash it ourselves to ensure we store the correct value
    coordinatorPubKeyHash = hashLeftRight(_coordinatorPubKey.x, _coordinatorPubKey.y);
    // store the external contracts to interact with
    extContracts = _extContracts;
    // store duration of the poll
    duration = _duration;
    // store max values
    maxValues = _maxValues;
    // store tree depth
    treeDepths = _treeDepths;
    // Record the current timestamp
    deployTime = block.timestamp;
  }

  /// @notice A modifier that causes the function to revert if the voting period is
  /// not over.
  modifier isAfterVotingDeadline() {
    uint256 secondsPassed = block.timestamp - deployTime;
    if (secondsPassed <= duration) revert VotingPeriodNotOver();
    _;
  }

  /// @notice A modifier that causes the function to revert if the voting period is
  /// over
  modifier isWithinVotingDeadline() {
    uint256 secondsPassed = block.timestamp - deployTime;
    if (secondsPassed >= duration) revert VotingPeriodOver();
    _;
  }

  /// @notice The initialization function.
  /// @dev Should be called immediately after Poll creation
  /// and messageAq ownership transferred
  function init() public {
    if (isInit) revert PollAlreadyInit();
    // set to true so it cannot be called again
    isInit = true;

    unchecked {
      numMessages++;
    }

    // init messageAq here by inserting placeholderLeaf
    uint256[2] memory dat;
    dat[0] = NOTHING_UP_MY_SLEEVE;
    dat[1] = 0;

    (Message memory _message, PubKey memory _padKey, uint256 placeholderLeaf) = padAndHashMessage(dat, 1);
    extContracts.messageAq.enqueue(placeholderLeaf);

    emit PublishMessage(_message, _padKey);
  }

  /// @inheritdoc IPoll
  function topup(uint256 stateIndex, uint256 amount) public virtual isWithinVotingDeadline {
    // we check that we do not exceed the max number of messages
    if (numMessages >= maxValues.maxMessages) revert TooManyMessages();

    // cannot realistically overflow
    unchecked {
      numMessages++;
    }

    /// @notice topupCredit is a trusted token contract which reverts if the transfer fails
    extContracts.topupCredit.transferFrom(msg.sender, address(this), amount);

    uint256[2] memory dat;
    dat[0] = stateIndex;
    dat[1] = amount;

    (Message memory _message, , uint256 messageLeaf) = padAndHashMessage(dat, 2);

    extContracts.messageAq.enqueue(messageLeaf);

    emit TopupMessage(_message);
  }

  /// @inheritdoc IPoll
  function publishMessage(Message memory _message, PubKey calldata _encPubKey) public virtual isWithinVotingDeadline {
    // we check that we do not exceed the max number of messages
    if (numMessages >= maxValues.maxMessages) revert TooManyMessages();

    // check if the public key is on the curve
    if (!CurveBabyJubJub.isOnCurve(_encPubKey.x, _encPubKey.y)) {
      revert InvalidPubKey();
    }

    // cannot realistically overflow
    unchecked {
      numMessages++;
    }

    // we enforce that msgType here is 1 so we don't need checks
    // at the circuit level
    _message.msgType = 1;

    uint256 messageLeaf = hashMessageAndEncPubKey(_message, _encPubKey);
    extContracts.messageAq.enqueue(messageLeaf);

    emit PublishMessage(_message, _encPubKey);
  }

  /// @notice submit a message batch
  /// @dev Can only be submitted before the voting deadline
  /// @param _messages the messages
  /// @param _encPubKeys the encrypted public keys
  function publishMessageBatch(Message[] calldata _messages, PubKey[] calldata _encPubKeys) external {
    if (_messages.length != _encPubKeys.length) {
      revert InvalidBatchLength();
    }

    uint256 len = _messages.length;
    for (uint256 i = 0; i < len; ) {
      // an event will be published by this function already
      publishMessage(_messages[i], _encPubKeys[i]);

      unchecked {
        i++;
      }
    }
  }

  /// @inheritdoc IPoll
  function mergeMaciStateAqSubRoots(uint256 _numSrQueueOps, uint256 _pollId) public onlyOwner isAfterVotingDeadline {
    // This function cannot be called after the stateAq was merged
    if (stateAqMerged) revert StateAqAlreadyMerged();

    // merge subroots
    extContracts.maci.mergeStateAqSubRoots(_numSrQueueOps, _pollId);

    emit MergeMaciStateAqSubRoots(_numSrQueueOps);
  }

  /// @inheritdoc IPoll
  function mergeMaciStateAq(uint256 _pollId) public onlyOwner isAfterVotingDeadline {
    // This function can only be called once per Poll after the voting
    // deadline
    if (stateAqMerged) revert StateAqAlreadyMerged();

    // set merged to true so it cannot be called again
    stateAqMerged = true;

    // the subtrees must have been merged first
    if (!extContracts.maci.stateAq().subTreesMerged()) revert StateAqSubtreesNeedMerge();

    mergedStateRoot = extContracts.maci.mergeStateAq(_pollId);

    // Set currentSbCommitment
    uint256[3] memory sb;
    sb[0] = mergedStateRoot;
    sb[1] = emptyBallotRoots[treeDepths.voteOptionTreeDepth - 1];
    sb[2] = uint256(0);

    currentSbCommitment = hash3(sb);

    numSignups = extContracts.maci.numSignUps();
    emit MergeMaciStateAq(mergedStateRoot, numSignups);
  }

  /// @inheritdoc IPoll
  function mergeMessageAqSubRoots(uint256 _numSrQueueOps) public onlyOwner isAfterVotingDeadline {
    extContracts.messageAq.mergeSubRoots(_numSrQueueOps);
    emit MergeMessageAqSubRoots(_numSrQueueOps);
  }

  /// @inheritdoc IPoll
  function mergeMessageAq() public onlyOwner isAfterVotingDeadline {
    uint256 root = extContracts.messageAq.merge(treeDepths.messageTreeDepth);
    emit MergeMessageAq(root);
  }

  /// @inheritdoc IPoll
  function getDeployTimeAndDuration() public view returns (uint256 pollDeployTime, uint256 pollDuration) {
    pollDeployTime = deployTime;
    pollDuration = duration;
  }

  /// @inheritdoc IPoll
  function numSignUpsAndMessages() public view returns (uint256 numSUps, uint256 numMsgs) {
    numSUps = numSignups;
    numMsgs = numMessages;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IMACI } from "./interfaces/IMACI.sol";
import { AccQueue } from "./trees/AccQueue.sol";
import { AccQueueQuinaryMaci } from "./trees/AccQueueQuinaryMaci.sol";
import { TopupCredit } from "./TopupCredit.sol";
import { Params } from "./utilities/Params.sol";
import { DomainObjs } from "./utilities/DomainObjs.sol";
import { Poll } from "./Poll.sol";
import { IPollFactory } from "./interfaces/IPollFactory.sol";

/// @title PollFactory
/// @notice A factory contract which deploys Poll contracts. It allows the MACI contract
/// size to stay within the limit set by EIP-170.
contract PollFactory is Params, DomainObjs, IPollFactory {
  // The number of children each node in the message tree has
  uint256 internal constant TREE_ARITY = 5;

  // custom error
  error InvalidMaxValues();

  /// @notice The PollFactory constructor
  // solhint-disable-next-line no-empty-blocks
  constructor() payable {}

  /// @inheritdoc IPollFactory
  function deploy(
    uint256 _duration,
    MaxValues calldata _maxValues,
    TreeDepths calldata _treeDepths,
    PubKey calldata _coordinatorPubKey,
    address _maci,
    TopupCredit _topupCredit,
    address _pollOwner
  ) public virtual returns (address pollAddr) {
    /// @notice Validate _maxValues
    /// maxVoteOptions must be less than 2 ** 50 due to circuit limitations;
    /// it will be packed as a 50-bit value along with other values as one
    /// of the inputs (aka packedVal)
    if (_maxValues.maxVoteOptions >= (2 ** 50)) {
      revert InvalidMaxValues();
    }

    /// @notice deploy a new AccQueue contract to store messages
    AccQueue messageAq = new AccQueueQuinaryMaci(_treeDepths.messageTreeSubDepth);

    /// @notice the smart contracts that a Poll would interact with
    ExtContracts memory extContracts = ExtContracts({
      maci: IMACI(_maci),
      messageAq: messageAq,
      topupCredit: _topupCredit
    });

    // deploy the poll
    Poll poll = new Poll(_duration, _maxValues, _treeDepths, _coordinatorPubKey, extContracts);

    // Make the Poll contract own the messageAq contract, so only it can
    // run enqueue/merge
    messageAq.transferOwnership(address(poll));

    // init Poll
    poll.init();

    poll.transferOwnership(_pollOwner);

    pollAddr = address(poll);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/// @title TopupCredit
/// @notice A contract representing a token used to topup a MACI's voter
/// credits
contract TopupCredit is ERC20, Ownable(msg.sender) {
  uint8 public constant DECIMALS = 1;
  uint256 public constant MAXIMUM_AIRDROP_AMOUNT = 100000 * 10 ** DECIMALS;

  /// @notice custom errors
  error ExceedLimit();

  /// @notice create  a new TopupCredit token
  constructor() payable ERC20("TopupCredit", "TopupCredit") {}

  /// @notice mint tokens to an account
  /// @param account the account to mint tokens to
  /// @param amount the amount of tokens to mint
  function airdropTo(address account, uint256 amount) public onlyOwner {
    if (amount >= MAXIMUM_AIRDROP_AMOUNT) {
      revert ExceedLimit();
    }

    _mint(account, amount);
  }

  /// @notice mint tokens to the contract owner
  /// @param amount the amount of tokens to mint
  function airdrop(uint256 amount) public onlyOwner {
    if (amount >= MAXIMUM_AIRDROP_AMOUNT) {
      revert ExceedLimit();
    }

    _mint(msg.sender, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Hasher } from "../crypto/Hasher.sol";

/// @title AccQueue
/// @notice This contract defines a Merkle tree where each leaf insertion only updates a
/// subtree. To obtain the main tree root, the contract owner must merge the
/// subtrees together. Merging subtrees requires at least 2 operations:
/// mergeSubRoots(), and merge(). To get around the gas limit,
/// the mergeSubRoots() can be performed in multiple transactions.
abstract contract AccQueue is Ownable(msg.sender), Hasher {
  // The maximum tree depth
  uint256 public constant MAX_DEPTH = 32;

  /// @notice A Queue is a 2D array of Merkle roots and indices which represents nodes
  /// in a Merkle tree while it is progressively updated.
  struct Queue {
    /// @notice IMPORTANT: the following declares an array of b elements of type T: T[b]
    /// And the following declares an array of b elements of type T[a]: T[a][b]
    /// As such, the following declares an array of MAX_DEPTH+1 arrays of
    /// uint256[4] arrays, **not the other way round**:
    uint256[4][MAX_DEPTH + 1] levels;
    uint256[MAX_DEPTH + 1] indices;
  }

  // The depth of each subtree
  uint256 internal immutable subDepth;

  // The number of elements per hash operation. Should be either 2 (for
  // binary trees) or 5 (quinary trees). The limit is 5 because that is the
  // maximum supported number of inputs for the EVM implementation of the
  // Poseidon hash function
  uint256 internal immutable hashLength;

  // hashLength ** subDepth
  uint256 internal immutable subTreeCapacity;

  // True hashLength == 2, false if hashLength == 5
  bool internal isBinary;

  // The index of the current subtree. e.g. the first subtree has index 0, the
  // second has 1, and so on
  uint256 internal currentSubtreeIndex;

  // Tracks the current subtree.
  Queue internal leafQueue;

  // Tracks the smallest tree of subroots
  Queue internal subRootQueue;

  // Subtree roots
  mapping(uint256 => uint256) internal subRoots;

  // Merged roots
  uint256[MAX_DEPTH + 1] internal mainRoots;

  // Whether the subtrees have been merged
  bool public subTreesMerged;

  // Whether entire merkle tree has been merged
  bool public treeMerged;

  // The root of the shortest possible tree which fits all current subtree
  // roots
  uint256 internal smallSRTroot;

  // Tracks the next subroot to queue
  uint256 internal nextSubRootIndex;

  // The number of leaves inserted across all subtrees so far
  uint256 public numLeaves;

  /// @notice custom errors
  error SubDepthCannotBeZero();
  error SubdepthTooLarge(uint256 _subDepth, uint256 max);
  error InvalidHashLength();
  error DepthCannotBeZero();
  error SubTreesAlreadyMerged();
  error NothingToMerge();
  error SubTreesNotMerged();
  error DepthTooLarge(uint256 _depth, uint256 max);
  error DepthTooSmall(uint256 _depth, uint256 min);
  error InvalidIndex(uint256 _index);
  error InvalidLevel();

  /// @notice Create a new AccQueue
  /// @param _subDepth The depth of each subtree.
  /// @param _hashLength The number of leaves per node (2 or 5).
  constructor(uint256 _subDepth, uint256 _hashLength) payable {
    /// validation
    if (_subDepth == 0) revert SubDepthCannotBeZero();
    if (_subDepth > MAX_DEPTH) revert SubdepthTooLarge(_subDepth, MAX_DEPTH);
    if (_hashLength != 2 && _hashLength != 5) revert InvalidHashLength();

    isBinary = _hashLength == 2;
    subDepth = _subDepth;
    hashLength = _hashLength;
    subTreeCapacity = _hashLength ** _subDepth;
  }

  /// @notice Hash the contents of the specified level and the specified leaf.
  /// This is a virtual function as the hash function which the overriding
  /// contract uses will be either hashLeftRight or hash5, which require
  /// different input array lengths.
  /// @param _level The level to hash.
  /// @param _leaf The leaf include with the level.
  /// @return _hash The hash of the level and leaf.
  // solhint-disable-next-line no-empty-blocks
  function hashLevel(uint256 _level, uint256 _leaf) internal virtual returns (uint256 _hash) {}

  /// @notice Hash the contents of the specified level and the specified leaf.
  /// This is a virtual function as the hash function which the overriding
  /// contract uses will be either hashLeftRight or hash5, which require
  /// different input array lengths.
  /// @param _level The level to hash.
  /// @param _leaf The leaf include with the level.
  /// @return _hash The hash of the level and leaf.
  // solhint-disable-next-line no-empty-blocks
  function hashLevelLeaf(uint256 _level, uint256 _leaf) public view virtual returns (uint256 _hash) {}

  /// @notice Returns the zero leaf at a specified level.
  /// This is a virtual function as the hash function which the overriding
  /// contract uses will be either hashLeftRight or hash5, which will produce
  /// different zero values (e.g. hashLeftRight(0, 0) vs
  /// hash5([0, 0, 0, 0, 0]). Moreover, the zero value may be a
  /// nothing-up-my-sleeve value.
  /// @param _level The level at which to return the zero leaf.
  /// @return zero The zero leaf at the specified level.
  // solhint-disable-next-line no-empty-blocks
  function getZero(uint256 _level) internal virtual returns (uint256 zero) {}

  /// @notice Add a leaf to the queue for the current subtree.
  /// @param _leaf The leaf to add.
  /// @return leafIndex The index of the leaf in the queue.
  function enqueue(uint256 _leaf) public onlyOwner returns (uint256 leafIndex) {
    leafIndex = numLeaves;
    // Recursively queue the leaf
    _enqueue(_leaf, 0);

    // Update the leaf counter
    numLeaves = leafIndex + 1;

    // Now that a new leaf has been added, mainRoots and smallSRTroot are
    // obsolete
    delete mainRoots;
    delete smallSRTroot;
    subTreesMerged = false;

    // If a subtree is full
    if (numLeaves % subTreeCapacity == 0) {
      // Store the subroot
      subRoots[currentSubtreeIndex] = leafQueue.levels[subDepth][0];

      // Increment the index
      currentSubtreeIndex++;

      // Delete ancillary data
      delete leafQueue.levels[subDepth][0];
      delete leafQueue.indices;
    }
  }

  /// @notice Updates the queue at a given level and hashes any subroots
  /// that need to be hashed.
  /// @param _leaf The leaf to add.
  /// @param _level The level at which to queue the leaf.
  function _enqueue(uint256 _leaf, uint256 _level) internal {
    if (_level > subDepth) {
      revert InvalidLevel();
    }

    while (true) {
      uint256 n = leafQueue.indices[_level];

      if (n != hashLength - 1) {
        // Just store the leaf
        leafQueue.levels[_level][n] = _leaf;

        if (_level != subDepth) {
          // Update the index
          leafQueue.indices[_level]++;
        }

        return;
      }

      // Hash the leaves to next level
      _leaf = hashLevel(_level, _leaf);

      // Reset the index for this level
      delete leafQueue.indices[_level];

      // Queue the hash of the leaves into to the next level
      _level++;
    }
  }

  /// @notice Fill any empty leaves of the current subtree with zeros and store the
  /// resulting subroot.
  function fill() public onlyOwner {
    if (numLeaves % subTreeCapacity == 0) {
      // If the subtree is completely empty, then the subroot is a
      // precalculated zero value
      subRoots[currentSubtreeIndex] = getZero(subDepth);
    } else {
      // Otherwise, fill the rest of the subtree with zeros
      _fill(0);

      // Store the subroot
      subRoots[currentSubtreeIndex] = leafQueue.levels[subDepth][0];

      // Reset the subtree data
      delete leafQueue.levels;

      // Reset the merged roots
      delete mainRoots;
    }

    // Increment the subtree index
    uint256 curr = currentSubtreeIndex + 1;
    currentSubtreeIndex = curr;

    // Update the number of leaves
    numLeaves = curr * subTreeCapacity;

    // Reset the subroot tree root now that it is obsolete
    delete smallSRTroot;

    subTreesMerged = false;
  }

  /// @notice A function that queues zeros to the specified level, hashes,
  /// the level, and enqueues the hash to the next level.
  /// @param _level The level at which to queue zeros.
  // solhint-disable-next-line no-empty-blocks
  function _fill(uint256 _level) internal virtual {}

  /// Insert a subtree. Used for batch enqueues.
  function insertSubTree(uint256 _subRoot) public onlyOwner {
    subRoots[currentSubtreeIndex] = _subRoot;

    // Increment the subtree index
    currentSubtreeIndex++;

    // Update the number of leaves
    numLeaves += subTreeCapacity;

    // Reset the subroot tree root now that it is obsolete
    delete smallSRTroot;

    subTreesMerged = false;
  }

  /// @notice Calculate the lowest possible height of a tree with
  /// all the subroots merged together.
  /// @return depth The lowest possible height of a tree with all the
  function calcMinHeight() public view returns (uint256 depth) {
    depth = 1;
    while (true) {
      if (hashLength ** depth >= currentSubtreeIndex) {
        break;
      }
      depth++;
    }
  }

  /// @notice Merge all subtrees to form the shortest possible tree.
  /// This function can be called either once to merge all subtrees in a
  /// single transaction, or multiple times to do the same in multiple
  /// transactions.
  /// @param _numSrQueueOps The number of times this function will call
  ///                       queueSubRoot(), up to the maximum number of times
  ///                       necessary. If it is set to 0, it will call
  ///                       queueSubRoot() as many times as is necessary. Set
  ///                       this to a low number and call this function
  ///                       multiple times if there are many subroots to
  ///                       merge, or a single transaction could run out of
  ///                       gas.
  function mergeSubRoots(uint256 _numSrQueueOps) public onlyOwner {
    // This function can only be called once unless a new subtree is created
    if (subTreesMerged) revert SubTreesAlreadyMerged();

    // There must be subtrees to merge
    if (numLeaves == 0) revert NothingToMerge();

    // Fill any empty leaves in the current subtree with zeros only if the
    // current subtree is not full
    if (numLeaves % subTreeCapacity != 0) {
      fill();
    }

    // If there is only 1 subtree, use its root
    if (currentSubtreeIndex == 1) {
      smallSRTroot = getSubRoot(0);
      subTreesMerged = true;
      return;
    }

    uint256 depth = calcMinHeight();

    uint256 queueOpsPerformed = 0;
    for (uint256 i = nextSubRootIndex; i < currentSubtreeIndex; i++) {
      if (_numSrQueueOps != 0 && queueOpsPerformed == _numSrQueueOps) {
        // If the limit is not 0, stop if the limit has been reached
        return;
      }

      // Queue the next subroot
      queueSubRoot(getSubRoot(nextSubRootIndex), 0, depth);

      // Increment the next subroot counter
      nextSubRootIndex++;

      // Increment the ops counter
      queueOpsPerformed++;
    }

    // The height of the tree of subroots
    uint256 m = hashLength ** depth;

    // Queue zeroes to fill out the SRT
    if (nextSubRootIndex == currentSubtreeIndex) {
      uint256 z = getZero(subDepth);
      for (uint256 i = currentSubtreeIndex; i < m; i++) {
        queueSubRoot(z, 0, depth);
      }
    }

    // Store the smallest main root
    smallSRTroot = subRootQueue.levels[depth][0];
    subTreesMerged = true;
  }

  /// @notice Queues a subroot into the subroot tree.
  /// @param _leaf The value to queue.
  /// @param _level The level at which to queue _leaf.
  /// @param _maxDepth The depth of the tree.
  function queueSubRoot(uint256 _leaf, uint256 _level, uint256 _maxDepth) internal {
    if (_level > _maxDepth) {
      return;
    }

    uint256 n = subRootQueue.indices[_level];

    if (n != hashLength - 1) {
      // Just store the leaf
      subRootQueue.levels[_level][n] = _leaf;
      subRootQueue.indices[_level]++;
    } else {
      // Hash the elements in this level and queue it in the next level
      uint256 hashed;
      if (isBinary) {
        uint256[2] memory inputs;
        inputs[0] = subRootQueue.levels[_level][0];
        inputs[1] = _leaf;
        hashed = hash2(inputs);
      } else {
        uint256[5] memory inputs;
        for (uint8 i = 0; i < n; i++) {
          inputs[i] = subRootQueue.levels[_level][i];
        }
        inputs[n] = _leaf;
        hashed = hash5(inputs);
      }

      // TODO: change recursion to a while loop
      // Recurse
      delete subRootQueue.indices[_level];
      queueSubRoot(hashed, _level + 1, _maxDepth);
    }
  }

  /// @notice Merge all subtrees to form a main tree with a desired depth.
  /// @param _depth The depth of the main tree. It must fit all the leaves or
  ///               this function will revert.
  /// @return root The root of the main tree.
  function merge(uint256 _depth) public onlyOwner returns (uint256 root) {
    // The tree depth must be more than 0
    if (_depth == 0) revert DepthCannotBeZero();

    // Ensure that the subtrees have been merged
    if (!subTreesMerged) revert SubTreesNotMerged();

    // Check the depth
    if (_depth > MAX_DEPTH) revert DepthTooLarge(_depth, MAX_DEPTH);

    // Calculate the SRT depth
    uint256 srtDepth = subDepth;
    while (true) {
      if (hashLength ** srtDepth >= numLeaves) {
        break;
      }
      srtDepth++;
    }

    if (_depth < srtDepth) revert DepthTooSmall(_depth, srtDepth);

    // If the depth is the same as the SRT depth, just use the SRT root
    if (_depth == srtDepth) {
      mainRoots[_depth] = smallSRTroot;
      treeMerged = true;
      return smallSRTroot;
    } else {
      root = smallSRTroot;

      // Calculate the main root

      for (uint256 i = srtDepth; i < _depth; i++) {
        uint256 z = getZero(i);

        if (isBinary) {
          uint256[2] memory inputs;
          inputs[0] = root;
          inputs[1] = z;
          root = hash2(inputs);
        } else {
          uint256[5] memory inputs;
          inputs[0] = root;
          inputs[1] = z;
          inputs[2] = z;
          inputs[3] = z;
          inputs[4] = z;
          root = hash5(inputs);
        }
      }

      mainRoots[_depth] = root;
      treeMerged = true;
    }
  }

  /// @notice Returns the subroot at the specified index. Reverts if the index refers
  /// to a subtree which has not been filled yet.
  /// @param _index The subroot index.
  /// @return subRoot The subroot at the specified index.
  function getSubRoot(uint256 _index) public view returns (uint256 subRoot) {
    if (currentSubtreeIndex <= _index) revert InvalidIndex(_index);
    subRoot = subRoots[_index];
  }

  /// @notice Returns the subroot tree (SRT) root. Its value must first be computed
  /// using mergeSubRoots.
  /// @return smallSubTreeRoot The SRT root.
  function getSmallSRTroot() public view returns (uint256 smallSubTreeRoot) {
    if (!subTreesMerged) revert SubTreesNotMerged();
    smallSubTreeRoot = smallSRTroot;
  }

  /// @notice Return the merged Merkle root of all the leaves at a desired depth.
  /// @dev merge() or merged(_depth) must be called first.
  /// @param _depth The depth of the main tree. It must first be computed
  ///               using mergeSubRoots() and merge().
  /// @return mainRoot The root of the main tree.
  function getMainRoot(uint256 _depth) public view returns (uint256 mainRoot) {
    if (hashLength ** _depth < numLeaves) revert DepthTooSmall(_depth, numLeaves);

    mainRoot = mainRoots[_depth];
  }

  /// @notice Get the next subroot index and the current subtree index.
  function getSrIndices() public view returns (uint256 next, uint256 current) {
    next = nextSubRootIndex;
    current = currentSubtreeIndex;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { AccQueue } from "./AccQueue.sol";

/// @title AccQueueQuinary
/// @notice This contract defines a Merkle tree where each leaf insertion only updates a
/// subtree. To obtain the main tree root, the contract owner must merge the
/// subtrees together. Merging subtrees requires at least 2 operations:
/// mergeSubRoots(), and merge(). To get around the gas limit,
/// the mergeSubRoots() can be performed in multiple transactions.
/// @dev This contract is for a quinary tree (5 leaves per node)
abstract contract AccQueueQuinary is AccQueue {
  /// @notice Create a new AccQueueQuinary instance
  constructor(uint256 _subDepth) AccQueue(_subDepth, 5) {}

  /// @notice Hash the contents of the specified level and the specified leaf.
  /// @dev it also frees up storage slots to refund gas.
  /// @param _level The level to hash.
  /// @param _leaf The leaf include with the level.
  /// @return hashed The hash of the level and leaf.
  function hashLevel(uint256 _level, uint256 _leaf) internal override returns (uint256 hashed) {
    uint256[5] memory inputs;
    inputs[0] = leafQueue.levels[_level][0];
    inputs[1] = leafQueue.levels[_level][1];
    inputs[2] = leafQueue.levels[_level][2];
    inputs[3] = leafQueue.levels[_level][3];
    inputs[4] = _leaf;
    hashed = hash5(inputs);

    // Free up storage slots to refund gas. Note that using a loop here
    // would result in lower gas savings.
    delete leafQueue.levels[_level];
  }

  /// @notice Hash the contents of the specified level and the specified leaf.
  /// @param _level The level to hash.
  /// @param _leaf The leaf include with the level.
  /// @return hashed The hash of the level and leaf.
  function hashLevelLeaf(uint256 _level, uint256 _leaf) public view override returns (uint256 hashed) {
    uint256[5] memory inputs;
    inputs[0] = leafQueue.levels[_level][0];
    inputs[1] = leafQueue.levels[_level][1];
    inputs[2] = leafQueue.levels[_level][2];
    inputs[3] = leafQueue.levels[_level][3];
    inputs[4] = _leaf;
    hashed = hash5(inputs);
  }

  /// @notice An internal function which fills a subtree
  /// @param _level The level at which to fill the subtree
  function _fill(uint256 _level) internal override {
    while (_level < subDepth) {
      uint256 n = leafQueue.indices[_level];

      if (n != 0) {
        // Fill the subtree level with zeros and hash the level
        uint256 hashed;

        uint256[5] memory inputs;
        uint256 z = getZero(_level);
        uint8 i = 0;
        for (; i < n; i++) {
          inputs[i] = leafQueue.levels[_level][i];
        }

        for (; i < hashLength; i++) {
          inputs[i] = z;
        }
        hashed = hash5(inputs);

        // Update the subtree from the next level onwards with the new leaf
        _enqueue(hashed, _level + 1);
      }

      // Reset the current level
      delete leafQueue.indices[_level];

      _level++;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { MerkleZeros as MerkleQuinaryMaci } from "./zeros/MerkleQuinaryMaci.sol";
import { AccQueueQuinary } from "./AccQueueQuinary.sol";

/// @title AccQueueQuinaryMaci
/// @notice This contract extends AccQueueQuinary and MerkleQuinaryMaci
/// @dev This contract is used for creating a
/// Merkle tree with quinary (5 leaves per node) structure
contract AccQueueQuinaryMaci is AccQueueQuinary, MerkleQuinaryMaci {
  /// @notice Constructor for creating AccQueueQuinaryMaci contract
  /// @param _subDepth The depth of each subtree
  constructor(uint256 _subDepth) AccQueueQuinary(_subDepth) {}

  /// @notice Returns the zero leaf at a specified level
  /// @param _level The level at which to return the zero leaf
  /// @return zero The zero leaf at the specified level
  function getZero(uint256 _level) internal view override returns (uint256 zero) {
    zero = zeros[_level];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract EmptyBallotRoots {
  // emptyBallotRoots contains the roots of Ballot trees of five leaf
  // configurations.
  // Each tree has a depth of 10, which is the hardcoded state tree depth.
  // Each leaf is an empty ballot. A configuration refers to the depth of the
  // voice option tree for that ballot.

  // The leaf for the root at index 0 contains hash(0, root of a VO tree with
  // depth 1 and zero-value 0)

  // The leaf for the root at index 1 contains hash(0, root of a VO tree with
  // depth 2 and zero-value 0)

  // ... and so on.

  // The first parameter to the hash function is the nonce, which is 0.

  uint256[5] internal emptyBallotRoots;

  constructor() {
    emptyBallotRoots[0] = uint256(4904028317433377177773123885584230878115556059208431880161186712332781831975);
    emptyBallotRoots[1] = uint256(344732312350052944041104345325295111408747975338908491763817872057138864163);
    emptyBallotRoots[2] = uint256(19445814455012978799483892811950396383084183210860279923207176682490489907069);
    emptyBallotRoots[3] = uint256(10621810780690303482827422143389858049829670222244900617652404672125492013328);
    emptyBallotRoots[4] = uint256(17077690379337026179438044602068085690662043464643511544329656140997390498741);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract MerkleZeros {
  uint256[33] internal zeros;

  // Quinary tree zeros (Keccak hash of 'Maci')
  constructor() {
    zeros[0] = uint256(8370432830353022751713833565135785980866757267633941821328460903436894336785);
    zeros[1] = uint256(12915444503621073454579416579430905206970714557680052030066757042249102605307);
    zeros[2] = uint256(15825388848727206932541662858173052318786639683743459477657913288690190505308);
    zeros[3] = uint256(20672917177817295069558894035958266756825295443848082659014905185716743537191);
    zeros[4] = uint256(448586013948167251740855715259393055429962470693972912240018559200278204556);
    zeros[5] = uint256(3228865992178886480410396198366133115832717015233640381802715479176981303177);
    zeros[6] = uint256(19116532419590876304532847271428641103751206695152259493043279205958851263600);
    zeros[7] = uint256(13531983203936271379763604150672239370281863210813769735936250692178889682484);
    zeros[8] = uint256(8276490051100115441938424474671329955897359239518198952109759468777824929104);
    zeros[9] = uint256(1234816188709792521426066175633785051600533236493067959807265450339481920006);
    zeros[10] = uint256(14253963034950198848796956783804665963745244419038717333683296599064556174281);
    zeros[11] = uint256(6367560368479067766970398112009211893636892126125767203198799843543931913172);
    zeros[12] = uint256(9086778412328290069463938062555298073857321633960448227011862356090607842391);
    zeros[13] = uint256(1440983698234119608650157588008070947531139377294971527360643096251396484622);
    zeros[14] = uint256(3957599085599383799297196095384587366602816424699353871878382158004571037876);
    zeros[15] = uint256(2874250189355749385170216620368454832544508482778847425177457138604069991955);
    zeros[16] = uint256(21009179226085449764156117702096359546848859855915028677582017987249294772778);
    zeros[17] = uint256(11639371146919469643603772238908032714588430905217730187804009793768292270213);
    zeros[18] = uint256(6279313411277883478350325643881386249374023631847602720184182017599127173896);
    zeros[19] = uint256(21059196126634383551994255775761712285020874549906884292741523421591865338509);
    zeros[20] = uint256(9444544622817172574621750245792527383369133221167610044960147559319164808325);
    zeros[21] = uint256(5374570219497355452080912323548395721574511162814862844226178635172695078543);
    zeros[22] = uint256(4155904241440251764630449308160227499466701168124519106689866311729092343061);
    zeros[23] = uint256(15881609944326576145786405158479503217901875433072026818450276983706463215155);
    zeros[24] = uint256(20831546672064137588434602157208687297579005252478070660473540633558666587287);
    zeros[25] = uint256(3209071488384365842993449718919243416332014108747571544339190291353564426179);
    zeros[26] = uint256(10030934989297780221224272248227257782450689603145083016739151821673604746295);
    zeros[27] = uint256(16504852316033851373501270056537918974469380446508638487151124538300880427080);
    zeros[28] = uint256(5226137093551352657015038416264755428944140743893702595442932837011856178457);
    zeros[29] = uint256(18779994066356991319291039019820482828679702085087990978933303018673869446075);
    zeros[30] = uint256(12037506572124351893114409509086276299115869080424687624451184925646292710978);
    zeros[31] = uint256(12049750997011422639258622747494178076018128204515149991024639355149614767606);
    zeros[32] = uint256(3171463916443906096008599541392648187002297410622977814790586531203175805057);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title DomainObjs
/// @notice An utility contract that holds
/// a number of domain objects and functions
contract DomainObjs {
  /// @notice the length of a MACI message
  uint8 public constant MESSAGE_DATA_LENGTH = 10;

  /// @notice voting modes
  enum Mode {
    QV,
    NON_QV
  }

  /// @title Message
  /// @notice this struct represents a MACI message
  /// @dev msgType: 1 for vote message, 2 for topup message (size 2)
  struct Message {
    uint256 msgType;
    uint256[MESSAGE_DATA_LENGTH] data;
  }

  /// @title PubKey
  /// @notice A MACI public key
  struct PubKey {
    uint256 x;
    uint256 y;
  }

  /// @title StateLeaf
  /// @notice A MACI state leaf
  /// @dev used to represent a user's state
  /// in the state Merkle tree
  struct StateLeaf {
    PubKey pubKey;
    uint256 voiceCreditBalance;
    uint256 timestamp;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IMACI } from "../interfaces/IMACI.sol";
import { AccQueue } from "../trees/AccQueue.sol";
import { TopupCredit } from "../TopupCredit.sol";

/// @title Params
/// @notice This contracts contains a number of structures
/// which are to be passed as parameters to Poll contracts.
/// This way we can reduce the number of parameters
/// and avoid a stack too deep error during compilation.
contract Params {
  /// @notice A struct holding the depths of the merkle trees
  struct TreeDepths {
    uint8 intStateTreeDepth;
    uint8 messageTreeSubDepth;
    uint8 messageTreeDepth;
    uint8 voteOptionTreeDepth;
  }

  /// @notice A struct holding the max values for the poll
  struct MaxValues {
    uint256 maxMessages;
    uint256 maxVoteOptions;
  }

  /// @notice A struct holding the external contracts
  /// that are to be passed to a Poll contract on
  /// deployment
  struct ExtContracts {
    IMACI maci;
    AccQueue messageAq;
    TopupCredit topupCredit;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import { DomainObjs } from "./DomainObjs.sol";
import { Hasher } from "../crypto/Hasher.sol";
import { SnarkConstants } from "../crypto/SnarkConstants.sol";

/// @title Utilities
/// @notice An utility contract that can be used to:
/// * hash a state leaf
/// * pad and hash a MACI message
/// * hash a MACI message and an encryption public key
contract Utilities is SnarkConstants, DomainObjs, Hasher {
  /// @notice custom errors
  error InvalidMessage();

  /// @notice An utility function used to hash a state leaf
  /// @param _stateLeaf the state leaf to be hashed
  /// @return ciphertext The hash of the state leaf
  function hashStateLeaf(StateLeaf memory _stateLeaf) public pure returns (uint256 ciphertext) {
    uint256[4] memory plaintext;
    plaintext[0] = _stateLeaf.pubKey.x;
    plaintext[1] = _stateLeaf.pubKey.y;
    plaintext[2] = _stateLeaf.voiceCreditBalance;
    plaintext[3] = _stateLeaf.timestamp;

    ciphertext = hash4(plaintext);
  }

  /// @notice An utility function used to pad and hash a MACI message
  /// @param dataToPad the data to be padded
  /// @param msgType the type of the message
  /// @return message The padded message
  /// @return padKey The padding public key
  /// @return msgHash The hash of the padded message and encryption key
  function padAndHashMessage(
    uint256[2] memory dataToPad,
    uint256 msgType
  ) public pure returns (Message memory message, PubKey memory padKey, uint256 msgHash) {
    // add data and pad it to 10 elements (automatically cause it's the default value)
    uint256[10] memory dat;
    dat[0] = dataToPad[0];
    dat[1] = dataToPad[1];

    padKey = PubKey(PAD_PUBKEY_X, PAD_PUBKEY_Y);
    message = Message({ msgType: msgType, data: dat });
    msgHash = hashMessageAndEncPubKey(message, padKey);
  }

  /// @notice An utility function used to hash a MACI message and an encryption public key
  /// @param _message the message to be hashed
  /// @param _encPubKey the encryption public key to be hashed
  /// @return msgHash The hash of the message and the encryption public key
  function hashMessageAndEncPubKey(
    Message memory _message,
    PubKey memory _encPubKey
  ) public pure returns (uint256 msgHash) {
    if (_message.data.length != 10) {
      revert InvalidMessage();
    }

    uint256[5] memory n;
    n[0] = _message.data[0];
    n[1] = _message.data[1];
    n[2] = _message.data[2];
    n[3] = _message.data[3];
    n[4] = _message.data[4];

    uint256[5] memory m;
    m[0] = _message.data[5];
    m[1] = _message.data[6];
    m[2] = _message.data[7];
    m[3] = _message.data[8];
    m[4] = _message.data[9];

    msgHash = hash5([_message.msgType, hash5(n), hash5(m), _encPubKey.x, _encPubKey.y]);
  }
}