pragma solidity 0.8.4;

import "InterfacesUD.sol";
import "Ownable.sol";

contract MarketOIConfig is Ownable {
    uint256 public _maxMarketOI;
    uint256 public _maxTradeSize;
    IBufferBinaryOptionsUD public _marketContract;

    constructor(
        uint256 maxMarketOI,
        uint256 maxTradeSize,
        IBufferBinaryOptionsUD marketContract
    ) {
        _maxMarketOI = maxMarketOI;
        _maxTradeSize = maxTradeSize;
        _marketContract = marketContract;
    }

    function setMaxMarketOI(uint256 maxMarketOI) external onlyOwner {
        _maxMarketOI = maxMarketOI;
    }

    function setMaxTradeSize(uint256 maxTradeSize) external onlyOwner {
        _maxTradeSize = maxTradeSize;
    }

    function getMaxMarketOI(
        uint256 currentMarketOI
    ) external view returns (uint256) {
        uint256 remainingOI = _maxMarketOI - currentMarketOI;
        return remainingOI < _maxTradeSize ? remainingOI : _maxTradeSize;
    }

    function getMarketOICap() external view returns (uint256) {
        return _maxMarketOI;
    }
}

// SPDX-License-Identifier: BUSL-1.1
import "ERC20.sol";
import "Interfaces.sol";
pragma solidity 0.8.4;

interface IBufferRouterUD {
    struct QueuedTrade {
        address user;
        uint256 totalFee;
        uint256 period;
        address targetContract;
        uint256 strike;
        uint256 slippage;
        bool allowPartialFill;
        string referralCode;
        uint256 settlementFee;
        LimitOrder limitOrder;
        bool isTradeResolved;
        bool isEarlyCloseAllowed;
        bool isAbove;
        uint256 queueTime;
    }

    struct QueueIdInfo {
        address targetContract;
        uint256 optionId;
    }

    struct OptionInfo {
        uint256 queueId;
        address signer;
        uint256 nonce;
    }

    struct SignInfo {
        bytes signature;
        uint256 timestamp;
    }

    struct LimitOrder {
        bool isLimitOrder;
        uint256 limitOrderExpiry;
        uint256 limitOrderOpenTime;
    }

    struct TradeParams {
        uint256 queueId;
        uint256 totalFee;
        uint256 period;
        address targetContract;
        uint256 strike;
        uint256 slippage;
        bool allowPartialFill;
        string referralCode;
        bool isAbove;
        uint256 settlementFee;
        LimitOrder limitOrder;
        uint256 userSignedSettlementFee;
        uint256 spread;
        uint256 queueTime;
        SignInfo settlementFeeSignInfo;
        SignInfo userSignInfo;
        bytes[] priceUpdateData;
        bytes32[] priceIds;
        SignInfo spreadSignInfo;
    }

    struct TradeParamsV2 {
        uint256 totalFee;
        uint256 period;
        address targetContract;
        uint256 strike;
        uint256 slippage;
        bool allowPartialFill;
        string referralCode;
        bool isAbove;
        uint256 settlementFee;
        LimitOrder limitOrder;
    }
    struct ResolveParams {
        uint256 settlementFee;
        uint256 spread;
        SignInfo settlementFeeSignInfo;
        bytes[] priceUpdateData;
        bytes32[] priceIds;
        SignInfo spreadSignInfo;
        uint256 limitOrderOpenTime;
    }
    struct Register {
        address oneCT;
        bytes signature;
        bool shouldRegister;
    }

    struct Permit {
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
        bool shouldApprove;
    }
    struct RevokeParams {
        address tokenX;
        address user;
        Permit permit;
    }
    struct OpenTxn {
        TradeParams tradeParams;
        Register register;
        Permit permit;
        address user;
    }

    struct AccountMapping {
        address oneCT;
        uint256 nonce;
    }

    struct CloseTradeParams {
        uint256 optionId;
        address targetContract;
        uint256 closingTime;
        bytes[] priceUpdateData;
        bytes32[] priceIds;
    }

    struct CloseAnytimeParams {
        CloseTradeParams closeTradeParams;
        Register register;
        SignInfo userSignInfo;
    }

    struct IdMapping {
        uint256 id;
        bool isSet;
    }

