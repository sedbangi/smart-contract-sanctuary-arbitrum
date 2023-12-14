pragma solidity >=0.5.0;

// SPDX-License-Identifier: GPL-2.0-or-later


import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

pragma solidity >=0.5.0;

// SPDX-License-Identifier: GPL-2.0-or-later


/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

pragma solidity >=0.5.0;

// SPDX-License-Identifier: GPL-2.0-or-later


/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

pragma solidity >=0.5.0;

// SPDX-License-Identifier: GPL-2.0-or-later


/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

pragma solidity >=0.5.0;

// SPDX-License-Identifier: GPL-2.0-or-later


/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

pragma solidity >=0.5.0;

// SPDX-License-Identifier: GPL-2.0-or-later


/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

pragma solidity >=0.5.0;

// SPDX-License-Identifier: GPL-2.0-or-later


/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

pragma solidity >=0.4.0 <0.8.0;

// SPDX-License-Identifier: MIT


/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

pragma solidity >=0.5.0 <0.8.0;

// SPDX-License-Identifier: GPL-2.0-or-later


/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(MAX_TICK), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}

pragma solidity >=0.5.0 <0.8.0;

// SPDX-License-Identifier: GPL-2.0-or-later


import '@uniswap/v3-core/contracts/libraries/FullMath.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

/// @title Oracle library
/// @notice Provides functions to integrate with V3 pool oracle
library OracleLibrary {
    /// @notice Calculates time-weighted means of tick and liquidity for a given Uniswap V3 pool
    /// @param pool Address of the pool that we want to observe
    /// @param secondsAgo Number of seconds in the past from which to calculate the time-weighted means
    /// @return arithmeticMeanTick The arithmetic mean tick from (block.timestamp - secondsAgo) to block.timestamp
    /// @return harmonicMeanLiquidity The harmonic mean liquidity from (block.timestamp - secondsAgo) to block.timestamp
    function consult(address pool, uint32 secondsAgo)
        internal
        view
        returns (int24 arithmeticMeanTick, uint128 harmonicMeanLiquidity)
    {
        require(secondsAgo != 0, 'BP');

        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = secondsAgo;
        secondsAgos[1] = 0;

        (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s) =
            IUniswapV3Pool(pool).observe(secondsAgos);

        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
        uint160 secondsPerLiquidityCumulativesDelta =
            secondsPerLiquidityCumulativeX128s[1] - secondsPerLiquidityCumulativeX128s[0];

        arithmeticMeanTick = int24(tickCumulativesDelta / secondsAgo);
        // Always round to negative infinity
        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % secondsAgo != 0)) arithmeticMeanTick--;

        // We are multiplying here instead of shifting to ensure that harmonicMeanLiquidity doesn't overflow uint128
        uint192 secondsAgoX160 = uint192(secondsAgo) * type(uint160).max;
        harmonicMeanLiquidity = uint128(secondsAgoX160 / (uint192(secondsPerLiquidityCumulativesDelta) << 32));
    }

    /// @notice Given a tick and a token amount, calculates the amount of token received in exchange
    /// @param tick Tick value used to calculate the quote
    /// @param baseAmount Amount of token to be converted
    /// @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
    /// @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
    /// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
    function getQuoteAtTick(
        int24 tick,
        uint128 baseAmount,
        address baseToken,
        address quoteToken
    ) internal pure returns (uint256 quoteAmount) {
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

        // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX192, baseAmount, 1 << 192)
                : FullMath.mulDiv(1 << 192, baseAmount, ratioX192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, 1 << 64);
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX128, baseAmount, 1 << 128)
                : FullMath.mulDiv(1 << 128, baseAmount, ratioX128);
        }
    }

    /// @notice Given a pool, it returns the number of seconds ago of the oldest stored observation
    /// @param pool Address of Uniswap V3 pool that we want to observe
    /// @return secondsAgo The number of seconds ago of the oldest observation stored for the pool
    function getOldestObservationSecondsAgo(address pool) internal view returns (uint32 secondsAgo) {
        (, , uint16 observationIndex, uint16 observationCardinality, , , ) = IUniswapV3Pool(pool).slot0();
        require(observationCardinality > 0, 'NI');

        (uint32 observationTimestamp, , , bool initialized) =
            IUniswapV3Pool(pool).observations((observationIndex + 1) % observationCardinality);

        // The next index might not be initialized if the cardinality is in the process of increasing
        // In this case the oldest observation is always in index 0
        if (!initialized) {
            (observationTimestamp, , , ) = IUniswapV3Pool(pool).observations(0);
        }

        secondsAgo = uint32(block.timestamp) - observationTimestamp;
    }

    /// @notice Given a pool, it returns the tick value as of the start of the current block
    /// @param pool Address of Uniswap V3 pool
    /// @return The tick that the pool was in at the start of the current block
    function getBlockStartingTickAndLiquidity(address pool) internal view returns (int24, uint128) {
        (, int24 tick, uint16 observationIndex, uint16 observationCardinality, , , ) = IUniswapV3Pool(pool).slot0();

        // 2 observations are needed to reliably calculate the block starting tick
        require(observationCardinality > 1, 'NEO');

        // If the latest observation occurred in the past, then no tick-changing trades have happened in this block
        // therefore the tick in `slot0` is the same as at the beginning of the current block.
        // We don't need to check if this observation is initialized - it is guaranteed to be.
        (uint32 observationTimestamp, int56 tickCumulative, uint160 secondsPerLiquidityCumulativeX128, ) =
            IUniswapV3Pool(pool).observations(observationIndex);
        if (observationTimestamp != uint32(block.timestamp)) {
            return (tick, IUniswapV3Pool(pool).liquidity());
        }

        uint256 prevIndex = (uint256(observationIndex) + observationCardinality - 1) % observationCardinality;
        (
            uint32 prevObservationTimestamp,
            int56 prevTickCumulative,
            uint160 prevSecondsPerLiquidityCumulativeX128,
            bool prevInitialized
        ) = IUniswapV3Pool(pool).observations(prevIndex);

        require(prevInitialized, 'ONI');

        uint32 delta = observationTimestamp - prevObservationTimestamp;
        tick = int24((tickCumulative - prevTickCumulative) / delta);
        uint128 liquidity =
            uint128(
                (uint192(delta) * type(uint160).max) /
                    (uint192(secondsPerLiquidityCumulativeX128 - prevSecondsPerLiquidityCumulativeX128) << 32)
            );
        return (tick, liquidity);
    }

    /// @notice Information for calculating a weighted arithmetic mean tick
    struct WeightedTickData {
        int24 tick;
        uint128 weight;
    }

    /// @notice Given an array of ticks and weights, calculates the weighted arithmetic mean tick
    /// @param weightedTickData An array of ticks and weights
    /// @return weightedArithmeticMeanTick The weighted arithmetic mean tick
    /// @dev Each entry of `weightedTickData` should represents ticks from pools with the same underlying pool tokens. If they do not,
    /// extreme care must be taken to ensure that ticks are comparable (including decimal differences).
    /// @dev Note that the weighted arithmetic mean tick corresponds to the weighted geometric mean price.
    function getWeightedArithmeticMeanTick(WeightedTickData[] memory weightedTickData)
        internal
        pure
        returns (int24 weightedArithmeticMeanTick)
    {
        // Accumulates the sum of products between each tick and its weight
        int256 numerator;

        // Accumulates the sum of the weights
        uint256 denominator;

        // Products fit in 152 bits, so it would take an array of length ~2**104 to overflow this logic
        for (uint256 i; i < weightedTickData.length; i++) {
            numerator += weightedTickData[i].tick * int256(weightedTickData[i].weight);
            denominator += weightedTickData[i].weight;
        }

        weightedArithmeticMeanTick = int24(numerator / int256(denominator));
        // Always round to negative infinity
        if (numerator < 0 && (numerator % int256(denominator) != 0)) weightedArithmeticMeanTick--;
    }

    /// @notice Returns the "synthetic" tick which represents the price of the first entry in `tokens` in terms of the last
    /// @dev Useful for calculating relative prices along routes.
    /// @dev There must be one tick for each pairwise set of tokens.
    /// @param tokens The token contract addresses
    /// @param ticks The ticks, representing the price of each token pair in `tokens`
    /// @return syntheticTick The synthetic tick, representing the relative price of the outermost tokens in `tokens`
    function getChainedPrice(address[] memory tokens, int24[] memory ticks)
        internal
        pure
        returns (int256 syntheticTick)
    {
        require(tokens.length - 1 == ticks.length, 'DL');
        for (uint256 i = 1; i <= ticks.length; i++) {
            // check the tokens for address sort order, then accumulate the
            // ticks into the running synthetic tick, ensuring that intermediate tokens "cancel out"
            tokens[i - 1] < tokens[i] ? syntheticTick += ticks[i - 1] : syntheticTick -= ticks[i - 1];
        }
    }
}

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9



interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9



interface IReserves {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1);

    function getFees() external view returns (uint256 fee0, uint256 fee1);
}

pragma solidity 0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9




import '../libraries/Orders.sol';

interface ITwapDelay {
    event OrderExecuted(uint256 indexed id, bool indexed success, bytes data, uint256 gasSpent, uint256 ethRefunded);
    event EthRefund(address indexed to, bool indexed success, uint256 value);
    event OwnerSet(address owner);
    event FactoryGovernorSet(address factoryGovernor);
    event BotSet(address bot, bool isBot);
    event DelaySet(uint256 delay);
    event RelayerSet(address relayer);
    event MaxGasLimitSet(uint256 maxGasLimit);
    event GasPriceInertiaSet(uint256 gasPriceInertia);
    event MaxGasPriceImpactSet(uint256 maxGasPriceImpact);
    event TransferGasCostSet(address token, uint256 gasCost);
    event ToleranceSet(address pair, uint16 amount);
    event NonRebasingTokenSet(address token, bool isNonRebasing);

