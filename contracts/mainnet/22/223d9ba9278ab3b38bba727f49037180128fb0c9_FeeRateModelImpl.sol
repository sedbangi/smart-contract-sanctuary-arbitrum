// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import {IFeeRateImpl} from "../interfaces/IFeeRateModel.sol";
import {Math} from "/mimswap/libraries/Math.sol";

contract FeeRateModelImpl {
    // 50% of the LP fee rate
    function getFeeRate(
        address /*pool*/,
        address /*trader*/,
        uint256 lpFeeRate
    ) external pure returns (uint256 adjustedLpFeeRate, uint256 mtFeeRate) {
        mtFeeRate = Math.divCeil(lpFeeRate, 2);
        return (lpFeeRate - mtFeeRate, mtFeeRate);
    }
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity >=0.8.0;

interface IFeeRateImpl {
    function getFeeRate(
        address pool,
        address trader,
        uint256 lpFeeRate
    ) external view returns (uint256 adjustedLpFeeRate, uint256 mtFeeRate);
}

interface IFeeRateModel {
    function maintainer() external view returns (address);

    function getFeeRate(address trader, uint256 lpFeeRate) external view returns (uint256 adjustedLpFeeRate, uint256 mtFeeRate);
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity >=0.8.0;

import {DecimalMath} from "/mimswap/libraries/DecimalMath.sol";

/**
 * @author Adapted from https://github.com/DODOEX/contractV2/blob/main/contracts/lib/Math.sol
 * @notice Functions for complex calculating. Including ONE Integration and TWO Quadratic solutions
 */
library Math {
    error ErrIsZero();

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = a / b;
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    // from UniswapV2 https://github.com/Uniswap/v2-core/blob/master/contracts/libraries/Math.sol
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    /*
        Integrate dodo curve from V1 to V2
        require V0>=V1>=V2>0
        res = (1-k)i(V1-V2)+ikV0*V0(1/V2-1/V1)
        let V1-V2=delta
        res = i*delta*(1-k+k(V0^2/V1/V2))

        i is the price of V-res trading pair

        support k=1 & k=0 case

        [round down]
    */
    function _GeneralIntegrate(uint256 V0, uint256 V1, uint256 V2, uint256 i, uint256 k) internal pure returns (uint256) {
        if (V0 == 0) {
            revert ErrIsZero();
        }

        uint256 fairAmount = i * (V1 - V2); // i*delta

        if (k == 0) {
            return fairAmount / DecimalMath.ONE;
        }

        uint256 V0V0V1V2 = DecimalMath.divFloor((V0 * V0) / V1, V2);
        uint256 penalty = DecimalMath.mulFloor(k, V0V0V1V2); // k(V0^2/V1/V2)
        return (((DecimalMath.ONE - k) + penalty) * fairAmount) / DecimalMath.ONE2;
    }

    /*
        Follow the integration function above
        i*deltaB = (Q2-Q1)*(1-k+kQ0^2/Q1/Q2)
        Assume Q2=Q0, Given Q1 and deltaB, solve Q0

        i is the price of delta-V trading pair
        give out target of V

        support k=1 & k=0 case

        [round down]
    */
    function _SolveQuadraticFunctionForTarget(uint256 V1, uint256 delta, uint256 i, uint256 k) internal pure returns (uint256) {
        if (k == 0) {
            return V1 + DecimalMath.mulFloor(i, delta);
        }

        // V0 = V1*(1+(sqrt-1)/2k)
        // sqrt = √(1+4kidelta/V1)
        // premium = 1+(sqrt-1)/2k
        // uint256 sqrt = (4 * k).mul(i).mul(delta).div(V1).add(DecimalMath.ONE2).sqrt();

        if (V1 == 0) {
            return 0;
        }
        uint256 _sqrt;
        uint256 ki = (4 * k) * i;
        if (ki == 0) {
            _sqrt = DecimalMath.ONE;
        } else if ((ki * delta) / ki == delta) {
            _sqrt = sqrt(((ki * delta) / V1) + DecimalMath.ONE2);
        } else {
            _sqrt = sqrt(((ki / V1) * delta) + DecimalMath.ONE2);
        }
        uint256 premium = DecimalMath.divFloor(_sqrt - DecimalMath.ONE, k * 2) + DecimalMath.ONE;
        // V0 is greater than or equal to V1 according to the solution
        return DecimalMath.mulFloor(V1, premium);
    }

    /*
        Follow the integration expression above, we have:
        i*deltaB = (Q2-Q1)*(1-k+kQ0^2/Q1/Q2)
        Given Q1 and deltaB, solve Q2
        This is a quadratic function and the standard version is
        aQ2^2 + bQ2 + c = 0, where
        a=1-k
        -b=(1-k)Q1-kQ0^2/Q1+i*deltaB
        c=-kQ0^2 
        and Q2=(-b+sqrt(b^2+4(1-k)kQ0^2))/2(1-k)
        note: another root is negative, abondan

        if deltaBSig=true, then Q2>Q1, user sell Q and receive B
        if deltaBSig=false, then Q2<Q1, user sell B and receive Q
        return |Q1-Q2|

        as we only support sell amount as delta, the deltaB is always negative
        the input ideltaB is actually -ideltaB in the equation

        i is the price of delta-V trading pair

        support k=1 & k=0 case

        [round down]
    */
    function _SolveQuadraticFunctionForTrade(uint256 V0, uint256 V1, uint256 delta, uint256 i, uint256 k) internal pure returns (uint256) {
        if (V0 == 0) {
            revert ErrIsZero();
        }

        if (delta == 0) {
            return 0;
        }

        if (k == 0) {
            return DecimalMath.mulFloor(i, delta) > V1 ? V1 : DecimalMath.mulFloor(i, delta);
        }

        if (k == DecimalMath.ONE) {
            // if k==1
            // Q2=Q1/(1+ideltaBQ1/Q0/Q0)
            // temp = ideltaBQ1/Q0/Q0
            // Q2 = Q1/(1+temp)
            // Q1-Q2 = Q1*(1-1/(1+temp)) = Q1*(temp/(1+temp))
            // uint256 temp = i.mul(delta).mul(V1).div(V0.mul(V0));
            uint256 temp;
            uint256 idelta = i * delta;
            if (idelta == 0) {
                temp = 0;
            } else if ((idelta * V1) / idelta == V1) {
                temp = (idelta * V1) / (V0 * V0);
            } else {
                temp = (((delta * V1) / V0) * i) / V0;
            }
            return (V1 * temp) / (temp + DecimalMath.ONE);
        }

        // calculate -b value and sig
        // b = kQ0^2/Q1-i*deltaB-(1-k)Q1
        // part1 = (1-k)Q1 >=0
        // part2 = kQ0^2/Q1-i*deltaB >=0
        // bAbs = abs(part1-part2)
        // if part1>part2 => b is negative => bSig is false
        // if part2>part1 => b is positive => bSig is true
        uint256 part2 = (((k * V0) / V1) * V0) + (i * delta); // kQ0^2/Q1-i*deltaB
        uint256 bAbs = (DecimalMath.ONE - k) * V1; // (1-k)Q1

        bool bSig;
        if (bAbs >= part2) {
            bAbs = bAbs - part2;
            bSig = false;
        } else {
            bAbs = part2 - bAbs;
            bSig = true;
        }
        bAbs = bAbs / DecimalMath.ONE;

        // calculate sqrt
        uint256 squareRoot = DecimalMath.mulFloor((DecimalMath.ONE - k) * 4, DecimalMath.mulFloor(k, V0) * V0); // 4(1-k)kQ0^2
        squareRoot = sqrt((bAbs * bAbs) + squareRoot); // sqrt(b*b+4(1-k)kQ0*Q0)

        // final res
        uint256 denominator = (DecimalMath.ONE - k) * 2; // 2(1-k)
        uint256 numerator;
        if (bSig) {
            numerator = squareRoot - bAbs;
            if (numerator == 0) {
                revert ErrIsZero();
            }
        } else {
            numerator = bAbs + squareRoot;
        }

        uint256 V2 = DecimalMath.divCeil(numerator, denominator);
        if (V2 > V1) {
            return 0;
        } else {
            return V1 - V2;
        }
    }
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/
pragma solidity >=0.8.0;

import {Math} from "/mimswap/libraries/Math.sol";

/**
 * @title DecimalMath
 * @author DODO Breeder
 *
 * @notice Functions for fixed point number with 18 decimals
 */
library DecimalMath {
    using Math for uint256;

    uint256 internal constant ONE = 10 ** 18;
    uint256 internal constant ONE2 = 10 ** 36;

    function mulFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return (target * d) / ONE;
    }

    function mulCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return (target * d).divCeil(ONE);
    }

    function divFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return (target * ONE) / d;
    }

    function divCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return (target * ONE).divCeil(d);
    }

    function reciprocalFloor(uint256 target) internal pure returns (uint256) {
        return ONE2 / target;
    }

    function reciprocalCeil(uint256 target) internal pure returns (uint256) {
        return ONE2.divCeil(target);
    }

    function powFloor(uint256 target, uint256 e) internal pure returns (uint256) {
        if (e == 0) {
            return 10 ** 18;
        } else if (e == 1) {
            return target;
        } else {
            uint p = powFloor(target, e / 2);
            p = (p * p) / ONE;
            if (e % 2 == 1) {
                p = (p * target) / ONE;
            }
            return p;
        }
    }
}