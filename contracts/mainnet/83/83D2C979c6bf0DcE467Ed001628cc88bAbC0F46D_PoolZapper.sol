// SPDX-License-Identifier: GPL-v3
pragma solidity 0.8.21;

interface IDeltaSwapFactory9 {
    function getPair(address, address) external returns (address);

    function createPair(address tokenA, address tokenB) external returns (address);
}

// SPDX-License-Identifier: GPL-v3
pragma solidity 0.8.21;

interface IGammaPoolFactory9 {
    function getProtocol(uint16 _protocolId) external view returns (address);
    function isProtocolRestricted(uint16 _protocolId) external view returns(bool);
    function createPool(uint16 _protocolId, address _cfmm, address[] calldata _tokens, bytes calldata _data) external returns(address);
}

// SPDX-License-Identifier: GPL-v3
pragma solidity ^0.8.0;

/// @title Interface for Zapper contract to create DS/GS pools
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
interface IPoolZapper {

    /// @notice Create GammaPool from DeltaSwap pool
    /// @notice If token pair not found in DS, new DS pair will be created
    /// @dev Needs tokens approval from user to position manager to add liquidity
    /// @param token0 Token0 address
    /// @param token1 Token1 address
    /// @param amount0 (Optional) Token0 amount to add liquidity
    /// @param amount1 (Optional) Token1 amount to add liquidity
    /// @param protocolId GammaPool protocolId
    /// @param cfmm address of cfmm (if not DeltaSwap)
    /// @return New GammaPool address
    function createAndAddLiquidity(address token0, address token1, uint256 amount0, uint256 amount1, uint16 protocolId, address cfmm) external returns (address);

}

// SPDX-License-Identifier: GPL-v3
pragma solidity 0.8.21;

interface IPositionManager9 {
	struct DepositReservesParams {
        uint16 protocolId;
        address cfmm;
        address to;
        uint256 deadline;
        uint256[] amountsDesired;
        uint256[] amountsMin;
    }

	function depositReserves(DepositReservesParams calldata params) external returns (uint256[] memory reserves, uint256 shares);
}

// SPDX-License-Identifier: GPL-v3
pragma solidity ^0.8.0;

interface ITransferToken {
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-v3
pragma solidity 0.8.21;

import "./interfaces/IGammaPoolFactory9.sol";
import "./interfaces/IDeltaSwapFactory9.sol";
import "./interfaces/IPositionManager9.sol";
import "./interfaces/ITransferToken.sol";
import "./interfaces/IPoolZapper.sol";

/// @title Zapper contract to create DS/GS pools
/// @author Simon Mall
contract PoolZapper is IPoolZapper {
    /// @notice GammaPool factory
    address public gsFactory;
    /// @notice DeltaSwap factory
    address public dsFactory;
    /// @notice DeltaSwapV2 factory
    address public dsV2Factory;
    /// @notice UniswapV2 factory
    address public uniV2Factory;
    /// @notice Sushiswap factory
    address public sushiFactory;
    /// @notice GammaSwap position manager
    address public positionManager;

    constructor(address _gsFactory, address _dsFactory, address _dsv2Factory, address _univ2Factory, address _sushiFactory, address _positionManager) {
        gsFactory = _gsFactory;
        dsFactory = _dsFactory;
        dsV2Factory = _dsv2Factory;
        uniV2Factory = _univ2Factory;
        sushiFactory = _sushiFactory;
        positionManager = _positionManager;
    }

    function getOrCreatePool(address factory, address token0, address token1) internal virtual returns(address) {
        address cfmm;
        if(factory!=address(0)) {
            cfmm = IDeltaSwapFactory9(factory).getPair(token0, token1);
            if (cfmm == address(0)) {
                cfmm = IDeltaSwapFactory9(factory).createPair(token0, token1);
            }
        }
        return cfmm;
    }

    /// @dev See {IPoolZapper-createAndAddLiquidity}.
    function createAndAddLiquidity(address token0, address token1, uint256 amount0, uint256 amount1, uint16 protocolId, address cfmm) external override virtual returns (address) {
        require(token0 != address(0), "MISSING_TOKEN0");
        require(token1 != address(0), "MISSING_TOKEN1");

        require(IGammaPoolFactory9(gsFactory).getProtocol(protocolId) != address(0), "PROTOCOL_NOT_SET");
        require(!IGammaPoolFactory9(gsFactory).isProtocolRestricted(protocolId), "PROTOCOL_RESTRICTED");

        if(cfmm == address(0)) {
            if(protocolId == 1) {
                cfmm = getOrCreatePool(uniV2Factory, token0, token1);
            } else if(protocolId == 2) {
                cfmm = getOrCreatePool(sushiFactory, token0, token1);
            } else if(protocolId == 3) {
                cfmm = getOrCreatePool(dsFactory, token0, token1);
            } else if(protocolId == 4) {
                cfmm = getOrCreatePool(dsV2Factory, token0, token1);
            }
        }

        require(cfmm != address(0), "MISSING_CFMM");

        address[] memory tokens = new address[](2);
        tokens[0] = token0;
        tokens[1] = token1;

        address gammaPool = IGammaPoolFactory9(gsFactory).createPool(protocolId, cfmm, tokens, "");

        // Add liquidity if tokens are provided to set pricing
        if (amount0 > 0 && amount1 > 0) {
            ITransferToken(token0).transferFrom(msg.sender, address(this), amount0);
            ITransferToken(token1).transferFrom(msg.sender, address(this), amount1);
            ITransferToken(token0).approve(positionManager, amount0);
            ITransferToken(token1).approve(positionManager, amount1);

            uint256[] memory amounts = new uint256[](2);
            amounts[0] = token0 < token1 ? amount0 : amount1;
            amounts[1] = token0 < token1 ? amount1 : amount0;
            uint256[] memory amountsMin = new uint256[](2);
            amountsMin[0] = amounts[0] * 99 / 100;
            amountsMin[1] = amounts[1] * 99 / 100;
            IPositionManager9.DepositReservesParams memory depositParams = IPositionManager9.DepositReservesParams({
                protocolId: protocolId,
                cfmm: cfmm,
                to: msg.sender,
                deadline: type(uint256).max,
                amountsDesired: amounts,
                amountsMin: amountsMin
            });
            (, uint256 shares) = IPositionManager9(positionManager).depositReserves(depositParams);

            require(shares > 0, "Something went wrong");
        }

        return gammaPool;
    }
}