    function factory() external view returns (address);

    function factoryGovernor() external view returns (address);

    function relayer() external view returns (address);

    function owner() external view returns (address);

    function isBot(address bot) external view returns (bool);

    function getTolerance(address pair) external view returns (uint16);

    function isNonRebasingToken(address token) external view returns (bool);

    function gasPriceInertia() external view returns (uint256);

    function gasPrice() external view returns (uint256);

    function maxGasPriceImpact() external view returns (uint256);

    function maxGasLimit() external view returns (uint256);

    function delay() external view returns (uint256);

    function totalShares(address token) external view returns (uint256);

    function weth() external view returns (address);

    function getTransferGasCost(address token) external pure returns (uint256);

    function getDepositDisabled(address pair) external view returns (bool);

    function getWithdrawDisabled(address pair) external view returns (bool);

    function getBuyDisabled(address pair) external view returns (bool);

    function getSellDisabled(address pair) external view returns (bool);

    function getOrderStatus(uint256 orderId, uint256 validAfterTimestamp) external view returns (Orders.OrderStatus);

    function setOrderTypesDisabled(
        address pair,
        Orders.OrderType[] calldata orderTypes,
        bool disabled
    ) external;

    function setOwner(address _owner) external;

    function setFactoryGovernor(address _factoryGovernor) external;

    function setBot(address _bot, bool _isBot) external;

    function deposit(Orders.DepositParams memory depositParams) external payable returns (uint256 orderId);

    function withdraw(Orders.WithdrawParams memory withdrawParams) external payable returns (uint256 orderId);

    function sell(Orders.SellParams memory sellParams) external payable returns (uint256 orderId);

    function relayerSell(Orders.SellParams memory sellParams) external payable returns (uint256 orderId);

    function buy(Orders.BuyParams memory buyParams) external payable returns (uint256 orderId);

    function execute(Orders.Order[] calldata orders) external payable;

    function retryRefund(Orders.Order calldata order) external;

    function cancelOrder(Orders.Order calldata order) external;

    function syncPair(address token0, address token1) external returns (address pairAddress);
}

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9



import './IERC20.sol';

interface ITwapERC20 is IERC20 {
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

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9



interface ITwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);
    event OwnerSet(address owner);

    function owner() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB,
        address oracle,
        address trader
    ) external returns (address pair);

    function setOwner(address) external;

    function setMintFee(
        address tokenA,
        address tokenB,
        uint256 fee
    ) external;

    function setBurnFee(
        address tokenA,
        address tokenB,
        uint256 fee
    ) external;

    function setSwapFee(
        address tokenA,
        address tokenB,
        uint256 fee
    ) external;

    function setOracle(
        address tokenA,
        address tokenB,
        address oracle
    ) external;

    function setTrader(
        address tokenA,
        address tokenB,
        address trader
    ) external;

    function collect(
        address tokenA,
        address tokenB,
        address to
    ) external;

    function withdraw(
        address tokenA,
        address tokenB,
        uint256 amount,
        address to
    ) external;
}

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9



interface ITwapOracle {
    event OwnerSet(address owner);
    event UniswapPairSet(address uniswapPair);

    function decimalsConverter() external view returns (int256);

    function xDecimals() external view returns (uint8);

    function yDecimals() external view returns (uint8);

    function owner() external view returns (address);

    function uniswapPair() external view returns (address);

    function getPriceInfo() external view returns (uint256 priceAccumulator, uint256 priceTimestamp);

    function getSpotPrice() external view returns (uint256);

    function getAveragePrice(uint256 priceAccumulator, uint256 priceTimestamp) external view returns (uint256);

    function setOwner(address _owner) external;

    function setUniswapPair(address _uniswapPair) external;

    function tradeX(
        uint256 xAfter,
        uint256 xBefore,
        uint256 yBefore,
        bytes calldata data
    ) external view returns (uint256 yAfter);

    function tradeY(
        uint256 yAfter,
        uint256 yBefore,
        uint256 xBefore,
        bytes calldata data
    ) external view returns (uint256 xAfter);

    function depositTradeXIn(
        uint256 xLeft,
        uint256 xBefore,
        uint256 yBefore,
        bytes calldata data
    ) external view returns (uint256 xIn);

    function depositTradeYIn(
        uint256 yLeft,
        uint256 yBefore,
        uint256 xBefore,
        bytes calldata data
    ) external view returns (uint256 yIn);

    function getSwapAmount0Out(
        uint256 swapFee,
        uint256 amount1In,
        bytes calldata data
    ) external view returns (uint256 amount0Out);

    function getSwapAmount1Out(
        uint256 swapFee,
        uint256 amount0In,
        bytes calldata data
    ) external view returns (uint256 amount1Out);

    function getSwapAmountInMaxOut(
        bool inverse,
        uint256 swapFee,
        uint256 _amountOut,
        bytes calldata data
    ) external view returns (uint256 amountIn, uint256 amountOut);

    function getSwapAmountInMinOut(
        bool inverse,
        uint256 swapFee,
        uint256 _amountOut,
        bytes calldata data
    ) external view returns (uint256 amountIn, uint256 amountOut);
}

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9



import './ITwapOracle.sol';

interface ITwapOracleV3 is ITwapOracle {
    event TwapIntervalSet(uint32 interval);

    function setTwapInterval(uint32 _interval) external;
}

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9



import './ITwapERC20.sol';
import './IReserves.sol';

interface ITwapPair is ITwapERC20, IReserves {
    event Mint(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 liquidityOut, address indexed to);
    event Burn(address indexed sender, uint256 amount0Out, uint256 amount1Out, uint256 liquidityIn, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event SetMintFee(uint256 fee);
    event SetBurnFee(uint256 fee);
    event SetSwapFee(uint256 fee);
    event SetOracle(address account);
    event SetTrader(address trader);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function oracle() external view returns (address);

    function trader() external view returns (address);

    function mintFee() external view returns (uint256);

    function setMintFee(uint256 fee) external;

    function mint(address to) external returns (uint256 liquidity);

    function burnFee() external view returns (uint256);

    function setBurnFee(uint256 fee) external;

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swapFee() external view returns (uint256);

    function setSwapFee(uint256 fee) external;

    function setOracle(address account) external;

    function setTrader(address account) external;

    function collect(address to) external;

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function sync() external;

    function initialize(
        address _token0,
        address _token1,
        address _oracle,
        address _trader
    ) external;

    function getSwapAmount0In(uint256 amount1Out, bytes calldata data) external view returns (uint256 swapAmount0In);

    function getSwapAmount1In(uint256 amount0Out, bytes calldata data) external view returns (uint256 swapAmount1In);

    function getSwapAmount0Out(uint256 amount1In, bytes calldata data) external view returns (uint256 swapAmount0Out);

    function getSwapAmount1Out(uint256 amount0In, bytes calldata data) external view returns (uint256 swapAmount1Out);

    function getDepositAmount0In(uint256 amount0, bytes calldata data) external view returns (uint256 depositAmount0In);

    function getDepositAmount1In(uint256 amount1, bytes calldata data) external view returns (uint256 depositAmount1In);
}

pragma solidity 0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9




import '../libraries/Orders.sol';

interface ITwapRelayer {
    event OwnerSet(address owner);
    event RebalancerSet(address rebalancer);
    event DelaySet(address delay);
    event PairEnabledSet(address pair, bool enabled);
    event SwapFeeSet(address pair, uint256 fee);
    event TwapIntervalSet(address pair, uint32 interval);
    event EthTransferGasCostSet(uint256 gasCost);
    event ExecutionGasLimitSet(uint256 limit);
    event TokenLimitMinSet(address token, uint256 limit);
    event TokenLimitMaxMultiplierSet(address token, uint256 limit);
    event ToleranceSet(address pair, uint16 tolerance);
    event Approve(address token, address to, uint256 amount);
    event Withdraw(address token, address to, uint256 amount);
    event Sell(
        address indexed sender,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 amountOutMin,
        bool wrapUnwrap,
        uint256 fee,
        address indexed to,
        address orderContract,
        uint256 indexed orderId
    );
    event Buy(
        address indexed sender,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountInMax,
        uint256 amountOut,
        bool wrapUnwrap,
        uint256 fee,
        address indexed to,
        address orderContract,
        uint256 indexed orderId
    );
    event RebalanceSellWithDelay(
        address indexed sender,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 indexed delayOrderId
    );
    event RebalanceSellWithOneInch(address indexed oneInchRouter, uint256 gas, bytes data);
    event OneInchRouterWhitelisted(address indexed oneInchRouter, bool whitelisted);
    event WrapEth(uint256 amount);
    event UnwrapWeth(uint256 amount);

    function factory() external pure returns (address);

    function delay() external pure returns (address);

    function weth() external pure returns (address);

    function owner() external view returns (address);

    function rebalancer() external view returns (address);

    function isOneInchRouterWhitelisted(address oneInchRouter) external view returns (bool);

    function setOwner(address _owner) external;

    function swapFee(address pair) external view returns (uint256);

    function setSwapFee(address pair, uint256 fee) external;

    function twapInterval(address pair) external pure returns (uint32);

    function isPairEnabled(address pair) external view returns (bool);

    function setPairEnabled(address pair, bool enabled) external;

    function ethTransferGasCost() external pure returns (uint256);

    function executionGasLimit() external pure returns (uint256);

