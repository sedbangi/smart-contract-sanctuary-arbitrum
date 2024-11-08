// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {ILBPair} from "joe-v2/interfaces/ILBPair.sol";

import {LiquidityHelper} from "./periphery/LiquidityHelper.sol";
import {NonEmptyBinHelper} from "./periphery/NonEmptyBinHelper.sol";

/**
 * @title Liquidity Book periphery contract for Liquidity, Fees Amounts and bin fetching.
 * This contract can waste a lot of gas and is not meant to be used for on-chain calls.
 * @notice Periphery contract to help compute liquidity, fees amounts from amounts and ids and fetch bins.
 * @dev The caller must ensure that the parameters are valid following the comments.
 */
contract LiquidityHelperContract {
    /**
     * @dev Return the shares of the receipt token for a given user and ids
     * The ids must be unique, if not, the result will be wrong.
     * @param lbPair The pair
     * @param user The user
     * @param ids The list of ids
     * @return balances The balance of the receipt token for each id
     */
    function getSharesOf(ILBPair lbPair, address user, uint256[] memory ids)
        external
        view
        returns (uint256[] memory balances)
    {
        return LiquidityHelper.getSharesOf(lbPair, user, ids);
    }

    /**
     * @dev Return the liquidity (calculated using the constant sum formula: p*x + y) for a given user and ids
     * The ids must be unique, if not, the result will be wrong.
     * @param lbPair The pair
     * @param user The user
     * @param ids The list of ids
     * @return liquidities The liquidity for each id
     */
    function getLiquiditiesOf(ILBPair lbPair, address user, uint256[] memory ids)
        external
        view
        returns (uint256[] memory liquidities)
    {
        return LiquidityHelper.getLiquiditiesOf(lbPair, user, ids);
    }

    /**
     * @dev Return the amounts of x and y for a given user and ids
     * The ids must be unique, if not, the result will be wrong.
     * @param lbPair The pair
     * @param user The user
     * @param ids The list of ids
     * @return amountsX The list of amounts of token X
     * @return amountsY The list of amounts of token Y
     */
    function getAmountsOf(ILBPair lbPair, address user, uint256[] memory ids)
        external
        view
        returns (uint256[] memory amountsX, uint256[] memory amountsY)
    {
        return LiquidityHelper.getAmountsOf(lbPair, user, ids);
    }

    /**
     * @dev Return the shares minted for a given list of amounts of x and y
     * The ids must be unique, if not, the result will be wrong.
     * @param lbPair The pair
     * @param ids The list of ids
     * @param amountsX The list of amounts of token X
     * @param amountsY The list of amounts of token Y
     * @return shares The amount of shares of the receipt token
     */
    function getSharesForAmounts(
        ILBPair lbPair,
        uint256[] memory ids,
        uint256[] memory amountsX,
        uint256[] memory amountsY
    ) external view returns (uint256[] memory shares) {
        return LiquidityHelper.getSharesForAmounts(lbPair, ids, amountsX, amountsY);
    }

    /**
     * @dev Return the liquidities for a given list of amounts of x and y
     * The ids must be unique, if not, the result will be wrong.
     * @param lbPair The pair
     * @param ids The list of ids
     * @param amountsX The list of amounts of token X
     * @param amountsY The list of amounts of token Y
     * @return liquidities The liquidity for each id
     */
    function getLiquiditiesForAmounts(
        ILBPair lbPair,
        uint256[] memory ids,
        uint256[] memory amountsX,
        uint256[] memory amountsY
    ) external view returns (uint256[] memory liquidities) {
        return LiquidityHelper.getLiquiditiesForAmounts(lbPair, ids, amountsX, amountsY);
    }

    /**
     * @dev Return the liquidities for a given list of shares
     * The ids must be unique, if not, the result will be wrong.
     * @param lbPair The pair
     * @param ids The list of ids
     * @param shares The list of shares
     * @return liquidities The liquidity for each id
     */
    function getLiquiditiesForShares(ILBPair lbPair, uint256[] memory ids, uint256[] memory shares)
        external
        view
        returns (uint256[] memory liquidities)
    {
        return LiquidityHelper.getLiquiditiesForShares(lbPair, ids, shares);
    }

    /**
     * @dev Return the amounts of x and y for a list of shares
     * The ids must be unique, if not, the result will be wrong.
     * @param lbPair The pair
     * @param ids The list of ids
     * @param shares The list of shares
     * @return amountsX The amount of token X for each id
     * @return amountsY The amount of token Y for each id
     */
    function getAmountsForShares(ILBPair lbPair, uint256[] memory ids, uint256[] memory shares)
        external
        view
        returns (uint256[] memory amountsX, uint256[] memory amountsY)
    {
        return LiquidityHelper.getAmountsForShares(lbPair, ids, shares);
    }

    /**
     * @dev Return the amounts of x and y for a list of liquidities
     * The ids must be unique, if not, the result will be wrong.
     * @param lbPair The pair
     * @param ids The list of ids
     * @param liquidities The list of liquidities
     * @return amountsX The amount of token X for each id
     * @return amountsY The amount of token Y for each id
     */
    function getAmountsForLiquidities(ILBPair lbPair, uint256[] memory ids, uint256[] memory liquidities)
        external
        view
        returns (uint256[] memory amountsX, uint256[] memory amountsY)
    {
        return LiquidityHelper.getAmountsForLiquidities(lbPair, ids, liquidities);
    }

    /**
     * @dev Return the shares for a given list of liquidities
     * The ids must be unique, if not, the result will be wrong.
     * @param lbPair The pair
     * @param ids The list of ids
     * @param liquidities The list of liquidities
     * @return shares The share for each id
     */
    function getSharesForLiquidities(ILBPair lbPair, uint256[] memory ids, uint256[] memory liquidities)
        external
        view
        returns (uint256[] memory shares)
    {
        return LiquidityHelper.getSharesForLiquidities(lbPair, ids, liquidities);
    }

    /**
     * @dev Return the amounts of x and y and fees earned of a given user for a list of ids
     * The ids must be unique, if not, the result will be wrong.
     * @param lbPair The pair
     * @param user The user
     * @param ids The list of ids
     * @param previousX The list of previous amounts of token X
     * @param previousY The list of previous amounts of token Y
     * @return amountsX The amount of token X for each id (including fees)
     * @return amountsY The amount of token Y for each id (including fees)
     * @return feesX The fees of token X for each id
     * @return feesY The fees of token Y for each id
     */
    function getAmountsAndFeesEarnedOf(
        ILBPair lbPair,
        address user,
        uint256[] memory ids,
        uint256[] memory previousX,
        uint256[] memory previousY
    )
        external
        view
        returns (uint256[] memory amountsX, uint256[] memory amountsY, uint256[] memory feesX, uint256[] memory feesY)
    {
        return LiquidityHelper.getAmountsAndFeesEarnedOf(lbPair, user, ids, previousX, previousY);
    }

    /**
     * @dev Return the fee shares and fees earned of a given user for a list of ids
     * The ids must be unique, if not, the result will be wrong.
     * @param lbPair The pair
     * @param user The user
     * @param ids The list of ids
     * @param previousLiquidities The list of previous liquidities
     * @return feeShares The fee shares for each id. This is the amount to burn to receive the fees,
     * in 128.128 fixed point number
     * @return feesX The fees of token X for each id
     * @return feesY The fees of token Y for each id
     */
    function getFeeSharesAndFeesEarnedOf(
        ILBPair lbPair,
        address user,
        uint256[] memory ids,
        uint256[] memory previousLiquidities
    ) external view returns (uint256[] memory feeShares, uint256[] memory feesX, uint256[] memory feesY) {
        return LiquidityHelper.getFeeSharesAndFeesEarnedOf(lbPair, user, ids, previousLiquidities);
    }

    /**
     * @dev Fetch the non-empty bins ids of a liquidity book pair from [start, end].
     * If length is specified, it will return the first `length` non-empty bins.
     * Returns the ids in a packed bytes array, where each id is 3 bytes.
     * @param pair The liquidity book pair.
     * @param start The start bin id.
     * @param end The end bin id. (inclusive)
     * @param length The number of non-empty bins to fetch. (optional)
     * @return ids The non-empty bins ids.
     */
    function getPopulatedBinsId(ILBPair pair, uint24 start, uint24 end, uint24 length)
        external
        view
        returns (bytes memory)
    {
        return NonEmptyBinHelper.getPopulatedBinsId(pair, start, end, length);
    }

    /**
     * @notice Fetches the non-empty bins reserves of a liquidity book pair from [start, end].
     *  If length is specified, it will return the first `length` non-empty bins.
     * @param pair The liquidity book pair.
     * @param start The start bin id.
     * @param end The end bin id. (inclusive)
     * @param length The number of non-empty bins to fetch. (optional)
     * @return The array of populated bins with (id, reserveX, reserveY)
     */
    function getPopulatedBinsReserves(ILBPair pair, uint24 start, uint24 end, uint24 length)
        external
        view
        returns (NonEmptyBinHelper.PopulatedBin[] memory)
    {
        return NonEmptyBinHelper.getPopulatedBinsReserves(pair, start, end, length);
    }

    /**
     * @notice Fetches the non-empty bins reserves of a liquidity book pair from [id-lengthLeft, id+lengthRight] where the user has liquidity.
     * If id is not specified, it will use the active bin id of the pair.
     * Will check `lengthLeft` non-empty bins on the left and `lengthRight` non-empty bins on the right, so if the user
     * has liquidity only after the `lengthLeft + 1` bin on the left and `lengthRight + 1` bin on the right, it will return
     * an empty array.
     * @param pair The liquidity book pair.
     * @param user The user.
     * @param id The specific bin id. (optional)
     * @param lengthLeft The number of non-empty bins to fetch on the left.
     * @param lengthRight The number of non-empty bins to fetch on the right.
     * @return id The bin id used. (if id was not specified, will return the active bin id)
     * @return The array of populated bins with (id, reserveX, reserveY, shares, totalShares)
     * The user amounts can be calculated as (shares * reserve{X,Y}) / totalShares.
     */
    function getBinsReserveOf(ILBPair pair, address user, uint24 id, uint24 lengthLeft, uint24 lengthRight)
        external
        view
        returns (uint24, NonEmptyBinHelper.PopulatedBinUser[] memory)
    {
        return NonEmptyBinHelper.getBinsReserveOf(pair, user, id, lengthLeft, lengthRight);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Hooks} from "../libraries/Hooks.sol";
import {ILBFactory} from "./ILBFactory.sol";
import {ILBFlashLoanCallback} from "./ILBFlashLoanCallback.sol";
import {ILBToken} from "./ILBToken.sol";

interface ILBPair is ILBToken {
    error LBPair__ZeroBorrowAmount();
    error LBPair__AddressZero();
    error LBPair__EmptyMarketConfigs();
    error LBPair__FlashLoanCallbackFailed();
    error LBPair__FlashLoanInsufficientAmount();
    error LBPair__InsufficientAmountIn();
    error LBPair__InsufficientAmountOut();
    error LBPair__InvalidInput();
    error LBPair__InvalidStaticFeeParameters();
    error LBPair__OnlyFactory();
    error LBPair__OnlyProtocolFeeRecipient();
    error LBPair__OutOfLiquidity();
    error LBPair__TokenNotSupported();
    error LBPair__ZeroAmount(uint24 id);
    error LBPair__ZeroAmountsOut(uint24 id);
    error LBPair__ZeroShares(uint24 id);
    error LBPair__MaxTotalFeeExceeded();
    error LBPair__InvalidHooks();

    struct MintArrays {
        uint256[] ids;
        bytes32[] amounts;
        uint256[] liquidityMinted;
    }

    event DepositedToBins(address indexed sender, address indexed to, uint256[] ids, bytes32[] amounts);

    event WithdrawnFromBins(address indexed sender, address indexed to, uint256[] ids, bytes32[] amounts);

    event CompositionFees(address indexed sender, uint24 id, bytes32 totalFees, bytes32 protocolFees);

    event CollectedProtocolFees(address indexed feeRecipient, bytes32 protocolFees);

    event Swap(
        address indexed sender,
        address indexed to,
        uint24 id,
        bytes32 amountsIn,
        bytes32 amountsOut,
        uint24 volatilityAccumulator,
        bytes32 totalFees,
        bytes32 protocolFees
    );

    event StaticFeeParametersSet(
        address indexed sender,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    );

    event HooksParametersSet(address indexed sender, bytes32 hooksParameters);

    event FlashLoan(
        address indexed sender,
        ILBFlashLoanCallback indexed receiver,
        uint24 activeId,
        bytes32 amounts,
        bytes32 totalFees,
        bytes32 protocolFees
    );

    event OracleLengthIncreased(address indexed sender, uint16 oracleLength);

    event ForcedDecay(address indexed sender, uint24 idReference, uint24 volatilityReference);

    function initialize(
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator,
        uint24 activeId
    ) external;

    function implementation() external view returns (address);

    function getFactory() external view returns (ILBFactory factory);

    function getTokenX() external view returns (IERC20 tokenX);

    function getTokenY() external view returns (IERC20 tokenY);

    function getBinStep() external view returns (uint16 binStep);

    function getReserves() external view returns (uint128 reserveX, uint128 reserveY);

    function getActiveId() external view returns (uint24 activeId);

    function getBin(uint24 id) external view returns (uint128 binReserveX, uint128 binReserveY);

    function getNextNonEmptyBin(bool swapForY, uint24 id) external view returns (uint24 nextId);

    function getProtocolFees() external view returns (uint128 protocolFeeX, uint128 protocolFeeY);

    function getStaticFeeParameters()
        external
        view
        returns (
            uint16 baseFactor,
            uint16 filterPeriod,
            uint16 decayPeriod,
            uint16 reductionFactor,
            uint24 variableFeeControl,
            uint16 protocolShare,
            uint24 maxVolatilityAccumulator
        );

    function getLBHooksParameters() external view returns (bytes32 hooksParameters);

    function getVariableFeeParameters()
        external
        view
        returns (uint24 volatilityAccumulator, uint24 volatilityReference, uint24 idReference, uint40 timeOfLastUpdate);

    function getOracleParameters()
        external
        view
        returns (uint8 sampleLifetime, uint16 size, uint16 activeSize, uint40 lastUpdated, uint40 firstTimestamp);

    function getOracleSampleAt(uint40 lookupTimestamp)
        external
        view
        returns (uint64 cumulativeId, uint64 cumulativeVolatility, uint64 cumulativeBinCrossed);

    function getPriceFromId(uint24 id) external view returns (uint256 price);

    function getIdFromPrice(uint256 price) external view returns (uint24 id);

    function getSwapIn(uint128 amountOut, bool swapForY)
        external
        view
        returns (uint128 amountIn, uint128 amountOutLeft, uint128 fee);

    function getSwapOut(uint128 amountIn, bool swapForY)
        external
        view
        returns (uint128 amountInLeft, uint128 amountOut, uint128 fee);

    function swap(bool swapForY, address to) external returns (bytes32 amountsOut);

    function flashLoan(ILBFlashLoanCallback receiver, bytes32 amounts, bytes calldata data) external;

    function mint(address to, bytes32[] calldata liquidityConfigs, address refundTo)
        external
        returns (bytes32 amountsReceived, bytes32 amountsLeft, uint256[] memory liquidityMinted);

    function burn(address from, address to, uint256[] calldata ids, uint256[] calldata amountsToBurn)
        external
        returns (bytes32[] memory amounts);

    function collectProtocolFees() external returns (bytes32 collectedProtocolFees);

    function increaseOracleLength(uint16 newLength) external;

    function setStaticFeeParameters(
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    ) external;

    function setHooksParameters(bytes32 hooksParameters, bytes calldata onHooksSetData) external;

    function forceDecay() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Uint256x256Math} from "joe-v2/libraries/math/Uint256x256Math.sol";
import {PriceHelper} from "joe-v2/libraries/PriceHelper.sol";
import {BinHelper} from "joe-v2/libraries/BinHelper.sol";
import {SafeCast} from "joe-v2/libraries/math/SafeCast.sol";
import {ILBPair} from "joe-v2/interfaces/ILBPair.sol";

/**
 * @title Liquidity Book periphery library for Liquidity and Fees Amounts
 * @notice Periphery library to help compute liquidity and fees amounts from amounts and ids.
 * @dev The caller must ensure that the parameters are valid following the comments.
 */
library LiquidityHelper {
    using Uint256x256Math for uint256;
    using SafeCast for uint256;

    error FeesAmounts__LengthMismatch();

    /**
     * @dev Return the shares of the receipt token for a given user and ids
     * The ids must be unique, if not, the result will be wrong.
     * @param lbPair The pair
     * @param user The user
     * @param ids The list of ids
     * @return balances The balance of the receipt token for each id
     */
    function getSharesOf(ILBPair lbPair, address user, uint256[] memory ids)
        internal
        view
        returns (uint256[] memory balances)
    {
        balances = new uint256[](ids.length);

        for (uint256 i; i < ids.length;) {
            balances[i] = lbPair.balanceOf(user, ids[i].safe24());

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Return the liquidity (calculated using the constant sum formula: p*x + y) for a given user and ids
     * The ids must be unique, if not, the result will be wrong.
     * @param lbPair The pair
     * @param user The user
     * @param ids The list of ids
     * @return liquidities The liquidity for each id
     */
    function getLiquiditiesOf(ILBPair lbPair, address user, uint256[] memory ids)
        internal
        view
        returns (uint256[] memory liquidities)
    {
        liquidities = new uint256[](ids.length);

        uint16 binStep = ILBPair(lbPair).getBinStep();

        for (uint256 i; i < ids.length;) {
            uint24 id = ids[i].safe24();

            (uint256 amountX, uint256 amountY) = getAmountsOfAtId(lbPair, user, id);

            liquidities[i] = getLiquidityFromId(amountX, amountY, id, binStep);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Return the amounts of x and y for a given user and ids
     * The ids must be unique, if not, the result will be wrong.
     * @param lbPair The pair
     * @param user The user
     * @param ids The list of ids
     * @return amountsX The list of amounts of token X
     * @return amountsY The list of amounts of token Y
     */
    function getAmountsOf(ILBPair lbPair, address user, uint256[] memory ids)
        internal
        view
        returns (uint256[] memory amountsX, uint256[] memory amountsY)
    {
        amountsX = new uint256[](ids.length);
        amountsY = new uint256[](ids.length);

        for (uint256 i; i < ids.length;) {
            (amountsX[i], amountsY[i]) = getAmountsOfAtId(lbPair, user, ids[i].safe24());

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Return the shares minted for a given list of amounts of x and y
     * The ids must be unique, if not, the result will be wrong.
     * @param lbPair The pair
     * @param ids The list of ids
     * @param amountsX The list of amounts of token X
     * @param amountsY The list of amounts of token Y
     * @return shares The amount of shares of the receipt token
     */
    function getSharesForAmounts(
        ILBPair lbPair,
        uint256[] memory ids,
        uint256[] memory amountsX,
        uint256[] memory amountsY
    ) internal view returns (uint256[] memory shares) {
        if (ids.length != amountsX.length || ids.length != amountsY.length) revert FeesAmounts__LengthMismatch();

        shares = new uint256[](ids.length);

        uint16 binStep = ILBPair(lbPair).getBinStep();

        for (uint256 i; i < ids.length;) {
            uint24 id = ids[i].safe24();

            uint256 price = PriceHelper.getPriceFromId(id, binStep);

            uint256 liquidity = getLiquidityFromPrice(amountsX[i], amountsY[i], price);

            shares[i] = getShareForLiquidity(lbPair, id, liquidity, price);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Return the liquidities for a given list of amounts of x and y
     * The ids must be unique, if not, the result will be wrong.
     * @param lbPair The pair
     * @param ids The list of ids
     * @param amountsX The list of amounts of token X
     * @param amountsY The list of amounts of token Y
     * @return liquidities The liquidity for each id
     */
    function getLiquiditiesForAmounts(
        ILBPair lbPair,
        uint256[] memory ids,
        uint256[] memory amountsX,
        uint256[] memory amountsY
    ) internal view returns (uint256[] memory liquidities) {
        if (ids.length != amountsX.length || ids.length != amountsY.length) revert FeesAmounts__LengthMismatch();

        liquidities = new uint256[](ids.length);

        uint16 binStep = lbPair.getBinStep();

        for (uint256 i; i < ids.length;) {
            liquidities[i] = getLiquidityFromId(amountsX[i], amountsY[i], ids[i].safe24(), binStep);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Return the liquidities for a given list of shares
     * The ids must be unique, if not, the result will be wrong.
     * @param lbPair The pair
     * @param ids The list of ids
     * @param shares The list of shares
     * @return liquidities The liquidity for each id
     */
    function getLiquiditiesForShares(ILBPair lbPair, uint256[] memory ids, uint256[] memory shares)
        internal
        view
        returns (uint256[] memory liquidities)
    {
        if (ids.length != shares.length) revert FeesAmounts__LengthMismatch();

        liquidities = new uint256[](ids.length);

        uint16 binStep = ILBPair(lbPair).getBinStep();

        for (uint256 i; i < ids.length;) {
            uint24 id = ids[i].safe24();

            (uint256 amountX, uint256 amountY) = getAmountsForShare(lbPair, id, shares[i]);

            liquidities[i] = getLiquidityFromId(amountX, amountY, id, binStep);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Return the amounts of x and y for a list of shares
     * The ids must be unique, if not, the result will be wrong.
     * @param lbPair The pair
     * @param ids The list of ids
     * @param shares The list of shares
     * @return amountsX The amount of token X for each id
     * @return amountsY The amount of token Y for each id
     */
    function getAmountsForShares(ILBPair lbPair, uint256[] memory ids, uint256[] memory shares)
        internal
        view
        returns (uint256[] memory amountsX, uint256[] memory amountsY)
    {
        if (ids.length != shares.length) revert FeesAmounts__LengthMismatch();

        amountsX = new uint256[](ids.length);
        amountsY = new uint256[](ids.length);

        for (uint256 i; i < ids.length;) {
            (uint256 amountX, uint256 amountY) = getAmountsForShare(lbPair, ids[i], shares[i]);

            amountsX[i] = amountX;
            amountsY[i] = amountY;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Return the amounts of x and y for a list of liquidities
     * The ids must be unique, if not, the result will be wrong.
     * @param lbPair The pair
     * @param ids The list of ids
     * @param liquidities The list of liquidities
     * @return amountsX The amount of token X for each id
     * @return amountsY The amount of token Y for each id
     */
    function getAmountsForLiquidities(ILBPair lbPair, uint256[] memory ids, uint256[] memory liquidities)
        internal
        view
        returns (uint256[] memory amountsX, uint256[] memory amountsY)
    {
        if (ids.length != liquidities.length) revert FeesAmounts__LengthMismatch();

        amountsX = new uint256[](ids.length);
        amountsY = new uint256[](ids.length);

        uint16 binStep = ILBPair(lbPair).getBinStep();

        for (uint256 i; i < ids.length;) {
            uint256 price = PriceHelper.getPriceFromId(ids[i].safe24(), binStep);

            (uint256 binReserveX, uint256 binReserveY) = lbPair.getBin(ids[i].safe24());
            uint256 binLiquidity = getLiquidityFromPrice(binReserveX, binReserveY, price);

            uint256 liquidity = liquidities[i];

            (amountsX[i], amountsY[i]) = binLiquidity == 0
                ? (0, 0)
                : (
                    liquidity.mulDivRoundDown(binReserveX, binLiquidity),
                    liquidity.mulDivRoundDown(binReserveY, binLiquidity)
                );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Return the shares for a given list of liquidities
     * The ids must be unique, if not, the result will be wrong.
     * @param lbPair The pair
     * @param ids The list of ids
     * @param liquidities The list of liquidities
     * @return shares The share for each id
     */
    function getSharesForLiquidities(ILBPair lbPair, uint256[] memory ids, uint256[] memory liquidities)
        internal
        view
        returns (uint256[] memory shares)
    {
        if (ids.length != liquidities.length) revert FeesAmounts__LengthMismatch();

        shares = new uint256[](ids.length);

        uint16 binStep = ILBPair(lbPair).getBinStep();

        for (uint256 i; i < ids.length;) {
            uint256 price = PriceHelper.getPriceFromId(ids[i].safe24(), binStep);

            shares[i] = getShareForLiquidity(lbPair, ids[i], liquidities[i], price);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Return the amounts of x and y and fees earned of a given user for a list of ids
     * The ids must be unique, if not, the result will be wrong.
     * @param lbPair The pair
     * @param user The user
     * @param ids The list of ids
     * @param previousX The list of previous amounts of token X
     * @param previousY The list of previous amounts of token Y
     * @return amountsX The amount of token X for each id (including fees)
     * @return amountsY The amount of token Y for each id (including fees)
     * @return feesX The fees of token X for each id
     * @return feesY The fees of token Y for each id
     */
    function getAmountsAndFeesEarnedOf(
        ILBPair lbPair,
        address user,
        uint256[] memory ids,
        uint256[] memory previousX,
        uint256[] memory previousY
    )
        internal
        view
        returns (uint256[] memory amountsX, uint256[] memory amountsY, uint256[] memory feesX, uint256[] memory feesY)
    {
        if (ids.length != previousX.length || ids.length != previousY.length) revert FeesAmounts__LengthMismatch();

        amountsX = new uint256[](ids.length);
        amountsY = new uint256[](ids.length);
        feesX = new uint256[](ids.length);
        feesY = new uint256[](ids.length);

        uint16 binStep = ILBPair(lbPair).getBinStep();

        for (uint256 i; i < ids.length;) {
            uint24 id = ids[i].safe24();

            (uint256 amountX, uint256 amountY) = getAmountsOfAtId(lbPair, user, id);

            amountsX[i] = amountX;
            amountsY[i] = amountY;

            (uint256 feeX, uint256 feeY) = getFeesAtId(binStep, id, previousX[i], previousY[i], amountX, amountY);

            feesX[i] = feeX;
            feesY[i] = feeY;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Return the fee shares and fees earned of a given user for a list of ids
     * The ids must be unique, if not, the result will be wrong.
     * @param lbPair The pair
     * @param user The user
     * @param ids The list of ids
     * @param previousLiquidities The list of previous liquidities
     * @return feeShares The fee shares for each id. This is the amount to burn to receive the fees,
     * in 128.128 fixed point number
     * @return feesX The fees of token X for each id
     * @return feesY The fees of token Y for each id
     */
    function getFeeSharesAndFeesEarnedOf(
        ILBPair lbPair,
        address user,
        uint256[] memory ids,
        uint256[] memory previousLiquidities
    ) internal view returns (uint256[] memory feeShares, uint256[] memory feesX, uint256[] memory feesY) {
        if (ids.length != previousLiquidities.length) revert FeesAmounts__LengthMismatch();

        feeShares = new uint256[](ids.length);
        feesX = new uint256[](ids.length);
        feesY = new uint256[](ids.length);

        uint16 binStep = ILBPair(lbPair).getBinStep();

        for (uint256 i; i < ids.length;) {
            uint24 id = ids[i].safe24();

            uint256 share = getShareOfAtId(lbPair, user, id);
            (uint256 binReserveX, uint256 binReserveY) = lbPair.getBin(id);
            uint256 totalShares = lbPair.totalSupply(id);

            (uint256 amountX, uint256 amountY) = totalShares == 0
                ? (0, 0)
                : (share.mulDivRoundDown(binReserveX, totalShares), share.mulDivRoundDown(binReserveY, totalShares));

            uint256 previousLiquidity = previousLiquidities[i];

            uint256 currentLiquidity = getLiquidityFromPrice(amountX, amountY, PriceHelper.getPriceFromId(id, binStep));

            uint256 feeShare = currentLiquidity > previousLiquidity
                ? (currentLiquidity - previousLiquidity).mulDivRoundDown(share, currentLiquidity)
                : 0;

            feeShares[i] = feeShare;

            (feesX[i], feesY[i]) = totalShares == 0
                ? (0, 0)
                : (feeShare.mulDivRoundDown(binReserveX, totalShares), feeShare.mulDivRoundDown(binReserveY, totalShares));

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Return the amounts of x and y for a given share amount
     * @param lbPair The pair
     * @param id The id
     * @param share The share amount
     * @return amountX The amount of token X
     * @return amountY The amount of token Y
     */
    function getAmountsForShare(ILBPair lbPair, uint256 id, uint256 share)
        internal
        view
        returns (uint256 amountX, uint256 amountY)
    {
        (uint256 binReserveX, uint256 binReserveY) = lbPair.getBin(id.safe24());
        uint256 totalShares = lbPair.totalSupply(id);

        (amountX, amountY) = totalShares == 0
            ? (0, 0)
            : (share.mulDivRoundDown(binReserveX, totalShares), share.mulDivRoundDown(binReserveY, totalShares));
    }

    /**
     * @dev Return the share amount of a given user at a given id
     * @param lbPair The pair
     * @param user The user
     * @param id The id
     * @return the share amount of the user at the given id
     */
    function getShareOfAtId(ILBPair lbPair, address user, uint24 id) internal view returns (uint256) {
        return lbPair.balanceOf(user, id);
    }

    /**
     * @dev Return the amounts of x and y of a given user at a given id
     * @param lbPair The pair
     * @param user The user
     * @param id The id
     * @return amountX The amount of token X
     * @return amountY The amount of token Y
     */
    function getAmountsOfAtId(ILBPair lbPair, address user, uint24 id)
        internal
        view
        returns (uint256 amountX, uint256 amountY)
    {
        uint256 share = getShareOfAtId(lbPair, user, id);
        (uint256 binReserveX, uint256 binReserveY) = lbPair.getBin(id);
        uint256 totalShares = lbPair.totalSupply(id);

        (amountX, amountY) = totalShares == 0
            ? (0, 0)
            : (share.mulDivRoundDown(binReserveX, totalShares), share.mulDivRoundDown(binReserveY, totalShares));
    }

    /**
     * @dev Return the fees earned of a given user at a given id from a given amounts of x and y
     * @param binStep The binStep of the pair
     * @param id The id
     * @param previousX The previous amount of token X
     * @param previousY The previous amount of token Y
     * @param amountX The current amount of token X
     * @param amountY The current amount of token Y
     * @return feesX The fees of token X
     * @return feesY The fees of token Y
     */
    function getFeesAtId(
        uint16 binStep,
        uint24 id,
        uint256 previousX,
        uint256 previousY,
        uint256 amountX,
        uint256 amountY
    ) internal pure returns (uint256 feesX, uint256 feesY) {
        uint256 price = PriceHelper.getPriceFromId(id, binStep);

        uint256 previousLiquidity = getLiquidityFromPrice(previousX, previousY, price);
        uint256 currentLiquidity = getLiquidityFromPrice(amountX, amountY, price);

        return getFeesFromLiquidities(previousLiquidity, currentLiquidity, amountX, amountY);
    }

    /**
     * @dev Return the fees earned of a given user at a given id from a given liquidity position
     * @param previousLiquidity The previous liquidity
     * @param currentLiquidity The current liquidity
     * @param amountX The current amount of token X
     * @param amountY The current amount of token Y
     * @return feesX The fees of token X
     * @return feesY The fees of token Y
     */
    function getFeesFromLiquidities(
        uint256 previousLiquidity,
        uint256 currentLiquidity,
        uint256 amountX,
        uint256 amountY
    ) internal pure returns (uint256 feesX, uint256 feesY) {
        if (currentLiquidity > previousLiquidity) {
            uint256 feesinL = (currentLiquidity - previousLiquidity);

            feesX = feesinL.mulDivRoundDown(amountX, currentLiquidity);
            feesY = feesinL.mulDivRoundDown(amountY, currentLiquidity);
        }
    }

    /**
     * @dev Return the share amount for a given liquidity at a given id
     * @param lbPair The pair
     * @param id The id
     * @param liquidity The liquidity
     * @param price The price
     * @return The share amount
     */
    function getShareForLiquidity(ILBPair lbPair, uint256 id, uint256 liquidity, uint256 price)
        internal
        view
        returns (uint256)
    {
        (uint256 binReserveX, uint256 binReserveY) = lbPair.getBin(id.safe24());
        uint256 binLiquidity = getLiquidityFromPrice(binReserveX, binReserveY, price);

        uint256 totalShares = lbPair.totalSupply(id);

        return binLiquidity == 0 ? 0 : liquidity.mulDivRoundDown(totalShares, binLiquidity);
    }

    /**
     * @dev Return the liquidity of a given amount of x and y at a given id
     * @param amountX The amount of token X
     * @param amountY The amount of token Y
     * @param id The id
     * @param binStep The binStep of the pair
     * @return liquidity The liquidity
     */
    function getLiquidityFromId(uint256 amountX, uint256 amountY, uint24 id, uint16 binStep)
        internal
        pure
        returns (uint256 liquidity)
    {
        return getLiquidityFromPrice(amountX, amountY, PriceHelper.getPriceFromId(id, binStep));
    }

    /**
     * @dev Return the liquidity of a given amount of x and y at a given price
     * The amount is returned as a 128.128 fixed point number
     * @param amountX The amount of token X
     * @param amountY The amount of token Y
     * @param price The price
     * @return liquidity The liquidity
     */
    function getLiquidityFromPrice(uint256 amountX, uint256 amountY, uint256 price)
        internal
        pure
        returns (uint256 liquidity)
    {
        return BinHelper.getLiquidity(amountX, amountY, price) >> 128;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Uint256x256Math} from "joe-v2/libraries/math/Uint256x256Math.sol";
import {ILBPair} from "joe-v2/interfaces/ILBPair.sol";

/**
 * @title Liquidity Book periphery library for fetching non-empty bins.
 * @notice Periphery library to help fetch the non-empty bins of a liquidity book.
 * @dev The caller must ensure that the parameters are valid following the comments.
 */
library NonEmptyBinHelper {
    struct PopulatedBin {
        uint24 id;
        uint128 reserveX;
        uint128 reserveY;
    }

    struct PopulatedBinUser {
        uint24 id;
        uint128 reserveX;
        uint128 reserveY;
        uint256 shares;
        uint256 totalShares;
    }

    /**
     * @dev Fetch the non-empty bins ids of a liquidity book pair from [start, end].
     * If length is specified, it will return the first `length` non-empty bins.
     * Returns the ids in a packed bytes array, where each id is 3 bytes.
     * @param pair The liquidity book pair.
     * @param start The start bin id.
     * @param end The end bin id. (inclusive)
     * @param length The number of non-empty bins to fetch. (optional)
     * @return ids The non-empty bins ids.
     */
    function getPopulatedBinsId(ILBPair pair, uint24 start, uint24 end, uint24 length)
        internal
        view
        returns (bytes memory)
    {
        (start, end) = start < end
            ? (start == 0 ? (0, end) : (start - 1, end))
            : (start == type(uint24).max ? (end, start) : (start + 1, end));

        length = length == 0 ? (end > start ? end - start : start - end) : length;

        bytes memory ids = new bytes(uint256(length) * 3); // pessimistic memory allocation of 3 bytes per id

        uint256 populatedBinCount = 0;
        uint256 memValue = ids.length;
        uint256 memSlot;

        assembly {
            memSlot := ids
        }

        uint24 id = start;
        bool swapForY = start > end;
        for (uint256 i; i < length && populatedBinCount < length; ++i) {
            id = pair.getNextNonEmptyBin(swapForY, id);

            if (swapForY ? id < end || id == type(uint24).max : id > end || id == 0) break;

            ++populatedBinCount;

            assembly {
                memValue := or(shl(24, memValue), id)
                memSlot := add(memSlot, 3)

                mstore(memSlot, memValue)
            }
        }

        assembly {
            mstore(ids, mul(3, populatedBinCount))
        }

        return ids;
    }

    /**
     * @notice Fetches the non-empty bins reserves of a liquidity book pair from [start, end].
     *  If length is specified, it will return the first `length` non-empty bins.
     * @param pair The liquidity book pair.
     * @param start The start bin id.
     * @param end The end bin id. (inclusive)
     * @param length The number of non-empty bins to fetch. (optional)
     * @return The array of populated bins with (id, reserveX, reserveY)
     */
    function getPopulatedBinsReserves(ILBPair pair, uint24 start, uint24 end, uint24 length)
        internal
        view
        returns (PopulatedBin[] memory)
    {
        bytes memory ids = getPopulatedBinsId(pair, start, end, length);

        uint256 populatedBinCount = ids.length / 3;
        PopulatedBin[] memory populatedBins = new PopulatedBin[](populatedBinCount);

        uint256 memSlot;
        assembly {
            memSlot := add(ids, 0x1d)
        }

        uint24 id;

        for (uint256 i; i < populatedBinCount; ++i) {
            assembly {
                memSlot := add(memSlot, 3)
                id := shr(232, mload(memSlot))
            }

            (uint128 reserveX, uint128 reserveY) = pair.getBin(id);
            populatedBins[i] = PopulatedBin(id, reserveX, reserveY);
        }

        return populatedBins;
    }

    /**
     * @notice Fetches the non-empty bins reserves of a liquidity book pair from [id-lengthLeft, id+lengthRight] where the user has liquidity.
     * If id is not specified, it will use the active bin id of the pair.
     * Will check `lengthLeft` non-empty bins on the left and `lengthRight` non-empty bins on the right, so if the user
     * has liquidity only after the `lengthLeft + 1` bin on the left and `lengthRight + 1` bin on the right, it will return
     * an empty array.
     * @param pair The liquidity book pair.
     * @param user The user.
     * @param id The specific bin id. (optional)
     * @param lengthLeft The number of non-empty bins to fetch on the left.
     * @param lengthRight The number of non-empty bins to fetch on the right.
     * @return The bin id used. (if id was not specified, it will return the active bin id)
     * @return The array of populated bins with (id, reserveX, reserveY, shares, totalShares)
     * The user amounts can be calculated as (shares * reserve{X,Y}) / totalShares.
     */
    function getBinsReserveOf(ILBPair pair, address user, uint24 id, uint24 lengthLeft, uint24 lengthRight)
        internal
        view
        returns (uint24, PopulatedBinUser[] memory)
    {
        if (id == 0) id = pair.getActiveId();

        bytes memory idsLeft =
            lengthLeft == 0 ? new bytes(0) : getPopulatedBinsId(pair, lengthRight == 0 ? id : id - 1, 0, lengthLeft);
        bytes memory idsRight =
            lengthRight == 0 ? new bytes(0) : getPopulatedBinsId(pair, id, type(uint24).max, lengthRight);

        uint256 populatedBinCountLeft = idsLeft.length / 3;
        uint256 populatedBinCountRight = idsRight.length / 3;
        uint256 populatedBinCount = populatedBinCountLeft + populatedBinCountRight;

        PopulatedBinUser[] memory userBins = new PopulatedBinUser[](populatedBinCount);

        uint256 memSlot;

        assembly {
            memSlot := add(add(idsLeft, 0x20), mul(populatedBinCountLeft, 3)) // Start at the end to reorder the ids
        }

        ILBPair pair_ = pair; // Avoid stack too deep error
        address user_ = user;

        uint256 i;
        while (i < populatedBinCountLeft) {
            uint24 binId;
            assembly {
                memSlot := sub(memSlot, 3)
                binId := shr(232, mload(memSlot))
            }

            uint256 shares = pair_.balanceOf(user_, binId);

            if (shares > 0) {
                (uint128 reserveX, uint128 reserveY) = pair_.getBin(binId);
                uint256 totalShares = pair_.totalSupply(binId);

                userBins[i++] = PopulatedBinUser(binId, reserveX, reserveY, shares, totalShares);
            } else {
                --populatedBinCountLeft;
            }
        }

        populatedBinCount = populatedBinCountLeft + populatedBinCountRight;

        assembly {
            memSlot := add(idsRight, 0x1d)
        }

        while (i < populatedBinCount) {
            uint24 binId;
            assembly {
                memSlot := add(memSlot, 3)
                binId := shr(232, mload(memSlot))
            }

            uint256 shares = pair_.balanceOf(user_, binId);

            if (shares > 0) {
                (uint128 reserveX, uint128 reserveY) = pair_.getBin(binId);
                uint256 totalShares = pair_.totalSupply(binId);

                userBins[i++] = PopulatedBinUser(binId, reserveX, reserveY, shares, totalShares);
            } else {
                --populatedBinCount;
            }
        }

        assembly {
            mstore(userBins, populatedBinCount)
        }

        return (id, userBins);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
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
pragma solidity ^0.8.10;

import {ILBHooks} from "../interfaces/ILBHooks.sol";

/**
 * @title Hooks library
 * @notice This library contains functions that should be used to interact with hooks
 */
library Hooks {
    error Hooks__CallFailed();

    bytes32 internal constant BEFORE_SWAP_FLAG = bytes32(uint256(1 << 160));
    bytes32 internal constant AFTER_SWAP_FLAG = bytes32(uint256(1 << 161));
    bytes32 internal constant BEFORE_FLASH_LOAN_FLAG = bytes32(uint256(1 << 162));
    bytes32 internal constant AFTER_FLASH_LOAN_FLAG = bytes32(uint256(1 << 163));
    bytes32 internal constant BEFORE_MINT_FLAG = bytes32(uint256(1 << 164));
    bytes32 internal constant AFTER_MINT_FLAG = bytes32(uint256(1 << 165));
    bytes32 internal constant BEFORE_BURN_FLAG = bytes32(uint256(1 << 166));
    bytes32 internal constant AFTER_BURN_FLAG = bytes32(uint256(1 << 167));
    bytes32 internal constant BEFORE_TRANSFER_FLAG = bytes32(uint256(1 << 168));
    bytes32 internal constant AFTER_TRANSFER_FLAG = bytes32(uint256(1 << 169));

    struct Parameters {
        address hooks;
        bool beforeSwap;
        bool afterSwap;
        bool beforeFlashLoan;
        bool afterFlashLoan;
        bool beforeMint;
        bool afterMint;
        bool beforeBurn;
        bool afterBurn;
        bool beforeBatchTransferFrom;
        bool afterBatchTransferFrom;
    }

    /**
     * @dev Helper function to encode the hooks parameters to a single bytes32 value
     * @param parameters The hooks parameters
     * @return hooksParameters The encoded hooks parameters
     */
    function encode(Parameters memory parameters) internal pure returns (bytes32 hooksParameters) {
        hooksParameters = bytes32(uint256(uint160(address(parameters.hooks))));

        if (parameters.beforeSwap) hooksParameters |= BEFORE_SWAP_FLAG;
        if (parameters.afterSwap) hooksParameters |= AFTER_SWAP_FLAG;
        if (parameters.beforeFlashLoan) hooksParameters |= BEFORE_FLASH_LOAN_FLAG;
        if (parameters.afterFlashLoan) hooksParameters |= AFTER_FLASH_LOAN_FLAG;
        if (parameters.beforeMint) hooksParameters |= BEFORE_MINT_FLAG;
        if (parameters.afterMint) hooksParameters |= AFTER_MINT_FLAG;
        if (parameters.beforeBurn) hooksParameters |= BEFORE_BURN_FLAG;
        if (parameters.afterBurn) hooksParameters |= AFTER_BURN_FLAG;
        if (parameters.beforeBatchTransferFrom) hooksParameters |= BEFORE_TRANSFER_FLAG;
        if (parameters.afterBatchTransferFrom) hooksParameters |= AFTER_TRANSFER_FLAG;
    }

    /**
     * @dev Helper function to decode the hooks parameters from a single bytes32 value
     * @param hooksParameters The encoded hooks parameters
     * @return parameters The hooks parameters
     */
    function decode(bytes32 hooksParameters) internal pure returns (Parameters memory parameters) {
        parameters.hooks = getHooks(hooksParameters);

        parameters.beforeSwap = (hooksParameters & BEFORE_SWAP_FLAG) != 0;
        parameters.afterSwap = (hooksParameters & AFTER_SWAP_FLAG) != 0;
        parameters.beforeFlashLoan = (hooksParameters & BEFORE_FLASH_LOAN_FLAG) != 0;
        parameters.afterFlashLoan = (hooksParameters & AFTER_FLASH_LOAN_FLAG) != 0;
        parameters.beforeMint = (hooksParameters & BEFORE_MINT_FLAG) != 0;
        parameters.afterMint = (hooksParameters & AFTER_MINT_FLAG) != 0;
        parameters.beforeBurn = (hooksParameters & BEFORE_BURN_FLAG) != 0;
        parameters.afterBurn = (hooksParameters & AFTER_BURN_FLAG) != 0;
        parameters.beforeBatchTransferFrom = (hooksParameters & BEFORE_TRANSFER_FLAG) != 0;
        parameters.afterBatchTransferFrom = (hooksParameters & AFTER_TRANSFER_FLAG) != 0;
    }

    /**
     * @dev Helper function to get the hooks address from the encoded hooks parameters
     * @param hooksParameters The encoded hooks parameters
     * @return hooks The hooks address
     */
    function getHooks(bytes32 hooksParameters) internal pure returns (address hooks) {
        hooks = address(uint160(uint256(hooksParameters)));
    }

    /**
     * @dev Helper function to set the hooks address in the encoded hooks parameters
     * @param hooksParameters The encoded hooks parameters
     * @param newHooks The new hooks address
     * @return hooksParameters The updated hooks parameters
     */
    function setHooks(bytes32 hooksParameters, address newHooks) internal pure returns (bytes32) {
        return bytes32(bytes12(hooksParameters)) | bytes32(uint256(uint160(newHooks)));
    }

    /**
     * @dev Helper function to get the flags from the encoded hooks parameters
     * @param hooksParameters The encoded hooks parameters
     * @return flags The flags
     */
    function getFlags(bytes32 hooksParameters) internal pure returns (bytes12 flags) {
        flags = bytes12(hooksParameters);
    }

    /**
     * @dev Helper function call the onHooksSet function on the hooks contract, only if the
     * hooksParameters is not 0
     * @param hooksParameters The encoded hooks parameters
     * @param onHooksSetData The data to pass to the onHooksSet function
     */
    function onHooksSet(bytes32 hooksParameters, bytes calldata onHooksSetData) internal {
        if (hooksParameters != 0) {
            _safeCall(
                hooksParameters, abi.encodeWithSelector(ILBHooks.onHooksSet.selector, hooksParameters, onHooksSetData)
            );
        }
    }

    /**
     * @dev Helper function to call the beforeSwap function on the hooks contract, only if the
     * BEFORE_SWAP_FLAG is set in the hooksParameters
     * @param hooksParameters The encoded hooks parameters
     * @param sender The sender
     * @param to The recipient
     * @param swapForY Whether the swap is for Y
     * @param amountsIn The amounts in
     */
    function beforeSwap(bytes32 hooksParameters, address sender, address to, bool swapForY, bytes32 amountsIn)
        internal
    {
        if ((hooksParameters & BEFORE_SWAP_FLAG) != 0) {
            _safeCall(
                hooksParameters, abi.encodeWithSelector(ILBHooks.beforeSwap.selector, sender, to, swapForY, amountsIn)
            );
        }
    }

    /**
     * @dev Helper function to call the afterSwap function on the hooks contract, only if the
     * AFTER_SWAP_FLAG is set in the hooksParameters
     * @param hooksParameters The encoded hooks parameters
     * @param sender The sender
     * @param to The recipient
     * @param swapForY Whether the swap is for Y
     * @param amountsOut The amounts out
     */
    function afterSwap(bytes32 hooksParameters, address sender, address to, bool swapForY, bytes32 amountsOut)
        internal
    {
        if ((hooksParameters & AFTER_SWAP_FLAG) != 0) {
            _safeCall(
                hooksParameters, abi.encodeWithSelector(ILBHooks.afterSwap.selector, sender, to, swapForY, amountsOut)
            );
        }
    }

    /**
     * @dev Helper function to call the beforeFlashLoan function on the hooks contract, only if the
     * BEFORE_FLASH_LOAN_FLAG is set in the hooksParameters
     * @param hooksParameters The encoded hooks parameters
     * @param sender The sender
     * @param to The recipient
     * @param amounts The amounts
     */
    function beforeFlashLoan(bytes32 hooksParameters, address sender, address to, bytes32 amounts) internal {
        if ((hooksParameters & BEFORE_FLASH_LOAN_FLAG) != 0) {
            _safeCall(hooksParameters, abi.encodeWithSelector(ILBHooks.beforeFlashLoan.selector, sender, to, amounts));
        }
    }

    /**
     * @dev Helper function to call the afterFlashLoan function on the hooks contract, only if the
     * AFTER_FLASH_LOAN_FLAG is set in the hooksParameters
     * @param hooksParameters The encoded hooks parameters
     * @param sender The sender
     * @param to The recipient
     * @param fees The fees
     * @param feesReceived The fees received
     */
    function afterFlashLoan(bytes32 hooksParameters, address sender, address to, bytes32 fees, bytes32 feesReceived)
        internal
    {
        if ((hooksParameters & AFTER_FLASH_LOAN_FLAG) != 0) {
            _safeCall(
                hooksParameters,
                abi.encodeWithSelector(ILBHooks.afterFlashLoan.selector, sender, to, fees, feesReceived)
            );
        }
    }

    /**
     * @dev Helper function to call the beforeMint function on the hooks contract, only if the
     * BEFORE_MINT_FLAG is set in the hooksParameters
     * @param hooksParameters The encoded hooks parameters
     * @param sender The sender
     * @param to The recipient
     * @param liquidityConfigs The liquidity configs
     * @param amountsReceived The amounts received
     */
    function beforeMint(
        bytes32 hooksParameters,
        address sender,
        address to,
        bytes32[] calldata liquidityConfigs,
        bytes32 amountsReceived
    ) internal {
        if ((hooksParameters & BEFORE_MINT_FLAG) != 0) {
            _safeCall(
                hooksParameters,
                abi.encodeWithSelector(ILBHooks.beforeMint.selector, sender, to, liquidityConfigs, amountsReceived)
            );
        }
    }

    /**
     * @dev Helper function to call the afterMint function on the hooks contract, only if the
     * AFTER_MINT_FLAG is set in the hooksParameters
     * @param hooksParameters The encoded hooks parameters
     * @param sender The sender
     * @param to The recipient
     * @param liquidityConfigs The liquidity configs
     * @param amountsIn The amounts in
     */
    function afterMint(
        bytes32 hooksParameters,
        address sender,
        address to,
        bytes32[] calldata liquidityConfigs,
        bytes32 amountsIn
    ) internal {
        if ((hooksParameters & AFTER_MINT_FLAG) != 0) {
            _safeCall(
                hooksParameters,
                abi.encodeWithSelector(ILBHooks.afterMint.selector, sender, to, liquidityConfigs, amountsIn)
            );
        }
    }

    /**
     * @dev Helper function to call the beforeBurn function on the hooks contract, only if the
     * BEFORE_BURN_FLAG is set in the hooksParameters
     * @param hooksParameters The encoded hooks parameters
     * @param sender The sender
     * @param from The sender
     * @param to The recipient
     * @param ids The ids
     * @param amountsToBurn The amounts to burn
     */
    function beforeBurn(
        bytes32 hooksParameters,
        address sender,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amountsToBurn
    ) internal {
        if ((hooksParameters & BEFORE_BURN_FLAG) != 0) {
            _safeCall(
                hooksParameters,
                abi.encodeWithSelector(ILBHooks.beforeBurn.selector, sender, from, to, ids, amountsToBurn)
            );
        }
    }

    /**
     * @dev Helper function to call the afterBurn function on the hooks contract, only if the
     * AFTER_BURN_FLAG is set in the hooksParameters
     * @param hooksParameters The encoded hooks parameters
     * @param sender The sender
     * @param from The sender
     * @param to The recipient
     * @param ids The ids
     * @param amountsToBurn The amounts to burn
     */
    function afterBurn(
        bytes32 hooksParameters,
        address sender,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amountsToBurn
    ) internal {
        if ((hooksParameters & AFTER_BURN_FLAG) != 0) {
            _safeCall(
                hooksParameters,
                abi.encodeWithSelector(ILBHooks.afterBurn.selector, sender, from, to, ids, amountsToBurn)
            );
        }
    }

    /**
     * @dev Helper function to call the beforeTransferFrom function on the hooks contract, only if the
     * BEFORE_TRANSFER_FLAG is set in the hooksParameters
     * @param hooksParameters The encoded hooks parameters
     * @param sender The sender
     * @param from The sender
     * @param to The recipient
     * @param ids The list of ids
     * @param amounts The list of amounts
     */
    function beforeBatchTransferFrom(
        bytes32 hooksParameters,
        address sender,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) internal {
        if ((hooksParameters & BEFORE_TRANSFER_FLAG) != 0) {
            _safeCall(
                hooksParameters,
                abi.encodeWithSelector(ILBHooks.beforeBatchTransferFrom.selector, sender, from, to, ids, amounts)
            );
        }
    }

    /**
     * @dev Helper function to call the afterTransferFrom function on the hooks contract, only if the
     * AFTER_TRANSFER_FLAG is set in the hooksParameters
     * @param hooksParameters The encoded hooks parameters
     * @param sender The sender
     * @param from The sender
     * @param to The recipient
     * @param ids The list of ids
     * @param amounts The list of amounts
     */
    function afterBatchTransferFrom(
        bytes32 hooksParameters,
        address sender,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) internal {
        if ((hooksParameters & AFTER_TRANSFER_FLAG) != 0) {
            _safeCall(
                hooksParameters,
                abi.encodeWithSelector(ILBHooks.afterBatchTransferFrom.selector, sender, from, to, ids, amounts)
            );
        }
    }

    /**
     * @dev Helper function to call the hooks contract and verify the call was successful
     * by matching the expected selector with the returned data
     * @param hooksParameters The encoded hooks parameters
     * @param data The data to pass to the hooks contract
     */
    function _safeCall(bytes32 hooksParameters, bytes memory data) private {
        bool success;

        address hooks = getHooks(hooksParameters);

        assembly {
            let expectedSelector := shr(224, mload(add(data, 0x20)))

            success := call(gas(), hooks, 0, add(data, 0x20), mload(data), 0, 0x20)

            if and(iszero(success), iszero(iszero(returndatasize()))) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }

            success := and(success, and(gt(returndatasize(), 0x1f), eq(shr(224, mload(0)), expectedSelector)))
        }

        if (!success) revert Hooks__CallFailed();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ILBHooks} from "./ILBHooks.sol";
import {ILBPair} from "./ILBPair.sol";

/**
 * @title Liquidity Book Factory Interface
 * @author Trader Joe
 * @notice Required interface of LBFactory contract
 */
interface ILBFactory {
    error LBFactory__IdenticalAddresses(IERC20 token);
    error LBFactory__QuoteAssetNotWhitelisted(IERC20 quoteAsset);
    error LBFactory__QuoteAssetAlreadyWhitelisted(IERC20 quoteAsset);
    error LBFactory__AddressZero();
    error LBFactory__LBPairAlreadyExists(IERC20 tokenX, IERC20 tokenY, uint256 _binStep);
    error LBFactory__LBPairDoesNotExist(IERC20 tokenX, IERC20 tokenY, uint256 binStep);
    error LBFactory__LBPairNotCreated(IERC20 tokenX, IERC20 tokenY, uint256 binStep);
    error LBFactory__FlashLoanFeeAboveMax(uint256 fees, uint256 maxFees);
    error LBFactory__BinStepTooLow(uint256 binStep);
    error LBFactory__PresetIsLockedForUsers(address user, uint256 binStep);
    error LBFactory__LBPairIgnoredIsAlreadyInTheSameState();
    error LBFactory__BinStepHasNoPreset(uint256 binStep);
    error LBFactory__PresetOpenStateIsAlreadyInTheSameState();
    error LBFactory__SameFeeRecipient(address feeRecipient);
    error LBFactory__SameFlashLoanFee(uint256 flashLoanFee);
    error LBFactory__LBPairSafetyCheckFailed(address LBPairImplementation);
    error LBFactory__SameImplementation(address LBPairImplementation);
    error LBFactory__ImplementationNotSet();
    error LBFactory__SameHooksImplementation(address hooksImplementation);
    error LBFactory__SameHooksParameters(bytes32 hooksParameters);
    error LBFactory__InvalidHooksParameters();
    error LBFactory__CannotGrantDefaultAdminRole();

    /**
     * @dev Structure to store the LBPair information, such as:
     * binStep: The bin step of the LBPair
     * LBPair: The address of the LBPair
     * createdByOwner: Whether the pair was created by the owner of the factory
     * ignoredForRouting: Whether the pair is ignored for routing or not. An ignored pair will not be explored during routes finding
     */
    struct LBPairInformation {
        uint16 binStep;
        ILBPair LBPair;
        bool createdByOwner;
        bool ignoredForRouting;
    }

    event LBPairCreated(
        IERC20 indexed tokenX, IERC20 indexed tokenY, uint256 indexed binStep, ILBPair LBPair, uint256 pid
    );

    event FeeRecipientSet(address oldRecipient, address newRecipient);

    event FlashLoanFeeSet(uint256 oldFlashLoanFee, uint256 newFlashLoanFee);

    event LBPairImplementationSet(address oldLBPairImplementation, address LBPairImplementation);

    event LBPairIgnoredStateChanged(ILBPair indexed LBPair, bool ignored);

    event PresetSet(
        uint256 indexed binStep,
        uint256 baseFactor,
        uint256 filterPeriod,
        uint256 decayPeriod,
        uint256 reductionFactor,
        uint256 variableFeeControl,
        uint256 protocolShare,
        uint256 maxVolatilityAccumulator
    );

    event PresetOpenStateChanged(uint256 indexed binStep, bool indexed isOpen);

    event PresetRemoved(uint256 indexed binStep);

    event QuoteAssetAdded(IERC20 indexed quoteAsset);

    event QuoteAssetRemoved(IERC20 indexed quoteAsset);

    function getMinBinStep() external pure returns (uint256);

    function getFeeRecipient() external view returns (address);

    function getMaxFlashLoanFee() external pure returns (uint256);

    function getFlashLoanFee() external view returns (uint256);

    function getLBPairImplementation() external view returns (address);

    function getNumberOfLBPairs() external view returns (uint256);

    function getLBPairAtIndex(uint256 id) external returns (ILBPair);

    function getNumberOfQuoteAssets() external view returns (uint256);

    function getQuoteAssetAtIndex(uint256 index) external view returns (IERC20);

    function isQuoteAsset(IERC20 token) external view returns (bool);

    function getLBPairInformation(IERC20 tokenX, IERC20 tokenY, uint256 binStep)
        external
        view
        returns (LBPairInformation memory);

    function getPreset(uint256 binStep)
        external
        view
        returns (
            uint256 baseFactor,
            uint256 filterPeriod,
            uint256 decayPeriod,
            uint256 reductionFactor,
            uint256 variableFeeControl,
            uint256 protocolShare,
            uint256 maxAccumulator,
            bool isOpen
        );

    function getAllBinSteps() external view returns (uint256[] memory presetsBinStep);

    function getOpenBinSteps() external view returns (uint256[] memory openBinStep);

    function getAllLBPairs(IERC20 tokenX, IERC20 tokenY)
        external
        view
        returns (LBPairInformation[] memory LBPairsBinStep);

    function setLBPairImplementation(address lbPairImplementation) external;

    function createLBPair(IERC20 tokenX, IERC20 tokenY, uint24 activeId, uint16 binStep)
        external
        returns (ILBPair pair);

    function setLBPairIgnored(IERC20 tokenX, IERC20 tokenY, uint16 binStep, bool ignored) external;

    function setPreset(
        uint16 binStep,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator,
        bool isOpen
    ) external;

    function setPresetOpenState(uint16 binStep, bool isOpen) external;

    function removePreset(uint16 binStep) external;

    function setFeesParametersOnPair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    ) external;

    function setLBHooksParametersOnPair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        bytes32 hooksParameters,
        bytes memory onHooksSetData
    ) external;

    function removeLBHooksOnPair(IERC20 tokenX, IERC20 tokenY, uint16 binStep) external;

    function setFeeRecipient(address feeRecipient) external;

    function setFlashLoanFee(uint256 flashLoanFee) external;

    function addQuoteAsset(IERC20 quoteAsset) external;

    function removeQuoteAsset(IERC20 quoteAsset) external;

    function forceDecay(ILBPair lbPair) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Liquidity Book Flashloan Callback Interface
/// @author Trader Joe
/// @notice Required interface to interact with LB flash loans
interface ILBFlashLoanCallback {
    function LBFlashLoanCallback(
        address sender,
        IERC20 tokenX,
        IERC20 tokenY,
        bytes32 amounts,
        bytes32 totalFees,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @title Liquidity Book Token Interface
 * @author Trader Joe
 * @notice Interface to interact with the LBToken.
 */
interface ILBToken {
    error LBToken__AddressThisOrZero();
    error LBToken__InvalidLength();
    error LBToken__SelfApproval(address owner);
    error LBToken__SpenderNotApproved(address from, address spender);
    error LBToken__TransferExceedsBalance(address from, uint256 id, uint256 amount);
    error LBToken__BurnExceedsBalance(address from, uint256 id, uint256 amount);

    event TransferBatch(
        address indexed sender, address indexed from, address indexed to, uint256[] ids, uint256[] amounts
    );

    event ApprovalForAll(address indexed account, address indexed sender, bool approved);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply(uint256 id) external view returns (uint256);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function isApprovedForAll(address owner, address spender) external view returns (bool);

    function approveForAll(address spender, bool approved) external;

    function batchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {BitMath} from "./BitMath.sol";

/**
 * @title Liquidity Book Uint256x256 Math Library
 * @author Trader Joe
 * @notice Helper contract used for full precision calculations
 */
library Uint256x256Math {
    error Uint256x256Math__MulShiftOverflow();
    error Uint256x256Math__MulDivOverflow();

    /**
     * @notice Calculates floor(x*y/denominator) with full precision
     * The result will be rounded down
     * @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
     * Requirements:
     * - The denominator cannot be zero
     * - The result must fit within uint256
     * Caveats:
     * - This function does not work with fixed-point numbers
     * @param x The multiplicand as an uint256
     * @param y The multiplier as an uint256
     * @param denominator The divisor as an uint256
     * @return result The result as an uint256
     */
    function mulDivRoundDown(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        (uint256 prod0, uint256 prod1) = _getMulProds(x, y);

        return _getEndOfDivRoundDown(x, y, denominator, prod0, prod1);
    }

    /**
     * @notice Calculates ceil(x*y/denominator) with full precision
     * The result will be rounded up
     * @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
     * Requirements:
     * - The denominator cannot be zero
     * - The result must fit within uint256
     * Caveats:
     * - This function does not work with fixed-point numbers
     * @param x The multiplicand as an uint256
     * @param y The multiplier as an uint256
     * @param denominator The divisor as an uint256
     * @return result The result as an uint256
     */
    function mulDivRoundUp(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        result = mulDivRoundDown(x, y, denominator);
        if (mulmod(x, y, denominator) != 0) result += 1;
    }

    /**
     * @notice Calculates floor(x * y / 2**offset) with full precision
     * The result will be rounded down
     * @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
     * Requirements:
     * - The offset needs to be strictly lower than 256
     * - The result must fit within uint256
     * Caveats:
     * - This function does not work with fixed-point numbers
     * @param x The multiplicand as an uint256
     * @param y The multiplier as an uint256
     * @param offset The offset as an uint256, can't be greater than 256
     * @return result The result as an uint256
     */
    function mulShiftRoundDown(uint256 x, uint256 y, uint8 offset) internal pure returns (uint256 result) {
        (uint256 prod0, uint256 prod1) = _getMulProds(x, y);

        if (prod0 != 0) result = prod0 >> offset;
        if (prod1 != 0) {
            // Make sure the result is less than 2^256.
            if (prod1 >= 1 << offset) revert Uint256x256Math__MulShiftOverflow();

            unchecked {
                result += prod1 << (256 - offset);
            }
        }
    }

    /**
     * @notice Calculates floor(x * y / 2**offset) with full precision
     * The result will be rounded down
     * @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
     * Requirements:
     * - The offset needs to be strictly lower than 256
     * - The result must fit within uint256
     * Caveats:
     * - This function does not work with fixed-point numbers
     * @param x The multiplicand as an uint256
     * @param y The multiplier as an uint256
     * @param offset The offset as an uint256, can't be greater than 256
     * @return result The result as an uint256
     */
    function mulShiftRoundUp(uint256 x, uint256 y, uint8 offset) internal pure returns (uint256 result) {
        result = mulShiftRoundDown(x, y, offset);
        if (mulmod(x, y, 1 << offset) != 0) result += 1;
    }

    /**
     * @notice Calculates floor(x << offset / y) with full precision
     * The result will be rounded down
     * @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
     * Requirements:
     * - The offset needs to be strictly lower than 256
     * - The result must fit within uint256
     * Caveats:
     * - This function does not work with fixed-point numbers
     * @param x The multiplicand as an uint256
     * @param offset The number of bit to shift x as an uint256
     * @param denominator The divisor as an uint256
     * @return result The result as an uint256
     */
    function shiftDivRoundDown(uint256 x, uint8 offset, uint256 denominator) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;

        prod0 = x << offset; // Least significant 256 bits of the product
        unchecked {
            prod1 = x >> (256 - offset); // Most significant 256 bits of the product
        }

        return _getEndOfDivRoundDown(x, 1 << offset, denominator, prod0, prod1);
    }

    /**
     * @notice Calculates ceil(x << offset / y) with full precision
     * The result will be rounded up
     * @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
     * Requirements:
     * - The offset needs to be strictly lower than 256
     * - The result must fit within uint256
     * Caveats:
     * - This function does not work with fixed-point numbers
     * @param x The multiplicand as an uint256
     * @param offset The number of bit to shift x as an uint256
     * @param denominator The divisor as an uint256
     * @return result The result as an uint256
     */
    function shiftDivRoundUp(uint256 x, uint8 offset, uint256 denominator) internal pure returns (uint256 result) {
        result = shiftDivRoundDown(x, offset, denominator);
        if (mulmod(x, 1 << offset, denominator) != 0) result += 1;
    }

    /**
     * @notice Helper function to return the result of `x * y` as 2 uint256
     * @param x The multiplicand as an uint256
     * @param y The multiplier as an uint256
     * @return prod0 The least significant 256 bits of the product
     * @return prod1 The most significant 256 bits of the product
     */
    function _getMulProds(uint256 x, uint256 y) private pure returns (uint256 prod0, uint256 prod1) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }
    }

    /**
     * @notice Helper function to return the result of `x * y / denominator` with full precision
     * @param x The multiplicand as an uint256
     * @param y The multiplier as an uint256
     * @param denominator The divisor as an uint256
     * @param prod0 The least significant 256 bits of the product
     * @param prod1 The most significant 256 bits of the product
     * @return result The result as an uint256
     */
    function _getEndOfDivRoundDown(uint256 x, uint256 y, uint256 denominator, uint256 prod0, uint256 prod1)
        private
        pure
        returns (uint256 result)
    {
        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            unchecked {
                result = prod0 / denominator;
            }
        } else {
            // Make sure the result is less than 2^256. Also prevents denominator == 0
            if (prod1 >= denominator) revert Uint256x256Math__MulDivOverflow();

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1
            // See https://cs.stackexchange.com/q/138556/92363
            unchecked {
                // Does not overflow because the denominator cannot be zero at this stage in the function
                uint256 lpotdod = denominator & (~denominator + 1);
                assembly {
                    // Divide denominator by lpotdod.
                    denominator := div(denominator, lpotdod)

                    // Divide [prod1 prod0] by lpotdod.
                    prod0 := div(prod0, lpotdod)

                    // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one
                    lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
                }

                // Shift in bits from prod1 into prod0
                prod0 |= prod1 * lpotdod;

                // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
                // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
                // four bits. That is, denominator * inv = 1 mod 2^4
                uint256 inverse = (3 * denominator) ^ 2;

                // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
                // in modular arithmetic, doubling the correct bits in each step
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
            }
        }
    }

    /**
     * @notice Calculates the square root of x
     * @dev Credit to OpenZeppelin's Math library under MIT license
     */
    function sqrt(uint256 x) internal pure returns (uint256 sqrtX) {
        if (x == 0) return 0;

        uint256 msb = BitMath.mostSignificantBit(x);

        assembly {
            sqrtX := shl(shr(1, msb), 1)

            sqrtX := shr(1, add(sqrtX, div(x, sqrtX)))
            sqrtX := shr(1, add(sqrtX, div(x, sqrtX)))
            sqrtX := shr(1, add(sqrtX, div(x, sqrtX)))
            sqrtX := shr(1, add(sqrtX, div(x, sqrtX)))
            sqrtX := shr(1, add(sqrtX, div(x, sqrtX)))
            sqrtX := shr(1, add(sqrtX, div(x, sqrtX)))
            sqrtX := shr(1, add(sqrtX, div(x, sqrtX)))

            x := div(x, sqrtX)
        }

        return sqrtX < x ? sqrtX : x;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {Uint128x128Math} from "./math/Uint128x128Math.sol";
import {Uint256x256Math} from "./math/Uint256x256Math.sol";
import {SafeCast} from "./math/SafeCast.sol";
import {Constants} from "./Constants.sol";

/**
 * @title Liquidity Book Price Helper Library
 * @author Trader Joe
 * @notice This library contains functions to calculate prices
 */
library PriceHelper {
    using Uint128x128Math for uint256;
    using Uint256x256Math for uint256;
    using SafeCast for uint256;

    int256 private constant REAL_ID_SHIFT = 1 << 23;

    /**
     * @dev Calculates the price from the id and the bin step
     * @param id The id
     * @param binStep The bin step
     * @return price The price as a 128.128-binary fixed-point number
     */
    function getPriceFromId(uint24 id, uint16 binStep) internal pure returns (uint256 price) {
        uint256 base = getBase(binStep);
        int256 exponent = getExponent(id);

        price = base.pow(exponent);
    }

    /**
     * @dev Calculates the id from the price and the bin step
     * @param price The price as a 128.128-binary fixed-point number
     * @param binStep The bin step
     * @return id The id
     */
    function getIdFromPrice(uint256 price, uint16 binStep) internal pure returns (uint24 id) {
        uint256 base = getBase(binStep);
        int256 realId = price.log2() / base.log2();

        unchecked {
            id = uint256(REAL_ID_SHIFT + realId).safe24();
        }
    }

    /**
     * @dev Calculates the base from the bin step, which is `1 + binStep / BASIS_POINT_MAX`
     * @param binStep The bin step
     * @return base The base
     */
    function getBase(uint16 binStep) internal pure returns (uint256) {
        unchecked {
            return Constants.SCALE + (uint256(binStep) << Constants.SCALE_OFFSET) / Constants.BASIS_POINT_MAX;
        }
    }

    /**
     * @dev Calculates the exponent from the id, which is `id - REAL_ID_SHIFT`
     * @param id The id
     * @return exponent The exponent
     */
    function getExponent(uint24 id) internal pure returns (int256) {
        unchecked {
            return int256(uint256(id)) - REAL_ID_SHIFT;
        }
    }

    /**
     * @dev Converts a price with 18 decimals to a 128.128-binary fixed-point number
     * @param price The price with 18 decimals
     * @return price128x128 The 128.128-binary fixed-point number
     */
    function convertDecimalPriceTo128x128(uint256 price) internal pure returns (uint256) {
        return price.shiftDivRoundDown(Constants.SCALE_OFFSET, Constants.PRECISION);
    }

    /**
     * @dev Converts a 128.128-binary fixed-point number to a price with 18 decimals
     * @param price128x128 The 128.128-binary fixed-point number
     * @return price The price with 18 decimals
     */
    function convert128x128PriceToDecimal(uint256 price128x128) internal pure returns (uint256) {
        return price128x128.mulShiftRoundDown(Constants.PRECISION, Constants.SCALE_OFFSET);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {PackedUint128Math} from "./math/PackedUint128Math.sol";
import {Uint256x256Math} from "./math/Uint256x256Math.sol";
import {SafeCast} from "./math/SafeCast.sol";
import {Constants} from "./Constants.sol";
import {PairParameterHelper} from "./PairParameterHelper.sol";
import {FeeHelper} from "./FeeHelper.sol";
import {PriceHelper} from "./PriceHelper.sol";

/**
 * @title Liquidity Book Bin Helper Library
 * @author Trader Joe
 * @notice This library contains functions to help interaction with bins.
 */
library BinHelper {
    using PackedUint128Math for bytes32;
    using PackedUint128Math for uint128;
    using Uint256x256Math for uint256;
    using PriceHelper for uint24;
    using SafeCast for uint256;
    using PairParameterHelper for bytes32;
    using FeeHelper for uint128;
    using SafeERC20 for IERC20;

    error BinHelper__CompositionFactorFlawed(uint24 id);
    error BinHelper__LiquidityOverflow();

    /**
     * @dev Returns the amount of tokens that will be received when burning the given amount of liquidity
     * @param binReserves The reserves of the bin
     * @param amountToBurn The amount of liquidity to burn
     * @param totalSupply The total supply of the liquidity book
     * @return amountsOut The encoded amount of tokens that will be received
     */
    function getAmountOutOfBin(bytes32 binReserves, uint256 amountToBurn, uint256 totalSupply)
        internal
        pure
        returns (bytes32 amountsOut)
    {
        (uint128 binReserveX, uint128 binReserveY) = binReserves.decode();

        uint128 amountXOutFromBin;
        uint128 amountYOutFromBin;

        if (binReserveX > 0) {
            amountXOutFromBin = (amountToBurn.mulDivRoundDown(binReserveX, totalSupply)).safe128();
        }

        if (binReserveY > 0) {
            amountYOutFromBin = (amountToBurn.mulDivRoundDown(binReserveY, totalSupply)).safe128();
        }

        amountsOut = amountXOutFromBin.encode(amountYOutFromBin);
    }

    /**
     * @dev Returns the share and the effective amounts in when adding liquidity
     * @param binReserves The reserves of the bin
     * @param amountsIn The amounts of tokens to add
     * @param price The price of the bin
     * @param totalSupply The total supply of the liquidity book
     * @return shares The share of the liquidity book that the user will receive
     * @return effectiveAmountsIn The encoded effective amounts of tokens that the user will add.
     * This is the amount of tokens that the user will actually add to the liquidity book,
     * and will always be less than or equal to the amountsIn.
     */
    function getSharesAndEffectiveAmountsIn(bytes32 binReserves, bytes32 amountsIn, uint256 price, uint256 totalSupply)
        internal
        pure
        returns (uint256 shares, bytes32 effectiveAmountsIn)
    {
        (uint256 x, uint256 y) = amountsIn.decode();

        uint256 userLiquidity = getLiquidity(x, y, price);
        if (userLiquidity == 0) return (0, 0);

        uint256 binLiquidity = getLiquidity(binReserves, price);
        if (binLiquidity == 0 || totalSupply == 0) return (userLiquidity.sqrt(), amountsIn);

        shares = userLiquidity.mulDivRoundDown(totalSupply, binLiquidity);
        uint256 effectiveLiquidity = shares.mulDivRoundUp(binLiquidity, totalSupply);

        if (userLiquidity > effectiveLiquidity) {
            uint256 deltaLiquidity = userLiquidity - effectiveLiquidity;

            // The other way might be more efficient, but as y is the quote asset, it is more valuable
            if (deltaLiquidity >= Constants.SCALE) {
                uint256 deltaY = deltaLiquidity >> Constants.SCALE_OFFSET;
                deltaY = deltaY > y ? y : deltaY;

                y -= deltaY;
                deltaLiquidity -= deltaY << Constants.SCALE_OFFSET;
            }

            if (deltaLiquidity >= price) {
                uint256 deltaX = deltaLiquidity / price;
                deltaX = deltaX > x ? x : deltaX;

                x -= deltaX;
            }

            amountsIn = uint128(x).encode(uint128(y));
        }

        return (shares, amountsIn);
    }

    /**
     * @dev Returns the amount of liquidity following the constant sum formula `L = price * x + y`
     * @param amounts The amounts of tokens
     * @param price The price of the bin
     * @return liquidity The amount of liquidity
     */
    function getLiquidity(bytes32 amounts, uint256 price) internal pure returns (uint256 liquidity) {
        (uint256 x, uint256 y) = amounts.decode();
        return getLiquidity(x, y, price);
    }

    /**
     * @dev Returns the amount of liquidity following the constant sum formula `L = price * x + y`
     * @param x The amount of the token X
     * @param y The amount of the token Y
     * @param price The price of the bin
     * @return liquidity The amount of liquidity
     */
    function getLiquidity(uint256 x, uint256 y, uint256 price) internal pure returns (uint256 liquidity) {
        if (x > 0) {
            unchecked {
                liquidity = price * x;
                if (liquidity / x != price) revert BinHelper__LiquidityOverflow();
            }
        }
        if (y > 0) {
            unchecked {
                y <<= Constants.SCALE_OFFSET;
                liquidity += y;

                if (liquidity < y) revert BinHelper__LiquidityOverflow();
            }
        }

        return liquidity;
    }

    /**
     * @dev Verify that the amounts are correct and that the composition factor is not flawed
     * @param amounts The amounts of tokens
     * @param activeId The id of the active bin
     * @param id The id of the bin
     */
    function verifyAmounts(bytes32 amounts, uint24 activeId, uint24 id) internal pure {
        if (id < activeId && (amounts << 128) > 0 || id > activeId && uint256(amounts) > type(uint128).max) {
            revert BinHelper__CompositionFactorFlawed(id);
        }
    }

    /**
     * @dev Returns the composition fees when adding liquidity to the active bin with a different
     * composition factor than the bin's one, as it does an implicit swap
     * @param binReserves The reserves of the bin
     * @param parameters The parameters of the liquidity book
     * @param binStep The step of the bin
     * @param amountsIn The amounts of tokens to add
     * @param totalSupply The total supply of the liquidity book
     * @param shares The share of the liquidity book that the user will receive
     * @return fees The encoded fees that will be charged
     */
    function getCompositionFees(
        bytes32 binReserves,
        bytes32 parameters,
        uint16 binStep,
        bytes32 amountsIn,
        uint256 totalSupply,
        uint256 shares
    ) internal pure returns (bytes32 fees) {
        if (shares == 0) return 0;

        (uint128 amountX, uint128 amountY) = amountsIn.decode();
        (uint128 receivedAmountX, uint128 receivedAmountY) =
            getAmountOutOfBin(binReserves.add(amountsIn), shares, totalSupply + shares).decode();

        if (receivedAmountX > amountX) {
            uint128 feeY = (amountY - receivedAmountY).getCompositionFee(parameters.getTotalFee(binStep));

            fees = feeY.encodeSecond();
        } else if (receivedAmountY > amountY) {
            uint128 feeX = (amountX - receivedAmountX).getCompositionFee(parameters.getTotalFee(binStep));

            fees = feeX.encodeFirst();
        }
    }

    /**
     * @dev Returns whether the bin is empty (true) or not (false)
     * @param binReserves The reserves of the bin
     * @param isX Whether the reserve to check is the X reserve (true) or the Y reserve (false)
     * @return Whether the bin is empty (true) or not (false)
     */
    function isEmpty(bytes32 binReserves, bool isX) internal pure returns (bool) {
        return isX ? binReserves.decodeX() == 0 : binReserves.decodeY() == 0;
    }

    /**
     * @dev Returns the amounts of tokens that will be added and removed from the bin during a swap
     * along with the fees that will be charged
     * @param binReserves The reserves of the bin
     * @param parameters The parameters of the liquidity book
     * @param binStep The step of the bin
     * @param swapForY Whether the swap is for Y (true) or for X (false)
     * @param activeId The id of the active bin
     * @param amountsInLeft The amounts of tokens left to swap
     * @return amountsInWithFees The encoded amounts of tokens that will be added to the bin, including fees
     * @return amountsOutOfBin The encoded amounts of tokens that will be removed from the bin
     * @return totalFees The encoded fees that will be charged
     */
    function getAmounts(
        bytes32 binReserves,
        bytes32 parameters,
        uint16 binStep,
        bool swapForY, // swap `swapForY` and `activeId` to avoid stack too deep
        uint24 activeId,
        bytes32 amountsInLeft
    ) internal pure returns (bytes32 amountsInWithFees, bytes32 amountsOutOfBin, bytes32 totalFees) {
        uint256 price = activeId.getPriceFromId(binStep);

        uint128 binReserveOut = binReserves.decode(!swapForY);

        uint128 maxAmountIn = swapForY
            ? uint256(binReserveOut).shiftDivRoundUp(Constants.SCALE_OFFSET, price).safe128()
            : uint256(binReserveOut).mulShiftRoundUp(price, Constants.SCALE_OFFSET).safe128();

        uint128 totalFee = parameters.getTotalFee(binStep);
        uint128 maxFee = maxAmountIn.getFeeAmount(totalFee);

        maxAmountIn += maxFee;

        uint128 amountIn128 = amountsInLeft.decode(swapForY);
        uint128 fee128;
        uint128 amountOut128;

        if (amountIn128 >= maxAmountIn) {
            fee128 = maxFee;

            amountIn128 = maxAmountIn;
            amountOut128 = binReserveOut;
        } else {
            fee128 = amountIn128.getFeeAmountFrom(totalFee);

            uint256 amountIn = amountIn128 - fee128;

            amountOut128 = swapForY
                ? uint256(amountIn).mulShiftRoundDown(price, Constants.SCALE_OFFSET).safe128()
                : uint256(amountIn).shiftDivRoundDown(Constants.SCALE_OFFSET, price).safe128();

            if (amountOut128 > binReserveOut) amountOut128 = binReserveOut;
        }

        (amountsInWithFees, amountsOutOfBin, totalFees) = swapForY
            ? (amountIn128.encodeFirst(), amountOut128.encodeSecond(), fee128.encodeFirst())
            : (amountIn128.encodeSecond(), amountOut128.encodeFirst(), fee128.encodeSecond());
    }

    /**
     * @dev Returns the encoded amounts that were transferred to the contract
     * @param reserves The reserves
     * @param tokenX The token X
     * @param tokenY The token Y
     * @return amounts The amounts, encoded as follows:
     * [0 - 128[: amountX
     * [128 - 256[: amountY
     */
    function received(bytes32 reserves, IERC20 tokenX, IERC20 tokenY) internal view returns (bytes32 amounts) {
        amounts = _balanceOf(tokenX).encode(_balanceOf(tokenY)).sub(reserves);
    }

    /**
     * @dev Returns the encoded amounts that were transferred to the contract, only for token X
     * @param reserves The reserves
     * @param tokenX The token X
     * @return amounts The amounts, encoded as follows:
     * [0 - 128[: amountX
     * [128 - 256[: empty
     */
    function receivedX(bytes32 reserves, IERC20 tokenX) internal view returns (bytes32) {
        uint128 reserveX = reserves.decodeX();
        return (_balanceOf(tokenX) - reserveX).encodeFirst();
    }

    /**
     * @dev Returns the encoded amounts that were transferred to the contract, only for token Y
     * @param reserves The reserves
     * @param tokenY The token Y
     * @return amounts The amounts, encoded as follows:
     * [0 - 128[: empty
     * [128 - 256[: amountY
     */
    function receivedY(bytes32 reserves, IERC20 tokenY) internal view returns (bytes32) {
        uint128 reserveY = reserves.decodeY();
        return (_balanceOf(tokenY) - reserveY).encodeSecond();
    }

    /**
     * @dev Transfers the encoded amounts to the recipient
     * @param amounts The amounts, encoded as follows:
     * [0 - 128[: amountX
     * [128 - 256[: amountY
     * @param tokenX The token X
     * @param tokenY The token Y
     * @param recipient The recipient
     */
    function transfer(bytes32 amounts, IERC20 tokenX, IERC20 tokenY, address recipient) internal {
        (uint128 amountX, uint128 amountY) = amounts.decode();

        if (amountX > 0) tokenX.safeTransfer(recipient, amountX);
        if (amountY > 0) tokenY.safeTransfer(recipient, amountY);
    }

    /**
     * @dev Transfers the encoded amounts to the recipient, only for token X
     * @param amounts The amounts, encoded as follows:
     * [0 - 128[: amountX
     * [128 - 256[: empty
     * @param tokenX The token X
     * @param recipient The recipient
     */
    function transferX(bytes32 amounts, IERC20 tokenX, address recipient) internal {
        uint128 amountX = amounts.decodeX();

        if (amountX > 0) tokenX.safeTransfer(recipient, amountX);
    }

    /**
     * @dev Transfers the encoded amounts to the recipient, only for token Y
     * @param amounts The amounts, encoded as follows:
     * [0 - 128[: empty
     * [128 - 256[: amountY
     * @param tokenY The token Y
     * @param recipient The recipient
     */
    function transferY(bytes32 amounts, IERC20 tokenY, address recipient) internal {
        uint128 amountY = amounts.decodeY();

        if (amountY > 0) tokenY.safeTransfer(recipient, amountY);
    }

    function _balanceOf(IERC20 token) private view returns (uint128) {
        return token.balanceOf(address(this)).safe128();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @title Liquidity Book Safe Cast Library
 * @author Trader Joe
 * @notice This library contains functions to safely cast uint256 to different uint types.
 */
library SafeCast {
    error SafeCast__Exceeds248Bits();
    error SafeCast__Exceeds240Bits();
    error SafeCast__Exceeds232Bits();
    error SafeCast__Exceeds224Bits();
    error SafeCast__Exceeds216Bits();
    error SafeCast__Exceeds208Bits();
    error SafeCast__Exceeds200Bits();
    error SafeCast__Exceeds192Bits();
    error SafeCast__Exceeds184Bits();
    error SafeCast__Exceeds176Bits();
    error SafeCast__Exceeds168Bits();
    error SafeCast__Exceeds160Bits();
    error SafeCast__Exceeds152Bits();
    error SafeCast__Exceeds144Bits();
    error SafeCast__Exceeds136Bits();
    error SafeCast__Exceeds128Bits();
    error SafeCast__Exceeds120Bits();
    error SafeCast__Exceeds112Bits();
    error SafeCast__Exceeds104Bits();
    error SafeCast__Exceeds96Bits();
    error SafeCast__Exceeds88Bits();
    error SafeCast__Exceeds80Bits();
    error SafeCast__Exceeds72Bits();
    error SafeCast__Exceeds64Bits();
    error SafeCast__Exceeds56Bits();
    error SafeCast__Exceeds48Bits();
    error SafeCast__Exceeds40Bits();
    error SafeCast__Exceeds32Bits();
    error SafeCast__Exceeds24Bits();
    error SafeCast__Exceeds16Bits();
    error SafeCast__Exceeds8Bits();

    /**
     * @dev Returns x on uint248 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint248
     */
    function safe248(uint256 x) internal pure returns (uint248 y) {
        if ((y = uint248(x)) != x) revert SafeCast__Exceeds248Bits();
    }

    /**
     * @dev Returns x on uint240 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint240
     */
    function safe240(uint256 x) internal pure returns (uint240 y) {
        if ((y = uint240(x)) != x) revert SafeCast__Exceeds240Bits();
    }

    /**
     * @dev Returns x on uint232 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint232
     */
    function safe232(uint256 x) internal pure returns (uint232 y) {
        if ((y = uint232(x)) != x) revert SafeCast__Exceeds232Bits();
    }

    /**
     * @dev Returns x on uint224 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint224
     */
    function safe224(uint256 x) internal pure returns (uint224 y) {
        if ((y = uint224(x)) != x) revert SafeCast__Exceeds224Bits();
    }

    /**
     * @dev Returns x on uint216 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint216
     */
    function safe216(uint256 x) internal pure returns (uint216 y) {
        if ((y = uint216(x)) != x) revert SafeCast__Exceeds216Bits();
    }

    /**
     * @dev Returns x on uint208 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint208
     */
    function safe208(uint256 x) internal pure returns (uint208 y) {
        if ((y = uint208(x)) != x) revert SafeCast__Exceeds208Bits();
    }

    /**
     * @dev Returns x on uint200 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint200
     */
    function safe200(uint256 x) internal pure returns (uint200 y) {
        if ((y = uint200(x)) != x) revert SafeCast__Exceeds200Bits();
    }

    /**
     * @dev Returns x on uint192 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint192
     */
    function safe192(uint256 x) internal pure returns (uint192 y) {
        if ((y = uint192(x)) != x) revert SafeCast__Exceeds192Bits();
    }

    /**
     * @dev Returns x on uint184 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint184
     */
    function safe184(uint256 x) internal pure returns (uint184 y) {
        if ((y = uint184(x)) != x) revert SafeCast__Exceeds184Bits();
    }

    /**
     * @dev Returns x on uint176 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint176
     */
    function safe176(uint256 x) internal pure returns (uint176 y) {
        if ((y = uint176(x)) != x) revert SafeCast__Exceeds176Bits();
    }

    /**
     * @dev Returns x on uint168 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint168
     */
    function safe168(uint256 x) internal pure returns (uint168 y) {
        if ((y = uint168(x)) != x) revert SafeCast__Exceeds168Bits();
    }

    /**
     * @dev Returns x on uint160 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint160
     */
    function safe160(uint256 x) internal pure returns (uint160 y) {
        if ((y = uint160(x)) != x) revert SafeCast__Exceeds160Bits();
    }

    /**
     * @dev Returns x on uint152 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint152
     */
    function safe152(uint256 x) internal pure returns (uint152 y) {
        if ((y = uint152(x)) != x) revert SafeCast__Exceeds152Bits();
    }

    /**
     * @dev Returns x on uint144 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint144
     */
    function safe144(uint256 x) internal pure returns (uint144 y) {
        if ((y = uint144(x)) != x) revert SafeCast__Exceeds144Bits();
    }

    /**
     * @dev Returns x on uint136 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint136
     */
    function safe136(uint256 x) internal pure returns (uint136 y) {
        if ((y = uint136(x)) != x) revert SafeCast__Exceeds136Bits();
    }

    /**
     * @dev Returns x on uint128 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint128
     */
    function safe128(uint256 x) internal pure returns (uint128 y) {
        if ((y = uint128(x)) != x) revert SafeCast__Exceeds128Bits();
    }

    /**
     * @dev Returns x on uint120 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint120
     */
    function safe120(uint256 x) internal pure returns (uint120 y) {
        if ((y = uint120(x)) != x) revert SafeCast__Exceeds120Bits();
    }

    /**
     * @dev Returns x on uint112 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint112
     */
    function safe112(uint256 x) internal pure returns (uint112 y) {
        if ((y = uint112(x)) != x) revert SafeCast__Exceeds112Bits();
    }

    /**
     * @dev Returns x on uint104 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint104
     */
    function safe104(uint256 x) internal pure returns (uint104 y) {
        if ((y = uint104(x)) != x) revert SafeCast__Exceeds104Bits();
    }

    /**
     * @dev Returns x on uint96 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint96
     */
    function safe96(uint256 x) internal pure returns (uint96 y) {
        if ((y = uint96(x)) != x) revert SafeCast__Exceeds96Bits();
    }

    /**
     * @dev Returns x on uint88 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint88
     */
    function safe88(uint256 x) internal pure returns (uint88 y) {
        if ((y = uint88(x)) != x) revert SafeCast__Exceeds88Bits();
    }

    /**
     * @dev Returns x on uint80 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint80
     */
    function safe80(uint256 x) internal pure returns (uint80 y) {
        if ((y = uint80(x)) != x) revert SafeCast__Exceeds80Bits();
    }

    /**
     * @dev Returns x on uint72 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint72
     */
    function safe72(uint256 x) internal pure returns (uint72 y) {
        if ((y = uint72(x)) != x) revert SafeCast__Exceeds72Bits();
    }

    /**
     * @dev Returns x on uint64 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint64
     */
    function safe64(uint256 x) internal pure returns (uint64 y) {
        if ((y = uint64(x)) != x) revert SafeCast__Exceeds64Bits();
    }

    /**
     * @dev Returns x on uint56 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint56
     */
    function safe56(uint256 x) internal pure returns (uint56 y) {
        if ((y = uint56(x)) != x) revert SafeCast__Exceeds56Bits();
    }

    /**
     * @dev Returns x on uint48 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint48
     */
    function safe48(uint256 x) internal pure returns (uint48 y) {
        if ((y = uint48(x)) != x) revert SafeCast__Exceeds48Bits();
    }

    /**
     * @dev Returns x on uint40 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint40
     */
    function safe40(uint256 x) internal pure returns (uint40 y) {
        if ((y = uint40(x)) != x) revert SafeCast__Exceeds40Bits();
    }

    /**
     * @dev Returns x on uint32 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint32
     */
    function safe32(uint256 x) internal pure returns (uint32 y) {
        if ((y = uint32(x)) != x) revert SafeCast__Exceeds32Bits();
    }

    /**
     * @dev Returns x on uint24 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint24
     */
    function safe24(uint256 x) internal pure returns (uint24 y) {
        if ((y = uint24(x)) != x) revert SafeCast__Exceeds24Bits();
    }

    /**
     * @dev Returns x on uint16 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint16
     */
    function safe16(uint256 x) internal pure returns (uint16 y) {
        if ((y = uint16(x)) != x) revert SafeCast__Exceeds16Bits();
    }

    /**
     * @dev Returns x on uint8 and check that it does not overflow
     * @param x The value as an uint256
     * @return y The value as an uint8
     */
    function safe8(uint256 x) internal pure returns (uint8 y) {
        if ((y = uint8(x)) != x) revert SafeCast__Exceeds8Bits();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ILBPair} from "./ILBPair.sol";

import {Hooks} from "../libraries/Hooks.sol";

interface ILBHooks {
    function getLBPair() external view returns (ILBPair);

    function isLinked() external view returns (bool);

    function onHooksSet(bytes32 hooksParameters, bytes calldata onHooksSetData) external returns (bytes4);

    function beforeSwap(address sender, address to, bool swapForY, bytes32 amountsIn) external returns (bytes4);

    function afterSwap(address sender, address to, bool swapForY, bytes32 amountsOut) external returns (bytes4);

    function beforeFlashLoan(address sender, address to, bytes32 amounts) external returns (bytes4);

    function afterFlashLoan(address sender, address to, bytes32 fees, bytes32 feesReceived) external returns (bytes4);

    function beforeMint(address sender, address to, bytes32[] calldata liquidityConfigs, bytes32 amountsReceived)
        external
        returns (bytes4);

    function afterMint(address sender, address to, bytes32[] calldata liquidityConfigs, bytes32 amountsIn)
        external
        returns (bytes4);

    function beforeBurn(
        address sender,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amountsToBurn
    ) external returns (bytes4);

    function afterBurn(
        address sender,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amountsToBurn
    ) external returns (bytes4);

    function beforeBatchTransferFrom(
        address sender,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external returns (bytes4);

    function afterBatchTransferFrom(
        address sender,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @title Liquidity Book Bit Math Library
 * @author Trader Joe
 * @notice Helper contract used for bit calculations
 */
library BitMath {
    /**
     * @dev Returns the index of the closest bit on the right of x that is non null
     * @param x The value as a uint256
     * @param bit The index of the bit to start searching at
     * @return id The index of the closest non null bit on the right of x.
     * If there is no closest bit, it returns max(uint256)
     */
    function closestBitRight(uint256 x, uint8 bit) internal pure returns (uint256 id) {
        unchecked {
            uint256 shift = 255 - bit;
            x <<= shift;

            // can't overflow as it's non-zero and we shifted it by `_shift`
            return (x == 0) ? type(uint256).max : mostSignificantBit(x) - shift;
        }
    }

    /**
     * @dev Returns the index of the closest bit on the left of x that is non null
     * @param x The value as a uint256
     * @param bit The index of the bit to start searching at
     * @return id The index of the closest non null bit on the left of x.
     * If there is no closest bit, it returns max(uint256)
     */
    function closestBitLeft(uint256 x, uint8 bit) internal pure returns (uint256 id) {
        unchecked {
            x >>= bit;

            return (x == 0) ? type(uint256).max : leastSignificantBit(x) + bit;
        }
    }

    /**
     * @dev Returns the index of the most significant bit of x
     * This function returns 0 if x is 0
     * @param x The value as a uint256
     * @return msb The index of the most significant bit of x
     */
    function mostSignificantBit(uint256 x) internal pure returns (uint8 msb) {
        assembly {
            if gt(x, 0xffffffffffffffffffffffffffffffff) {
                x := shr(128, x)
                msb := 128
            }
            if gt(x, 0xffffffffffffffff) {
                x := shr(64, x)
                msb := add(msb, 64)
            }
            if gt(x, 0xffffffff) {
                x := shr(32, x)
                msb := add(msb, 32)
            }
            if gt(x, 0xffff) {
                x := shr(16, x)
                msb := add(msb, 16)
            }
            if gt(x, 0xff) {
                x := shr(8, x)
                msb := add(msb, 8)
            }
            if gt(x, 0xf) {
                x := shr(4, x)
                msb := add(msb, 4)
            }
            if gt(x, 0x3) {
                x := shr(2, x)
                msb := add(msb, 2)
            }
            if gt(x, 0x1) { msb := add(msb, 1) }
        }
    }

    /**
     * @dev Returns the index of the least significant bit of x
     * This function returns 255 if x is 0
     * @param x The value as a uint256
     * @return lsb The index of the least significant bit of x
     */
    function leastSignificantBit(uint256 x) internal pure returns (uint8 lsb) {
        assembly {
            let sx := shl(128, x)
            if iszero(iszero(sx)) {
                lsb := 128
                x := sx
            }
            sx := shl(64, x)
            if iszero(iszero(sx)) {
                x := sx
                lsb := add(lsb, 64)
            }
            sx := shl(32, x)
            if iszero(iszero(sx)) {
                x := sx
                lsb := add(lsb, 32)
            }
            sx := shl(16, x)
            if iszero(iszero(sx)) {
                x := sx
                lsb := add(lsb, 16)
            }
            sx := shl(8, x)
            if iszero(iszero(sx)) {
                x := sx
                lsb := add(lsb, 8)
            }
            sx := shl(4, x)
            if iszero(iszero(sx)) {
                x := sx
                lsb := add(lsb, 4)
            }
            sx := shl(2, x)
            if iszero(iszero(sx)) {
                x := sx
                lsb := add(lsb, 2)
            }
            if iszero(iszero(shl(1, x))) { lsb := add(lsb, 1) }

            lsb := sub(255, lsb)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {Constants} from "../Constants.sol";
import {BitMath} from "./BitMath.sol";

/**
 * @title Liquidity Book Uint128x128 Math Library
 * @author Trader Joe
 * @notice Helper contract used for power and log calculations
 */
library Uint128x128Math {
    using BitMath for uint256;

    error Uint128x128Math__LogUnderflow();
    error Uint128x128Math__PowUnderflow(uint256 x, int256 y);

    uint256 constant LOG_SCALE_OFFSET = 127;
    uint256 constant LOG_SCALE = 1 << LOG_SCALE_OFFSET;
    uint256 constant LOG_SCALE_SQUARED = LOG_SCALE * LOG_SCALE;

    /**
     * @notice Calculates the binary logarithm of x.
     * @dev Based on the iterative approximation algorithm.
     * https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
     * Requirements:
     * - x must be greater than zero.
     * Caveats:
     * - The results are not perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation
     * Also because x is converted to an unsigned 129.127-binary fixed-point number during the operation to optimize the multiplication
     * @param x The unsigned 128.128-binary fixed-point number for which to calculate the binary logarithm.
     * @return result The binary logarithm as a signed 128.128-binary fixed-point number.
     */
    function log2(uint256 x) internal pure returns (int256 result) {
        // Convert x to a unsigned 129.127-binary fixed-point number to optimize the multiplication.
        // If we use an offset of 128 bits, y would need 129 bits and y**2 would would overflow and we would have to
        // use mulDiv, by reducing x to 129.127-binary fixed-point number we assert that y will use 128 bits, and we
        // can use the regular multiplication

        if (x == 1) return -128;
        if (x == 0) revert Uint128x128Math__LogUnderflow();

        x >>= 1;

        unchecked {
            // This works because log2(x) = -log2(1/x).
            int256 sign;
            if (x >= LOG_SCALE) {
                sign = 1;
            } else {
                sign = -1;
                // Do the fixed-point inversion inline to save gas
                x = LOG_SCALE_SQUARED / x;
            }

            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = (x >> LOG_SCALE_OFFSET).mostSignificantBit();

            // The integer part of the logarithm as a signed 129.127-binary fixed-point number. The operation can't overflow
            // because n is maximum 255, LOG_SCALE_OFFSET is 127 bits and sign is either 1 or -1.
            result = int256(n) << LOG_SCALE_OFFSET;

            // This is y = x * 2^(-n).
            uint256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y != LOG_SCALE) {
                // Calculate the fractional part via the iterative approximation.
                // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
                for (int256 delta = int256(1 << (LOG_SCALE_OFFSET - 1)); delta > 0; delta >>= 1) {
                    y = (y * y) >> LOG_SCALE_OFFSET;

                    // Is y^2 > 2 and so in the range [2,4)?
                    if (y >= 1 << (LOG_SCALE_OFFSET + 1)) {
                        // Add the 2^(-m) factor to the logarithm.
                        result += delta;

                        // Corresponds to z/2 on Wikipedia.
                        y >>= 1;
                    }
                }
            }
            // Convert x back to unsigned 128.128-binary fixed-point number
            result = (result * sign) << 1;
        }
    }

    /**
     * @notice Returns the value of x^y. It calculates `1 / x^abs(y)` if x is bigger than 2^128.
     * At the end of the operations, we invert the result if needed.
     * @param x The unsigned 128.128-binary fixed-point number for which to calculate the power
     * @param y A relative number without any decimals, needs to be between ]-2^21; 2^21[
     */
    function pow(uint256 x, int256 y) internal pure returns (uint256 result) {
        bool invert;
        uint256 absY;

        if (y == 0) return Constants.SCALE;

        assembly {
            absY := y
            if slt(absY, 0) {
                absY := sub(0, absY)
                invert := iszero(invert)
            }
        }

        if (absY < 0x100000) {
            result = Constants.SCALE;
            assembly {
                let squared := x
                if gt(x, 0xffffffffffffffffffffffffffffffff) {
                    squared := div(not(0), squared)
                    invert := iszero(invert)
                }

                if and(absY, 0x1) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x2) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x4) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x8) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x10) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x20) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x40) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x80) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x100) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x200) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x400) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x800) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x1000) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x2000) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x4000) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x8000) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x10000) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x20000) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x40000) { result := shr(128, mul(result, squared)) }
                squared := shr(128, mul(squared, squared))
                if and(absY, 0x80000) { result := shr(128, mul(result, squared)) }
            }
        }

        // revert if y is too big or if x^y underflowed
        if (result == 0) revert Uint128x128Math__PowUnderflow(x, y);

        return invert ? type(uint256).max / result : result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @title Liquidity Book Constants Library
 * @author Trader Joe
 * @notice Set of constants for Liquidity Book contracts
 */
library Constants {
    uint8 internal constant SCALE_OFFSET = 128;
    uint256 internal constant SCALE = 1 << SCALE_OFFSET;

    uint256 internal constant PRECISION = 1e18;
    uint256 internal constant SQUARED_PRECISION = PRECISION * PRECISION;

    uint256 internal constant MAX_FEE = 0.1e18; // 10%
    uint256 internal constant MAX_PROTOCOL_SHARE = 2_500; // 25% of the fee

    uint256 internal constant BASIS_POINT_MAX = 10_000;

    /// @dev The expected return after a successful flash loan
    bytes32 internal constant CALLBACK_SUCCESS = keccak256("LBPair.onFlashLoan");
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";
import {IERC1363} from "../../../interfaces/IERC1363.sol";
import {Address} from "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC-20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev An operation with an ERC-20 token failed.
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
     * @dev Performs an {ERC1363} transferAndCall, with a fallback to the simple {ERC20} transfer if the target has no
     * code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * Reverts if the returned value is other than `true`.
     */
    function transferAndCallRelaxed(IERC1363 token, address to, uint256 value, bytes memory data) internal {
        if (to.code.length == 0) {
            safeTransfer(token, to, value);
        } else if (!token.transferAndCall(to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Performs an {ERC1363} transferFromAndCall, with a fallback to the simple {ERC20} transferFrom if the target
     * has no code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * Reverts if the returned value is other than `true`.
     */
    function transferFromAndCallRelaxed(
        IERC1363 token,
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) internal {
        if (to.code.length == 0) {
            safeTransferFrom(token, from, to, value);
        } else if (!token.transferFromAndCall(from, to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Performs an {ERC1363} approveAndCall, with a fallback to the simple {ERC20} approve if the target has no
     * code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * NOTE: When the recipient address (`to`) has no code (i.e. is an EOA), this function behaves as {forceApprove}.
     * Opposedly, when the recipient address (`to`) has code, this function only attempts to call {ERC1363-approveAndCall}
     * once without retrying, and relies on the returned value to be true.
     *
     * Reverts if the returned value is other than `true`.
     */
    function approveAndCallRelaxed(IERC1363 token, address to, uint256 value, bytes memory data) internal {
        if (to.code.length == 0) {
            forceApprove(token, to, value);
        } else if (!token.approveAndCall(to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
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

pragma solidity ^0.8.10;

import {Constants} from "../Constants.sol";

/**
 * @title Liquidity Book Packed Uint128 Math Library
 * @author Trader Joe
 * @notice This library contains functions to encode and decode two uint128 into a single bytes32
 * and interact with the encoded bytes32.
 */
library PackedUint128Math {
    error PackedUint128Math__AddOverflow();
    error PackedUint128Math__SubUnderflow();
    error PackedUint128Math__MultiplierTooLarge();

    uint256 private constant OFFSET = 128;
    uint256 private constant MASK_128 = 0xffffffffffffffffffffffffffffffff;
    uint256 private constant MASK_128_PLUS_ONE = MASK_128 + 1;

    /**
     * @dev Encodes two uint128 into a single bytes32
     * @param x1 The first uint128
     * @param x2 The second uint128
     * @return z The encoded bytes32 as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     */
    function encode(uint128 x1, uint128 x2) internal pure returns (bytes32 z) {
        assembly {
            z := or(and(x1, MASK_128), shl(OFFSET, x2))
        }
    }

    /**
     * @dev Encodes a uint128 into a single bytes32 as the first uint128
     * @param x1 The uint128
     * @return z The encoded bytes32 as follows:
     * [0 - 128[: x1
     * [128 - 256[: empty
     */
    function encodeFirst(uint128 x1) internal pure returns (bytes32 z) {
        assembly {
            z := and(x1, MASK_128)
        }
    }

    /**
     * @dev Encodes a uint128 into a single bytes32 as the second uint128
     * @param x2 The uint128
     * @return z The encoded bytes32 as follows:
     * [0 - 128[: empty
     * [128 - 256[: x2
     */
    function encodeSecond(uint128 x2) internal pure returns (bytes32 z) {
        assembly {
            z := shl(OFFSET, x2)
        }
    }

    /**
     * @dev Encodes a uint128 into a single bytes32 as the first or second uint128
     * @param x The uint128
     * @param first Whether to encode as the first or second uint128
     * @return z The encoded bytes32 as follows:
     * if first:
     * [0 - 128[: x
     * [128 - 256[: empty
     * else:
     * [0 - 128[: empty
     * [128 - 256[: x
     */
    function encode(uint128 x, bool first) internal pure returns (bytes32 z) {
        return first ? encodeFirst(x) : encodeSecond(x);
    }

    /**
     * @dev Decodes a bytes32 into two uint128
     * @param z The encoded bytes32 as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @return x1 The first uint128
     * @return x2 The second uint128
     */
    function decode(bytes32 z) internal pure returns (uint128 x1, uint128 x2) {
        assembly {
            x1 := and(z, MASK_128)
            x2 := shr(OFFSET, z)
        }
    }

    /**
     * @dev Decodes a bytes32 into a uint128 as the first uint128
     * @param z The encoded bytes32 as follows:
     * [0 - 128[: x
     * [128 - 256[: any
     * @return x The first uint128
     */
    function decodeX(bytes32 z) internal pure returns (uint128 x) {
        assembly {
            x := and(z, MASK_128)
        }
    }

    /**
     * @dev Decodes a bytes32 into a uint128 as the second uint128
     * @param z The encoded bytes32 as follows:
     * [0 - 128[: any
     * [128 - 256[: y
     * @return y The second uint128
     */
    function decodeY(bytes32 z) internal pure returns (uint128 y) {
        assembly {
            y := shr(OFFSET, z)
        }
    }

    /**
     * @dev Decodes a bytes32 into a uint128 as the first or second uint128
     * @param z The encoded bytes32 as follows:
     * if first:
     * [0 - 128[: x1
     * [128 - 256[: empty
     * else:
     * [0 - 128[: empty
     * [128 - 256[: x2
     * @param first Whether to decode as the first or second uint128
     * @return x The decoded uint128
     */
    function decode(bytes32 z, bool first) internal pure returns (uint128 x) {
        return first ? decodeX(z) : decodeY(z);
    }

    /**
     * @dev Adds two encoded bytes32, reverting on overflow on any of the uint128
     * @param x The first bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param y The second bytes32 encoded as follows:
     * [0 - 128[: y1
     * [128 - 256[: y2
     * @return z The sum of x and y encoded as follows:
     * [0 - 128[: x1 + y1
     * [128 - 256[: x2 + y2
     */
    function add(bytes32 x, bytes32 y) internal pure returns (bytes32 z) {
        assembly {
            z := add(x, y)
        }

        if (z < x || uint128(uint256(z)) < uint128(uint256(x))) {
            revert PackedUint128Math__AddOverflow();
        }
    }

    /**
     * @dev Adds an encoded bytes32 and two uint128, reverting on overflow on any of the uint128
     * @param x The bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param y1 The first uint128
     * @param y2 The second uint128
     * @return z The sum of x and y encoded as follows:
     * [0 - 128[: x1 + y1
     * [128 - 256[: x2 + y2
     */
    function add(bytes32 x, uint128 y1, uint128 y2) internal pure returns (bytes32) {
        return add(x, encode(y1, y2));
    }

    /**
     * @dev Subtracts two encoded bytes32, reverting on underflow on any of the uint128
     * @param x The first bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param y The second bytes32 encoded as follows:
     * [0 - 128[: y1
     * [128 - 256[: y2
     * @return z The difference of x and y encoded as follows:
     * [0 - 128[: x1 - y1
     * [128 - 256[: x2 - y2
     */
    function sub(bytes32 x, bytes32 y) internal pure returns (bytes32 z) {
        assembly {
            z := sub(x, y)
        }

        if (z > x || uint128(uint256(z)) > uint128(uint256(x))) {
            revert PackedUint128Math__SubUnderflow();
        }
    }

    /**
     * @dev Subtracts an encoded bytes32 and two uint128, reverting on underflow on any of the uint128
     * @param x The bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param y1 The first uint128
     * @param y2 The second uint128
     * @return z The difference of x and y encoded as follows:
     * [0 - 128[: x1 - y1
     * [128 - 256[: x2 - y2
     */
    function sub(bytes32 x, uint128 y1, uint128 y2) internal pure returns (bytes32) {
        return sub(x, encode(y1, y2));
    }

    /**
     * @dev Returns whether any of the uint128 of x is strictly greater than the corresponding uint128 of y
     * @param x The first bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param y The second bytes32 encoded as follows:
     * [0 - 128[: y1
     * [128 - 256[: y2
     * @return x1 < y1 || x2 < y2
     */
    function lt(bytes32 x, bytes32 y) internal pure returns (bool) {
        (uint128 x1, uint128 x2) = decode(x);
        (uint128 y1, uint128 y2) = decode(y);

        return x1 < y1 || x2 < y2;
    }

    /**
     * @dev Returns whether any of the uint128 of x is strictly greater than the corresponding uint128 of y
     * @param x The first bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param y The second bytes32 encoded as follows:
     * [0 - 128[: y1
     * [128 - 256[: y2
     * @return x1 < y1 || x2 < y2
     */
    function gt(bytes32 x, bytes32 y) internal pure returns (bool) {
        (uint128 x1, uint128 x2) = decode(x);
        (uint128 y1, uint128 y2) = decode(y);

        return x1 > y1 || x2 > y2;
    }

    /**
     * @dev Multiplies an encoded bytes32 by a uint128 then divides the result by 10_000, rounding down
     * The result can't overflow as the multiplier needs to be smaller or equal to 10_000
     * @param x The bytes32 encoded as follows:
     * [0 - 128[: x1
     * [128 - 256[: x2
     * @param multiplier The uint128 to multiply by (must be smaller or equal to 10_000)
     * @return z The product of x and multiplier encoded as follows:
     * [0 - 128[: floor((x1 * multiplier) / 10_000)
     * [128 - 256[: floor((x2 * multiplier) / 10_000)
     */
    function scalarMulDivBasisPointRoundDown(bytes32 x, uint128 multiplier) internal pure returns (bytes32 z) {
        if (multiplier == 0) return 0;

        uint256 BASIS_POINT_MAX = Constants.BASIS_POINT_MAX;
        if (multiplier > BASIS_POINT_MAX) revert PackedUint128Math__MultiplierTooLarge();

        (uint128 x1, uint128 x2) = decode(x);

        assembly {
            x1 := div(mul(x1, multiplier), BASIS_POINT_MAX)
            x2 := div(mul(x2, multiplier), BASIS_POINT_MAX)
        }

        return encode(x1, x2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {Constants} from "./Constants.sol";
import {SafeCast} from "./math/SafeCast.sol";
import {Encoded} from "./math/Encoded.sol";

/**
 * @title Liquidity Book Pair Parameter Helper Library
 * @author Trader Joe
 * @dev This library contains functions to get and set parameters of a pair
 * The parameters are stored in a single bytes32 variable in the following format:
 * [0 - 16[: base factor (16 bits)
 * [16 - 28[: filter period (12 bits)
 * [28 - 40[: decay period (12 bits)
 * [40 - 54[: reduction factor (14 bits)
 * [54 - 78[: variable fee control (24 bits)
 * [78 - 92[: protocol share (14 bits)
 * [92 - 112[: max volatility accumulator (20 bits)
 * [112 - 132[: volatility accumulator (20 bits)
 * [132 - 152[: volatility reference (20 bits)
 * [152 - 176[: index reference (24 bits)
 * [176 - 216[: time of last update (40 bits)
 * [216 - 232[: oracle index (16 bits)
 * [232 - 256[: active index (24 bits)
 */
library PairParameterHelper {
    using SafeCast for uint256;
    using Encoded for bytes32;

    error PairParametersHelper__InvalidParameter();

    uint256 internal constant OFFSET_BASE_FACTOR = 0;
    uint256 internal constant OFFSET_FILTER_PERIOD = 16;
    uint256 internal constant OFFSET_DECAY_PERIOD = 28;
    uint256 internal constant OFFSET_REDUCTION_FACTOR = 40;
    uint256 internal constant OFFSET_VAR_FEE_CONTROL = 54;
    uint256 internal constant OFFSET_PROTOCOL_SHARE = 78;
    uint256 internal constant OFFSET_MAX_VOL_ACC = 92;
    uint256 internal constant OFFSET_VOL_ACC = 112;
    uint256 internal constant OFFSET_VOL_REF = 132;
    uint256 internal constant OFFSET_ID_REF = 152;
    uint256 internal constant OFFSET_TIME_LAST_UPDATE = 176;
    uint256 internal constant OFFSET_ORACLE_ID = 216;
    uint256 internal constant OFFSET_ACTIVE_ID = 232;

    uint256 internal constant MASK_STATIC_PARAMETER = 0xffffffffffffffffffffffffffff;

    /**
     * @dev Get the base factor from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 16[: base factor (16 bits)
     * [16 - 256[: other parameters
     * @return baseFactor The base factor
     */
    function getBaseFactor(bytes32 params) internal pure returns (uint16 baseFactor) {
        baseFactor = params.decodeUint16(OFFSET_BASE_FACTOR);
    }

    /**
     * @dev Get the filter period from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 16[: other parameters
     * [16 - 28[: filter period (12 bits)
     * [28 - 256[: other parameters
     * @return filterPeriod The filter period
     */
    function getFilterPeriod(bytes32 params) internal pure returns (uint16 filterPeriod) {
        filterPeriod = params.decodeUint12(OFFSET_FILTER_PERIOD);
    }

    /**
     * @dev Get the decay period from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 28[: other parameters
     * [28 - 40[: decay period (12 bits)
     * [40 - 256[: other parameters
     * @return decayPeriod The decay period
     */
    function getDecayPeriod(bytes32 params) internal pure returns (uint16 decayPeriod) {
        decayPeriod = params.decodeUint12(OFFSET_DECAY_PERIOD);
    }

    /**
     * @dev Get the reduction factor from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 40[: other parameters
     * [40 - 54[: reduction factor (14 bits)
     * [54 - 256[: other parameters
     * @return reductionFactor The reduction factor
     */
    function getReductionFactor(bytes32 params) internal pure returns (uint16 reductionFactor) {
        reductionFactor = params.decodeUint14(OFFSET_REDUCTION_FACTOR);
    }

    /**
     * @dev Get the variable fee control from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 54[: other parameters
     * [54 - 78[: variable fee control (24 bits)
     * [78 - 256[: other parameters
     * @return variableFeeControl The variable fee control
     */
    function getVariableFeeControl(bytes32 params) internal pure returns (uint24 variableFeeControl) {
        variableFeeControl = params.decodeUint24(OFFSET_VAR_FEE_CONTROL);
    }

    /**
     * @dev Get the protocol share from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 78[: other parameters
     * [78 - 92[: protocol share (14 bits)
     * [92 - 256[: other parameters
     * @return protocolShare The protocol share
     */
    function getProtocolShare(bytes32 params) internal pure returns (uint16 protocolShare) {
        protocolShare = params.decodeUint14(OFFSET_PROTOCOL_SHARE);
    }

    /**
     * @dev Get the max volatility accumulator from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 92[: other parameters
     * [92 - 112[: max volatility accumulator (20 bits)
     * [112 - 256[: other parameters
     * @return maxVolatilityAccumulator The max volatility accumulator
     */
    function getMaxVolatilityAccumulator(bytes32 params) internal pure returns (uint24 maxVolatilityAccumulator) {
        maxVolatilityAccumulator = params.decodeUint20(OFFSET_MAX_VOL_ACC);
    }

    /**
     * @dev Get the volatility accumulator from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 112[: other parameters
     * [112 - 132[: volatility accumulator (20 bits)
     * [132 - 256[: other parameters
     * @return volatilityAccumulator The volatility accumulator
     */
    function getVolatilityAccumulator(bytes32 params) internal pure returns (uint24 volatilityAccumulator) {
        volatilityAccumulator = params.decodeUint20(OFFSET_VOL_ACC);
    }

    /**
     * @dev Get the volatility reference from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 132[: other parameters
     * [132 - 152[: volatility reference (20 bits)
     * [152 - 256[: other parameters
     * @return volatilityReference The volatility reference
     */
    function getVolatilityReference(bytes32 params) internal pure returns (uint24 volatilityReference) {
        volatilityReference = params.decodeUint20(OFFSET_VOL_REF);
    }

    /**
     * @dev Get the index reference from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 152[: other parameters
     * [152 - 176[: index reference (24 bits)
     * [176 - 256[: other parameters
     * @return idReference The index reference
     */
    function getIdReference(bytes32 params) internal pure returns (uint24 idReference) {
        idReference = params.decodeUint24(OFFSET_ID_REF);
    }

    /**
     * @dev Get the time of last update from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 176[: other parameters
     * [176 - 216[: time of last update (40 bits)
     * [216 - 256[: other parameters
     * @return timeOflastUpdate The time of last update
     */
    function getTimeOfLastUpdate(bytes32 params) internal pure returns (uint40 timeOflastUpdate) {
        timeOflastUpdate = params.decodeUint40(OFFSET_TIME_LAST_UPDATE);
    }

    /**
     * @dev Get the oracle id from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 216[: other parameters
     * [216 - 232[: oracle id (16 bits)
     * [232 - 256[: other parameters
     * @return oracleId The oracle id
     */
    function getOracleId(bytes32 params) internal pure returns (uint16 oracleId) {
        oracleId = params.decodeUint16(OFFSET_ORACLE_ID);
    }

    /**
     * @dev Get the active index from the encoded pair parameters
     * @param params The encoded pair parameters, as follows:
     * [0 - 232[: other parameters
     * [232 - 256[: active index (24 bits)
     * @return activeId The active index
     */
    function getActiveId(bytes32 params) internal pure returns (uint24 activeId) {
        activeId = params.decodeUint24(OFFSET_ACTIVE_ID);
    }

    /**
     * @dev Get the delta between the current active index and the cached active index
     * @param params The encoded pair parameters, as follows:
     * [0 - 232[: other parameters
     * [232 - 256[: active index (24 bits)
     * @param activeId The current active index
     * @return The delta
     */
    function getDeltaId(bytes32 params, uint24 activeId) internal pure returns (uint24) {
        uint24 id = getActiveId(params);
        unchecked {
            return activeId > id ? activeId - id : id - activeId;
        }
    }

    /**
     * @dev Calculates the base fee, with 18 decimals
     * @param params The encoded pair parameters
     * @param binStep The bin step (in basis points)
     * @return baseFee The base fee
     */
    function getBaseFee(bytes32 params, uint16 binStep) internal pure returns (uint256) {
        unchecked {
            // Base factor is in basis points, binStep is in basis points, so we multiply by 1e10
            return uint256(getBaseFactor(params)) * binStep * 1e10;
        }
    }

    /**
     * @dev Calculates the variable fee
     * @param params The encoded pair parameters
     * @param binStep The bin step (in basis points)
     * @return variableFee The variable fee
     */
    function getVariableFee(bytes32 params, uint16 binStep) internal pure returns (uint256 variableFee) {
        uint256 variableFeeControl = getVariableFeeControl(params);

        if (variableFeeControl != 0) {
            unchecked {
                // The volatility accumulator is in basis points, binStep is in basis points,
                // and the variable fee control is in basis points, so the result is in 100e18th
                uint256 prod = uint256(getVolatilityAccumulator(params)) * binStep;
                variableFee = (prod * prod * variableFeeControl + 99) / 100;
            }
        }
    }

    /**
     * @dev Calculates the total fee, which is the sum of the base fee and the variable fee
     * @param params The encoded pair parameters
     * @param binStep The bin step (in basis points)
     * @return totalFee The total fee
     */
    function getTotalFee(bytes32 params, uint16 binStep) internal pure returns (uint128) {
        unchecked {
            return (getBaseFee(params, binStep) + getVariableFee(params, binStep)).safe128();
        }
    }

    /**
     * @dev Set the oracle id in the encoded pair parameters
     * @param params The encoded pair parameters
     * @param oracleId The oracle id
     * @return The updated encoded pair parameters
     */
    function setOracleId(bytes32 params, uint16 oracleId) internal pure returns (bytes32) {
        return params.set(oracleId, Encoded.MASK_UINT16, OFFSET_ORACLE_ID);
    }

    /**
     * @dev Set the volatility reference in the encoded pair parameters
     * @param params The encoded pair parameters
     * @param volRef The volatility reference
     * @return The updated encoded pair parameters
     */
    function setVolatilityReference(bytes32 params, uint24 volRef) internal pure returns (bytes32) {
        if (volRef > Encoded.MASK_UINT20) revert PairParametersHelper__InvalidParameter();

        return params.set(volRef, Encoded.MASK_UINT20, OFFSET_VOL_REF);
    }

    /**
     * @dev Set the volatility accumulator in the encoded pair parameters
     * @param params The encoded pair parameters
     * @param volAcc The volatility accumulator
     * @return The updated encoded pair parameters
     */
    function setVolatilityAccumulator(bytes32 params, uint24 volAcc) internal pure returns (bytes32) {
        if (volAcc > Encoded.MASK_UINT20) revert PairParametersHelper__InvalidParameter();

        return params.set(volAcc, Encoded.MASK_UINT20, OFFSET_VOL_ACC);
    }

    /**
     * @dev Set the active id in the encoded pair parameters
     * @param params The encoded pair parameters
     * @param activeId The active id
     * @return newParams The updated encoded pair parameters
     */
    function setActiveId(bytes32 params, uint24 activeId) internal pure returns (bytes32 newParams) {
        return params.set(activeId, Encoded.MASK_UINT24, OFFSET_ACTIVE_ID);
    }

    /**
     * @dev Sets the static fee parameters in the encoded pair parameters
     * @param params The encoded pair parameters
     * @param baseFactor The base factor
     * @param filterPeriod The filter period
     * @param decayPeriod The decay period
     * @param reductionFactor The reduction factor
     * @param variableFeeControl The variable fee control
     * @param protocolShare The protocol share
     * @param maxVolatilityAccumulator The max volatility accumulator
     * @return newParams The updated encoded pair parameters
     */
    function setStaticFeeParameters(
        bytes32 params,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    ) internal pure returns (bytes32 newParams) {
        if (
            filterPeriod > decayPeriod || decayPeriod > Encoded.MASK_UINT12
                || reductionFactor > Constants.BASIS_POINT_MAX || protocolShare > Constants.MAX_PROTOCOL_SHARE
                || maxVolatilityAccumulator > Encoded.MASK_UINT20
        ) revert PairParametersHelper__InvalidParameter();

        newParams = newParams.set(baseFactor, Encoded.MASK_UINT16, OFFSET_BASE_FACTOR);
        newParams = newParams.set(filterPeriod, Encoded.MASK_UINT12, OFFSET_FILTER_PERIOD);
        newParams = newParams.set(decayPeriod, Encoded.MASK_UINT12, OFFSET_DECAY_PERIOD);
        newParams = newParams.set(reductionFactor, Encoded.MASK_UINT14, OFFSET_REDUCTION_FACTOR);
        newParams = newParams.set(variableFeeControl, Encoded.MASK_UINT24, OFFSET_VAR_FEE_CONTROL);
        newParams = newParams.set(protocolShare, Encoded.MASK_UINT14, OFFSET_PROTOCOL_SHARE);
        newParams = newParams.set(maxVolatilityAccumulator, Encoded.MASK_UINT20, OFFSET_MAX_VOL_ACC);

        return params.set(uint256(newParams), MASK_STATIC_PARAMETER, 0);
    }

    /**
     * @dev Updates the index reference in the encoded pair parameters
     * @param params The encoded pair parameters
     * @return newParams The updated encoded pair parameters
     */
    function updateIdReference(bytes32 params) internal pure returns (bytes32 newParams) {
        uint24 activeId = getActiveId(params);
        return params.set(activeId, Encoded.MASK_UINT24, OFFSET_ID_REF);
    }

    /**
     * @dev Updates the time of last update in the encoded pair parameters
     * @param params The encoded pair parameters
     * @param timestamp The timestamp
     * @return newParams The updated encoded pair parameters
     */
    function updateTimeOfLastUpdate(bytes32 params, uint256 timestamp) internal pure returns (bytes32 newParams) {
        uint40 currentTime = timestamp.safe40();
        return params.set(currentTime, Encoded.MASK_UINT40, OFFSET_TIME_LAST_UPDATE);
    }

    /**
     * @dev Updates the volatility reference in the encoded pair parameters
     * @param params The encoded pair parameters
     * @return The updated encoded pair parameters
     */
    function updateVolatilityReference(bytes32 params) internal pure returns (bytes32) {
        uint256 volAcc = getVolatilityAccumulator(params);
        uint256 reductionFactor = getReductionFactor(params);

        uint24 volRef;
        unchecked {
            volRef = uint24(volAcc * reductionFactor / Constants.BASIS_POINT_MAX);
        }

        return setVolatilityReference(params, volRef);
    }

    /**
     * @dev Updates the volatility accumulator in the encoded pair parameters
     * @param params The encoded pair parameters
     * @param activeId The active id
     * @return The updated encoded pair parameters
     */
    function updateVolatilityAccumulator(bytes32 params, uint24 activeId) internal pure returns (bytes32) {
        uint256 idReference = getIdReference(params);

        uint256 deltaId;
        uint256 volAcc;

        unchecked {
            deltaId = activeId > idReference ? activeId - idReference : idReference - activeId;
            volAcc = (uint256(getVolatilityReference(params)) + deltaId * Constants.BASIS_POINT_MAX);
        }

        uint256 maxVolAcc = getMaxVolatilityAccumulator(params);

        volAcc = volAcc > maxVolAcc ? maxVolAcc : volAcc;

        return setVolatilityAccumulator(params, uint24(volAcc));
    }

    /**
     * @dev Updates the volatility reference and the volatility accumulator in the encoded pair parameters
     * @param params The encoded pair parameters
     * @param timestamp The timestamp
     * @return The updated encoded pair parameters
     */
    function updateReferences(bytes32 params, uint256 timestamp) internal pure returns (bytes32) {
        uint256 dt = timestamp - getTimeOfLastUpdate(params);

        if (dt >= getFilterPeriod(params)) {
            params = updateIdReference(params);
            params = dt < getDecayPeriod(params) ? updateVolatilityReference(params) : setVolatilityReference(params, 0);
        }

        return updateTimeOfLastUpdate(params, timestamp);
    }

    /**
     * @dev Updates the volatility reference and the volatility accumulator in the encoded pair parameters
     * @param params The encoded pair parameters
     * @param activeId The active id
     * @param timestamp The timestamp
     * @return The updated encoded pair parameters
     */
    function updateVolatilityParameters(bytes32 params, uint24 activeId, uint256 timestamp)
        internal
        pure
        returns (bytes32)
    {
        params = updateReferences(params, timestamp);
        return updateVolatilityAccumulator(params, activeId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {Constants} from "./Constants.sol";

/**
 * @title Liquidity Book Fee Helper Library
 * @author Trader Joe
 * @notice This library contains functions to calculate fees
 */
library FeeHelper {
    error FeeHelper__FeeTooLarge();
    error FeeHelper__ProtocolShareTooLarge();

    /**
     * @dev Modifier to check that the fee is not too large
     * @param fee The fee
     */
    modifier verifyFee(uint128 fee) {
        if (fee > Constants.MAX_FEE) revert FeeHelper__FeeTooLarge();
        _;
    }

    /**
     * @dev Modifier to check that the protocol share is not too large
     * @param protocolShare The protocol share
     */
    modifier verifyProtocolShare(uint128 protocolShare) {
        if (protocolShare > Constants.MAX_PROTOCOL_SHARE) revert FeeHelper__ProtocolShareTooLarge();
        _;
    }

    /**
     * @dev Calculates the fee amount from the amount with fees, rounding up
     * @param amountWithFees The amount with fees
     * @param totalFee The total fee
     * @return feeAmount The fee amount
     */
    function getFeeAmountFrom(uint128 amountWithFees, uint128 totalFee)
        internal
        pure
        verifyFee(totalFee)
        returns (uint128)
    {
        unchecked {
            // Can't overflow, max(result) = (type(uint128).max * 0.1e18 + 1e18 - 1) / 1e18 < 2^128
            return uint128((uint256(amountWithFees) * totalFee + Constants.PRECISION - 1) / Constants.PRECISION);
        }
    }

    /**
     * @dev Calculates the fee amount that will be charged, rounding up
     * @param amount The amount
     * @param totalFee The total fee
     * @return feeAmount The fee amount
     */
    function getFeeAmount(uint128 amount, uint128 totalFee) internal pure verifyFee(totalFee) returns (uint128) {
        unchecked {
            uint256 denominator = Constants.PRECISION - totalFee;
            // Can't overflow, max(result) = (type(uint128).max * 0.1e18 + (1e18 - 1)) / 0.9e18 < 2^128
            return uint128((uint256(amount) * totalFee + denominator - 1) / denominator);
        }
    }

    /**
     * @dev Calculates the composition fee amount from the amount with fees, rounding down
     * @param amountWithFees The amount with fees
     * @param totalFee The total fee
     * @return The amount with fees
     */
    function getCompositionFee(uint128 amountWithFees, uint128 totalFee)
        internal
        pure
        verifyFee(totalFee)
        returns (uint128)
    {
        unchecked {
            uint256 denominator = Constants.SQUARED_PRECISION;
            // Can't overflow, max(result) = type(uint128).max * 0.1e18 * 1.1e18 / 1e36 <= 2^128 * 0.11e36 / 1e36 < 2^128
            return uint128(uint256(amountWithFees) * totalFee * (uint256(totalFee) + Constants.PRECISION) / denominator);
        }
    }

    /**
     * @dev Calculates the protocol fee amount from the fee amount and the protocol share, rounding down
     * @param feeAmount The fee amount
     * @param protocolShare The protocol share
     * @return protocolFeeAmount The protocol fee amount
     */
    function getProtocolFeeAmount(uint128 feeAmount, uint128 protocolShare)
        internal
        pure
        verifyProtocolShare(protocolShare)
        returns (uint128)
    {
        unchecked {
            return uint128(uint256(feeAmount) * protocolShare / Constants.BASIS_POINT_MAX);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC1363.sol)

pragma solidity ^0.8.20;

import {IERC20} from "./IERC20.sol";
import {IERC165} from "./IERC165.sol";

/**
 * @title IERC1363
 * @dev Interface of the ERC-1363 standard as defined in the https://eips.ethereum.org/EIPS/eip-1363[ERC-1363].
 *
 * Defines an extension interface for ERC-20 tokens that supports executing code on a recipient contract
 * after `transfer` or `transferFrom`, or code on a spender contract after `approve`, in a single transaction.
 */
interface IERC1363 is IERC20, IERC165 {
    /*
     * Note: the ERC-165 identifier for this interface is 0xb0202a11.
     * 0xb0202a11 ===
     *   bytes4(keccak256('transferAndCall(address,uint256)')) ^
     *   bytes4(keccak256('transferAndCall(address,uint256,bytes)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256,bytes)'))
     */

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferAndCall(address to, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `to`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the allowance mechanism
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferFromAndCall(address from, address to, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the allowance mechanism
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `to`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferFromAndCall(address from, address to, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens and then calls {IERC1363Spender-onApprovalReceived} on `spender`.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function approveAndCall(address spender, uint256 value) external returns (bool);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens and then calls {IERC1363Spender-onApprovalReceived} on `spender`.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @param data Additional data with no specified format, sent in call to `spender`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function approveAndCall(address spender, uint256 value, bytes calldata data) external returns (bool);
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

pragma solidity ^0.8.10;

/**
 * @title Liquidity Book Encoded Library
 * @author Trader Joe
 * @notice Helper contract used for decoding bytes32 sample
 */
library Encoded {
    uint256 internal constant MASK_UINT1 = 0x1;
    uint256 internal constant MASK_UINT8 = 0xff;
    uint256 internal constant MASK_UINT12 = 0xfff;
    uint256 internal constant MASK_UINT14 = 0x3fff;
    uint256 internal constant MASK_UINT16 = 0xffff;
    uint256 internal constant MASK_UINT20 = 0xfffff;
    uint256 internal constant MASK_UINT24 = 0xffffff;
    uint256 internal constant MASK_UINT40 = 0xffffffffff;
    uint256 internal constant MASK_UINT64 = 0xffffffffffffffff;
    uint256 internal constant MASK_UINT128 = 0xffffffffffffffffffffffffffffffff;

    /**
     * @notice Internal function to set a value in an encoded bytes32 using a mask and offset
     * @dev This function can overflow
     * @param encoded The previous encoded value
     * @param value The value to encode
     * @param mask The mask
     * @param offset The offset
     * @return newEncoded The new encoded value
     */
    function set(bytes32 encoded, uint256 value, uint256 mask, uint256 offset)
        internal
        pure
        returns (bytes32 newEncoded)
    {
        assembly {
            newEncoded := and(encoded, not(shl(offset, mask)))
            newEncoded := or(newEncoded, shl(offset, and(value, mask)))
        }
    }

    /**
     * @notice Internal function to set a bool in an encoded bytes32 using an offset
     * @dev This function can overflow
     * @param encoded The previous encoded value
     * @param boolean The bool to encode
     * @param offset The offset
     * @return newEncoded The new encoded value
     */
    function setBool(bytes32 encoded, bool boolean, uint256 offset) internal pure returns (bytes32 newEncoded) {
        return set(encoded, boolean ? 1 : 0, MASK_UINT1, offset);
    }

    /**
     * @notice Internal function to decode a bytes32 sample using a mask and offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param mask The mask
     * @param offset The offset
     * @return value The decoded value
     */
    function decode(bytes32 encoded, uint256 mask, uint256 offset) internal pure returns (uint256 value) {
        assembly {
            value := and(shr(offset, encoded), mask)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a bool using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return boolean The decoded value as a bool
     */
    function decodeBool(bytes32 encoded, uint256 offset) internal pure returns (bool boolean) {
        assembly {
            boolean := and(shr(offset, encoded), MASK_UINT1)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint8 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value
     */
    function decodeUint8(bytes32 encoded, uint256 offset) internal pure returns (uint8 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT8)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint12 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value as a uint16, since uint12 is not supported
     */
    function decodeUint12(bytes32 encoded, uint256 offset) internal pure returns (uint16 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT12)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint14 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value as a uint16, since uint14 is not supported
     */
    function decodeUint14(bytes32 encoded, uint256 offset) internal pure returns (uint16 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT14)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint16 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value
     */
    function decodeUint16(bytes32 encoded, uint256 offset) internal pure returns (uint16 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT16)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint20 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value as a uint24, since uint20 is not supported
     */
    function decodeUint20(bytes32 encoded, uint256 offset) internal pure returns (uint24 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT20)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint24 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value
     */
    function decodeUint24(bytes32 encoded, uint256 offset) internal pure returns (uint24 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT24)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint40 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value
     */
    function decodeUint40(bytes32 encoded, uint256 offset) internal pure returns (uint40 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT40)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint64 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value
     */
    function decodeUint64(bytes32 encoded, uint256 offset) internal pure returns (uint64 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT64)
        }
    }

    /**
     * @notice Internal function to decode a bytes32 sample into a uint128 using an offset
     * @dev This function can overflow
     * @param encoded The encoded value
     * @param offset The offset
     * @return value The decoded value
     */
    function decodeUint128(bytes32 encoded, uint256 offset) internal pure returns (uint128 value) {
        assembly {
            value := and(shr(offset, encoded), MASK_UINT128)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC-165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[ERC].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}