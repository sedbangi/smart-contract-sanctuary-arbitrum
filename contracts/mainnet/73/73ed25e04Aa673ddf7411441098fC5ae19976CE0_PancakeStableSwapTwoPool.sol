// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin-4.5.0/contracts/access/Ownable.sol";
import "@openzeppelin-4.5.0/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin-4.5.0/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin-4.5.0/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IPancakeStableSwapLP.sol";

contract PancakeStableSwapTwoPool is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant N_COINS = 2;

    uint256 public constant MAX_DECIMAL = 18;
    uint256 public constant FEE_DENOMINATOR = 1e10;
    uint256 public constant PRECISION = 1e18;
    uint256[N_COINS] public PRECISION_MUL;
    uint256[N_COINS] public RATES;

    uint256 public constant MAX_ADMIN_FEE = 1e10;
    uint256 public constant MAX_FEE = 5e9;
    uint256 public constant MAX_A = 1e6;
    uint256 public constant MAX_A_CHANGE = 10;
    uint256 public constant MIN_BNB_GAS = 2300;
    uint256 public constant MAX_BNB_GAS = 23000;

    uint256 public constant ADMIN_ACTIONS_DELAY = 3 days;
    uint256 public constant MIN_RAMP_TIME = 1 days;

    address[N_COINS] public coins;
    uint256[N_COINS] public balances;
    uint256 public fee; // fee * 1e10.
    uint256 public admin_fee; // admin_fee * 1e10.
    uint256 public bnb_gas = 4029; // transfer bnb gas.

    IPancakeStableSwapLP public token;

    address constant BNB_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    bool support_BNB;

    uint256 public initial_A;
    uint256 public future_A;
    uint256 public initial_A_time;
    uint256 public future_A_time;

    uint256 public admin_actions_deadline;
    uint256 public future_fee;
    uint256 public future_admin_fee;

    uint256 public kill_deadline;
    uint256 public constant KILL_DEADLINE_DT = 2 * 30 days;
    bool public is_killed;

    address public immutable STABLESWAP_FACTORY;
    bool public isInitialized;

    event TokenExchange(
        address indexed buyer,
        uint256 sold_id,
        uint256 tokens_sold,
        uint256 bought_id,
        uint256 tokens_bought
    );
    event AddLiquidity(
        address indexed provider,
        uint256[N_COINS] token_amounts,
        uint256[N_COINS] fees,
        uint256 invariant,
        uint256 token_supply
    );
    event RemoveLiquidity(
        address indexed provider,
        uint256[N_COINS] token_amounts,
        uint256[N_COINS] fees,
        uint256 token_supply
    );
    event RemoveLiquidityOne(address indexed provider, uint256 index, uint256 token_amount, uint256 coin_amount);
    event RemoveLiquidityImbalance(
        address indexed provider,
        uint256[N_COINS] token_amounts,
        uint256[N_COINS] fees,
        uint256 invariant,
        uint256 token_supply
    );
    event CommitNewFee(uint256 indexed deadline, uint256 fee, uint256 admin_fee);
    event NewFee(uint256 fee, uint256 admin_fee);
    event RampA(uint256 old_A, uint256 new_A, uint256 initial_time, uint256 future_time);
    event StopRampA(uint256 A, uint256 t);
    event SetBNBGas(uint256 bnb_gas);
    event RevertParameters();
    event DonateAdminFees();
    event Kill();
    event Unkill();

    /**
     * @notice constructor
     */
    constructor() {
        STABLESWAP_FACTORY = msg.sender;
    }

    /**
     * @notice initialize
     * @param _coins: Addresses of ERC20 conracts of coins (c-tokens) involved
     * @param _A: Amplification coefficient multiplied by n * (n - 1)
     * @param _fee: Fee to charge for exchanges
     * @param _admin_fee: Admin fee
     * @param _owner: Owner
     * @param _LP: LP address
     */
    function initialize(
        address[N_COINS] memory _coins,
        uint256 _A,
        uint256 _fee,
        uint256 _admin_fee,
        address _owner,
        address _LP
    ) external {
        require(!isInitialized, "Operations: Already initialized");
        require(msg.sender == STABLESWAP_FACTORY, "Operations: Not factory");
        require(_A <= MAX_A, "_A exceeds maximum");
        require(_fee <= MAX_FEE, "_fee exceeds maximum");
        require(_admin_fee <= MAX_ADMIN_FEE, "_admin_fee exceeds maximum");
        isInitialized = true;
        for (uint256 i = 0; i < N_COINS; i++) {
            require(_coins[i] != address(0), "ZERO Address");
            uint256 coinDecimal;
            if (_coins[i] == BNB_ADDRESS) {
                coinDecimal = 18;
                support_BNB = true;
            } else {
                coinDecimal = IERC20Metadata(_coins[i]).decimals();
            }
            require(coinDecimal <= MAX_DECIMAL, "The maximum decimal cannot exceed 18");
            //set PRECISION_MUL and  RATES
            PRECISION_MUL[i] = 10**(MAX_DECIMAL - coinDecimal);
            RATES[i] = PRECISION * PRECISION_MUL[i];
        }
        coins = _coins;
        initial_A = _A;
        future_A = _A;
        fee = _fee;
        admin_fee = _admin_fee;
        kill_deadline = block.timestamp + KILL_DEADLINE_DT;
        token = IPancakeStableSwapLP(_LP);

        transferOwnership(_owner);
    }

    function get_A() internal view returns (uint256) {
        //Handle ramping A up or down
        uint256 t1 = future_A_time;
        uint256 A1 = future_A;
        if (block.timestamp < t1) {
            uint256 A0 = initial_A;
            uint256 t0 = initial_A_time;
            // Expressions in uint256 cannot have negative numbers, thus "if"
            if (A1 > A0) {
                return A0 + ((A1 - A0) * (block.timestamp - t0)) / (t1 - t0);
            } else {
                return A0 - ((A0 - A1) * (block.timestamp - t0)) / (t1 - t0);
            }
        } else {
            // when t1 == 0 or block.timestamp >= t1
            return A1;
        }
    }

    function A() external view returns (uint256) {
        return get_A();
    }

    function _xp() internal view returns (uint256[N_COINS] memory result) {
        result = RATES;
        for (uint256 i = 0; i < N_COINS; i++) {
            result[i] = (result[i] * balances[i]) / PRECISION;
        }
    }

    function _xp_mem(uint256[N_COINS] memory _balances) internal view returns (uint256[N_COINS] memory result) {
        result = RATES;
        for (uint256 i = 0; i < N_COINS; i++) {
            result[i] = (result[i] * _balances[i]) / PRECISION;
        }
    }

    function get_D(uint256[N_COINS] memory xp, uint256 amp) internal pure returns (uint256) {
        uint256 S;
        for (uint256 i = 0; i < N_COINS; i++) {
            S += xp[i];
        }
        if (S == 0) {
            return 0;
        }

        uint256 Dprev;
        uint256 D = S;
        uint256 Ann = amp * N_COINS;
        for (uint256 j = 0; j < 255; j++) {
            uint256 D_P = D;
            for (uint256 k = 0; k < N_COINS; k++) {
                D_P = (D_P * D) / (xp[k] * N_COINS); // If division by 0, this will be borked: only withdrawal will work. And that is good
            }
            Dprev = D;
            D = ((Ann * S + D_P * N_COINS) * D) / ((Ann - 1) * D + (N_COINS + 1) * D_P);
            // Equality with the precision of 1
            if (D > Dprev) {
                if (D - Dprev <= 1) {
                    break;
                }
            } else {
                if (Dprev - D <= 1) {
                    break;
                }
            }
        }
        return D;
    }

    function get_D_mem(uint256[N_COINS] memory _balances, uint256 amp) internal view returns (uint256) {
        return get_D(_xp_mem(_balances), amp);
    }

    function get_virtual_price() external view returns (uint256) {
        /**
        Returns portfolio virtual price (for calculating profit)
        scaled up by 1e18
        */
        uint256 D = get_D(_xp(), get_A());
        /**
        D is in the units similar to DAI (e.g. converted to precision 1e18)
        When balanced, D = n * x_u - total virtual value of the portfolio
        */
        uint256 token_supply = token.totalSupply();
        return (D * PRECISION) / token_supply;
    }

    function calc_token_amount(uint256[N_COINS] memory amounts, bool deposit) external view returns (uint256) {
        /**
        Simplified method to calculate addition or reduction in token supply at
        deposit or withdrawal without taking fees into account (but looking at
        slippage).
        Needed to prevent front-running, not for precise calculations!
        */
        uint256[N_COINS] memory _balances = balances;
        uint256 amp = get_A();
        uint256 D0 = get_D_mem(_balances, amp);
        for (uint256 i = 0; i < N_COINS; i++) {
            if (deposit) {
                _balances[i] += amounts[i];
            } else {
                _balances[i] -= amounts[i];
            }
        }
        uint256 D1 = get_D_mem(_balances, amp);
        uint256 token_amount = token.totalSupply();
        uint256 difference;
        if (deposit) {
            difference = D1 - D0;
        } else {
            difference = D0 - D1;
        }
        return (difference * token_amount) / D0;
    }

    function add_liquidity(uint256[N_COINS] memory amounts, uint256 min_mint_amount) external payable nonReentrant {
        //Amounts is amounts of c-tokens
        require(!is_killed, "Killed");
        if (!support_BNB) {
            require(msg.value == 0, "Inconsistent quantity"); // Avoid sending BNB by mistake.
        }
        uint256[N_COINS] memory fees;
        uint256 _fee = (fee * N_COINS) / (4 * (N_COINS - 1));
        uint256 _admin_fee = admin_fee;
        uint256 amp = get_A();

        uint256 token_supply = token.totalSupply();
        //Initial invariant
        uint256 D0;
        uint256[N_COINS] memory old_balances = balances;
        if (token_supply > 0) {
            D0 = get_D_mem(old_balances, amp);
        }
        uint256[N_COINS] memory new_balances = [old_balances[0], old_balances[1]];

        for (uint256 i = 0; i < N_COINS; i++) {
            if (token_supply == 0) {
                require(amounts[i] > 0, "Initial deposit requires all coins");
            }
            // balances store amounts of c-tokens
            new_balances[i] = old_balances[i] + amounts[i];
        }

        // Invariant after change
        uint256 D1 = get_D_mem(new_balances, amp);
        require(D1 > D0, "D1 must be greater than D0");

        // We need to recalculate the invariant accounting for fees
        // to calculate fair user's share
        uint256 D2 = D1;
        if (token_supply > 0) {
            // Only account for fees if we are not the first to deposit
            for (uint256 i = 0; i < N_COINS; i++) {
                uint256 ideal_balance = (D1 * old_balances[i]) / D0;
                uint256 difference;
                if (ideal_balance > new_balances[i]) {
                    difference = ideal_balance - new_balances[i];
                } else {
                    difference = new_balances[i] - ideal_balance;
                }

                fees[i] = (_fee * difference) / FEE_DENOMINATOR;
                balances[i] = new_balances[i] - ((fees[i] * _admin_fee) / FEE_DENOMINATOR);
                new_balances[i] -= fees[i];
            }
            D2 = get_D_mem(new_balances, amp);
        } else {
            balances = new_balances;
        }

        // Calculate, how much pool tokens to mint
        uint256 mint_amount;
        if (token_supply == 0) {
            mint_amount = D1; // Take the dust if there was any
        } else {
            mint_amount = (token_supply * (D2 - D0)) / D0;
        }
        require(mint_amount >= min_mint_amount, "Slippage screwed you");

        // Take coins from the sender
        for (uint256 i = 0; i < N_COINS; i++) {
            uint256 amount = amounts[i];
            address coin = coins[i];
            transfer_in(coin, amount);
        }

        // Mint pool tokens
        token.mint(msg.sender, mint_amount);

        emit AddLiquidity(msg.sender, amounts, fees, D1, token_supply + mint_amount);
    }

    function get_y(
        uint256 i,
        uint256 j,
        uint256 x,
        uint256[N_COINS] memory xp_
    ) internal view returns (uint256) {
        // x in the input is converted to the same price/precision
        require((i != j) && (i < N_COINS) && (j < N_COINS), "Illegal parameter");
        uint256 amp = get_A();
        uint256 D = get_D(xp_, amp);
        uint256 c = D;
        uint256 S_;
        uint256 Ann = amp * N_COINS;

        uint256 _x;
        for (uint256 k = 0; k < N_COINS; k++) {
            if (k == i) {
                _x = x;
            } else if (k != j) {
                _x = xp_[k];
            } else {
                continue;
            }
            S_ += _x;
            c = (c * D) / (_x * N_COINS);
        }
        c = (c * D) / (Ann * N_COINS);
        uint256 b = S_ + D / Ann; // - D
        uint256 y_prev;
        uint256 y = D;

        for (uint256 m = 0; m < 255; m++) {
            y_prev = y;
            y = (y * y + c) / (2 * y + b - D);
            // Equality with the precision of 1
            if (y > y_prev) {
                if (y - y_prev <= 1) {
                    break;
                }
            } else {
                if (y_prev - y <= 1) {
                    break;
                }
            }
        }
        return y;
    }

    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256) {
        // dx and dy in c-units
        uint256[N_COINS] memory rates = RATES;
        uint256[N_COINS] memory xp = _xp();

        uint256 x = xp[i] + ((dx * rates[i]) / PRECISION);
        uint256 y = get_y(i, j, x, xp);
        uint256 dy = ((xp[j] - y - 1) * PRECISION) / rates[j];
        uint256 _fee = (fee * dy) / FEE_DENOMINATOR;
        return dy - _fee;
    }

    function get_dy_underlying(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256) {
        // dx and dy in underlying units
        uint256[N_COINS] memory xp = _xp();
        uint256[N_COINS] memory precisions = PRECISION_MUL;

        uint256 x = xp[i] + dx * precisions[i];
        uint256 y = get_y(i, j, x, xp);
        uint256 dy = (xp[j] - y - 1) / precisions[j];
        uint256 _fee = (fee * dy) / FEE_DENOMINATOR;
        return dy - _fee;
    }

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external payable nonReentrant {
        require(!is_killed, "Killed");
        if (!support_BNB) {
            require(msg.value == 0, "Inconsistent quantity"); // Avoid sending BNB by mistake.
        }

        uint256[N_COINS] memory old_balances = balances;
        uint256[N_COINS] memory xp = _xp_mem(old_balances);

        uint256 x = xp[i] + (dx * RATES[i]) / PRECISION;
        uint256 y = get_y(i, j, x, xp);

        uint256 dy = xp[j] - y - 1; //  -1 just in case there were some rounding errors
        uint256 dy_fee = (dy * fee) / FEE_DENOMINATOR;

        // Convert all to real units
        dy = ((dy - dy_fee) * PRECISION) / RATES[j];
        require(dy >= min_dy, "Exchange resulted in fewer coins than expected");

        uint256 dy_admin_fee = (dy_fee * admin_fee) / FEE_DENOMINATOR;
        dy_admin_fee = (dy_admin_fee * PRECISION) / RATES[j];

        // Change balances exactly in same way as we change actual ERC20 coin amounts
        balances[i] = old_balances[i] + dx;
        // When rounding errors happen, we undercharge admin fee in favor of LP
        balances[j] = old_balances[j] - dy - dy_admin_fee;

        address iAddress = coins[i];
        if (iAddress == BNB_ADDRESS) {
            require(dx == msg.value, "Inconsistent quantity");
        } else {
            IERC20(iAddress).safeTransferFrom(msg.sender, address(this), dx);
        }
        address jAddress = coins[j];
        transfer_out(jAddress, dy);
        emit TokenExchange(msg.sender, i, dx, j, dy);
    }

    function remove_liquidity(uint256 _amount, uint256[N_COINS] memory min_amounts) external nonReentrant {
        uint256 total_supply = token.totalSupply();
        uint256[N_COINS] memory amounts;
        uint256[N_COINS] memory fees; //Fees are unused but we've got them historically in event

        for (uint256 i = 0; i < N_COINS; i++) {
            uint256 value = (balances[i] * _amount) / total_supply;
            require(value >= min_amounts[i], "Withdrawal resulted in fewer coins than expected");
            balances[i] -= value;
            amounts[i] = value;
            transfer_out(coins[i], value);
        }

        token.burnFrom(msg.sender, _amount); // dev: insufficient funds

        emit RemoveLiquidity(msg.sender, amounts, fees, total_supply - _amount);
    }

    function remove_liquidity_imbalance(uint256[N_COINS] memory amounts, uint256 max_burn_amount)
        external
        nonReentrant
    {
        require(!is_killed, "Killed");

        uint256 token_supply = token.totalSupply();
        require(token_supply > 0, "dev: zero total supply");
        uint256 _fee = (fee * N_COINS) / (4 * (N_COINS - 1));
        uint256 _admin_fee = admin_fee;
        uint256 amp = get_A();

        uint256[N_COINS] memory old_balances = balances;
        uint256[N_COINS] memory new_balances = [old_balances[0], old_balances[1]];
        uint256 D0 = get_D_mem(old_balances, amp);
        for (uint256 i = 0; i < N_COINS; i++) {
            new_balances[i] -= amounts[i];
        }
        uint256 D1 = get_D_mem(new_balances, amp);
        uint256[N_COINS] memory fees;
        for (uint256 i = 0; i < N_COINS; i++) {
            uint256 ideal_balance = (D1 * old_balances[i]) / D0;
            uint256 difference;
            if (ideal_balance > new_balances[i]) {
                difference = ideal_balance - new_balances[i];
            } else {
                difference = new_balances[i] - ideal_balance;
            }
            fees[i] = (_fee * difference) / FEE_DENOMINATOR;
            balances[i] = new_balances[i] - ((fees[i] * _admin_fee) / FEE_DENOMINATOR);
            new_balances[i] -= fees[i];
        }
        uint256 D2 = get_D_mem(new_balances, amp);

        uint256 token_amount = ((D0 - D2) * token_supply) / D0;
        require(token_amount > 0, "token_amount must be greater than 0");
        token_amount += 1; // In case of rounding errors - make it unfavorable for the "attacker"
        require(token_amount <= max_burn_amount, "Slippage screwed you");

        token.burnFrom(msg.sender, token_amount); // dev: insufficient funds

        for (uint256 i = 0; i < N_COINS; i++) {
            if (amounts[i] > 0) {
                transfer_out(coins[i], amounts[i]);
            }
        }
        token_supply -= token_amount;
        emit RemoveLiquidityImbalance(msg.sender, amounts, fees, D1, token_supply);
    }

    function get_y_D(
        uint256 A_,
        uint256 i,
        uint256[N_COINS] memory xp,
        uint256 D
    ) internal pure returns (uint256) {
        /**
        Calculate x[i] if one reduces D from being calculated for xp to D

        Done by solving quadratic equation iteratively.
        x_1**2 + x1 * (sum' - (A*n**n - 1) * D / (A * n**n)) = D ** (n + 1) / (n ** (2 * n) * prod' * A)
        x_1**2 + b*x_1 = c

        x_1 = (x_1**2 + c) / (2*x_1 + b)
        */
        // x in the input is converted to the same price/precision
        require(i < N_COINS, "dev: i above N_COINS");
        uint256 c = D;
        uint256 S_;
        uint256 Ann = A_ * N_COINS;

        uint256 _x;
        for (uint256 k = 0; k < N_COINS; k++) {
            if (k != i) {
                _x = xp[k];
            } else {
                continue;
            }
            S_ += _x;
            c = (c * D) / (_x * N_COINS);
        }
        c = (c * D) / (Ann * N_COINS);
        uint256 b = S_ + D / Ann;
        uint256 y_prev;
        uint256 y = D;

        for (uint256 k = 0; k < 255; k++) {
            y_prev = y;
            y = (y * y + c) / (2 * y + b - D);
            // Equality with the precision of 1
            if (y > y_prev) {
                if (y - y_prev <= 1) {
                    break;
                }
            } else {
                if (y_prev - y <= 1) {
                    break;
                }
            }
        }
        return y;
    }

    function _calc_withdraw_one_coin(uint256 _token_amount, uint256 i) internal view returns (uint256, uint256) {
        // First, need to calculate
        // * Get current D
        // * Solve Eqn against y_i for D - _token_amount
        uint256 amp = get_A();
        uint256 _fee = (fee * N_COINS) / (4 * (N_COINS - 1));
        uint256[N_COINS] memory precisions = PRECISION_MUL;
        uint256 total_supply = token.totalSupply();

        uint256[N_COINS] memory xp = _xp();

        uint256 D0 = get_D(xp, amp);
        uint256 D1 = D0 - (_token_amount * D0) / total_supply;
        uint256[N_COINS] memory xp_reduced = xp;

        uint256 new_y = get_y_D(amp, i, xp, D1);
        uint256 dy_0 = (xp[i] - new_y) / precisions[i]; // w/o fees

        for (uint256 k = 0; k < N_COINS; k++) {
            uint256 dx_expected;
            if (k == i) {
                dx_expected = (xp[k] * D1) / D0 - new_y;
            } else {
                dx_expected = xp[k] - (xp[k] * D1) / D0;
            }
            xp_reduced[k] -= (_fee * dx_expected) / FEE_DENOMINATOR;
        }
        uint256 dy = xp_reduced[i] - get_y_D(amp, i, xp_reduced, D1);
        dy = (dy - 1) / precisions[i]; // Withdraw less to account for rounding errors

        return (dy, dy_0 - dy);
    }

    function calc_withdraw_one_coin(uint256 _token_amount, uint256 i) external view returns (uint256) {
        (uint256 dy, ) = _calc_withdraw_one_coin(_token_amount, i);
        return dy;
    }

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        uint256 i,
        uint256 min_amount
    ) external nonReentrant {
        // Remove _amount of liquidity all in a form of coin i
        require(!is_killed, "Killed");
        (uint256 dy, uint256 dy_fee) = _calc_withdraw_one_coin(_token_amount, i);
        require(dy >= min_amount, "Not enough coins removed");

        balances[i] -= (dy + (dy_fee * admin_fee) / FEE_DENOMINATOR);
        token.burnFrom(msg.sender, _token_amount); // dev: insufficient funds
        transfer_out(coins[i], dy);

        emit RemoveLiquidityOne(msg.sender, i, _token_amount, dy);
    }

    function transfer_out(address coin_address, uint256 value) internal {
        if (coin_address == BNB_ADDRESS) {
            _safeTransferBNB(msg.sender, value);
        } else {
            IERC20(coin_address).safeTransfer(msg.sender, value);
        }
    }

    function transfer_in(address coin_address, uint256 value) internal {
        if (coin_address == BNB_ADDRESS) {
            require(value == msg.value, "Inconsistent quantity");
        } else {
            IERC20(coin_address).safeTransferFrom(msg.sender, address(this), value);
        }
    }

    function _safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{gas: bnb_gas, value: value}("");
        require(success, "BNB transfer failed");
    }

    // Admin functions

    function set_bnb_gas(uint256 _bnb_gas) external onlyOwner {
        require(_bnb_gas >= MIN_BNB_GAS && _bnb_gas <= MAX_BNB_GAS, "Illegal gas");
        bnb_gas = _bnb_gas;
        emit SetBNBGas(_bnb_gas);
    }

    function ramp_A(uint256 _future_A, uint256 _future_time) external onlyOwner {
        require(block.timestamp >= initial_A_time + MIN_RAMP_TIME, "dev : too early");
        require(_future_time >= block.timestamp + MIN_RAMP_TIME, "dev: insufficient time");

        uint256 _initial_A = get_A();
        require(_future_A > 0 && _future_A < MAX_A, "_future_A must be between 0 and MAX_A");
        require(
            (_future_A >= _initial_A && _future_A <= _initial_A * MAX_A_CHANGE) ||
                (_future_A < _initial_A && _future_A * MAX_A_CHANGE >= _initial_A),
            "Illegal parameter _future_A"
        );
        initial_A = _initial_A;
        future_A = _future_A;
        initial_A_time = block.timestamp;
        future_A_time = _future_time;

        emit RampA(_initial_A, _future_A, block.timestamp, _future_time);
    }

    function stop_rampget_A() external onlyOwner {
        uint256 current_A = get_A();
        initial_A = current_A;
        future_A = current_A;
        initial_A_time = block.timestamp;
        future_A_time = block.timestamp;
        // now (block.timestamp < t1) is always False, so we return saved A

        emit StopRampA(current_A, block.timestamp);
    }

    function commit_new_fee(uint256 new_fee, uint256 new_admin_fee) external onlyOwner {
        require(admin_actions_deadline == 0, "admin_actions_deadline must be 0"); // dev: active action
        require(new_fee <= MAX_FEE, "dev: fee exceeds maximum");
        require(new_admin_fee <= MAX_ADMIN_FEE, "dev: admin fee exceeds maximum");

        admin_actions_deadline = block.timestamp + ADMIN_ACTIONS_DELAY;
        future_fee = new_fee;
        future_admin_fee = new_admin_fee;

        emit CommitNewFee(admin_actions_deadline, new_fee, new_admin_fee);
    }

    function apply_new_fee() external onlyOwner {
        require(block.timestamp >= admin_actions_deadline, "dev: insufficient time");
        require(admin_actions_deadline != 0, "admin_actions_deadline should not be 0");

        admin_actions_deadline = 0;
        fee = future_fee;
        admin_fee = future_admin_fee;

        emit NewFee(fee, admin_fee);
    }

    function revert_new_parameters() external onlyOwner {
        admin_actions_deadline = 0;
        emit RevertParameters();
    }

    function admin_balances(uint256 i) external view returns (uint256) {
        if (coins[i] == BNB_ADDRESS) {
            return address(this).balance - balances[i];
        } else {
            return IERC20(coins[i]).balanceOf(address(this)) - balances[i];
        }
    }

    function withdraw_admin_fees() external onlyOwner {
        for (uint256 i = 0; i < N_COINS; i++) {
            uint256 value;
            if (coins[i] == BNB_ADDRESS) {
                value = address(this).balance - balances[i];
            } else {
                value = IERC20(coins[i]).balanceOf(address(this)) - balances[i];
            }
            if (value > 0) {
                transfer_out(coins[i], value);
            }
        }
    }

    function donate_admin_fees() external onlyOwner {
        for (uint256 i = 0; i < N_COINS; i++) {
            if (coins[i] == BNB_ADDRESS) {
                balances[i] = address(this).balance;
            } else {
                balances[i] = IERC20(coins[i]).balanceOf(address(this));
            }
        }
        emit DonateAdminFees();
    }

    function kill_me() external onlyOwner {
        require(kill_deadline > block.timestamp, "Exceeded deadline");
        is_killed = true;
        emit Kill();
    }

    function unkill_me() external onlyOwner {
        is_killed = false;
        emit Unkill();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IPancakeStableSwapLP {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function mint(address _to, uint256 _amount) external;

    function burnFrom(address _to, uint256 _amount) external;

    function setMinter(address _newMinter) external;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}