    function tokenLimitMin(address token) external pure returns (uint256);

    function tokenLimitMaxMultiplier(address token) external pure returns (uint256);

    function tolerance(address pair) external pure returns (uint16);

    function setRebalancer(address _rebalancer) external;

    function whitelistOneInchRouter(address oneInchRouter, bool whitelisted) external;

    function getTolerance(address pair) external pure returns (uint16);

    function getTokenLimitMin(address token) external pure returns (uint256);

    function getTokenLimitMaxMultiplier(address token) external pure returns (uint256);

    function getTwapInterval(address pair) external pure returns (uint32);

    struct SellParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOutMin;
        bool wrapUnwrap;
        address to;
        uint32 submitDeadline;
    }

    function sell(SellParams memory sellParams) external payable returns (uint256 orderId);

    struct BuyParams {
        address tokenIn;
        address tokenOut;
        uint256 amountInMax;
        uint256 amountOut;
        bool wrapUnwrap;
        address to;
        uint32 submitDeadline;
    }

    function buy(BuyParams memory buyParams) external payable returns (uint256 orderId);

    function getPriceByPairAddress(address pair, bool inverted)
        external
        view
        returns (
            uint8 xDecimals,
            uint8 yDecimals,
            uint256 price
        );

    function getPriceByTokenAddresses(address tokenIn, address tokenOut) external view returns (uint256 price);

    function getPoolState(address token0, address token1)
        external
        view
        returns (
            uint256 price,
            uint256 fee,
            uint256 limitMin0,
            uint256 limitMax0,
            uint256 limitMin1,
            uint256 limitMax1
        );