    event OpenTrade(
        address indexed account,
        uint256 queueId,
        uint256 optionId,
        address targetContract
    );
    event CancelTrade(address indexed account, uint256 queueId, string reason);
    event FailUnlock(
        uint256 indexed optionId,
        address targetContract,
        string reason
    );
    event FailResolve(uint256 indexed queueId, string reason);
    event FailRevoke(address indexed user, address tokenX, string reason);
    event ContractRegistryUpdated(address targetContract, bool register);
    event ApproveRouter(
        address user,
        uint256 nonce,
        uint256 value,
        uint256 deadline,
        address tokenX
    );
    event RevokeRouter(
        address user,
        uint256 nonce,
        uint256 value,
        uint256 deadline,
        address tokenX
    );

    event InitiateTrade(
        address indexed user,
        uint256 queueId,
        address targetContract,
        uint256 strike,
        uint256 slippage,
        uint256 period,
        bool allowPartialFill,
        uint256 totalFee,
        string referralCode,
        uint256 settlementFee,
        bool isAbove
    );
}

interface IBufferBinaryOptionsUD {
    event Create(
        address indexed account,
        uint256 indexed id,
        uint256 settlementFee,
        uint256 totalFee
    );

    event Exercise(
        address indexed account,
        uint256 indexed id,
        uint256 profit,
        uint256 priceAtExpiration,
        bool isAbove
    );
    event Expire(
        uint256 indexed id,
        uint256 premium,
        uint256 priceAtExpiration,
        bool isAbove
    );
    event Pause(bool isPaused);
    event UpdateReferral(
        address user,
        address referrer,
        bool isReferralValid,
        uint256 totalFee,
        uint256 referrerFee,
        uint256 rebate,
        string referralCode
    );

    event LpProfit(uint256 indexed id, uint256 amount);
    event LpLoss(uint256 indexed id, uint256 amount);

    function createFromRouter(
        OptionParams calldata optionParams,
        uint256 queuedTime
    ) external returns (uint256 optionID);

    function evaluateParams(
        OptionParams calldata optionParams,
        uint256 slippage
    ) external returns (uint256 amount, uint256 revisedFee);

    function tokenX() external view returns (ERC20);

    function pool() external view returns (ILiquidityPool);

    function config() external view returns (IOptionsConfigUD);

    function token0() external view returns (string memory);

    function token1() external view returns (string memory);

    function ownerOf(uint256 id) external view returns (address);

    function assetPair() external view returns (string memory);

    function totalMarketOI() external view returns (uint256);

    function getMaxOI() external view returns (uint256);

    function fees(
        uint256 amount,
        address user,
        string calldata referralCode,
        uint256 baseSettlementFeePercent
    )
        external
        view
        returns (uint256 total, uint256 settlementFee, uint256 premium);

    function isStrikeValid(
        uint256 slippage,
        uint256 currentPrice,
        uint256 strike
    ) external pure returns (bool);

    enum State {
        Inactive,
        Active,
        Exercised,
        Expired
    }

    enum AssetCategory {
        Forex,
        Crypto,
        Commodities
    }
    struct OptionExpiryData {
        uint256 optionId;
        uint256 priceAtExpiration;
    }

    event CreateOptionsContract(
        address config,
        address pool,
        address tokenX,
        string token0,
        string token1,
        AssetCategory category
    );
    struct Option {
        State state;
        uint256 strike;
        uint256 amount;
        uint256 lockedAmount;
        uint256 premium;
        uint256 expiration;
        uint256 totalFee;
        uint256 createdAt;
        bool isAbove;
    }
    struct OptionParams {
        uint256 strike;
        uint256 amount;
        uint256 period;
        bool allowPartialFill;
        uint256 totalFee;
        address user;
        string referralCode;
        uint256 baseSettlementFeePercentage;
        bool isAbove;
    }

    function options(
        uint256 optionId
    )
        external
        view
        returns (
            State state,
            uint256 strike,
            uint256 amount,
            uint256 lockedAmount,
            uint256 premium,
            uint256 expiration,
            uint256 totalFee,
            uint256 createdAt,
            bool isAbove
        );

    function unlock(
        uint256 optionID,
        uint256 priceAtExpiration,
        uint256 closingTime
    ) external;
}

