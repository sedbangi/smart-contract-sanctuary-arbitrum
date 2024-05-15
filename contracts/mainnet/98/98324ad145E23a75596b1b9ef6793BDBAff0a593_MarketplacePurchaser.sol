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
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC3156FlashBorrower.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC3156 FlashBorrower, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 */
interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC3156FlashLender.sol)

pragma solidity ^0.8.20;

import {IERC3156FlashBorrower} from "./IERC3156FlashBorrower.sol";

/**
 * @dev Interface of the ERC3156 FlashLender, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 */
interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.20;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeCast {
    /**
     * @dev Value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedUintDowncast(uint8 bits, uint256 value);

    /**
     * @dev An int value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedIntToUint(int256 value);

    /**
     * @dev Value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedIntDowncast(uint8 bits, int256 value);

    /**
     * @dev An uint value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedUintToInt(uint256 value);

    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        if (value > type(uint248).max) {
            revert SafeCastOverflowedUintDowncast(248, value);
        }
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        if (value > type(uint240).max) {
            revert SafeCastOverflowedUintDowncast(240, value);
        }
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        if (value > type(uint232).max) {
            revert SafeCastOverflowedUintDowncast(232, value);
        }
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        if (value > type(uint224).max) {
            revert SafeCastOverflowedUintDowncast(224, value);
        }
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        if (value > type(uint216).max) {
            revert SafeCastOverflowedUintDowncast(216, value);
        }
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        if (value > type(uint208).max) {
            revert SafeCastOverflowedUintDowncast(208, value);
        }
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        if (value > type(uint200).max) {
            revert SafeCastOverflowedUintDowncast(200, value);
        }
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        if (value > type(uint192).max) {
            revert SafeCastOverflowedUintDowncast(192, value);
        }
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        if (value > type(uint184).max) {
            revert SafeCastOverflowedUintDowncast(184, value);
        }
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        if (value > type(uint176).max) {
            revert SafeCastOverflowedUintDowncast(176, value);
        }
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        if (value > type(uint168).max) {
            revert SafeCastOverflowedUintDowncast(168, value);
        }
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        if (value > type(uint160).max) {
            revert SafeCastOverflowedUintDowncast(160, value);
        }
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        if (value > type(uint152).max) {
            revert SafeCastOverflowedUintDowncast(152, value);
        }
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        if (value > type(uint144).max) {
            revert SafeCastOverflowedUintDowncast(144, value);
        }
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        if (value > type(uint136).max) {
            revert SafeCastOverflowedUintDowncast(136, value);
        }
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        if (value > type(uint128).max) {
            revert SafeCastOverflowedUintDowncast(128, value);
        }
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        if (value > type(uint120).max) {
            revert SafeCastOverflowedUintDowncast(120, value);
        }
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        if (value > type(uint112).max) {
            revert SafeCastOverflowedUintDowncast(112, value);
        }
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        if (value > type(uint104).max) {
            revert SafeCastOverflowedUintDowncast(104, value);
        }
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        if (value > type(uint96).max) {
            revert SafeCastOverflowedUintDowncast(96, value);
        }
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        if (value > type(uint88).max) {
            revert SafeCastOverflowedUintDowncast(88, value);
        }
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        if (value > type(uint80).max) {
            revert SafeCastOverflowedUintDowncast(80, value);
        }
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        if (value > type(uint72).max) {
            revert SafeCastOverflowedUintDowncast(72, value);
        }
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        if (value > type(uint64).max) {
            revert SafeCastOverflowedUintDowncast(64, value);
        }
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        if (value > type(uint56).max) {
            revert SafeCastOverflowedUintDowncast(56, value);
        }
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        if (value > type(uint48).max) {
            revert SafeCastOverflowedUintDowncast(48, value);
        }
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        if (value > type(uint40).max) {
            revert SafeCastOverflowedUintDowncast(40, value);
        }
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        if (value > type(uint32).max) {
            revert SafeCastOverflowedUintDowncast(32, value);
        }
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        if (value > type(uint24).max) {
            revert SafeCastOverflowedUintDowncast(24, value);
        }
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        if (value > type(uint16).max) {
            revert SafeCastOverflowedUintDowncast(16, value);
        }
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        if (value > type(uint8).max) {
            revert SafeCastOverflowedUintDowncast(8, value);
        }
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        if (value < 0) {
            revert SafeCastOverflowedIntToUint(value);
        }
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(248, value);
        }
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(240, value);
        }
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(232, value);
        }
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(224, value);
        }
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(216, value);
        }
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(208, value);
        }
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(200, value);
        }
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(192, value);
        }
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(184, value);
        }
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(176, value);
        }
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(168, value);
        }
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(160, value);
        }
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(152, value);
        }
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(144, value);
        }
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(136, value);
        }
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(128, value);
        }
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(120, value);
        }
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(112, value);
        }
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(104, value);
        }
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(96, value);
        }
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(88, value);
        }
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(80, value);
        }
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(72, value);
        }
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(64, value);
        }
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(56, value);
        }
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(48, value);
        }
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(40, value);
        }
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(32, value);
        }
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(24, value);
        }
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(16, value);
        }
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(8, value);
        }
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        if (value > uint256(type(int256).max)) {
            revert SafeCastOverflowedUintToInt(value);
        }
        return int256(value);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "../dependencies/@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH9 is IERC20 {
  
  event Deposit(address indexed dst, uint wad);
  
  event Withdrawal(address indexed src, uint wad);

  function deposit() external payable;   

  function withdraw(uint wad) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

interface IAddressRegistry {

  event SetAddress (
    address indexed addr,
    bytes32 key
  );

  /**
   * @notice Sets an address for a given key.
   * 
   * @param key The key that defines the address.
   * @param addr The address to assign to the given key.
   */
  function setAddress(bytes32 key, address addr) external;

  /**
   * @notice Returns an address that is defined by the given key.
   * 
   * @param key The key that defines the address.
   * 
   * @return The address that is defined by the given key.
   */
  function getAddress(bytes32 key) external view returns (address);

  /**
   * @notice Returns a list of addresses that are defined by the keys.
   * 
   * @param keys The keys that defines the addresses.
   * 
   * @return The addresses that are defined by the given keys.
   */
  function getAddresses(bytes32[] calldata keys) external view returns (address[] memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import { BPS } from "../../libraries/PercentageMath.sol";

uint16 constant ASSET_FIELD_CUSTODIAN = 0x01;
uint16 constant ASSET_FIELD_PRICE_ORACLE = 0x02;
uint16 constant ASSET_FIELD_MARKETPLACE_ADAPTER = 0x04;
uint16 constant ASSET_FIELD_MAX_SUPPLY = 0x08;
uint16 constant ASSET_FIELD_MAX_LTV = 0x10;
uint16 constant ASSET_FIELD_LIQUIDATION_DISCOUNT = 0x20;
uint16 constant ASSET_FIELD_HOOKS = 0x40;

interface IAssetStorage  {

  struct PortfolioHooks {
    address callback;
    uint16 options; 
  }

  struct Asset {
    address token;
    address custodian;
    address priceOracle;
    address marketplaceAdapter;
    BPS maxLTV;
    BPS liquidationDiscount;
    uint256 maxSupply;
    PortfolioHooks hooks;
  }

  event SetAsset (
    address indexed asset,
    address custodian,
    address priceFeed,
    address marketplaceAdapter,
    BPS maxLTV,
    BPS liquidationDiscount,
    uint256 maxSupply,
    PortfolioHooks hooks  
  );

  /**
   * @notice Adds or updates the asset.
   */
  function setAsset(Asset memory asset) external;

  /**
   * @notice Returns the asset with the given token asset address.
   * 
   * @param token The address of the asset to return.
   * @param mask The bitmask that defines the data to return for the asset.
   * 
   * @return The asset with the specified token asset address.
   */
  function getAsset(address token, uint16 mask) external view returns (Asset memory);

  /**
   * @notice Returns all of the assets that have been registered.
   * 
   * @return The assets that have been registered.
   */
  function getAssets() external view returns (Asset[] memory);

  /**
   * @notice Returns a list of assets with the given token addresses.
   * 
   * @param tokens The list of address of the assets to return.
   * @param mask The bitmask that defines the data to return for the asset.
   * 
   * @return The list of assets with the specified token addresses.
   */
  function getAssets(address[] calldata tokens, uint16 mask) external view returns (Asset[] memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

interface ISanctionList {
  /**
   * @notice Returns a value indicating whether or not the address is the in sanction list.
   * 
   * @param account The account to test whether it is the sanction list.
   * 
   * @return Returns true if the account has been sanctioned.
   */
  function isSanctioned(address account) external view returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

interface IGovernor {

  event Execute(address indexed executable);

  /**
   * @notice Perform the execution.
   * 
   * @param executable The executable component.
   */
  function execute(address executable) external;

  /**
   * @notice Resume the protocol after an emergency shutdown.
   */
  function resume() external;

  /**
   * @notice Forces an emergency shutdown of the protocol.
   */
  function shutdown() external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import { IERC20Burnable } from "../tokens/IERC20Burnable.sol";

interface ITreasury {

  /**
   * @notice Transfer a token from the treasury.
   * 
   * @dev Note that the implementation of this will retstrict the callers to authorized accounts only.
   * 
   * @param token The token to transfer.
   * @param recipient The address to transfer the token to.
   * @param amount The amount of tokens to transfer.
   */
  function transfer(address token, address recipient, uint256 amount) external;

  /**
   * @notice Transfer ETH to from the treasury. 
   * 
   * @dev Note that the implementation of this will retstrict the callers to authorized accounts only.
   * 
   * @param recipient The address to transfer the ETH to.
   * @param amount The amount of ETH to transfer.
   */
  function transferETH(address recipient, uint256 amount) external;

  /**
   * @notice Burn an amount of tokens from the treasury.
   * 
   * @param token The token to burn.
   * @param amount The amount of tokens to burn.
   */
  function burn(IERC20Burnable token, uint256 amount) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

interface ILoyalty {

  event ClaimPoints (address indexed account, uint256 points, uint256 totalPoints);

  event BurnTokens (address indexed account, uint256 amount);

  event SetRewardToken (
    address indexed token, 
    address indexed donor,
    address indexed caller
  );

  event DisableRewardToken (
    address indexed token, 
    address indexed caller
  );

   event RemoveRewardToken (
    address indexed token, 
    address indexed caller
  );

  event Donate (
    address indexed token, 
    address indexed caller, 
    uint256 amount
  );

  event ClaimRewards (
    address indexed account, 
    address indexed token, 
    address indexed caller, 
    uint256 amount
  );

  event ClaimBoost (
    address indexed account, 
    address indexed caller, 
    bytes32 id,
    uint32 boost
  );

  /**
   * @notice Accrued any vesting or pending points for the account.
   * 
   * @param account The account to accrued.
   **/
  function accruePoints(address account) external;
  
  /**
   * @notice Returns the number of points that the account has accrued.
   * 
   * @param account The account to return the points for.
   * 
   * @return The number of points that the user has accrued.
   **/
  function getPoints(address account) external view returns (uint256);

  /**
   * @notice Returns the number of points that the have accrued in the protocol.
   * 
   * @return The number of points for the protocol.
   **/
  function getTotalPoints() external view returns (uint256);

  /**
   * @notice Returns the number of points that are claimable for the account.
   * 
   * @param account The account to return the claimable points for.
   * 
   * @return The number of points that the user has accrued and can claim.
   **/
  function getClaimablePoints(address account) external view returns (uint256);

  /**
   * @notice Claim any accrued the points for the account.
   * 
   * @param account The account to claim the accrued points for.
   **/
  function claimPoints(address account) external;

  /**
   * @notice Burn AMBT tokens in exchange for a permenant supply of boosted points.
   * 
   * @param amount The amount of tokens to burn.
   **/
  function burnTokens(uint256 amount) external;

  /**
   * @notice Sets a token to be tracked for rewards.
   * 
   * @param token The token to track for rewards.
   * @param donor The donor to allow for donating rewards.
   **/
  function setRewardToken(address token, address donor) external;

  /**
   * @notice Disable a token to be tracked for rewards.
   * 
   * @param token The token to disable reward accounting.
   **/
  function disableRewardToken(address token) external;

  /**
   * @notice Remove a reward token.
   * 
   * @dev The token can no longer accrue rewards and unclaimed 
   * rewards will no longer be allowed to be claimed. Once a reward 
   * token has been removed it can no longer be added again.
   * 
   * @param token The token to remove.
   **/
  function removeRewardToken(address token) external;

  /**
   * @notice Gets the tokens that can be tracked for rewards.
   * 
   * @return The list of tokens that can be tracked for rewards.
   **/
  function getRewardTokens() external view returns (address[] memory);

  /**
   * @notice Donate rewards.
   * 
   * @param token The token to donate.
   * @param amount The amount to donate.
   **/
  function donate(address token, uint256 amount) external;

  /**
   * @notice Accrued any pending rewards for the account.
   * 
   * @param account The account to accrue rewards for.
   **/
  function accrueRewards(address account) external;

  /**
   * @notice Claim any pending rewards.
   * 
   * @param account The account to claim the rewards for.
   * @param token The token to claim the rewards for.
   **/
  function claimRewards(address account, address token) external;

  /**
   * @notice Returns the total amount of rewards that are claimable.
   * 
   * @param account The account to check the claimable rewards for.
   * @param token The token to check the claimable rewards for.
   * 
   * @return The total amount of rewards that are claimable.
   **/
  function getClaimableRewards(address account, address token) external view returns (uint256);

  /**
   * @notice Claim the boost for the given account.
   * 
   * @param account The account to claim the boost for.
   * @param id The id of the boost to claim.
   **/
  function claimBoost(address account, bytes32 id) external;

  /**
   * @notice Returns a value indicating whether or not the account is eligible for the boost.
   * 
   * @param account The account to check the eligibility for.
   * @param id The id of the boost to check the eligibility for.
   * 
   * @return true or false depending on whether the account is eligible for the boost.
   **/
  function checkBoostEligibility(address account, bytes32 id) external view returns (bool);

  /**
   * @notice Returns the boost for the given account.
   * 
   * @param account The account to return the boost for.
   **/
  function getBoost(address account) external view returns (uint32);

  /**
   * @notice Returns the underlying token that is used to award loyalty points.
   * 
   * @return The address of the underlying loyaty token.
   **/
  function getLoyaltyToken() external view returns (address);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import { Epoch } from "../../libraries/EpochLib.sol";

interface ILoyaltyStorage {

  struct TotalPoints {
    uint64 balance1;
    uint64 balance2;
    uint128 points;
  }

  struct UserPoints {
    uint64 balance1;
    uint64 balance2;
    uint64 boost;
  }

  struct UserPointsAccrual {
    uint64 accrued;
    uint64 vesting;
    uint64 pending;
    Epoch epoch;
  }

  struct TokenReward {
    uint128 index;
    address donor;
  }

  struct UserReward {
    uint128 index;
    uint128 accrued;
  }

  /**
   * @notice Returns the total points for the protocol.
   * 
   * @return The total points for the protocol.
   **/
  function getTotalPoints() external view returns (TotalPoints memory);

  /**
   * @notice Sets the total points for the protocol.
   * 
   * @param total The total points for the protocol.
   **/
  function setTotalPoints(TotalPoints memory total) external;
  
  /**
   * @notice Returns the user points for an account.
   * 
   * @param account The account to return the points for.
   * 
   * @return The points for the account.
   **/
  function getUserPoints(address account) external view returns (UserPoints memory);

  /**
   * @notice Sets the points for the account.
   * 
   * @param account The account to set the points for.
   * @param points The points to set for the account.
   **/
  function setUserPoints(address account, UserPoints memory points) external;

  /**
   * @notice Returns the points accrual for the account.
   * 
   * @param account The account to return the points accrual for.
   * 
   * @return pointsAccrual The points accrual for the account.
   **/
   function getUserPointsAccrual(address account) external view returns (UserPointsAccrual memory pointsAccrual);

  /**
   * @notice Sets the points accrual for the account.
   * 
   * @param account The account to set the points accrual for.
   * @param pointsAccrual The points accrual to set for the account.
   **/
  function setUserPointsAccrual(address account, UserPointsAccrual memory pointsAccrual) external;

  /**
   * @notice Enables a token to be used for rewards.
   * 
   * @param token The token to enable for rewards accounting.
   **/
  function setRewardToken(address token) external;

  /**
   * @notice Remove a reward token.
   * 
   * @param token The token to remove.
   **/
  function removeRewardToken(address token) external;

  /**
   * @notice Returns a value indicating whether or not the token is enabled.
   * 
   * @param token The token to test whether it is enabled.
   * 
   * @return A value indicating whether the token is enabled for reward accounting.
   **/
  function isRewardToken(address token) external view returns (bool);

  /**
   * @notice Returns a list of enabled reward tokens.
   * 
   * @return The list of enabled reward tokens.
   **/
  function getRewardTokens() external view returns (address[] memory);

  /**
   * @notice Gets the token reward state.
   * 
   * @param token The token to return the reward state for.
   * 
   * @return The token reward state
   **/
  function getTokenReward(address token) external view returns (TokenReward memory);

  /**
   * @notice Sets or updates the token reward state.
   * 
   * @param token The token to update the reward state for.
   * @param tokenReward The token reward state to update.
   **/
  function setTokenReward(address token, TokenReward memory tokenReward) external;

  /**
   * @notice Gets the user reward state.
   * 
   * @param account The account to return the reward state for.
   * @param token The token to return the reward state for.
   * 
   * @return The user reward state
   **/
  function getUserReward(address account, address token) external view returns (UserReward memory);

  /**
   * @notice Sets or updates the user reward state.
   * 
   * @param account The account to update the reward state for.
   * @param token The token to update the reward state for.
   * @param userReward The user reward state to update.
   **/
  function setUserReward(address account, address token, UserReward memory userReward) external;

  /**
   * @notice Sets a claim to the given boost for an account.
   * 
   * @param account The account to set the claim for.
   * @param id The ID of the boost.
   **/
  function setBoostClaim(address account, bytes32 id) external;

  /**
   * @notice Gets a value indicating whether the boost has been claimed.
   * 
   * @param account The account to test.
   * @param id The ID of the boost.
   * 
   * @return A value indicating whether the boost has been claimed.
   **/
  function getBoostClaim(address account, bytes32 id) external view returns (bool);

  /**
   * @notice Sets/registers an available boost module.
   * 
   * @param addr The address of the boost module.
   **/
  function setBoostModule(address addr) external;

  /**
   * @notice Remove an available boost module.
   * 
   * @param id The ID of the module to remove.
   **/
  function removeBoostModule(bytes32 id) external;

  /**
   * @notice Returns the boost module with the given ID.
   * 
   * @param id The ID of the module to return.
   * 
   * @return The address of the boost module.
   **/
  function getBoostModule(bytes32 id) external view returns (address);

  /**
   * @notice Returns a list of the registered boost modules.
   * 
   * @return The list of registered boost modules.
   **/
  function getBoostModules() external view returns (bytes32[] memory, address[] memory);  
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import { IMarketStorage } from "../../interfaces/market/IMarketStorage.sol";

interface IDiscountModel {
  /**
   * @notice Calculate the amount of borrowing that can be considered for a discount.
   * 
   * @param account The account the calculate the discount amount for.
   * @param liability The current user liability state.
   * 
   * @return The amount of borrowing that should be considered for a discount.
   */  
  function calculateDiscountAmount(address account, IMarketStorage.Liability memory liability) external view returns (uint128);

  /**
   * @notice Calculate the discount borrowing rate to apply.
   * 
   * @param rate The current borrowing rate.
   * 
   * @return The discount rate to apply.
   */  
  function calculateDiscountRate(uint128 rate) external view returns (uint128);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

interface IInterestRateModel {
  /**
   * @notice Calculate the interest rate for borrowing from the pool.
   * 
   * @return The interest rate for borrowing from the pool as a WAD (18 decimal places).
   */  
  function calculateRate() external view returns (uint128);  
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import { IPortfolioStorage } from "../../interfaces/portfolio/IPortfolioStorage.sol";
import { IDiscountModel } from "../../interfaces/market/IDiscountModel.sol";
import { IInterestRateModel } from "../../interfaces/market/IInterestRateModel.sol";
import { IPriceOracle } from "../../interfaces/oracle/IPriceOracle.sol";
import { Fees } from "../../libraries/Fees.sol";

interface IMarket {

  event SetBorrowingFee (
    Fees.Parameters feeParameters
  );

  event SetDiscountModel (
    IDiscountModel discountModel,
    address indexed caller
  );

  event SetInterestRateModel (
    IInterestRateModel interestRateModel,
    address indexed caller
  );

  event Borrow (
    address indexed account,
    address indexed receiver,
    uint256 amount,
    uint256 feeAmount
  );

  event Repay (
    address indexed account,
    address indexed repayer,
    uint256 amount
  );

  event AccrueLiabilities (
    address indexed account,
    uint256 liabilities,
    uint256 borrowIndex
  );

  /**
   * @notice Sets the borrowing fee that is applied when accounts borrow from the market.
   * 
   * @dev The borrowing fee is sent to the treasury.
   * 
   * @param fee The fee parameters.
   */  
  function setBorrowingFee(Fees.Parameters memory fee) external;

  /**
   * @notice Gets the borrowing fee.
   * 
   * @return The borrowing fee that is applied when a user borrows from the market.
   */  
  function getBorrowingFee() external view returns (Fees.Parameters memory);
  
  /**
   * @notice Sets the discount model to apply to borrowing.
   * 
   * @param discountModel The discount model to apply to borrowing.
   */ 
  function setDiscountModel(IDiscountModel discountModel) external;

  /**
   * @notice Gets the discount model that is to be applied to borrowing.
   * 
   * @return The discount model to apply to borrowing.
   */ 
  function getDiscountModel() external view returns (IDiscountModel);

  /**
   * @notice Sets the interest rate model to apply to borrowing.
   * 
   * @param interestRateModel The interest rate model to apply to borrowing.
   */ 
  function setInterestRateModel(IInterestRateModel interestRateModel) external;

  /**
   * @notice Gets the interest rate model that is to be applied to borrowing.
   * 
   * @return The interest rate model to apply to borrowing.
   */ 
  function getInterestRateModel() external view returns (IInterestRateModel);

  /**
   * @notice Forces the liabilities to accrue.
   * 
   * @dev This can be called externally by other components that could feed into the liabilties in someway.
   */
  function accrue() external;
  
  /**
   * @notice Accrue the liabilities for an account.
   * 
   * @param account The account to accrue the liabilities for.
   */  
  function accrue(address account) external;

  /**
   * @notice Borrow an amount.
   * 
   * @dev This will fail is the total liabilities would exceed the accounts borrowing limit.
   * 
   * @param amount The amount to borrow.
   */
  function borrow(uint256 amount) external;

  /** 
   * @notice Borrow an amount on behalf of another account.
   * 
   * @dev This can only be called by authorized broker accounts.
   * 
   * @param account The account to borrow from.
   * @param amount The amount to borrow.
   * @param receiver The account that will receive the funds.
   */
  function borrow(address account, uint256 amount, address receiver) external;

  /**
   * @notice Repays an amount towards the accounts current liabilities.
   * 
   * @param amount The amount to repay towards the current liabilities.
   * 
   * @return principal The amount of principal that was repaid.
   * @return interest The amount of interest that was repaid and donated as yield.
   */
  function repay(uint256 amount) external returns (uint256 principal, uint256 interest);

  /**
   * @notice Repays an amount towards an accounts liabilities.
   * 
   * @dev The repayer must be equal to the msg.sender unless the call is coming from
   * authorized callers.
   * 
   * @param account The account to repay the debt for.
   * @param amount The amount to repay towards the current liabilities.
   * @param repayer The account to that is repaying the debt.
   * 
   * @return principal The amount of principal that was repaid.
   * @return interest The amount of interest that was repaid and donated as yield.
   */
  function repay(address account, uint256 amount, address repayer) external returns (uint256 principal, uint256 interest);

  /**
   * @notice Repays all outstanding liabilities.
   * 
   * @dev If an application was to include functionality to allow a user to pay their liabilities, 
   * there would be a delay between when the current liabilities was shown to the user and when the 
   * transaction to repay that debt was executed. During this lag time, additional liabilities can accrue
   * such that even after the user thinks they have paid their debts they would still have some dust 
   * remaining. This method can be used to resolve that scenario.
   * 
   * @return principal The amount of principal that was repaid.
   * @return interest The amount of interest that was repaid and donated as yield.
   */
  function repayOutstandingLiabilities() external returns (uint256 principal, uint256 interest);

  /**
   * @notice Returns the borrowing limit in for an account.
   * 
   * @dev The borrowing limit is denominated in the base asset of the pool.
   * 
   * @param account The account to return the borrowing limit for.
   * @param confidence The confidence level that the prices must exhibit 
   * for them to be included in the borrow limit.
   * 
   * @return The borrowing limit that is available for the list of provided assets.
   */
  function getBorrowLimit(address account, IPriceOracle.Confidence confidence) external view returns (uint256);

  /**
   * @notice Returns the borrowing limit for the list of assets.
   * 
   * @dev The borrowing limit is denominated in the base asset of the pool.
   * 
   * @param portfolioAssets The list of portfolio assets to calculate the borrowing limit for.
   * @param confidence The confidence level that the prices must exhibit 
   * for them to be included in the borrow limit.
   * 
   * @return The borrowing limit that is available for the list of provided assets.
   */
  function getBorrowLimit(IPortfolioStorage.PortfolioAsset[] memory portfolioAssets, IPriceOracle.Confidence confidence) external view returns (uint256);

  /**
   * @notice Returns the outstanding liabilities for an account, including any interest that has accrued.
   * 
   * @dev The liabilities is denominated in the base asset of the pool and this call must include
   * any interest that has accrued up until the current time in which this function is called.
   * 
   * @param account The account to return the liabilities for.
   * 
   * @return The total liabilities that the account has accrued.
   */
  function getLiabilities(address account) external view returns (uint256);

  /**
   * @notice Ensures that the specified account is healthy using the default threshold.
   * 
   * @param account The account to ensure the health of.
   */
  function ensureHealthyAccount(address account) external view;

  /**
   * @notice Ensures that the specified account is healthy.
   * 
   * @dev Test the healh score against the threshold and revert if it is unhealthy.
   * 
   * @param account The account to ensure the health of.
   * @param threshold The threshold to test against the health score.
   */
  function ensureHealthyAccount(address account, uint16 threshold) external view;  
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import { BPS } from "../../libraries/PercentageMath.sol";

interface IMarketLiquidation {

  struct LiquidateParams {
    /// @dev The account to liquidate.
    address account;
    /// @dev The asset to liquidate from the accounts position.
    address asset;
    /// @dev The maximum amount of liabilities to repay.
    uint256 maxAmount;
    /// @dev The total supply to liquidate, this is only valid is maxAmount is 0.
    uint256 totalSupply;
    /// @dev The minimum discount the liquidator is willing to accept on this asset. This is capped at the maximum that is configured for the asset.
    BPS discount;
  }

  event Liquidate (
    address indexed account,
    address indexed liquidator,
    address indexed token,
    uint256 price,
    uint256 repayAmount,
    uint256 refundAmount, 
    uint256 liquidatedSupply
  );

  event SetSmallAccountThreshold (
    uint256 threshold
  );

  /**
   * @notice Sets the liabilities threshold that deems and account to be small.
   * 
   * @dev An account with liabilities under the threshold can be liquidated fully is possible.
   * 
   * @param threshold The liabilities threshold that deems a small account.
   */  
  function setSmallAccountThreshold(uint256 threshold) external;

  /**
   * @notice Gets the liabilities threshold that deems and account to be small.
   * 
   * @return The liabilities threshold that deems a small account.
   */  
  function getSmallAccountThreshold() external view returns (uint256);

  /**
   * @notice Returns a value indicating whether the account is liquidating.
   * 
   * @param account The account to check the liquidation status.
   * 
   * @return Returns true if the account can be liquidated.
   */  
  function isLiquidatable(address account) external view returns (bool);

  /**
   * @notice Liquidate an account up the maximum amount.
   * 
   * @dev The minimum discount allows liquidators to act in good faith if the 
   * position is insolvent to reduce bad debt.
   * 
   * @param params The parameters to perform the liquidation with.
   * 
   * @return asset The asset that is to be liquidated.
   * @return liquidatedSupply The total supply that was liquidated.
   * @return repayPrincipalAmount The amount that was repaid towards the principal of the account debt.
   * @return repayInterestAmount The amount that was repaid towards the interest of the account debt.
   * @return refundAmount The total amount that was refunded to the account.
   */  
  function liquidate(LiquidateParams memory params) external returns (
    address asset, 
    uint256 liquidatedSupply, 
    uint256 repayPrincipalAmount,
    uint256 repayInterestAmount,
    uint256 refundAmount);

  /**
   * @notice Forces a liquidation of an asset from an account up the maximum amount.
   * 
   * @dev This is an admin controlled function that will be used in emergency situations.
   * 
   * @param params The parameters to perform the liquidation with.
   * 
   * @return asset The asset that is to be liquidated.
   * @return liquidatedSupply The total supply that was liquidated.
   * @return repayPrincipalAmount The amount that was repaid towards the principal of the account debt.
   * @return repayInterestAmount The amount that was repaid towards the interest of the account debt.
   * @return refundAmount The total amount that was repaid on the liabilties.
   */  
  function forceLiquidate(LiquidateParams memory params) external returns (
    address asset, 
    uint256 liquidatedSupply, 
    uint256 repayPrincipalAmount,
    uint256 repayInterestAmount,
    uint256 refundAmount);

  /**
   * @notice Finds the position that is most favorble to the health of the account.
   * 
   * @dev This will return the asset that is the most favorable to liquidate to return
   * the accounts position as close to healthy as possible.
   * 
   * @param account The account to return the position for.
   * 
   * @return asset The asset that is to be liquidated.
   * @return total The total amount in USD that the asset contributes to the position.
   */ 
  function findMostFavorablePosition(address account) external view returns (address asset, uint256 total);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

interface IMarketStorage  {

  struct Liability {
    uint128 borrowed;
    uint128 liabilities;
  }

  struct MarketState {
    uint128 borrowIndex;
    uint128 discountIndex;
    uint40 lastUpdate;
  }

  struct UserState {
    uint128 borrowIndex;
    uint128 discountIndex;
  }

  function getMarketState() external view returns (MarketState memory);

  function setMarketState(MarketState calldata marketState) external;

  function getMarketLiability() external view returns (Liability memory);

  function setMarketLiability(Liability calldata marketLiability) external;

  function getUserState(address account) external view returns (UserState memory);

  function setUserState(address account, UserState calldata userState) external;

  function getUserLiability(address account) external view returns (Liability memory);

  function setUserLiability(address account, Liability calldata userLiability) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

interface IMarketplaceAdapter {
  /**
   * @notice Execute the operation on the adapter.
   * 
   * @dev This is designed such that the execute data is computed off-chain.
   * 
   * @param data The call data to execute.
   * 
   * @return amountOut The amount that was returned from the operation.
   */
  function execute(bytes memory data) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

interface IMarketplacePurchaser  {

  struct Parameters {
    /// @param token The token to add with leverage.
    address token;
    /// @param amount The total amount of the loan to spend on the asset (includes fees).
    uint256 amount;
    /// @param executionData The data to execute on the marketplace adapter.
    bytes executionData;
  }

  /**
   * @notice Make a purchase of an asset into the accounts portfolio.
   * 
   * @param params The parameters to use for the operation.
   */  
  function buy(Parameters calldata params) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

interface IMarketplaceVendor {

  struct Parameters {
    /// @param token The token to sell from the accounts portfolio.
    address token;     
    /// @param amount The amount of the asset to sell.
    uint256 amount;
    /// @param repayAmount The amount to repay towards any outstanding liabilities.
    uint256 repayAmount;
     /// @param amountOutMinimum The minimum amount out.
    uint256 amountOutMinimum; 
    /// @param executionData The data to execute on the marketplace adapter.
    bytes executionData;
  }

  /**
   * @notice Sell the given amount of an asset into USDT into the accounts portfolio.
   * 
   * @param params The params to make the sale.
   */
  function sell(Parameters calldata params) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import { USD } from "../../libraries/USDMath.sol";

interface IPriceOracle {

  enum Status { 
    ONLINE, 
    OFFLINE 
  }

  /// @dev do not reorder this list
  enum Confidence {
    /// @dev the price should be accepted.
    OK,
    /// @dev the price was available, but it was stale.
    STALE,
    /// @dev the price was not available.
    OFFLINE
  }

  /**
   * @notice Returns the price of an asset according to its configured Oracle.
   * 
   * @dev The price is denominated in USD to a precision of 8 decimals places.
   * 
   * @return price The current price of the asset denominated in USD.
   * @return confidence The confidence level that the price has.
   */  
  function getLatestPrice() external view returns (USD price, Confidence confidence);

  /**
   * @notice Returns the status of the Oracle.
   * 
   * @return status The current status of the oracle.
   * @return changedAt The timestamp at which the status was changed.
   */
  function getStatus() external view returns (Status status, uint256 changedAt);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import { IVault } from "../vault/IVault.sol";

interface ICustodian is IVault {

  event Supply (
    address indexed caller,
    address indexed supplier,
    address indexed asset,
    uint256 amount,
    uint256 shares
  );
  
  event Withdraw (
    address indexed caller,
    address indexed receiver,
    address indexed asset,
    uint256 amount,
    uint256 shares
  );

  /**
   * @notice Returns the total assets that are included in the vault.
   * 
   * @return The total supply for the underlying asset in the vault.
   */
  function getTotalAssets() external view returns (uint256);

  /**
   * @notice Returns the total number of shares for the vault.
   * 
   * @return The total number of shares for the the vault.
   */
  function getTotalShares() external view returns (uint256);

  /**
   * @notice Returns the number of shares that would be exchanged for the amount under ideal conditions.
   * 
   * @param amount The amount that will be convert to shares.
   * 
   * @return shares The total number of shares that would represent the given amount.
   */
  function toShares(uint256 amount) external view returns (uint256 shares);

  /**
   * @notice Returns the amount of assets that would be returned from the number of shares under ideal conditions.
   * 
   * @param shares The number of shares to convert to an amount of assets.
   * 
   * @return amount The amount that would represent the given number of shares at the current block.
   */
  function toAssets(uint256 shares) external view returns (uint256 amount);

  /**
   * @notice Allows an on-chain or off-chain user to simulate the effects of a 
   * supply at the current block, given current on-chain conditions.
   * 
   * @dev This should take into account any fees or slippage that would be incurred.
   * 
   * @param amount The amount of assets that will be supplied.
   * 
   * @return shares The total shares that would be returned based on the current on-chain state.
   */
  function previewSupply(uint256 amount) external view returns (uint256 shares);

  /**
   * @notice Supplies an amount of the underlying asset from the account to the custodian. 
   * 
   * @param supplier The account to supply the assets from.
   * @param amount The amount of the underlying asset to supply.
   * 
   * @return shares The total number of shares that were supplied.
   */
  function supply(address supplier, uint256 amount) external returns (uint256 shares);

  /**
   * @notice Allows an on-chain or off-chain user to simulate the effects of a 
   * withdraw at the current block, given current on-chain conditions.
   * 
   * @dev This should take into account any fees or slippage that would be incurred.
   * 
   * @param amount The amount that will be withdrawn.
   * 
   * @return shares The total number of shares that would be withdrawn based on the current on-chain state.
   */
  function previewWithdraw(uint256 amount) external view returns (uint256 shares);
  
  /**
   * @notice Withdraws an amount of the underlying asset from the custodian to the account. 
   * 
   * @param receiver The account to withdraw the assets to.
   * @param amount The amount to withdraw.
   * 
   * @return shares The total number of shares that were withdran.
   */
  function withdraw(address receiver, uint256 amount) external returns (uint256 shares);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import { IPortfolioStorage } from "./IPortfolioStorage.sol";
import { USD } from "../../libraries/USDMath.sol";

interface IPortfolio {

  event Supply (
    address indexed account,
    address indexed supplier,
    address indexed asset,
    uint256 amount,
    uint256 shares,
    address caller
  );

  event SupplyETH (
    address indexed account,
    uint256 amount,
    uint256 shares,
    address caller
  );

  event Withdraw (
    address indexed account,
    address indexed asset,
    uint256 amount,
    uint256 shares,
    address caller
  );

  event WithdrawETH (
    address indexed account,
    uint256 amount,
    uint256 shares,
    address caller
  );

  /**
   * @notice Supply the an asset as collateral towards the accounts portfolio value.
   * 
   * @param asset The asset to supply.
   * @param amount The amount of the asset to supply.
   * 
   * @return shares The total number of shares that were supplied.
   */  
  function supply(address asset, uint256 amount) external returns (uint256 shares);

  /**
   * @notice Supply the an asset towards the accounts portfolio value.
   * 
   * @dev Only privileged accounts can call this method.
   * 
   * @param account The account to supply the assets to.
   * @param asset The asset to supply.
   * @param amount The amount of the asset to supply.
   * 
   * @return shares The total number of shares that were supplied.
   */  
  function supply(address account, address asset, uint256 amount) external returns (uint256 shares);

  /**
   * @notice Supply the native asset as collateral towards the accounts portfolio value.
   * 
   * @dev The amount to be supplied is sent along with the transaction.
   * 
   * @return shares The total number of shares that were supplied.
   */  
  function supplyETH() external payable returns (uint256 shares);

  /**
   * @notice Withdraw an asset from the accounts portfolio.
   * 
   * @dev This will fail if the are encumbrances from the market with regards to liabilities. 
   * 
   * @param asset The asset to withdraw.
   * @param amount The amount to withdraw.
   * 
   * @return shares The total number of shars that were withdrawn.
   */  
  function withdraw(address asset, uint256 amount) external returns (uint256 shares);

  /**
   * @notice Withdraw the an asset as from the accounts portfolio value.
   * 
   * @dev Only privileged accounts can call this method. Callers of this method much ensure
   * the healthy state of the account after the withdraw method as it is not called internally.
   * 
   * @param account The account to withdraw the assets from.
   * @param receiver The address of the account to receive the assets.
   * @param asset The asset to withdraw.
   * @param amount The total amount to withdraw.
   * 
   * @return shares The number of shares that were withdrawn.
   */  
  function withdraw(address account, address receiver, address asset, uint256 amount) external returns (uint256 shares);

  /**
   * @notice Withdraw the native asset from the accounts portfolio.
   * 
   * @dev This will fail if the are encumbrances from the market with regards to liabilities.
   * 
   * @param amount The amount to withdraw.
   * 
   * @return shares The total number of shares that were withdrawn.
   */  
  function withdrawETH(uint256 amount) external returns (uint256 shares);

  /**
   * @notice Returns the total value of the users portfolio denominated in USD.
   * 
   * @param account The account to return the portfolio value for.
   * 
   * @return The total portfolio value for the account denominated in USD.
   */
  function getPortfolioValue(address account) external view returns (USD);

  /**
   * @notice Returns the total value of the supplied asset position.
   * 
   * @param position The asset position to calculate the total value for.
   * 
   * @return The total value for the position denominated 
   * in USD along with the total for each of the individual positions.
   */
  function getPortfolioValue(IPortfolioStorage.PortfolioAsset[] memory position) external view returns (USD, USD[] memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

uint16 constant PORTFOLIO_ASSET_FIELD_SHARES = 0x01;
uint16 constant PORTFOLIO_ASSET_FIELD_LAST_UPDATE_BLOCK = 0x02;

interface IPortfolioStorage {

  struct PortfolioAsset {
    address token;
    uint256 shares;
    uint256 lastUpdateBlock;
  }

  /**
   * @notice Returns the count of assets that a user has in their portfolio.
   * 
   * @param account The account to return the count of assets for.
   * 
   * @return The count of assets in the accounts portfolio.
   */
  function getCount(address account) external view returns (uint256);

  /**
   * @notice Returns assets that have been added to the portfolio of the account.
   * 
   * @param account The account to return the assets for.
   * @param mask The bitmask that defines the data to return.
   * 
   * @return The list of assets that have been added to the account.
   */
  function getPortfolioAssets(address account, uint16 mask) external view returns (PortfolioAsset[] memory);

  /**
   * @notice Returns a single assets from the accounts portfolio.
   * 
   * @param account The account to return the assets for.
   * @param token The token address of the asset to return.
   * @param mask The bitmask that defines the data to return.
   * 
   * @return The asset with with the given token address.
   */
  function getPortfolioAsset(address account, address token, uint16 mask) external view returns (PortfolioAsset memory);

  /**
   * @notice Increase the number of shares for a specific asset.
   * 
   * @param account The account to increase the shares for.
   * @param token The token address of the asset to increase the shares for.
   * @param shares The number of additional shares to add.
   * 
   * @return The total shares for the token and account.
   */
  function increaseShares(address account, address token, uint256 shares) external returns (uint256);

  /**
   * @notice Decrease the number of shares for a specific asset.
   * 
   * @param account The account to decrease the shares for.
   * @param token The token address of the asset to decrease the shares for.
   * @param shares The number of additional shares to remove.
   * 
   * @return The total shares for the token and account.
   */
  function decreaseShares(address account, address token, uint256 shares) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

bytes32 constant ADMIN_ROLE = 0xdf8b4c520ffe197c5343c6f5aec59570151ef9a492f2c624fd45ddde6135ec42; // ADMIN
bytes32 constant EMERGENCY_ADMIN_ROLE = 0x5c91514091af31f62f596a314af7d5be40146b2f2355969392f055e12e0982fb; // EMERGENCY_ADMIN

interface IAccessControlList {

  event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

  event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

  /**
   * @notice Returns a value indicating whether or not the account has the specified role.
   * 
   * @param role The role to test for.
   * @param account The account to test for the role.
   * 
   * @return Returns `true` if the account has the role, `false' if it doesnt.
   */
  function hasRole(bytes32 role, address account) external view returns (bool);

  /**
   * @notice Grants a role to the account.
   * 
   * @param role The role to grant.
   * @param account The account to grant the role to.
   */
  function grantRole(bytes32 role, address account) external;

  /**
   * @notice Revokes a role from the account.
   * 
   * @param role The role to revoke.
   * @param account The account to revoke the role from.
   */
  function revokeRole(bytes32 role, address account) external;

  /**
   * @notice Renounce a role from the calling account.
   * 
   * @dev This can be used by the account itself to revoke roles that were assigned to it.
   * 
   * @param role The role to revoke.
   * @param account The account to renounce the role from. This must be the callers account.
   */
  function renounceRole(bytes32 role, address account) external;

  /**
   * @notice Returns the list of members for a role.
   * 
   * @param role The role to return the list of members for.
   *
   * @return The list of members that exists in the role.
   */
  function getMembers(bytes32 role) external view returns (address[] memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import { IERC20Metadata } from "../../dependencies/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IERC20Burnable is IERC20Metadata {
  /**
   * @dev Destroys `amount` tokens from the caller.
   *
   * See {ERC20-_burn}.
   */
  function burn(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import { IERC20 } from "../../dependencies/@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface ISweepable {
  event Sweep(
    address indexed caller, 
    address indexed treasury, 
    address indexed token, 
    uint256 amount
  );

  event SweepETH(
    address indexed caller, 
    address indexed treasury, 
    uint256 amount
  );

  /** 
   * @notice Sends a given amount of a token to the treasury.
   * 
   * @param token The token to send to the treasury.
   * @param amount The amount to send to the treasury.
   */
  function sweep(IERC20 token, uint256 amount) external;

  /** 
   * @notice Sweeps the given amount of ETH to the treasury.
   * 
   * @param amount The amount to send to the treasury.
   */
  function sweepETH(uint256 amount) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import { IDepositorVaultStorage } from "./IDepositorVaultStorage.sol";
import { IDepositorVaultToken } from "./IDepositorVaultToken.sol";
import { IYieldVault } from "./IYieldVault.sol";
import { BPS } from "../../libraries/PercentageMath.sol";
import { Fees } from "../../libraries/Fees.sol";

interface IDepositorVault is IYieldVault {

  struct Snapshot {
    uint32 timestamp;
    uint128 totalLiabilities;
    uint256 totalAssets;
    uint256 totalShares;
  } 

  event SetBorrowLimit (
    address indexed caller, 
    address indexed borrower, 
    uint256 amount,
    IDepositorVaultStorage.AbsoluteOrRelative absoluteOrRelative
  );

  event SetReserveBPS (
    address indexed caller, 
    BPS bps
  );

  event SetMaxSupply (
    address indexed caller, 
    uint256 maxSupply
  );

  event SetDonationFee (
    address indexed caller, 
    Fees.Parameters feeParameters
  );

  event Borrow (
    address indexed borrower, 
    address indexed receiver, 
    uint256 amount,
    address indexed feeReceiver, 
    uint256 feeAmount
  );

  event Repay (
    address indexed borrower, 
    uint256 amount
  );

  event Deposit(
    address indexed sender, 
    uint256 assets, 
    uint256 shares
  );

  event Withdraw(
    address indexed sender,
    uint256 assets,
    uint256 shares
  );

  event Redeem(
    address indexed sender,
    uint256 shares,
    uint256 assets  
  );

  /**
   * @notice Returns the borrowing limit for the given account taking into account the current state of the vault.
   * 
   * @param account The borrower to return the borrowing limit for.
   * 
   * @return The borrowing limit for the given borrower.
   */
  function getBorrowLimit(address account) external view returns (uint256);

  /**
   * @notice Sets the borrowing limit for a given borrower.
   * 
   * @param account The borrower to set the borrowing limit for.
   * @param amount The borrowing limit relative to the limitType.
   * @param absoluteOrRelative The type that defines the limit.
   */
  function setBorrowLimit(address account, uint256 amount, IDepositorVaultStorage.AbsoluteOrRelative absoluteOrRelative) external;

  /**
   * @notice Returns the reserve BPS.
   * 
   * @return The reserve BPS.
   */
  function getReserveBPS() external view returns (BPS);

  /**
   * @notice Sets the reserve BPS.
   * 
   * @param bps The reserve BPS.
   */
  function setReserveBPS(BPS bps) external;

  /**
   * @notice Returns the maximum that can be supplied to the vault.
   * 
   * @return The maximum total assets that can be supplied to the vault.
   */
  function getMaxSupply() external view returns (uint256);

  /**
   * @notice Sets the maximum supply cap for the vault.
   * 
   * @param maxSupply The maximum supply cap that should apply to new deposits.
   */
  function setMaxSupply(uint256 maxSupply) external;

  /**
   * @notice Sets the fee that is applied to donations and sent to the treasury.
   * 
   * @dev The fee amount to send to the treasury.
   * 
   * @param fee The fee parameters.
   */  
  function setDonationFee(Fees.Parameters memory fee) external;

  /**
   * @notice Gets the donation fee.
   * 
   * @return The fee that is applied to a donation to send to the treasury.
   */  
  function getDonationFee() external view returns (Fees.Parameters memory);

  /**
   * @notice Returns a history of snapshots of the depositor vault state that 
   * is closest but not exceeding the specified timestamp.
   * 
   * @param timestamp The timestamp to return the snapshots from.
   * @param count The number of snapshots to return.
   * 
   * @return snapshots The snapshot history starting from the timestamp.
   */
  function findSnapshots(uint32 timestamp, uint256 count) external view returns (Snapshot[] memory snapshots);

  /**
   * @notice Take a snapshot of the current vault state.
   */
  function takeSnapshot() external;

  /**
   * @notice Returns the borrowable amount for a borrower. This is different to the borrowable limit as that is a 
   * theoretical limit whereas the borrow amount takes into account current liabilities and the vault reserves.
   * 
   * @param account The borrower to return the borrowable amount for.
   * 
   * @return The borrowable amount for the given borrower.
   */
  function getBorrowableAmount(address account) external view returns (uint256);

   /**
   * @notice Returns the utilization of a borrower.
   * 
   * @dev The utilization is returned as a WAD (18 decimal places).
   * 
   * @param account The borrower to return the utilization for.
   * 
   * @return The utilization of the borrower account.
   */
  function getBorrowerUtilization(address account) external view returns (uint256);

  /**
   * @notice Borrows an amount from the vault.
   * 
   * @dev Borrowing from the vault is limited to approved protocols and each could 
   * have its own fee structure. Therefore we just allow fees to be included and
   * transferred from the pool without the pool having to calculate the actual fee.
   * 
   * @param amount The amount to borrow including any fee that is to be paid.
   * @param receiver The receiver that the assets should be transferred to.
   * @param feeAmount The amount that should charged of a fee.
   * @param feeReceiver The receiver that the fee should be transferred to.
   */
  function borrow(uint256 amount, address receiver, uint256 feeAmount, address feeReceiver) external;

  /**
   * @notice Repays and amount to the vault
   * 
   * @param amount The amount to pay to the vault is yield.
   */
  function repay(uint256 amount) external;

  /**
   * @notice Mints shares in the vault to receiver by depositing exactly amount of underlying tokens.
   *
   * @param amount The amount of assets to deposit into the vault.
   * @param minSharesOut The minimum number of shares that should be minted.
   * 
   * @return The total shares in the vault that were deposited
   */
  function deposit(uint256 amount, uint256 minSharesOut) external returns (uint256);

  /**
   * @notice Allows an on-chain or off-chain user to simulate the effects of their 
   * deposit at the current block, given current on-chain conditions.
   * 
   * @param amount The amount of assets that will be deposited.
   * 
   * @return shares The total shares that would be returned based on the current on-chain state.
   */
  function previewDeposit(uint256 amount) external view returns (uint256 shares);

  /**
   * @notice Burns shares from owner and sends exactly assets of underlying tokens to receiver.
   *
   * @param amount The amount of assets to burn from the owner.
   * @param maxSharesOut The maximum number of shares that should be burned.
   * 
   * @return The total shares that were withdrawn from the vault.
   */
  function withdraw(uint256 amount, uint256 maxSharesOut) external returns (uint256);

  /**
   * @notice Allows an on-chain or off-chain user to simulate the effects of their 
   * withdraw at the current block, given current on-chain conditions.
   * 
   * @param amount The amount of assets that will be withdrawn.
   * 
   * @return shares The total shares that would be withdrawn based on the current on-chain state.
   */
  function previewWithdraw(uint256 amount) external view returns (uint256 shares);

  /**
   * @notice Burns exactly shares from owner and sends assets of underlying tokens to receiver.
   *
   * @param shares The amount of shares to burn.
   * @param minAmountOut The minimum number of assets that should be returned.
   * 
   * @return The total assets that were withdrawn from the vault.
   */
  function redeem(uint256 shares, uint256 minAmountOut) external returns (uint256);

  /**
   * @notice Allows an on-chain or off-chain user to simulate the effects of their 
   * redemption at the current block, given current on-chain conditions.
   * 
   * @param shares The amount of shares that will be redeemed.
   * 
   * @return amount The total amount that would be redeemed based on the current on-chain state.
   */
  function previewRedeem(uint256 shares) external view returns (uint256 amount);

  /**
   * @notice Returns the vault token that represents the accounts share.
   * 
   * @return The token that represents the accounts share in the vault.
   */
  function getToken() external view returns (IDepositorVaultToken);

  /**
   * @notice Returns the total liabilities for all borrowers from the vault.
   * 
   * @return The total liabilities for all borrowers.
   */
  function getTotalLiabilities() external view returns (uint256);
  
  /**
   * @notice Returns the total liabilities for a given borrower.
   * 
   * @return The liabilities for the given borrower.
   */
  function getLiabilities(address account) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

interface IDepositorVaultStorage  {

  enum AbsoluteOrRelative { 
    ABSOLUTE, // an absolute amount
    RELATIVE // an amount relative to the total value of the vault, ie a percentage
  }

  struct BorrowLimit {
    AbsoluteOrRelative absoluteOrRelative;
    uint256 amount;
  }

  /**
   * @notice Returns the borrowing limit for the given account taking into account the current state of the vault.
   * 
   * @param account The borrower to return the borrowing limit for.
   * 
   * @return The borrowing limit for the given borrower.
   */
  function getBorrowLimit(address account) external view returns (BorrowLimit memory);

  /**
   * @notice Sets the borrowing limit for a given borrower.
   * 
   * @param account The borrower to set the borrowing limit for.
   * @param borrowLimit The borrowing limit to set for the account.
   */
  function setBorrowLimit(address account, BorrowLimit calldata borrowLimit) external;

  /**
   * @notice Returns the liabilities for an account.
   * 
   * @param account The account to return the liabilities for.
   */
  function getLiabilities(address account) external view returns (uint256);

  /**
   * @notice Returns the total liabilities for all accounts.
   */
  function getTotalLiabilities() external view returns (uint256);

  /**
   * @notice Increase the total liabilities for an account.
   * 
   * @param account The account to increase the liabilities for.
   * @param amount The total amount to increase the liabilities for.
   */
  function increaseLiabilities(address account, uint128 amount) external;

  /**
   * @notice Decrease the total liabilities for an account.
   * 
   * @param account The account to decrease the liabilities for.
   * @param amount The total amount to decrease the liabilities for.
   */
  function decreaseLiabilities(address account, uint128 amount) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import { IERC20Metadata } from "../../dependencies/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IDepositorVaultToken is IERC20Metadata { 

  event Mint(address indexed account, uint256 amount);

  event Burn(address indexed account, uint256 amount);

  /**
   * @notice Mint tokens for an account.
   * 
   * @param account The account to mint the tokens for.
   * @param amount The amount of tokens to mint.
   */
  function mint(address account, uint256 amount) external;

  /**
   * @notice Burn tokens from an account.
   * 
   * @param account The account to burn the tokens from.
   * @param amount The amount of tokens to burn.
   */
  function burn(address account, uint256 amount) external;  
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import { IERC3156FlashLender } from "../../dependencies/@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import { ISweepable } from "../../interfaces/utils/ISweepable.sol";
import { BPS } from "../../libraries/PercentageMath.sol";
import { Fees } from "../../libraries/Fees.sol";

interface IFlashLender is ISweepable, IERC3156FlashLender  { 

  event SetFlashLoanFee (
    address indexed caller, 
    BPS bps,
    uint256 maxAmount
  );

  event SetFeeWhitelist (
    address indexed caller, 
    address indexed account,
    bool excluded
  );

  event FlashLoan(
    address indexed receiver,
    address indexed initiator,
    address indexed depositorVault,
    uint256 amount,
    uint256 fee
  );

  /**
   * @notice Returns the flash loan fee.
   * 
   * @return The flash loan fee.
   */
  function getFlashLoanFee() external returns (Fees.Parameters memory);

  /**
   * @notice Sets the flash loan fee.
   * 
   * @param fee The flash loan fee.
   */
  function setFlashLoanFee(Fees.Parameters calldata fee) external;

  /**
   * @notice Sets the account to be excluded from flash loan fees.
   * 
   * @param account The account to exclude from flash loan fees.
   * @param excluded A value indicating whether the account should be excluded.
   */
  function setFeeWhitelist(address account, bool excluded) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import { IERC20Metadata } from "../../dependencies/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IVault {
  /**
   * @notice Returns the underlying asset for the vault.
   * 
   * @return The underlying asset for the vault.
   */
  function getUnderlyingAsset() external view returns (IERC20Metadata);

  /**
   * @notice Returns the number of decimal places to use for the underlying asset.
   * 
   * @return The number of decimals to use for the underlying asset.
   */
  function getDecimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import { IVault } from "./IVault.sol";

interface IYieldVault is IVault {
  
  event Donate (
    address indexed donater, 
    uint256 amount,
    uint256 feeAmount,
    address indexed feeReceiver
  );

  /**
   * @notice Donates yield to the vault.
   * 
   * @param amount The amount of yield to donate.
   */
  function donate(uint256 amount) external;

  /**
   * @notice Distribute any yield that is pending.
   */
  function distribute() external;

  /**
   * @notice Returns the total number of shares in the vault.
   * 
   * @return The total number of shares in the vault.
   */
  function getTotalShares() external view returns (uint256);

  /**
   * @notice Returns the total assets that are included in the vault.
   * 
   * @return The total supply for the underlying asset in the vault.
   */
  function getTotalAssets() external view returns (uint256);

  /**
   * @notice Returns the exchange rate between shares and assets in the vault.
   * 
   * @return The exchange rate between shares and assets in the vault.
   */
  function getExchangeRate() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import { IWETH9 } from "../dependencies/IWETH9.sol";

import { IAddressRegistry } from "../interfaces/core/IAddressRegistry.sol";
import { IAssetStorage } from "../interfaces/core/IAssetStorage.sol";
import { IAccessControlList } from "../interfaces/security/IAccessControlList.sol";
import { ITreasury } from "../interfaces/governance/ITreasury.sol";
import { IGovernor } from "../interfaces/governance/IGovernor.sol";
import { IDepositorVault } from "../interfaces/vault/IDepositorVault.sol";
import { IDepositorVaultStorage } from "../interfaces/vault/IDepositorVaultStorage.sol";
import { IDepositorVaultToken } from "../interfaces/vault/IDepositorVaultToken.sol";
import { IFlashLender } from "../interfaces/vault/IFlashLender.sol";
import { IMarket } from "../interfaces/market/IMarket.sol";
import { IMarketStorage } from "../interfaces/market/IMarketStorage.sol";
import { IMarketLiquidation } from "../interfaces/market/IMarketLiquidation.sol";
import { ILoyalty } from "../interfaces/loyalty/ILoyalty.sol";
import { ILoyaltyStorage } from "../interfaces/loyalty/ILoyaltyStorage.sol";
import { IPortfolio } from "../interfaces/portfolio/IPortfolio.sol";
import { IPortfolioStorage } from "../interfaces/portfolio/IPortfolioStorage.sol";
import { IMarketplaceVendor } from "../interfaces/marketplace/IMarketplaceVendor.sol";
import { IMarketplacePurchaser } from "../interfaces/marketplace/IMarketplacePurchaser.sol";
import { ISanctionList } from "../interfaces/core/ISanctionList.sol";

bytes32 constant AMBIT_ACCESS_CONTROL_LIST = 0x13a993c3bf3b4408a525cee20fb4780056c09c1378aeb33db21173b33d30bdd0; // ambit.acl
//bytes32 constant AMBIT_TOKEN = 0xecda6d4d9cf761ef0273e863e3cc2c72a2214c95e9ff3ee7c8bfdc9b8192f643; // ambit.token
bytes32 constant AMBIT_TREASURY = 0xaef04b9e2c9ec721a01ca424bbc4285142e44828bb9153fda4eb5d820563cb16; // ambit.treasury
bytes32 constant AMBIT_GOVERNOR = 0xc178db1589a9b11430b9c9547236d8089bc566c2d91713297980e596baa4c0a0; // ambit.governor   
bytes32 constant AMBIT_DEPOSITOR_VAULT = 0x970bffd07196f826592058a2977d8df91d0b38816ca31aaaa6a628eda0328dbe; // ambit.depositorVault
bytes32 constant AMBIT_DEPOSITOR_VAULT_STORAGE = 0x16680ddbaabf15b6d5dbc3406f33d0406c50351487c620a7378d14cb1e7cfc4d; // ambit.depositorVault.storage  
bytes32 constant AMBIT_DEPOSITOR_VAULT_TOKEN = 0x8e9a5206de4051330868a4fdef94140eaddce6206903c36de600007efb237b8d; // ambit.depositorVault.token
bytes32 constant AMBIT_FLASH_LENDER = 0x5db83dc15ba773f314e0d7f47e69757036f6987e727bf039e10e99a51ee2bb2f; // ambit.flashLender
bytes32 constant AMBIT_MARKET = 0xcc0fa1d8c6527b2fc2cd5cbed9e80e1843330af5cd1d34a45c3f125a60dc07aa; // ambit.market
bytes32 constant AMBIT_MARKET_STORAGE = 0x9465eb522ae1daef33ae6a71635f0a8b6e14ebb04ffb43bb9cd5063b065f7e70; // ambit.market.storage
bytes32 constant AMBIT_MARKET_LIQUIDATION = 0xbb6ead2ccd82be7d476c8b4d73c8021113b74ad34f4d8eb76cd88bfd4f1a9bf9; // ambit.market.liquidation
bytes32 constant AMBIT_WETH = 0x0f8a193ff464434486c0daf7db2a895884365d2bc84ba47a68fcf89c1b14b5b8; // WETH
bytes32 constant AMBIT_PORTFOLIO = 0x9d8aacac4eddf5ce050e7031a356719ed884b6564e70750ad9b5329bbba04170; // ambit.portfolio
bytes32 constant AMBIT_PORTFOLIO_STORAGE = 0xb3f3fe76bfa026278cd5611d49ef3069ee575f8d82b68ac967f8479228711d42; // ambit.portfolio.storage
bytes32 constant AMBIT_ASSET_STORAGE = 0x7267fae8044d9c0f406ec1d6bfdfdb3a4afea229fceedb3c88cc26df2ac97809; // ambit.asset.storage
bytes32 constant AMBIT_MARKETPLACE = 0x3c0e39ea1c28bdbbbba0594664427737b78d0eec7090ca32248302c0253a7e17; // ambit.marketplace
bytes32 constant AMBIT_LOYALTY = 0x5f89fbcad831cfcfaf01235ecf4a3cb0ef695880db8f0f32788c2374e70cecc9; // ambit.loyalty
bytes32 constant AMBIT_LOYALTY_STORAGE = 0x43775782d5b087cb5d4793124778d57d4a440c54ff592025231eb524a865567c; // ambit.loyalty.storage
bytes32 constant AMBIT_MARKETPLACE_VENDOR = 0xddeb7b23f95729b7960076fe105872e43d30e54c549d2283f0f1c7572837e540; // ambit.marketplace.vendor
bytes32 constant AMBIT_MARKETPLACE_PURCHASER = 0xf8fa3cb01a72c03d7977780689be23ca870ab653929f790ff2ae3cf12cbf034c; // ambit.marketplace.purchaser
bytes32 constant AMBIT_SANCTION_LIST = 0x186e6a650de6234d1f90896d7a7aff748a6ab62ee117272581e8943ecc0fd598; // ambit.sanctionList

library AddressRegistryExtensions {
  function getWETH(IAddressRegistry self) internal view returns (IWETH9) {
    return IWETH9(self.getAddress(AMBIT_WETH));
  }

  function getAccessControlList(IAddressRegistry self) internal view returns (IAccessControlList) {
    return IAccessControlList(self.getAddress(AMBIT_ACCESS_CONTROL_LIST));
  }

  function getTreasury(IAddressRegistry self) internal view returns (ITreasury) {
    return ITreasury(self.getAddress(AMBIT_TREASURY));
  }

  function getGovernor(IAddressRegistry self) internal view returns (IGovernor) {
    return IGovernor(self.getAddress(AMBIT_GOVERNOR));
  }
  
  function getDepositorVault(IAddressRegistry self) internal view returns (IDepositorVault) {
    return IDepositorVault(self.getAddress(AMBIT_DEPOSITOR_VAULT));
  }

  function getDepositorVaultStorage(IAddressRegistry self) internal view returns (IDepositorVaultStorage) {
    return IDepositorVaultStorage(self.getAddress(AMBIT_DEPOSITOR_VAULT_STORAGE));
  }

  function getDepositorVaultToken(IAddressRegistry self) internal view returns (IDepositorVaultToken) {
    return IDepositorVaultToken(self.getAddress(AMBIT_DEPOSITOR_VAULT_TOKEN));
  }

  function getFlashLender(IAddressRegistry self) internal view returns (IFlashLender) {
    return IFlashLender(self.getAddress(AMBIT_FLASH_LENDER));
  }

  function getAssetStorage(IAddressRegistry self) internal view returns (IAssetStorage) {
    return IAssetStorage(self.getAddress(AMBIT_ASSET_STORAGE));
  }

  function getPortfolio(IAddressRegistry self) internal view returns (IPortfolio) {
    return IPortfolio(self.getAddress(AMBIT_PORTFOLIO));
  }

  function getPortfolioStorage(IAddressRegistry self) internal view returns (IPortfolioStorage) {
    return IPortfolioStorage(self.getAddress(AMBIT_PORTFOLIO_STORAGE));
  }

  function getLoyalty(IAddressRegistry self) internal view returns (ILoyalty) {
    return ILoyalty(self.getAddress(AMBIT_LOYALTY));
  }

  function getLoyaltyStorage(IAddressRegistry self) internal view returns (ILoyaltyStorage) {
    return ILoyaltyStorage(self.getAddress(AMBIT_LOYALTY_STORAGE));
  }

  function getMarket(IAddressRegistry self) internal view returns (IMarket) {
    return IMarket(self.getAddress(AMBIT_MARKET));
  }

  function getMarketLiquidation(IAddressRegistry self) internal view returns (IMarketLiquidation) {
    return IMarketLiquidation(self.getAddress(AMBIT_MARKET_LIQUIDATION));
  }

  function getMarketStorage(IAddressRegistry self) internal view returns (IMarketStorage) {
    return IMarketStorage(self.getAddress(AMBIT_MARKET_STORAGE));
  }

  function getMarketplaceVendor(IAddressRegistry self) internal view returns (IMarketplaceVendor) {
    return IMarketplaceVendor(self.getAddress(AMBIT_MARKETPLACE_VENDOR));
  }

  function getMarketplacePurchaser(IAddressRegistry self) internal view returns (IMarketplacePurchaser) {
    return IMarketplacePurchaser(self.getAddress(AMBIT_MARKETPLACE_PURCHASER));
  }

  function getSanctionList(IAddressRegistry self) internal view returns (ISanctionList) {
    return ISanctionList(self.getAddress(AMBIT_SANCTION_LIST));
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

type Epoch is uint16;

/// @dev this lib allows the Loyalty contract code to be a bit more readable.
library EpochLib {
  uint32 constant private EPOCH = 7 days;

  /// @dev this will truncate the timestamp to the week starting 
  /// on the Sunday and the create the epoch from that
  function from(uint256 timestamp) internal pure returns (Epoch) {
    uint256 week = (timestamp / EPOCH * EPOCH + 3 days);

    uint256 day = (timestamp / 86400) % 7;

    return Epoch.wrap(uint16((day < 3 ? week - EPOCH : week) / EPOCH));
  }

  function previous(Epoch self) internal pure returns (Epoch) {
    return Epoch.wrap(Epoch.unwrap(self) - 1);
  }

  function equals(Epoch self, Epoch other) internal pure returns (bool) {
    return Epoch.unwrap(self) == Epoch.unwrap(other);
  }

  function olderThan(Epoch self, Epoch other) internal pure returns (bool) {
    return Epoch.unwrap(self) < Epoch.unwrap(other);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import { BPS } from "./PercentageMath.sol";
import { USD } from "./USDMath.sol";

library Errors {

  // validation errors
  error Validation_ZeroAmountNotAllowed();
  error Validation_ZeroAddressNotAllowed();
  error Validation_OutOfRange(uint256 value);
  error Validation_MaxLTVOutOfRange(BPS maxLTV);
  error Validation_LimitExceeded(uint256 limit, uint256 actual);
  error Validation_TokenNotAllowed(address token);

  // hooks errors
  error Hooks_NotImplemented();

  // authorization errors
  error Authorization_NotAuthorized(address caller);

  // migratable errors
  error Migratable_AlreadyMigrated();

  // portfolio storage
  error PortfolioStorage_AssetNotFound(address account, address token);

  // portfolio errors
  error Portfolio_MaximumSupplyExceeded(uint256 limit);
  error Portfolio_MaxmimumLimitReached(uint256 limit);
  error Portfolio_WithdrawAmountTooLarge(uint256 amount, uint256 shares, uint256 totalShares);
  error Portfolio_UnknownHookResponse();
  error Portfolio_WithdrawUnavailableInCurrentBlock(uint256 currentBlock, uint256 lastUpdateBlock);

  // flashloan errors
  error FlashLoan_UntrustedLender(address lender);
  error FlashLoan_UntrustedInitiator(address initiator);
  error FlashLoan_AmountExceeded(uint256 available, uint256 amount);
  error FlashLoan_TokenNotSupported(address token);
  error FlashLoan_ReceiverNotAllowed(address receiver);
  error FlashLoan_ReceiverFailed(address receiver);
  error FlashLoan_InsufficentAmount(uint256 requested, uint256 received);

  // marketplace errors
  error Marketplace_MissingMarketplaceAdapter(address asset);
  error Marketplace_MaximumRiskExceeded(BPS risk);
  error Marketplace_MaximumAmountExceeded(uint256 maxAmount, uint256 amount);
  
  // custodian errors
  error Custodian_BalanceExceeded(uint256 balance, uint256 amount);

  // liquidator errors
  error Liquidator_NotProfitable(uint256 totalSupply, uint256 totalAmount, uint256 amountReceived);

  // market errors
  error Market_BorrowLimitExceeded(uint256 borrowLimit, uint256 liabilities);
  error Market_InvalidMarketState(uint256 blockTimestamp, uint256 lastUpdate);
  error Market_NoLiabilities();
  error Market_UnhealthyAccount(address account, uint256 score); 
  error Market_StalePriceFound(address asset, address priceOracle, USD price); 
  
  // market liquidation errors
  error MarketLiquidation_NoTotalSupply(address account, address asset);
  error MarketLiquidation_LiquidationAmountExceedsMaxAmount(uint256 maxAmount, uint256 liquidationAmount);
  error MarketLiquidation_AccountNotLiquidatable(address account);

  // depositor vault errors
  error DepositorVault_AmountExceedsBalance(uint256 amount, uint256 balance);
  error DepositorVault_AmountExceedsMaximumAllowed(uint256 amount, uint256 borrowableAmount);
  error DepositorVault_FeeExceedsAmount(uint256 amount, uint256 feeAmount);
  error DepositorVault_FlashLoanAmountExceeded(uint256 available, uint256 amount);
  error DepositorVault_SlippageExceeded(uint256 actual, uint256 expected);
  error DepositorVault_MaximumSupplyExceeded(uint256 limit);
  
  // boosters
  error Boost_NotEligible(address account, bytes32 id);
  
  // access control list errors
  error AccessControlList_CanNotRemoveRole(bytes32 role, address account);

  // sanction list
  error SanctionList_AccountNotAllowed(address account);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import { Math } from "../dependencies/@openzeppelin/contracts/utils/math/Math.sol";
import { PercentageMath, BPS } from "./PercentageMath.sol";

library Fees {

  using PercentageMath for BPS;

  struct Parameters {
    BPS bps;
    uint256 maxAmount;
  }

  function calculate(Parameters memory feeParameters, uint256 amount) internal pure returns (uint256) {
    uint256 fee = feeParameters.bps.percentOf(amount);

    return Math.min(fee, feeParameters.maxAmount);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

library Normalizer {
  /**
   * @notice Normalize the amount from the source decimals to the destination decimals.
   * 
   * @param amount The amount to normalize.
   * @param from The precision to normalize the value from.
   * @param to The precision to normalize the value to.
   */  
  function normalize(uint256 amount, uint8 from, uint8 to) internal pure returns (uint256) {
    if (from < to) {
      return amount * 10 ** uint256(to - from);
    }
    if (from > to) {
      return amount / 10 ** uint256(from - to);
    }
    return amount;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import { Math } from "../dependencies/@openzeppelin/contracts/utils/math/Math.sol";

type BPS is uint16;

library PercentageMath {

  using Math for uint;
  
  BPS public constant ONE_HUNDRED_PERCENT = BPS.wrap(10000);

  function percentOf(BPS bps, uint256 amount) internal pure returns (uint256) {
    return amount.mulDiv(BPS.unwrap(bps), BPS.unwrap(ONE_HUNDRED_PERCENT));
  }

  function min(BPS a, BPS b) internal pure returns (BPS) {
    return BPS.wrap(uint16(Math.min(BPS.unwrap(a), BPS.unwrap(b))));
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import { IPortfolioStorage } from "../interfaces/portfolio/IPortfolioStorage.sol";

library PortfolioAssetExtensions {
  function getTokenAddresses(IPortfolioStorage.PortfolioAsset[] memory self) internal pure returns (address[] memory) {
    address[] memory array = new address[](self.length);
    for (uint256 i = 0; i < array.length;) {
      array[i] = self[i].token;
      unchecked { i++; }
    }
    return array;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import { Normalizer } from "./Normalizer.sol";

/// @dev USD is a number with a precision of 8 decimal places. It is used
/// to make the code more explicit for when a function deals with a USD value.
type USD is uint256;

library USDMath {

  uint8 public constant DECIMALS = 8;

  function normalize(USD amount, uint8 decimals) internal pure returns (uint256) {
    return Normalizer.normalize(USD.unwrap(amount), DECIMALS, decimals);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import { Address } from "../../dependencies/@openzeppelin/contracts/utils/Address.sol";
import { Math } from "../../dependencies/@openzeppelin/contracts/utils/math/Math.sol";
import { SafeCast } from "../../dependencies/@openzeppelin/contracts/utils/math/SafeCast.sol";
import { IERC3156FlashBorrower } from "../../dependencies/@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import { IERC20Metadata } from "../../dependencies/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "../../dependencies/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IAddressRegistry } from "../../interfaces/core/IAddressRegistry.sol";
import { ICustodian } from "../../interfaces/portfolio/ICustodian.sol";
import { 
  IAssetStorage, 
  ASSET_FIELD_CUSTODIAN,
  ASSET_FIELD_MARKETPLACE_ADAPTER,
  ASSET_FIELD_MAX_LTV
} from "../../interfaces/core/IAssetStorage.sol";
import { IDepositorVault } from "../../interfaces/vault/IDepositorVault.sol";
import { IFlashLender } from "../../interfaces/vault/IFlashLender.sol";
import { IPriceOracle } from "../../interfaces/oracle/IPriceOracle.sol";
import { IMarket } from "../../interfaces/market/IMarket.sol";
import { IMarketplacePurchaser } from "../../interfaces/marketplace/IMarketplacePurchaser.sol";
import { IPortfolioStorage } from "../../interfaces/portfolio/IPortfolioStorage.sol";
import { IPortfolio } from "../../interfaces/portfolio/IPortfolio.sol";
import { IMarketplaceAdapter } from "../../interfaces/marketplace/IMarketplaceAdapter.sol";
import { PortfolioAssetExtensions } from "../../libraries/PortfolioAssetExtensions.sol";
import { PercentageMath, BPS } from "../../libraries/PercentageMath.sol";
import { AddressRegistryExtensions } from "../../libraries/AddressRegistryExtensions.sol";
import { USD, USDMath } from "../../libraries/USDMath.sol";
import { Fees } from "../../libraries/Fees.sol";
import { Errors } from "../../libraries/Errors.sol";
import { Sanctionable } from "../utils/Sanctionable.sol";

contract MarketplacePurchaser is Sanctionable, IMarketplacePurchaser, IERC3156FlashBorrower  {

  struct FlashLoanContext {
    address account; 
    address marketplaceAdapter; 
    Parameters params;
    uint256 loanAmount;
    uint256 fees;
  }

  using Address for address payable;
  using PortfolioAssetExtensions for IPortfolioStorage.PortfolioAsset[];
  using Fees for Fees.Parameters;
  using AddressRegistryExtensions for IAddressRegistry;
  using Math for uint256;
  using SafeCast for uint256;
  using SafeERC20 for IERC20Metadata;
  using USDMath for USD;
  using PercentageMath for BPS;

  bytes32 private constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

  BPS private constant NINETY_FIVE_PERCENT = BPS.wrap(9500);

  IAddressRegistry public immutable _registry;

  constructor(IAddressRegistry registry) Sanctionable(registry) {
    _registry = registry;
  }

  function estimateMaxAmount(uint256 available, BPS risk) public pure returns (uint256) {
    if (BPS.unwrap(risk) > BPS.unwrap(NINETY_FIVE_PERCENT)) {
      revert Errors.Marketplace_MaximumRiskExceeded(risk);
    }
    return available.mulDiv(BPS.unwrap(PercentageMath.ONE_HUNDRED_PERCENT), BPS.unwrap(PercentageMath.ONE_HUNDRED_PERCENT) - BPS.unwrap(risk));
  }

  /// @inheritdoc IMarketplacePurchaser
  function buy(IMarketplacePurchaser.Parameters calldata params) external notSanctioned(msg.sender) {
    IAssetStorage.Asset memory asset = _registry.getAssetStorage().getAsset(
      params.token,
      ASSET_FIELD_CUSTODIAN | ASSET_FIELD_MARKETPLACE_ADAPTER | ASSET_FIELD_MAX_LTV);
    require(asset.custodian != address(0), "no custodian");

    if (asset.marketplaceAdapter == address(0)) {
      revert Errors.Marketplace_MissingMarketplaceAdapter(asset.token);
    }

    IMarket market = _registry.getMarket();

    // estimate the maximum credit the account has for the specific asset
    uint256 available = market.getBorrowLimit(msg.sender, IPriceOracle.Confidence.OK) - market.getLiabilities(msg.sender);

    uint256 maxAmount = estimateMaxAmount(available, asset.maxLTV);

    if (params.amount > maxAmount) {
       revert Errors.Marketplace_MaximumAmountExceeded(maxAmount, params.amount);
    }

    IFlashLender lender = _registry.getFlashLender();
    address underlyingAsset = address(_registry.getDepositorVault().getUnderlyingAsset());

    // ensure that we think we can get what we need from the lender
    if (params.amount > lender.maxFlashLoan(underlyingAsset)) {
      revert Errors.FlashLoan_InsufficentAmount(
        params.amount, 
        lender.maxFlashLoan(underlyingAsset));
    }

    bytes memory context = abi.encode(msg.sender, asset.marketplaceAdapter, params);

    lender.flashLoan(IERC3156FlashBorrower(this), underlyingAsset, params.amount, context);
  }

  /// @inheritdoc IERC3156FlashBorrower
  function onFlashLoan(address initiator, address, uint256 amount, uint256 fee, bytes calldata data) external returns (bytes32) {
    if (msg.sender != address(_registry.getFlashLender())) {
      revert Errors.FlashLoan_UntrustedLender(msg.sender);
    }

    if (initiator != address(this)) {
      revert Errors.FlashLoan_UntrustedInitiator(initiator);
    }
    
    FlashLoanContext memory context;
    context.loanAmount = amount;
    context.fees = fee;

    (
      context.account, 
      context.marketplaceAdapter, 
      context.params
    ) = abi.decode(data, (address, address, Parameters));
    
    if (context.loanAmount < context.params.amount) {
      // dont continue with the swap if we didn't get all the funds we were after
      revert Errors.FlashLoan_InsufficentAmount(context.params.amount, context.loanAmount);
    }

    executePurchaseOperation(context);

    approveLoanRepayment(amount, fee);

    ensureHealthyAccount(context.account);

    return CALLBACK_SUCCESS;
  }

  function executePurchaseOperation(FlashLoanContext memory context) private {
    IMarket market = _registry.getMarket();
    uint256 borrowingFee = market.getBorrowingFee().calculate(context.loanAmount + context.fees);

    // flash loan fees are paid on top of the amount request but 
    // borrowing fees are taken from the amount borrowed so we need
    // to adjust our total amount to take this into account    
    uint256 availableAmount = context.loanAmount - borrowingFee;

    IERC20Metadata underlyingAsset = _registry.getDepositorVault().getUnderlyingAsset();
    underlyingAsset.forceApprove(context.marketplaceAdapter, availableAmount);

    uint256 amountOut = IMarketplaceAdapter(context.marketplaceAdapter).execute(context.params.executionData);

    supply(context.account, context.params.token, amountOut);

    market.borrow(context.account, context.loanAmount + context.fees, address(this));
  }

  /// @dev supply the assets to the accounts portfolio
  function supply(address account, address token, uint256 amount) private {
    IAssetStorage.Asset memory asset = _registry.getAssetStorage().getAsset(
      token, 
      ASSET_FIELD_CUSTODIAN);
    require(asset.custodian != address(0), "no custodian");

    ICustodian(asset.custodian).getUnderlyingAsset().forceApprove(asset.custodian, amount);

    IPortfolio portfolio = _registry.getPortfolio();
    portfolio.supply(account, token, amount);
  }

  /// @dev approve the appropriate amount of funds for the flash loan to be repaid
  function approveLoanRepayment(uint256 amount, uint256 fees) private {
    IDepositorVault vault = _registry.getDepositorVault();
    vault.getUnderlyingAsset().forceApprove(address(_registry.getFlashLender()), amount + fees);
  }

  /// @dev ensure that the account is healthy once the leverage has been taken
  function ensureHealthyAccount(address account) private view {
    IMarket market = _registry.getMarket();
    market.ensureHealthyAccount(account);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import { ISanctionList } from "../../interfaces/core/ISanctionList.sol";
import { IAddressRegistry } from "../../interfaces/core/IAddressRegistry.sol";
import { Errors } from "../../libraries/Errors.sol";
import { AddressRegistryExtensions } from "../../libraries/AddressRegistryExtensions.sol";

abstract contract Sanctionable {

  using AddressRegistryExtensions for IAddressRegistry;

  IAddressRegistry private immutable _registry;

  constructor (IAddressRegistry registry) {
    _registry = registry;
  }

  modifier notSanctioned(address account) {
    {
      ISanctionList sanctionList = _registry.getSanctionList();
      if (address(sanctionList) != address(0) && sanctionList.isSanctioned(account)) {
        revert Errors.SanctionList_AccountNotAllowed(account);
      }
    }
    _;
  }
}