    function quoteSell(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (uint256 amountOut);

    function quoteBuy(
        address tokenIn,
        address tokenOut,
        uint256 amountOut
    ) external view returns (uint256 amountIn);

    function approve(
        address token,
        uint256 amount,
        address to
    ) external;

    function withdraw(
        address token,
        uint256 amount,
        address to
    ) external;

    function rebalanceSellWithDelay(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external;

    function rebalanceSellWithOneInch(
        address tokenIn,
        uint256 amountIn,
        address oneInchRouter,
        uint256 _gas,
        bytes calldata data
    ) external;

    function wrapEth(uint256 amount) external;

    function unwrapWeth(uint256 amount) external;
}

pragma solidity 0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9




interface ITwapRelayerInitializable {
    event Initialized(address _factory, address _delay, address _weth);

    function initialize() external;
}

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9



interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9



// a library for performing various math operations

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x > y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

pragma solidity 0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9




import './SafeMath.sol';
import '../libraries/Math.sol';
import '../interfaces/ITwapFactory.sol';
import '../interfaces/ITwapPair.sol';
import '../interfaces/ITwapOracle.sol';
import '../libraries/TokenShares.sol';


library Orders {
    using SafeMath for uint256;
    using TokenShares for TokenShares.Data;
    using TransferHelper for address;

    enum OrderType {
        Empty,
        Deposit,
        Withdraw,
        Sell,
        Buy
    }
    enum OrderStatus {
        NonExistent,
        EnqueuedWaiting,
        EnqueuedReady,
        ExecutedSucceeded,
        ExecutedFailed,
        Canceled
    }

    event DepositEnqueued(uint256 indexed orderId, Order order);
    event WithdrawEnqueued(uint256 indexed orderId, Order order);
    event SellEnqueued(uint256 indexed orderId, Order order);
    event BuyEnqueued(uint256 indexed orderId, Order order);

    event OrderTypesDisabled(address pair, Orders.OrderType[] orderTypes, bool disabled);

    event RefundFailed(address indexed to, address indexed token, uint256 amount, bytes data);

    // Note on gas estimation for the full order execution in the UI:
    // Add (ORDER_BASE_COST + token transfer costs) to the actual gas usage
    // of the TwapDelay._execute* functions when updating gas cost in the UI.
    // Remember that ETH unwrap is part of those functions. It is optional,
    // but also needs to be included in the estimate.

    uint256 public constant ETHER_TRANSFER_COST = ETHER_TRANSFER_CALL_COST + 2600 + 1504; // Std cost + EIP-2929 acct access cost + Gnosis Safe receive ETH cost
    uint256 private constant BOT_ETHER_TRANSFER_COST = 10_000;
    uint256 private constant BUFFER_COST = 10_000;
    uint256 private constant ORDER_EXECUTED_EVENT_COST = 3700;
    uint256 private constant EXECUTE_PREPARATION_COST = 30_000; // dequeue + gas calculation before calls to _execute* functions

    uint256 public constant ETHER_TRANSFER_CALL_COST = 10_000;
    uint256 public constant PAIR_TRANSFER_COST = 55_000;
    uint256 public constant REFUND_BASE_COST =
        BOT_ETHER_TRANSFER_COST + ETHER_TRANSFER_COST + BUFFER_COST + ORDER_EXECUTED_EVENT_COST;
    uint256 public constant ORDER_BASE_COST = EXECUTE_PREPARATION_COST + REFUND_BASE_COST;

    // Masks used for setting order disabled
    // Different bits represent different order types
    uint8 private constant DEPOSIT_MASK = uint8(1 << uint8(OrderType.Deposit)); //   00000010
    uint8 private constant WITHDRAW_MASK = uint8(1 << uint8(OrderType.Withdraw)); // 00000100
    uint8 private constant SELL_MASK = uint8(1 << uint8(OrderType.Sell)); //         00001000
    uint8 private constant BUY_MASK = uint8(1 << uint8(OrderType.Buy)); //           00010000

    address public constant FACTORY_ADDRESS = 0x717EF162cf831db83c51134734A15D1EBe9E516a; 
    uint256 public constant MAX_GAS_LIMIT = 5000000; 
    uint256 public constant GAS_PRICE_INERTIA = 20000000; 
    uint256 public constant MAX_GAS_PRICE_IMPACT = 1000000; 
    uint256 public constant DELAY = 1800; 

    address public constant NATIVE_CURRENCY_SENTINEL = address(0); // A sentinel value for the native currency to distinguish it from ERC20 tokens

    struct Data {
        uint256 newestOrderId;
        uint256 lastProcessedOrderId;
        mapping(uint256 => bytes32) orderQueue;
        uint256 gasPrice;
        mapping(uint256 => bool) canceled;
        // Bit on specific positions indicates whether order type is disabled (1) or enabled (0) on specific pair
        mapping(address => uint8) orderTypesDisabled;
        mapping(uint256 => bool) refundFailed;
    }

    struct Order {
        uint256 orderId;
        OrderType orderType;
        bool inverted;
        uint256 validAfterTimestamp;
        bool unwrap;
        uint256 timestamp;
        uint256 gasLimit;
        uint256 gasPrice;
        uint256 liquidity;
        uint256 value0; // Deposit: share0, Withdraw: amount0Min, Sell: shareIn, Buy: shareInMax
        uint256 value1; // Deposit: share1, Withdraw: amount1Min, Sell: amountOutMin, Buy: amountOut
        address token0; // Sell: tokenIn, Buy: tokenIn
        address token1; // Sell: tokenOut, Buy: tokenOut
        address to;
        uint256 minSwapPrice;
        uint256 maxSwapPrice;
        bool swap;
        uint256 priceAccumulator;
        uint256 amountLimit0;
        uint256 amountLimit1;
    }

    function getOrderStatus(
        Data storage data,
        uint256 orderId,
        uint256 validAfterTimestamp
    ) internal view returns (OrderStatus) {
        if (orderId > data.newestOrderId) {
            return OrderStatus.NonExistent;
        }
        if (data.canceled[orderId]) {
            return OrderStatus.Canceled;
        }
        if (data.refundFailed[orderId]) {
            return OrderStatus.ExecutedFailed;
        }
        if (data.orderQueue[orderId] == bytes32(0)) {
            return OrderStatus.ExecutedSucceeded;
        }
        if (validAfterTimestamp >= block.timestamp) {
            return OrderStatus.EnqueuedWaiting;
        }
        return OrderStatus.EnqueuedReady;
    }

    function getPair(address tokenA, address tokenB) internal view returns (address pair, bool inverted) {
        pair = ITwapFactory(FACTORY_ADDRESS).getPair(tokenA, tokenB);
        require(pair != address(0), 'OS17');
        inverted = tokenA > tokenB;
    }

    function getDepositDisabled(Data storage data, address pair) internal view returns (bool) {
        return data.orderTypesDisabled[pair] & DEPOSIT_MASK != 0;
    }

    function getWithdrawDisabled(Data storage data, address pair) internal view returns (bool) {
        return data.orderTypesDisabled[pair] & WITHDRAW_MASK != 0;
    }

    function getSellDisabled(Data storage data, address pair) internal view returns (bool) {
        return data.orderTypesDisabled[pair] & SELL_MASK != 0;
    }

    function getBuyDisabled(Data storage data, address pair) internal view returns (bool) {
        return data.orderTypesDisabled[pair] & BUY_MASK != 0;
    }

    function setOrderTypesDisabled(
        Data storage data,
        address pair,
        Orders.OrderType[] calldata orderTypes,
        bool disabled
    ) external {
        uint256 orderTypesLength = orderTypes.length;
        uint8 currentSettings = data.orderTypesDisabled[pair];

        uint8 combinedMask;
        for (uint256 i; i < orderTypesLength; ++i) {
            Orders.OrderType orderType = orderTypes[i];
            require(orderType != Orders.OrderType.Empty, 'OS32');
            // zeros with 1 bit set at position specified by orderType
            // e.g. for SELL order type
            // mask for SELL    = 00001000
            // combinedMask     = 00000110 (DEPOSIT and WITHDRAW masks set in previous iterations)
            // the result of OR = 00001110 (DEPOSIT, WITHDRAW and SELL combined mask)
            combinedMask = combinedMask | uint8(1 << uint8(orderType));
        }

        // set/unset a bit accordingly to 'disabled' value
        if (disabled) {
            // OR operation to disable order
            // e.g. for disable DEPOSIT
            // currentSettings   = 00010100 (BUY and WITHDRAW disabled)
            // mask for DEPOSIT  = 00000010
            // the result of OR  = 00010110
            currentSettings = currentSettings | combinedMask;
        } else {
            // AND operation with a mask negation to enable order
            // e.g. for enable DEPOSIT
            // currentSettings   = 00010100 (BUY and WITHDRAW disabled)
            // 0xff              = 11111111
            // mask for Deposit  = 00000010
            // mask negation     = 11111101
            // the result of AND = 00010100
            currentSettings = currentSettings & (combinedMask ^ 0xff);
        }
        require(currentSettings != data.orderTypesDisabled[pair], 'OS01');
        data.orderTypesDisabled[pair] = currentSettings;

        emit OrderTypesDisabled(pair, orderTypes, disabled);
    }

    function markRefundFailed(Data storage data) internal {
        data.refundFailed[data.lastProcessedOrderId] = true;
    }

    /// @dev The passed in order.oderId is ignored and overwritten with the correct value, i.e. an updated data.newestOrderId.
    /// This is done to ensure atomicity of these two actions while optimizing gas usage - adding an order to the queue and incrementing
    /// data.newestOrderId (which should not be done anywhere else in the contract).
    /// Must only be called on verified orders.
    function enqueueOrder(Data storage data, Order memory order) internal {
        order.orderId = ++data.newestOrderId;
        data.orderQueue[order.orderId] = getOrderDigest(order);
    }

    struct DepositParams {
        address token0;
        address token1;
        uint256 amount0;
        uint256 amount1;
        uint256 minSwapPrice;
        uint256 maxSwapPrice;
        bool wrap;
        bool swap;
        address to;
        uint256 gasLimit;
        uint32 submitDeadline;
    }

    function deposit(
        Data storage data,
        DepositParams calldata depositParams,
        TokenShares.Data storage tokenShares
    ) external {
        {
            // scope for checks, avoids stack too deep errors
            uint256 token0TransferCost = getTransferGasCost(depositParams.token0);
            uint256 token1TransferCost = getTransferGasCost(depositParams.token1);
            checkOrderParams(
                depositParams.to,
                depositParams.gasLimit,
                depositParams.submitDeadline,
                ORDER_BASE_COST.add(token0TransferCost).add(token1TransferCost)
            );
        }
        require(depositParams.amount0 != 0 || depositParams.amount1 != 0, 'OS25');
        (address pairAddress, bool inverted) = getPair(depositParams.token0, depositParams.token1);
        require(!getDepositDisabled(data, pairAddress), 'OS46');
        {
            // scope for value, avoids stack too deep errors
            uint256 value = msg.value;

            // allocate gas refund
            if (depositParams.wrap) {
                if (depositParams.token0 == TokenShares.WETH_ADDRESS) {
                    value = msg.value.sub(depositParams.amount0, 'OS1E');
                } else if (depositParams.token1 == TokenShares.WETH_ADDRESS) {
                    value = msg.value.sub(depositParams.amount1, 'OS1E');
                }
            }
            allocateGasRefund(data, value, depositParams.gasLimit);
        }

        uint256 shares0 = tokenShares.amountToShares(
            inverted ? depositParams.token1 : depositParams.token0,
            inverted ? depositParams.amount1 : depositParams.amount0,
            depositParams.wrap
        );
        uint256 shares1 = tokenShares.amountToShares(
            inverted ? depositParams.token0 : depositParams.token1,
            inverted ? depositParams.amount0 : depositParams.amount1,
            depositParams.wrap
        );

        (uint256 priceAccumulator, uint256 timestamp) = ITwapOracle(ITwapPair(pairAddress).oracle()).getPriceInfo();

        Order memory order = Order(
            0,
            OrderType.Deposit,
            inverted,
            timestamp + DELAY, // validAfterTimestamp
            depositParams.wrap,
            timestamp,
            depositParams.gasLimit,
            data.gasPrice,
            0, // liquidity
            shares0,
            shares1,
            inverted ? depositParams.token1 : depositParams.token0,
            inverted ? depositParams.token0 : depositParams.token1,
            depositParams.to,
            depositParams.minSwapPrice,
            depositParams.maxSwapPrice,
            depositParams.swap,
            priceAccumulator,
            inverted ? depositParams.amount1 : depositParams.amount0,
            inverted ? depositParams.amount0 : depositParams.amount1
        );
        enqueueOrder(data, order);

        emit DepositEnqueued(order.orderId, order);
    }

    struct WithdrawParams {
        address token0;
        address token1;
        uint256 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        bool unwrap;
        address to;
        uint256 gasLimit;
        uint32 submitDeadline;
    }

    function withdraw(Data storage data, WithdrawParams calldata withdrawParams) external {
        (address pair, bool inverted) = getPair(withdrawParams.token0, withdrawParams.token1);
        require(!getWithdrawDisabled(data, pair), 'OS0A');
        checkOrderParams(
            withdrawParams.to,
            withdrawParams.gasLimit,
            withdrawParams.submitDeadline,
            ORDER_BASE_COST.add(PAIR_TRANSFER_COST)
        );
        require(withdrawParams.liquidity != 0, 'OS22');

        allocateGasRefund(data, msg.value, withdrawParams.gasLimit);
        pair.safeTransferFrom(msg.sender, address(this), withdrawParams.liquidity);

        Order memory order = Order(
            0,
            OrderType.Withdraw,
            inverted,
            block.timestamp + DELAY, // validAfterTimestamp
            withdrawParams.unwrap,
            0, // timestamp
            withdrawParams.gasLimit,
            data.gasPrice,
            withdrawParams.liquidity,
            inverted ? withdrawParams.amount1Min : withdrawParams.amount0Min,
            inverted ? withdrawParams.amount0Min : withdrawParams.amount1Min,
            inverted ? withdrawParams.token1 : withdrawParams.token0,
            inverted ? withdrawParams.token0 : withdrawParams.token1,
            withdrawParams.to,
            0, // minSwapPrice
            0, // maxSwapPrice
            false, // swap
            0, // priceAccumulator
            0, // amountLimit0
            0 // amountLimit1
        );
        enqueueOrder(data, order);

        emit WithdrawEnqueued(order.orderId, order);
    }

    struct SellParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOutMin;
        bool wrapUnwrap;
        address to;
        uint256 gasLimit;
        uint32 submitDeadline;
    }

    function sell(
        Data storage data,
        SellParams calldata sellParams,
        TokenShares.Data storage tokenShares
    ) external {
        uint256 tokenTransferCost = getTransferGasCost(sellParams.tokenIn);
        checkOrderParams(
            sellParams.to,
            sellParams.gasLimit,
            sellParams.submitDeadline,
            ORDER_BASE_COST.add(tokenTransferCost)
        );

        (address pairAddress, bool inverted) = sellHelper(data, sellParams);

        (uint256 priceAccumulator, uint256 timestamp) = ITwapOracle(ITwapPair(pairAddress).oracle()).getPriceInfo();

        uint256 shares = tokenShares.amountToShares(sellParams.tokenIn, sellParams.amountIn, sellParams.wrapUnwrap);

        Order memory order = Order(
            0,
            OrderType.Sell,
            inverted,
            timestamp + DELAY, // validAfterTimestamp
            sellParams.wrapUnwrap,
            timestamp,
            sellParams.gasLimit,
            data.gasPrice,
            0, // liquidity
            shares,
            sellParams.amountOutMin,
            sellParams.tokenIn,
            sellParams.tokenOut,
            sellParams.to,
            0, // minSwapPrice
            0, // maxSwapPrice
            false, // swap
            priceAccumulator,
            sellParams.amountIn,
            0 // amountLimit1
        );
        enqueueOrder(data, order);

        emit SellEnqueued(order.orderId, order);
    }

    function relayerSell(
        Data storage data,
        SellParams calldata sellParams,
        TokenShares.Data storage tokenShares
    ) external {
        checkOrderParams(sellParams.to, sellParams.gasLimit, sellParams.submitDeadline, ORDER_BASE_COST);

        (, bool inverted) = sellHelper(data, sellParams);

        uint256 shares = tokenShares.amountToSharesWithoutTransfer(
            sellParams.tokenIn,
            sellParams.amountIn,
            sellParams.wrapUnwrap
        );

        Order memory order = Order(
            0,
            OrderType.Sell,
            inverted,
            block.timestamp + DELAY, // validAfterTimestamp
            false, // Never wrap/unwrap
            block.timestamp,
            sellParams.gasLimit,
            data.gasPrice,
            0, // liquidity
            shares,
            sellParams.amountOutMin,
            sellParams.tokenIn,
            sellParams.tokenOut,
            sellParams.to,
            0, // minSwapPrice
            0, // maxSwapPrice
            false, // swap
            0, // priceAccumulator - oracleV3 pairs don't need priceAccumulator
            sellParams.amountIn,
            0 // amountLimit1
        );
        enqueueOrder(data, order);

        emit SellEnqueued(order.orderId, order);
    }

    function sellHelper(Data storage data, SellParams calldata sellParams)
        internal
        returns (address pairAddress, bool inverted)
    {
        require(sellParams.amountIn != 0, 'OS24');
        (pairAddress, inverted) = getPair(sellParams.tokenIn, sellParams.tokenOut);
        require(!getSellDisabled(data, pairAddress), 'OS13');

        // allocate gas refund
        uint256 value = msg.value;
        if (sellParams.wrapUnwrap && sellParams.tokenIn == TokenShares.WETH_ADDRESS) {
            value = msg.value.sub(sellParams.amountIn, 'OS1E');
        }
        allocateGasRefund(data, value, sellParams.gasLimit);
    }

    struct BuyParams {
        address tokenIn;
        address tokenOut;
        uint256 amountInMax;
        uint256 amountOut;
        bool wrapUnwrap;
        address to;
        uint256 gasLimit;
        uint32 submitDeadline;
    }

    function buy(
        Data storage data,
        BuyParams calldata buyParams,
        TokenShares.Data storage tokenShares
    ) external {
        uint256 tokenTransferCost = getTransferGasCost(buyParams.tokenIn);
        checkOrderParams(
            buyParams.to,
            buyParams.gasLimit,
            buyParams.submitDeadline,
            ORDER_BASE_COST.add(tokenTransferCost)
        );
        require(buyParams.amountOut != 0, 'OS23');
        (address pairAddress, bool inverted) = getPair(buyParams.tokenIn, buyParams.tokenOut);
        require(!getBuyDisabled(data, pairAddress), 'OS49');
        uint256 value = msg.value;

        // allocate gas refund
        if (buyParams.tokenIn == TokenShares.WETH_ADDRESS && buyParams.wrapUnwrap) {
            value = msg.value.sub(buyParams.amountInMax, 'OS1E');
        }

        allocateGasRefund(data, value, buyParams.gasLimit);

        uint256 shares = tokenShares.amountToShares(buyParams.tokenIn, buyParams.amountInMax, buyParams.wrapUnwrap);

        (uint256 priceAccumulator, uint256 timestamp) = ITwapOracle(ITwapPair(pairAddress).oracle()).getPriceInfo();

        Order memory order = Order(
            0,
            OrderType.Buy,
            inverted,
            timestamp + DELAY, // validAfterTimestamp
            buyParams.wrapUnwrap,
            timestamp,
            buyParams.gasLimit,
            data.gasPrice,
            0, // liquidity
            shares,
            buyParams.amountOut,
            buyParams.tokenIn,
            buyParams.tokenOut,
            buyParams.to,
            0, // minSwapPrice
            0, // maxSwapPrice
            false, // swap
            priceAccumulator,
            buyParams.amountInMax,
            0 // amountLimit1
        );
        enqueueOrder(data, order);

        emit BuyEnqueued(order.orderId, order);
    }

    function checkOrderParams(
        address to,
        uint256 gasLimit,
        uint32 submitDeadline,
        uint256 minGasLimit
    ) private view {
        require(submitDeadline >= block.timestamp, 'OS04');
        require(gasLimit <= MAX_GAS_LIMIT, 'OS3E');
        require(gasLimit >= minGasLimit, 'OS3D');
        require(to != address(0), 'OS26');
    }

    function allocateGasRefund(
        Data storage data,
        uint256 value,
        uint256 gasLimit
    ) private returns (uint256 futureFee) {
        futureFee = data.gasPrice.mul(gasLimit);
        require(value >= futureFee, 'OS1E');
        if (value > futureFee) {
            TransferHelper.safeTransferETH(
                msg.sender,
                value.sub(futureFee),
                getTransferGasCost(NATIVE_CURRENCY_SENTINEL)
            );
        }
    }

    function updateGasPrice(Data storage data, uint256 gasUsed) external {
        uint256 scale = Math.min(gasUsed, MAX_GAS_PRICE_IMPACT);
        data.gasPrice = data.gasPrice.mul(GAS_PRICE_INERTIA.sub(scale)).add(tx.gasprice.mul(scale)).div(
            GAS_PRICE_INERTIA
        );
    }

    function refundLiquidity(
        address pair,
        address to,
        uint256 liquidity,
        bytes4 selector
    ) internal returns (bool) {
        if (liquidity == 0) {
            return true;
        }
        (bool success, bytes memory data) = address(this).call{ gas: PAIR_TRANSFER_COST }(
            abi.encodeWithSelector(selector, pair, to, liquidity, false)
        );
        if (!success) {
            emit RefundFailed(to, pair, liquidity, data);
        }
        return success;
    }

    function dequeueOrder(Data storage data, uint256 orderId) internal {
        ++data.lastProcessedOrderId;
        require(orderId == data.lastProcessedOrderId, 'OS72');
    }

    function forgetOrder(Data storage data, uint256 orderId) internal {
        delete data.orderQueue[orderId];
    }

    function forgetLastProcessedOrder(Data storage data) internal {
        delete data.orderQueue[data.lastProcessedOrderId];
    }

    function getOrderDigest(Order memory order) internal pure returns (bytes32) {
        // Used to avoid the 'stack too deep' error.
        bytes memory partialOrderData = abi.encodePacked(
            order.orderId,
            order.orderType,
            order.inverted,
            order.validAfterTimestamp,
            order.unwrap,
            order.timestamp,
            order.gasLimit,
            order.gasPrice,
            order.liquidity,
            order.value0,
            order.value1,
            order.token0,
            order.token1,
            order.to
        );

        return
            keccak256(
                abi.encodePacked(
                    partialOrderData,
                    order.minSwapPrice,
                    order.maxSwapPrice,
                    order.swap,
                    order.priceAccumulator,
                    order.amountLimit0,
                    order.amountLimit1
                )
            );
    }

    function verifyOrder(Data storage data, Order memory order) external view {
        require(getOrderDigest(order) == data.orderQueue[order.orderId], 'OS71');
    }

    
    // constant mapping for transferGasCost
    /**
     * @dev This function should either return a default value != 0 or revert.
     */
    function getTransferGasCost(address token) internal pure returns (uint256) {
        if (token == NATIVE_CURRENCY_SENTINEL) return ETHER_TRANSFER_CALL_COST;
        if (token == 0xaf88d065e77c8cC2239327C5EDb3A432268e5831) return 70000;
        if (token == 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8) return 70000;
        return 60000;
    }
}

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9



// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    int256 private constant _INT256_MIN = -2**255;

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'SM4E');
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = sub(x, y, 'SM12');
    }

    function sub(
        uint256 x,
        uint256 y,
        string memory message
    ) internal pure returns (uint256 z) {
        require((z = x - y) <= x, message);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'SM2A');
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SM43');
        return a / b;
    }

    function ceil_div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = div(a, b);
        if (a != mul(b, c)) {
            return add(c, 1);
        }
    }

    function toUint32(uint256 n) internal pure returns (uint32) {
        require(n <= type(uint32).max, 'SM50');
        return uint32(n);
    }

    function toUint64(uint256 n) internal pure returns (uint64) {
        require(n <= type(uint64).max, 'SM54');
        return uint64(n);
    }

    function toUint112(uint256 n) internal pure returns (uint112) {
        require(n <= type(uint112).max, 'SM51');
        return uint112(n);
    }

    function toInt256(uint256 unsigned) internal pure returns (int256 signed) {
        require(unsigned <= uint256(type(int256).max), 'SM34');
        signed = int256(unsigned);
    }

    // int256

    function add(int256 a, int256 b) internal pure returns (int256 c) {
        c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), 'SM4D');
    }

    function sub(int256 a, int256 b) internal pure returns (int256 c) {
        c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), 'SM11');
    }

    function mul(int256 a, int256 b) internal pure returns (int256 c) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), 'SM29');

        c = a * b;
        require(c / a == b, 'SM29');
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, 'SM43');
        require(!(b == -1 && a == _INT256_MIN), 'SM42');

        return a / b;
    }

    function neg_floor_div(int256 a, int256 b) internal pure returns (int256 c) {
        c = div(a, b);
        if ((a < 0 && b > 0) || (a >= 0 && b < 0)) {
            if (a != mul(b, c)) {
                c = sub(c, 1);
            }
        }
    }
}

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9