interface IOptionsConfigUD {
    event UpdateMaxPeriod(uint32 value);
    event UpdateMinPeriod(uint32 value);
    event UpdateEarlyCloseThreshold(uint32 earlyCloseThreshold);
    event UpdateEarlyClose(bool isAllowed);
    event UpdateSettlementFeeDisbursalContract(address value);
    event UpdatetraderNFTContract(address value);
    event UpdateMinFee(uint256 value);
    event UpdateOptionStorageContract(address value);
    event UpdateCreationWindowContract(address value);
    event UpdatePlatformFee(uint256 _platformFee);
    event UpdatePoolOIStorageContract(address _poolOIStorageContract);
    event UpdatePoolOIConfigContract(address _poolOIConfigContract);
    event UpdateMarketOIConfigContract(address _marketOIConfigContract);
    event UpdateIV(uint32 _iv);
    event UpdateBoosterContract(address _boosterContract);
    event UpdateSpreadConfig1(uint256 spreadConfig1);
    event UpdateSpreadConfig2(uint256 spreadConfig2);
    event UpdateIVFactorITM(uint256 ivFactorITM);
    event UpdateIVFactorOTM(uint256 ivFactorOTM);
    event UpdateSpreadFactor(uint32 ivFactorOTM);
    event UpdateCircuitBreakerContract(address _circuitBreakerContract);

    function circuitBreakerContract() external view returns (address);

    function settlementFeeDisbursalContract() external view returns (address);

    function maxPeriod() external view returns (uint32);

    function minPeriod() external view returns (uint32);

    function minFee() external view returns (uint256);

    function platformFee() external view returns (uint256);

    function optionStorageContract() external view returns (address);

    function creationWindowContract() external view returns (address);

    function poolOIStorageContract() external view returns (address);

    function poolOIConfigContract() external view returns (address);

    function marketOIConfigContract() external view returns (address);

    function iv() external view returns (uint32);

    function earlyCloseThreshold() external view returns (uint32);

    function isEarlyCloseAllowed() external view returns (bool);

    function boosterContract() external view returns (address);

    function spreadConfig1() external view returns (uint256);

    function spreadConfig2() external view returns (uint256);

    function spreadFactor() external view returns (uint32);

    function getFactoredIv(bool isITM) external view returns (uint32);
}

interface IPoolOIStorage {
    function updatePoolOI(bool isIncreased, uint256 interest) external;

    function totalPoolOI() external view returns (uint256);
}

interface IPoolOIConfig {
    function getMaxPoolOI() external view returns (uint256);

    function getPoolOICap() external view returns (uint256);
}

interface IMarketOIConfig {
    function getMaxMarketOI(
        uint256 currentMarketOI
    ) external view returns (uint256);

    function getMarketOICap() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

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

// SPDX-License-Identifier: BUSL-1.1
import "ERC20.sol";

pragma solidity 0.8.4;

interface IBufferBinaryOptionPauserV2_5 {
    function isPaused() external view returns (bool);

    function setIsPaused() external;
}

interface IBufferBinaryOptionPauserV2 {
    function isPaused() external view returns (bool);

    function toggleCreation() external;
}

interface ICircuitBreaker {
    struct MarketPoolPair {
        address market;
        address pool;
    }
    struct Configs {
        int256 value;
        address contractAddress;
    }
    struct OverallStats {
        address contractAddress;
        int256 loss;
        int256 sf;
        int256 lp_sf;
        int256 net_loss;
    }
    struct MarketStats {
        address pool;
        int256 loss;
        int256 sf;
    }
    struct PoolStats {
        address[] markets;
        int256 loss;
        int256 sf;
    }

    function update(int256 loss, int256 sf, uint256 option_id) external;

    event Update(
        int256 loss,
        int256 sf,
        address market,
        address pool,
        uint256 option_id
    );

    event MarketPaused(address market, address pool);
    event PoolPaused(address pool);
}

interface IBooster {
    struct UserBoostTrades {
        uint256 totalBoostTrades;
        uint256 totalBoostTradesUsed;
    }

    function getUserBoostData(
        address user,
        address token
    ) external view returns (UserBoostTrades memory);

    function updateUserBoost(address user, address token) external;

    function getBoostPercentage(
        address user,
        address token
    ) external view returns (uint256);

    struct Permit {
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
        bool shouldApprove;
    }
    event ApproveTokenX(
        address user,
        uint256 nonce,
        uint256 value,
        uint256 deadline,
        address tokenX
    );
    event BuyCoupon(address indexed token, address indexed user, uint256 price);
    event SetPrice(uint256 couponPrice);
    event SetBoostPercentage(uint256 boost);
    event UpdateBoostTradesUser(address indexed user, address indexed token);
    event Configure(uint8[4] nftTierDiscounts);
}

interface IAccountRegistrar {
    struct AccountMapping {
        address oneCT;
        uint256 nonce;
    }
    event RegisterAccount(
        address indexed user,
        address indexed oneCT,
        uint256 nonce
    );
    event DeregisterAccount(address indexed account, uint256 nonce);