import '../interfaces/IERC20.sol';
import '../interfaces/IWETH.sol';
import './SafeMath.sol';
import './TransferHelper.sol';


library TokenShares {
    using SafeMath for uint256;
    using TransferHelper for address;

    uint256 private constant PRECISION = 10**18;
    uint256 private constant TOLERANCE = 10**18 + 10**16;
    uint256 private constant TOTAL_SHARES_PRECISION = 10**18;

    event UnwrapFailed(address to, uint256 amount);

    // represents wrapped native currency (WETH or WMATIC)
    address public constant WETH_ADDRESS = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1; 

    struct Data {
        mapping(address => uint256) totalShares;
    }

    function sharesToAmount(
        Data storage data,
        address token,
        uint256 share,
        uint256 amountLimit,
        address refundTo
    ) external returns (uint256) {
        if (share == 0) {
            return 0;
        }
        if (token == WETH_ADDRESS || isNonRebasing(token)) {
            return share;
        }

        uint256 totalTokenShares = data.totalShares[token];
        require(totalTokenShares >= share, 'TS3A');
        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 value = balance.mul(share).div(totalTokenShares);
        data.totalShares[token] = totalTokenShares.sub(share);

        if (amountLimit > 0) {
            uint256 amountLimitWithTolerance = amountLimit.mul(TOLERANCE).div(PRECISION);
            if (value > amountLimitWithTolerance) {
                TransferHelper.safeTransfer(token, refundTo, value.sub(amountLimitWithTolerance));
                return amountLimitWithTolerance;
            }
        }

        return value;
    }

    function amountToShares(
        Data storage data,
        address token,
        uint256 amount,
        bool wrap
    ) external returns (uint256) {
        if (amount == 0) {
            return 0;
        }
        if (token == WETH_ADDRESS) {
            if (wrap) {
                require(msg.value >= amount, 'TS03');
                IWETH(token).deposit{ value: amount }();
            } else {
                token.safeTransferFrom(msg.sender, address(this), amount);
            }
            return amount;
        } else if (isNonRebasing(token)) {
            token.safeTransferFrom(msg.sender, address(this), amount);
            return amount;
        } else {
            uint256 balanceBefore = IERC20(token).balanceOf(address(this));
            token.safeTransferFrom(msg.sender, address(this), amount);
            uint256 balanceAfter = IERC20(token).balanceOf(address(this));

            return amountToSharesHelper(data, token, balanceBefore, balanceAfter);
        }
    }

    function amountToSharesWithoutTransfer(
        Data storage data,
        address token,
        uint256 amount,
        bool wrap
    ) external returns (uint256) {
        if (token == WETH_ADDRESS) {
            if (wrap) {
                // require(msg.value >= amount, 'TS03'); // Duplicate check in TwapRelayer.sell
                IWETH(token).deposit{ value: amount }();
            }
            return amount;
        } else if (isNonRebasing(token)) {
            return amount;
        } else {
            uint256 balanceAfter = IERC20(token).balanceOf(address(this));
            uint256 balanceBefore = balanceAfter.sub(amount);
            return amountToSharesHelper(data, token, balanceBefore, balanceAfter);
        }
    }

    function amountToSharesHelper(
        Data storage data,
        address token,
        uint256 balanceBefore,
        uint256 balanceAfter
    ) internal returns (uint256) {
        uint256 totalTokenShares = data.totalShares[token];
        require(balanceBefore > 0 || totalTokenShares == 0, 'TS30');
        require(balanceAfter > balanceBefore, 'TS2C');

        if (balanceBefore > 0) {
            if (totalTokenShares == 0) {
                totalTokenShares = balanceBefore.mul(TOTAL_SHARES_PRECISION);
            }
            uint256 newShares = totalTokenShares.mul(balanceAfter).div(balanceBefore);
            require(balanceAfter < type(uint256).max.div(newShares), 'TS73'); // to prevent overflow at execution
            data.totalShares[token] = newShares;
            return newShares - totalTokenShares;
        } else {
            totalTokenShares = balanceAfter.mul(TOTAL_SHARES_PRECISION);
            require(totalTokenShares < type(uint256).max.div(totalTokenShares), 'TS73'); // to prevent overflow at execution
            data.totalShares[token] = totalTokenShares;
            return totalTokenShares;
        }
    }

    function onUnwrapFailed(address to, uint256 amount) external {
        emit UnwrapFailed(to, amount);
        IWETH(WETH_ADDRESS).deposit{ value: amount }();
        TransferHelper.safeTransfer(WETH_ADDRESS, to, amount);
    }

    
    // constant mapping for nonRebasingToken
    function isNonRebasing(address token) internal pure returns (bool) {
        if (token == 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1) return true;
        if (token == 0xaf88d065e77c8cC2239327C5EDb3A432268e5831) return true;
        if (token == 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8) return true;
        if (token == 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9) return true;
        if (token == 0x5979D7b546E38E414F7E9822514be443A4800529) return true;
        return false;
    }
}

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9



// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TH4B');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TH05');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TH0E');
    }

    function safeTransferETH(
        address to,
        uint256 value,
        uint256 gasLimit
    ) internal {
        (bool success, ) = to.call{ value: value, gas: gasLimit }('');
        require(success, 'TH3F');
    }

    function transferETH(
        address to,
        uint256 value,
        uint256 gasLimit
    ) internal returns (bool success) {
        (success, ) = to.call{ value: value, gas: gasLimit }('');
    }
}

pragma solidity 0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9




import './interfaces/ITwapFactory.sol';
import './interfaces/ITwapDelay.sol';
import './interfaces/ITwapPair.sol';
import './interfaces/ITwapOracleV3.sol';
import './interfaces/ITwapRelayer.sol';
import './interfaces/ITwapRelayerInitializable.sol';
import './interfaces/IWETH.sol';
import './libraries/SafeMath.sol';
import './libraries/Orders.sol';
import './libraries/TransferHelper.sol';
import '@uniswap/v3-core/contracts/libraries/FullMath.sol';
import '@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol';


contract TwapRelayer is ITwapRelayer, ITwapRelayerInitializable {
    using SafeMath for uint256;

    uint256 private constant PRECISION = 10**18;
    address public constant FACTORY_ADDRESS = 0x717EF162cf831db83c51134734A15D1EBe9E516a; 
    address public constant WETH_ADDRESS = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1; 
    address public constant DELAY_ADDRESS = 0xA12A0AB13e43c3F9A501Be4b809AfbB639113320; 
    uint256 public constant EXECUTION_GAS_LIMIT = 500000; 

    /*
     * DO NOT CHANGE THE BELOW STATE VARIABLES.
     * REMOVING, REORDERING OR INSERTING STATE VARIABLES WILL CAUSE STORAGE COLLISION.
     * NEW VARIABLES SHOULD BE ADDED BELOW THESE VARIABLES TO AVOID STORAGE COLLISION.
     */
    uint8 public initialized;
    uint8 private __RESERVED__OLD_LOCKED;
    address public override owner;
    address public __RESERVED__OLD_FACTORY;
    address public __RESERVED__OLD_WETH;
    address public __RESERVED__OLD_DELAY;
    uint256 public __RESERVED__OLD_ETH_TRANSFER_GAS_COST;
    uint256 public __RESERVED__OLD_EXECUTION_GAS_LIMIT;
    uint256 public __RESERVED__SLOT_6_USED_IN_PREVIOUS_VERSIONS;

    mapping(address => uint256) public override swapFee;
    mapping(address => uint32) public __RESERVED__OLD_TWAP_INTERVAL;
    mapping(address => bool) public override isPairEnabled;
    mapping(address => uint256) public __RESERVED__OLD_TOKEN_LIMIT_MIN;
    mapping(address => uint256) public __RESERVED__OLD_TOKEN_LIMIT_MAX_MULTIPLIER;
    mapping(address => uint16) public __RESERVED__OLD_TOLERANCE;

    address public override rebalancer;
    mapping(address => bool) public override isOneInchRouterWhitelisted;

    uint256 private locked;

    /*
     * DO NOT CHANGE THE ABOVE STATE VARIABLES.
     * REMOVING, REORDERING OR INSERTING STATE VARIABLES WILL CAUSE STORAGE COLLISION.
     * NEW VARIABLES SHOULD BE ADDED BELOW THESE VARIABLES TO AVOID STORAGE COLLISION.
     */

    modifier lock() {
        require(locked == 0, 'TR06');
        locked = 1;
        _;
        locked = 0;
    }

    // This contract implements a proxy pattern.
    // The constructor is to set to prevent abuse of this implementation contract.
    // Setting locked = 1 forces core features, e.g. buy(), to always revert.
    constructor() {
        owner = msg.sender;
        initialized = 1;
        locked = 1;
    }

    // This function should be called through the proxy contract to initialize the proxy contract's storage.
    function initialize() external override {
        require(initialized == 0, 'TR5B');

        initialized = 1;
        owner = msg.sender;

        emit Initialized(FACTORY_ADDRESS, DELAY_ADDRESS, WETH_ADDRESS);
        emit OwnerSet(msg.sender);
        _emitEventWithDefaults();
    }

    function setOwner(address _owner) external override {
        require(msg.sender == owner, 'TR00');
        require(_owner != owner, 'TR01');
        require(_owner != address(0), 'TR02');
        owner = _owner;
        emit OwnerSet(_owner);
    }

    function setSwapFee(address pair, uint256 fee) external override {
        require(msg.sender == owner, 'TR00');
        require(fee != swapFee[pair], 'TR01');
        swapFee[pair] = fee;
        emit SwapFeeSet(pair, fee);
    }

    function setPairEnabled(address pair, bool enabled) external override {
        require(msg.sender == owner, 'TR00');
        require(enabled != isPairEnabled[pair], 'TR01');
        isPairEnabled[pair] = enabled;
        emit PairEnabledSet(pair, enabled);
    }

    function setRebalancer(address _rebalancer) external override {
        require(msg.sender == owner, 'TR00');
        require(_rebalancer != rebalancer, 'TR01');
        require(_rebalancer != msg.sender, 'TR5D');
        rebalancer = _rebalancer;
        emit RebalancerSet(_rebalancer);
    }

    function whitelistOneInchRouter(address oneInchRouter, bool whitelisted) external override {
        require(msg.sender == owner, 'TR00');
        require(oneInchRouter != address(0), 'TR02');
        require(whitelisted != isOneInchRouterWhitelisted[oneInchRouter], 'TR01');
        isOneInchRouterWhitelisted[oneInchRouter] = whitelisted;
        emit OneInchRouterWhitelisted(oneInchRouter, whitelisted);
    }

    function sell(SellParams calldata sellParams) external payable override lock returns (uint256 orderId) {
        require(
            sellParams.to != sellParams.tokenIn && sellParams.to != sellParams.tokenOut && sellParams.to != address(0),
            'TR26'
        );
        // Duplicate checks in Orders.sell
        // require(sellParams.amountIn != 0, 'TR24');

        uint256 ethValue = calculatePrepay();

        if (sellParams.wrapUnwrap && sellParams.tokenIn == WETH_ADDRESS) {
            require(msg.value == sellParams.amountIn, 'TR59');
            ethValue = ethValue.add(msg.value);
        } else {
            require(msg.value == 0, 'TR58');
        }

        (uint256 amountIn, uint256 amountOut, uint256 fee) = swapExactIn(
            sellParams.tokenIn,
            sellParams.tokenOut,
            sellParams.amountIn,
            sellParams.wrapUnwrap,
            sellParams.to
        );
        require(amountOut >= sellParams.amountOutMin, 'TR37');

        orderId = ITwapDelay(DELAY_ADDRESS).relayerSell{ value: ethValue }(
            Orders.SellParams(
                sellParams.tokenIn,
                sellParams.tokenOut,
                amountIn,
                0, // Relax slippage constraints
                sellParams.wrapUnwrap,
                address(this),
                EXECUTION_GAS_LIMIT,
                sellParams.submitDeadline
            )
        );

        emit Sell(
            msg.sender,
            sellParams.tokenIn,
            sellParams.tokenOut,
            amountIn,
            amountOut,
            sellParams.amountOutMin,
            sellParams.wrapUnwrap,
            fee,
            sellParams.to,
            DELAY_ADDRESS,
            orderId
        );
    }

    function buy(BuyParams calldata buyParams) external payable override lock returns (uint256 orderId) {
        require(
            buyParams.to != buyParams.tokenIn && buyParams.to != buyParams.tokenOut && buyParams.to != address(0),
            'TR26'
        );
        // Duplicate checks in Orders.sell
        // require(buyParams.amountOut != 0, 'TR23');

        uint256 balanceBefore = address(this).balance.sub(msg.value);

        (uint256 amountIn, uint256 amountOut, uint256 fee) = swapExactOut(
            buyParams.tokenIn,
            buyParams.tokenOut,
            buyParams.amountOut,
            buyParams.wrapUnwrap,
            buyParams.to
        );
        require(amountIn <= buyParams.amountInMax, 'TR08');

        // Used to avoid the 'stack too deep' error.
        {
            bool wrapUnwrapWeth = buyParams.wrapUnwrap && buyParams.tokenIn == WETH_ADDRESS;
            uint256 prepay = calculatePrepay();
            uint256 ethValue = prepay;

            if (wrapUnwrapWeth) {
                require(msg.value >= amountIn, 'TR59');
                ethValue = ethValue.add(amountIn);
            } else {
                require(msg.value == 0, 'TR58');
            }

            orderId = ITwapDelay(DELAY_ADDRESS).relayerSell{ value: ethValue }(
                Orders.SellParams(
                    buyParams.tokenIn,
                    buyParams.tokenOut,
                    amountIn,
                    0, // Relax slippage constraints
                    buyParams.wrapUnwrap,
                    address(this),
                    EXECUTION_GAS_LIMIT,
                    buyParams.submitDeadline
                )
            );

            // refund remaining ETH
            if (wrapUnwrapWeth) {
                uint256 balanceAfter = address(this).balance + prepay;
                if (balanceAfter > balanceBefore) {
                    TransferHelper.safeTransferETH(
                        msg.sender,
                        balanceAfter - balanceBefore,
                        Orders.ETHER_TRANSFER_COST
                    );
                }
            }
        }

        emit Buy(
            msg.sender,
            buyParams.tokenIn,
            buyParams.tokenOut,
            amountIn,
            buyParams.amountInMax,
            amountOut,
            buyParams.wrapUnwrap,
            fee,
            buyParams.to,
            DELAY_ADDRESS,
            orderId
        );
    }

    function getPair(address tokenA, address tokenB) internal view returns (address pair, bool inverted) {
        inverted = tokenA > tokenB;
        pair = ITwapFactory(FACTORY_ADDRESS).getPair(tokenA, tokenB);

        require(pair != address(0), 'TR17');
    }

    function calculatePrepay() internal view returns (uint256) {
        return ITwapDelay(DELAY_ADDRESS).gasPrice().mul(EXECUTION_GAS_LIMIT);
    }

    function swapExactIn(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        bool wrapUnwrap,
        address to
    )
        internal
        returns (
            uint256 _amountIn,
            uint256 _amountOut,
            uint256 fee
        )
    {
        (address pair, bool inverted) = getPair(tokenIn, tokenOut);
        require(isPairEnabled[pair], 'TR5A');

        _amountIn = transferIn(tokenIn, amountIn, wrapUnwrap);

        fee = _amountIn.mul(swapFee[pair]).div(PRECISION);
        uint256 calculatedAmountOut = calculateAmountOut(pair, inverted, _amountIn.sub(fee));
        _amountOut = transferOut(to, tokenOut, calculatedAmountOut, wrapUnwrap);

        require(_amountOut <= calculatedAmountOut.add(getTolerance(pair)), 'TR2E');
    }

    function swapExactOut(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        bool wrapUnwrap,
        address to
    )
        internal
        returns (
            uint256 _amountIn,
            uint256 _amountOut,
            uint256 fee
        )
    {
        (address pair, bool inverted) = getPair(tokenIn, tokenOut);
        require(isPairEnabled[pair], 'TR5A');

        _amountOut = transferOut(to, tokenOut, amountOut, wrapUnwrap);
        uint256 calculatedAmountIn = calculateAmountIn(pair, inverted, _amountOut);

        uint256 amountInPlusFee = calculatedAmountIn.mul(PRECISION).ceil_div(PRECISION.sub(swapFee[pair]));
        fee = amountInPlusFee.sub(calculatedAmountIn);
        _amountIn = transferIn(tokenIn, amountInPlusFee, wrapUnwrap);

        require(_amountIn >= amountInPlusFee.sub(getTolerance(pair)), 'TR2E');
    }

    function calculateAmountIn(
        address pair,
        bool inverted,
        uint256 amountOut
    ) internal view returns (uint256 amountIn) {
        (uint8 xDecimals, uint8 yDecimals, uint256 price) = getPriceByPairAddress(pair, inverted);
        uint256 decimalsConverter = getDecimalsConverter(xDecimals, yDecimals, inverted);
        amountIn = amountOut.mul(decimalsConverter).ceil_div(price);
    }

    function calculateAmountOut(
        address pair,
        bool inverted,
        uint256 amountIn
    ) internal view returns (uint256 amountOut) {
        (uint8 xDecimals, uint8 yDecimals, uint256 price) = getPriceByPairAddress(pair, inverted);
        uint256 decimalsConverter = getDecimalsConverter(xDecimals, yDecimals, inverted);
        amountOut = amountIn.mul(price).div(decimalsConverter);
    }

    function getDecimalsConverter(
        uint8 xDecimals,
        uint8 yDecimals,
        bool inverted
    ) internal pure returns (uint256 decimalsConverter) {
        decimalsConverter = 10**(18 + (inverted ? yDecimals - xDecimals : xDecimals - yDecimals));
    }

    function getPriceByPairAddress(address pair, bool inverted)
        public
        view
        override
        returns (
            uint8 xDecimals,
            uint8 yDecimals,
            uint256 price
        )
    {
        uint256 spotPrice;
        uint256 averagePrice;
        (spotPrice, averagePrice, xDecimals, yDecimals) = getPricesFromOracle(pair);

        if (inverted) {
            price = uint256(10**36).div(spotPrice > averagePrice ? spotPrice : averagePrice);
        } else {
            price = spotPrice < averagePrice ? spotPrice : averagePrice;
        }
    }

    function getPriceByTokenAddresses(address tokenIn, address tokenOut) public view override returns (uint256 price) {
        (address pair, bool inverted) = getPair(tokenIn, tokenOut);
        (, , price) = getPriceByPairAddress(pair, inverted);
    }

    function getPoolState(address token0, address token1)
        external
        view
        override
        returns (
            uint256 price,
            uint256 fee,
            uint256 limitMin0,
            uint256 limitMax0,
            uint256 limitMin1,
            uint256 limitMax1
        )
    {
        (address pair, ) = getPair(token0, token1);
        require(isPairEnabled[pair], 'TR5A');

        fee = swapFee[pair];

        price = getPriceByTokenAddresses(token0, token1);

        limitMin0 = getTokenLimitMin(token0);
        limitMax0 = IERC20(token0).balanceOf(address(this)).mul(getTokenLimitMaxMultiplier(token0)).div(PRECISION);
        limitMin1 = getTokenLimitMin(token1);
        limitMax1 = IERC20(token1).balanceOf(address(this)).mul(getTokenLimitMaxMultiplier(token1)).div(PRECISION);
    }

    function quoteSell(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view override returns (uint256 amountOut) {
        require(amountIn > 0, 'TR24');

        (address pair, bool inverted) = getPair(tokenIn, tokenOut);

        uint256 fee = amountIn.mul(swapFee[pair]).div(PRECISION);
        uint256 amountInMinusFee = amountIn.sub(fee);
        amountOut = calculateAmountOut(pair, inverted, amountInMinusFee);
        checkLimits(tokenOut, amountOut);
    }

    function quoteBuy(
        address tokenIn,
        address tokenOut,
        uint256 amountOut
    ) external view override returns (uint256 amountIn) {
        require(amountOut > 0, 'TR23');

        (address pair, bool inverted) = getPair(tokenIn, tokenOut);

        checkLimits(tokenOut, amountOut);
        uint256 calculatedAmountIn = calculateAmountIn(pair, inverted, amountOut);
        amountIn = calculatedAmountIn.mul(PRECISION).ceil_div(PRECISION.sub(swapFee[pair]));
    }

    function getPricesFromOracle(address pair)
        internal
        view
        returns (
            uint256 spotPrice,
            uint256 averagePrice,
            uint8 xDecimals,
            uint8 yDecimals
        )
    {
        ITwapOracleV3 oracle = ITwapOracleV3(ITwapPair(pair).oracle());

        xDecimals = oracle.xDecimals();
        yDecimals = oracle.yDecimals();

        spotPrice = oracle.getSpotPrice();

        address uniswapPair = oracle.uniswapPair();
        averagePrice = getAveragePrice(pair, uniswapPair, getDecimalsConverter(xDecimals, yDecimals, false));
    }

    function getAveragePrice(
        address pair,
        address uniswapPair,
        uint256 decimalsConverter
    ) internal view returns (uint256) {
        uint32 secondsAgo = getTwapInterval(pair);
        require(secondsAgo > 0, 'TR55');
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = secondsAgo;
        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(uniswapPair).observe(secondsAgos);

        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
        int24 arithmeticMeanTick = int24(tickCumulativesDelta / secondsAgo);
        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % secondsAgo != 0)) --arithmeticMeanTick;

        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(arithmeticMeanTick);

        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            return FullMath.mulDiv(ratioX192, decimalsConverter, 2**192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, 2**64);
            return FullMath.mulDiv(ratioX128, decimalsConverter, 2**128);
        }
    }

    function transferIn(
        address token,
        uint256 amount,
        bool wrap
    ) internal returns (uint256) {
        if (amount == 0) {
            return 0;
        }
        if (token == WETH_ADDRESS) {
            // eth is transferred directly to the delay in sell / buy function
            if (!wrap) {
                TransferHelper.safeTransferFrom(token, msg.sender, DELAY_ADDRESS, amount);
            }
            return amount;
        } else {
            uint256 balanceBefore = IERC20(token).balanceOf(DELAY_ADDRESS);
            TransferHelper.safeTransferFrom(token, msg.sender, DELAY_ADDRESS, amount);
            uint256 balanceAfter = IERC20(token).balanceOf(DELAY_ADDRESS);
            require(balanceAfter > balanceBefore, 'TR2C');
            return balanceAfter - balanceBefore;
        }
    }

    function transferOut(
        address to,
        address token,
        uint256 amount,
        bool unwrap
    ) internal returns (uint256) {
        if (amount == 0) {
            return 0;
        }
        checkLimits(token, amount);

        if (token == WETH_ADDRESS) {
            if (unwrap) {
                IWETH(token).withdraw(amount);
                TransferHelper.safeTransferETH(to, amount, Orders.ETHER_TRANSFER_COST);
            } else {
                TransferHelper.safeTransfer(token, to, amount);
            }
            return amount;
        } else {
            uint256 balanceBefore = IERC20(token).balanceOf(address(this));
            TransferHelper.safeTransfer(token, to, amount);
            uint256 balanceAfter = IERC20(token).balanceOf(address(this));
            require(balanceBefore > balanceAfter, 'TR2C');
            return balanceBefore - balanceAfter;
        }
    }

    function checkLimits(address token, uint256 amount) internal view {
        require(amount >= getTokenLimitMin(token), 'TR03');
        require(
            amount <= IERC20(token).balanceOf(address(this)).mul(getTokenLimitMaxMultiplier(token)).div(PRECISION),
            'TR3A'
        );
    }

    function approve(
        address token,
        uint256 amount,
        address to
    ) external override lock {
        require(msg.sender == owner, 'TR00');
        require(to != address(0), 'TR02');

        TransferHelper.safeApprove(token, to, amount);

        emit Approve(token, to, amount);
    }

    function withdraw(
        address token,
        uint256 amount,
        address to
    ) external override lock {
        require(msg.sender == owner, 'TR00');
        require(to != address(0), 'TR02');
        if (token == Orders.NATIVE_CURRENCY_SENTINEL) {
            TransferHelper.safeTransferETH(to, amount, Orders.ETHER_TRANSFER_COST);
        } else {
            TransferHelper.safeTransfer(token, to, amount);
        }
        emit Withdraw(token, to, amount);
    }

    function rebalanceSellWithDelay(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external override lock {
        require(msg.sender == rebalancer, 'TR00');

        uint256 delayOrderId = ITwapDelay(DELAY_ADDRESS).sell{ value: calculatePrepay() }(
            Orders.SellParams(
                tokenIn,
                tokenOut,
                amountIn,
                0, // Relax slippage constraints
                false, // Never wrap/unwrap
                address(this),
                EXECUTION_GAS_LIMIT,
                uint32(block.timestamp)
            )
        );

        emit RebalanceSellWithDelay(msg.sender, tokenIn, tokenOut, amountIn, delayOrderId);
    }

    function rebalanceSellWithOneInch(
        address tokenIn,
        uint256 amountIn,
        address oneInchRouter,
        uint256 _gas,
        bytes calldata data
    ) external override lock {
        require(msg.sender == rebalancer, 'TR00');
        require(isOneInchRouterWhitelisted[oneInchRouter], 'TR5F');

        TransferHelper.safeApprove(tokenIn, oneInchRouter, amountIn);

        (bool success, ) = oneInchRouter.call{ gas: _gas }(data);
        require(success, 'TR5E');

        emit Approve(tokenIn, oneInchRouter, amountIn);
        emit RebalanceSellWithOneInch(oneInchRouter, _gas, data);
    }

    function wrapEth(uint256 amount) external override lock {
        require(msg.sender == owner, 'TR00');
        IWETH(WETH_ADDRESS).deposit{ value: amount }();
        emit WrapEth(amount);
    }

    function unwrapWeth(uint256 amount) external override lock {
        require(msg.sender == owner, 'TR00');
        IWETH(WETH_ADDRESS).withdraw(amount);
        emit UnwrapWeth(amount);
    }

    
    function _emitEventWithDefaults() internal {
        emit DelaySet(DELAY_ADDRESS);
        emit EthTransferGasCostSet(Orders.ETHER_TRANSFER_COST);
        emit ExecutionGasLimitSet(EXECUTION_GAS_LIMIT);

        emit ToleranceSet(0x12b8bC27Ca8A997680F49d1A6FC1D93D552aacbe, 0);
        emit ToleranceSet(0x4BCa34ad27Df83566016B55c60Dd80a9eB14913b, 0);
        emit ToleranceSet(0xf31778748B3364fC43d6ab6AAc4f52E2C29B6353, 0);
        emit ToleranceSet(0x7A0f899EF730FE178E0574B8DAb4440cA336e415, 0);

        emit TokenLimitMinSet(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1, 2500000000000000);
        emit TokenLimitMinSet(0xaf88d065e77c8cC2239327C5EDb3A432268e5831, 5000000);
        emit TokenLimitMinSet(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8, 5000000);
        emit TokenLimitMinSet(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9, 5000000);
        emit TokenLimitMinSet(0x5979D7b546E38E414F7E9822514be443A4800529, 2500000000000000);

        emit TokenLimitMaxMultiplierSet(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1, 950000000000000000);
        emit TokenLimitMaxMultiplierSet(0xaf88d065e77c8cC2239327C5EDb3A432268e5831, 950000000000000000);
        emit TokenLimitMaxMultiplierSet(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8, 950000000000000000);
        emit TokenLimitMaxMultiplierSet(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9, 950000000000000000);
        emit TokenLimitMaxMultiplierSet(0x5979D7b546E38E414F7E9822514be443A4800529, 950000000000000000);

        emit TwapIntervalSet(0x12b8bC27Ca8A997680F49d1A6FC1D93D552aacbe, 300);
        emit TwapIntervalSet(0x4BCa34ad27Df83566016B55c60Dd80a9eB14913b, 300);
        emit TwapIntervalSet(0xf31778748B3364fC43d6ab6AAc4f52E2C29B6353, 300);
        emit TwapIntervalSet(0x7A0f899EF730FE178E0574B8DAb4440cA336e415, 300);
    }

    
    // constant mapping for tolerance
    function getTolerance(address) public pure override returns (uint16) {
        return 0;
    }

    
    // constant mapping for tokenLimitMin
    function getTokenLimitMin(address token) public pure override returns (uint256) {
        if (token == 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1) return 2500000000000000;
        if (token == 0xaf88d065e77c8cC2239327C5EDb3A432268e5831) return 5000000;
        if (token == 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8) return 5000000;
        if (token == 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9) return 5000000;
        if (token == 0x5979D7b546E38E414F7E9822514be443A4800529) return 2500000000000000;
        return 0;
    }

    
    // constant mapping for tokenLimitMaxMultiplier
    function getTokenLimitMaxMultiplier(address) public pure override returns (uint256) {
        return 950000000000000000;
    }

    
    // constant mapping for twapInterval
    function getTwapInterval(address) public pure override returns (uint32) {
        return 300;
    }

    /*
     * Methods for backward compatibility
     */

    function factory() external pure override returns (address) {
        return FACTORY_ADDRESS;
    }

    function delay() external pure override returns (address) {
        return DELAY_ADDRESS;
    }

    function weth() external pure override returns (address) {
        return WETH_ADDRESS;
    }

    function twapInterval(address pair) external pure override returns (uint32) {
        return getTwapInterval(pair);
    }

    function ethTransferGasCost() external pure override returns (uint256) {
        return Orders.ETHER_TRANSFER_COST;
    }

    function executionGasLimit() external pure override returns (uint256) {
        return EXECUTION_GAS_LIMIT;
    }

    function tokenLimitMin(address token) external pure override returns (uint256) {
        return getTokenLimitMin(token);
    }

    function tokenLimitMaxMultiplier(address token) external pure override returns (uint256) {
        return getTokenLimitMaxMultiplier(token);
    }

    function tolerance(address pair) external pure override returns (uint16) {
        return getTolerance(pair);
    }

    receive() external payable {}
}