    function accountMapping(
        address
    ) external view returns (address oneCT, uint256 nonce);

    function registerAccount(
        address oneCT,
        address user,
        bytes memory signature
    ) external;
}

interface ILiquidityPool {
    struct LockedAmount {
        uint256 timestamp;
        uint256 amount;
    }
    struct ProvidedLiquidity {
        uint256 unlockedAmount;
        LockedAmount[] lockedAmounts;
        uint256 nextIndexForUnlock;
    }
    struct LockedLiquidity {
        uint256 amount;
        uint256 premium;
        bool locked;
    }
    event Profit(uint256 indexed id, uint256 amount);
    event Loss(uint256 indexed id, uint256 amount);
    event Provide(address indexed account, uint256 amount, uint256 writeAmount);
    event UpdateMaxLiquidity(uint256 indexed maxLiquidity);
    event Withdraw(
        address indexed account,
        uint256 amount,
        uint256 writeAmount
    );

    function unlock(uint256 id) external;

    function totalTokenXBalance() external view returns (uint256 amount);

    function availableBalance() external view returns (uint256 balance);

    function send(uint256 id, address account, uint256 amount) external;

    function lock(uint256 id, uint256 tokenXAmount, uint256 premium) external;
}

interface ITraderNFT {
    function tokenOwner(uint256 id) external view returns (address user);

    function tokenTierMappings(uint256 id) external view returns (uint8 tier);

    event UpdateTiers(uint256[] tokenIds, uint8[] tiers, uint256[] batchIds);
}

interface IFakeTraderNFT {
    function tokenOwner(uint256 id) external view returns (address user);

    function tokenTierMappings(uint256 id) external view returns (uint8 tier);

    event UpdateNftBasePrice(uint256 nftBasePrice);
    event UpdateMaxNFTMintLimits(uint256 maxNFTMintLimit);
    event UpdateBaseURI(string baseURI);
    event Claim(address indexed account, uint256 claimTokenId);
    event Mint(address indexed account, uint256 tokenId, uint8 tier);
}

interface IReferralStorage {
    function codeOwner(string memory _code) external view returns (address);

    function traderReferralCodes(address) external view returns (string memory);

    function getTraderReferralInfo(
        address user
    ) external view returns (string memory, address);

    function setTraderReferralCode(address user, string memory _code) external;

    function setReferrerTier(address, uint8) external;

    function referrerTierStep(
        uint8 referralTier
    ) external view returns (uint8 step);

    function referrerTierDiscount(
        uint8 referralTier
    ) external view returns (uint32 discount);

    function referrerTier(address referrer) external view returns (uint8 tier);

    struct ReferrerData {
        uint256 tradeVolume;
        uint256 rebate;
        uint256 trades;
    }

    struct ReferreeData {
        uint256 tradeVolume;
        uint256 rebate;
    }

    struct ReferralData {
        ReferrerData referrerData;
        ReferreeData referreeData;
    }

    struct Tier {
        uint256 totalRebate; // e.g. 2400 for 24%
        uint256 discountShare; // 5000 for 50%/50%, 7000 for 30% rebates/70% discount
    }

    event UpdateTraderReferralCode(address indexed account, string code);
    event UpdateReferrerTier(address referrer, uint8 tierId);
    event RegisterCode(address indexed account, string code);
    event SetCodeOwner(
        address indexed account,
        address newAccount,
        string code
    );
}

interface IOptionStorage {
    function save(
        uint256 optionId,
        address optionsContract,
        address user
    ) external;
}

interface ICreationWindowContract {
    function isInCreationWindow(uint256 period) external view returns (bool);
}

interface IPyth {
    /// @notice Returns the period (in seconds) that a price feed is considered valid since its publish time
    function getValidTimePeriod() external view returns (uint validTimePeriod);

    /// @notice Returns the price and confidence interval.
    /// @dev Reverts if the price has not been updated within the last `getValidTimePeriod()` seconds.
    /// @param id The Pyth Price Feed ID of which to fetch the price and confidence interval.
    /// @return price - please read the documentation of Price to understand how to use this safely.
    function getPrice(bytes32 id) external view returns (Price memory price);

    /// @notice Returns the exponentially-weighted moving average price and confidence interval.
    /// @dev Reverts if the EMA price is not available.
    /// @param id The Pyth Price Feed ID of which to fetch the EMA price and confidence interval.
    /// @return price - please read the documentation of Price to understand how to use this safely.
    function getEmaPrice(bytes32 id) external view returns (Price memory price);

    /// @notice Returns the price of a price feed without any sanity checks.
    /// @dev This function returns the most recent price update in this contract without any recency checks.
    /// This function is unsafe as the returned price update may be arbitrarily far in the past.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getPrice` or `getPriceNoOlderThan`.
    /// @return price - please read the documentation of Price to understand how to use this safely.
    function getPriceUnsafe(
        bytes32 id
    ) external view returns (Price memory price);

    /// @notice Returns the price that is no older than `age` seconds of the current time.
    /// @dev This function is a sanity-checked version of `getPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of Price to understand how to use this safely.
    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (Price memory price);

    /// @notice Returns the exponentially-weighted moving average price of a price feed without any sanity checks.
    /// @dev This function returns the same price as `getEmaPrice` in the case where the price is available.
    /// However, if the price is not recent this function returns the latest available price.
    ///
    /// The returned price can be from arbitrarily far in the past; this function makes no guarantees that
    /// the returned price is recent or useful for any particular application.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getEmaPrice` or `getEmaPriceNoOlderThan`.
    /// @return price - please read the documentation of Price to understand how to use this safely.
    function getEmaPriceUnsafe(
        bytes32 id
    ) external view returns (Price memory price);

    /// @notice Returns the exponentially-weighted moving average price that is no older than `age` seconds
    /// of the current time.
    /// @dev This function is a sanity-checked version of `getEmaPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of Price to understand how to use this safely.
    function getEmaPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (Price memory price);

    /// @notice Update price feeds with given update messages.
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    /// Prices will be updated if they are more recent than the current stored prices.
    /// The call will succeed even if the update is not the most recent.
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    /// @notice Wrapper around updatePriceFeeds that rejects fast if a price update is not necessary. A price update is
    /// necessary if the current on-chain publishTime is older than the given publishTime. It relies solely on the
    /// given `publishTimes` for the price feeds and does not read the actual price update publish time within `updateData`.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    /// `priceIds` and `publishTimes` are two arrays with the same size that correspond to senders known publishTime
    /// of each priceId when calling this method. If all of price feeds within `priceIds` have updated and have
    /// a newer or equal publish time than the given publish time, it will reject the transaction to save gas.
    /// Otherwise, it calls updatePriceFeeds method to update the prices.
    ///
    /// @dev Reverts if update is not needed or the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param publishTimes Array of publishTimes. `publishTimes[i]` corresponds to known `publishTime` of `priceIds[i]`
    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable;

    /// @notice Returns the required fee to update an array of price updates.
    /// @param updateData Array of price update data.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(
        bytes[] calldata updateData
    ) external view returns (uint feeAmount);

    /// @notice Parse `updateData` and return price feeds of the given `priceIds` if they are all published
    /// within `minPublishTime` and `maxPublishTime`.
    ///
    /// You can use this method if you want to use a Pyth price at a fixed time and not the most recent price;
    /// otherwise, please consider using `updatePriceFeeds`. This method does not store the price updates on-chain.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PriceFeed[] memory priceFeeds);

    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
    }
}
interface IIncentivePool {
    // Events
    event Withdrawal(address indexed token, address to, uint256 amount);

    event JackpotTriggered(
        address indexed userAddress,
        uint256 jackpotWinAmount,
        address indexed optionContract,
        uint256 amount,
        address indexed router,
        uint256 optionId
    );
    event UpdateIncentivePoolPercentForJackpot(
        uint256 _incentivePoolPercentForJackpot
    );
    event UpdateMinBetSizeForJackpot(
        address indexed token,
        uint256 _minBetSizeForJackpot
    );
    event UpdateMaxJackpotWinPercentForUser(
        uint256 _maxJackpotWinPercentForUser
    );
    event UpdateIncentivePercentForWager(uint256 _incentivePercentForWager);
    event UpdateMinWinningsForTransfer(
        address indexed token,
        uint256 _minWinningsForTransfer
    );
    event UpdateJackpotToken(address indexed token);
    event UpdateKeyHash(bytes32 keyHash);

    function executeIncentives(
        address userAddress,
        uint256 amount,
        address optionContract,
        uint256 optionId,
        address router,
        address tokenAddress
    ) external returns (uint256 jackpotWinAmount);

    function minBetSizeForJackpot(address) external view returns (uint256);
    function jackpotToken() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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