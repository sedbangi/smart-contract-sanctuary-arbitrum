// SPDX-License-Identifier: Apache 2.0
/*

    Copyright 2023 Dolomite.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.8.9;

import { HasLiquidatorRegistry } from "./HasLiquidatorRegistry.sol";
import { OnlyDolomiteMargin } from "../helpers/OnlyDolomiteMargin.sol";
import { IExpiry } from "../interfaces/IExpiry.sol";
import { DolomiteMarginVersionWrapperLib } from "../lib/DolomiteMarginVersionWrapperLib.sol";
import { InterestIndexLib } from "../lib/InterestIndexLib.sol";
import { IDolomiteMargin } from "../protocol/interfaces/IDolomiteMargin.sol";
import { BitsLib } from "../protocol/lib/BitsLib.sol";
import { DecimalLib } from "../protocol/lib/DecimalLib.sol";
import { DolomiteMarginMath } from "../protocol/lib/DolomiteMarginMath.sol";
import { Require } from "../protocol/lib/Require.sol";
import { TypesLib } from "../protocol/lib/TypesLib.sol";

/**
 * @title   BaseLiquidatorProxy
 * @author  Dolomite
 *
 * Inheritable contract that allows sharing code across different liquidator proxy contracts
 */
abstract contract BaseLiquidatorProxy is HasLiquidatorRegistry, OnlyDolomiteMargin {
    using DecimalLib for IDolomiteMargin.Decimal;
    using TypesLib for IDolomiteMargin.Par;
    using DolomiteMarginVersionWrapperLib for *;

    // ============ Structs ============

    struct MarketInfo {
        uint256 marketId;
        IDolomiteMargin.MonetaryPrice price;
        IDolomiteMargin.InterestIndex index;
    }

    struct LiquidatorProxyConstants {
        IDolomiteMargin.AccountInfo solidAccount;
        IDolomiteMargin.AccountInfo liquidAccount;
        uint256 heldMarket;
        uint256 owedMarket;
        MarketInfo[] markets;
        uint256[] liquidMarkets;
        uint256 expirationTimestamp;
    }

    struct LiquidatorProxyCache {
        // mutable
        uint256 owedWeiToLiquidate;
        // The amount of heldMarket the solidAccount will receive. Includes the liquidation reward. Useful as the
        // `amountIn` for a trade
        uint256 solidHeldUpdateWithReward;
        IDolomiteMargin.Wei solidHeldWei;
        IDolomiteMargin.Wei solidOwedWei;
        IDolomiteMargin.Wei liquidHeldWei;
        IDolomiteMargin.Wei liquidOwedWei;
        // This exists purely for expirations. If the amount being repaid is meant to be ALL but the value of the debt
        // is greater than the value of the collateral, then we need to flip the markets in the trade for the Target=0
        // encoding of the Amount. There's a rounding issue otherwise because amounts are calculated differently for
        // trades vs. liquidations
        bool flipMarketsForExpiration;

        // immutable
        uint256 heldPrice;
        uint256 owedPrice;
        uint256 owedPriceAdj;
    }

    // ============ Constants ============

    bytes32 private constant _FILE = "BaseLiquidatorProxy";

    // ============ Immutable Fields ============

    IExpiry public immutable EXPIRY; // solhint-disable-line var-name-mixedcase
    uint256 public immutable CHAIN_ID;

    // ================ Constructor ===============

    constructor(
        address _liquidatorAssetRegistry,
        address _dolomiteMargin,
        address _expiry,
        uint256 _chainId
    )
        HasLiquidatorRegistry(_liquidatorAssetRegistry)
        OnlyDolomiteMargin(_dolomiteMargin)
    {
        EXPIRY = IExpiry(_expiry);
        CHAIN_ID = _chainId;
    }

    // ============ Internal Functions ============

    /**
     * Pre-populates cache values for some pair of markets.
     */
    function _initializeCache(
        LiquidatorProxyConstants memory _constants
    )
    internal
    view
    returns (LiquidatorProxyCache memory)
    {
        MarketInfo memory heldMarketInfo = _binarySearch(_constants.markets, _constants.heldMarket);
        MarketInfo memory owedMarketInfo = _binarySearch(_constants.markets, _constants.owedMarket);

        uint256 owedPriceAdj;
        if (_constants.expirationTimestamp > 0) {
            (, IDolomiteMargin.MonetaryPrice memory owedPricePrice) = EXPIRY.getVersionedSpreadAdjustedPrices(
                CHAIN_ID,
                _constants.liquidAccount,
                _constants.heldMarket,
                _constants.owedMarket,
                uint32(_constants.expirationTimestamp)
            );
            owedPriceAdj = owedPricePrice.value;
        } else {
            IDolomiteMargin.Decimal memory spread = DOLOMITE_MARGIN().getVersionedLiquidationSpreadForPair(
                CHAIN_ID,
                _constants.liquidAccount,
                _constants.heldMarket,
                _constants.owedMarket
            );
            owedPriceAdj = owedMarketInfo.price.value + DecimalLib.mul(owedMarketInfo.price.value, spread);
        }

        return LiquidatorProxyCache({
            owedWeiToLiquidate: 0,
            solidHeldUpdateWithReward: 0,
            solidHeldWei: InterestIndexLib.parToWei(
                DOLOMITE_MARGIN().getAccountPar(_constants.solidAccount, _constants.heldMarket),
                heldMarketInfo.index
            ),
            solidOwedWei: InterestIndexLib.parToWei(
                DOLOMITE_MARGIN().getAccountPar(_constants.solidAccount, _constants.owedMarket),
                owedMarketInfo.index
            ),
            liquidHeldWei: InterestIndexLib.parToWei(
                DOLOMITE_MARGIN().getAccountPar(_constants.liquidAccount, _constants.heldMarket),
                heldMarketInfo.index
            ),
            liquidOwedWei: InterestIndexLib.parToWei(
                DOLOMITE_MARGIN().getAccountPar(_constants.liquidAccount, _constants.owedMarket),
                owedMarketInfo.index
            ),
            flipMarketsForExpiration: false,
            heldPrice: heldMarketInfo.price.value,
            owedPrice: owedMarketInfo.price.value,
            owedPriceAdj: owedPriceAdj
        });
    }

    /**
     * Make some basic checks before attempting to liquidate an account.
     *  - Require that the msg.sender has the permission to use the liquidator account
     *  - Require that the liquid account is liquidatable based on the accounts global value (all assets held and owed,
     *    not just what's being liquidated)
     */
    function _checkConstants(
        LiquidatorProxyConstants memory _constants
    )
    internal
    view
    {
        // panic if the developer didn't set these variables already
        assert(_constants.solidAccount.owner != address(0));
        assert(_constants.liquidAccount.owner != address(0));

        Require.that(
            _constants.owedMarket != _constants.heldMarket,
            _FILE,
            "Owed market equals held market",
            _constants.owedMarket
        );

        Require.that(
            !DOLOMITE_MARGIN().getAccountPar(_constants.liquidAccount, _constants.owedMarket).isPositive(),
            _FILE,
            "Owed market cannot be positive",
            _constants.owedMarket
        );

        Require.that(
            DOLOMITE_MARGIN().getAccountPar(_constants.liquidAccount, _constants.heldMarket).isPositive(),
            _FILE,
            "Held market cannot be negative",
            _constants.heldMarket
        );

        Require.that(
            uint32(_constants.expirationTimestamp) == _constants.expirationTimestamp,
            _FILE,
            "Expiration timestamp overflows",
            _constants.expirationTimestamp
        );

        Require.that(
            _constants.expirationTimestamp <= block.timestamp,
            _FILE,
            "Borrow not yet expired",
            _constants.expirationTimestamp
        );
    }

    /**
     * Make some basic checks before attempting to liquidate an account.
     *  - Require that the msg.sender has the permission to use the solid account
     *  - Require that the liquid account is liquidatable if using an expiration timestamp
     */
    function _checkBasicRequirements(
        LiquidatorProxyConstants memory _constants
    )
    internal
    view
    {
        // check credentials for msg.sender
        Require.that(
            _constants.solidAccount.owner == msg.sender
                || DOLOMITE_MARGIN().getIsLocalOperator(_constants.solidAccount.owner, msg.sender),
            _FILE,
            "Sender not operator",
            msg.sender
        );

        if (_constants.expirationTimestamp != 0) {
            // check the expiration is valid
            uint32 expirationTimestamp = EXPIRY.getExpiry(_constants.liquidAccount, _constants.owedMarket);
            Require.that(
                expirationTimestamp == _constants.expirationTimestamp,
                _FILE,
                "Expiration timestamp mismatch",
                expirationTimestamp,
                _constants.expirationTimestamp
            );
        }
    }

    /**
     * Gets the current total supplyValue and borrowValue for some account. Takes into account what
     * the current index will be once updated.
     */
    function _getAccountValues(
        MarketInfo[] memory _marketInfos,
        IDolomiteMargin.AccountInfo memory _account,
        uint256[] memory _marketIds
    )
    internal
    view
    returns (
        IDolomiteMargin.MonetaryValue memory supplyValue,
        IDolomiteMargin.MonetaryValue memory borrowValue
    )
    {
        return _getAccountValues(
            _marketInfos,
            _account,
            _marketIds,
            /* _adjustForMarginPremiums = */ false
        );
    }

    /**
     * Gets the adjusted current total supplyValue and borrowValue for some account. Takes into account what
     * the current index will be once updated and the margin premium.
     */
    function _getAdjustedAccountValues(
        MarketInfo[] memory _marketInfos,
        IDolomiteMargin.AccountInfo memory _account,
        uint256[] memory _marketIds
    )
    internal
    view
    returns (
        IDolomiteMargin.MonetaryValue memory supplyValue,
        IDolomiteMargin.MonetaryValue memory borrowValue
    )
    {
        return _getAccountValues(
            _marketInfos,
            _account,
            _marketIds,
            /* _adjustForMarginPremiums = */ true
        );
    }

    function _getMarketInfos(
        uint256[] memory _solidMarketIds,
        uint256[] memory _liquidMarketIds
    ) internal view returns (MarketInfo[] memory) {
        uint[] memory marketBitmaps = BitsLib.createBitmaps(DOLOMITE_MARGIN().getNumMarkets());
        uint256 marketsLength = 0;
        marketsLength = _addMarketsToBitmap(_solidMarketIds, marketBitmaps, marketsLength);
        marketsLength = _addMarketsToBitmap(_liquidMarketIds, marketBitmaps, marketsLength);

        uint256 counter = 0;
        MarketInfo[] memory marketInfos = new MarketInfo[](marketsLength);
        for (uint256 i; i < marketBitmaps.length && counter != marketsLength; ++i) {
            uint256 bitmap = marketBitmaps[i];
            while (bitmap != 0) {
                uint256 nextSetBit = BitsLib.getLeastSignificantBit(bitmap);
                uint256 marketId = BitsLib.getMarketIdFromBit(i, nextSetBit);

                marketInfos[counter++] = MarketInfo({
                    marketId: marketId,
                    price: DOLOMITE_MARGIN().getMarketPrice(marketId),
                    index: DOLOMITE_MARGIN().getMarketCurrentIndex(marketId)
                });

                // unset the set bit
                bitmap = BitsLib.unsetBit(bitmap, nextSetBit);
            }
        }

        return marketInfos;
    }

    /**
     * Calculate the maximum amount that can be liquidated on `liquidAccount`
     */
    function _calculateAndSetMaxLiquidationAmount(
        LiquidatorProxyCache memory _cache
    )
        internal
        pure
    {
        uint256 liquidHeldValue = _cache.heldPrice * _cache.liquidHeldWei.value;
        uint256 liquidOwedValue = _cache.owedPriceAdj * _cache.liquidOwedWei.value;
        if (liquidHeldValue < liquidOwedValue) {
            // The held collateral is worth less than the adjusted debt
            _cache.solidHeldUpdateWithReward = _cache.liquidHeldWei.value;
            _cache.owedWeiToLiquidate = DolomiteMarginMath.getPartialRoundUp(
                _cache.liquidHeldWei.value,
                _cache.heldPrice,
                _cache.owedPriceAdj
            );
            _cache.flipMarketsForExpiration = true;
        } else {
            _cache.solidHeldUpdateWithReward = DolomiteMarginMath.getPartial(
                _cache.liquidOwedWei.value,
                _cache.owedPriceAdj,
                _cache.heldPrice
            );
            _cache.owedWeiToLiquidate = _cache.liquidOwedWei.value;
        }
    }

    function _calculateAndSetActualLiquidationAmount(
        uint256 _inputAmountWei,
        uint256 _minOutputAmountWei,
        LiquidatorProxyCache memory _cache
    )
        internal
        pure
        returns (uint256 _newInputAmountWei, uint256 _newMinOutputAmountWei)
    {
        // at this point, _cache.owedWeiToLiquidate should be the max amount that can be liquidated on the user.
        assert(_cache.owedWeiToLiquidate > 0); // assert it was initialized

        uint256 desiredLiquidationOwedAmount = _minOutputAmountWei;
        if (
            desiredLiquidationOwedAmount < _cache.owedWeiToLiquidate
            && desiredLiquidationOwedAmount * _cache.owedPriceAdj < _cache.heldPrice * _cache.liquidHeldWei.value
        ) {
            // The user wants to liquidate less than the max amount, and the held collateral is worth more than the
            // desired debt to liquidate
            _cache.owedWeiToLiquidate = desiredLiquidationOwedAmount;
            _cache.solidHeldUpdateWithReward = DolomiteMarginMath.getPartial(
                desiredLiquidationOwedAmount,
                _cache.owedPriceAdj,
                _cache.heldPrice
            );
        }

        if (_inputAmountWei == type(uint256).max) {
            // This is analogous to saying "sell all of the collateral I receive from the liquidation"
            _newInputAmountWei = _cache.solidHeldUpdateWithReward;
        } else {
            _newInputAmountWei = _inputAmountWei;
        }

        if (_minOutputAmountWei == type(uint256).max) {
            // Setting the value to max uint256 is analogous to saying "liquidate all"
            _newMinOutputAmountWei = _cache.owedWeiToLiquidate;
        } else {
            _newMinOutputAmountWei = _minOutputAmountWei;
        }
    }

    /**
     * Returns true if the supplyValue over-collateralizes the borrowValue by the ratio.
     */
    function _isCollateralized(
        uint256 _supplyValue,
        uint256 _borrowValue,
        IDolomiteMargin.Decimal memory _ratio
    )
        internal
        pure
        returns (bool)
    {
        uint256 requiredMargin = DecimalLib.mul(_borrowValue, _ratio);
        return _supplyValue >= _borrowValue + requiredMargin;
    }

    function _binarySearch(
        MarketInfo[] memory _markets,
        uint256 _marketId
    ) internal pure returns (MarketInfo memory) {
        return _binarySearch(
            _markets,
            /* _beginInclusive = */ 0,
            _markets.length,
            _marketId
        );
    }

    // ============ Private Functions ============

    function _getAccountValues(
        MarketInfo[] memory _marketInfos,
        IDolomiteMargin.AccountInfo memory _account,
        uint256[] memory _marketIds,
        bool _adjustForMarginPremiums
    )
        private
        view
        returns (
            IDolomiteMargin.MonetaryValue memory supplyValue,
            IDolomiteMargin.MonetaryValue memory borrowValue
        )
    {
        for (uint256 i; i < _marketIds.length; ++i) {
            IDolomiteMargin.Par memory par = DOLOMITE_MARGIN().getAccountPar(_account, _marketIds[i]);
            MarketInfo memory marketInfo = _binarySearch(_marketInfos, _marketIds[i]);
            IDolomiteMargin.Wei memory userWei = InterestIndexLib.parToWei(par, marketInfo.index);
            uint256 assetValue = userWei.value * marketInfo.price.value;
            IDolomiteMargin.Decimal memory marginPremium = DecimalLib.one();
            if (_adjustForMarginPremiums) {
                marginPremium = DecimalLib.onePlus(DOLOMITE_MARGIN().getMarketMarginPremium(_marketIds[i]));
            }
            if (userWei.sign) {
                supplyValue.value = supplyValue.value + DecimalLib.div(assetValue, marginPremium);
            } else {
                borrowValue.value = borrowValue.value + DecimalLib.mul(assetValue, marginPremium);
            }
        }

        return (supplyValue, borrowValue);
    }

    function _addMarketsToBitmap(
        uint256[] memory _markets,
        uint256[] memory _bitmaps,
        uint256 _marketsLength
    ) private pure returns (uint) {
        for (uint256 i; i < _markets.length; ++i) {
            if (!BitsLib.hasBit(_bitmaps, _markets[i])) {
                BitsLib.setBit(_bitmaps, _markets[i]);
                _marketsLength += 1;
            }
        }
        return _marketsLength;
    }

    function _binarySearch(
        MarketInfo[] memory _markets,
        uint256 _beginInclusive,
        uint256 _endExclusive,
        uint256 _marketId
    ) private pure returns (MarketInfo memory) {
        uint256 len = _endExclusive - _beginInclusive;
        if (len == 0 || (len == 1 && _markets[_beginInclusive].marketId != _marketId)) {
            revert("BaseLiquidatorProxy: Market not found"); // solhint-disable-line reason-string
        }

        uint256 mid = _beginInclusive + len / 2;
        uint256 midMarketId = _markets[mid].marketId;
        if (_marketId < midMarketId) {
            return _binarySearch(
                _markets,
                _beginInclusive,
                mid,
                _marketId
            );
        } else if (_marketId > midMarketId) {
            return _binarySearch(
                _markets,
                mid + 1,
                _endExclusive,
                _marketId
            );
        } else {
            return _markets[mid];
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { OnlyDolomiteMarginForUpgradeable } from "../helpers/OnlyDolomiteMarginForUpgradeable.sol";
import { ProxyContractHelpers } from "../helpers/ProxyContractHelpers.sol";
import { IBaseRegistry } from "../interfaces/IBaseRegistry.sol";
import { IDolomiteRegistry } from "../interfaces/IDolomiteRegistry.sol";
import { ValidationLib } from "../lib/ValidationLib.sol";
import { Require } from "../protocol/lib/Require.sol";


/**
 * @title   BaseRegistry
 * @author  Dolomite
 *
 * @notice  Registry contract for storing ecosystem-related addresses
 */
contract BaseRegistry is
    IBaseRegistry,
    ProxyContractHelpers,
    OnlyDolomiteMarginForUpgradeable,
    Initializable
{

    // ===================== Constants =====================

    bytes32 private constant _FILE = "BaseRegistry";
    bytes32 private constant _DOLOMITE_REGISTRY_SLOT = bytes32(uint256(keccak256("eip1967.proxy.dolomiteRegistry")) - 1); // solhint-disable-line max-line-length

    // ===================== Functions =====================

    function ownerSetDolomiteRegistry(
        address _dolomiteRegistry
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        _ownerSetDolomiteRegistry(_dolomiteRegistry);
    }

    function dolomiteRegistry() external view returns (IDolomiteRegistry) {
        return IDolomiteRegistry(_getAddress(_DOLOMITE_REGISTRY_SLOT));
    }

    // ===================== Internal Functions =====================

    function _ownerSetDolomiteRegistry(
        address _dolomiteRegistry
    ) internal {
        Require.that(
            _dolomiteRegistry != address(0),
            _FILE,
            "Invalid dolomiteRegistry"
        );
        bytes memory returnData = ValidationLib.callAndCheckSuccess(
            _dolomiteRegistry,
            IDolomiteRegistry(_dolomiteRegistry).genericTraderProxy.selector,
            bytes("")
        );
        abi.decode(returnData, (address));

        _setAddress(_DOLOMITE_REGISTRY_SLOT, _dolomiteRegistry);
        emit DolomiteRegistrySet(_dolomiteRegistry);
    }
}

// SPDX-License-Identifier: Apache 2.0
/*

    Copyright 2022 Dolomite.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.8.9;

import { ILiquidatorAssetRegistry } from "../interfaces/ILiquidatorAssetRegistry.sol";
import { Require } from "../protocol/lib/Require.sol";


/**
 * @title   HasLiquidatorRegistry
 * @author  Dolomite
 *
 * Contract for storing and referring to the liquidator asset registry for whitelisting/handling liquidations
 */
abstract contract HasLiquidatorRegistry {

    // ============ Constants ============

    bytes32 private constant _FILE = "HasLiquidatorRegistry";

    // ============ Storage ============

    ILiquidatorAssetRegistry public immutable LIQUIDATOR_ASSET_REGISTRY; // solhint-disable-line var-name-mixedcase

    // ============ Modifiers ============

    modifier requireIsAssetWhitelistedForLiquidation(uint256 _marketId) {
        _validateAssetForLiquidation(_marketId);
        _;
    }

    modifier requireIsAssetsWhitelistedForLiquidation(uint256[] memory _marketIds) {
        _validateAssetsForLiquidation(_marketIds);
        _;
    }

    // ============ Constructors ============

    constructor(address _liquidatorAssetRegistry) {
        LIQUIDATOR_ASSET_REGISTRY = ILiquidatorAssetRegistry(_liquidatorAssetRegistry);
    }

    // ============ Internal Functions ============

    function _validateAssetForLiquidation(uint256 _marketId) internal view {
        Require.that(
            LIQUIDATOR_ASSET_REGISTRY.isAssetWhitelistedForLiquidation(_marketId, address(this)),
            _FILE,
            "Asset not whitelisted",
            _marketId
        );
    }

    function _validateAssetsForLiquidation(uint256[] memory _marketIds) internal view {
        for (uint256 i = 0; i < _marketIds.length; i++) {
            Require.that(
                LIQUIDATOR_ASSET_REGISTRY.isAssetWhitelistedForLiquidation(_marketIds[i], address(this)),
                _FILE,
                "Asset not whitelisted",
                _marketIds[i]
            );
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";


/**
 * @title   MinimalERC20
 * @author  OpenZeppelin
 *
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
contract MinimalERC20 is IERC20, IERC20Metadata {

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
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
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
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
        address owner = msg.sender;
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
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
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
        return _decimals;
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
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
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
        require(
            from != address(0),
            "ERC20: Transfer from the zero address"
        );
        require(
            to != address(0),
            "ERC20: Transfer to the zero address"
        );

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: Transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
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
        require(
            account != address(0),
            "ERC20: Mint to the zero address"
        );

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
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
        require(
            account != address(0),
            "ERC20: Burn from the zero address"
        );

        uint256 accountBalance = _balances[account];
        require(
            accountBalance >= amount,
            "ERC20: Burn amount exceeds balance"
        );
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
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
        require(
            owner != address(0),
            "ERC20: Approve from the zero address"
        );
        require(
            spender != address(0),
            "ERC20: Approve to the zero address"
        );

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
        require(
            currentAllowance >= amount,
            "ERC20: Insufficient allowance"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - amount);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { OnlyDolomiteMarginForUpgradeable } from "./OnlyDolomiteMarginForUpgradeable.sol";
import { IDolomiteMargin } from "../protocol/interfaces/IDolomiteMargin.sol";


/**
 * @title   OnlyDolomiteMargin
 * @author  Dolomite
 *
 * @notice  Inheritable contract that restricts the calling of certain functions to `DolomiteMargin`, the owner of
 *          `DolomiteMargin` or a `DolomiteMargin` global operator
 */
abstract contract OnlyDolomiteMargin is OnlyDolomiteMarginForUpgradeable {

    // ============ Constants ============

    bytes32 private constant _FILE = "OnlyDolomiteMargin";

    // ============ Storage ============

    IDolomiteMargin private immutable _DOLOMITE_MARGIN; // solhint-disable-line var-name-mixedcase

    // ============ Constructor ============

    constructor (address _dolomiteMargin) {
        _DOLOMITE_MARGIN = IDolomiteMargin(_dolomiteMargin);
    }

    // ============ Functions ============

    function DOLOMITE_MARGIN() public override view returns (IDolomiteMargin) {
        return _DOLOMITE_MARGIN;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { ProxyContractHelpers } from "./ProxyContractHelpers.sol";
import { IOnlyDolomiteMargin } from "../interfaces/IOnlyDolomiteMargin.sol";
import { IDolomiteMargin } from "../protocol/interfaces/IDolomiteMargin.sol";
import { Require } from "../protocol/lib/Require.sol";


/**
 * @title   OnlyDolomiteMarginForUpgradeable
 * @author  Dolomite
 *
 * @notice  Inheritable contract that restricts the calling of certain functions to `DolomiteMargin`, the owner of
 *          `DolomiteMargin` or a `DolomiteMargin` global operator
 */
abstract contract OnlyDolomiteMarginForUpgradeable is IOnlyDolomiteMargin, ProxyContractHelpers {

    // ============ Constants ============

    bytes32 private constant _FILE = "OnlyDolomiteMargin";
    bytes32 private constant _DOLOMITE_MARGIN_SLOT = bytes32(uint256(keccak256("eip1967.proxy.dolomiteMargin")) - 1);

    // ============ Modifiers ============

    modifier onlyDolomiteMargin(address _from) {
        Require.that(
            _from == address(DOLOMITE_MARGIN()),
            _FILE,
            "Only Dolomite can call function",
            _from
        );
        _;
    }

    modifier onlyDolomiteMarginOwner(address _from) {
        Require.that(
            _from == DOLOMITE_MARGIN().owner(),
            _FILE,
            "Caller is not owner of Dolomite",
            _from
        );
        _;
    }

    modifier onlyDolomiteMarginGlobalOperator(address _from) {
        Require.that(
            DOLOMITE_MARGIN().getIsGlobalOperator(_from),
            _FILE,
            "Caller is not a global operator",
            _from
        );
        _;
    }

    // ============ Functions ============

    function DOLOMITE_MARGIN() public virtual view returns (IDolomiteMargin) {
        return IDolomiteMargin(_getAddress(_DOLOMITE_MARGIN_SLOT));
    }

    function _setDolomiteMarginViaSlot(address _dolomiteMargin) internal {
        _setAddress(_DOLOMITE_MARGIN_SLOT, _dolomiteMargin);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;


/**
 * @title   ProxyContractHelpers
 * @author  Dolomite
 *
 * @notice  Helper functions for upgradeable proxy contracts to use
 */
abstract contract ProxyContractHelpers {

    // ================ Internal Functions ==================

    function _callImplementation(address _implementation) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    function _setAddress(bytes32 slot, address _value) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _value)
        }
    }

    function _setUint256(bytes32 slot, uint256 _value) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _value)
        }
    }

    function _getAddress(bytes32 slot) internal view returns (address value) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            value := sload(slot)
        }
    }

    function _getUint256(bytes32 slot) internal view returns (uint256 value) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            value := sload(slot)
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;


/**
 * @title   IAuthorizationBase
 * @author  Dolomite
 *
 * @notice  Interface for allowing only trusted callers to invoke functions that use the `requireIsCallerAuthorized`
 *          modifier.
 */
interface IAuthorizationBase {

    function setIsCallerAuthorized(address _caller, bool _isAuthorized) external;

    function isCallerAuthorized(address _caller) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteRegistry } from "./IDolomiteRegistry.sol";


/**
 * @title   IBaseRegistry
 * @author  Dolomite
 *
 * @notice  Interface for base storage variables that should be in all registry contracts
 */
interface IBaseRegistry {

    // ========================================================
    // ======================== Events ========================
    // ========================================================

    event DolomiteRegistrySet(address indexed _dolomiteRegistry);

    // ========================================================
    // =================== Admin Functions ====================
    // ========================================================

    function ownerSetDolomiteRegistry(address _dolomiteRegistry) external;

    // ========================================================
    // =================== Getter Functions ===================
    // ========================================================

    function dolomiteRegistry() external view returns (IDolomiteRegistry);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { AccountBalanceLib } from "../lib/AccountBalanceLib.sol";


/**
 * @title   IBorrowPositionProxyV1
 * @author  Dolomite
 *
 * @notice  Interface for allowing the transfer of assets between account numbers. Emits an event to allow for easy
 *          indexing of a subgraph for getting active borrow positions.
 */
interface IBorrowPositionProxyV1 {

    // ========================= Events =========================

    event BorrowPositionOpen(address indexed _borrower, uint256 indexed _borrowAccountNumber);

    // ========================= Functions =========================

    /**
     *
     * @param  _fromAccountNumber   The index from which `msg.sender` will be sourcing the deposit
     * @param  _toAccountNumber     The index into which `msg.sender` will be depositing
     * @param  _collateralMarketId  The ID of the market being deposited
     * @param  _amountWei           The amount, in Wei, to deposit
     * @param  _balanceCheckFlag    Flag used to check if `_fromAccountNumber`, `_toAccountNumber`, or both accounts can
     *                              go negative after the transfer settles. Setting the flag to
     *                              `AccountBalanceLib.BalanceCheckFlag.None=3` results in neither account being
     *                              checked.
     */
    function openBorrowPosition(
        uint256 _fromAccountNumber,
        uint256 _toAccountNumber,
        uint256 _collateralMarketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    /**
     * @notice  This method can only be called once the user's debt has been reduced to zero. Sends all
     *          `_collateralMarketIds` from `_borrowAccountNumber` to `_toAccountNumber`.
     *
     * @param  _borrowAccountNumber The index from which `msg.sender` collateral will be withdrawn
     * @param  _toAccountNumber     The index into which `msg.sender` will be depositing leftover collateral
     * @param  _collateralMarketIds The IDs of the markets being withdrawn, to close the position
     */
    function closeBorrowPosition(
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber,
        uint256[] calldata _collateralMarketIds
    ) external;

    /**
     *
     * @param  _fromAccountNumber   The index from which `msg.sender` will be withdrawing assets
     * @param  _toAccountNumber     The index into which `msg.sender` will be depositing assets
     * @param  _marketId            The ID of the market being transferred
     * @param  _amountWei           The amount, in Wei, to transfer
     * @param  _balanceCheckFlag    Flag used to check if `_fromAccountNumber`, `_toAccountNumber`, or both accounts can
     *                              go negative after the transfer settles. Setting the flag to
     *                              `AccountBalanceLib.BalanceCheckFlag.None=3` results in neither account being
     *                              checked.
     */
    function transferBetweenAccounts(
        uint256 _fromAccountNumber,
        uint256 _toAccountNumber,
        uint256 _marketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    /**
     *
     * @param  _fromAccountNumber   The index from which `msg.sender` will be depositing assets
     * @param  _borrowAccountNumber The index of the borrow position for that will receive the deposited assets
     * @param  _marketId            The ID of the market being transferred
     * @param  _balanceCheckFlag    Flag used to check if `_fromAccountNumber`, `_borrowAccountNumber`, or both accounts
     *                              can go negative after the transfer settles. Setting the flag to
     *                              `AccountBalanceLib.BalanceCheckFlag.None=3` results in neither account being
     *                              checked.
     */
    function repayAllForBorrowPosition(
        uint256 _fromAccountNumber,
        uint256 _borrowAccountNumber,
        uint256 _marketId,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IAuthorizationBase } from "./IAuthorizationBase.sol";
import { IBorrowPositionProxyV1 } from "./IBorrowPositionProxyV1.sol";
import { AccountBalanceLib } from "../lib/AccountBalanceLib.sol";


/**
 * @title   IBorrowPositionProxyV2
 * @author  Dolomite
 *
 * @notice  Interface for allowing only trusted callers to invoke borrow related functions for transferring funds
 *          between account owners.
 */
interface IBorrowPositionProxyV2 is IAuthorizationBase, IBorrowPositionProxyV1 {

    // ========================= Functions =========================

    /**
     *
     * @param  _fromAccountOwner    The account from which the user will be sourcing the deposit
     * @param  _fromAccountNumber   The index from which `_toAccountOwner` will be sourcing the deposit
     * @param  _toAccountOwner      The account into which `_fromAccountOwner` will be depositing
     * @param  _toAccountNumber     The index into which `_fromAccountOwner` will be depositing
     * @param  _collateralMarketId  The ID of the market being deposited
     * @param  _amountWei           The amount, in Wei, to deposit
     * @param  _balanceCheckFlag    Flag used to check if `_fromAccountNumber`, `_toAccountNumber`, or both accounts can
     *                              go negative after the transfer settles. Setting the flag to
     *                              `AccountBalanceLib.BalanceCheckFlag.None=3` results in neither account being
     *                              checked.
     */
    function openBorrowPositionWithDifferentAccounts(
        address _fromAccountOwner,
        uint256 _fromAccountNumber,
        address _toAccountOwner,
        uint256 _toAccountNumber,
        uint256 _collateralMarketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    /**
     * @notice  This method can only be called once the user's debt has been reduced to zero. Sends all
     *          `_collateralMarketIds` from `_borrowAccountNumber` to `_toAccountNumber`.
     *
     * @param  _borrowAccountOwner  The account from which collateral will be withdrawn
     * @param  _borrowAccountNumber The index from which `msg.sender` collateral will be withdrawn
     * @param  _toAccountOwner      The account into which `_borrowAccountOwner` will be depositing leftover collateral
     * @param  _toAccountNumber     The index into which `_borrowAccountOwner` will be depositing leftover collateral
     * @param  _collateralMarketIds The IDs of the markets being withdrawn, to close the position
     */
    function closeBorrowPositionWithDifferentAccounts(
        address _borrowAccountOwner,
        uint256 _borrowAccountNumber,
        address _toAccountOwner,
        uint256 _toAccountNumber,
        uint256[] calldata _collateralMarketIds
    ) external;

    /**
     *
     * @param  _fromAccountOwner    The account from which assets will be withdrawn
     * @param  _fromAccountNumber   The index from which `msg.sender` will be withdrawing assets
     * @param  _toAccountOwner      The account to which assets will be deposited
     * @param  _toAccountNumber     The index into which `msg.sender` will be depositing assets
     * @param  _marketId            The ID of the market being transferred
     * @param  _amountWei           The amount, in Wei, to transfer
     * @param  _balanceCheckFlag    Flag used to check if `_fromAccountNumber`, `_toAccountNumber`, or both accounts can
     *                              go negative after the transfer settles. Setting the flag to
     *                              `AccountBalanceLib.BalanceCheckFlag.None=3` results in neither account being
     *                              checked.
     */
    function transferBetweenAccountsWithDifferentAccounts(
        address _fromAccountOwner,
        uint256 _fromAccountNumber,
        address _toAccountOwner,
        uint256 _toAccountNumber,
        uint256 _marketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    /**
     *
     * @param  _fromAccountOwner    The account from which assets will be withdrawn for repayment
     * @param  _fromAccountNumber   The index from which `msg.sender` will be depositing assets
     * @param  _borrowAccountOwner  The account of the borrow position that will receive the deposited assets
     * @param  _borrowAccountNumber The index of the borrow position for that will receive the deposited assets
     * @param  _marketId            The ID of the market being transferred
     * @param  _balanceCheckFlag    Flag used to check if `_fromAccountNumber`, `_borrowAccountNumber`, or both accounts
     *                              can go negative after the transfer settles. Setting the flag to
     *                              `AccountBalanceLib.BalanceCheckFlag.None=3` results in neither account being
     *                              checked.
     */
    function repayAllForBorrowPositionWithDifferentAccounts(
        address _fromAccountOwner,
        uint256 _fromAccountNumber,
        address _borrowAccountOwner,
        uint256 _borrowAccountNumber,
        uint256 _marketId,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteStructs } from "../protocol/interfaces/IDolomiteStructs.sol";


/**
 * @title   IDolomiteMigrator
 * @author  Dolomite
 *
 * Interface for a migrator contract, which can migrate funds out of users isolation mode vaults
 */
interface IDolomiteMigrator {

    // ================================================
    // ==================== Structs ===================
    // ================================================

    struct Transformer {
        address transformer;
        bool soloAllowable;
    }

    // ================================================
    // ==================== Events ====================
    // ================================================

    event MigrationComplete(
        address indexed _accountOwner,
        uint256 _accountNumber,
        uint256 _fromMarketId,
        uint256 _toMarketId
    );

    event TransformerSet(uint256 _fromMarketId, uint256 _toMarketId, address _transformer);

    event HandlerSet(address _handler);

    // ================================================
    // ================== Functions ===================
    // ================================================

    function migrate(
        IDolomiteStructs.AccountInfo[] calldata _accounts,
        uint256 _fromMarketId,
        uint256 _toMarketId,
        bytes calldata _extraData
    ) external;

    function selfMigrate(
        uint256 _accountNumber,
        uint256 _fromMarketId,
        uint256 _toMarketId,
        bytes calldata _extraData
    ) external;

    function ownerSetTransformer(
        uint256 _fromMarketId,
        uint256 _toMarketId,
        address _transformer,
        bool _soloAllowable
    ) external;

    function ownerSetHandler(address _handler) external;

    function getTransformerByMarketIds(
        uint256 _fromMarketId,
        uint256 _toMarketId
    ) external view returns (Transformer memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteMigrator } from "./IDolomiteMigrator.sol";
import { IEventEmitterRegistry } from "./IEventEmitterRegistry.sol";
import { IExpiry } from "./IExpiry.sol";
import { IGenericTraderProxyV1 } from "./IGenericTraderProxyV1.sol";
import { ILiquidatorAssetRegistry } from "./ILiquidatorAssetRegistry.sol";
import { IDolomitePriceOracle } from "../protocol/interfaces/IDolomitePriceOracle.sol";


/**
 * @title   IDolomiteRegistry
 * @author  Dolomite
 *
 * @notice  A registry contract for storing all of the addresses that can interact with Umami's Delta Neutral vaults
 */
interface IDolomiteRegistry {

    // ========================================================
    // ======================== Events ========================
    // ========================================================

    event GenericTraderProxySet(address indexed _genericTraderProxy);
    event ExpirySet(address indexed _expiry);
    event SlippageToleranceForPauseSentinelSet(uint256 _slippageTolerance);
    event LiquidatorAssetRegistrySet(address indexed _liquidatorAssetRegistry);
    event EventEmitterSet(address indexed _eventEmitter);
    event ChainlinkPriceOracleSet(address indexed _chainlinkPriceOracle);
    event DolomiteMigratorSet(address indexed _dolomiteMigrator);
    event RedstonePriceOracleSet(address indexed _redstonePriceOracle);
    event OracleAggregatorSet(address indexed _oracleAggregator);

    // ========================================================
    // =================== Admin Functions ====================
    // ========================================================

    /**
     *
     * @param  _genericTraderProxy  The new address of the generic trader proxy
     */
    function ownerSetGenericTraderProxy(address _genericTraderProxy) external;

    /**
     *
     * @param  _expiry  The new address of the expiry contract
     */
    function ownerSetExpiry(address _expiry) external;

    /**
     *
     * @param  _slippageToleranceForPauseSentinel   The slippage tolerance (using 1e18 as the base) for zaps when pauses
     *                                              are enabled
     */
    function ownerSetSlippageToleranceForPauseSentinel(uint256 _slippageToleranceForPauseSentinel) external;

    /**
     *
     * @param  _liquidatorRegistry  The new address of the liquidator registry
     */
    function ownerSetLiquidatorAssetRegistry(address _liquidatorRegistry) external;

    /**
     *
     * @param  _eventEmitter  The new address of the event emitter
     */
    function ownerSetEventEmitter(address _eventEmitter) external;

    /**
     *
     * @param  _chainlinkPriceOracle    The new address of the Chainlink price oracle that's compatible with
     *                                  DolomiteMargin.
     */
    function ownerSetChainlinkPriceOracle(address _chainlinkPriceOracle) external;

    function ownerSetDolomiteMigrator(address _dolomiteMigrator) external;

    /**
     *
     * @param  _redstonePriceOracle    The new address of the Redstone price oracle that's compatible with
     *                                  DolomiteMargin.
     */
    function ownerSetRedstonePriceOracle(address _redstonePriceOracle) external;

    /**
     *
     * @param  _oracleAggregator    The new address of the oracle aggregator that's compatible with
     *                              DolomiteMargin.
     */
    function ownerSetOracleAggregator(address _oracleAggregator) external;

    // ========================================================
    // =================== Getter Functions ===================
    // ========================================================

    /**
     * @return  The address of the generic trader proxy for making zaps
     */
    function genericTraderProxy() external view returns (IGenericTraderProxyV1);

    /**
     * @return  The address of the expiry contract
     */
    function expiry() external view returns (IExpiry);

    /**
     * @return  The slippage tolerance (using 1e18 as the base) for zaps when pauses are enabled
     */
    function slippageToleranceForPauseSentinel() external view returns (uint256);

    /**
     * @return  The address of the liquidator asset registry contract
     */
    function liquidatorAssetRegistry() external view returns (ILiquidatorAssetRegistry);

    /**
     * @return The address of the emitter contract that can emit certain events for indexing
     */
    function eventEmitter() external view returns (IEventEmitterRegistry);

    /**
     * @return The address of the Chainlink price oracle that's compatible with DolomiteMargin
     */
    function chainlinkPriceOracle() external view returns (IDolomitePriceOracle);

    function dolomiteMigrator() external view returns (IDolomiteMigrator);

    /**
     * @return The address of the Redstone price oracle that's compatible with DolomiteMargin
     */
    function redstonePriceOracle() external view returns (IDolomitePriceOracle);

    /**
     * @return The address of the oracle aggregator that's compatible with DolomiteMargin
     */
    function oracleAggregator() external view returns (IDolomitePriceOracle);

    /**
     * @return The base (denominator) for the slippage tolerance variable. Always 1e18.
     */
    function slippageToleranceForPauseSentinelBase() external pure returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;


/**
 * @title   IDolomiteTransformer
 * @author  Dolomite
 *
 * @notice  Interface for a transformer implementation
 */
interface IDolomiteTransformer {

    function inputToken() external view returns (address);

    function outputToken() external view returns (address);

    function transform(uint256 amount, bytes calldata _extraData) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IGenericTraderBase } from "./IGenericTraderBase.sol";
import { IUpgradeableAsyncIsolationModeUnwrapperTrader } from "../isolation-mode/interfaces/IUpgradeableAsyncIsolationModeUnwrapperTrader.sol"; // solhint-disable-line max-line-length
import { IUpgradeableAsyncIsolationModeWrapperTrader } from "../isolation-mode/interfaces/IUpgradeableAsyncIsolationModeWrapperTrader.sol"; // solhint-disable-line max-line-length
import { IDolomiteStructs } from "../protocol/interfaces/IDolomiteStructs.sol";


/**
 * @title   IEventEmitterRegistry
 * @author  Dolomite
 *
 * Interface for a a singleton event emission contract, which makes tracking events easier for the Subgraph.
 */
interface IEventEmitterRegistry {

    // ================================================
    // ==================== Structs ===================
    // ================================================

    struct BalanceUpdate {
        IDolomiteStructs.Wei deltaWei;
        IDolomiteStructs.Par newPar;
    }

    // ================================================
    // ==================== Events ====================
    // ================================================

    /**
     * @notice This is emitted when a zap is executed
     *
     * @param  accountOwner     The address of the account that executed the zap
     * @param  accountNumber    The sub account of the address that executed the zap
     * @param  marketIdsPath    The path of market IDs that was executed
     * @param  tradersPath      The path of traders that was executed
     */
    event ZapExecuted(
        address indexed accountOwner,
        uint256 accountNumber,
        uint256[] marketIdsPath,
        IGenericTraderBase.TraderParam[] tradersPath
    );

    /**
     * @notice This is emitted when a borrow position is initially opened
     *
     * @param  borrower             The address of the account that opened the position
     * @param  borrowAccountNumber  The account number of the account that opened the position
     */
    event BorrowPositionOpen(
        address indexed borrower,
        uint256 indexed borrowAccountNumber
    );

    /**
     * @notice This is emitted when a margin position is initially opened
     *
     * @param  accountOwner         The address of the account that opened the position
     * @param  accountNumber        The account number of the account that opened the position
     * @param  inputToken           The token that was sold to purchase the collateral. This should be the owed token
     * @param  outputToken          The token that was purchased with the debt. This should be the held token
     * @param  depositToken         The token that was deposited as collateral. This should be the held token
     * @param  inputBalanceUpdate   The amount of inputToken that was sold to purchase the outputToken
     * @param  outputBalanceUpdate  The amount of outputToken that was purchased with the inputToken
     * @param  marginDepositUpdate  The amount of depositToken that was deposited as collateral
     */
    event MarginPositionOpen(
        address indexed accountOwner,
        uint256 indexed accountNumber,
        address inputToken,
        address outputToken,
        address depositToken,
        BalanceUpdate inputBalanceUpdate,
        BalanceUpdate outputBalanceUpdate,
        BalanceUpdate marginDepositUpdate
    );

    /**
     * @notice This is emitted when a margin position is (partially) closed
     *
     * @param  accountOwner             The address of the account that opened the position
     * @param  accountNumber            The account number of the account that opened the position
     * @param  inputToken               The token that was sold to purchase the debt. This should be the held token
     * @param  outputToken              The token that was purchased with the collateral. This should be the owed token
     * @param  withdrawalToken          The token that was withdrawn as collateral. This should be the held token
     * @param  inputBalanceUpdate       The amount of inputToken that was sold to purchase the outputToken
     * @param  outputBalanceUpdate      The amount of outputToken that was purchased with the inputToken
     * @param  marginWithdrawalUpdate   The amount of withdrawalToken that was deposited as collateral
     */
    event MarginPositionClose(
        address indexed accountOwner,
        uint256 indexed accountNumber,
        address inputToken,
        address outputToken,
        address withdrawalToken,
        BalanceUpdate inputBalanceUpdate,
        BalanceUpdate outputBalanceUpdate,
        BalanceUpdate marginWithdrawalUpdate
    );

    event AsyncDepositCreated(
        bytes32 indexed key,
        address indexed token,
        IUpgradeableAsyncIsolationModeWrapperTrader.DepositInfo deposit
    );

    event AsyncDepositOutputAmountUpdated(
        bytes32 indexed key,
        address indexed token,
        uint256 outputAmount
    );

    event AsyncDepositExecuted(bytes32 indexed key, address indexed token);

    event AsyncDepositFailed(bytes32 indexed key, address indexed token, string reason);

    event AsyncDepositCancelled(bytes32 indexed key, address indexed token);

    event AsyncDepositCancelledFailed(bytes32 indexed key, address indexed token, string reason);

    event AsyncWithdrawalCreated(
        bytes32 indexed key,
        address indexed token,
        IUpgradeableAsyncIsolationModeUnwrapperTrader.WithdrawalInfo withdrawal
    );

    event AsyncWithdrawalOutputAmountUpdated(
        bytes32 indexed key,
        address indexed token,
        uint256 outputAmount
    );

    event AsyncWithdrawalExecuted(bytes32 indexed key, address indexed token);

    event AsyncWithdrawalFailed(bytes32 indexed key, address indexed token, string reason);

    event AsyncWithdrawalCancelled(bytes32 indexed key, address indexed token);

    event RewardClaimed(
        address indexed distributor,
        address indexed user,
        uint256 epoch,
        uint256 amount
    );

    // ================================================
    // ================== Functions ===================
    // ================================================

    /**
     * @notice Emits a ZapExecuted event
     *
     * @param  _accountOwner    The address of the account that executed the zap
     * @param  _accountNumber   The sub account of the address that executed the zap
     * @param  _marketIdsPath   The path of market IDs that was executed
     * @param  _tradersPath     The path of traders that was executed
     */
    function emitZapExecuted(
        address _accountOwner,
        uint256 _accountNumber,
        uint256[] calldata _marketIdsPath,
        IGenericTraderBase.TraderParam[] calldata _tradersPath
    )
    external;

    /**
     * @notice Emits a MarginPositionOpen event
     *
     * @param  _accountOwner         The address of the account that opened the position
     * @param  _accountNumber        The account number of the account that opened the position
     */
    function emitBorrowPositionOpen(
        address _accountOwner,
        uint256 _accountNumber
    )
    external;

    /**
     * @notice Emits a MarginPositionOpen event
     *
     * @param  _accountOwner         The address of the account that opened the position
     * @param  _accountNumber        The account number of the account that opened the position
     * @param  _inputToken           The token that was sold to purchase the collateral. This should be the owed token
     * @param  _outputToken          The token that was purchased with the debt. This should be the held token
     * @param  _depositToken         The token that was deposited as collateral. This should be the held token
     * @param  _inputBalanceUpdate   The amount of inputToken that was sold to purchase the outputToken
     * @param  _outputBalanceUpdate  The amount of outputToken that was purchased with the inputToken
     * @param  _marginDepositUpdate  The amount of depositToken that was deposited as collateral
     */
    function emitMarginPositionOpen(
        address _accountOwner,
        uint256 _accountNumber,
        address _inputToken,
        address _outputToken,
        address _depositToken,
        BalanceUpdate calldata _inputBalanceUpdate,
        BalanceUpdate calldata _outputBalanceUpdate,
        BalanceUpdate calldata _marginDepositUpdate
    )
    external;

    /**
     * @notice Emits a MarginPositionClose event
     *
     * @param  _accountOwner            The address of the account that opened the position
     * @param  _accountNumber           The account number of the account that opened the position
     * @param  _inputToken              The token that was sold to purchase the debt. This should be the held token
     * @param  _outputToken             The token that was purchased with the collateral. This should be the owed token
     * @param  _withdrawalToken         The token that was withdrawn as collateral. This should be the held token
     * @param  _inputBalanceUpdate      The amount of inputToken that was sold to purchase the outputToken
     * @param  _outputBalanceUpdate     The amount of outputToken that was purchased with the inputToken
     * @param  _marginWithdrawalUpdate  The amount of withdrawalToken that was deposited as collateral
     */
    function emitMarginPositionClose(
        address _accountOwner,
        uint256 _accountNumber,
        address _inputToken,
        address _outputToken,
        address _withdrawalToken,
        BalanceUpdate calldata _inputBalanceUpdate,
        BalanceUpdate calldata _outputBalanceUpdate,
        BalanceUpdate calldata _marginWithdrawalUpdate
    )
    external;

    function emitAsyncDepositCreated(
        bytes32 _key,
        address _token,
        IUpgradeableAsyncIsolationModeWrapperTrader.DepositInfo calldata _deposit
    ) external;

    function emitAsyncDepositOutputAmountUpdated(
        bytes32 _key,
        address _token,
        uint256 _outputAmount
    ) external;

    function emitAsyncDepositExecuted(bytes32 _key, address _token) external;

    function emitAsyncDepositFailed(bytes32 _key, address _token, string calldata _reason) external;

    function emitAsyncDepositCancelled(bytes32 _key, address _token) external;

    function emitAsyncDepositCancelledFailed(bytes32 _key, address _token, string calldata _reason) external;

    function emitAsyncWithdrawalCreated(
        bytes32 _key,
        address _token,
        IUpgradeableAsyncIsolationModeUnwrapperTrader.WithdrawalInfo calldata _withdrawal
    ) external;

    function emitAsyncWithdrawalOutputAmountUpdated(
        bytes32 _key,
        address _token,
        uint256 _outputAmount
    ) external;

    function emitAsyncWithdrawalExecuted(bytes32 _key, address _token) external;

    function emitAsyncWithdrawalFailed(bytes32 _key, address _token, string calldata _reason) external;

    function emitAsyncWithdrawalCancelled(bytes32 _key, address _token) external;

    function emitRewardClaimed(address user, uint256 _epoch, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteMargin } from "../protocol/interfaces/IDolomiteMargin.sol";


/**
 * @title   IExpiry
 * @author  Dolomite
 *
 * @notice  Interface for getting, setting, and executing the expiry of a position.
 */
interface IExpiry {

    // ============ Enums ============

    enum CallFunctionType {
        SetExpiry,
        SetApproval
    }

    // ============ Structs ============

    struct SetExpiryArg {
        IDolomiteMargin.AccountInfo account;
        uint256 marketId;
        uint32 timeDelta;
        bool forceUpdate;
    }

    struct SetApprovalArg {
        address sender;
        uint32 minTimeDelta;
    }

    function getSpreadAdjustedPrices(
        uint256 heldMarketId,
        uint256 owedMarketId,
        uint32 expiry
    )
    external
    view
    returns (IDolomiteMargin.MonetaryPrice memory heldPrice, IDolomiteMargin.MonetaryPrice memory owedPriceAdj);

    function getExpiry(
        IDolomiteMargin.AccountInfo calldata account,
        uint256 marketId
    )
    external
    view
    returns (uint32);

    function g_expiryRampTime() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteMargin } from "../protocol/interfaces/IDolomiteMargin.sol";
import { IDolomiteStructs } from "../protocol/interfaces/IDolomiteStructs.sol";


/**
 * @title   IExpiryV2
 * @author  Dolomite
 *
 * @notice  Interface for getting, setting, and executing the expiry of a position.
 */
interface IExpiryV2 {

    // ============ Enums ============

    enum CallFunctionType {
        SetExpiry,
        SetApproval
    }

    // ============ Structs ============

    struct SetExpiryArg {
        IDolomiteMargin.AccountInfo account;
        uint256 marketId;
        uint32 timeDelta;
        bool forceUpdate;
    }

    struct SetApprovalArg {
        address sender;
        uint32 minTimeDelta;
    }

    function getLiquidationSpreadAdjustedPrices(
        IDolomiteStructs.AccountInfo calldata liquidAccount,
        uint256 heldMarketId,
        uint256 owedMarketId,
        uint32 expiry
    )
    external
    view
    returns (IDolomiteStructs.MonetaryPrice memory heldPrice, IDolomiteStructs.MonetaryPrice memory owedPriceAdj);

    function getExpiry(
        IDolomiteMargin.AccountInfo calldata account,
        uint256 marketId
    )
    external
    view
    returns (uint32);

    function g_expiryRampTime() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteMargin } from "../protocol/interfaces/IDolomiteMargin.sol";


/**
 * @title   IGenericTraderBase
 * @author  Dolomite
 *
 * @notice  Base contract structs/params for a generic trader contract.
 */
interface IGenericTraderBase {

    // ============ Enums ============

    enum TraderType {
        /// @dev    The trade will be conducted using external liquidity, using an `ActionType.Sell` or `ActionType.Buy`
        ///         action.
        ExternalLiquidity,
        /// @dev    The trade will be conducted using internal liquidity, using an `ActionType.Trade` action.
        InternalLiquidity,
        /// @dev    The trade will be conducted using external liquidity using an `ActionType.Sell` or `ActionType.Buy`
        ///         action. If this TradeType is used, the trader must be validated using
        ///         the `IIsolationModeToken#isTokenConverterTrusted` function on the IsolationMode token.
        IsolationModeUnwrapper,
        /// @dev    The trade will be conducted using external liquidity using an `ActionType.Sell` or `ActionType.Buy`
        ///         action. If this TradeType is used, the trader must be validated using
        ///         the `IIsolationModeToken#isTokenConverterTrusted` function on the IsolationMode token.
        IsolationModeWrapper
    }

    // ============ Structs ============

    struct TraderParam {
        /// @dev The type of trade to conduct
        TraderType traderType;
        /// @dev    The index into the `_makerAccounts` array of the maker account to trade with. Should be set to 0 if
        ///         the traderType is not `TraderType.InternalLiquidity`.
        uint256 makerAccountIndex;
        /// @dev The address of IAutoTrader or IExchangeWrapper that will be used to conduct the trade.
        address trader;
        /// @dev The data that will be passed through to the trader contract.
        bytes tradeData;
    }

    struct GenericTraderProxyCache {
        IDolomiteMargin dolomiteMargin;
        /// @dev    True if the user is making a margin deposit, false if they are withdrawing. False if the variable is
        ///         unused too.
        bool isMarginDeposit;
        /// @dev    The other account number that is not `_traderAccountNumber`. Only used for TransferCollateralParams.
        uint256 otherAccountNumber;
        /// @dev    The index into the account array at which traders start.
        uint256 traderAccountStartIndex;
        /// @dev    The cursor for the looping through the operation's actions.
        uint256 actionsCursor;
        /// @dev    The balance of `inputMarket` that the trader has before the call to `dolomiteMargin.operate`
        IDolomiteMargin.Wei inputBalanceWeiBeforeOperate;
        /// @dev    The balance of `outputMarket` that the trader has before the call to `dolomiteMargin.operate`
        IDolomiteMargin.Wei outputBalanceWeiBeforeOperate;
        /// @dev    The balance of `transferMarket` that the trader has before the call to `dolomiteMargin.operate`
        IDolomiteMargin.Wei transferBalanceWeiBeforeOperate;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.8.9;

import { IGenericTraderBase } from "./IGenericTraderBase.sol";
import { AccountBalanceLib } from "../lib/AccountBalanceLib.sol";
import { IDolomiteMargin } from "../protocol/interfaces/IDolomiteMargin.sol";



/**
 * @title   IGenericTraderProxyV1
 * @author  Dolomite
 *
 * Trader proxy interface for trading assets using any trader from msg.sender
 */
interface IGenericTraderProxyV1 is IGenericTraderBase {

    // ============ Structs ============

    enum EventEmissionType {
        None,
        BorrowPosition,
        MarginPosition
    }

    struct TransferAmount {
        /// @dev The market ID to transfer
        uint256 marketId;
        /// @dev Note, setting to uint(-1) will transfer all of the user's balance.
        uint256 amountWei;
    }

    struct TransferCollateralParam {
        /// @dev The account number from which collateral will be transferred.
        uint256 fromAccountNumber;
        /// @dev The account number to which collateral will be transferred.
        uint256 toAccountNumber;
        /// @dev The transfers to execute after all of the trades.
        TransferAmount[] transferAmounts;
    }

    struct ExpiryParam {
        /// @dev The market ID whose expiry will be updated.
        uint256 marketId;
        /// @dev The new expiry time delta for the market. Setting this to `0` will reset the expiration.
        uint32 expiryTimeDelta;
    }

    struct UserConfig {
        /// @dev The timestamp at which the zap request fails
        uint256 deadline;
        /// @dev    Setting this to `BalanceCheckFlag.Both` or `BalanceCheckFlag.From` will check the
        ///         `_tradeAccountNumber` is not negative after the trade for the input market (_marketIdsPath[0]).
        ///         Setting this to `BalanceCheckFlag.Both` or `BalanceCheckFlag.To` will check the
        ///         `_transferAccountNumber` is not negative after the trade for any of the transfers in
        ///         `TransferCollateralParam.transferAmounts`.
        AccountBalanceLib.BalanceCheckFlag balanceCheckFlag;
        EventEmissionType eventType;
    }

    // ============ Functions ============

    /**
     * @dev     Swaps an exact amount of input for a minimum amount of output.
     *
     * @param  _tradeAccountNumber          The account number to use for msg.sender's trade
     * @param  _marketIdsPath               The path of market IDs to use for each trade action. Length should be equal
     *                                      to `_tradersPath.length + 1`.
     * @param  _inputAmountWei              The input amount (in wei) to use for the initial trade action. Setting this
     *                                      value to `uint(-1)` will use the user's full balance.
     * @param  _minOutputAmountWei          The minimum output amount expected to be received by the user.
     * @param  _tradersPath                 The path of traders to use for each trade action. Length should be equal to
     *                                      `_marketIdsPath.length - 1`.
     * @param  _makerAccounts               The accounts that will be used for the maker side of the trades involving
     *                                      `TraderType.InternalLiquidity`.
     * @param  _userConfig                  The user configuration for the trade. Setting the `balanceCheckFlag` to
     *                                      `BalanceCheckFlag.From` will check that the user's `_tradeAccountNumber`
     *                                      is non-negative after the trade. Setting the `balanceCheckFlag` to
     *                                      `BalanceCheckFlag.To` has no effect.
     */
    function swapExactInputForOutput(
        uint256 _tradeAccountNumber,
        uint256[] calldata _marketIdsPath,
        uint256 _inputAmountWei,
        uint256 _minOutputAmountWei,
        IGenericTraderBase.TraderParam[] calldata _tradersPath,
        IDolomiteMargin.AccountInfo[] calldata _makerAccounts,
        UserConfig calldata _userConfig
    )
    external;

    /**
     * @dev     The same function as `swapExactInputForOutput`, but allows the caller to transfer collateral and modify
     *          the position's expiration in the same transaction.
     *
     * @param  _tradeAccountNumber          The account number to use for msg.sender's trade
     * @param  _marketIdsPath               The path of market IDs to use for each trade action. Length should be equal
     *                                      to `_tradersPath.length + 1`.
     * @param  _inputAmountWei              The input amount (in wei) to use for the initial trade action. Setting this
     *                                      value to `uint(-1)` will use the user's full balance.
     * @param  _minOutputAmountWei          The minimum output amount expected to be received by the user.
     * @param  _tradersPath                 The path of traders to use for each trade action. Length should be equal to
     *                                      `_marketIdsPath.length - 1`.
     * @param  _makerAccounts               The accounts that will be used for the maker side of the trades involving
                                            `TraderType.InternalLiquidity`.
     * @param  _transferCollateralParams    The parameters for transferring collateral in/out of the
     *                                      `_tradeAccountNumber` once the trades settle. One of
     *                                      `_params.fromAccountNumber` or `_params.toAccountNumber` must be equal to
     *                                      `_tradeAccountNumber`.
     * @param  _expiryParams                The parameters for modifying the expiration of the debt in the position.
     * @param  _userConfig                  The user configuration for the trade. Setting the `balanceCheckFlag` to
     *                                      `BalanceCheckFlag.From` will check that the user's balance for inputMarket
     *                                      for `_tradeAccountNumber` is non-negative after the trade. Setting the
     *                                      `balanceCheckFlag` to `BalanceCheckFlag.To` will check that the user's
     *                                      balance for each `transferMarket` for `transferAccountNumber` is
     *                                      non-negative after.
     */
    function swapExactInputForOutputAndModifyPosition(
        uint256 _tradeAccountNumber,
        uint256[] calldata _marketIdsPath,
        uint256 _inputAmountWei,
        uint256 _minOutputAmountWei,
        IGenericTraderBase.TraderParam[] calldata _tradersPath,
        IDolomiteMargin.AccountInfo[] calldata _makerAccounts,
        TransferCollateralParam calldata _transferCollateralParams,
        ExpiryParam calldata _expiryParams,
        UserConfig calldata _userConfig
    )
    external;

    function ownerSetEventEmitterRegistry(
        address _eventEmitterRegistry
    ) external;

    function EXPIRY() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

/**
 * @title   ILiquidatorAssetRegistry
 * @author  Dolomite
 *
 * Interface for a registry that tracks which assets can be liquidated and by each contract
 */
interface ILiquidatorAssetRegistry {

    /**
     *
     * @param  _marketId    The market ID of the asset
     * @param  _liquidator  The address of the liquidator to add
     */
    function ownerAddLiquidatorToAssetWhitelist(
        uint256 _marketId,
        address _liquidator
    )
    external;

    /**
     *
     * @param  _marketId    The market ID of the asset
     * @param  _liquidator  The address of the liquidator to remove
     */
    function ownerRemoveLiquidatorFromAssetWhitelist(
        uint256 _marketId,
        address _liquidator
    )
    external;

    /**
     *
     * @param  _marketId    The market ID of the asset to check
     * @return              An array of whitelisted liquidators for the asset. An empty array is returned if any
     *                      liquidator can be used for this asset
     */
    function getLiquidatorsForAsset(
        uint256 _marketId
    )
    external view returns (address[] memory);

    /**
     *
     * @param  _marketId    The market ID of the asset to check
     * @param  _liquidator  The address of the liquidator to check
     * @return              True if the liquidator is whitelisted for the asset, false otherwise. Returns true if there
     *                      are no whitelisted liquidators for the asset. Should ALWAYS have at least ONE whitelisted
     *                      liquidator for IsolationMode assets.
     */
    function isAssetWhitelistedForLiquidation(
        uint256 _marketId,
        address _liquidator
    )
    external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteMargin } from "../protocol/interfaces/IDolomiteMargin.sol";


/**
 * @title   IOnlyDolomiteMargin
 * @author  Dolomite
 *
 * @notice  This interface is for contracts that need to add modifiers for only DolomiteMargin / Owner caller.
 */
interface IOnlyDolomiteMargin {

    function DOLOMITE_MARGIN() external view returns (IDolomiteMargin);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/
pragma solidity ^0.8.9;

import { BaseLiquidatorProxy } from "../../../general/BaseLiquidatorProxy.sol";
import { IDolomiteRegistry } from "../../../interfaces/IDolomiteRegistry.sol";
import { IGenericTraderProxyV1 } from "../../../interfaces/IGenericTraderProxyV1.sol";
import { AccountActionLib } from "../../../lib/AccountActionLib.sol";
import { AccountBalanceLib } from "../../../lib/AccountBalanceLib.sol";
import { DolomiteMarginVersionWrapperLib } from "../../../lib/DolomiteMarginVersionWrapperLib.sol";
import { InterestIndexLib } from "../../../lib/InterestIndexLib.sol";
import { IDolomiteMargin } from "../../../protocol/interfaces/IDolomiteMargin.sol";
import { IDolomiteStructs } from "../../../protocol/interfaces/IDolomiteStructs.sol";
import { BitsLib } from "../../../protocol/lib/BitsLib.sol";
import { DecimalLib } from "../../../protocol/lib/DecimalLib.sol";
import { Require } from "../../../protocol/lib/Require.sol";
import { TypesLib } from "../../../protocol/lib/TypesLib.sol";
import { IIsolationModeTokenVaultV1 } from "../../interfaces/IIsolationModeTokenVaultV1.sol";
import { IIsolationModeVaultFactory } from "../../interfaces/IIsolationModeVaultFactory.sol";


/**
 * @title   IsolationModeTokenVaultV1ActionsImpl
 * @author  Dolomite
 *
 * Reusable library for functions that save bytecode on the async unwrapper/wrapper contracts
 */
library IsolationModeTokenVaultV1ActionsImpl {
    using DecimalLib for uint256;
    using DolomiteMarginVersionWrapperLib for IDolomiteMargin;
    using TypesLib for IDolomiteMargin.Par;
    using TypesLib for IDolomiteMargin.Wei;

    // ===================================================
    // ==================== Constants ====================
    // ===================================================

    bytes32 private constant _FILE = "IsolationModeVaultV1ActionsImpl";

    // ===================================================
    // ==================== Functions ====================
    // ===================================================

    function depositIntoVaultForDolomiteMargin(
        IIsolationModeTokenVaultV1 _vault,
        uint256 _toAccountNumber,
        uint256 _amountWei
    ) public {
        // This implementation requires we deposit into index 0
        _checkToAccountNumberIsZero(_toAccountNumber);
        IIsolationModeVaultFactory(_vault.VAULT_FACTORY()).depositIntoDolomiteMargin(_toAccountNumber, _amountWei);
    }

    function withdrawFromVaultForDolomiteMargin(
        IIsolationModeTokenVaultV1 _vault,
        uint256 _fromAccountNumber,
        uint256 _amountWei
    ) public {
        // This implementation requires we withdraw from index 0
        _checkFromAccountNumberIsZero(_fromAccountNumber);
        IIsolationModeVaultFactory(_vault.VAULT_FACTORY()).withdrawFromDolomiteMargin(_fromAccountNumber, _amountWei);
    }

    function openBorrowPosition(
        IIsolationModeTokenVaultV1 _vault,
        uint256 _fromAccountNumber,
        uint256 _toAccountNumber,
        uint256 _amountWei
    ) public {
        _checkFromAccountNumberIsZero(_fromAccountNumber);
        Require.that(
            _toAccountNumber != 0,
            _FILE,
            "Invalid toAccountNumber",
            _toAccountNumber
        );

        _vault.BORROW_POSITION_PROXY().openBorrowPosition(
            _fromAccountNumber,
            _toAccountNumber,
            _vault.marketId(),
            _amountWei,
            AccountBalanceLib.BalanceCheckFlag.Both
        );
    }

    function closeBorrowPositionWithUnderlyingVaultToken(
        IIsolationModeTokenVaultV1 _vault,
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber
    ) public {
        _checkBorrowAccountNumberIsNotZero(_borrowAccountNumber, /* _bypassAccountNumberCheck = */ false);
        _checkToAccountNumberIsZero(_toAccountNumber);

        uint256[] memory collateralMarketIds = new uint256[](1);
        collateralMarketIds[0] = _vault.marketId();

        _vault.BORROW_POSITION_PROXY().closeBorrowPositionWithDifferentAccounts(
            /* _borrowAccountOwner = */ address(this),
            _borrowAccountNumber,
            /* _toAccountOwner = */ address(this),
            _toAccountNumber,
            collateralMarketIds
        );
    }

    function closeBorrowPositionWithOtherTokens(
        IIsolationModeTokenVaultV1 _vault,
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber,
        uint256[] calldata _collateralMarketIds
    ) public {
        _checkBorrowAccountNumberIsNotZero(_borrowAccountNumber, /* _bypassAccountNumberCheck = */ false);
        uint256 underlyingMarketId = _vault.marketId();
        for (uint256 i = 0; i < _collateralMarketIds.length; i++) {
            Require.that(
                _collateralMarketIds[i] != underlyingMarketId,
                _FILE,
                "Cannot withdraw market to wallet",
                underlyingMarketId
            );
        }

        _vault.BORROW_POSITION_PROXY().closeBorrowPositionWithDifferentAccounts(
            /* _borrowAccountOwner = */ address(this),
            _borrowAccountNumber,
            /* _toAccountOwner = */ _vault.OWNER(),
            _toAccountNumber,
            _collateralMarketIds
        );
    }

    function transferIntoPositionWithUnderlyingToken(
        IIsolationModeTokenVaultV1 _vault,
        uint256 _fromAccountNumber,
        uint256 _borrowAccountNumber,
        uint256 _amountWei
    ) public {
        _checkFromAccountNumberIsZero(_fromAccountNumber);
        _checkBorrowAccountNumberIsNotZero(_borrowAccountNumber, /* _bypassAccountNumberCheck = */ false);

        _vault.BORROW_POSITION_PROXY().transferBetweenAccounts(
            _fromAccountNumber,
            _borrowAccountNumber,
            _vault.marketId(),
            _amountWei,
            AccountBalanceLib.BalanceCheckFlag.Both
        );
    }

    function transferIntoPositionWithOtherToken(
        IIsolationModeTokenVaultV1 _vault,
        uint256 _fromAccountNumber,
        uint256 _borrowAccountNumber,
        uint256 _marketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag,
        bool _checkAllowableCollateralMarketFlag,
        bool _bypassAccountNumberCheck
    ) public {
        _checkBorrowAccountNumberIsNotZero(_borrowAccountNumber, _bypassAccountNumberCheck);
        _checkMarketIdIsNotSelf(_vault, _marketId);

        _vault.BORROW_POSITION_PROXY().transferBetweenAccountsWithDifferentAccounts(
            /* _fromAccountOwner = */ _vault.OWNER(),
            _fromAccountNumber,
            /* _toAccountOwner = */ address(this),
            _borrowAccountNumber,
            _marketId,
            _amountWei,
            _balanceCheckFlag
        );

        if (_checkAllowableCollateralMarketFlag) {
            _checkAllowableCollateralMarket(
                _vault,
                address(this),
                _borrowAccountNumber,
                _marketId
            );
        }
    }

    function transferFromPositionWithUnderlyingToken(
        IIsolationModeTokenVaultV1 _vault,
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber,
        uint256 _amountWei
    ) public {
        _checkBorrowAccountNumberIsNotZero(_borrowAccountNumber, /* _bypassAccountNumberCheck = */ false);
        _checkToAccountNumberIsZero(_toAccountNumber);

        _vault.BORROW_POSITION_PROXY().transferBetweenAccounts(
            _borrowAccountNumber,
            _toAccountNumber,
            _vault.marketId(),
            _amountWei,
            AccountBalanceLib.BalanceCheckFlag.Both
        );
    }

    function transferFromPositionWithOtherToken(
        IIsolationModeTokenVaultV1 _vault,
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber,
        uint256 _marketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag,
        bool _bypassAccountNumberCheck
    ) public {
        _checkBorrowAccountNumberIsNotZero(_borrowAccountNumber, _bypassAccountNumberCheck);
        _checkMarketIdIsNotSelf(_vault, _marketId);

        _vault.BORROW_POSITION_PROXY().transferBetweenAccountsWithDifferentAccounts(
            /* _fromAccountOwner = */ address(this),
            _borrowAccountNumber,
            /* _toAccountOwner = */ _vault.OWNER(),
            _toAccountNumber,
            _marketId,
            _amountWei,
            _balanceCheckFlag
        );

        _checkAllowableDebtMarket(_vault, address(this), _borrowAccountNumber, _marketId);
    }

    function repayAllForBorrowPosition(
        IIsolationModeTokenVaultV1 _vault,
        uint256 _fromAccountNumber,
        uint256 _borrowAccountNumber,
        uint256 _marketId,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) public {
        _checkBorrowAccountNumberIsNotZero(_borrowAccountNumber, /* _bypassAccountNumberCheck = */ false);
        _checkMarketIdIsNotSelf(_vault, _marketId);
        _vault.BORROW_POSITION_PROXY().repayAllForBorrowPositionWithDifferentAccounts(
            /* _fromAccountOwner = */ _vault.OWNER(),
            _fromAccountNumber,
            /* _borrowAccountOwner = */ address(this),
            _borrowAccountNumber,
            _marketId,
            _balanceCheckFlag
        );
    }

    function addCollateralAndSwapExactInputForOutput(
        IIsolationModeTokenVaultV1 _vault,
        uint256 _fromAccountNumber,
        uint256 _borrowAccountNumber,
        uint256[] calldata _marketIdsPath,
        uint256 _inputAmountWei,
        uint256 _minOutputAmountWei,
        IGenericTraderProxyV1.TraderParam[] memory _tradersPath,
        IDolomiteMargin.AccountInfo[] memory _makerAccounts,
        IGenericTraderProxyV1.UserConfig memory _userConfig
    ) public {
        if (_borrowAccountNumber == 0) {
            uint256 marketId = _vault.marketId();
            Require.that(
                _marketIdsPath[0] != marketId && _marketIdsPath[_marketIdsPath.length - 1] == marketId,
                _FILE,
                "Invalid marketId for swap/add"
            );
        }

        if (_marketIdsPath[0] == _vault.marketId()) {
            transferIntoPositionWithUnderlyingToken(
                _vault,
                _fromAccountNumber,
                _borrowAccountNumber,
                _inputAmountWei
            );
        } else {
            if (_inputAmountWei == AccountActionLib.all()) {
                _inputAmountWei = _getAndValidateBalanceForAllForMarket(
                    _vault,
                    _vault.OWNER(),
                    _fromAccountNumber,
                    _marketIdsPath[0]
                );
            }
            // we always swap the exact amount out; no need to check `BalanceCheckFlag.To`
            // always skip the checking allowable collateral, since we're immediately trading all of it here
            transferIntoPositionWithOtherToken(
                _vault,
                _fromAccountNumber,
                _borrowAccountNumber,
                _marketIdsPath[0],
                _inputAmountWei,
                AccountBalanceLib.BalanceCheckFlag.From,
                /* _checkAllowableCollateralMarketFlag = */ false,
                /* _bypassAccountNumberCheck = */ true
            );
        }

        swapExactInputForOutput(
            _vault,
            _borrowAccountNumber,
            _marketIdsPath,
            _inputAmountWei,
            _minOutputAmountWei,
            _tradersPath,
            _makerAccounts,
            _userConfig,
            /* _checkOutputMarketIdFlag = */ true,
            /* _bypassAccountNumberCheck = */ true
        );
    }

    function swapExactInputForOutputAndRemoveCollateral(
        IIsolationModeTokenVaultV1 _vault,
        uint256 _toAccountNumber,
        uint256 _borrowAccountNumber,
        uint256[] calldata _marketIdsPath,
        uint256 _inputAmountWei,
        uint256 _minOutputAmountWei,
        IGenericTraderProxyV1.TraderParam[] memory _tradersPath,
        IDolomiteMargin.AccountInfo[] memory _makerAccounts,
        IGenericTraderProxyV1.UserConfig memory _userConfig
    ) public {
        uint256 outputMarketId = _marketIdsPath[_marketIdsPath.length - 1];
        if (_borrowAccountNumber == 0) {
            uint256 marketId = _vault.marketId();
            Require.that(
                outputMarketId != marketId && _marketIdsPath[0] == marketId,
                _FILE,
                "Invalid marketId for swap/remove"
            );
        }

        IDolomiteStructs.Wei memory balanceDelta;

        // Create a new scope for stack too deep
        {
            IDolomiteMargin dolomiteMargin = _vault.DOLOMITE_MARGIN();
            IDolomiteStructs.AccountInfo memory borrowAccount = IDolomiteStructs.AccountInfo({
                owner: address(this),
                number: _borrowAccountNumber
            });
            // Validate the output balance before executing the swap
            IDolomiteStructs.Wei memory balanceBefore = dolomiteMargin.getAccountWei(borrowAccount, outputMarketId);

            swapExactInputForOutput(
                _vault,
                _borrowAccountNumber,
                _marketIdsPath,
                _inputAmountWei,
                _minOutputAmountWei,
                _tradersPath,
                _makerAccounts,
                _userConfig,
                /* _checkOutputMarketIdFlag = */ false,
                /* _bypassAccountNumberCheck = */ true
            );

            balanceDelta = dolomiteMargin
                .getAccountWei(borrowAccount, outputMarketId)
                .sub(balanceBefore);
        }

        // Panic if the balance delta is not positive
        assert(balanceDelta.isPositive());

        if (outputMarketId == _vault.marketId()) {
            transferFromPositionWithUnderlyingToken(
                /* _vault = */ _vault,
                _borrowAccountNumber,
                _toAccountNumber,
                balanceDelta.value
            );
        } else {
            transferFromPositionWithOtherToken(
                /* _vault = */ _vault,
                _borrowAccountNumber,
                _toAccountNumber,
                outputMarketId,
                balanceDelta.value,
                AccountBalanceLib.BalanceCheckFlag.None, // we always transfer the exact amount out; no need to check
                /* _bypassAccountNumberCheck = */ true
            );
        }
    }

    function swapExactInputForOutput(
        IIsolationModeTokenVaultV1 _vault,
        uint256 _tradeAccountNumber,
        uint256[] calldata _marketIdsPath,
        uint256 _inputAmountWei,
        uint256 _minOutputAmountWei,
        IGenericTraderProxyV1.TraderParam[] memory _tradersPath,
        IDolomiteMargin.AccountInfo[] memory _makerAccounts,
        IGenericTraderProxyV1.UserConfig memory _userConfig,
        bool _checkOutputMarketIdFlag,
        bool _bypassAccountNumberCheck
    ) public {
        if (!_bypassAccountNumberCheck) {
            Require.that(
                _tradeAccountNumber != 0,
                _FILE,
                "Invalid tradeAccountNumber",
                _tradeAccountNumber
            );
        }

        if (_inputAmountWei == AccountActionLib.all()) {
            _inputAmountWei = _getAndValidateBalanceForAllForMarket(
                _vault,
                /* _accountOwner = */ address(_vault),
                _tradeAccountNumber,
                _marketIdsPath[0]
            );
        }

        _vault.dolomiteRegistry().genericTraderProxy().swapExactInputForOutput(
            _tradeAccountNumber,
            _marketIdsPath,
            _inputAmountWei,
            _minOutputAmountWei,
            _tradersPath,
            _makerAccounts,
            _userConfig
        );

        uint256 inputMarketId = _marketIdsPath[0];
        uint256 outputMarketId = _marketIdsPath[_marketIdsPath.length - 1];
        address tradeAccountOwner = address(this);
        _checkAllowableCollateralMarket(_vault, tradeAccountOwner, _tradeAccountNumber, inputMarketId);
        _checkAllowableDebtMarket(_vault, tradeAccountOwner, _tradeAccountNumber, inputMarketId);
        if (_checkOutputMarketIdFlag) {
            _checkAllowableCollateralMarket(_vault, tradeAccountOwner, _tradeAccountNumber, outputMarketId);
            _checkAllowableDebtMarket(_vault, tradeAccountOwner, _tradeAccountNumber, outputMarketId);
        }
    }

    function validateIsNotLiquidatable(
        IIsolationModeTokenVaultV1 _vault,
        uint256 _accountNumber
    ) public view {
        IDolomiteMargin dolomiteMargin = _vault.DOLOMITE_MARGIN();
        IDolomiteStructs.AccountInfo memory liquidAccount = IDolomiteStructs.AccountInfo({
            owner: address(this),
            number: _accountNumber
        });
        uint256[] memory marketsWithBalances = dolomiteMargin.getAccountMarketsWithBalances(liquidAccount);
        BaseLiquidatorProxy.MarketInfo[] memory marketInfos = _getMarketInfos(
            dolomiteMargin,
            /* _solidMarketIds = */ new uint256[](0),
            marketsWithBalances
        );
        (
            IDolomiteStructs.MonetaryValue memory liquidSupplyValue,
            IDolomiteStructs.MonetaryValue memory liquidBorrowValue
        ) = _getAdjustedAccountValues(
            dolomiteMargin,
            marketInfos,
            liquidAccount,
            marketsWithBalances
        );

        IDolomiteStructs.Decimal memory marginRatio = dolomiteMargin.getMarginRatio();
        Require.that(
            dolomiteMargin.getAccountStatus(liquidAccount) != IDolomiteStructs.AccountStatus.Liquid
                && _isCollateralized(liquidSupplyValue.value, liquidBorrowValue.value, marginRatio),
            _FILE,
            "Account liquidatable"
        );
    }

    function requireMinAmountIsNotTooLargeForLiquidation(
        IDolomiteMargin _dolomiteMargin,
        uint256 _chainId,
        IDolomiteStructs.AccountInfo memory _liquidAccount,
        uint256 _inputMarketId,
        uint256 _outputMarketId,
        uint256 _inputTokenAmount,
        uint256 _minOutputAmount
    ) public view {
        uint256 inputValue = _dolomiteMargin.getMarketPrice(_inputMarketId).value * _inputTokenAmount;
        uint256 outputValue = _dolomiteMargin.getMarketPrice(_outputMarketId).value * _minOutputAmount;

        IDolomiteStructs.Decimal memory spread = _dolomiteMargin.getVersionedLiquidationSpreadForPair(
            _chainId,
            _liquidAccount,
            /* heldMarketId = */ _inputMarketId,
            /* ownedMarketId = */ _outputMarketId
        );
        spread.value /= 2;
        uint256 inputValueAdj = inputValue - inputValue.mul(spread);

        Require.that(
            outputValue <= inputValueAdj,
            _FILE,
            "minOutputAmount too large"
        );
    }

    function requireMinAmountIsNotTooLargeForWrapToUnderlying(
        IDolomiteRegistry _dolomiteRegistry,
        IDolomiteMargin _dolomiteMargin,
        address _accountOwner,
        uint256 _accountNumber,
        uint256 _inputMarketId,
        uint256 _outputMarketId,
        uint256 _inputAmount,
        uint256 _minOutputAmount
    ) public view {
        if (_inputAmount == type(uint256).max) {
            IDolomiteStructs.AccountInfo memory account = IDolomiteStructs.AccountInfo({
                owner: _accountOwner,
                number: _accountNumber
            });
            _inputAmount = _dolomiteMargin.getAccountWei(account, _inputMarketId).value;
        }

        uint256 inputValue = _dolomiteMargin.getMarketPrice(_inputMarketId).value * _inputAmount;
        uint256 outputValue = _dolomiteMargin.getMarketPrice(_outputMarketId).value * _minOutputAmount;

        IDolomiteStructs.Decimal memory toleranceDecimal = IDolomiteStructs.Decimal({
            value: _dolomiteRegistry.slippageToleranceForPauseSentinel()
        });
        uint256 inputValueAdj = inputValue + inputValue.mul(toleranceDecimal);

        Require.that(
            outputValue <= inputValueAdj,
            _FILE,
            "minOutputAmount too large"
        );
    }

    // ===================================================
    // ==================== Private ======================
    // ===================================================

    function _getAndValidateBalanceForAllForMarket(
        IIsolationModeTokenVaultV1 _vault,
        address _accountOwner,
        uint256 _accountNumber,
        uint256 _marketId
    ) private view returns (uint256) {
        IDolomiteStructs.Wei memory balanceWei = _vault.DOLOMITE_MARGIN().getAccountWei(
            IDolomiteStructs.AccountInfo({
                owner: _accountOwner,
                number: _accountNumber
            }),
            _marketId
        );
        Require.that(
            balanceWei.isPositive(),
            _FILE,
            "Invalid balance for transfer all"
        );
        return balanceWei.value;
    }

    function _checkAllowableCollateralMarket(
        IIsolationModeTokenVaultV1 _vault,
        address _accountOwner,
        uint256 _accountNumber,
        uint256 _marketId
    ) private view {
        // If the balance is positive, check that the collateral is for an allowable market. We use the Par balance
        // because, it uses less gas than getting the Wei balance, and we're only checking whether the balance is
        // positive.
        IDolomiteStructs.Par memory balancePar = _vault.DOLOMITE_MARGIN().getAccountPar(
            IDolomiteStructs.AccountInfo({
                owner: _accountOwner,
                number: _accountNumber
            }),
            _marketId
        );
        if (balancePar.isPositive()) {
            // Check the allowable collateral markets for the position:
            IIsolationModeVaultFactory vaultFactory = IIsolationModeVaultFactory(_vault.VAULT_FACTORY());
            uint256[] memory allowableCollateralMarketIds = vaultFactory.allowableCollateralMarketIds();
            uint256 allowableCollateralsLength = allowableCollateralMarketIds.length;
            if (allowableCollateralsLength != 0) {
                bool isAllowable = false;
                for (uint256 i = 0; i < allowableCollateralsLength; i++) {
                    if (allowableCollateralMarketIds[i] == _marketId) {
                        isAllowable = true;
                        break;
                    }
                }
                Require.that(
                    isAllowable,
                    _FILE,
                    "Market not allowed as collateral",
                    _marketId
                );
            }
        }
    }

    function _checkAllowableDebtMarket(
        IIsolationModeTokenVaultV1 _vault,
        address _accountOwner,
        uint256 _accountNumber,
        uint256 _marketId
    ) private view {
        // If the balance is negative, check that the debt is for an allowable market. We use the Par balance because,
        // it uses less gas than getting the Wei balance, and we're only checking whether the balance is negative.
        IDolomiteStructs.Par memory balancePar = _vault.DOLOMITE_MARGIN().getAccountPar(
            IDolomiteStructs.AccountInfo({
                owner: _accountOwner,
                number: _accountNumber
            }),
            _marketId
        );
        if (balancePar.isNegative()) {
            // Check the allowable debt markets for the position:
            IIsolationModeVaultFactory vaultFactory = IIsolationModeVaultFactory(_vault.VAULT_FACTORY());
            uint256[] memory allowableDebtMarketIds = vaultFactory.allowableDebtMarketIds();
            if (allowableDebtMarketIds.length != 0) {
                bool isAllowable = false;
                for (uint256 i = 0; i < allowableDebtMarketIds.length; i++) {
                    if (allowableDebtMarketIds[i] == _marketId) {
                        isAllowable = true;
                        break;
                    }
                }
                Require.that(
                    isAllowable,
                    _FILE,
                    "Market not allowed as debt",
                    _marketId
                );
            }
        }
    }

    function _checkMarketIdIsNotSelf(
        IIsolationModeTokenVaultV1 _vault,
        uint256 _marketId
    ) private view {
        Require.that(
            _marketId != _vault.marketId(),
            _FILE,
            "Invalid marketId",
            _marketId
        );
    }

    function _getAdjustedAccountValues(
        IDolomiteMargin _dolomiteMargin,
        BaseLiquidatorProxy.MarketInfo[] memory _marketInfos,
        IDolomiteStructs.AccountInfo memory _account,
        uint256[] memory _marketIds
    )
        internal
        view
        returns (
            IDolomiteStructs.MonetaryValue memory supplyValue,
            IDolomiteStructs.MonetaryValue memory borrowValue
        )
    {
        return _getAccountValues(
            _dolomiteMargin,
            _marketInfos,
            _account,
            _marketIds,
            /* _adjustForMarginPremiums = */ true
        );
    }

    function _getAccountValues(
        IDolomiteMargin _dolomiteMargin,
        BaseLiquidatorProxy.MarketInfo[] memory _marketInfos,
        IDolomiteStructs.AccountInfo memory _account,
        uint256[] memory _marketIds,
        bool _adjustForMarginPremiums
    )
        internal
        view
        returns (
            IDolomiteStructs.MonetaryValue memory,
            IDolomiteStructs.MonetaryValue memory
        )
    {
        IDolomiteStructs.MonetaryValue memory supplyValue = IDolomiteStructs.MonetaryValue(0);
        IDolomiteStructs.MonetaryValue memory borrowValue = IDolomiteStructs.MonetaryValue(0);
        for (uint256 i; i < _marketIds.length; ++i) {
            IDolomiteStructs.Par memory par = _dolomiteMargin.getAccountPar(_account, _marketIds[i]);
            BaseLiquidatorProxy.MarketInfo memory marketInfo = _binarySearch(_marketInfos, _marketIds[i]);
            IDolomiteStructs.Wei memory userWei = InterestIndexLib.parToWei(par, marketInfo.index);
            uint256 assetValue = userWei.value * marketInfo.price.value;
            IDolomiteStructs.Decimal memory marginPremium = DecimalLib.one();
            if (_adjustForMarginPremiums) {
                marginPremium = DecimalLib.onePlus(_dolomiteMargin.getMarketMarginPremium(_marketIds[i]));
            }
            if (userWei.sign) {
                supplyValue.value = supplyValue.value + DecimalLib.div(assetValue, marginPremium);
            } else {
                borrowValue.value = borrowValue.value + DecimalLib.mul(assetValue, marginPremium);
            }
        }
        return (supplyValue, borrowValue);
    }

    function _getMarketInfos(
        IDolomiteMargin _dolomiteMargin,
        uint256[] memory _solidMarketIds,
        uint256[] memory _liquidMarketIds
    ) internal view returns (BaseLiquidatorProxy.MarketInfo[] memory) {
        uint[] memory marketBitmaps = BitsLib.createBitmaps(_dolomiteMargin.getNumMarkets());
        uint256 marketsLength = 0;
        marketsLength = _addMarketsToBitmap(_solidMarketIds, marketBitmaps, marketsLength);
        marketsLength = _addMarketsToBitmap(_liquidMarketIds, marketBitmaps, marketsLength);

        uint256 counter = 0;
        BaseLiquidatorProxy.MarketInfo[] memory marketInfos = new BaseLiquidatorProxy.MarketInfo[](marketsLength);
        for (uint256 i; i < marketBitmaps.length && counter != marketsLength; ++i) {
            uint256 bitmap = marketBitmaps[i];
            while (bitmap != 0) {
                uint256 nextSetBit = BitsLib.getLeastSignificantBit(bitmap);
                uint256 marketId = BitsLib.getMarketIdFromBit(i, nextSetBit);

                marketInfos[counter++] = BaseLiquidatorProxy.MarketInfo({
                    marketId: marketId,
                    price: _dolomiteMargin.getMarketPrice(marketId),
                    index: _dolomiteMargin.getMarketCurrentIndex(marketId)
                });

                // unset the set bit
                bitmap = BitsLib.unsetBit(bitmap, nextSetBit);
            }
        }

        return marketInfos;
    }


    function _checkFromAccountNumberIsZero(uint256 _fromAccountNumber) private pure {
        Require.that(
            _fromAccountNumber == 0,
            _FILE,
            "Invalid fromAccountNumber",
            _fromAccountNumber
        );
    }

    function _checkToAccountNumberIsZero(uint256 _toAccountNumber) private pure {
        Require.that(
            _toAccountNumber == 0,
            _FILE,
            "Invalid toAccountNumber",
            _toAccountNumber
        );
    }

    function _checkBorrowAccountNumberIsNotZero(
        uint256 _borrowAccountNumber,
        bool _bypassAccountNumberCheck
    ) private pure {
        if (!_bypassAccountNumberCheck) {
            Require.that(
                _borrowAccountNumber != 0,
                _FILE,
                "Invalid borrowAccountNumber",
                _borrowAccountNumber
            );
        }
    }

    function _addMarketsToBitmap(
        uint256[] memory _markets,
        uint256[] memory _bitmaps,
        uint256 _marketsLength
    ) private pure returns (uint) {
        for (uint256 i; i < _markets.length; ++i) {
            if (!BitsLib.hasBit(_bitmaps, _markets[i])) {
                BitsLib.setBit(_bitmaps, _markets[i]);
                _marketsLength += 1;
            }
        }
        return _marketsLength;
    }

    function _binarySearch(
        BaseLiquidatorProxy.MarketInfo[] memory _markets,
        uint256 _marketId
    ) internal pure returns (BaseLiquidatorProxy.MarketInfo memory) {
        return _binarySearch(
            _markets,
            /* _beginInclusive = */ 0,
            _markets.length,
            _marketId
        );
    }

    function _binarySearch(
        BaseLiquidatorProxy.MarketInfo[] memory _markets,
        uint256 _beginInclusive,
        uint256 _endExclusive,
        uint256 _marketId
    ) internal pure returns (BaseLiquidatorProxy.MarketInfo memory) {
        uint256 len = _endExclusive - _beginInclusive;
        if (len == 0 || (len == 1 && _markets[_beginInclusive].marketId != _marketId)) {
            revert("BaseLiquidatorProxy: Market not found"); // solhint-disable-line reason-string
        }

        uint256 mid = _beginInclusive + len / 2;
        uint256 midMarketId = _markets[mid].marketId;
        if (_marketId < midMarketId) {
            return _binarySearch(
                _markets,
                _beginInclusive,
                mid,
                _marketId
            );
        } else if (_marketId > midMarketId) {
            return _binarySearch(
                _markets,
                mid + 1,
                _endExclusive,
                _marketId
            );
        } else {
            return _markets[mid];
        }
    }

    function _isCollateralized(
        uint256 _supplyValue,
        uint256 _borrowValue,
        IDolomiteStructs.Decimal memory _ratio
    )
        private
        pure
        returns (bool)
    {
        uint256 requiredMargin = DecimalLib.mul(_borrowValue, _ratio);
        return _supplyValue >= _borrowValue + requiredMargin;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ProxyContractHelpers } from "../../helpers/ProxyContractHelpers.sol";
import { IBorrowPositionProxyV2 } from "../../interfaces/IBorrowPositionProxyV2.sol";
import { IDolomiteRegistry } from "../../interfaces/IDolomiteRegistry.sol";
import { IGenericTraderProxyV1 } from "../../interfaces/IGenericTraderProxyV1.sol";
import { AccountBalanceLib } from "../../lib/AccountBalanceLib.sol";
import { IDolomiteMargin } from "../../protocol/interfaces/IDolomiteMargin.sol";
import { Require } from "../../protocol/lib/Require.sol";
import { IIsolationModeTokenVaultV1 } from "../interfaces/IIsolationModeTokenVaultV1.sol";
import { IIsolationModeVaultFactory } from "../interfaces/IIsolationModeVaultFactory.sol";
import { IsolationModeTokenVaultV1ActionsImpl } from "./impl/IsolationModeTokenVaultV1ActionsImpl.sol";


/**
 * @title   IsolationModeTokenVaultV1
 * @author  Dolomite
 *
 * @notice  Abstract implementation (for an upgradeable proxy) for wrapping tokens via a per-user vault that can be used
 *          with DolomiteMargin
 */
abstract contract IsolationModeTokenVaultV1 is IIsolationModeTokenVaultV1, ProxyContractHelpers {
    using SafeERC20 for IERC20;

    // ===================================================
    // ==================== Constants ====================
    // ===================================================

    bytes32 private constant _FILE = "IsolationModeTokenVaultV1";
    bytes32 private constant _IS_INITIALIZED_SLOT = bytes32(uint256(keccak256("eip1967.proxy.isInitialized")) - 1);
    bytes32 private constant _OWNER_SLOT = bytes32(uint256(keccak256("eip1967.proxy.owner")) - 1);
    bytes32 private constant _REENTRANCY_GUARD_SLOT = bytes32(uint256(keccak256("eip1967.proxy.reentrancyGuard")) - 1);
    bytes32 private constant _VAULT_FACTORY_SLOT = bytes32(uint256(keccak256("eip1967.proxy.vaultFactory")) - 1);

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    // =================================================
    // ================ Field Variables ================
    // =================================================

    /// @dev This is unused, but required to keep the storage slots the same
    uint256 private _reentrancyGuard;

    // ===================================================
    // ==================== Modifiers ====================
    // ===================================================

    modifier onlyVaultFactory(address _from) {
        _requireOnlyVaultFactory(_from);
        _;
    }

    modifier onlyVaultOwner(address _from) {
        _requireOnlyVaultOwner(_from);
        _;
    }

    modifier onlyVaultOwnerOrConverter(address _from) {
        _requireOnlyVaultOwnerOrConverter(_from);
        _;
    }

    modifier onlyVaultOwnerOrVaultFactory(address _from) {
        _requireOnlyVaultOwnerOrVaultFactory(_from);
        _;
    }

    modifier requireNotLiquidatable(uint256 _accountNumber) {
        _requireNotLiquidatable(_accountNumber);
        _;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly. Calling a `nonReentrant` function from
     *      another `nonReentrant` function is not supported. It is possible to prevent this from happening by making
     *      the `nonReentrant` function external, and making it call a `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    // ===================================================
    // ==================== Functions ====================
    // ===================================================

    function initialize() external {
        _initialize();
    }

    function depositIntoVaultForDolomiteMargin(
        uint256 _toAccountNumber,
        uint256 _amountWei
    )
    external
    nonReentrant
    onlyVaultOwnerOrVaultFactory(msg.sender) {
        _depositIntoVaultForDolomiteMargin(_toAccountNumber, _amountWei);
    }

    function withdrawFromVaultForDolomiteMargin(
        uint256 _fromAccountNumber,
        uint256 _amountWei
    )
    external
    nonReentrant
    onlyVaultOwner(msg.sender) {
        _withdrawFromVaultForDolomiteMargin(_fromAccountNumber, _amountWei);
    }

    function openBorrowPosition(
        uint256 _fromAccountNumber,
        uint256 _toAccountNumber,
        uint256 _amountWei
    )
    external
    payable
    nonReentrant
    onlyVaultOwner(msg.sender) {
        _checkMsgValue();
        _openBorrowPosition(_fromAccountNumber, _toAccountNumber, _amountWei);
    }

    function closeBorrowPositionWithUnderlyingVaultToken(
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber
    )
    external
    nonReentrant
    onlyVaultOwner(msg.sender) {
        _closeBorrowPositionWithUnderlyingVaultToken(_borrowAccountNumber, _toAccountNumber);
    }

    function closeBorrowPositionWithOtherTokens(
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber,
        uint256[] calldata _collateralMarketIds
    )
    external
    nonReentrant
    onlyVaultOwner(msg.sender) {
        _closeBorrowPositionWithOtherTokens(_borrowAccountNumber, _toAccountNumber, _collateralMarketIds);
    }

    function transferIntoPositionWithUnderlyingToken(
        uint256 _fromAccountNumber,
        uint256 _borrowAccountNumber,
        uint256 _amountWei
    )
    external
    nonReentrant
    onlyVaultOwner(msg.sender) {
        _transferIntoPositionWithUnderlyingToken(_fromAccountNumber, _borrowAccountNumber, _amountWei);
    }

    function transferIntoPositionWithOtherToken(
        uint256 _fromAccountNumber,
        uint256 _borrowAccountNumber,
        uint256 _marketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    )
    external
    nonReentrant
    onlyVaultOwner(msg.sender) {
        _transferIntoPositionWithOtherToken(
            _fromAccountNumber,
            _borrowAccountNumber,
            _marketId,
            _amountWei,
            _balanceCheckFlag
        );
    }

    function transferFromPositionWithUnderlyingToken(
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber,
        uint256 _amountWei
    )
    external
    nonReentrant
    onlyVaultOwner(msg.sender) {
        _transferFromPositionWithUnderlyingToken(_borrowAccountNumber, _toAccountNumber, _amountWei);
    }

    function transferFromPositionWithOtherToken(
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber,
        uint256 _marketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    )
    external
    nonReentrant
    onlyVaultOwner(msg.sender) {
        _transferFromPositionWithOtherToken(
            _borrowAccountNumber,
            _toAccountNumber,
            _marketId,
            _amountWei,
            _balanceCheckFlag
        );
    }

    function repayAllForBorrowPosition(
        uint256 _fromAccountNumber,
        uint256 _borrowAccountNumber,
        uint256 _marketId,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    )
    external
    nonReentrant
    onlyVaultOwner(msg.sender) {
        _repayAllForBorrowPosition(
            _fromAccountNumber,
            _borrowAccountNumber,
            _marketId,
            _balanceCheckFlag
        );
    }

    function openBorrowPositionAndSwapExactInputForOutput(
        uint256 _fromAccountNumber,
        uint256 _borrowAccountNumber,
        uint256[] calldata _marketIdsPath,
        uint256 _inputAmountWei,
        uint256 _minOutputAmountWei,
        IGenericTraderProxyV1.TraderParam[] calldata _tradersPath,
        IDolomiteMargin.AccountInfo[] calldata _makerAccounts,
        IGenericTraderProxyV1.UserConfig calldata _userConfig
    )
        external
        payable
        nonReentrant
        onlyVaultOwnerOrConverter(msg.sender)
    {
        _checkMsgValue();
        _openBorrowPosition(_fromAccountNumber, _borrowAccountNumber, /* _amountWei = */ 0);
        _addCollateralAndSwapExactInputForOutput(
            _fromAccountNumber,
            _borrowAccountNumber,
            _marketIdsPath,
            _inputAmountWei,
            _minOutputAmountWei,
            _tradersPath,
            _makerAccounts,
            _userConfig
        );
    }

    function addCollateralAndSwapExactInputForOutput(
        uint256 _fromAccountNumber,
        uint256 _borrowAccountNumber,
        uint256[] calldata _marketIdsPath,
        uint256 _inputAmountWei,
        uint256 _minOutputAmountWei,
        IGenericTraderProxyV1.TraderParam[] calldata _tradersPath,
        IDolomiteMargin.AccountInfo[] calldata _makerAccounts,
        IGenericTraderProxyV1.UserConfig calldata _userConfig
    )
    external
    payable
    nonReentrant
    onlyVaultOwnerOrConverter(msg.sender) {
        _checkMsgValue();
        _addCollateralAndSwapExactInputForOutput(
            _fromAccountNumber,
            _borrowAccountNumber,
            _marketIdsPath,
            _inputAmountWei,
            _minOutputAmountWei,
            _tradersPath,
            _makerAccounts,
            _userConfig
        );
    }

    function swapExactInputForOutputAndRemoveCollateral(
        uint256 _toAccountNumber,
        uint256 _borrowAccountNumber,
        uint256[] calldata _marketIdsPath,
        uint256 _inputAmountWei,
        uint256 _minOutputAmountWei,
        IGenericTraderProxyV1.TraderParam[] calldata _tradersPath,
        IDolomiteMargin.AccountInfo[] calldata _makerAccounts,
        IGenericTraderProxyV1.UserConfig calldata _userConfig
    )
    external
    payable
    nonReentrant
    onlyVaultOwnerOrConverter(msg.sender) {
        _checkMsgValue();
        _swapExactInputForOutputAndRemoveCollateral(
            _toAccountNumber,
            _borrowAccountNumber,
            _marketIdsPath,
            _inputAmountWei,
            _minOutputAmountWei,
            _tradersPath,
            _makerAccounts,
            _userConfig
        );
    }


    function swapExactInputForOutput(
        uint256 _tradeAccountNumber,
        uint256[] calldata _marketIdsPath,
        uint256 _inputAmountWei,
        uint256 _minOutputAmountWei,
        IGenericTraderProxyV1.TraderParam[] calldata _tradersPath,
        IDolomiteMargin.AccountInfo[] calldata _makerAccounts,
        IGenericTraderProxyV1.UserConfig calldata _userConfig
    )
    external
    payable
    nonReentrant
    onlyVaultOwnerOrConverter(msg.sender) {
        _checkMsgValue();
        SwapExactInputForOutputParams memory params = SwapExactInputForOutputParams({
            tradeAccountNumber: _tradeAccountNumber,
            marketIdsPath: _marketIdsPath,
            inputAmountWei: _inputAmountWei,
            minOutputAmountWei: _minOutputAmountWei,
            tradersPath: _tradersPath,
            makerAccounts: _makerAccounts,
            userConfig: _userConfig
        });
        _swapExactInputForOutput(params);
    }

    // ======== Public functions ========

    function executeDepositIntoVault(
        address _from,
        uint256 _amount
    )
    public
    virtual
    onlyVaultFactory(msg.sender) {
        IERC20(UNDERLYING_TOKEN()).safeTransferFrom(_from, address(this), _amount);
    }

    function executeWithdrawalFromVault(
        address _recipient,
        uint256 _amount
    )
    public
    virtual
    onlyVaultFactory(msg.sender) {
        assert(_recipient != address(this));
        IERC20(UNDERLYING_TOKEN()).safeTransfer(_recipient, _amount);
    }

    function UNDERLYING_TOKEN() public view returns (address) {
        return IIsolationModeVaultFactory(VAULT_FACTORY()).UNDERLYING_TOKEN();
    }

    function DOLOMITE_MARGIN() public view returns (IDolomiteMargin) {
        return IIsolationModeVaultFactory(VAULT_FACTORY()).DOLOMITE_MARGIN();
    }

    function BORROW_POSITION_PROXY() public view returns (IBorrowPositionProxyV2) {
        return IIsolationModeVaultFactory(VAULT_FACTORY()).BORROW_POSITION_PROXY();
    }

    function VAULT_FACTORY() public view returns (address) {
        return _getAddress(_VAULT_FACTORY_SLOT);
    }

    function OWNER() public override view returns (address) {
        return _getAddress(_OWNER_SLOT);
    }

    function marketId() public view returns (uint256) {
        return IIsolationModeVaultFactory(VAULT_FACTORY()).marketId();
    }

    function underlyingBalanceOf() public override virtual view returns (uint256) {
        return IERC20(UNDERLYING_TOKEN()).balanceOf(address(this));
    }

    function dolomiteRegistry() public override virtual view returns (IDolomiteRegistry);

    // ============ Internal Functions ============

    function _initialize() internal virtual {
        Require.that(
            _getUint256(_IS_INITIALIZED_SLOT) == 0,
            _FILE,
            "Already initialized"
        );

        _setUint256(_REENTRANCY_GUARD_SLOT, _NOT_ENTERED);
    }

    function _depositIntoVaultForDolomiteMargin(
        uint256 _toAccountNumber,
        uint256 _amountWei
    ) internal virtual {
        IsolationModeTokenVaultV1ActionsImpl.depositIntoVaultForDolomiteMargin(
            /* _vault = */ this,
            _toAccountNumber,
            _amountWei
        );
    }

    function _withdrawFromVaultForDolomiteMargin(
        uint256 _fromAccountNumber,
        uint256 _amountWei
    ) internal virtual {
        IsolationModeTokenVaultV1ActionsImpl.withdrawFromVaultForDolomiteMargin(
            /* _vault = */ this,
            _fromAccountNumber,
            _amountWei
        );
    }

    function _openBorrowPosition(
        uint256 _fromAccountNumber,
        uint256 _toAccountNumber,
        uint256 _amountWei
    )
        internal
        virtual
    {
        IsolationModeTokenVaultV1ActionsImpl.openBorrowPosition(
            /* _vault = */ this,
            _fromAccountNumber,
            _toAccountNumber,
            _amountWei
        );
    }

    function _closeBorrowPositionWithUnderlyingVaultToken(
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber
    )
        internal
        virtual
    {
        IsolationModeTokenVaultV1ActionsImpl.closeBorrowPositionWithUnderlyingVaultToken(
            /* _vault = */ this,
            _borrowAccountNumber,
            _toAccountNumber
        );
    }

    function _closeBorrowPositionWithOtherTokens(
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber,
        uint256[] calldata _collateralMarketIds
    )
        internal
        virtual
    {
        IsolationModeTokenVaultV1ActionsImpl.closeBorrowPositionWithOtherTokens(
            /* _vault = */ this,
            _borrowAccountNumber,
            _toAccountNumber,
            _collateralMarketIds
        );
    }

    function _transferIntoPositionWithUnderlyingToken(
        uint256 _fromAccountNumber,
        uint256 _borrowAccountNumber,
        uint256 _amountWei
    )
        internal
        virtual
    {
        IsolationModeTokenVaultV1ActionsImpl.transferIntoPositionWithUnderlyingToken(
            /* _vault = */ this,
            _fromAccountNumber,
            _borrowAccountNumber,
            _amountWei
        );
    }

    function _transferIntoPositionWithOtherToken(
        uint256 _fromAccountNumber,
        uint256 _borrowAccountNumber,
        uint256 _marketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    )
        internal
        virtual
    {
        IsolationModeTokenVaultV1ActionsImpl.transferIntoPositionWithOtherToken(
            /* _vault = */ this,
            _fromAccountNumber,
            _borrowAccountNumber,
            _marketId,
            _amountWei,
            _balanceCheckFlag,
            /* _checkAllowableCollateralMarketFlag =  */ true,
            /* _bypassAccountNumberCheck = */ false
        );
    }

    function _transferFromPositionWithUnderlyingToken(
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber,
        uint256 _amountWei
    )
        internal
        virtual
    {
        IsolationModeTokenVaultV1ActionsImpl.transferFromPositionWithUnderlyingToken(
            /* _vault = */ this,
            _borrowAccountNumber,
            _toAccountNumber,
            _amountWei
        );
    }

    function _transferFromPositionWithOtherToken(
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber,
        uint256 _marketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    )
        virtual
        internal
    {
        IsolationModeTokenVaultV1ActionsImpl.transferFromPositionWithOtherToken(
            /* _vault = */ this,
            _borrowAccountNumber,
            _toAccountNumber,
            _marketId,
            _amountWei,
            _balanceCheckFlag,
            /* _bypassAccountNumberCheck = */ false
        );
    }

    function _repayAllForBorrowPosition(
        uint256 _fromAccountNumber,
        uint256 _borrowAccountNumber,
        uint256 _marketId,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    )
        internal
        virtual
    {
        IsolationModeTokenVaultV1ActionsImpl.repayAllForBorrowPosition(
            /* _vault = */ this,
            _fromAccountNumber,
            _borrowAccountNumber,
            _marketId,
            _balanceCheckFlag
        );
    }

    function _addCollateralAndSwapExactInputForOutput(
        uint256 _fromAccountNumber,
        uint256 _borrowAccountNumber,
        uint256[] calldata _marketIdsPath,
        uint256 _inputAmountWei,
        uint256 _minOutputAmountWei,
        IGenericTraderProxyV1.TraderParam[] memory _tradersPath,
        IDolomiteMargin.AccountInfo[] memory _makerAccounts,
        IGenericTraderProxyV1.UserConfig memory _userConfig
    ) internal virtual {
        IsolationModeTokenVaultV1ActionsImpl.addCollateralAndSwapExactInputForOutput(
            /* _vault = */ this,
            _fromAccountNumber,
            _borrowAccountNumber,
            _marketIdsPath,
            _inputAmountWei,
            _minOutputAmountWei,
            _tradersPath,
            _makerAccounts,
            _userConfig
        );
    }

    function _swapExactInputForOutputAndRemoveCollateral(
        uint256 _toAccountNumber,
        uint256 _borrowAccountNumber,
        uint256[] calldata _marketIdsPath,
        uint256 _inputAmountWei,
        uint256 _minOutputAmountWei,
        IGenericTraderProxyV1.TraderParam[] memory _tradersPath,
        IDolomiteMargin.AccountInfo[] memory _makerAccounts,
        IGenericTraderProxyV1.UserConfig memory _userConfig
    )
        internal
        virtual
    {
        IsolationModeTokenVaultV1ActionsImpl.swapExactInputForOutputAndRemoveCollateral(
            /* _vault = */ this,
            _toAccountNumber,
            _borrowAccountNumber,
            _marketIdsPath,
            _inputAmountWei,
            _minOutputAmountWei,
            _tradersPath,
            _makerAccounts,
            _userConfig
        );
    }

    function _swapExactInputForOutput(
        SwapExactInputForOutputParams memory _params
    )
        internal
        virtual
    {
        IsolationModeTokenVaultV1ActionsImpl.swapExactInputForOutput(
            /* _vault = */ this,
            _params.tradeAccountNumber,
            _params.marketIdsPath,
            _params.inputAmountWei,
            _params.minOutputAmountWei,
            _params.tradersPath,
            _params.makerAccounts,
            _params.userConfig,
            /* _checkOutputMarketIdFlag = */ true,
            /* _bypassAccountNumberCheck = */ false
        );
    }

    function _requireOnlyVaultFactory(address _from) internal view {
        Require.that(
            _from == address(VAULT_FACTORY()),
            _FILE,
            "Only factory can call",
            _from
        );
    }

    function _requireOnlyVaultOwner(address _from) internal virtual view {
        Require.that(
            _from == OWNER(),
            _FILE,
            "Only owner can call",
            _from
        );
    }

    function _requireOnlyVaultOwnerOrConverter(address _from) internal virtual view {
        Require.that(
            _from == address(OWNER())
                || IIsolationModeVaultFactory(VAULT_FACTORY()).isTokenConverterTrusted(_from),
            _FILE,
            "Only owner or converter can call",
            _from
        );
    }

    function _requireOnlyVaultOwnerOrVaultFactory(address _from) internal virtual view {
        Require.that(
            _from == address(OWNER()) || _from == VAULT_FACTORY(),
            _FILE,
            "Only owner or factory can call",
            _from
        );
    }

    function _requireOnlyConverter(address _from) internal virtual view {
        Require.that(
            IIsolationModeVaultFactory(VAULT_FACTORY()).isTokenConverterTrusted(_from),
            _FILE,
            "Only converter can call",
            _from
        );
    }

    function _requireNotLiquidatable(uint256 _accountNumber) internal view {
        IsolationModeTokenVaultV1ActionsImpl.validateIsNotLiquidatable(
            /* _vault = */ this,
            _accountNumber
        );
    }

    /**
     *  Called within `swapExactInputForOutput` to check that the caller send the right amount of ETH with the
     *  transaction.
     */
    function _checkMsgValue() internal virtual view {
        Require.that(
            msg.value == 0,
            _FILE,
            "Cannot send ETH"
        );
    }

    // ===========================================
    // ============ Private Functions ============
    // ===========================================

    function _nonReentrantBefore() private {
        // @notice:  This MUST stay as `value != _ENTERED` otherwise it will DOS old vaults that don't have the
        //          `initialize` fix
        Require.that(
            _getUint256(_REENTRANCY_GUARD_SLOT) != _ENTERED,
            _FILE,
            "Reentrant call"
        );

        // Any calls to nonReentrant after this point will fail
        _setUint256(_REENTRANCY_GUARD_SLOT, _ENTERED);
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see https://eips.ethereum.org/EIPS/eip-2200)
        _setUint256(_REENTRANCY_GUARD_SLOT, _NOT_ENTERED);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IsolationModeTokenVaultV1 } from "./IsolationModeTokenVaultV1.sol";
import { AccountBalanceLib } from "../../lib/AccountBalanceLib.sol";
import { IDolomiteMargin } from "../../protocol/interfaces/IDolomiteMargin.sol";
import { IDolomiteStructs } from "../../protocol/interfaces/IDolomiteStructs.sol";
import { Require } from "../../protocol/lib/Require.sol";
import { TypesLib } from "../../protocol/lib/TypesLib.sol";
import { IIsolationModeTokenVaultV1WithPausable } from "../interfaces/IIsolationModeTokenVaultV1WithPausable.sol";

/**
 * @title   IsolationModeTokenVaultV1WithPausable
 * @author  Dolomite
 *
 * @notice  An abstract implementation of IsolationModeTokenVaultV1 that disallows borrows if the ecosystem integration
 *          is paused.
 */
abstract contract IsolationModeTokenVaultV1WithPausable is
    IIsolationModeTokenVaultV1WithPausable,
    IsolationModeTokenVaultV1
{
    using TypesLib for IDolomiteMargin.Par;
    using TypesLib for IDolomiteMargin.Wei;

    // ===================================================
    // ==================== Constants ====================
    // ===================================================

    bytes32 private constant _FILE = "IsolationModeVaultV1Pausable"; // shortened to fit in 32 bytes

    // ===================================================
    // ==================== Modifiers ====================
    // ===================================================

    modifier _openBorrowPositionPausableValidator(
        uint256 _fromAccountNumber,
        uint256 _toAccountNumber,
        uint256 _amountWei
    ) {
        _requireExternalRedemptionNotPaused();
        _;
    }

    modifier _closeBorrowPositionWithOtherTokensPausableValidator(
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber,
        uint256[] calldata _collateralMarketIds
    ) {
        _;
        if (isExternalRedemptionPaused()) {
            _requireNumberOfMarketsWithDebtIsZero(_borrowAccountNumber);
        }
    }

    modifier _transferIntoPositionWithUnderlyingTokenPausableValidator(
        uint256 _fromAccountNumber,
        uint256 _borrowAccountNumber,
        uint256 _amountWei
    ) {
        _requireExternalRedemptionNotPaused();
        _;
    }

    modifier _transferFromPositionWithOtherTokenPausableValidator(
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber,
        uint256 _marketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) {
        IDolomiteMargin.Par memory valueBefore = DOLOMITE_MARGIN().getAccountPar(
            IDolomiteStructs.AccountInfo({
                owner: address(this),
                number: _borrowAccountNumber
            }),
            _marketId
        );

        _;

        if (isExternalRedemptionPaused()) {
            Require.that(
                valueBefore.isPositive(),
                _FILE,
                "Cannot lever up when paused",
                _marketId
            );

            // If redemptions are paused (preventing liquidations), the user cannot decrease collateralization.
            // If there is no debt markets, the user can can withdraw without affecting collateralization (it's ∞)
            _requireNumberOfMarketsWithDebtIsZero(_borrowAccountNumber);
        }
    }

    modifier _swapExactInputForOutputPausableValidator(
        uint256 _tradeAccountNumber,
        uint256[] memory _marketIdsPath,
        uint256 _inputAmountWei
    ) {
        bool isPaused = isExternalRedemptionPaused();

        IDolomiteMargin.Wei memory outputBalanceBefore;
        IDolomiteStructs.AccountInfo memory tradeAccount = IDolomiteStructs.AccountInfo({
            owner: address(this),
            number: _tradeAccountNumber
        });
        if (isPaused) {
            uint256 outputMarket = _marketIdsPath[_marketIdsPath.length - 1];
            // If the ecosystem is paused, we cannot swap into more of the irredeemable asset
            Require.that(
                outputMarket != marketId(),
                _FILE,
                "Cannot zap to market when paused",
                outputMarket
            );
            outputBalanceBefore = DOLOMITE_MARGIN().getAccountWei(tradeAccount, outputMarket);
            Require.that(
                outputBalanceBefore.isNegative(),
                _FILE,
                "Zaps can only repay when paused"
            );
        }

        _;

        if (isPaused) {
            IDolomiteMargin dolomiteMargin = DOLOMITE_MARGIN();
            uint256 inputMarket = _marketIdsPath[0];
            uint256 outputMarket = _marketIdsPath[_marketIdsPath.length - 1];
            // we don't need Wei here, and using Par saves gas costs
            IDolomiteMargin.Par memory inputBalanceAfter = dolomiteMargin.getAccountPar(
                tradeAccount,
                inputMarket
            );
            Require.that(
                inputBalanceAfter.isPositive() || inputBalanceAfter.value == 0,
                _FILE,
                "Cannot lever up when paused",
                inputMarket
            );

            IDolomiteMargin.Wei memory outputBalanceAfter = dolomiteMargin.getAccountWei(tradeAccount, outputMarket);
            IDolomiteMargin.Wei memory outputDelta = outputBalanceAfter.sub(outputBalanceBefore);

            uint256 inputValue = _inputAmountWei * dolomiteMargin.getMarketPrice(inputMarket).value;
            uint256 outputDeltaValue = outputDelta.value * dolomiteMargin.getMarketPrice(outputMarket).value;
            uint256 slippageNumerator = dolomiteRegistry().slippageToleranceForPauseSentinel();
            uint256 slippageDenominator = dolomiteRegistry().slippageToleranceForPauseSentinelBase();
            // Confirm the user is doing a fair trade and there is not more than the acceptable slippage while paused
            Require.that(
                outputDeltaValue >= inputValue - (inputValue * slippageNumerator / slippageDenominator),
                _FILE,
                "Unacceptable trade when paused"
            );
        }
    }

    // ===================================================
    // ==================== Functions ====================
    // ===================================================

    /**
     * @return  true if redemptions (conversion) from this isolated token to its underlying are paused or are in a
     *          distressed state. Resolving this function to true actives the Pause Sentinel, which prevents further
     *          contamination of this market across Dolomite.
     */
    function isExternalRedemptionPaused() public virtual view returns (bool);

    /// @dev   Cannot further collateralize a position with underlying, when underlying is paused
    function _openBorrowPosition(
        uint256 _fromAccountNumber,
        uint256 _toAccountNumber,
        uint256 _amountWei
    )
        internal
        virtual
        override
        _openBorrowPositionPausableValidator(
            _fromAccountNumber,
            _toAccountNumber,
            _amountWei
        )
    {
        super._openBorrowPosition(
            _fromAccountNumber,
            _toAccountNumber,
            _amountWei
        );
    }

    /// @dev   Cannot reduce collateralization of a position when underlying is paused
    function _closeBorrowPositionWithOtherTokens(
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber,
        uint256[] calldata _collateralMarketIds
    )
        internal
        virtual
        override
        _closeBorrowPositionWithOtherTokensPausableValidator(
            _borrowAccountNumber,
            _toAccountNumber,
            _collateralMarketIds
        )
    {
        super._closeBorrowPositionWithOtherTokens(
            _borrowAccountNumber,
            _toAccountNumber,
            _collateralMarketIds
        );
    }

    /// @dev   Cannot further collateralize a position with underlying, when underlying is paused
    function _transferIntoPositionWithUnderlyingToken(
        uint256 _fromAccountNumber,
        uint256 _borrowAccountNumber,
        uint256 _amountWei
    )
        internal
        virtual
        override
        _transferIntoPositionWithUnderlyingTokenPausableValidator(
            _fromAccountNumber,
            _borrowAccountNumber,
            _amountWei
        )
    {
        super._transferIntoPositionWithUnderlyingToken(
            _fromAccountNumber,
            _borrowAccountNumber,
            _amountWei
        );
    }

    /// @dev   Cannot reduce collateralization by withdrawing other tokens, when underlying is paused
    function _transferFromPositionWithOtherToken(
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber,
        uint256 _marketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    )
        internal
        virtual
        override
        _transferFromPositionWithOtherTokenPausableValidator(
            _borrowAccountNumber,
            _toAccountNumber,
            _marketId,
            _amountWei,
            _balanceCheckFlag
        )
    {
        super._transferFromPositionWithOtherToken(
            _borrowAccountNumber,
            _toAccountNumber,
            _marketId,
            _amountWei,
            _balanceCheckFlag
        );
    }

    function _swapExactInputForOutput(
        SwapExactInputForOutputParams memory _params
    )
        internal
        virtual
        override
        _swapExactInputForOutputPausableValidator(
            _params.tradeAccountNumber,
            _params.marketIdsPath,
            _params.inputAmountWei
        )
    {
        IsolationModeTokenVaultV1._swapExactInputForOutput(
            _params
        );
    }

    // ===================================================
    // =============== Private Functions =================
    // ===================================================

    function _requireExternalRedemptionNotPaused() private view {
        Require.that(
            !isExternalRedemptionPaused(),
            _FILE,
            "Cannot execute when paused"
        );
    }

    function _requireNumberOfMarketsWithDebtIsZero(uint256 _borrowAccountNumber) private view {
        uint256 numberOfMarketsWithDebt = DOLOMITE_MARGIN().getAccountNumberOfMarketsWithDebt(
            IDolomiteStructs.AccountInfo({
                owner: address(this),
                number: _borrowAccountNumber
            })
        );
        // If the user has debt, withdrawing collateral decreases their collateralization
        Require.that(
            numberOfMarketsWithDebt == 0,
            _FILE,
            "Cannot lever up when paused"
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { OnlyDolomiteMargin } from "../../helpers/OnlyDolomiteMargin.sol";
import { IDolomiteRegistry } from "../../interfaces/IDolomiteRegistry.sol";
import { ILiquidatorAssetRegistry } from "../../interfaces/ILiquidatorAssetRegistry.sol";
import { Require } from "../../protocol/lib/Require.sol";
import { IIsolationModeVaultFactory } from "../interfaces/IIsolationModeVaultFactory.sol";


/**
 * @title   IsolationModeTraderBaseV2
 * @author  Dolomite
 *
 * @notice  Abstract contract for selling a vault token into the underlying token. Must be set as a token converter by
 *          the DolomiteMargin admin on the corresponding `IsolationModeVaultFactory` token to be used.
 */
abstract contract IsolationModeTraderBaseV2 is OnlyDolomiteMargin {

    // ======================== Constants ========================

    bytes32 private constant _FILE = "IsolationModeTraderBaseV2";

    // ======================== Field Variables ========================

    IIsolationModeVaultFactory public immutable VAULT_FACTORY; // solhint-disable-line var-name-mixedcase
    IDolomiteRegistry public immutable DOLOMITE_REGISTRY; // solhint-disable-line var-name-mixedcase

    // ========================= Modifiers =========================

    modifier onlyGenericTraderOrTrustedLiquidator(address _from) {
        _validateIsGenericTraderOrTrustedLiquidator(_from);
        _;
    }

    // ======================== Constructor ========================

    constructor(
        address _vaultFactory,
        address _dolomiteMargin,
        address _dolomiteRegistry
    )
    OnlyDolomiteMargin(
        _dolomiteMargin
    ) {
        VAULT_FACTORY = IIsolationModeVaultFactory(_vaultFactory);
        DOLOMITE_REGISTRY = IDolomiteRegistry(_dolomiteRegistry);
    }

    // ========================= Internal Functions ========================

    function _isValidLiquidator(
        address _from,
        uint256 _marketId
    ) internal view returns (bool) {
        ILiquidatorAssetRegistry liquidatorRegistry = DOLOMITE_REGISTRY.liquidatorAssetRegistry();
        return liquidatorRegistry.isAssetWhitelistedForLiquidation(_marketId, _from)
            && liquidatorRegistry.getLiquidatorsForAsset(_marketId).length > 0;
    }

    // ========================= Private Functions ========================

    function _validateIsGenericTraderOrTrustedLiquidator(address _from) private view {
        uint256 marketId = DOLOMITE_MARGIN().getMarketIdByTokenAddress(address(VAULT_FACTORY));
        Require.that(
            _isValidLiquidator(_from, marketId) || _from == address(DOLOMITE_REGISTRY.genericTraderProxy()),
            _FILE,
            "Caller is not authorized",
            _from
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IsolationModeTraderBaseV2 } from "./IsolationModeTraderBaseV2.sol";
import { AccountActionLib } from "../../lib/AccountActionLib.sol";
import { IDolomiteMargin } from "../../protocol/interfaces/IDolomiteMargin.sol";
import { IDolomiteMarginCallee } from "../../protocol/interfaces/IDolomiteMarginCallee.sol";
import { IDolomiteStructs } from "../../protocol/interfaces/IDolomiteStructs.sol";
import { Require } from "../../protocol/lib/Require.sol";
import { IIsolationModeTokenVaultV1 } from "../interfaces/IIsolationModeTokenVaultV1.sol";
import { IIsolationModeUnwrapperTraderV2 } from "../interfaces/IIsolationModeUnwrapperTraderV2.sol";


/**
 * @title   IsolationModeUnwrapperTraderV2
 * @author  Dolomite
 *
 * @notice  Abstract contract for selling a vault token into the underlying token. Must be set as a token converter by
 *          the DolomiteMargin admin on the corresponding `IsolationModeVaultFactory` token to be used.
 */
abstract contract IsolationModeUnwrapperTraderV2 is
    IIsolationModeUnwrapperTraderV2,
    IDolomiteMarginCallee,
    IsolationModeTraderBaseV2
{
    using SafeERC20 for IERC20;

    // ======================== Constants ========================

    bytes32 private constant _FILE = "IsolationModeUnwrapperTraderV2";
    uint256 private constant _ACTIONS_LENGTH = 2;

    // ======================== Constructor ========================

    constructor(
        address _vaultFactory,
        address _dolomiteMargin,
        address _dolomiteRegistry
    )
    IsolationModeTraderBaseV2(
        _vaultFactory,
        _dolomiteMargin,
        _dolomiteRegistry
    ) {
        // solhint-disable-previous-line no-empty-blocks
    }

    // ======================== External Functions ========================

    function callFunction(
        address _sender,
        IDolomiteStructs.AccountInfo calldata _accountInfo,
        bytes calldata _data
    )
    external
    onlyDolomiteMargin(msg.sender)
    onlyGenericTraderOrTrustedLiquidator(_sender) {
        _callFunction(_sender, _accountInfo, _data);
    }

    function exchange(
        address _tradeOriginator,
        address _receiver,
        address _outputToken,
        address _inputToken,
        uint256 _inputAmount,
        bytes calldata _orderData
    )
    external
    onlyDolomiteMargin(msg.sender)
    returns (uint256) {
        Require.that(
            _inputToken == address(VAULT_FACTORY),
            _FILE,
            "Invalid input token",
            _inputToken
        );
        Require.that(
            isValidOutputToken(_outputToken),
            _FILE,
            "Invalid output token",
            _outputToken
        );
        Require.that(
            _inputAmount > 0,
            _FILE,
            "Invalid input amount"
        );

        (uint256 minOutputAmount, bytes memory extraOrderData) = abi.decode(_orderData, (uint256, bytes));

        {
            uint256 balance = IERC20(VAULT_FACTORY.UNDERLYING_TOKEN()).balanceOf(address(this));
            Require.that(
                balance >= _inputAmount,
                _FILE,
                "Insufficient input token",
                balance,
                _inputAmount
            );
        }

        uint256 outputAmount = _exchangeUnderlyingTokenToOutputToken(
            _tradeOriginator,
            _receiver,
            _outputToken,
            minOutputAmount,
            address(VAULT_FACTORY),
            _inputAmount,
            extraOrderData
        );
        Require.that(
            outputAmount >= minOutputAmount,
            _FILE,
            "Insufficient output amount",
            outputAmount,
            minOutputAmount
        );

        IERC20(_outputToken).safeApprove(_receiver, outputAmount);

        return outputAmount;
    }

    function token() external view returns (address) {
        return address(VAULT_FACTORY);
    }

    function createActionsForUnwrapping(
        CreateActionsForUnwrappingParams calldata _params
    )
        external
        view
        returns (IDolomiteMargin.ActionArgs[] memory)
    {
        Require.that(
            DOLOMITE_MARGIN().getMarketTokenAddress(_params.inputMarket) == address(VAULT_FACTORY),
            _FILE,
            "Invalid input market",
            _params.inputMarket
        );
        Require.that(
            isValidOutputToken(DOLOMITE_MARGIN().getMarketTokenAddress(_params.outputMarket)),
            _FILE,
            "Invalid output market",
            _params.outputMarket
        );

        IDolomiteMargin.ActionArgs[] memory actions = new IDolomiteMargin.ActionArgs[](_ACTIONS_LENGTH);

        // Transfer the IsolationMode tokens to this contract. Do this by enqueuing a transfer via the call to
        // `enqueueTransferFromDolomiteMargin` in `callFunction` on this contract.
        actions[0] = AccountActionLib.encodeCallAction(
            _params.primaryAccountId,
            /* _callee */ address(this),
            /* _callData = */ abi.encode(
                _params.inputAmount,
                _params.otherAccountOwner,
                _params.otherAccountNumber
            )
        );

        actions[1] = AccountActionLib.encodeExternalSellAction(
            _params.primaryAccountId,
            _params.inputMarket,
            _params.outputMarket,
            /* _trader = */ address(this),
            /* _amountInWei = */ _params.inputAmount,
            /* _amountOutMinWei = */ _params.minOutputAmount,
            _params.orderData
        );

        return actions;
    }

    function actionsLength() external virtual pure returns (uint256) {
        return _ACTIONS_LENGTH;
    }

    function isValidOutputToken(address _outputToken) public override virtual view returns (bool);

    function getExchangeCost(
        address _inputToken,
        address _outputToken,
        uint256 _desiredInputAmount,
        bytes memory _orderData
    )
    public
    override
    view
    returns (uint256) {
        Require.that(
            _inputToken == address(VAULT_FACTORY),
            _FILE,
            "Invalid input token",
            _inputToken
        );
        Require.that(
            isValidOutputToken(_outputToken),
            _FILE,
            "Invalid output token",
            _outputToken
        );
        Require.that(
            _desiredInputAmount > 0,
            _FILE,
            "Invalid desired input amount"
        );

        return _getExchangeCost(
            _inputToken,
            _outputToken,
            _desiredInputAmount,
            _orderData
        );
    }

    // ============ Internal Functions ============

    function _callFunction(
        address /* _sender */,
        IDolomiteStructs.AccountInfo calldata _accountInfo,
        bytes calldata _data
    )
    internal
    virtual {
        // This is called after a liquidation has occurred. We need to transfer excess tokens to the liquidator's
        // designated recipient
        (uint256 transferAmount, address vaultOwner, /* uint256 vaultSubAccount */) = abi.decode(
            _data,
            (uint256, address, uint256)
        );

        Require.that(
            VAULT_FACTORY.getAccountByVault(vaultOwner) != address(0),
            _FILE,
            "Account owner is not a vault",
            vaultOwner
        );

        if (transferAmount == type(uint256).max) {
            uint256 marketId = DOLOMITE_MARGIN().getMarketIdByTokenAddress(address(VAULT_FACTORY));
            /// @note   Account wei cannot be negative for Isolation Mode assets
            /// @note   We can safely get the _accountInfo's (the Zap account for ordinary unwraps or Solid account for
            ///         liquidations) balance here without worrying about read-only reentrancy
            IDolomiteStructs.Wei memory balanceWei = DOLOMITE_MARGIN().getAccountWei(_accountInfo, marketId);
            assert(balanceWei.sign || balanceWei.value == 0);

            transferAmount = balanceWei.value;
        }
        Require.that(
            transferAmount > 0,
            _FILE,
            "Invalid transfer amount"
        );

        uint256 underlyingBalanceOf = IIsolationModeTokenVaultV1(vaultOwner).underlyingBalanceOf();
        Require.that(
            underlyingBalanceOf >= transferAmount,
            _FILE,
            "Insufficient balance",
            underlyingBalanceOf,
            transferAmount
        );

        VAULT_FACTORY.enqueueTransferFromDolomiteMargin(vaultOwner, transferAmount);
    }

    /**
     * @notice Performs the exchange from the Isolation Mode's underlying token to `_outputToken`.
     */
    function _exchangeUnderlyingTokenToOutputToken(
        address _tradeOriginator,
        address _receiver,
        address _outputToken,
        uint256 _minOutputAmount,
        address _inputToken,
        uint256 _inputAmount,
        bytes memory _extraOrderData
    ) internal virtual returns (uint256);

    function _getExchangeCost(
        address _inputToken,
        address _outputToken,
        uint256 _desiredInputAmount,
        bytes memory _orderData
    ) internal virtual view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { IsolationModeUpgradeableProxy } from "../IsolationModeUpgradeableProxy.sol";
import { MinimalERC20 } from "../../general/MinimalERC20.sol";
import { OnlyDolomiteMargin } from "../../helpers/OnlyDolomiteMargin.sol";
import { IBorrowPositionProxyV2 } from "../../interfaces/IBorrowPositionProxyV2.sol";
import { AccountActionLib } from "../../lib/AccountActionLib.sol";
import { AccountBalanceLib } from "../../lib/AccountBalanceLib.sol";
import { IDolomiteStructs } from "../../protocol/interfaces/IDolomiteStructs.sol";
import { Require } from "../../protocol/lib/Require.sol";
import { IIsolationModeTokenVaultV1 } from "../interfaces/IIsolationModeTokenVaultV1.sol";
import { IIsolationModeUpgradeableProxy } from "../interfaces/IIsolationModeUpgradeableProxy.sol";
import { IIsolationModeVaultFactory } from "../interfaces/IIsolationModeVaultFactory.sol";


/**
 * @title   IsolationModeVaultFactory
 * @author  Dolomite
 *
 * @notice  Abstract contract for wrapping tokens via a per-user vault that credits a user's balance within
 *          DolomiteMargin
 */
abstract contract IsolationModeVaultFactory is
    IIsolationModeVaultFactory,
    OnlyDolomiteMargin,
    MinimalERC20
{

    // ===================================================
    // ==================== Constants ====================
    // ===================================================

    bytes32 private constant _FILE = "IsolationModeVaultFactory";

    // ==================================================
    // ================ Immutable Fields ================
    // ==================================================

    address public immutable override UNDERLYING_TOKEN; // solhint-disable-line var-name-mixedcase
    IBorrowPositionProxyV2 public immutable override BORROW_POSITION_PROXY; // solhint-disable-line var-name-mixedcase

    // ================================================
    // ==================== Fields ====================
    // ================================================

    address public override userVaultImplementation;
    bool public isInitialized;
    uint256 public override marketId; // can't be immutable because it's set in the call to #initialize
    uint256 public transferCursor;

    mapping(uint256 => QueuedTransfer) internal _cursorToQueuedTransferMap;
    mapping(address => address) internal _vaultToUserMap;
    mapping(address => address) internal _userToVaultMap;
    mapping(address => bool) internal _tokenConverterToIsTrustedMap;

    // ===================================================
    // ==================== Modifiers ====================
    // ===================================================

    modifier requireIsInitialized {
        Require.that(
            isInitialized,
            _FILE,
            "Not initialized"
        );
        _;
    }

    modifier requireIsVault(address _vault) {
        Require.that(
            address(_vaultToUserMap[_vault]) != address(0),
            _FILE,
            "Invalid vault",
            _vault
        );
        _;
    }

    modifier requireIsTokenConverter(address _tokenConverter) {
        Require.that(
            _tokenConverterToIsTrustedMap[_tokenConverter],
            _FILE,
            "Caller is not a token converter",
            _tokenConverter
        );
        _;
    }

    modifier requireIsTokenConverterOrVault(address _tokenConverterOrVault) {
        Require.that(
            _tokenConverterToIsTrustedMap[_tokenConverterOrVault]
                || _vaultToUserMap[_tokenConverterOrVault] != address(0),
            _FILE,
            "Caller is not a authorized",
            _tokenConverterOrVault
        );
        _;
    }

    constructor(
        address _underlyingToken,
        address _borrowPositionProxyV2,
        address _userVaultImplementation,
        address _dolomiteMargin
    )
    MinimalERC20(
        /* name_ = */ string(abi.encodePacked("Dolomite Isolation: ", MinimalERC20(_underlyingToken).name())),
        /* symbol_ = */ string(abi.encodePacked("d", MinimalERC20(_underlyingToken).symbol())),
        /* decimals_ = */ MinimalERC20(_underlyingToken).decimals()
    )
    OnlyDolomiteMargin(_dolomiteMargin)
    {
        UNDERLYING_TOKEN = _underlyingToken;
        BORROW_POSITION_PROXY = IBorrowPositionProxyV2(_borrowPositionProxyV2);
        userVaultImplementation = _userVaultImplementation;
    }

    // =================================================
    // ================ Write Functions ================
    // =================================================

    function ownerInitialize(
        address[] calldata _tokenConverters
    )
    external
    override
    onlyDolomiteMarginOwner(msg.sender) {
        Require.that(
            !isInitialized,
            _FILE,
            "Already initialized"
        );
        marketId = DOLOMITE_MARGIN().getMarketIdByTokenAddress(address(this));
        Require.that(
            DOLOMITE_MARGIN().getMarketIsClosing(marketId),
            _FILE,
            "Market cannot allow borrowing"
        );

        for (uint256 i = 0; i < _tokenConverters.length; i++) {
            _ownerSetIsTokenConverterTrusted(_tokenConverters[i], true);
        }

        isInitialized = true;
        emit Initialized();

        _afterInitialize();
    }

    function createVault(
        address _account
    )
    external
    override
    requireIsInitialized
    returns (address) {
        return _createVault(_account);
    }

    function createVaultAndDepositIntoDolomiteMargin(
        uint256 _toAccountNumber,
        uint256 _amountWei
    )
    external
    override
    requireIsInitialized
    returns (address) {
        address vault = _createVault(msg.sender);
        IIsolationModeTokenVaultV1(vault).depositIntoVaultForDolomiteMargin(_toAccountNumber, _amountWei);
        return vault;
    }

    function ownerSetUserVaultImplementation(
        address _userVaultImplementation
    )
    external
    override
    requireIsInitialized
    onlyDolomiteMarginOwner(msg.sender) {
        Require.that(
            _userVaultImplementation != address(0),
            _FILE,
            "Invalid user implementation"
        );
        address _oldUserVaultImplementation = userVaultImplementation;
        userVaultImplementation = _userVaultImplementation;
        emit UserVaultImplementationSet(_oldUserVaultImplementation, _userVaultImplementation);
    }

    function ownerSetIsTokenConverterTrusted(
        address _tokenConverter,
        bool _isTrusted
    )
    external
    override
    requireIsInitialized
    onlyDolomiteMarginOwner(msg.sender) {
        _ownerSetIsTokenConverterTrusted(_tokenConverter, _isTrusted);
    }

    function depositOtherTokenIntoDolomiteMarginForVaultOwner(
        uint256 _toAccountNumber,
        uint256 _otherMarketId,
        uint256 _amountWei
    )
    external
    override
    requireIsVault(msg.sender) {
        Require.that(
            _otherMarketId != marketId,
            _FILE,
            "Invalid market",
            _otherMarketId
        );

        // we have to deposit into the vault first and then transfer to vault.owner, because the deposit is not
        // coming from the factory address or the vault owner.
        IDolomiteStructs.AccountInfo[] memory accounts = new IDolomiteStructs.AccountInfo[](2);
        accounts[0] = IDolomiteStructs.AccountInfo({
            owner: msg.sender,
            number: 0
        });
        accounts[1] = IDolomiteStructs.AccountInfo({
            owner: _vaultToUserMap[msg.sender],
            number: _toAccountNumber
        });

        IDolomiteStructs.ActionArgs[] memory actions = new IDolomiteStructs.ActionArgs[](2);
        actions[0] = AccountActionLib.encodeDepositAction(
            /* _accountId = */ 0,
            _otherMarketId,
            IDolomiteStructs.AssetAmount({
                sign: true,
                denomination: IDolomiteStructs.AssetDenomination.Wei,
                ref: IDolomiteStructs.AssetReference.Delta,
                value: _amountWei
            }),
            /* _fromAccount = */ msg.sender
        );
        actions[1] = AccountActionLib.encodeTransferAction(
            /* _fromAccountId = */ 0,
            /* _toAccountId = */ 1,
            _otherMarketId,
            IDolomiteStructs.AssetDenomination.Wei,
            AccountActionLib.all()
        );

        DOLOMITE_MARGIN().operate(accounts, actions);
    }

    function enqueueTransferIntoDolomiteMargin(
        address _vault,
        uint256 _amountWei
    )
    external
    override
    requireIsTokenConverter(msg.sender)
    requireIsVault(_vault) {
        _enqueueTransfer(msg.sender, address(DOLOMITE_MARGIN()), _amountWei, _vault);
    }

    function enqueueTransferFromDolomiteMargin(
        address _vault,
        uint256 _amountWei
    )
    external
    override
    requireIsTokenConverter(msg.sender)
    requireIsVault(_vault) {
        _enqueueTransfer(address(DOLOMITE_MARGIN()), msg.sender, _amountWei, _vault);
    }

    function depositIntoDolomiteMargin(
        uint256 _toAccountNumber,
        uint256 _amountWei
    )
    external
    override
    requireIsVault(msg.sender) {
        address vault = msg.sender;
        _enqueueTransfer(
            vault,
            address(DOLOMITE_MARGIN()),
            _amountWei,
            vault
        );
        AccountActionLib.deposit(
            DOLOMITE_MARGIN(),
            /* _accountOwner = */ vault,
            /* _fromAccount = */ vault,
            _toAccountNumber,
            marketId,
            IDolomiteStructs.AssetAmount({
                sign: true,
                denomination: IDolomiteStructs.AssetDenomination.Wei,
                ref: IDolomiteStructs.AssetReference.Delta,
                value: _amountWei
            })
        );
    }

    function withdrawFromDolomiteMargin(
        uint256 _fromAccountNumber,
        uint256 _amountWei
    )
    external
    override
    requireIsVault(msg.sender) {
        address vault = msg.sender;
        _enqueueTransfer(
            address(DOLOMITE_MARGIN()),
            vault,
            _amountWei,
            vault
        );
        AccountActionLib.withdraw(
            DOLOMITE_MARGIN(),
            /* _accountOwner = */ vault,
            _fromAccountNumber,
            /* _toAccount = */ vault,
            marketId,
            IDolomiteStructs.AssetAmount({
                sign: false,
                denomination: IDolomiteStructs.AssetDenomination.Wei,
                ref: IDolomiteStructs.AssetReference.Delta,
                value: _amountWei
            }),
            AccountBalanceLib.BalanceCheckFlag.From
        );
    }

    // ================================================
    // ================ Read Functions ================
    // ================================================

    function getQueuedTransferByCursor(uint256 _transferCursor) external view returns (QueuedTransfer memory) {
        Require.that(
            _transferCursor <= transferCursor,
            _FILE,
            "Invalid transfer cursor"
        );
        return _cursorToQueuedTransferMap[_transferCursor];
    }

    function isTokenConverterTrusted(address _tokenConverter) external view override returns (bool) {
        return _tokenConverterToIsTrustedMap[_tokenConverter];
    }

    function getVaultByAccount(address _account) external view override returns (address _vault) {
        _vault = _userToVaultMap[_account];
    }

    function calculateVaultByAccount(address _account) external view override returns (address _vault) {
        _vault = Create2.computeAddress(
            keccak256(abi.encodePacked(_account)),
            getProxyVaultInitCodeHash()
        );
    }

    function getAccountByVault(address _vault) external view override returns (address _account) {
        _account = _vaultToUserMap[_vault];
    }

    function isIsolationAsset() external pure returns (bool) {
        return true;
    }

    // ====================================================
    // ================= Public Functions =================
    // ====================================================

    function getProxyVaultInitCodeHash() public pure override returns (bytes32) {
        return keccak256(type(IsolationModeUpgradeableProxy).creationCode);
    }

    // ====================================================
    // ================ Internal Functions ================
    // ====================================================

    function _afterInitialize() internal virtual {
        // solhint-disable-previous-line no-empty-blocks
    }

    function _ownerSetIsTokenConverterTrusted(address _tokenConverter, bool _isTrusted) internal {
        Require.that(
            _tokenConverter != address(0),
            _FILE,
            "Invalid token converter"
        );
        _tokenConverterToIsTrustedMap[_tokenConverter] = _isTrusted;
        emit TokenConverterSet(_tokenConverter, _isTrusted);
    }

    function _createVault(address _account) internal virtual returns (address) {
        Require.that(
            _account != address(0),
            _FILE,
            "Invalid account"
        );
        Require.that(
            _userToVaultMap[_account] == address(0),
            _FILE,
            "Vault already exists"
        );
        address vault = Create2.deploy(
            /* amount = */ 0,
            keccak256(abi.encodePacked(_account)),
            type(IsolationModeUpgradeableProxy).creationCode
        );
        assert(vault != address(0));
        emit VaultCreated(_account, vault);
        _vaultToUserMap[vault] = _account;
        _userToVaultMap[_account] = vault;
        IIsolationModeUpgradeableProxy(vault).initialize(_account);
        BORROW_POSITION_PROXY.setIsCallerAuthorized(vault, true);
        return vault;
    }

    function _enqueueTransfer(
        address _from,
        address _to,
        uint256 _amount,
        address _vault
    ) internal {
        QueuedTransfer memory oldTransfer = _cursorToQueuedTransferMap[transferCursor];
        if (!oldTransfer.isExecuted && oldTransfer.to == address(DOLOMITE_MARGIN())) {
            // remove the approval if the previous transfer was not executed and was to DolomiteMargin
            _approve(oldTransfer.vault, oldTransfer.to, 0);
        }

        if (_from == _vault && _to == address(DOLOMITE_MARGIN())) {
            // Approve the queued transfer amount from the vault contract into DolomiteMargin from this contract
            _approve(_vault, _to, _amount);
        }
        // add 1 to the cursor for any enqueue, allowing anyone to overwrite stale enqueues in case a developer
        // doesn't integrate with this contract properly
        transferCursor += 1;
        _cursorToQueuedTransferMap[transferCursor] = QueuedTransfer({
            from: _from,
            to: _to,
            amount: _amount,
            vault: _vault,
            isExecuted: false
        });
        emit TransferQueued(transferCursor, _from, _to, _amount, _vault);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    )
    internal
    override
    onlyDolomiteMargin(msg.sender) {
        Require.that(
            _from != address(0),
            _FILE,
            "Transfer from the zero address"
        );
        Require.that(
            _to != address(0),
            _FILE,
            "Transfer to the zero address"
        );

        // Since this must be called from DolomiteMargin via Exchange#transferIn/Exchange#transferOut, we can assume
        // that it's non-reentrant
        address dolomiteMargin = address(DOLOMITE_MARGIN());
        Require.that(
            _from == dolomiteMargin || _to == dolomiteMargin,
            _FILE,
            "from/to must eq DolomiteMargin"
        );

        uint256 _transferCursor = transferCursor;
        QueuedTransfer memory queuedTransfer = _cursorToQueuedTransferMap[_transferCursor];
        Require.that(
            queuedTransfer.from == _from
                && queuedTransfer.to == _to
                && queuedTransfer.amount == _amount
                && _vaultToUserMap[queuedTransfer.vault] != address(0),
            _FILE,
            "Invalid queued transfer"
        );
        Require.that(
            !queuedTransfer.isExecuted,
            _FILE,
            "Transfer already executed",
            _transferCursor
        );
        _cursorToQueuedTransferMap[_transferCursor].isExecuted = true;

        if (_to == dolomiteMargin) {
            // transfers TO DolomiteMargin must be made FROM a vault or a tokenConverter
            address vaultOwner = _vaultToUserMap[_from];
            Require.that(
                (vaultOwner != address(0) && _from == queuedTransfer.vault) || _tokenConverterToIsTrustedMap[_from],
                _FILE,
                "Invalid from"
            );
            IIsolationModeTokenVaultV1(queuedTransfer.vault).executeDepositIntoVault(
                vaultOwner != address(0) ? vaultOwner : _from,
                _amount
            );
            _mint(_to, _amount);
        } else {
            assert(_from == dolomiteMargin);

            // transfers FROM DolomiteMargin must be made TO a vault OR to a tokenConverter
            address vaultOwner = _vaultToUserMap[_to];
            Require.that(
                vaultOwner != address(0) || _tokenConverterToIsTrustedMap[_to],
                _FILE,
                "Invalid to"
            );

            IIsolationModeTokenVaultV1(queuedTransfer.vault).executeWithdrawalFromVault(
                vaultOwner != address(0) ? vaultOwner : _to,
                _amount
            );
            _burn(_from, _amount);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IsolationModeTraderBaseV2 } from "./IsolationModeTraderBaseV2.sol";
import { AccountActionLib } from "../../lib/AccountActionLib.sol";
import { IDolomiteMargin } from "../../protocol/interfaces/IDolomiteMargin.sol";
import { Require } from "../../protocol/lib/Require.sol";
import { IIsolationModeWrapperTraderV2 } from "../interfaces/IIsolationModeWrapperTraderV2.sol";


/**
 * @title   IsolationModeWrapperTraderV2
 * @author  Dolomite
 *
 * @notice  Abstract contract for wrapping a token into an IsolationMode token. Must be set as a token converter
 *          for the VaultWrapperFactory token.
 */
abstract contract IsolationModeWrapperTraderV2 is IIsolationModeWrapperTraderV2, IsolationModeTraderBaseV2 {
    using SafeERC20 for IERC20;

    // ======================== Constants ========================

    bytes32 private constant _FILE = "IsolationModeWrapperTraderV2";
    uint256 private constant _ACTIONS_LENGTH = 1;

    // ======================== Constructor ========================

    constructor(
        address _vaultFactory,
        address _dolomiteMargin,
        address _dolomiteRegistry
    )
    IsolationModeTraderBaseV2(
        _vaultFactory,
        _dolomiteMargin,
        _dolomiteRegistry
    ) {
        // solhint-disable-previous-line no-empty-blocks
    }

    // ======================== External Functions ========================

    function exchange(
        address _tradeOriginator,
        address _receiver,
        address _outputToken,
        address _inputToken,
        uint256 _inputAmount,
        bytes calldata _orderData
    )
    external
    onlyDolomiteMargin(msg.sender)
    returns (uint256) {
        Require.that(
            VAULT_FACTORY.getAccountByVault(_tradeOriginator) != address(0),
            _FILE,
            "Invalid trade originator",
            _tradeOriginator
        );
        Require.that(
            isValidInputToken(_inputToken),
            _FILE,
            "Invalid input token",
            _inputToken
        );
        Require.that(
            _outputToken == address(VAULT_FACTORY),
            _FILE,
            "Invalid output token",
            _outputToken
        );
        Require.that(
            _inputAmount > 0,
            _FILE,
            "Invalid input amount"
        );

        (uint256 minOutputAmount, bytes memory _extraOrderData) = abi.decode(_orderData, (uint256, bytes));

        uint256 outputAmount = _exchangeIntoUnderlyingToken(
            _tradeOriginator,
            _receiver,
            VAULT_FACTORY.UNDERLYING_TOKEN(),
            minOutputAmount,
            _inputToken,
            _inputAmount,
            _extraOrderData
        );
        Require.that(
            outputAmount >= minOutputAmount,
            _FILE,
            "Insufficient output amount",
            outputAmount,
            minOutputAmount
        );

        _approveIsolationModeTokenForTransfer(_tradeOriginator, _receiver, outputAmount);

        return outputAmount;
    }

    function token() external override view returns (address) {
        return address(VAULT_FACTORY);
    }

    function createActionsForWrapping(
        CreateActionsForWrappingParams calldata _params
    )
    external
    override
    view
    returns (IDolomiteMargin.ActionArgs[] memory) {
        Require.that(
            isValidInputToken(DOLOMITE_MARGIN().getMarketTokenAddress(_params.inputMarket)),
            _FILE,
            "Invalid input market",
            _params.inputMarket
        );
        Require.that(
            DOLOMITE_MARGIN().getMarketTokenAddress(_params.outputMarket) == address(VAULT_FACTORY),
            _FILE,
            "Invalid output market",
            _params.outputMarket
        );

        IDolomiteMargin.ActionArgs[] memory actions = new IDolomiteMargin.ActionArgs[](_ACTIONS_LENGTH);

        actions[0] = AccountActionLib.encodeExternalSellAction(
            _params.primaryAccountId,
            _params.inputMarket,
            _params.outputMarket,
            /* _trader = */ address(this),
            /* _amountInWei = */ _params.inputAmount,
            /* _amountOutMinWei = */ _params.minOutputAmount,
            _params.orderData
        );

        return actions;
    }

    function actionsLength() external override pure returns (uint256) {
        return _ACTIONS_LENGTH;
    }

    function getExchangeCost(
        address _inputToken,
        address _outputToken,
        uint256 _desiredInputAmount,
        bytes memory _orderData
    )
    public
    override
    view
    returns (uint256) {
        Require.that(
            isValidInputToken(_inputToken),
            _FILE,
            "Invalid input token",
            _inputToken
        );
        Require.that(
            _outputToken == address(VAULT_FACTORY),
            _FILE,
            "Invalid output token",
            _outputToken
        );
        Require.that(
            _desiredInputAmount > 0,
            _FILE,
            "Invalid desired input amount"
        );

        return _getExchangeCost(
            _inputToken,
            _outputToken,
            _desiredInputAmount,
            _orderData
        );
    }

    function isValidInputToken(address _inputToken) public override virtual view returns (bool);

    // ============ Internal Functions ============

    /**
     * @notice Performs the exchange from `_inputToken` into the factory's underlying token.
     */
    function _exchangeIntoUnderlyingToken(
        address _tradeOriginator,
        address _receiver,
        address _outputTokenUnderlying,
        uint256 _minOutputAmount,
        address _inputToken,
        uint256 _inputAmount,
        bytes memory _extraOrderData
    ) internal virtual returns (uint256);

    function _approveIsolationModeTokenForTransfer(
        address _vault,
        address _receiver,
        uint256 _amount
    )
    internal
    virtual {
        VAULT_FACTORY.enqueueTransferIntoDolomiteMargin(_vault, _amount);

        address underlyingToken = VAULT_FACTORY.UNDERLYING_TOKEN();
        IERC20(underlyingToken).safeApprove(_vault, _amount);
        IERC20(address(VAULT_FACTORY)).safeApprove(_receiver, _amount);
    }

    function _getExchangeCost(
        address _inputToken,
        address _outputToken,
        uint256 _desiredInputAmount,
        bytes memory _orderData
    )
    internal
    virtual
    view
    returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IBorrowPositionProxyV2 } from "../../interfaces/IBorrowPositionProxyV2.sol";
import { IDolomiteRegistry } from "../../interfaces/IDolomiteRegistry.sol";
import { IGenericTraderBase } from "../../interfaces/IGenericTraderBase.sol";
import { IGenericTraderProxyV1 } from "../../interfaces/IGenericTraderProxyV1.sol";
import { AccountBalanceLib } from "../../lib/AccountBalanceLib.sol";
import { IDolomiteMargin } from "../../protocol/interfaces/IDolomiteMargin.sol";
import { IDolomiteStructs } from "../../protocol/interfaces/IDolomiteStructs.sol";


/**
 * @title   IIsolationModeTokenVaultV1
 * @author  Dolomite
 *
 * @notice Interface for the implementation contract used by proxy user vault contracts.
 */
interface IIsolationModeTokenVaultV1 {

    struct SwapExactInputForOutputParams {
        uint256 tradeAccountNumber;
        uint256[] marketIdsPath;
        uint256 inputAmountWei;
        uint256 minOutputAmountWei;
        IGenericTraderProxyV1.TraderParam[] tradersPath;
        IDolomiteStructs.AccountInfo[] makerAccounts;
        IGenericTraderProxyV1.UserConfig userConfig;
    }

    // ===========================================================
    // ======================== Functions ========================
    // ===========================================================

    /**
     * @notice  Initializes the vault contract. Should only be executable once by the proxy.
     */
    function initialize() external;

    /**
     * @notice  End-user function for depositing the vault factory's underlying token into DolomiteMargin. Should only
     *          be executable by the vault owner OR the vault factory.
     */
    function depositIntoVaultForDolomiteMargin(uint256 _toAccountNumber, uint256 _amountWei) external;

    /**
     * @notice  End-user function for withdrawing the vault factory's underlying token from DolomiteMargin. Should only
     *          be executable by the vault owner.
     */
    function withdrawFromVaultForDolomiteMargin(uint256 _fromAccountNumber, uint256 _amountWei) external;

    /**
     * @notice  End-user function for opening a borrow position involving the vault factory's underlying token. Should
     *          only be executable by the vault owner. Reverts if `_fromAccountNumber` is not 0 or if `_toAccountNumber`
     *          is 0.
     */
    function openBorrowPosition(
        uint256 _fromAccountNumber,
        uint256 _toAccountNumber,
        uint256 _amountWei
    ) external payable;

    /**
     * @notice  End-user function for closing a borrow position involving the vault factory's underlying token. Should
     *          only be executable by the vault owner. Reverts if `_borrowAccountNumber` is 0 or if `_toAccountNumber`
     *          is not 0.
     */
    function closeBorrowPositionWithUnderlyingVaultToken(
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber
    ) external;

    /**
     * @notice  End-user function for closing a borrow position involving anything BUT the vault factory's underlying
     *          token. Should only be executable by the vault owner. Throws if any of the `collateralMarketIds` is set
     *          to the vault factory's underlying token. Reverts if `_borrowAccountNumber` is 0.
     */
    function closeBorrowPositionWithOtherTokens(
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber,
        uint256[] calldata collateralMarketIds
    ) external;

    /**
     * @notice  End-user function for transferring collateral into a position using the vault factory's underlying
     *          token. Should only be executable by the vault owner. Reverts if `_fromAccountNumber` is not 0 or if
     *          `_borrowAccountNumber` is 0.
     */
    function transferIntoPositionWithUnderlyingToken(
        uint256 _fromAccountNumber,
        uint256 _borrowAccountNumber,
        uint256 _amountWei
    ) external;

    /**
     * @notice  End-user function for transferring collateral into a position using anything BUT the vault factory's
     *          underlying token. Should only be executable by the vault owner. Throws if the `_marketId` is set to the
     *          vault factory's underlying token. Reverts if `_borrowAccountNumber` is 0.
     */
    function transferIntoPositionWithOtherToken(
        uint256 _fromAccountNumber,
        uint256 _borrowAccountNumber,
        uint256 _marketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    /**
     * @notice  End-user function for transferring collateral from a position using the vault factory's underlying
     *          token. Should only be executable by the vault owner. Reverts if `_borrowAccountNumber` is 0 or if
     *          `_toAccountNumber` is not 0.
     */
    function transferFromPositionWithUnderlyingToken(
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber,
        uint256 _amountWei
    ) external;

    /**
     * @notice  End-user function for transferring collateral from a position using anything BUT the vault factory's
     *          underlying token. Should only be executable by the vault owner. Throws if the `_marketId` is set to the
     *          vault factory's underlying token. Reverts if `_borrowAccountNumber` is 0.
     */
    function transferFromPositionWithOtherToken(
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber,
        uint256 _marketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    /**
     * @notice  End-user function for transferring collateral involving anything BUT the vault factory's underlying
     *          token. Should only be executable by the vault owner. Throws if the `_marketId` is set to the vault
     *          factory's underlying token. Reverts if `_borrowAccountNumber` is 0.
     */
    function repayAllForBorrowPosition(
        uint256 _fromAccountNumber,
        uint256 _borrowAccountNumber,
        uint256 _marketId,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    /**
     * @dev     End-user function for adding collateral from the vault (in the case where `_marketIdsPath[0]` is the
     *          underlying marketId) or the vault owner (in the case where `_marketIdsPath[0]` is not the underlying
     *          marketId), then trading an exact amount of input for a minimum amount of output. Reverts if
     *          `_borrowAccountNumber` is 0 or if `_fromAccountNumber` is not 0 (and the `_marketIdsPath[0]` is the
     *          underlying). Reverts if the user has a negative balance for `_marketIdsPath[0]`.
     *
     * @param  _fromAccountNumber           The account number to use for the source of the transfer.
     * @param  _borrowAccountNumber         The account number to use for the vault's trade. Cannot be 0.
     * @param  _marketIdsPath               The path of market IDs to use for each trade action. Length should be equal
     *                                      to `_tradersPath.length + 1`.
     * @param  _inputAmountWei              The input amount (in wei) to use for the initial trade action. Setting this
     *                                      value to `uint(-1)` will use the user's full balance.
     * @param  _minOutputAmountWei          The minimum output amount expected to be received by the user.
     * @param  _tradersPath                 The path of traders to use for each trade action. Length should be equal to
     *                                      `_marketIdsPath.length - 1`.
     * @param  _makerAccounts               The accounts that will be used for the maker side of the trades involving
     *                                      `TraderType.InternalLiquidity`.
     * @param  _userConfig                  The user configuration for the trade. Setting the `balanceCheckFlag` to
     *                                      `BalanceCheckFlag.From` will check that the user's `_borrowAccountNumber`
     *                                      and `_fromAccountNumber` is non-negative after the trade.
     */
    function addCollateralAndSwapExactInputForOutput(
        uint256 _fromAccountNumber,
        uint256 _borrowAccountNumber,
        uint256[] calldata _marketIdsPath,
        uint256 _inputAmountWei,
        uint256 _minOutputAmountWei,
        IGenericTraderBase.TraderParam[] calldata _tradersPath,
        IDolomiteStructs.AccountInfo[] calldata _makerAccounts,
        IGenericTraderProxyV1.UserConfig calldata _userConfig
    )
    external payable;

    /**
     * @dev     End-user function for removing collateral from the vault (in the case where `_marketIdsPath[last]` is
     *          the underlying marketId) or the vault owner (in the case where `_marketIdsPath[last]` is not the
     *          underlying marketId). Reverts if `_borrowAccountNumber` is 0 or if `_toAccountNumber` is not 0 (and
     *          the `_marketIdsPath[0]` is the underlying). Reverts if the user has a negative balance before the swap
     *          for `_marketIdsPath[last]`.
     *
     * @param  _toAccountNumber             The account number to receive the collateral transfer after the trade.
     * @param  _borrowAccountNumber         The account number to use for the vault's trade.
     * @param  _marketIdsPath               The path of market IDs to use for each trade action. Length should be equal
     *                                      to `_tradersPath.length + 1`.
     * @param  _inputAmountWei              The input amount (in wei) to use for the initial trade action. Setting this
     *                                      value to `uint(-1)` will use the user's full balance.
     * @param  _minOutputAmountWei          The minimum output amount expected to be received by the user.
     * @param  _tradersPath                 The path of traders to use for each trade action. Length should be equal to
     *                                      `_marketIdsPath.length - 1`.
     * @param  _makerAccounts               The accounts that will be used for the maker side of the trades involving
     *                                      `TraderType.InternalLiquidity`.
     * @param  _userConfig                  The user configuration for the trade. Setting the `balanceCheckFlag` to
     *                                      `BalanceCheckFlag.From` will check that the user's `_tradeAccountNumber`
     *                                      is non-negative after the trade. Setting the `balanceCheckFlag` to
     *                                      `BalanceCheckFlag.To` has no effect.
     */
    function swapExactInputForOutputAndRemoveCollateral(
        uint256 _toAccountNumber,
        uint256 _borrowAccountNumber,
        uint256[] calldata _marketIdsPath,
        uint256 _inputAmountWei,
        uint256 _minOutputAmountWei,
        IGenericTraderBase.TraderParam[] calldata _tradersPath,
        IDolomiteStructs.AccountInfo[] calldata _makerAccounts,
        IGenericTraderProxyV1.UserConfig calldata _userConfig
    )
    external payable;

    /**
     * @dev     End-user function for swapping an exact amount of input for a minimum amount of output. Reverts if
     *          `_tradeAccountNumber` is 0.
     *
     * @param  _tradeAccountNumber          The account number to use for the vault's trade. Cannot be 0.
     * @param  _marketIdsPath               The path of market IDs to use for each trade action. Length should be equal
     *                                      to `_tradersPath.length + 1`.
     * @param  _inputAmountWei              The input amount (in wei) to use for the initial trade action. Setting this
     *                                      value to `uint(-1)` will use the user's full balance.
     * @param  _minOutputAmountWei          The minimum output amount expected to be received by the user.
     * @param  _tradersPath                 The path of traders to use for each trade action. Length should be equal to
     *                                      `_marketIdsPath.length - 1`.
     * @param  _makerAccounts               The accounts that will be used for the maker side of the trades involving
     *                                      `TraderType.InternalLiquidity`.
     * @param  _userConfig                  The user configuration for the trade. Setting the `balanceCheckFlag` to
     *                                      `BalanceCheckFlag.From` will check that the user's `_tradeAccountNumber`
     *                                      is non-negative after the trade. Setting the `balanceCheckFlag` to
     *                                      `BalanceCheckFlag.To` has no effect.
     */
    function swapExactInputForOutput(
        uint256 _tradeAccountNumber,
        uint256[] calldata _marketIdsPath,
        uint256 _inputAmountWei,
        uint256 _minOutputAmountWei,
        IGenericTraderBase.TraderParam[] calldata _tradersPath,
        IDolomiteStructs.AccountInfo[] calldata _makerAccounts,
        IGenericTraderProxyV1.UserConfig calldata _userConfig
    )
    external payable;

    // ==================== Does not modify balances ====================

    /**
     * @notice  Attempts to deposit assets into this vault from the vault's owner. Reverts if the caller is not the
     *          Vault Factory.
     *
     * @param  _from    The sender of the tokens into this vault.
     * @param  _amount  The amount of the vault's underlying token to transfer.
     */
    function executeDepositIntoVault(address _from, uint256 _amount) external;

    /**
     * @notice  Attempts to withdraw assets from this vault to the recipient. Reverts if the caller is not the
     *          Vault Factory.
     *
     * @param  _recipient   The address to receive the withdrawal.
     * @param  _amount      The amount of the vault's underlying token to transfer out.
     */
    function executeWithdrawalFromVault(address _recipient, uint256 _amount) external;

    /**
     * @return The amount of `UNDERLYING_TOKEN` that are currently in this vault.
     */
    function underlyingBalanceOf() external view returns (uint256);

    /**
     * @return The registry used to discover important addresses for Dolomite
     */
    function dolomiteRegistry() external view returns (IDolomiteRegistry);

    function marketId() external view returns (uint256);

    function BORROW_POSITION_PROXY() external view returns (IBorrowPositionProxyV2);

    function DOLOMITE_MARGIN() external view returns (IDolomiteMargin);

    function VAULT_FACTORY() external view returns (address);

    function OWNER() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IIsolationModeTokenVaultV1 } from "./IIsolationModeTokenVaultV1.sol";


/**
 * @title   IIsolationModeTokenVaultV1WithPausable
 * @author  Dolomite
 *
 * @notice Interface for the implementation contract used by proxy user vault contracts.
 */
interface IIsolationModeTokenVaultV1WithPausable is IIsolationModeTokenVaultV1 {

    // ===================================================
    // ==================== Functions ====================
    // ===================================================

    /**
     * @return  true if redemptions (conversion) from this isolated token to its underlying are paused or are in a
     *          distressed state. Resolving this function to true actives the Pause Sentinel, which prevents further
     *          contamination of this market across Dolomite.
     */
    function isExternalRedemptionPaused() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteMargin } from "../../protocol/interfaces/IDolomiteMargin.sol";
import { IDolomiteMarginExchangeWrapper } from "../../protocol/interfaces/IDolomiteMarginExchangeWrapper.sol";


/**
 * @title   IIsolationModeUnwrapperTraderV2
 * @author  Dolomite
 *
 * V2 Interface for a contract that can convert an isolation mode token into an underlying component token.
 */
interface IIsolationModeUnwrapperTraderV2 is IDolomiteMarginExchangeWrapper {

    struct CreateActionsForUnwrappingParams {
        /// @dev    The index of the account (according the Accounts[] array) that is performing the sell.
        uint256 primaryAccountId;
        /// @dev    The index of the account (according the Accounts[] array) that is being liquidated. This is set to
        ///         `_primaryAccountId` if a liquidation is not occurring.
        uint256 otherAccountId;
        /// @dev    The address of the owner of the account that is performing the sell.
        address primaryAccountOwner;
        /// @dev    The account number of the owner of the account that is performing the sell.
        uint256 primaryAccountNumber;
        /// @dev    The address of the owner of the account that is being liquidated. This is set to
        ///         `_primaryAccountOwner` if a liquidation is not occurring.
        address otherAccountOwner;
        /// @dev    The account number of the owner of the account that is being liquidated. This is set to
        ///         `_primaryAccountNumber` if a liquidation is not occurring.
        uint256 otherAccountNumber;
        /// @dev    The market that is being outputted by the unwrapping.
        uint256 outputMarket;
        /// @dev    The market that is being unwrapped, should be equal to `token()`.
        uint256 inputMarket;
        /// @dev    The min amount of `_outputMarket` that must be outputted by the unwrapping.
        uint256 minOutputAmount;
        /// @dev    The amount of the `_inputMarket` that the _primaryAccountId must sell.
        uint256 inputAmount;
        /// @dev    The calldata to pass through to any external sales that occur.
        bytes orderData;
    }

    /**
     * @return The isolation mode token that this contract can unwrap (the input token).
     */
    function token() external view returns (address);

    /**
     * @return True if the `_outputToken` is a valid output token for this contract, to be unwrapped by `token()`.
     */
    function isValidOutputToken(address _outputToken) external view returns (bool);

    /**
     * @notice  Creates the necessary actions for selling the `_inputMarket` into `_outputMarket`. Note, the
     *          `_inputMarket` should be equal to `token()` and `_outputMarket` should be validated to be a correct
     *           market that can be transformed into `token()`.
     *
     * @param  _params  The parameters for creating the actions for unwrapping.
     * @return          The actions that will be executed to unwrap the `_inputMarket` into `_outputMarket`.
     */
    function createActionsForUnwrapping(
        CreateActionsForUnwrappingParams calldata _params
    )
        external
        view
        returns (IDolomiteMargin.ActionArgs[] memory);

    /**
     * @return  The number of actions used to unwrap the isolation mode token.
     */
    function actionsLength() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;


/**
 * @title   IIsolationModeUpgradeableProxy
 * @author  Dolomite
 *
 * @notice  The interface for the upgradeable proxy contract that holds each user's tokens that are wrapped by the
 *          IsolationModeVaultFactory.
 */
interface IIsolationModeUpgradeableProxy {

    /**
     *
     * @param  _account The owner of this vault contract
     */
    function initialize(address _account) external;

    function isInitialized() external view returns (bool);

    function implementation() external view returns (address);

    function vaultFactory() external view returns (address);

    function owner() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IBorrowPositionProxyV2 } from "../../interfaces/IBorrowPositionProxyV2.sol";
import { IOnlyDolomiteMargin } from "../../interfaces/IOnlyDolomiteMargin.sol";


/**
 * @title   IIsolationModeVaultFactory
 * @author  Dolomite
 *
 * @notice A wrapper contract around a certain token to offer isolation mode features for DolomiteMargin.
 */
interface IIsolationModeVaultFactory is IOnlyDolomiteMargin {

    // =================================================
    // ==================== Structs ====================
    // =================================================

    struct QueuedTransfer {
        address from;
        address to;
        uint256 amount;
        address vault;
        bool isExecuted;
    }

    // ================================================
    // ==================== Events ====================
    // ================================================

    event UserVaultImplementationSet(
        address indexed previousUserVaultImplementation,
        address indexed newUserVaultImplementation
    );

    event TokenConverterSet(address indexed tokenConverter, bool isTrusted);

    event VaultCreated(address indexed account, address vault);

    event Initialized();

    event TransferQueued(
        uint256 indexed transferCursor,
        address from,
        address to,
        uint256 amountWei,
        address vault
    );

    // ======================================================
    // ================== Admin Functions ===================
    // ======================================================

    /**
     * @notice  Initializes this contract's variables that are dependent on this token being added to DolomiteMargin.
     */
    function ownerInitialize(address[] calldata _tokenConverters) external;

    /**
     *
     * @param  _userVaultImplementation  The address of the new vault implementation contract
     */
    function ownerSetUserVaultImplementation(address _userVaultImplementation) external;

    /**
     * @notice  A token converter is used to convert this underlying token into a Dolomite-compatible one for deposit
     *          or withdrawal
     *
     * @param  _tokenConverter   The address of the token converter contract to set whether or not it's trusted for
     *                          executing transfers to/from vaults
     * @param  _isTrusted        True if the token converter is trusted, false otherwise
     */
    function ownerSetIsTokenConverterTrusted(address _tokenConverter, bool _isTrusted) external;

    // ======================================================
    // ================== User Functions ===================
    // ======================================================

    /**
     * @notice  Creates the vault for `_account`
     *
     * @param  _account  The account owner to create the vault for
     */
    function createVault(address _account) external returns (address);

    /**
     * @notice  Creates the vault for `msg.sender`
     *
     * @param  _toAccountNumber  The account number of the account to which the tokens will be deposited
     * @param  _amountWei        The amount of tokens to deposit
     */
    function createVaultAndDepositIntoDolomiteMargin(
        uint256 _toAccountNumber,
        uint256 _amountWei
    ) external returns (address);

    /**
     * @notice  Deposits a token into the vault owner's account at `_toAccountNumber`. This function can only be called
     *          by a user's vault contract. Reverts if `_marketId` is set to the market ID of this vault.
     *
     * @param  _toAccountNumber  The account number of the account to which the tokens will be deposited
     * @param  _marketId         The market ID of the token to deposit
     * @param  _amountWei        The amount of tokens to deposit
     */
    function depositOtherTokenIntoDolomiteMarginForVaultOwner(
        uint256 _toAccountNumber,
        uint256 _marketId,
        uint256 _amountWei
    )
    external;

    /**
     * @notice  Enqueues a transfer into Dolomite Margin from the vault. Assumes msg.sender is a trusted token
     *          converter, else reverts. Reverts if `_vault` is not a valid vault contract.
     *
     * @param  _vault        The address of the vault that the token converter is interacting with
     * @param  _amountWei    The amount of tokens to transfer into Dolomite Margin
     */
    function enqueueTransferIntoDolomiteMargin(
        address _vault,
        uint256 _amountWei
    )
    external;

    /**
     * @notice  Enqueues a transfer from Dolomite Margin to the token converter. Assumes msg.sender is a trusted token
     *          converter, else reverts. Reverts if `_vault` is not a valid vault contract.
     *
     * @param  _vault        The address of the vault that the token converter is interacting with
     * @param  _amountWei    The amount of tokens to transfer from Dolomite Margin to the token converter
     */
    function enqueueTransferFromDolomiteMargin(
        address _vault,
        uint256 _amountWei
    )
    external;

    /**
     * @notice  This function should only be called by a user's vault contract
     *
     * @param  _toAccountNumber  The account number of the account to which the tokens will be deposited
     * @param  _amountWei        The amount of tokens to deposit
     */
    function depositIntoDolomiteMargin(
        uint256 _toAccountNumber,
        uint256 _amountWei
    )
    external;

    /**
     * @notice  This function should only be called by a user's vault contract
     *
     * @param  _fromAccountNumber    The account number of the account from which the tokens will be withdrawn
     * @param  _amountWei            The amount of tokens to withdraw
     */
    function withdrawFromDolomiteMargin(
        uint256 _fromAccountNumber,
        uint256 _amountWei
    )
    external;

    // ============================================
    // ================= Constants ================
    // ============================================

    /**
     * @return The address of the token that this vault wraps around
     */
    function UNDERLYING_TOKEN() external view returns (address);

    /**
     * @return  The address of the BorrowPositionProxyV2 contract
     */
    function BORROW_POSITION_PROXY() external view returns (IBorrowPositionProxyV2);

    // =================================================
    // ================= View Functions ================
    // =================================================

    /**
     * @return  The market ID of this token contract according to DolomiteMargin. This value is initializes in the
     *          #initialize function
     */
    function marketId() external view returns (uint256);

    /**
     * @return  This function should always return `true`. It's used by The Graph to index this contract as a Wrapper.
     */
    function isIsolationAsset() external view returns (bool);

    /**
     * @return  Returns the current transfer cursor
     */
    function transferCursor() external view returns (uint256);

    /**
     *
     * @param  _transferCursor   The cursor used to key into the mapping of queued transfers
     * @return The transfer enqueued in the mapping at the cursor's position
     */
    function getQueuedTransferByCursor(uint256 _transferCursor) external view returns (QueuedTransfer memory);

    /**
     * @return  The market IDs of the assets that can be borrowed in a position with this wrapped asset. An empty array
     *          indicates that any non-isolation mode asset can be borrowed against it.
     */
    function allowableDebtMarketIds() external view returns (uint256[] memory);

    /**
     * @return  The market IDs of the assets that can be used as collateral in a position with this wrapped asset. An
     *          empty array indicates that any non-isolation mode asset can be borrowed against it. To indicate that no
     *          assets can be used as collateral, return an array with a single element containing #marketId().
     */
    function allowableCollateralMarketIds() external view returns (uint256[] memory);

    /**
     * @return  The address of the current vault implementation contract
     */
    function userVaultImplementation() external view returns (address);

    /**
     *
     * @param  _account  The account owner to get the vault for
     * @return  _vault   The address of the vault created for `_account`. Returns address(0) if no vault has been
     *                   created yet for this account.
     */
    function getVaultByAccount(address _account) external view returns (address _vault);

    /**
     * @notice  Same as `getVaultByAccount`, but always returns the user's non-zero vault address.
     */
    function calculateVaultByAccount(address _account) external view returns (address _vault);

    /**
     *
     * @param  _vault    The vault that's used by an account for depositing/withdrawing
     * @return  _account The address of the account that owns the `_vault`
     */
    function getAccountByVault(address _vault) external view returns (address _account);

    /**
     * @notice  A token converter is used to convert this underlying token into a Dolomite-compatible one for deposit
     *          or withdrawal
     * @return  True if the token converter is currently in-use by this contract.
     */
    function isTokenConverterTrusted(address _tokenConverter) external view returns (bool);

    function getProxyVaultInitCodeHash() external pure returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteMargin } from "../../protocol/interfaces/IDolomiteMargin.sol";
import { IDolomiteMarginExchangeWrapper } from "../../protocol/interfaces/IDolomiteMarginExchangeWrapper.sol";


/**
 * @title   IIsolationModeWrapperTraderV2
 * @author  Dolomite
 *
 * Interface for a contract that can convert a token into an isolation mode token.
 */
interface IIsolationModeWrapperTraderV2 is IDolomiteMarginExchangeWrapper {

    struct CreateActionsForWrappingParams {
        /// @dev    The index of the account (according the Accounts[] array) that is performing the sell.
        uint256 primaryAccountId;
        /// @dev    The index of the account (according the Accounts[] array) that is being liquidated. This is set to
        ///         `_primaryAccountId` if a liquidation is not occurring.
        uint256 otherAccountId;
        /// @dev    The address of the owner of the account that is performing the sell.
        address primaryAccountOwner;
        /// @dev    The account number of the owner of the account that is performing the sell.
        uint256 primaryAccountNumber;
        /// @dev    The address of the owner of the account that is being liquidated. This is set to
        ///         `_primaryAccountOwner` if a liquidation is not occurring.
        address otherAccountOwner;
        /// @dev    The account number of the owner of the account that is being liquidated. This is set to
        ///         `_primaryAccountNumber` if a liquidation is not occurring.
        uint256 otherAccountNumber;
        /// @dev    The market that is being outputted by the wrapping, should be equal to `token().
        uint256 outputMarket;
        /// @dev    The market that is being used to wrap into `token()`.
        uint256 inputMarket;
        /// @dev    The min amount of `_outputMarket` that must be outputted by the wrapping.
        uint256 minOutputAmount;
        /// @dev    The amount of the `_inputMarket` that the _primaryAccountId must sell.
        uint256 inputAmount;
        /// @dev    The calldata to pass through to any external sales that occur.
        bytes orderData;
    }

    /**
     * @return The isolation mode token that this contract can wrap (the output token)
     */
    function token() external view returns (address);

    /**
     * @return True if the `_inputToken` is a valid input token for this contract, to be wrapped into `token()`
     */
    function isValidInputToken(address _inputToken) external view returns (bool);

    /**
     * @notice  Creates the necessary actions for selling the `_inputMarket` into `_outputMarket`. Note, the
     *          `_outputMarket` should be equal to `token()` and `_inputMarket` should be validated to be a correct
     *           market that can be transformed into `token()`.
     *
     * @param  _params  The parameters for creating the actions for wrapping.
     * @return          The actions that will be executed to unwrap the `_inputMarket` into `_outputMarket`.
     */
    function createActionsForWrapping(
        CreateActionsForWrappingParams calldata _params
    )
        external
        view
        returns (IDolomiteMargin.ActionArgs[] memory);

    /**
     * @return  The number of Actions used to wrap a valid input token into the this wrapper's Isolation Mode token.
     */
    function actionsLength() external pure returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IIsolationModeUnwrapperTraderV2 } from "./IIsolationModeUnwrapperTraderV2.sol";
import { IIsolationModeVaultFactory } from "./IIsolationModeVaultFactory.sol";
import { IOnlyDolomiteMargin } from "../../interfaces/IOnlyDolomiteMargin.sol";


/**
 * @title   IUpgradeableAsyncIsolationModeUnwrapperTrader
 * @author  Dolomite
 *
 * Interface for an upgradeable contract that can convert an isolation mode token into another token.
 */
interface IUpgradeableAsyncIsolationModeUnwrapperTrader is IIsolationModeUnwrapperTraderV2, IOnlyDolomiteMargin {

    // ================================================
    // ==================== Structs ===================
    // ================================================

    struct WithdrawalInfo {
        bytes32 key;
        address vault;
        uint256 accountNumber;
        /// @dev The amount of FACTORY tokens that is being sold
        uint256 inputAmount;
        address outputToken;
        /// @dev initially 0 until the withdrawal is executed
        uint256 outputAmount;
        bool isRetryable;
        bool isLiquidation;
        bytes extraData;
    }

    struct State {
        uint256 actionsLength;
        uint256 reentrancyGuard;
        address vaultFactory;
        address handlerRegistry;
        mapping(bytes32 => WithdrawalInfo) withdrawalInfo;
    }

    // ================================================
    // ===================== Enums ====================
    // ================================================

    enum TradeType {
        FromWithdrawal,
        FromDeposit,
        NoOp
    }

    // ===================================================
    // ==================== Functions ====================
    // ===================================================

    /**
     * Notifies the unwrapper that it'll be entered for a trade from the unwrapper. This allows it to modify the action
     * length
     */
    function handleCallbackFromWrapperBefore() external;

    /**
     * Reverts any changes made in `handleCallbackFromWrapperBefore`. Can only be called by a corresponding Wrapper
     * trader.
     */
    function handleCallbackFromWrapperAfter() external;

    /**
     * Transfers underlying tokens from the vault (msg.sender) to this contract to initiate a redemption.
     */
    function vaultInitiateUnwrapping(
        uint256 _tradeAccountNumber,
        uint256 _inputAmount,
        address _outputToken,
        uint256 _minOutputAmount,
        bool _isLiquidation,
        bytes calldata _extraData
    ) external payable;

    /**
     *
     * @param  _key The key of the withdrawal that should be cancelled
     */
    function initiateCancelWithdrawal(bytes32 _key) external;

    function getWithdrawalInfo(bytes32 _key) external view returns (WithdrawalInfo memory);

    function VAULT_FACTORY() external view returns (IIsolationModeVaultFactory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IIsolationModeVaultFactory } from "./IIsolationModeVaultFactory.sol";
import { IIsolationModeWrapperTraderV2 } from "./IIsolationModeWrapperTraderV2.sol";
import { IOnlyDolomiteMargin } from "../../interfaces/IOnlyDolomiteMargin.sol";


/**
 * @title   IUpgradeableAsyncIsolationModeWrapperTrader
 * @author  Dolomite
 *
 * Interface for an upgradeable contract that can convert a token into an isolation mode token.
 */
interface IUpgradeableAsyncIsolationModeWrapperTrader is IIsolationModeWrapperTraderV2, IOnlyDolomiteMargin {

    // ================================================
    // ==================== Structs ===================
    // ================================================

    struct State {
        mapping(bytes32 => DepositInfo) depositInfo;
        address vaultFactory;
        address handlerRegistry;
    }

    struct DepositInfo {
        bytes32 key;
        address vault;
        uint256 accountNumber;
        address inputToken;
        uint256 inputAmount;
        uint256 outputAmount;
        bool isRetryable;
    }

    // ===================================================
    // ==================== Functions ====================
    // ===================================================

    /**
     * This should be called by the vault to initiate a cancellation for a deposit.
     *
     * @param  _key The key of the deposit that should be cancelled
     */
    function initiateCancelDeposit(bytes32 _key) external;

    function setDepositInfoAndReducePendingAmountFromUnwrapper(
        bytes32 _key,
        uint256 _outputAmountDeltaWei,
        DepositInfo calldata _depositInfo
    ) external;

    function getDepositInfo(bytes32 _key) external view returns (DepositInfo memory);

    function VAULT_FACTORY() external view returns (IIsolationModeVaultFactory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { ProxyContractHelpers } from "../helpers/ProxyContractHelpers.sol";
import { Require } from "../protocol/lib/Require.sol";
import { IIsolationModeTokenVaultV1 } from "./interfaces/IIsolationModeTokenVaultV1.sol";
import { IIsolationModeUpgradeableProxy } from "./interfaces/IIsolationModeUpgradeableProxy.sol";
import { IIsolationModeVaultFactory } from "./interfaces/IIsolationModeVaultFactory.sol";


/**
 * @title   IsolationModeUpgradeableProxy
 * @author  Dolomite
 *
 * @notice  Abstract "implementation" (for an upgradeable proxy) contract for wrapping tokens via a per-user vault that
 *          can be used with DolomiteMargin
 */
contract IsolationModeUpgradeableProxy is
    IIsolationModeUpgradeableProxy,
    ProxyContractHelpers
{

    // ============ Constants ============

    bytes32 private constant _FILE = "IsolationModeUpgradeableProxy";
    bytes32 private constant _IS_INITIALIZED_SLOT = bytes32(uint256(keccak256("eip1967.proxy.isInitialized")) - 1);
    bytes32 private constant _VAULT_FACTORY_SLOT = bytes32(uint256(keccak256("eip1967.proxy.vaultFactory")) - 1);
    bytes32 private constant _OWNER_SLOT = bytes32(uint256(keccak256("eip1967.proxy.owner")) - 1);

    // ======== Modifiers =========

    modifier requireIsInitialized() {
        Require.that(
            isInitialized(),
            _FILE,
            "Not initialized"
        );
        _;
    }

    // ============ Constructor ============

    constructor() {
        _setAddress(_VAULT_FACTORY_SLOT, msg.sender);
    }

    // ============ Functions ============

    receive() external payable {} // solhint-disable-line no-empty-blocks

    // solhint-disable-next-line payable-fallback
    fallback() external payable requireIsInitialized {
        _callImplementation(implementation());
    }

    function initialize(
        address _account
    ) external {
        Require.that(
            !isInitialized(),
            _FILE,
            "Already initialized"
        );
        Require.that(
            IIsolationModeVaultFactory(vaultFactory()).getVaultByAccount(_account) == address(this),
            _FILE,
            "Invalid account",
            _account
        );
        _setAddress(_OWNER_SLOT, _account);
        _safeDelegateCall(implementation(), abi.encodePacked(IIsolationModeTokenVaultV1.initialize.selector));
        _setUint256(_IS_INITIALIZED_SLOT, 1);
    }

    function implementation() public override view returns (address) {
        return IIsolationModeVaultFactory(vaultFactory()).userVaultImplementation();
    }

    function isInitialized() public override view returns (bool) {
        return _getUint256(_IS_INITIALIZED_SLOT) == 1;
    }

    function vaultFactory() public override view returns (address) {
        return _getAddress(_VAULT_FACTORY_SLOT);
    }

    function owner() public override view returns (address) {
        return _getAddress(_OWNER_SLOT);
    }

    function _safeDelegateCall(address _target, bytes memory _calldata) internal returns (bytes memory) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool isSuccessful, bytes memory result) = _target.delegatecall(_calldata);
        assert(isSuccessful);

        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { Require } from "../protocol/lib/Require.sol";
import { IsolationModeVaultFactory } from "./abstract/IsolationModeVaultFactory.sol";



/**
 * @title   SimpleIsolationModeVaultFactory
 * @author  Dolomite
 *
 * @notice  Contract for wrapping tokens via a per-user vault that credits a user's balance within DolomiteMargin
 */
abstract contract SimpleIsolationModeVaultFactory is IsolationModeVaultFactory {

    // ===================================================
    // ==================== Constants ====================
    // ===================================================

    bytes32 private constant _FILE = "SimpleIsolationModeVaultFactory";

    // ================================================
    // ==================== Fields ====================
    // ================================================

    uint256[] internal _allowableDebtMarketIds;
    uint256[] internal _allowableCollateralMarketIds;

    // ===================================================
    // ===================== Events ======================
    // ===================================================

    event AllowableDebtMarketIdsSet(uint256[] allowableDebtMarketIds);
    event AllowableCollateralMarketIdsSet(uint256[] allowableCollateralMarketIds);

    // ================================================
    // ================== Constructor =================
    // ================================================

    constructor(
        uint256[] memory _initialAllowableDebtMarketIds,
        uint256[] memory _initialAllowableCollateralMarketIds,
        address _underlyingToken,
        address _borrowPositionProxyV2,
        address _userVaultImplementation,
        address _dolomiteMargin
    ) IsolationModeVaultFactory(
        _underlyingToken,
        _borrowPositionProxyV2,
        _userVaultImplementation,
        _dolomiteMargin
    ) {
        _ownerSetAllowableDebtMarketIds(_initialAllowableDebtMarketIds);
        _ownerSetAllowableCollateralMarketIds(_initialAllowableCollateralMarketIds);
    }

    function ownerSetAllowableDebtMarketIds(
        uint256[] calldata _newAllowableDebtMarketIds
    )
    external
    virtual
    onlyDolomiteMarginOwner(msg.sender) {
        _ownerSetAllowableDebtMarketIds(_newAllowableDebtMarketIds);
    }

    function ownerSetAllowableCollateralMarketIds(
        uint256[] calldata _newAllowableCollateralMarketIds
    )
    external
    virtual
    onlyDolomiteMarginOwner(msg.sender) {
        _ownerSetAllowableCollateralMarketIds(_newAllowableCollateralMarketIds);
    }

    function allowableDebtMarketIds() external view returns (uint256[] memory) {
        return _allowableDebtMarketIds;
    }

    function allowableCollateralMarketIds() external view returns (uint256[] memory) {
        return _allowableCollateralMarketIds;
    }

    // ================================================
    // =============== Internal Methods ===============
    // ================================================

    function _ownerSetAllowableDebtMarketIds(
        uint256[] memory _newAllowableDebtMarketIds
    ) internal virtual {
        uint256 len = _newAllowableDebtMarketIds.length;
        for (uint256 i; i < len; i++) {
            Require.that(
                !DOLOMITE_MARGIN().getMarketIsClosing(_newAllowableDebtMarketIds[i]),
                _FILE,
                "Market cannot be closing"
            );
        }

        _allowableDebtMarketIds = _newAllowableDebtMarketIds;
        emit AllowableDebtMarketIdsSet(_newAllowableDebtMarketIds);
    }

    function _ownerSetAllowableCollateralMarketIds(
        uint256[] memory _newAllowableCollateralMarketIds
    ) internal virtual {
        _allowableCollateralMarketIds = _newAllowableCollateralMarketIds;
        emit AllowableCollateralMarketIdsSet(_newAllowableCollateralMarketIds);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { AccountBalanceLib } from "./AccountBalanceLib.sol";
import { ChainHelperLib } from "./ChainHelperLib.sol";
import { IExpiry } from "../interfaces/IExpiry.sol";
import { IDolomiteMargin } from "../protocol/interfaces/IDolomiteMargin.sol";
import { IDolomiteStructs } from "../protocol/interfaces/IDolomiteStructs.sol";
import { Require } from "../protocol/lib/Require.sol";


/**
 * @title   AccountActionLib
 * @author  Dolomite
 *
 * @notice  Library contract that makes specific actions easy to call
 */
library AccountActionLib {

    // ============ Constants ============

    bytes32 private constant _FILE = "AccountActionLib";

    uint256 private constant _ALL = type(uint256).max;

    // ===================================================================
    // ========================= Write Functions =========================
    // ===================================================================

    function deposit(
        IDolomiteMargin _dolomiteMargin,
        address _accountOwner,
        address _fromAccount,
        uint256 _toAccountNumber,
        uint256 _marketId,
        IDolomiteMargin.AssetAmount memory _amount
    ) internal {
        IDolomiteStructs.AccountInfo[] memory accounts = new IDolomiteStructs.AccountInfo[](1);
        accounts[0] = IDolomiteStructs.AccountInfo({
            owner: _accountOwner,
            number: _toAccountNumber
        });

        IDolomiteStructs.ActionArgs[] memory actions = new IDolomiteStructs.ActionArgs[](1);
        actions[0] = encodeDepositAction(
            /* _accountId = */ 0,
            _marketId,
            _amount,
            _fromAccount
        );

        _dolomiteMargin.operate(accounts, actions);
    }

    /**
     *  Withdraws `_marketId` from `_fromAccount` to `_toAccount`
     */
    function withdraw(
        IDolomiteMargin _dolomiteMargin,
        address _accountOwner,
        uint256 _fromAccountNumber,
        address _toAccount,
        uint256 _marketId,
        IDolomiteStructs.AssetAmount memory _amount,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) internal {
        IDolomiteStructs.AccountInfo[] memory accounts = new IDolomiteStructs.AccountInfo[](1);
        accounts[0] = IDolomiteStructs.AccountInfo({
            owner: _accountOwner,
            number: _fromAccountNumber
        });

        IDolomiteStructs.ActionArgs[] memory actions = new IDolomiteStructs.ActionArgs[](1);
        actions[0] = encodeWithdrawalAction(
            /* _accountId = */ 0,
            _marketId,
            _amount,
            _toAccount
        );

        _dolomiteMargin.operate(accounts, actions);

        if (
            _balanceCheckFlag == AccountBalanceLib.BalanceCheckFlag.Both
            || _balanceCheckFlag == AccountBalanceLib.BalanceCheckFlag.From
        ) {
            AccountBalanceLib.verifyBalanceIsNonNegative(
                _dolomiteMargin,
                accounts[0].owner,
                _fromAccountNumber,
                _marketId
            );
        }
    }

    /**
     * Transfers `_marketId` from `_fromAccount` to `_toAccount`
     */
    function transfer(
        IDolomiteMargin _dolomiteMargin,
        address _fromAccountOwner,
        uint256 _fromAccountNumber,
        address _toAccountOwner,
        uint256 _toAccountNumber,
        uint256 _marketId,
        IDolomiteStructs.AssetDenomination _amountDenomination,
        uint256 _amount,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) internal {
        IDolomiteStructs.AccountInfo[] memory accounts = new IDolomiteStructs.AccountInfo[](2);
        accounts[0] = IDolomiteStructs.AccountInfo({
            owner: _fromAccountOwner,
            number: _fromAccountNumber
        });
        accounts[1] = IDolomiteStructs.AccountInfo({
            owner: _toAccountOwner,
            number: _toAccountNumber
        });

        IDolomiteStructs.ActionArgs[] memory actions = new IDolomiteStructs.ActionArgs[](1);
        actions[0] = encodeTransferAction(
            /* _fromAccountId = */ 0,
            /* _toAccountId = */ 1,
            _marketId,
            _amountDenomination,
            _amount
        );

        _dolomiteMargin.operate(accounts, actions);

        if (
            _balanceCheckFlag == AccountBalanceLib.BalanceCheckFlag.Both
            || _balanceCheckFlag == AccountBalanceLib.BalanceCheckFlag.From
        ) {
            AccountBalanceLib.verifyBalanceIsNonNegative(
                _dolomiteMargin,
                _fromAccountOwner,
                _fromAccountNumber,
                _marketId
            );
        }

        if (
            _balanceCheckFlag == AccountBalanceLib.BalanceCheckFlag.Both
            || _balanceCheckFlag == AccountBalanceLib.BalanceCheckFlag.To
        ) {
            AccountBalanceLib.verifyBalanceIsNonNegative(
                _dolomiteMargin,
                _toAccountOwner,
                _toAccountNumber,
                _marketId
            );
        }
    }

    // ===============================================================
    // ========================= Pure Functions ======================
    // ===============================================================

    function all() internal pure returns (uint256) {
        return _ALL;
    }

    function encodeCallAction(
        uint256 _accountId,
        address _callee,
        bytes memory _callData
    ) internal pure returns (IDolomiteStructs.ActionArgs memory) {
        return IDolomiteStructs.ActionArgs({
            actionType : IDolomiteStructs.ActionType.Call,
            accountId : _accountId,
            amount : IDolomiteStructs.AssetAmount({
                sign: false,
                denomination: IDolomiteStructs.AssetDenomination.Wei,
                ref: IDolomiteStructs.AssetReference.Delta,
                value: 0
            }),
            primaryMarketId : 0,
            secondaryMarketId : 0,
            otherAddress : _callee,
            otherAccountId : 0,
            data : _callData
        });
    }

    function encodeDepositAction(
        uint256 _accountId,
        uint256 _marketId,
        IDolomiteStructs.AssetAmount memory _amount,
        address _fromAccount
    ) internal pure returns (IDolomiteStructs.ActionArgs memory) {
        return IDolomiteStructs.ActionArgs({
            actionType: IDolomiteStructs.ActionType.Deposit,
            accountId: _accountId,
            amount: _amount,
            primaryMarketId: _marketId,
            secondaryMarketId: 0,
            otherAddress: _fromAccount,
            otherAccountId: 0,
            data: bytes("")
        });
    }

    function encodeExpirationAction(
        IDolomiteStructs.AccountInfo memory _account,
        uint256 _accountId,
        uint256 _owedMarketId,
        address _expiry,
        uint256 _expiryTimeDelta
    ) internal pure returns (IDolomiteStructs.ActionArgs memory) {
        Require.that(
            _expiryTimeDelta == uint32(_expiryTimeDelta),
            _FILE,
            "Invalid expiry time delta"
        );

        IExpiry.SetExpiryArg[] memory expiryArgs = new IExpiry.SetExpiryArg[](1);
        expiryArgs[0] = IExpiry.SetExpiryArg({
            account : _account,
            marketId : _owedMarketId,
            timeDelta : uint32(_expiryTimeDelta),
            forceUpdate : true
        });

        return encodeCallAction(
            _accountId,
            _expiry,
            abi.encode(IExpiry.CallFunctionType.SetExpiry, expiryArgs)
        );
    }

    function encodeExpiryLiquidateAction(
        uint256 _solidAccountId,
        uint256 _liquidAccountId,
        uint256 _owedMarketId,
        uint256 _heldMarketId,
        address _expiryProxy,
        uint32 _expiry,
        bool _flipMarkets
    ) internal pure returns (IDolomiteStructs.ActionArgs memory) {
        return IDolomiteStructs.ActionArgs({
            actionType: IDolomiteStructs.ActionType.Trade,
            accountId: _solidAccountId,
            amount: IDolomiteStructs.AssetAmount({
                sign: false,
                denomination: IDolomiteStructs.AssetDenomination.Wei,
                ref: IDolomiteStructs.AssetReference.Target,
                value: 0
            }),
            primaryMarketId: !_flipMarkets ? _owedMarketId : _heldMarketId,
            secondaryMarketId: !_flipMarkets ? _heldMarketId : _owedMarketId,
            otherAddress: _expiryProxy,
            otherAccountId: _liquidAccountId,
            data: abi.encode(_owedMarketId, _expiry)
        });
    }

    function encodeLiquidateAction(
        uint256 _solidAccountId,
        uint256 _liquidAccountId,
        uint256 _owedMarketId,
        uint256 _heldMarketId,
        uint256 _owedWeiToLiquidate
    ) internal pure returns (IDolomiteStructs.ActionArgs memory) {
        return IDolomiteStructs.ActionArgs({
            actionType: IDolomiteStructs.ActionType.Liquidate,
            accountId: _solidAccountId,
            amount: IDolomiteStructs.AssetAmount({
                sign: true,
                denomination: IDolomiteStructs.AssetDenomination.Wei,
                ref: IDolomiteStructs.AssetReference.Delta,
                value: _owedWeiToLiquidate
            }),
            primaryMarketId: _owedMarketId,
            secondaryMarketId: _heldMarketId,
            otherAddress: address(0),
            otherAccountId: _liquidAccountId,
            data: new bytes(0)
        });
    }

    function encodeExternalSellActionWithTarget(
        uint256 _fromAccountId,
        uint256 _primaryMarketId,
        uint256 _secondaryMarketId,
        address _trader,
        uint256 _targetAmountWei,
        uint256 _amountOutMinWei,
        bytes memory _orderData
    ) internal pure returns (IDolomiteStructs.ActionArgs memory) {
    IDolomiteStructs.AssetAmount memory assetAmount;
        assetAmount = IDolomiteStructs.AssetAmount({
            sign: true,
            denomination: IDolomiteStructs.AssetDenomination.Wei,
            ref: IDolomiteStructs.AssetReference.Target,
            value: _targetAmountWei
        });

        return IDolomiteStructs.ActionArgs({
            actionType : IDolomiteStructs.ActionType.Sell,
            accountId : _fromAccountId,
            amount : assetAmount,
            primaryMarketId : _primaryMarketId,
            secondaryMarketId : _secondaryMarketId,
            otherAddress : _trader,
            otherAccountId : 0,
            data : abi.encode(_amountOutMinWei, _orderData)
        });
    }

    function encodeExternalSellAction(
        uint256 _fromAccountId,
        uint256 _primaryMarketId,
        uint256 _secondaryMarketId,
        address _trader,
        uint256 _amountInWei,
        uint256 _amountOutMinWei,
        bytes memory _orderData
    ) internal pure returns (IDolomiteStructs.ActionArgs memory) {
        IDolomiteStructs.AssetAmount memory assetAmount;
        if (_amountInWei == _ALL) {
            assetAmount = IDolomiteStructs.AssetAmount({
                sign: false,
                denomination: IDolomiteStructs.AssetDenomination.Wei,
                ref: IDolomiteStructs.AssetReference.Target,
                value: 0
            });
        } else {
            assetAmount = IDolomiteStructs.AssetAmount({
                sign: false,
                denomination: IDolomiteStructs.AssetDenomination.Wei,
                ref: IDolomiteStructs.AssetReference.Delta,
                value: _amountInWei
            });
        }

        return IDolomiteStructs.ActionArgs({
            actionType : IDolomiteStructs.ActionType.Sell,
            accountId : _fromAccountId,
            amount : assetAmount,
            primaryMarketId : _primaryMarketId,
            secondaryMarketId : _secondaryMarketId,
            otherAddress : _trader,
            otherAccountId : 0,
            data : abi.encode(_amountOutMinWei, _orderData)
        });
    }

    function encodeInternalTradeAction(
        uint256 _fromAccountId,
        uint256 _toAccountId,
        uint256 _primaryMarketId,
        uint256 _secondaryMarketId,
        address _traderAddress,
        uint256 _amountInWei,
        uint256 _chainId,
        bool _calculateAmountWithMakerAccount,
        bytes memory _orderData
    ) internal pure returns (IDolomiteStructs.ActionArgs memory) {
        return IDolomiteStructs.ActionArgs({
            actionType: IDolomiteStructs.ActionType.Trade,
            accountId: _fromAccountId,
            amount: IDolomiteStructs.AssetAmount({
                sign: true,
                denomination: IDolomiteStructs.AssetDenomination.Wei,
                ref: IDolomiteStructs.AssetReference.Delta,
                value: _amountInWei
            }),
            primaryMarketId: _primaryMarketId,
            secondaryMarketId: _secondaryMarketId,
            otherAddress: _traderAddress,
            otherAccountId: _toAccountId,
            data: ChainHelperLib.isArbitrum(_chainId)
                ? _orderData
                : abi.encode(_calculateAmountWithMakerAccount, _orderData)
        });
    }

    function encodeTransferAction(
        uint256 _fromAccountId,
        uint256 _toAccountId,
        uint256 _marketId,
        IDolomiteStructs.AssetDenomination _amountDenomination,
        uint256 _amount
    ) internal pure returns (IDolomiteStructs.ActionArgs memory) {
        IDolomiteStructs.AssetAmount memory assetAmount;
        if (_amount == _ALL) {
            assetAmount = IDolomiteStructs.AssetAmount({
                sign: false,
                denomination: _amountDenomination,
                ref: IDolomiteStructs.AssetReference.Target,
                value: 0
            });
        } else {
            assetAmount = IDolomiteStructs.AssetAmount({
                sign: false,
                denomination: _amountDenomination,
                ref: IDolomiteStructs.AssetReference.Delta,
                value: _amount
            });
        }
        return IDolomiteStructs.ActionArgs({
            actionType : IDolomiteStructs.ActionType.Transfer,
            accountId : _fromAccountId,
            amount : assetAmount,
            primaryMarketId : _marketId,
            secondaryMarketId : 0,
            otherAddress : address(0),
            otherAccountId : _toAccountId,
            data : bytes("")
        });
    }

    function encodeWithdrawalAction(
        uint256 _accountId,
        uint256 _marketId,
        IDolomiteStructs.AssetAmount memory _amount,
        address _toAccount
    ) internal pure returns (IDolomiteStructs.ActionArgs memory) {
        return IDolomiteStructs.ActionArgs({
            actionType: IDolomiteStructs.ActionType.Withdraw,
            accountId: _accountId,
            amount: _amount,
            primaryMarketId: _marketId,
            secondaryMarketId: 0,
            otherAddress: _toAccount,
            otherAccountId: 0,
            data: bytes("")
        });
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteMargin } from "../protocol/interfaces/IDolomiteMargin.sol";
import { IDolomiteStructs } from "../protocol/interfaces/IDolomiteStructs.sol";

import { Require } from "../protocol/lib/Require.sol";
import { TypesLib } from "../protocol/lib/TypesLib.sol";


/**
 * @title   AccountBalanceLib
 * @author  Dolomite
 *
 * @notice  Library contract that checks a user's balance after transaction to be non-negative
 */
library AccountBalanceLib {
    using TypesLib for IDolomiteStructs.Par;

    // ============ Types ============

    /// Checks that either BOTH, FROM, or TO accounts all have non-negative balances
    enum BalanceCheckFlag {
        Both,
        From,
        To,
        None
    }

    // ============ Constants ============

    bytes32 private constant _FILE = "AccountBalanceLib";

    // ============ Functions ============

    /**
     *  Checks that the account's balance is non-negative. Reverts if the check fails
     */
    function verifyBalanceIsNonNegative(
        IDolomiteMargin dolomiteMargin,
        address _accountOwner,
        uint256 _accountNumber,
        uint256 _marketId
    ) internal view {
        IDolomiteStructs.AccountInfo memory account = IDolomiteStructs.AccountInfo({
            owner: _accountOwner,
            number: _accountNumber
        });
        IDolomiteStructs.Par memory par = dolomiteMargin.getAccountPar(account, _marketId);
        Require.that(
            par.isPositive() || par.isZero(),
            _FILE,
            "account cannot go negative",
            _accountOwner,
            _accountNumber,
            _marketId
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;


/**
 * @title   ChainHelperLib
 * @author  Dolomite
 *
 * @notice  Library contract that discovers which chain we're on
 */
library ChainHelperLib {

    // ============ Constants ============

    bytes32 private constant _FILE = "ChainHelperLib";
    uint256 private constant _ARBITRUM_ONE = 42161;
    uint256 private constant _ARBITRUM_SEPOLIA = 421614;

    // ============ Functions ============

    function isArbitrum(uint256 chainId) internal pure returns (bool) {
        return chainId == _ARBITRUM_ONE || chainId == _ARBITRUM_SEPOLIA;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { ChainHelperLib } from "./ChainHelperLib.sol";
import { IExpiry } from "../interfaces/IExpiry.sol";
import { IExpiryV2 } from "../interfaces/IExpiryV2.sol";
import { IDolomiteMargin } from "../protocol/interfaces/IDolomiteMargin.sol";
import { IDolomiteMarginV2 } from "../protocol/interfaces/IDolomiteMarginV2.sol";
import { IDolomiteStructs } from "../protocol/interfaces/IDolomiteStructs.sol";


/**
 * @title   DolomiteMarginVersionWrapperLib
 * @author  Dolomite
 *
 * @notice  Library contract that discovers which chain we're on
 */
library DolomiteMarginVersionWrapperLib {
    using DolomiteMarginVersionWrapperLib for *;

    // ============ Constants ============

    bytes32 private constant _FILE = "DolomiteMarginVersionWrapperLib";

    // ===========================================
    // ============= Public Functions ============
    // ===========================================

    function getVersionedLiquidationSpreadForPair(
        IDolomiteMargin _dolomiteMargin,
        uint256 _chainId,
        IDolomiteStructs.AccountInfo memory _liquidAccount,
        uint256 _heldMarketId,
        uint256 _owedMarketId
    ) internal view returns (IDolomiteStructs.Decimal memory) {
        if (ChainHelperLib.isArbitrum(_chainId)) {
            return _dolomiteMargin.getLiquidationSpreadForPair(_heldMarketId, _owedMarketId);
        } else {
            return dv2(_dolomiteMargin).getLiquidationSpreadForAccountAndPair(
                _liquidAccount,
                _heldMarketId,
                _owedMarketId
            );
        }
    }

    function getVersionedSpreadAdjustedPrices(
        IExpiry _expiry,
        uint256 _chainId,
        IDolomiteStructs.AccountInfo memory _liquidAccount,
        uint256 _heldMarketId,
        uint256 _owedMarketId,
        uint32 _expiration
    ) internal view returns (
        IDolomiteStructs.MonetaryPrice memory heldPrice,
        IDolomiteStructs.MonetaryPrice memory owedPriceAdj
    ) {
        if (ChainHelperLib.isArbitrum(_chainId)) {
            (heldPrice, owedPriceAdj) = _expiry.getSpreadAdjustedPrices(_heldMarketId, _owedMarketId, _expiration);
        } else {
            (heldPrice, owedPriceAdj) = ev2(_expiry).getLiquidationSpreadAdjustedPrices(
                _liquidAccount,
                _heldMarketId,
                _owedMarketId,
                _expiration
            );
        }
    }

    // ===========================================
    // ============ Private Functions ============
    // ===========================================

    function dv2(IDolomiteMargin _dolomiteMargin) private pure returns (IDolomiteMarginV2) {
        return IDolomiteMarginV2(address(_dolomiteMargin));
    }

    function ev2(IExpiry _expiry) private pure returns (IExpiryV2) {
        return IExpiryV2(address(_expiry));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteMargin } from "../protocol/interfaces/IDolomiteMargin.sol";
import { IDolomiteStructs } from "../protocol/interfaces/IDolomiteStructs.sol";
import { DolomiteMarginMath } from "../protocol/lib/DolomiteMarginMath.sol";



/**
 * @title   InterestIndexLib
 * @author  Dolomite
 *
 * @notice  Library contract that checks a user's balance after transaction to be non-negative
 */
library InterestIndexLib {
    using DolomiteMarginMath for uint256;

    // ============ Constants ============

    bytes32 private constant _FILE = "InterestIndexLib";
    uint256 private constant _BASE = 1e18;

    // ============ Functions ============

    /**
     *  Converts the scaled Par value to an actual Wei value
     */
    function parToWei(
        IDolomiteMargin dolomiteMargin,
        uint256 _marketId,
        IDolomiteStructs.Par memory _amountPar
    ) internal view returns (IDolomiteStructs.Wei memory) {
        IDolomiteStructs.InterestIndex memory index = dolomiteMargin.getMarketCurrentIndex(_marketId);
        if (_amountPar.sign) {
            return IDolomiteStructs.Wei({
                sign: true,
                value: uint256(_amountPar.value).getPartialRoundHalfUp(index.supply, _BASE)
            });
        } else {
            return IDolomiteStructs.Wei({
                sign: false,
                value: uint256(_amountPar.value).getPartialRoundHalfUp(index.borrow, _BASE).to128()
            });
        }
    }

    /**
     *  Converts an actual Wei value to a scaled Par value
     */
    function weiToPar(
        IDolomiteMargin dolomiteMargin,
        uint256 _marketId,
        IDolomiteStructs.Wei memory _amountWei
    ) internal view returns (IDolomiteStructs.Par memory) {
        IDolomiteStructs.InterestIndex memory index = dolomiteMargin.getMarketCurrentIndex(_marketId);
        if (_amountWei.sign) {
            return IDolomiteStructs.Par({
                sign: true,
                value: _amountWei.value.getPartialRoundHalfUp(_BASE, index.supply).to128()
            });
        } else {
            return IDolomiteStructs.Par({
                sign: false,
                value: _amountWei.value.getPartialRoundHalfUp(_BASE, index.borrow).to128()
            });
        }
    }

    /*
     * Convert a principal amount to a token amount given an index.
     */
    function parToWei(
        IDolomiteStructs.Par memory input,
        IDolomiteStructs.InterestIndex memory index
    )
        internal
        pure
        returns (IDolomiteStructs.Wei memory)
    {
        uint256 inputValue = uint256(input.value);
        if (input.sign) {
            return IDolomiteStructs.Wei({
                sign: true,
                value: inputValue.getPartialRoundHalfUp(index.supply, _BASE)
            });
        } else {
            return IDolomiteStructs.Wei({
                sign: false,
                value: inputValue.getPartialRoundHalfUp(index.borrow, _BASE)
            });
        }
    }

    /*
     * Convert a token amount to a principal amount given an index.
     */
    function weiToPar(
        IDolomiteStructs.Wei memory input,
        IDolomiteStructs.InterestIndex memory index
    )
        internal
        pure
        returns (IDolomiteStructs.Par memory)
    {
        if (input.sign) {
            return IDolomiteStructs.Par({
                sign: true,
                value: input.value.getPartialRoundHalfUp(_BASE, index.supply).to128()
            });
        } else {
            return IDolomiteStructs.Par({
                sign: false,
                value: input.value.getPartialRoundHalfUp(_BASE, index.borrow).to128()
            });
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { Require } from "../protocol/lib/Require.sol";


/**
 * @title   ValidationLib
 * @author  Dolomite
 *
 * @notice  Library contract that checks generic calls to be successful (useful when validation config changes)
 */
library ValidationLib {
    // ============ Constants ============

    bytes32 private constant _FILE = "ValidationLib";

    // ============ Functions ============

    /**
     *  Converts the scaled Par value to an actual Wei value
     */
    function callAndCheckSuccess(
        address _target,
        bytes4 _selector,
        bytes memory _data
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returnData) = _target.staticcall(abi.encodePacked(_selector, _data));
        Require.that(
            success && returnData.length > 0,
            _FILE,
            "Call to target failed",
            _target
        );
        return returnData;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.8.9;

import { IDolomiteStructs } from "./IDolomiteStructs.sol";


/**
 * @title   IDolomiteAccountRiskOverrideSetter
 * @author  Dolomite
 *
 * @notice  Interface that can be implemented by any contract that needs to implement risk overrides for an account.
 */
interface IDolomiteAccountRiskOverrideSetter {

    /**
     * @notice  Gets the risk overrides for a given account owner.
     *
     * @param  _accountOwner               The owner of the account whose risk override should be retrieved.
     * @return  marginRatioOverride         The margin ratio override for this account.
     * @return  liquidationSpreadOverride   The liquidation spread override for this account.
     */
    function getAccountRiskOverride(
        address _accountOwner
    )
    external
    view
    returns
    (
        IDolomiteStructs.Decimal memory marginRatioOverride,
        IDolomiteStructs.Decimal memory liquidationSpreadOverride
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;


/**
 * @title   IDolomiteInterestSetter
 * @author  Dolomite
 *
 * @notice  This interface defines the functions that for an interest setter that can be used to determine the interest
 *          rate of a market.
 */
interface IDolomiteInterestSetter {

    // ============ Enum ============

    enum InterestSetterType {
        None,
        Linear,
        DoubleExponential,
        Other
    }

    // ============ Structs ============

    struct InterestRate {
        uint256 value;
    }

    // ============ Functions ============

    /**
     * Get the interest rate of a token given some borrowed and supplied amounts
     *
     * @param  token        The address of the ERC20 token for the market
     * @param  borrowWei    The total borrowed token amount for the market
     * @param  supplyWei    The total supplied token amount for the market
     * @return              The interest rate per second
     */
    function getInterestRate(
        address token,
        uint256 borrowWei,
        uint256 supplyWei
    )
    external
    view
    returns (InterestRate memory);

    function interestSetterType() external pure returns (InterestSetterType);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteInterestSetter } from "./IDolomiteInterestSetter.sol";
import { IDolomiteMarginAdmin } from "./IDolomiteMarginAdmin.sol";
import { IDolomitePriceOracle } from "./IDolomitePriceOracle.sol";


/**
 * @title   IDolomiteMargin
 * @author  Dolomite
 *
 * @notice  The interface for interacting with the main entry-point to DolomiteMargin
 */
interface IDolomiteMargin is IDolomiteMarginAdmin {

    // ==================================================
    // ================= Write Functions ================
    // ==================================================

    /**
     * The main entry-point to DolomiteMargin that allows users and contracts to manage accounts.
     * Take one or more actions on one or more accounts. The msg.sender must be the owner or
     * operator of all accounts except for those being liquidated, vaporized, or traded with.
     * One call to operate() is considered a singular "operation". Account collateralization is
     * ensured only after the completion of the entire operation.
     *
     * @param  accounts  A list of all accounts that will be used in this operation. Cannot contain
     *                   duplicates. In each action, the relevant account will be referred-to by its
     *                   index in the list.
     * @param  actions   An ordered list of all actions that will be taken in this operation. The
     *                   actions will be processed in order.
     */
    function operate(
        AccountInfo[] calldata accounts,
        ActionArgs[] calldata actions
    ) external;

    /**
     * Approves/disapproves any number of operators. An operator is an external address that has the
     * same permissions to manipulate an account as the owner of the account. Operators are simply
     * addresses and therefore may either be externally-owned Ethereum accounts OR smart contracts.
     *
     * Operators are also able to act as AutoTrader contracts on behalf of the account owner if the
     * operator is a smart contract and implements the IAutoTrader interface.
     *
     * @param  args  A list of OperatorArgs which have an address and a boolean. The boolean value
     *               denotes whether to approve (true) or revoke approval (false) for that address.
     */
    function setOperators(
        OperatorArg[] calldata args
    ) external;

    // ==================================================
    // ================= Read Functions ================
    // ==================================================

    // ============ Getters for Markets ============

    /**
     * Get the ERC20 token address for a market.
     *
     * @param  token    The token to query
     * @return          The token's marketId if the token is valid
     */
    function getMarketIdByTokenAddress(
        address token
    ) external view returns (uint256);

    /**
     * Get the ERC20 token address for a market.
     *
     * @param  marketId  The market to query
     * @return           The token address
     */
    function getMarketTokenAddress(
        uint256 marketId
    ) external view returns (address);

    /**
     * Return the maximum amount of the market that can be supplied on Dolomite. Always 0 or positive.
     *
     * @param  marketId  The market to query
     * @return           The max amount of the market that can be supplied
     */
    function getMarketMaxWei(
        uint256 marketId
    ) external view returns (Wei memory);

    /**
     * Return true if a particular market is in closing mode. Additional borrows cannot be taken
     * from a market that is closing.
     *
     * @param  marketId  The market to query
     * @return           True if the market is closing
     */
    function getMarketIsClosing(
        uint256 marketId
    )
    external
    view
    returns (bool);

    /**
     * Get the price of the token for a market.
     *
     * @param  marketId  The market to query
     * @return           The price of each atomic unit of the token
     */
    function getMarketPrice(
        uint256 marketId
    ) external view returns (MonetaryPrice memory);

    /**
     * Get the total number of markets.
     *
     * @return  The number of markets
     */
    function getNumMarkets() external view returns (uint256);

    /**
     * Get the total principal amounts (borrowed and supplied) for a market.
     *
     * @param  marketId  The market to query
     * @return           The total principal amounts
     */
    function getMarketTotalPar(
        uint256 marketId
    ) external view returns (TotalPar memory);

    /**
     * Get the most recently cached interest index for a market.
     *
     * @param  marketId  The market to query
     * @return           The most recent index
     */
    function getMarketCachedIndex(
        uint256 marketId
    ) external view returns (InterestIndex memory);

    /**
     * Get the interest index for a market if it were to be updated right now.
     *
     * @param  marketId  The market to query
     * @return           The estimated current index
     */
    function getMarketCurrentIndex(
        uint256 marketId
    ) external view returns (InterestIndex memory);

    /**
     * Get the price oracle address for a market.
     *
     * @param  marketId  The market to query
     * @return           The price oracle address
     */
    function getMarketPriceOracle(
        uint256 marketId
    ) external view returns (IDolomitePriceOracle);

    /**
     * Get the interest-setter address for a market.
     *
     * @param  marketId  The market to query
     * @return           The interest-setter address
     */
    function getMarketInterestSetter(
        uint256 marketId
    ) external view returns (IDolomiteInterestSetter);

    /**
     * Get the margin premium for a market. A margin premium makes it so that any positions that
     * include the market require a higher collateralization to avoid being liquidated.
     *
     * @param  marketId  The market to query
     * @return           The market's margin premium
     */
    function getMarketMarginPremium(
        uint256 marketId
    ) external view returns (Decimal memory);

    /**
     * Get the spread premium for a market. A spread premium makes it so that any liquidations
     * that include the market have a higher spread than the global default.
     *
     * @param  marketId  The market to query
     * @return           The market's spread premium
     */
    function getMarketSpreadPremium(
        uint256 marketId
    ) external view returns (Decimal memory);

    /**
     * Return true if this market can be removed and its ID can be recycled and reused
     *
     * @param  marketId  The market to query
     * @return           True if the market is recyclable
     */
    function getMarketIsRecyclable(
        uint256 marketId
    ) external view returns (bool);

    /**
     * Gets the recyclable markets, up to `n` length. If `n` is greater than the length of the list, 0's are returned
     * for the empty slots.
     *
     * @param  n    The number of markets to get, bounded by the linked list being smaller than `n`
     * @return      The list of recyclable markets, in the same order held by the linked list
     */
    function getRecyclableMarkets(
        uint256 n
    ) external view returns (uint[] memory);

    /**
     * Get the current borrower interest rate for a market.
     *
     * @param  marketId  The market to query
     * @return           The current interest rate
     */
    function getMarketInterestRate(
        uint256 marketId
    ) external view returns (IDolomiteInterestSetter.InterestRate memory);

    /**
     * Get basic information about a particular market.
     *
     * @param  marketId  The market to query
     * @return           A Market struct with the current state of the market
     */
    function getMarket(
        uint256 marketId
    ) external view returns (Market memory);

    /**
     * Get comprehensive information about a particular market.
     *
     * @param  marketId  The market to query
     * @return           A tuple containing the values:
     *                    - A Market struct with the current state of the market
     *                    - The current estimated interest index
     *                    - The current token price
     *                    - The current market interest rate
     */
    function getMarketWithInfo(
        uint256 marketId
    )
    external
    view
    returns (
        Market memory,
        InterestIndex memory,
        MonetaryPrice memory,
        IDolomiteInterestSetter.InterestRate memory
    );

    /**
     * Get the number of excess tokens for a market. The number of excess tokens is calculated by taking the current
     * number of tokens held in DolomiteMargin, adding the number of tokens owed to DolomiteMargin by borrowers, and
     * subtracting the number of tokens owed to suppliers by DolomiteMargin.
     *
     * @param  marketId  The market to query
     * @return           The number of excess tokens
     */
    function getNumExcessTokens(
        uint256 marketId
    ) external view returns (Wei memory);

    // ============ Getters for Accounts ============

    /**
     * Get the principal value for a particular account and market.
     *
     * @param  account   The account to query
     * @param  marketId  The market to query
     * @return           The principal value
     */
    function getAccountPar(
        AccountInfo calldata account,
        uint256 marketId
    ) external view returns (Par memory);

    /**
     * Get the principal value for a particular account and market, with no check the market is valid. Meaning, markets
     * that don't exist return 0.
     *
     * @param  account   The account to query
     * @param  marketId  The market to query
     * @return           The principal value
     */
    function getAccountParNoMarketCheck(
        AccountInfo calldata account,
        uint256 marketId
    ) external view returns (Par memory);

    /**
     * Get the token balance for a particular account and market.
     *
     * @param  account   The account to query
     * @param  marketId  The market to query
     * @return           The token amount
     */
    function getAccountWei(
        AccountInfo calldata account,
        uint256 marketId
    ) external view returns (Wei memory);

    /**
     * Get the status of an account (Normal, Liquidating, or Vaporizing).
     *
     * @param  account  The account to query
     * @return          The account's status
     */
    function getAccountStatus(
        AccountInfo calldata account
    ) external view returns (AccountStatus);

    /**
     * Get a list of markets that have a non-zero balance for an account
     *
     * @param  account  The account to query
     * @return          The non-sorted marketIds with non-zero balance for the account.
     */
    function getAccountMarketsWithBalances(
        AccountInfo calldata account
    ) external view returns (uint256[] memory);

    /**
     * Get the number of markets that have a non-zero balance for an account
     *
     * @param  account  The account to query
     * @return          The non-sorted marketIds with non-zero balance for the account.
     */
    function getAccountNumberOfMarketsWithBalances(
        AccountInfo calldata account
    ) external view returns (uint256);

    /**
     * Get the marketId for an account's market with a non-zero balance at the given index
     *
     * @param  account  The account to query
     * @return          The non-sorted marketIds with non-zero balance for the account.
     */
    function getAccountMarketWithBalanceAtIndex(
        AccountInfo calldata account,
        uint256 index
    ) external view returns (uint256);

    /**
     * Get the number of markets with which an account has a negative balance.
     *
     * @param  account  The account to query
     * @return          The non-sorted marketIds with non-zero balance for the account.
     */
    function getAccountNumberOfMarketsWithDebt(
        AccountInfo calldata account
    ) external view returns (uint256);

    /**
     * Get the total supplied and total borrowed value of an account.
     *
     * @param  account  The account to query
     * @return          The following values:
     *                   - The supplied value of the account
     *                   - The borrowed value of the account
     */
    function getAccountValues(
        AccountInfo calldata account
    ) external view returns (MonetaryValue memory, MonetaryValue memory);

    /**
     * Get the total supplied and total borrowed values of an account adjusted by the marginPremium
     * of each market. Supplied values are divided by (1 + marginPremium) for each market and
     * borrowed values are multiplied by (1 + marginPremium) for each market. Comparing these
     * adjusted values gives the margin-ratio of the account which will be compared to the global
     * margin-ratio when determining if the account can be liquidated.
     *
     * @param  account  The account to query
     * @return          The following values:
     *                   - The supplied value of the account (adjusted for marginPremium)
     *                   - The borrowed value of the account (adjusted for marginPremium)
     */
    function getAdjustedAccountValues(
        AccountInfo calldata account
    ) external view returns (MonetaryValue memory, MonetaryValue memory);

    /**
     * Get an account's summary for each market.
     *
     * @param  account  The account to query
     * @return          The following values:
     *                   - The market IDs for each market
     *                   - The ERC20 token address for each market
     *                   - The account's principal value for each market
     *                   - The account's (supplied or borrowed) number of tokens for each market
     */
    function getAccountBalances(
        AccountInfo calldata account
    ) external view returns (uint[] memory, address[] memory, Par[] memory, Wei[] memory);

    // ============ Getters for Account Permissions ============

    /**
     * Return true if a particular address is approved as an operator for an owner's accounts.
     * Approved operators can act on the accounts of the owner as if it were the operator's own.
     *
     * @param  owner     The owner of the accounts
     * @param  operator  The possible operator
     * @return           True if operator is approved for owner's accounts
     */
    function getIsLocalOperator(
        address owner,
        address operator
    ) external view returns (bool);

    /**
     * Return true if a particular address is approved as a global operator. Such an address can
     * act on any account as if it were the operator's own.
     *
     * @param  operator  The address to query
     * @return           True if operator is a global operator
     */
    function getIsGlobalOperator(
        address operator
    ) external view returns (bool);

    /**
     * Checks if the autoTrader can only be called invoked by a global operator
     *
     * @param  autoTrader    The trader that should be checked for special call privileges.
     */
    function getIsAutoTraderSpecial(address autoTrader) external view returns (bool);

    /**
     * @return The address that owns the DolomiteMargin protocol
     */
    function owner() external view returns (address);

    // ============ Getters for Risk Params ============

    /**
     * Get the global minimum margin-ratio that every position must maintain to prevent being
     * liquidated.
     *
     * @return  The global margin-ratio
     */
    function getMarginRatio() external view returns (Decimal memory);

    /**
     * Get the global liquidation spread. This is the spread between oracle prices that incentivizes
     * the liquidation of risky positions.
     *
     * @return  The global liquidation spread
     */
    function getLiquidationSpread() external view returns (Decimal memory);

    /**
     * Get the adjusted liquidation spread for some market pair. This is equal to the global
     * liquidation spread multiplied by (1 + spreadPremium) for each of the two markets.
     *
     * @param  heldMarketId  The market for which the account has collateral
     * @param  owedMarketId  The market for which the account has borrowed tokens
     * @return               The adjusted liquidation spread
     */
    function getLiquidationSpreadForPair(
        uint256 heldMarketId,
        uint256 owedMarketId
    ) external view returns (Decimal memory);

    /**
     * Get the global earnings-rate variable that determines what percentage of the interest paid
     * by borrowers gets passed-on to suppliers.
     *
     * @return  The global earnings rate
     */
    function getEarningsRate() external view returns (Decimal memory);

    /**
     * Get the global minimum-borrow value which is the minimum value of any new borrow on DolomiteMargin.
     *
     * @return  The global minimum borrow value
     */
    function getMinBorrowedValue() external view returns (MonetaryValue memory);

    /**
     * Get all risk parameters in a single struct.
     *
     * @return  All global risk parameters
     */
    function getRiskParams() external view returns (RiskParams memory);

    /**
     * Get all risk parameter limits in a single struct. These are the maximum limits at which the
     * risk parameters can be set by the admin of DolomiteMargin.
     *
     * @return  All global risk parameter limits
     */
    function getRiskLimits() external view returns (RiskLimits memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteInterestSetter } from "./IDolomiteInterestSetter.sol";
import { IDolomitePriceOracle } from "./IDolomitePriceOracle.sol";
import { IDolomiteStructs } from "./IDolomiteStructs.sol";


/**
 * @title   IDolomiteMarginAdmin
 * @author  Dolomite
 *
 * @notice  This interface defines the functions that can be called by the owner of DolomiteMargin.
 */
interface IDolomiteMarginAdmin is IDolomiteStructs {

    // ============ Token Functions ============

    /**
     * Withdraw an ERC20 token for which there is an associated market. Only excess tokens can be withdrawn. The number
     * of excess tokens is calculated by taking the current number of tokens held in DolomiteMargin, adding the number
     * of tokens owed to DolomiteMargin by borrowers, and subtracting the number of tokens owed to suppliers by
     * DolomiteMargin.
     */
    function ownerWithdrawExcessTokens(
        uint256 marketId,
        address recipient
    )
    external
    returns (uint256);

    /**
     * Withdraw an ERC20 token for which there is no associated market.
     */
    function ownerWithdrawUnsupportedTokens(
        address token,
        address recipient
    )
    external
    returns (uint256);

    // ============ Market Functions ============

    /**
     * Sets the number of non-zero balances an account may have within the same `accountIndex`. This ensures a user
     * cannot DOS the system by filling their account with non-zero balances (which linearly increases gas costs when
     * checking collateralization) and disallowing themselves to close the position, because the number of gas units
     * needed to process their transaction exceed the block's gas limit. In turn, this would  prevent the user from also
     * being liquidated, causing the all of the capital to be "stuck" in the position.
     *
     * Lowering this number does not "freeze" user accounts that have more than the new limit of balances, because this
     * variable is enforced by checking the users number of non-zero balances against the max or if it sizes down before
     * each transaction finishes.
     */
    function ownerSetAccountMaxNumberOfMarketsWithBalances(
        uint256 accountMaxNumberOfMarketsWithBalances
    )
    external;

    /**
     * Add a new market to DolomiteMargin. Must be for a previously-unsupported ERC20 token.
     */
    function ownerAddMarket(
        address token,
        IDolomitePriceOracle priceOracle,
        IDolomiteInterestSetter interestSetter,
        Decimal calldata marginPremium,
        Decimal calldata spreadPremium,
        uint256 maxWei,
        bool isClosing,
        bool isRecyclable
    )
    external;

    /**
     * Removes a market from DolomiteMargin, sends any remaining tokens in this contract to `salvager` and invokes the
     * recyclable callback
     */
    function ownerRemoveMarkets(
        uint[] calldata marketIds,
        address salvager
    )
    external;

    /**
     * Set (or unset) the status of a market to "closing". The borrowedValue of a market cannot increase while its
     * status is "closing".
     */
    function ownerSetIsClosing(
        uint256 marketId,
        bool isClosing
    )
    external;

    /**
     * Set the price oracle for a market.
     */
    function ownerSetPriceOracle(
        uint256 marketId,
        IDolomitePriceOracle priceOracle
    )
    external;

    /**
     * Set the interest-setter for a market.
     */
    function ownerSetInterestSetter(
        uint256 marketId,
        IDolomiteInterestSetter interestSetter
    )
    external;

    /**
     * Set a premium on the minimum margin-ratio for a market. This makes it so that any positions that include this
     * market require a higher collateralization to avoid being liquidated.
     */
    function ownerSetMarginPremium(
        uint256 marketId,
        Decimal calldata marginPremium
    )
    external;

    function ownerSetMaxWei(
        uint256 marketId,
        uint256 maxWei
    )
    external;

    /**
     * Set a premium on the liquidation spread for a market. This makes it so that any liquidations that include this
     * market have a higher spread than the global default.
     */
    function ownerSetSpreadPremium(
        uint256 marketId,
        Decimal calldata spreadPremium
    )
    external;

    // ============ Risk Functions ============

    /**
     * Set the global minimum margin-ratio that every position must maintain to prevent being liquidated.
     */
    function ownerSetMarginRatio(
        Decimal calldata ratio
    )
    external;

    /**
     * Set the global liquidation spread. This is the spread between oracle prices that incentivizes the liquidation of
     * risky positions.
     */
    function ownerSetLiquidationSpread(
        Decimal calldata spread
    )
    external;

    /**
     * Set the global earnings-rate variable that determines what percentage of the interest paid by borrowers gets
     * passed-on to suppliers.
     */
    function ownerSetEarningsRate(
        Decimal calldata earningsRate
    )
    external;

    /**
     * Set the global minimum-borrow value which is the minimum value of any new borrow on DolomiteMargin.
     */
    function ownerSetMinBorrowedValue(
        MonetaryValue calldata minBorrowedValue
    )
    external;

    // ============ Global Operator Functions ============

    /**
     * Approve (or disapprove) an address that is permissioned to be an operator for all accounts in DolomiteMargin.
     * Intended only to approve smart-contracts.
     */
    function ownerSetGlobalOperator(
        address operator,
        bool approved
    )
    external;

    /**
     * Approve (or disapprove) an auto trader that can only be called by a global operator. IE for expirations
     */
    function ownerSetAutoTraderSpecial(
        address autoTrader,
        bool special
    )
    external;
}

// SPDX-License-Identifier: Apache-2.0
/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.8.9;

import { IDolomiteMargin } from "./IDolomiteMargin.sol";


/**
 * @title   IDolomiteMarginCallee
 * @author  dYdX
 *
 * @notice  Interface that Callees for DolomiteMargin must implement in order to ingest data.
 */
interface IDolomiteMarginCallee {

    // ============ Public Functions ============

    /**
     * Allows users to send this contract arbitrary data.
     *
     * @param  _sender      The msg.sender to DolomiteMargin
     * @param  _accountInfo The account from which the data is being sent
     * @param  _data        Arbitrary data given by the sender
     */
    function callFunction(
        address _sender,
        IDolomiteMargin.AccountInfo calldata _accountInfo,
        bytes calldata _data
    )
    external;
}

// SPDX-License-Identifier: Apache-2.0
/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.8.9;


/**
 * @title   IDolomiteMarginExchangeWrapper
 * @author  dYdX
 *
 * @notice  Interface that Exchange Wrappers for DolomiteMargin must implement in order to trade ERC20 tokens with
 *          external protocols.
 */
interface IDolomiteMarginExchangeWrapper {

    // ============ Public Functions ============

    /**
     * Exchange some amount of inputToken for outputToken.
     *
     * @param  _tradeOriginator Address of the initiator of the trade (however, this value cannot always be trusted as
     *                          it is set at the discretion of the msg.sender)
     * @param  _receiver        Address to set allowance on once the trade has completed
     * @param  _outputToken     The token to receive (target asset; IE path[path.length - 1])
     * @param  _inputToken      The token to pay (originator asset; IE path[0])
     * @param  _inputAmount     Amount of `inputToken` being paid to this wrapper
     * @param  _orderData       Arbitrary bytes data for any information to pass to the exchange
     * @return                  The amount of outputToken to be received by DolomiteMargin
     */
    function exchange(
        address _tradeOriginator,
        address _receiver,
        address _outputToken,
        address _inputToken,
        uint256 _inputAmount,
        bytes calldata _orderData
    )
    external
    returns (uint256);

    /**
     * Get amount of `inputToken` required to buy a certain amount of `outputToken` for a given trade.
     * Should match the `inputToken` amount used in exchangeForAmount. If the order cannot provide
     * exactly `_desiredOutputToken`, then it must return the price to buy the minimum amount greater
     * than `_desiredOutputToken`
     *
     * @param  _inputToken          The token to pay to this contract (originator asset; IE path[0])
     * @param  _outputToken         The token to receive by DolomiteMargin (target asset; IE path[path.length - 1])
     * @param  _desiredInputAmount  Amount of `_inputToken` requested
     * @param  _orderData           Arbitrary bytes data for any information to pass to the exchange
     * @return                      Amount of `_inputToken` the needed to complete the exchange
     */
    function getExchangeCost(
        address _inputToken,
        address _outputToken,
        uint256 _desiredInputAmount,
        bytes calldata _orderData
    )
    external
    view
    returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteAccountRiskOverrideSetter } from "./IDolomiteAccountRiskOverrideSetter.sol";
import { IDolomiteInterestSetter } from "./IDolomiteInterestSetter.sol";
import { IDolomiteMarginV2Admin } from "./IDolomiteMarginV2Admin.sol";
import { IDolomiteOracleSentinel } from "./IDolomiteOracleSentinel.sol";
import { IDolomitePriceOracle } from "./IDolomitePriceOracle.sol";


/**
 * @title   IDolomiteMarginV2
 * @author  Dolomite
 *
 * @notice  The interface for interacting with the main entry-point to DolomiteMargin
 */
interface IDolomiteMarginV2 is IDolomiteMarginV2Admin {

    // ==================================================
    // ================= Write Functions ================
    // ==================================================

    /**
     * The main entry-point to DolomiteMargin that allows users and contracts to manage accounts.
     * Take one or more actions on one or more accounts. The msg.sender must be the owner or
     * operator of all accounts except for those being liquidated, vaporized, or traded with.
     * One call to operate() is considered a singular "operation". Account collateralization is
     * ensured only after the completion of the entire operation.
     *
     * @param  accounts  A list of all accounts that will be used in this operation. Cannot contain
     *                   duplicates. In each action, the relevant account will be referred-to by its
     *                   index in the list.
     * @param  actions   An ordered list of all actions that will be taken in this operation. The
     *                   actions will be processed in order.
     */
    function operate(
        AccountInfo[] calldata accounts,
        ActionArgs[] calldata actions
    ) external;

    /**
     * Approves/disapproves any number of operators. An operator is an external address that has the
     * same permissions to manipulate an account as the owner of the account. Operators are simply
     * addresses and therefore may either be externally-owned Ethereum accounts OR smart contracts.
     *
     * Operators are also able to act as AutoTrader contracts on behalf of the account owner if the
     * operator is a smart contract and implements the IAutoTrader interface.
     *
     * @param  args  A list of OperatorArgs which have an address and a boolean. The boolean value
     *               denotes whether to approve (true) or revoke approval (false) for that address.
     */
    function setOperators(
        OperatorArg[] calldata args
    ) external;

    // ==================================================
    // ================= Read Functions ================
    // ==================================================

    // ============ Getters for Markets ============

    /**
     * Get the ERC20 token address for a market.
     *
     * @param  token    The token to query
     * @return          The token's marketId if the token is valid
     */
    function getMarketIdByTokenAddress(
        address token
    ) external view returns (uint256);

    /**
     * Get the ERC20 token address for a market.
     *
     * @param  marketId  The market to query
     * @return           The token address
     */
    function getMarketTokenAddress(
        uint256 marketId
    ) external view returns (address);

    /**
     * Return the maximum amount of the market that can be supplied on Dolomite. Always 0 or positive.
     *
     * @param  marketId  The market to query
     * @return           The max amount of the market that can be supplied
     */
    function getMarketMaxWei(
        uint256 marketId
    ) external view returns (Wei memory);

    /**
     * Get the max supply amount for a a market.
     *
     * @param  marketId  The market to query
     * @return           The market's max supply amount. Always 0 or positive.
     */
    function getMarketMaxSupplyWei(
        uint256 marketId
    )
    external
    view
    returns (Wei memory);

    /**
     * Get the max borrow amount for a a market.
     *
     * @param  marketId  The market to query
     * @return           The market's max borrow amount. Always negative or 0.
     */
    function getMarketMaxBorrowWei(
        uint256 marketId
    )
    external
    view
    returns (Wei memory);

    /**
     * Get the market-specific earnings that determines what percentage of the interest paid by borrowers gets passed-on
     * to suppliers. If the value is set to 0, the override is not set.
     *
     * @return  The market-specific earnings rate
     */
    function getMarketEarningsRateOverride(
        uint256 marketId
    )
    external
    view
    returns (Decimal memory);

    /**
     * Get the current borrow interest rate for a market. The value is denominated as interest paid per second, and the
     * number is scaled to have 18 decimals. To get APR, multiply the number returned by 31536000 (seconds in a year).
     *
     * @param  marketId  The market to query
     * @return           The current borrow interest rate
     */
    function getMarketBorrowInterestRatePerSecond(
        uint256 marketId
    ) external view returns (IDolomiteInterestSetter.InterestRate memory);

    /**
     * Return true if a particular market is in closing mode. Additional borrows cannot be taken
     * from a market that is closing.
     *
     * @param  marketId  The market to query
     * @return           True if the market is closing
     */
    function getMarketIsClosing(
        uint256 marketId
    )
    external
    view
    returns (bool);

    /**
     * Get the price of the token for a market.
     *
     * @param  marketId  The market to query
     * @return           The price of each atomic unit of the token
     */
    function getMarketPrice(
        uint256 marketId
    ) external view returns (MonetaryPrice memory);

    /**
     * Get the total number of markets.
     *
     * @return  The number of markets
     */
    function getNumMarkets() external view returns (uint256);

    /**
     * Get the total principal amounts (borrowed and supplied) for a market.
     *
     * @param  marketId  The market to query
     * @return           The total principal amounts
     */
    function getMarketTotalPar(
        uint256 marketId
    ) external view returns (TotalPar memory);

    /**
     * Get the total principal amounts (borrowed and supplied) for a market.
     *
     * @param  marketId  The market to query
     * @return           The total principal amounts
     */
    function getMarketTotalWei(
        uint256 marketId
    ) external view returns (TotalWei memory);

    /**
     * Get the most recently cached interest index for a market.
     *
     * @param  marketId  The market to query
     * @return           The most recent index
     */
    function getMarketCachedIndex(
        uint256 marketId
    ) external view returns (InterestIndex memory);

    /**
     * Get the interest index for a market if it were to be updated right now.
     *
     * @param  marketId  The market to query
     * @return           The estimated current index
     */
    function getMarketCurrentIndex(
        uint256 marketId
    ) external view returns (InterestIndex memory);

    /**
     * Get the price oracle address for a market.
     *
     * @param  marketId  The market to query
     * @return           The price oracle address
     */
    function getMarketPriceOracle(
        uint256 marketId
    ) external view returns (IDolomitePriceOracle);

    /**
     * Get the interest-setter address for a market.
     *
     * @param  marketId  The market to query
     * @return           The interest-setter address
     */
    function getMarketInterestSetter(
        uint256 marketId
    ) external view returns (IDolomiteInterestSetter);

    /**
     * Get the margin premium for a market. A margin premium makes it so that any positions that
     * include the market require a higher collateralization to avoid being liquidated.
     *
     * @param  marketId  The market to query
     * @return           The market's margin premium
     */
    function getMarketMarginPremium(
        uint256 marketId
    ) external view returns (Decimal memory);

    /**
     * Get the spread premium for a market. A spread premium makes it so that any liquidations
     * that include the market have a higher spread than the global default.
     *
     * @param  marketId  The market to query
     * @return           The market's spread premium
     */
    function getMarketLiquidationSpreadPremium(
        uint256 marketId
    ) external view returns (Decimal memory);

    /**
     * Get the spread premium for a market. A spread premium makes it so that any liquidations
     * that include the market have a higher spread than the global default.
     *
     * @param  marketId  The market to query
     * @return           The market's spread premium
     */
    function getMarketSpreadPremium(
        uint256 marketId
    ) external view returns (Decimal memory);

    /**
     * Get the current borrower interest rate for a market.
     *
     * @param  marketId  The market to query
     * @return           The current interest rate
     */
    function getMarketInterestRate(
        uint256 marketId
    ) external view returns (IDolomiteInterestSetter.InterestRate memory);

    /**
     * Get the current borrow interest rate for a market. The value is denominated as interest paid per year, and the
     * number is scaled to have 18 decimals.
     *
     * @param  marketId  The market to query
     * @return           The current supply interest rate
     */
    function getMarketBorrowInterestRateApr(
        uint256 marketId
    ) external view returns (IDolomiteInterestSetter.InterestRate memory);

    /**
     * Get the current supply interest rate for a market.
     *
     * @param  marketId  The market to query
     * @return           The current supply interest rate
     */
    function getMarketSupplyInterestRateApr(
        uint256 marketId
    ) external view returns (IDolomiteInterestSetter.InterestRate memory);

    /**
     * Get basic information about a particular market.
     *
     * @param  marketId  The market to query
     * @return           A Market struct with the current state of the market
     */
    function getMarket(
        uint256 marketId
    ) external view returns (MarketV2 memory);

    /**
     * Get comprehensive information about a particular market.
     *
     * @param  marketId  The market to query
     * @return           A tuple containing the values:
     *                    - A Market struct with the current state of the market
     *                    - The current estimated interest index
     *                    - The current token price
     *                    - The current market interest rate
     */
    function getMarketWithInfo(
        uint256 marketId
    )
    external
    view
    returns (
        MarketV2 memory,
        InterestIndex memory,
        MonetaryPrice memory,
        IDolomiteInterestSetter.InterestRate memory
    );

    /**
     * Get the number of excess tokens for a market. The number of excess tokens is calculated by taking the current
     * number of tokens held in DolomiteMargin, adding the number of tokens owed to DolomiteMargin by borrowers, and
     * subtracting the number of tokens owed to suppliers by DolomiteMargin.
     *
     * @param  marketId  The market to query
     * @return           The number of excess tokens
     */
    function getNumExcessTokens(
        uint256 marketId
    ) external view returns (Wei memory);

    // ============ Getters for Accounts ============

    /**
     * Get the principal value for a particular account and market.
     *
     * @param  account   The account to query
     * @param  marketId  The market to query
     * @return           The principal value
     */
    function getAccountPar(
        AccountInfo calldata account,
        uint256 marketId
    ) external view returns (Par memory);

    /**
     * Get the principal value for a particular account and market, with no check the market is valid. Meaning, markets
     * that don't exist return 0.
     *
     * @param  account   The account to query
     * @param  marketId  The market to query
     * @return           The principal value
     */
    function getAccountParNoMarketCheck(
        AccountInfo calldata account,
        uint256 marketId
    ) external view returns (Par memory);

    /**
     * Get the token balance for a particular account and market.
     *
     * @param  account   The account to query
     * @param  marketId  The market to query
     * @return           The token amount
     */
    function getAccountWei(
        AccountInfo calldata account,
        uint256 marketId
    ) external view returns (Wei memory);

    /**
     * Get the status of an account (Normal, Liquidating, or Vaporizing).
     *
     * @param  account  The account to query
     * @return          The account's status
     */
    function getAccountStatus(
        AccountInfo calldata account
    ) external view returns (AccountStatus);

    /**
     * Get a list of markets that have a non-zero balance for an account
     *
     * @param  account  The account to query
     * @return          The non-sorted marketIds with non-zero balance for the account.
     */
    function getAccountMarketsWithBalances(
        AccountInfo calldata account
    ) external view returns (uint256[] memory);

    /**
     * Get the number of markets that have a non-zero balance for an account
     *
     * @param  account  The account to query
     * @return          The non-sorted marketIds with non-zero balance for the account.
     */
    function getAccountNumberOfMarketsWithBalances(
        AccountInfo calldata account
    ) external view returns (uint256);

    /**
     * Get the marketId for an account's market with a non-zero balance at the given index
     *
     * @param  account  The account to query
     * @return          The non-sorted marketIds with non-zero balance for the account.
     */
    function getAccountMarketWithBalanceAtIndex(
        AccountInfo calldata account,
        uint256 index
    ) external view returns (uint256);

    /**
     * Get the number of markets with which an account has a negative balance.
     *
     * @param  account  The account to query
     * @return          The non-sorted marketIds with non-zero balance for the account.
     */
    function getAccountNumberOfMarketsWithDebt(
        AccountInfo calldata account
    ) external view returns (uint256);

    /**
     * Get the total supplied and total borrowed value of an account.
     *
     * @param  account  The account to query
     * @return          The following values:
     *                   - The supplied value of the account
     *                   - The borrowed value of the account
     */
    function getAccountValues(
        AccountInfo calldata account
    ) external view returns (MonetaryValue memory, MonetaryValue memory);

    /**
     * Get the total supplied and total borrowed values of an account adjusted by the marginPremium
     * of each market. Supplied values are divided by (1 + marginPremium) for each market and
     * borrowed values are multiplied by (1 + marginPremium) for each market. Comparing these
     * adjusted values gives the margin-ratio of the account which will be compared to the global
     * margin-ratio when determining if the account can be liquidated.
     *
     * @param  account  The account to query
     * @return          The following values:
     *                   - The supplied value of the account (adjusted for marginPremium)
     *                   - The borrowed value of the account (adjusted for marginPremium)
     */
    function getAdjustedAccountValues(
        AccountInfo calldata account
    ) external view returns (MonetaryValue memory, MonetaryValue memory);

    /**
     * Get an account's summary for each market.
     *
     * @param  account  The account to query
     * @return          The following values:
     *                   - The market IDs for each market
     *                   - The ERC20 token address for each market
     *                   - The account's principal value for each market
     *                   - The account's (supplied or borrowed) number of tokens for each market
     */
    function getAccountBalances(
        AccountInfo calldata account
    ) external view returns (uint[] memory, address[] memory, Par[] memory, Wei[] memory);

    // ============ Getters for Account Permissions ============

    /**
     * Return true if a particular address is approved as an operator for an owner's accounts.
     * Approved operators can act on the accounts of the owner as if it were the operator's own.
     *
     * @param  owner     The owner of the accounts
     * @param  operator  The possible operator
     * @return           True if operator is approved for owner's accounts
     */
    function getIsLocalOperator(
        address owner,
        address operator
    ) external view returns (bool);

    /**
     * Return true if a particular address is approved as a global operator. Such an address can
     * act on any account as if it were the operator's own.
     *
     * @param  operator  The address to query
     * @return           True if operator is a global operator
     */
    function getIsGlobalOperator(
        address operator
    ) external view returns (bool);

    /**
     * Checks if the autoTrader can only be called invoked by a global operator
     *
     * @param  autoTrader    The trader that should be checked for special call privileges.
     */
    function getIsAutoTraderSpecial(address autoTrader) external view returns (bool);

    /**
     * @return The address that owns the DolomiteMargin protocol
     */
    function owner() external view returns (address);

    // ============ Getters for Risk Params ============

    /**
     * Get the global minimum margin-ratio that every position must maintain to prevent being
     * liquidated.
     *
     * @return  The global margin-ratio
     */
    function getMarginRatio() external view returns (Decimal memory);

    /**
     * Get the global minimum margin-ratio that every position must maintain to prevent being
     * liquidated.
     *
     * @param  account       The account whose margin ratio is being queried. This is used to determine if there is an
     *                      override that supersedes the global minimum.
     * @return  The margin ratio for this account
     */
    function getMarginRatioForAccount(AccountInfo calldata account) external view returns (Decimal memory);

    /**
     * Get the global liquidation spread. This is the spread between oracle prices that incentivizes
     * the liquidation of risky positions.
     *
     * @return  The global liquidation spread
     */
    function getLiquidationSpread() external view returns (Decimal memory);

    /**
     * Get the adjusted liquidation spread for some market pair. This is equal to the global
     * liquidation spread multiplied by (1 + spreadPremium) for each of the two markets.
     *
     * @param  heldMarketId  The market for which the account has collateral
     * @param  owedMarketId  The market for which the account has borrowed tokens
     * @return               The adjusted liquidation spread
     */
    function getLiquidationSpreadForPair(
        uint256 heldMarketId,
        uint256 owedMarketId
    ) external view returns (Decimal memory);

    /**
     * Get the adjusted liquidation spread for some market pair. This is equal to the global liquidation spread
     * multiplied by (1 + spreadPremium) for each of the two markets.
     *
     * If the pair is in e-mode and has a liquidation spread override, then the override is used instead.
     *
     * @param  account      The account whose liquidation spread is being queried. This is used to determine if there is
     *                      an override in place.
     * @param  heldMarketId The market for which the account has collateral
     * @param  owedMarketId The market for which the account has borrowed tokens
     * @return              The adjusted liquidation spread
     */
    function getLiquidationSpreadForAccountAndPair(
        AccountInfo calldata account,
        uint256 heldMarketId,
        uint256 owedMarketId
    ) external view returns (Decimal memory);

    /**
     * Get the global earnings-rate variable that determines what percentage of the interest paid
     * by borrowers gets passed-on to suppliers.
     *
     * @return  The global earnings rate
     */
    function getEarningsRate() external view returns (Decimal memory);

    /**
     * Get the global minimum-borrow value which is the minimum value of any new borrow on DolomiteMargin.
     *
     * @return  The global minimum borrow value
     */
    function getMinBorrowedValue() external view returns (MonetaryValue memory);

    /**
     * Get the maximum number of assets an account owner can hold in an account number.
     *
     * @return  The maximum number of assets an account owner can hold in an account number.
     */
    function getAccountMaxNumberOfMarketsWithBalances() external view returns (uint256);

    /**
     * Gets the oracle sentinel, which is responsible for checking if the Blockchain or L2 is alive, if liquidations
     * should be processed, and if markets should are in size-down only mode.
     *
     * @return The oracle sentinel for DolomiteMargin
     */
    function getOracleSentinel() external view returns (IDolomiteOracleSentinel);

    /**
     * @return True if borrowing is globally allowed according to the Oracle Sentinel or false if it is not
     */
    function getIsBorrowAllowed() external view returns (bool);

    /**
     * @return True if liquidations are globally allowed according to the Oracle Sentinel or false if they are not
     */
    function getIsLiquidationAllowed() external view returns (bool);

    /**
     * @return  The gas limit used for making callbacks via `IExternalCallback::onInternalBalanceChange` to smart
     *          contract wallets.
     */
    function getCallbackGasLimit() external view returns (uint256);

    /**
     * Get the account risk override getter for global use. This contract enables e-mode based on the assets held in a
     * position.
     *
     * @return  The contract that contains risk override information for any account that does NOT have an account-
     *          specific override.
     */
    function getDefaultAccountRiskOverrideSetter() external view returns (IDolomiteAccountRiskOverrideSetter);

    /**
     * Get the account risk override getter for an account owner. This contract enables e-mode for certain isolation
     * mode vaults.
     *
     * @param  accountOwner  The address of the account to check if there is a margin ratio override.
     * @return  The contract that contains risk override information for this account.
     */
    function getAccountRiskOverrideSetterByAccountOwner(
        address accountOwner
    ) external view returns (IDolomiteAccountRiskOverrideSetter);

    /**
     * Get the margin ratio override for an account owner. Used to enable e-mode for certain isolation mode vaults.
     *
     * @param  account                       The account to check if there is a risk override.
     * @return marginRatioOverride          The margin ratio override for an account owner. Defaults to 0 if there's no
     *                                      override in place.
     * @return liquidationSpreadOverride    The margin ratio override for an account owner. Defaults to 0 if there's no
     *                                      override in place.
     */
    function getAccountRiskOverrideByAccount(
        AccountInfo calldata account
    )
    external
    view
    returns (Decimal memory marginRatioOverride, Decimal memory liquidationSpreadOverride);

    /**
     * Get the margin ratio override for an account. Used to enable e-mode for certain accounts/positions.
     *
     * @param  account   The account to check if there is a margin ratio override.
     * @return  The margin ratio override for an account owner. Defaults to 0 if there's no override in place.
     */
    function getMarginRatioOverrideByAccount(AccountInfo calldata account) external view returns (Decimal memory);

    /**
     * Get the liquidation reward override for an account owner. Used to enable e-mode for certain isolation mode
     * vaults.
     *
     * @param  account   The account to check if there is a liquidation spread override.
     * @return  The liquidation spread override for an account owner. Defaults to 0 if there's no override in place.
     */
    function getLiquidationSpreadOverrideByAccount(
        AccountInfo calldata account
    ) external view returns (Decimal memory);

    /**
     * Get all risk parameter limits in a single struct. These are the maximum limits at which the
     * risk parameters can be set by the admin of DolomiteMargin.
     *
     * @return  All global risk parameter limits
     */
    function getRiskLimits() external view returns (RiskLimitsV2 memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteAccountRiskOverrideSetter } from "./IDolomiteAccountRiskOverrideSetter.sol";
import { IDolomiteInterestSetter } from "./IDolomiteInterestSetter.sol";
import { IDolomiteOracleSentinel } from "./IDolomiteOracleSentinel.sol";
import { IDolomitePriceOracle } from "./IDolomitePriceOracle.sol";
import { IDolomiteStructs } from "./IDolomiteStructs.sol";


/**
 * @title   IDolomiteMarginV2Admin
 * @author  Dolomite
 *
 * @notice  This interface defines the functions that can be called by the owner of DolomiteMargin.
 */
interface IDolomiteMarginV2Admin is IDolomiteStructs {

    // ============ Token Functions ============

    /**
     * Withdraw an ERC20 token for which there is an associated market. Only excess tokens can be withdrawn. The number
     * of excess tokens is calculated by taking the current number of tokens held in DolomiteMargin, adding the number
     * of tokens owed to DolomiteMargin by borrowers, and subtracting the number of tokens owed to suppliers by
     * DolomiteMargin.
     */
    function ownerWithdrawExcessTokens(
        uint256 marketId,
        address recipient
    )
    external
    returns (uint256);

    /**
     * Withdraw an ERC20 token for which there is no associated market.
     */
    function ownerWithdrawUnsupportedTokens(
        address token,
        address recipient
    )
    external
    returns (uint256);

    // ============ Market Functions ============

    /**
     * Add a new market to DolomiteMargin. Must be for a previously-unsupported ERC20 token.
     */
    function ownerAddMarket(
        address token,
        IDolomitePriceOracle priceOracle,
        IDolomiteInterestSetter interestSetter,
        Decimal calldata marginPremium,
        Decimal calldata spreadPremium,
        uint256 maxSupplyWei,
        uint256 maxBorrowWei,
        Decimal calldata earningsRateOverride,
        bool isClosing
    )
    external;

    /**
     * Set (or unset) the status of a market to "closing". The borrowedValue of a market cannot increase while its
     * status is "closing".
     */
    function ownerSetIsClosing(
        uint256 marketId,
        bool isClosing
    )
    external;

    /**
     * Set the price oracle for a market.
     */
    function ownerSetPriceOracle(
        uint256 marketId,
        IDolomitePriceOracle priceOracle
    )
    external;

    /**
     * Set the interest-setter for a market.
     */
    function ownerSetInterestSetter(
        uint256 marketId,
        IDolomiteInterestSetter interestSetter
    )
    external;

    /**
     * Set a premium on the minimum margin-ratio for a market. This makes it so that any positions that include this
     * market require a higher collateralization to avoid being liquidated.
     */
    function ownerSetMarginPremium(
        uint256 marketId,
        Decimal calldata marginPremium
    )
    external;

    /**
     * Set a premium on the liquidation spread for a market. This makes it so that any liquidations that include this
     * market have a higher spread than the global default.
     */
    function ownerSetLiquidationSpreadPremium(
        uint256 marketId,
        Decimal calldata liquidationSpreadPremium
    )
    external;

    /**
     * Sets the maximum supply wei for a given `marketId`.
     */
    function ownerSetMaxSupplyWei(
        uint256 marketId,
        uint256 maxSupplyWei
    )
    external;

    /**
     * Sets the maximum borrow wei for a given `marketId`.
     */
    function ownerSetMaxBorrowWei(
        uint256 marketId,
        uint256 maxBorrowWei
    )
    external;

    /**
     * Sets the earnings rate override for a given `marketId`. Set it to 0 unset the override.
     */
    function ownerSetEarningsRateOverride(
        uint256 marketId,
        Decimal calldata earningsRateOverride
    )
    external;

    // ============ Risk Functions ============

    /**
     * Set the global minimum margin-ratio that every position must maintain to prevent being liquidated.
     */
    function ownerSetMarginRatio(
        Decimal calldata ratio
    )
    external;

    /**
     * Set the global liquidation spread. This is the spread between oracle prices that incentivizes the liquidation of
     * risky positions.
     */
    function ownerSetLiquidationSpread(
        Decimal calldata spread
    )
    external;

    /**
     * Set the global earnings-rate variable that determines what percentage of the interest paid by borrowers gets
     * passed-on to suppliers.
     */
    function ownerSetEarningsRate(
        Decimal calldata earningsRate
    )
    external;

    /**
     * Set the global minimum-borrow value which is the minimum value of any new borrow on DolomiteMargin.
     */
    function ownerSetMinBorrowedValue(
        MonetaryValue calldata minBorrowedValue
    )
    external;

    /**
     * Sets the number of non-zero balances an account may have within the same `accountIndex`. This ensures a user
     * cannot DOS the system by filling their account with non-zero balances (which linearly increases gas costs when
     * checking collateralization) and disallowing themselves to close the position, because the number of gas units
     * needed to process their transaction exceed the block's gas limit. In turn, this would  prevent the user from also
     * being liquidated, causing the all of the capital to be "stuck" in the position.
     *
     * Lowering this number does not "freeze" user accounts that have more than the new limit of balances, because this
     * variable is enforced by checking the users number of non-zero balances against the max or if it sizes down before
     * each transaction finishes.
     */
    function ownerSetAccountMaxNumberOfMarketsWithBalances(
        uint256 accountMaxNumberOfMarketsWithBalances
    )
    external;

    /**
     * Sets the current oracle sentinel used to report if borrowing and liquidations are enabled.
     */
    function ownerSetOracleSentinel(
        IDolomiteOracleSentinel oracleSentinel
    )
    external;

    /**
     * Sets the gas limit that's passed to any of the callback functions
     */
    function ownerSetCallbackGasLimit(
        uint256 callbackGasLimit
    )
    external;

    /**
     * Sets the account risk override setter by default for any account
     */
    function ownerSetDefaultAccountRiskOverride(
        IDolomiteAccountRiskOverrideSetter accountRiskOverrideSetter
    )
    external;

    /**
     * Sets the account risk override setter for a given wallet
     */
    function ownerSetAccountRiskOverride(
        address accountOwner,
        IDolomiteAccountRiskOverrideSetter accountRiskOverrideSetter
    )
    external;

    // ============ Global Operator Functions ============

    /**
     * Approve (or disapprove) an address that is permissioned to be an operator for all accounts in DolomiteMargin.
     * Intended only to approve smart-contracts.
     */
    function ownerSetGlobalOperator(
        address operator,
        bool approved
    )
    external;

    /**
     * Approve (or disapprove) an auto trader that can only be called by a global operator. IE for expirations
     */
    function ownerSetAutoTraderSpecial(
        address autoTrader,
        bool special
    )
    external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.8.9;


/**
 * @title   IDolomiteOracleSentinel
 * @author  Dolomite
 *
 * Interface that Dolomite pings to check if the Blockchain or L2 is alive, if liquidations should be processed, and if
 * markets should are in size-down only mode.
 */
interface IDolomiteOracleSentinel {

    // ============ Events ============

    event GracePeriodSet(
        uint256 gracePeriod
    );

    // ============ Functions ============

    /**
     * @dev Allows the owner to set the grace period duration, which specifies how long the system will disallow
     *      liquidations after sequencer is back online. Only callable by the owner.
     *
     * @param  _gracePeriod  The new duration of the grace period
     */
    function ownerSetGracePeriod(
        uint256 _gracePeriod
    )
    external;

    /**
     * @return True if new borrows should be allowed, false otherwise
     */
    function isBorrowAllowed() external view returns (bool);

    /**
     * @return True if liquidations should be allowed, false otherwise
     */
    function isLiquidationAllowed() external view returns (bool);

    /**
     * @return  The duration between when the feed comes back online and when the system will allow liquidations to be
     *          processed normally
     */
    function gracePeriod() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteStructs } from "./IDolomiteStructs.sol";


/**
 * @title   IDolomitePriceOracle
 * @author  Dolomite
 *
 * @notice  Interface that Price Oracles for DolomiteMargin must implement in order to report prices.
 */
interface IDolomitePriceOracle {

    // ============ Public Functions ============

    /**
     * Get the price of a token
     *
     * @param  token  The ERC20 token address of the market
     * @return        The USD price of a base unit of the token, then multiplied by 10^(36 - decimals).
     *                So a USD-stable coin with 6 decimal places would return `price * 10^30`.
     *                This is the price of the base unit rather than the price of a "human-readable"
     *                token amount. Every ERC20 may have a different number of decimals.
     */
    function getPrice(
        address token
    )
    external
    view
    returns (IDolomiteStructs.MonetaryPrice memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteAccountRiskOverrideSetter } from "./IDolomiteAccountRiskOverrideSetter.sol";
import { IDolomiteInterestSetter } from "./IDolomiteInterestSetter.sol";
import { IDolomiteOracleSentinel } from "./IDolomiteOracleSentinel.sol";
import { IDolomitePriceOracle } from "./IDolomitePriceOracle.sol";


/**
 * @title   IDolomiteStructs
 * @author  Dolomite
 *
 * @notice  This interface defines the structs used by DolomiteMargin
 */
interface IDolomiteStructs {

    // ========================= Enums =========================

    enum ActionType {
        Deposit,   // supply tokens
        Withdraw,  // borrow tokens
        Transfer,  // transfer balance between accounts
        Buy,       // buy an amount of some token (externally)
        Sell,      // sell an amount of some token (externally)
        Trade,     // trade tokens against another account
        Liquidate, // liquidate an undercollateralized or expiring account
        Vaporize,  // use excess tokens to zero-out a completely negative account
        Call       // send arbitrary data to an address
    }

    enum AssetDenomination {
        Wei, // the amount is denominated in wei
        Par  // the amount is denominated in par
    }

    enum AssetReference {
        Delta, // the amount is given as a delta from the current value
        Target // the amount is given as an exact number to end up at
    }

    // ========================= Structs =========================

    struct AccountInfo {
        address owner;  // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }

    /**
     * Most-recently-cached account status.
     *
     * Normal: Can only be liquidated if the account values are violating the global margin-ratio.
     * Liquid: Can be liquidated no matter the account values.
     *         Can be vaporized if there are no more positive account values.
     * Vapor:  Has only negative (or zeroed) account values. Can be vaporized.
     *
     */
    enum AccountStatus {
        Normal,
        Liquid,
        Vapor
    }

    /*
     * Arguments that are passed to DolomiteMargin in an ordered list as part of a single operation.
     * Each ActionArgs has an actionType which specifies which action struct that this data will be
     * parsed into before being processed.
     */
    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    struct Decimal {
        uint256 value;
    }

    struct InterestIndex {
        uint96 borrow;
        uint96 supply;
        uint32 lastUpdate;
    }

    struct Market {
        address token;

        // Whether additional borrows are allowed for this market
        bool isClosing;

        // Whether this market can be removed and its ID can be recycled and reused
        bool isRecyclable;

        // Total aggregated supply and borrow amount of the entire market
        TotalPar totalPar;

        // Interest index of the market
        InterestIndex index;

        // Contract address of the price oracle for this market
        IDolomitePriceOracle priceOracle;

        // Contract address of the interest setter for this market
        IDolomiteInterestSetter interestSetter;

        // Multiplier on the marginRatio for this market, IE 5% (0.05 * 1e18). This number increases the market's
        // required collateralization by: reducing the user's supplied value (in terms of dollars) for this market and
        // increasing its borrowed value. This is done through the following operation:
        // `suppliedWei = suppliedWei + (assetValueForThisMarket / (1 + marginPremium))`
        // This number increases the user's borrowed wei by multiplying it by:
        // `borrowedWei = borrowedWei + (assetValueForThisMarket * (1 + marginPremium))`
        Decimal marginPremium;

        // Multiplier on the liquidationSpread for this market, IE 20% (0.2 * 1e18). This number increases the
        // `liquidationSpread` using the following formula:
        // `liquidationSpread = liquidationSpread * (1 + spreadPremium)`
        // NOTE: This formula is applied up to two times - one for each market whose spreadPremium is greater than 0
        // (when performing a liquidation between two markets)
        Decimal spreadPremium;

        // The maximum amount that can be held by the external. This allows the external to cap any additional risk
        // that is inferred by allowing borrowing against low-cap or assets with increased volatility. Setting this
        // value to 0 is analogous to having no limit. This value can never be below 0.
        Wei maxWei;
    }

    struct MarketV2 {
        // Contract address of the associated ERC20 token
        address token;

        // Whether additional borrows are allowed for this market
        bool isClosing;

        // Total aggregated supply and borrow amount of the entire market
        TotalPar totalPar;

        // Interest index of the market
        InterestIndex index;

        // Contract address of the price oracle for this market
        IDolomitePriceOracle priceOracle;

        // Contract address of the interest setter for this market
        IDolomiteInterestSetter interestSetter;

        // Multiplier on the marginRatio for this market, IE 5% (0.05 * 1e18). This number increases the market's
        // required collateralization by: reducing the user's supplied value (in terms of dollars) for this market and
        // increasing its borrowed value. This is done through the following operation:
        // `suppliedWei = suppliedWei + (assetValueForThisMarket / (1 + marginPremium))`
        // This number increases the user's borrowed wei by multiplying it by:
        // `borrowedWei = borrowedWei + (assetValueForThisMarket * (1 + marginPremium))`
        Decimal marginPremium;

        // Multiplier on the liquidationSpread for this market, IE 20% (0.2 * 1e18). This number increases the
        // `liquidationSpread` using the following formula:
        // `liquidationSpread = liquidationSpread * (1 + spreadPremium)`
        // NOTE: This formula is applied up to two times - one for each market whose spreadPremium is greater than 0
        // (when performing a liquidation between two markets)
        Decimal liquidationSpreadPremium;

        // The maximum amount that can be held by the protocol. This allows the protocol to cap any additional risk
        // that is inferred by allowing borrowing against low-cap or assets with increased volatility. Setting this
        // value to 0 is analogous to having no limit. This value can never be below 0.
        Wei maxSupplyWei;

        // The maximum amount that can be borrowed by the protocol. This allows the protocol to cap any additional risk
        // that is inferred by allowing borrowing against low-cap or assets with increased volatility. Setting this
        // value to 0 is analogous to having no limit. This value can never be greater than 0.
        Wei maxBorrowWei;

        // The percentage of interest paid that is passed along from borrowers to suppliers. Setting this to 0 will
        // default to RiskParams.earningsRate.
        Decimal earningsRateOverride;
    }

    /*
     * The price of a base-unit of an asset. Has `36 - token.decimals` decimals
     */
    struct MonetaryPrice {
        uint256 value;
    }

    struct MonetaryValue {
        uint256 value;
    }

    struct OperatorArg {
        address operator;
        bool trusted;
    }

    struct Par {
        bool sign;
        uint128 value;
    }

    struct RiskLimits {
        // The highest that the ratio can be for liquidating under-water accounts
        uint64 marginRatioMax;
        // The highest that the liquidation rewards can be when a liquidator liquidates an account
        uint64 liquidationSpreadMax;
        // The highest that the supply APR can be for a market, as a proportion of the borrow rate. Meaning, a rate of
        // 100% (1e18) would give suppliers all of the interest that borrowers are paying. A rate of 90% would give
        // suppliers 90% of the interest that borrowers pay.
        uint64 earningsRateMax;
        // The highest min margin ratio premium that can be applied to a particular market. Meaning, a value of 100%
        // (1e18) would require borrowers to maintain an extra 100% collateral to maintain a healthy margin ratio. This
        // value works by increasing the debt owed and decreasing the supply held for the particular market by this
        // amount, plus 1e18 (since a value of 10% needs to be applied as `decimal.plusOne`)
        uint64 marginPremiumMax;
        // The highest liquidation reward that can be applied to a particular market. This percentage is applied
        // in addition to the liquidation spread in `RiskParams`. Meaning a value of 1e18 is 100%. It is calculated as:
        // `liquidationSpread * Decimal.onePlus(spreadPremium)`
        uint64 spreadPremiumMax;
        uint128 minBorrowedValueMax;
    }

    struct RiskLimitsV2 {
        // The highest that the ratio can be for liquidating under-water accounts
        uint64 marginRatioMax;
        // The highest that the liquidation rewards can be when a liquidator liquidates an account
        uint64 liquidationSpreadMax;
        // The highest that the supply APR can be for a market, as a proportion of the borrow rate. Meaning, a rate of
        // 100% (1e18) would give suppliers all of the interest that borrowers are paying. A rate of 90% would give
        // suppliers 90% of the interest that borrowers pay.
        uint64 earningsRateMax;
        // The highest min margin ratio premium that can be applied to a particular market. Meaning, a value of 100%
        // (1e18) would require borrowers to maintain an extra 100% collateral to maintain a healthy margin ratio. This
        // value works by increasing the debt owed and decreasing the supply held for the particular market by this
        // amount, plus 1e18 (since a value of 10% needs to be applied as `decimal.plusOne`)
        uint64 marginPremiumMax;
        // The highest liquidation reward that can be applied to a particular market. This percentage is applied
        // in addition to the liquidation spread in `RiskParams`. Meaning a value of 1e18 is 100%. It is calculated as:
        // `liquidationSpread * Decimal.onePlus(spreadPremium)`
        uint64 liquidationSpreadPremiumMax;
        // The highest that the borrow interest rate can ever be. If the rate returned is ever higher, the rate is
        // capped at this value instead of reverting. The goal is to keep Dolomite operational under all circumstances
        // instead of inadvertently DOS'ing the protocol.
        uint96 interestRateMax;
        // The highest that the minBorrowedValue can be. This is the minimum amount of value that must be borrowed.
        // Typically a value of $100 (100 * 1e18) is more than sufficient.
        uint128 minBorrowedValueMax;
    }

    struct RiskParams {
        // Required ratio of over-collateralization
        Decimal marginRatio;

        // Percentage penalty incurred by liquidated accounts
        Decimal liquidationSpread;

        // Percentage of the borrower's interest fee that gets passed to the suppliers
        Decimal earningsRate;

        // The minimum absolute borrow value of an account
        // There must be sufficient incentivize to liquidate undercollateralized accounts
        MonetaryValue minBorrowedValue;

        // The maximum number of markets a user can have a non-zero balance for a given account.
        uint256 accountMaxNumberOfMarketsWithBalances;
    }

    // The global risk parameters that govern the health and security of the system
    struct RiskParamsV2 {
        // Required ratio of over-collateralization
        Decimal marginRatio;

        // Percentage penalty incurred by liquidated accounts
        Decimal liquidationSpread;

        // Percentage of the borrower's interest fee that gets passed to the suppliers
        Decimal earningsRate;

        // The minimum absolute borrow value of an account
        // There must be sufficient incentivize to liquidate undercollateralized accounts
        MonetaryValue minBorrowedValue;

        // The maximum number of markets a user can have a non-zero balance for a given account.
        uint256 accountMaxNumberOfMarketsWithBalances;

        // The oracle sentinel used to disable borrowing/liquidations if the sequencer goes down
        IDolomiteOracleSentinel oracleSentinel;

        // The gas limit used for making callbacks via `IExternalCallback::onInternalBalanceChange` to smart contract
        // wallets. Setting to 0 will effectively disable callbacks; setting it super large is not desired since it
        // could lead to DOS attacks on the protocol; however, hard coding a max value isn't preferred since some chains
        // can calculate gas usage differently (like ArbGas before Arbitrum rolled out nitro)
        uint256 callbackGasLimit;

        // Certain addresses are allowed to borrow with different LTV requirements. When an account's risk is overrode,
        // the global risk parameters are ignored and the account's risk parameters are used instead.
        mapping(address => IDolomiteAccountRiskOverrideSetter) accountRiskOverrideSetterMap;
    }

    struct TotalPar {
        uint128 borrow;
        uint128 supply;
    }

    struct TotalWei {
        uint128 borrow;
        uint128 supply;
    }

    struct Wei {
        bool sign;
        uint256 value;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

    Copyright 2023 Dolomite.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.8.9;


/**
 * @title   BitsLib
 * @author  Dolomite
 *
 * Library for caching information about markets
 */
library BitsLib {

    // ============ Constants ============

    uint256 private constant _ONE = 1;
    uint256 private constant _MAX_UINT_BITS = 256;

    // ============ Functions ============

    function createBitmaps(uint256 _maxLength) internal pure returns (uint256[] memory) {
        return new uint256[]((_maxLength / _MAX_UINT_BITS) + _ONE);
    }

    function getMarketIdFromBit(
        uint256 _indexIntoBitmapsArray,
        uint256 _bit
    ) internal pure returns (uint256) {
        return (_MAX_UINT_BITS * _indexIntoBitmapsArray) + _bit;
    }

    function setBit(
        uint256[] memory _bitmaps,
        uint256 _marketId
    ) internal pure returns (uint256[] memory) {
        uint256 bucketIndex = _marketId / _MAX_UINT_BITS;
        uint256 indexFromRight = _marketId % _MAX_UINT_BITS;
        _bitmaps[bucketIndex] |= (_ONE << indexFromRight);
        return _bitmaps;
    }

    function hasBit(
        uint256[] memory _bitmaps,
        uint256 _marketId
    ) internal pure returns (bool) {
        uint256 bucketIndex = _marketId / _MAX_UINT_BITS;
        uint256 indexFromRight = _marketId % _MAX_UINT_BITS;
        uint256 bit = _bitmaps[bucketIndex] & (_ONE << indexFromRight);
        return bit > 0;
    }

    function unsetBit(
        uint256 _bitmap,
        uint256 _bit
    ) internal pure returns (uint256) {
        return _bitmap & ~(_ONE << _bit);
    }

    // solium-disable security/no-assign-params
    function getLeastSignificantBit(uint256 _value) internal pure returns (uint256) {
        if (_value == 0) {
            return 0;
        }

        uint256 leastSignificantBit = 255;

        if (_value & type(uint128).max > 0) {
            leastSignificantBit -= 128;
        } else {
            _value >>= 128;
        }

        if (_value & type(uint64).max > 0) {
            leastSignificantBit -= 64;
        } else {
            _value >>= 64;
        }

        if (_value & type(uint32).max > 0) {
            leastSignificantBit -= 32;
        } else {
            _value >>= 32;
        }

        if (_value & type(uint16).max > 0) {
            leastSignificantBit -= 16;
        } else {
            _value >>= 16;
        }

        if (_value & type(uint8).max > 0) {
            leastSignificantBit -= 8;
        } else {
            _value >>= 8;
        }

        if (_value & 0xf > 0) {
            leastSignificantBit -= 4;
        } else {
            _value >>= 4;
        }

        if (_value & 0x3 > 0) {
            leastSignificantBit -= 2;
        } else {
            _value >>= 2;
        }
        // solium-enable security/no-assign-params

        if (_value & 0x1 > 0) {
            leastSignificantBit -= 1;
        }

        return leastSignificantBit;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.8.9;

import { DolomiteMarginMath } from "./DolomiteMarginMath.sol";
import { IDolomiteStructs } from "../interfaces/IDolomiteStructs.sol";


/**
 * @title   DecimalLib
 * @author  dYdX
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library DecimalLib {

    // ============ Constants ============

    uint256 private constant _BASE = 10 ** 18;

    // ============ Functions ============

    function one()
        internal
        pure
        returns (IDolomiteStructs.Decimal memory)
    {
        return IDolomiteStructs.Decimal({ value: _BASE});
    }

    function onePlus(
        IDolomiteStructs.Decimal memory d
    )
        internal
        pure
        returns (IDolomiteStructs.Decimal memory)
    {
        return IDolomiteStructs.Decimal({ value: d.value + _BASE});
    }

    function oneSub(
        IDolomiteStructs.Decimal memory d
    )
        internal
        pure
        returns (IDolomiteStructs.Decimal memory)
    {
        return IDolomiteStructs.Decimal({ value: _BASE - d.value});
    }

    function mul(
        uint256 target,
        IDolomiteStructs.Decimal memory d
    )
        internal
        pure
        returns (uint256)
    {
        return DolomiteMarginMath.getPartial(target, d.value, _BASE);
    }

    function div(
        uint256 target,
        IDolomiteStructs.Decimal memory d
    )
    internal
    pure
    returns (uint256)
    {
        return DolomiteMarginMath.getPartial(target, _BASE, d.value);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { Require } from "./Require.sol";


/**
 * @title   DolomiteMarginMath
 * @author  dYdX
 *
 * @notice  Library for non-standard Math functions
 */
library DolomiteMarginMath {

    // ============ Constants ============

    bytes32 internal constant _FILE = "DolomiteMarginMath";

    // ============ Library Functions ============

    /*
     * Return target * (numerator / denominator).
     */
    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
    internal
    pure
    returns (uint256)
    {
        return target * numerator / denominator;
    }

    /*
     * Return target * (numerator / denominator), but rounded half-up. Meaning, a result of 101.1 rounds to 102
     * instead of 101.
     */
    function getPartialRoundUp(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
    internal
    pure
    returns (uint256)
    {
        if (target == 0 || numerator == 0) {
            return 0;
        }
        return (((target * numerator) - 1) / denominator) + 1;
    }

    /*
     * Return target * (numerator / denominator), but rounded half-up. Meaning, a result of 101.5 rounds to 102
     * instead of 101.
     */
    function getPartialRoundHalfUp(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
    internal
    pure
    returns (uint256)
    {
        if (target == 0 || numerator == 0) {
            return 0;
        }
        return (((target * numerator) + (denominator / 2)) / denominator);
    }

    function to128(
        uint256 number
    )
    internal
    pure
    returns (uint128)
    {
        uint128 result = uint128(number);
        Require.that(
            result == number,
            _FILE,
            "Unsafe cast to uint128",
            number
        );
        return result;
    }

    function to96(
        uint256 number
    )
    internal
    pure
    returns (uint96)
    {
        uint96 result = uint96(number);
        Require.that(
            result == number,
            _FILE,
            "Unsafe cast to uint96",
            number
        );
        return result;
    }

    function to32(
        uint256 number
    )
    internal
    pure
    returns (uint32)
    {
        uint32 result = uint32(number);
        Require.that(
            result == number,
            _FILE,
            "Unsafe cast to uint32",
            number
        );
        return result;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.8.9;


/**
 * @title   Require
 * @author  dYdX
 *
 * @notice  Stringifies parameters to pretty-print revert messages. Costs more gas than regular require()
 */
library Require {

    // ============ Constants ============

    uint256 private constant _ASCII_ZERO = 48; // '0'
    uint256 private constant _ASCII_RELATIVE_ZERO = 87; // 'a' - 10
    uint256 private constant _ASCII_LOWER_EX = 120; // 'x'
    bytes2 private constant _COLON = 0x3a20; // ': '
    bytes2 private constant _COMMA = 0x2c20; // ', '
    bytes2 private constant _LPAREN = 0x203c; // ' <'
    bytes1 private constant _RPAREN = 0x3e; // '>'
    uint256 private constant _FOUR_BIT_MASK = 0xf;

    // ============ Library Functions ============

    function that(
        bool must,
        bytes32 file,
        bytes32 reason
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason)
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        uint256 payloadA
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        uint256 payloadA,
        uint256 payloadB
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _COMMA,
                    _stringify(payloadB),
                    _RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA,
        uint256 payloadB
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _COMMA,
                    _stringify(payloadB),
                    _RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA,
        uint256 payloadB,
        uint256 payloadC
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _COMMA,
                    _stringify(payloadB),
                    _COMMA,
                    _stringify(payloadC),
                    _RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        bytes32 payloadA
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        bytes32 payloadA,
        uint256 payloadB,
        uint256 payloadC
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _COMMA,
                    _stringify(payloadB),
                    _COMMA,
                    _stringify(payloadC),
                    _RPAREN
                )
            )
            );
        }
    }

    // ============ Private Functions ============

    function stringifyTruncated(
        bytes32 input
    )
    internal
    pure
    returns (bytes memory)
    {
        // put the input bytes into the result
        bytes memory result = abi.encodePacked(input);

        // determine the length of the input by finding the location of the last non-zero byte
        for (uint256 i = 32; i > 0; ) {
            // reverse-for-loops with unsigned integer
            i--;

            // find the last non-zero byte in order to determine the length
            if (result[i] != 0) {
                uint256 length = i + 1;

                /* solhint-disable-next-line no-inline-assembly */
                assembly {
                    mstore(result, length) // r.length = length;
                }

                return result;
            }
        }

        // all bytes are zero
        return new bytes(0);
    }

    function stringifyFunctionSelector(
        bytes4 input
    )
    internal
    pure
    returns (bytes memory)
    {
        uint256 z = uint256(bytes32(input) >> 224);

        // bytes4 are "0x" followed by 4 bytes of data which take up 2 characters each
        bytes memory result = new bytes(10);

        // populate the result with "0x"
        result[0] = bytes1(uint8(_ASCII_ZERO));
        result[1] = bytes1(uint8(_ASCII_LOWER_EX));

        // for each byte (starting from the lowest byte), populate the result with two characters
        for (uint256 i = 0; i < 4; i++) {
            // each byte takes two characters
            uint256 shift = i * 2;

            // populate the least-significant character
            result[9 - shift] = _char(z & _FOUR_BIT_MASK);
            z = z >> 4;

            // populate the most-significant character
            result[8 - shift] = _char(z & _FOUR_BIT_MASK);
            z = z >> 4;
        }

        return result;
    }

    function _stringify(
        uint256 input
    )
    private
    pure
    returns (bytes memory)
    {
        if (input == 0) {
            return "0";
        }

        // get the final string length
        uint256 j = input;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }

        // allocate the string
        bytes memory bstr = new bytes(length);

        // populate the string starting with the least-significant character
        j = input;
        for (uint256 i = length; i > 0; ) {
            // reverse-for-loops with unsigned integer
            i--;

            // take last decimal digit
            bstr[i] = bytes1(uint8(_ASCII_ZERO + (j % 10)));

            // remove the last decimal digit
            j /= 10;
        }

        return bstr;
    }

    function _stringify(
        address input
    )
    private
    pure
    returns (bytes memory)
    {
        uint256 z = uint256(uint160(input));

        // addresses are "0x" followed by 20 bytes of data which take up 2 characters each
        bytes memory result = new bytes(42);

        // populate the result with "0x"
        result[0] = bytes1(uint8(_ASCII_ZERO));
        result[1] = bytes1(uint8(_ASCII_LOWER_EX));

        // for each byte (starting from the lowest byte), populate the result with two characters
        for (uint256 i = 0; i < 20; i++) {
            // each byte takes two characters
            uint256 shift = i * 2;

            // populate the least-significant character
            result[41 - shift] = _char(z & _FOUR_BIT_MASK);
            z = z >> 4;

            // populate the most-significant character
            result[40 - shift] = _char(z & _FOUR_BIT_MASK);
            z = z >> 4;
        }

        return result;
    }

    function _stringify(
        bytes32 input
    )
    private
    pure
    returns (bytes memory)
    {
        uint256 z = uint256(input);

        // bytes32 are "0x" followed by 32 bytes of data which take up 2 characters each
        bytes memory result = new bytes(66);

        // populate the result with "0x"
        result[0] = bytes1(uint8(_ASCII_ZERO));
        result[1] = bytes1(uint8(_ASCII_LOWER_EX));

        // for each byte (starting from the lowest byte), populate the result with two characters
        for (uint256 i = 0; i < 32; i++) {
            // each byte takes two characters
            uint256 shift = i * 2;

            // populate the least-significant character
            result[65 - shift] = _char(z & _FOUR_BIT_MASK);
            z = z >> 4;

            // populate the most-significant character
            result[64 - shift] = _char(z & _FOUR_BIT_MASK);
            z = z >> 4;
        }

        return result;
    }

    function _char(
        uint256 input
    )
    private
    pure
    returns (bytes1)
    {
        // return ASCII digit (0-9)
        if (input < 10) {
            return bytes1(uint8(input + _ASCII_ZERO));
        }

        // return ASCII letter (a-f)
        return bytes1(uint8(input + _ASCII_RELATIVE_ZERO));
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.8.9;

import { DolomiteMarginMath } from "./DolomiteMarginMath.sol";
import { IDolomiteStructs } from "../interfaces/IDolomiteStructs.sol";


/**
 * @title   TypesLib
 * @author  dYdX
 *
 * @notice  Library for interacting with the basic structs used in DolomiteMargin
 */
library TypesLib {
    using DolomiteMarginMath for uint256;

    // ============ Par (Principal Amount) ============

    function zeroPar()
    internal
    pure
    returns (IDolomiteStructs.Par memory)
    {
        return IDolomiteStructs.Par({
            sign: false,
            value: 0
        });
    }

    function sub(
        IDolomiteStructs.Par memory a,
        IDolomiteStructs.Par memory b
    )
    internal
    pure
    returns (IDolomiteStructs.Par memory)
    {
        return add(a, negative(b));
    }

    function add(
        IDolomiteStructs.Par memory a,
        IDolomiteStructs.Par memory b
    )
    internal
    pure
    returns (IDolomiteStructs.Par memory)
    {
        IDolomiteStructs.Par memory result;
        if (a.sign == b.sign) {
            result.sign = a.sign;
            result.value = a.value + b.value;
        } else {
            if (a.value >= b.value) {
                result.sign = a.sign;
                result.value = a.value - b.value;
            } else {
                result.sign = b.sign;
                result.value = b.value - a.value;
            }
        }
        return result;
    }

    function equals(
        IDolomiteStructs.Par memory a,
        IDolomiteStructs.Par memory b
    )
    internal
    pure
    returns (bool)
    {
        if (a.value == b.value) {
            if (a.value == 0) {
                return true;
            }
            return a.sign == b.sign;
        }
        return false;
    }

    function negative(
        IDolomiteStructs.Par memory a
    )
    internal
    pure
    returns (IDolomiteStructs.Par memory)
    {
        return IDolomiteStructs.Par({
            sign: !a.sign,
            value: a.value
        });
    }

    function isNegative(
        IDolomiteStructs.Par memory a
    )
    internal
    pure
    returns (bool)
    {
        return !a.sign && a.value > 0;
    }

    function isPositive(
        IDolomiteStructs.Par memory a
    )
    internal
    pure
    returns (bool)
    {
        return a.sign && a.value > 0;
    }

    function isZero(
        IDolomiteStructs.Par memory a
    )
    internal
    pure
    returns (bool)
    {
        return a.value == 0;
    }

    function isLessThanZero(
        IDolomiteStructs.Par memory a
    )
    internal
    pure
    returns (bool)
    {
        return a.value > 0 && !a.sign;
    }

    function isGreaterThanOrEqualToZero(
        IDolomiteStructs.Par memory a
    )
    internal
    pure
    returns (bool)
    {
        return isZero(a) || a.sign;
    }

    // ============ Wei (Token Amount) ============

    function zeroWei()
    internal
    pure
    returns (IDolomiteStructs.Wei memory)
    {
        return IDolomiteStructs.Wei({
            sign: false,
            value: 0
        });
    }

    function sub(
        IDolomiteStructs.Wei memory a,
        IDolomiteStructs.Wei memory b
    )
    internal
    pure
    returns (IDolomiteStructs.Wei memory)
    {
        return add(a, negative(b));
    }

    function add(
        IDolomiteStructs.Wei memory a,
        IDolomiteStructs.Wei memory b
    )
    internal
    pure
    returns (IDolomiteStructs.Wei memory)
    {
        IDolomiteStructs.Wei memory result;
        if (a.sign == b.sign) {
            result.sign = a.sign;
            result.value = a.value + b.value;
        } else {
            if (a.value >= b.value) {
                result.sign = a.sign;
                result.value = a.value - b.value;
            } else {
                result.sign = b.sign;
                result.value = b.value - a.value;
            }
        }
        return result;
    }

    function equals(
        IDolomiteStructs.Wei memory a,
        IDolomiteStructs.Wei memory b
    )
    internal
    pure
    returns (bool)
    {
        if (a.value == b.value) {
            if (a.value == 0) {
                return true;
            }
            return a.sign == b.sign;
        }
        return false;
    }

    function negative(
        IDolomiteStructs.Wei memory a
    )
    internal
    pure
    returns (IDolomiteStructs.Wei memory)
    {
        return IDolomiteStructs.Wei({
            sign: !a.sign,
            value: a.value
        });
    }

    function isNegative(
        IDolomiteStructs.Wei memory a
    )
    internal
    pure
    returns (bool)
    {
        return !a.sign && a.value > 0;
    }

    function isPositive(
        IDolomiteStructs.Wei memory a
    )
    internal
    pure
    returns (bool)
    {
        return a.sign && a.value > 0;
    }

    function isZero(
        IDolomiteStructs.Wei memory a
    )
    internal
    pure
    returns (bool)
    {
        return a.value == 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IIsolationModeVaultFactory } from "@dolomite-exchange/modules-base/contracts/isolation-mode/interfaces/IIsolationModeVaultFactory.sol"; // solhint-disable-line max-line-length
import { IGmxRegistryV1 } from "./IGmxRegistryV1.sol";


/**
 * @title   IGLPIsolationModeVaultFactory
 * @author  Dolomite
 *
 * @notice  Interface for a subclass of IsolationModeVaultFactory that creates vaults for staked-GLP tokens.
 */
interface IGLPIsolationModeVaultFactory is IIsolationModeVaultFactory {

    // ================================================
    // ==================== Events ====================
    // ================================================

    event GmxRegistrySet(address _gmxRegistry);

    // ===================================================
    // ==================== Functions ====================
    // ===================================================

    function createVaultAndAcceptFullAccountTransfer(address _sender) external returns (address);

    function setGmxRegistry(address _gmxRegistry) external;

    function WETH() external view returns (address);

    function WETH_MARKET_ID() external view returns (uint256);

    function gmxRegistry() external view returns (IGmxRegistryV1);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;


/**
 * @title   IGLPManager
 * @author  Dolomite
 *
 * @notice  Interface for getting the AUM (highest bid and lowest ask) of GLP.
 */
interface IGLPManager {

    function getAumInUsdg(bool _maximise) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;


/**
 * @title   IGLPRewardsRouterV2
 * @author  Dolomite
 *
 * @notice  Interface of the GMX Reward Router V2 contract, taken from:
 *          https://arbiscan.io/address/0xB95DB5B167D75e6d04227CfFFA61069348d271F5#code
 */
interface IGLPRewardsRouterV2 {

    function mintAndStakeGlp(
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minGlp
    ) external returns (uint256);

    function unstakeAndRedeemGlp(
        address _tokenOut,
        uint256 _glpAmount,
        uint256 _minAmountOut,
        address _receiver
    ) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IIsolationModeVaultFactory } from "@dolomite-exchange/modules-base/contracts/isolation-mode/interfaces/IIsolationModeVaultFactory.sol"; // solhint-disable-line max-line-length
import { IGmxRegistryV1 } from "./IGmxRegistryV1.sol";


/**
 * @title   IGMXIsolationModeVaultFactory
 * @author  Dolomite
 *
 * @notice  Interface for a subclass of IsolationModeVaultFactory that creates vaults for GMX tokens.
 */
interface IGMXIsolationModeVaultFactory is IIsolationModeVaultFactory {

    // ================================================
    // ==================== Events ====================
    // ================================================

    event GmxRegistrySet(address _gmxRegistry);

    // ===================================================
    // ==================== Functions ====================
    // ===================================================

    function setGmxRegistry(address _gmxRegistry) external;

    function executeDepositIntoVaultFromGLPVault(
        address _gmxVault,
        uint256 _accountNumber,
        uint256 _amountWei,
        bool _shouldSkipTransfer
    ) external;

    function gmxRegistry() external view returns (IGmxRegistryV1);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;


import { IBaseRegistry } from "@dolomite-exchange/modules-base/contracts/interfaces/IBaseRegistry.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IGLPIsolationModeVaultFactory } from "./IGLPIsolationModeVaultFactory.sol";
import { IGLPManager } from "./IGLPManager.sol";
import { IGLPRewardsRouterV2 } from "./IGLPRewardsRouterV2.sol";
import { IGMXIsolationModeVaultFactory } from "./IGMXIsolationModeVaultFactory.sol";
import { IGmxRegistryV1 } from "./IGmxRegistryV1.sol";
import { IGmxRewardRouterV2 } from "./IGmxRewardRouterV2.sol";
import { IGmxVault } from "./IGmxVault.sol";


/**
 * @title   IGmxRegistryV1
 * @author  Dolomite
 *
 * @notice  A registry contract for storing all of the different addresses that can interact with the GMX ecosystem
 */
interface IGmxRegistryV1 is IBaseRegistry {

    // ================================================
    // ==================== Events ====================
    // ================================================

    event BnGmxSet(address _bnGmx);
    event EsGmxSet(address _esGmx);
    event FSGlpSet(address _fsGlp);
    event GlpSet(address _glp);
    event GlpManagerSet(address _glpManager);
    event GlpRewardsRouterSet(address _glpRewardsRouter);
    event GlpVaultFactorySet(address _glpVaultFactory);
    event GmxSet(address _gmx);
    event GmxRewardsRouterSet(address _gmxRewardsRouter);
    event GmxVaultSet(address _gmxVault);
    event GmxVaultFactorySet(address _gmxVaultFactory);
    event SGlpSet(address _sGlp);
    event SGmxSet(address _sGmx);
    event SbfGmxSet(address _sbfGmx);
    event VGlpSet(address _vGlp);
    event VGmxSet(address _vGmx);
    event HandlerSet(address _handler, bool _isTrusted);

    // ===================================================
    // ==================== Functions ====================
    // ===================================================

    function ownerSetBnGmx(address _bnGmx) external;

    function ownerSetEsGmx(address _esGmx) external;

    function ownerSetFSGlp(address _fsGlp) external;

    function ownerSetGlp(address _glp) external;

    function ownerSetGlpManager(address _glpManager) external;

    function ownerSetGlpRewardsRouter(address _glpRewardsRouter) external;

    function ownerSetGlpVaultFactory(address _glpVaultFactory) external;

    function ownerSetGmx(address _gmx) external;

    function ownerSetGmxRewardsRouter(address _gmxRewardsRouter) external;

    function ownerSetGmxVault(address _gmxVault) external;

    function ownerSetGmxVaultFactory(address _gmxVaultFactory) external;

    function ownerSetSGlp(address _sGlp) external;

    function ownerSetSGmx(address _sGmx) external;

    function ownerSetSbfGmx(address _sbfGmx) external;

    function ownerSetVGlp(address _vGlp) external;

    function ownerSetVGmx(address _vGmx) external;

    function ownerSetIsHandler(address _handler, bool _isTrusted) external;

    function bnGmx() external view returns (address);

    function esGmx() external view returns (address);

    function fsGlp() external view returns (IERC20);

    function glp() external view returns (IERC20);

    function glpManager() external view returns (IGLPManager);

    function glpRewardsRouter() external view returns (IGLPRewardsRouterV2);

    function glpVaultFactory() external view returns (IGLPIsolationModeVaultFactory);

    function gmx() external view returns (IERC20);

    function gmxRewardsRouter() external view returns (IGmxRewardRouterV2);

    function gmxVault() external view returns (IGmxVault);

    function gmxVaultFactory() external view returns (IGMXIsolationModeVaultFactory);

    function sGlp() external view returns (address);

    function sGmx() external view returns (address);

    function sbfGmx() external view returns (address);

    function vGlp() external view returns (address);

    function vGmx() external view returns (address);

    function isHandler(address _handler) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;


/**
 * @title   IGmxRewardRouterV2
 * @author  Dolomite
 *
 * @notice  Interface of the GMX Reward Router V2 contract, taken from:
 *          https://arbiscan.io/address/0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1#code
 */
interface IGmxRewardRouterV2 {

    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external;

    function stakeGmx(uint256 _amount) external;

    function unstakeGmx(uint256 _amount) external;

    function stakeEsGmx(uint256 _amount) external;

    function unstakeEsGmx(uint256 _amount) external;

    function signalTransfer(address _receiver) external;

    function acceptTransfer(address _sender) external;

    /**
     * @notice              Checks if a pending transfer has been queued from `_sender` via a call to #signalTransfer
     *
     * @param  _sender      The address to check if a transfer from which has been queued
     * @return _receiver    The address to which the transfer will be sent if it's executed from the queue
     */
    function pendingReceivers(address _sender) external view returns (address _receiver);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;


/**
 * @title   IGmxVault
 * @author  Dolomite
 *
 * @notice  The vault contract used by GMX for holding the assets that back GLP.
 */
interface IGmxVault {

    function getFeeBasisPoints(
        address _token,
        uint256 _usdgDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);

    function getRedemptionAmount(address _token, uint256 _usdgAmount) external view returns (uint256);

    function taxBasisPoints() external view returns (uint256);

    function mintBurnFeeBasisPoints() external view returns (uint256);

    function adjustForDecimals(uint256 _amount, address _tokenDiv, address _tokenMul) external view returns (uint256);

    function usdg() external view returns (address);

    function getMinPrice(address _token) external view returns (uint256);

    function whitelistedTokens(address _token) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address addr) {
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address addr) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40) // Get free memory pointer

            // |                   | ↓ ptr ...  ↓ ptr + 0x0B (start) ...  ↓ ptr + 0x20 ...  ↓ ptr + 0x40 ...   |
            // |-------------------|---------------------------------------------------------------------------|
            // | bytecodeHash      |                                                        CCCCCCCCCCCCC...CC |
            // | salt              |                                      BBBBBBBBBBBBB...BB                   |
            // | deployer          | 000000...0000AAAAAAAAAAAAAAAAAAA...AA                                     |
            // | 0xFF              |            FF                                                             |
            // |-------------------|---------------------------------------------------------------------------|
            // | memory            | 000000...00FFAAAAAAAAAAAAAAAAAAA...AABBBBBBBBBBBBB...BBCCCCCCCCCCCCC...CC |
            // | keccak(start, 85) |            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ |

            mstore(add(ptr, 0x40), bytecodeHash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, deployer) // Right-aligned with 12 preceding garbage bytes
            let start := add(ptr, 0x0b) // The hashed data starts at the final garbage byte which we will set to 0xff
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
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
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
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
            require(denominator > prod1, "Math: mulDiv overflow");

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

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
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

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
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
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
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
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
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
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
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
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IBaseRegistry } from "@dolomite-exchange/modules-base/contracts/interfaces/IBaseRegistry.sol";
import { IPendlePtMarket } from "./IPendlePtMarket.sol";
import { IPendlePtOracle } from "./IPendlePtOracle.sol";
import { IPendlePtToken } from "./IPendlePtToken.sol";
import { IPendleRouter } from "./IPendleRouter.sol";
import { IPendleSyToken } from "./IPendleSyToken.sol";
import { IPendleYtToken } from "./IPendleYtToken.sol";


/**
 * @title   IPendleGLPRegistry
 * @author  Dolomite
 *
 * @notice  A registry contract for storing all of the addresses that can interact with the Pendle ecosystem for GLP
 *          (March 2024).
 */
interface IPendleGLPRegistry is IBaseRegistry {
    // ========================================================
    // ======================== Events ========================
    // ========================================================

    event PendleRouterSet(address indexed _pendleRouter);
    event PtGlpMarketSet(address indexed _ptGlpMarket);
    event PtGlpTokenSet(address indexed _ptGlpToken);
    event PtOracleSet(address indexed _ptOracle);
    event SyGlpTokenSet(address indexed _syGlpToken);
    event YtGlpTokenSet(address indexed _ytGlpToken);

    // ========================================================
    // =================== Admin Functions ====================
    // ========================================================

    function ownerSetPendleRouter(address _pendleRouter) external;

    function ownerSetPtGlpMarket(address _ptGlpMarket) external;

    function ownerSetPtGlpToken(address _ptGlpToken) external;

    function ownerSetPtOracle(address _ptOracle) external;

    function ownerSetSyGlpToken(address _syGlpToken) external;

    function ownerSetYtGlpToken(address _ytGlpToken) external;

    // ========================================================
    // =================== Getter Functions ===================
    // ========================================================

    function pendleRouter() external view returns (IPendleRouter);

    function ptGlpMarket() external view returns (IPendlePtMarket);

    function ptGlpToken() external view returns (IPendlePtToken);

    function ptOracle() external view returns (IPendlePtOracle);

    function syGlpToken() external view returns (IPendleSyToken);

    function ytGlpToken() external view returns (IPendleYtToken);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IIsolationModeTokenVaultV1 } from "@dolomite-exchange/modules-base/contracts/isolation-mode/interfaces/IIsolationModeTokenVaultV1.sol"; // solhint-disable-line max-line-length
import { IPendleGLPRegistry } from "./IPendleGLPRegistry.sol";


/**
 * @title   IPendlePtGLP2024IsolationModeTokenVaultV1
 * @author  Dolomite
 *
 * @notice  Interface for a subclass of IsolationModeTokenVaultV1 that serves as the implementation for the user's proxy
 *          vault for ptGLP tokens.
 */
interface IPendlePtGLP2024IsolationModeTokenVaultV1 is IIsolationModeTokenVaultV1 {

    function registry() external view returns (IPendleGLPRegistry);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IIsolationModeVaultFactory } from "@dolomite-exchange/modules-base/contracts/isolation-mode/interfaces/IIsolationModeVaultFactory.sol"; // solhint-disable-line max-line-length
import { IPendleGLPRegistry } from "./IPendleGLPRegistry.sol";


/**
 * @title   IPendlePtGLP2024IsolationModeVaultFactory
 * @author  Dolomite
 *
 * @notice  Interface for a subclass of IsolationModeVaultFactory that creates vaults for ptGLP tokens.
 */
interface IPendlePtGLPMar2024IsolationModeVaultFactory is IIsolationModeVaultFactory {

    // ================================================
    // ==================== Events ====================
    // ================================================

    event PendlePtGLP2024RegistrySet(address _pendlePtGLP2024Registry);

    // ===================================================
    // ==================== Functions ====================
    // ===================================================

    function ownerSetPendlePtGLP2024Registry(address _pendlePtGLP2024Registry) external;

    function pendlePtGLP2024Registry() external view returns (IPendleGLPRegistry);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IIsolationModeTokenVaultV1 } from "@dolomite-exchange/modules-base/contracts/isolation-mode/interfaces/IIsolationModeTokenVaultV1.sol"; // solhint-disable-line max-line-length
import { IPendleRegistry } from "./IPendleRegistry.sol";


/**
 * @title   IPendlePtIsolationModeTokenVaultV1
 * @author  Dolomite
 *
 * @notice  Interface for a subclass of IsolationModeTokenVaultV1 that serves as the implementation for the user's proxy
 *          vault for PT tokens.
 */
interface IPendlePtIsolationModeTokenVaultV1 is IIsolationModeTokenVaultV1 {

    function registry() external view returns (IPendleRegistry);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IIsolationModeVaultFactory } from "@dolomite-exchange/modules-base/contracts/isolation-mode/interfaces/IIsolationModeVaultFactory.sol"; // solhint-disable-line max-line-length
import { IPendleRegistry } from "./IPendleRegistry.sol";


/**
 * @title   IPendlePtIsolationModeVaultFactory
 * @author  Dolomite
 *
 * @notice  Interface for a subclass of IsolationModeVaultFactory that creates vaults for PT tokens.
 */
interface IPendlePtIsolationModeVaultFactory is IIsolationModeVaultFactory {

    // ================================================
    // ==================== Events ====================
    // ================================================

    event PendleRegistrySet(address _pendleRETHRegistry);

    // ===================================================
    // ==================== Functions ====================
    // ===================================================

    function ownerSetPendleRegistry(address _pendleRegistry) external;

    function pendleRegistry() external view returns (IPendleRegistry);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @title   IPendlePtMarket
 * @author  Dolomite
 *
 * @notice  Interface for interacting with Pendle's AMM LP tokens.
 */
interface IPendlePtMarket is IERC20 {

    function isExpired() external view returns (bool);

    function readTokens() external view returns (address sy, address pt, address yt);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;


/**
 * @title   IPendlePtOracle
 * @author  Dolomite
 *
 * @notice  The vault contract used by GMX for holding the assets that back GLP.
 */
interface IPendlePtOracle {

    /**
     * Gets the TWAP rate of PT/Asset for the given market and duration
     *
     * @param  _market   The market to get the rate from
     * @param  _duration The TWAP duration (in seconds)
     * @return the TWAP rate PT/Asset on market (uses 18 decimals of precision)
     */
    function getPtToAssetRate(
        address _market,
        uint32 _duration
    ) external view returns (uint256);

    /**
     * Gets the state of the oracle (whether or not it can be validly accessed now for the given market and duration)
     *
     * @param  _market   The market to check that oracle state for
     * @param  _duration The TWAP duration (in seconds)
     */
    function getOracleState(
        address _market,
        uint32 _duration
    )
        external
        view
        returns (bool increaseCardinalityRequired, uint16 cardinalityRequired, bool oldestObservationSatisfied);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomitePriceOracle } from "@dolomite-exchange/modules-base/contracts/protocol/interfaces/IDolomitePriceOracle.sol"; // solhint-disable-line max-line-length


/**
 * @title   IPendlePtPriceOracle
 * @author  Dolomite
 *
 * @notice  A price oracle contract for Pendle Pt assets
 */
interface IPendlePtPriceOracle is IDolomitePriceOracle {

    // ========================================================
    // ======================== Events ========================
    // ========================================================

    event DeductionCoefficientSet(uint256 _deductionCoefficient);

    // ========================================================
    // =================== Admin Functions ====================
    // ========================================================

    function ownerSetDeductionCoefficient(uint256 _deductionCoefficient) external;

    // ========================================================
    // =================== Getter Functions ===================
    // ========================================================

    function deductionCoefficient() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @title   IPendlePtToken
 * @author  Dolomite
 *
 * @notice  Interface for interacting with Pendle's principal tokens (PTs).
 */
interface IPendlePtToken is IERC20 {

    function expiry() external view returns (uint256);

    function isExpired() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IBaseRegistry } from "@dolomite-exchange/modules-base/contracts/interfaces/IBaseRegistry.sol";
import { IPendlePtMarket } from "./IPendlePtMarket.sol";
import { IPendlePtOracle } from "./IPendlePtOracle.sol";
import { IPendleRouter } from "./IPendleRouter.sol";
import { IPendleSyToken } from "./IPendleSyToken.sol";


/**
 * @title   IPendleRegistry
 * @author  Dolomite
 *
 * @notice  A registry contract for storing all of the addresses that can interact with the Pendle ecosystem for a PT
 *          asset.
 */
interface IPendleRegistry is IBaseRegistry {

    // ========================================================
    // ======================== Events ========================
    // ========================================================

    event PendleRouterSet(address indexed _pendleRouter);
    event PtMarketSet(address indexed _ptMarket);
    event PtOracleSet(address indexed _ptOracle);
    event SyTokenSet(address indexed _syToken);

    // ========================================================
    // =================== Admin Functions ====================
    // ========================================================

    function ownerSetPendleRouter(address _pendleRouter) external;

    function ownerSetPtMarket(address _ptMarket) external;

    function ownerSetPtOracle(address _ptOracle) external;

    function ownerSetSyToken(address _syToken) external;

    // ========================================================
    // =================== Getter Functions ===================
    // ========================================================

    function pendleRouter() external view returns (IPendleRouter);

    function ptMarket() external view returns (IPendlePtMarket);

    function ptOracle() external view returns (IPendlePtOracle);

    function syToken() external view returns (IPendleSyToken);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;


/**
 * @title   IPendleRouter
 * @author  Dolomite
 *
 * @notice  Router contract for selling ptTokens for underlying assets
 */
interface IPendleRouter {

    struct ApproxParams {
        uint256 guessMin;
        uint256 guessMax;
        /// pass 0 in to skip this variable
        uint256 guessOffchain;
        /// every iteration, the diff between guessMin and guessMax will be divided by 2
        uint256 maxIteration;
        /// the max eps between the returned result & the correct result, base 1e18. Normally this number will be set
        uint256 eps;
        // to 1e15 (1e18/1000 = 0.1%)

        /// Further explanation of the eps. Take swapExactSyForPt for example. To calc the corresponding amount of Pt to
        /// swap out, it's necessary to run an approximation algorithm, because by default there only exists the Pt to
        /// Sy formula
        /// To approx, the 5 values above will have to be provided, and the approx process will run as follows:
        /// mid = (guessMin + guessMax) / 2 // mid here is the current guess of the amount of Pt out
        /// netSyNeed = calcSwapSyForExactPt(mid)
        /// if (netSyNeed > exactSyIn) guessMax = mid - 1 // since the maximum Sy in can't exceed the exactSyIn
        /// else guessMin = mid (1)
        /// For the (1), since netSyNeed <= exactSyIn, the result might be usable. If the netSyNeed is within eps of
        /// exactSyIn (ex eps=0.1% => we have used 99.9% the amount of Sy specified), mid will be chosen as the final
        /// guess result

        /// for guessOffchain, this is to provide a shortcut to guessing. The offchain SDK can precalculate the exact
        /// result before the tx is sent. When the tx reaches the contract, the guessOffchain will be checked first, and
        /// if it satisfies the approximation, it will be used (and save all the guessing). It's expected that this
        /// shortcut will be used in most cases except in cases that there is a trade in the same market right before
        /// the tx
    }

    struct SwapData {
        SwapType swapType;
        address extRouter;
        bytes extCalldata;
        bool needScale;
    }

    enum SwapType {
        NONE,
        KYBERSWAP,
        ONE_INCH,
        // ETH_WETH not used in Aggregator
        ETH_WETH
    }

    struct TokenInput {
        // Token/Sy data
        address tokenIn;
        uint256 netTokenIn;
        address tokenMintSy;
        address bulk;
        // aggregator data
        address pendleSwap;
        SwapData swapData;
    }

    struct TokenOutput {
        // Token/Sy data
        address tokenOut;
        uint256 minTokenOut;
        address tokenRedeemSy;
        address bulk;
        // aggregator data
        address pendleSwap;
        SwapData swapData;
    }

    /**
     * @notice swap (through Kyberswap) from any input token for SY-mintable tokens, then mints SY
     * and swaps said SY for PT
     *
     * @param  input  data for input token, see {`./kyberswap/KyberSwapHelper.sol`}
     * @dev is a combination of `_mintSyFromToken()` and `_swapExactSyForPt()`
     */
    function swapExactTokenForPt(
        address receiver,
        address market,
        uint256 minPtOut,
        ApproxParams calldata guessPtOut,
        TokenInput calldata input
    ) external payable returns (uint256 netPtOut, uint256 netSyFee);

    /**
     * @notice swap from exact amount of PT to SY, then redeem SY for assets, finally swaps
     * resulting assets through Kyberswap to get desired output token
     *
     * @param  receiver      The address to receive output token
     * @param  exactPtIn     There will always consume this much PT for as much SY as possible
     * @param  output        The data for desired output token, see {`./kyberswap/KyberSwapHelper.sol`}
     * @dev This is a combination of `_swapExactPtForSy()` and `_redeemSyToToken()`
     */
    function swapExactPtForToken(
        address receiver,
        address market,
        uint256 exactPtIn,
        TokenOutput calldata output
    ) external returns (uint256 netTokenOut, uint256 netSyFee);

    function swapExactYtForToken(
        address receiver,
        address market,
        uint256 netYtIn,
        TokenOutput calldata output
    ) external returns (uint256 netTokenOut, uint256 netSyFee);

    function swapExactTokenForYt(
        address receiver,
        address market,
        uint256 minYtOut,
        ApproxParams calldata guessYtOut,
        TokenInput calldata input
    ) external payable returns (uint256 netYtOut, uint256 netSyFee);

    function mintPyFromSy(
        address receiver,
        address YT, // solhint-disable-line var-name-mixedcase
        uint256 netSyIn,
        uint256 minPyOut
    ) external returns (uint256 netPyOut);

    function redeemPyToToken(
        address receiver,
        address YT,
        uint256 netPyIn,
        TokenOutput calldata output
    ) external returns (uint256 netTokenOut);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;


/**
 * @title   IPendleRouterV3
 * @author  Dolomite
 *
 * @notice  Router contract for selling ptTokens for underlying assets
 */
interface IPendleRouterV3 {

    enum OrderType {
        SY_FOR_PT,
        PT_FOR_SY,
        SY_FOR_YT,
        YT_FOR_SY
    }

    enum SwapType {
        NONE,
        KYBERSWAP,
        ONE_INCH,
        // ETH_WETH not used in Aggregator
        ETH_WETH
    }

    struct ApproxParams {
        uint256 guessMin;
        uint256 guessMax;
        /// pass 0 in to skip this variable
        uint256 guessOffchain;
        /// every iteration, the diff between guessMin and guessMax will be divided by 2
        uint256 maxIteration;
        /// the max eps between the returned result & the correct result, base 1e18. Normally this number will be set
        uint256 eps;
        // to 1e15 (1e18/1000 = 0.1%)

        /// Further explanation of the eps. Take swapExactSyForPt for example. To calc the corresponding amount of Pt to
        /// swap out, it's necessary to run an approximation algorithm, because by default there only exists the Pt to
        /// Sy formula
        /// To approx, the 5 values above will have to be provided, and the approx process will run as follows:
        /// mid = (guessMin + guessMax) / 2 // mid here is the current guess of the amount of Pt out
        /// netSyNeed = calcSwapSyForExactPt(mid)
        /// if (netSyNeed > exactSyIn) guessMax = mid - 1 // since the maximum Sy in can't exceed the exactSyIn
        /// else guessMin = mid (1)
        /// For the (1), since netSyNeed <= exactSyIn, the result might be usable. If the netSyNeed is within eps of
        /// exactSyIn (ex eps=0.1% => we have used 99.9% the amount of Sy specified), mid will be chosen as the final
        /// guess result

        /// for guessOffchain, this is to provide a shortcut to guessing. The offchain SDK can precalculate the exact
        /// result before the tx is sent. When the tx reaches the contract, the guessOffchain will be checked first, and
        /// if it satisfies the approximation, it will be used (and save all the guessing). It's expected that this
        /// shortcut will be used in most cases except in cases that there is a trade in the same market right before
        /// the tx
    }

    struct SwapData {
        SwapType swapType;
        address extRouter;
        bytes extCalldata;
        bool needScale;
    }

    struct TokenInput {
        // TOKEN DATA
        address tokenIn;
        uint256 netTokenIn;
        address tokenMintSy;
        // AGGREGATOR DATA
        address pendleSwap;
        SwapData swapData;
    }

    struct TokenOutput {
        // TOKEN DATA
        address tokenOut;
        uint256 minTokenOut;
        address tokenRedeemSy;
        // AGGREGATOR DATA
        address pendleSwap;
        SwapData swapData;
    }

    struct LimitOrderData {
        address limitRouter;
        uint256 epsSkipMarket; // only used for swap operations, will be ignored otherwise
        FillOrderParams[] normalFills;
        FillOrderParams[] flashFills;
        bytes optData;
    }

    struct Order {
        uint256 salt;
        uint256 expiry;
        uint256 nonce;
        OrderType orderType;
        address token;
        address YT;
        address maker;
        address receiver;
        uint256 makingAmount;
        uint256 lnImpliedRate;
        uint256 failSafeRate;
        bytes permit;
    }

    struct FillOrderParams {
        Order order;
        bytes signature;
        uint256 makingAmount;
    }

    function swapExactTokenForPt(
        address receiver,
        address market,
        uint256 minPtOut,
        ApproxParams calldata guessPtOut,
        TokenInput calldata input,
        LimitOrderData calldata limit
    ) external payable returns (uint256 netPtOut, uint256 netSyFee, uint256 netSyInterm);

    function swapExactPtForToken(
        address receiver,
        address market,
        uint256 exactPtIn,
        TokenOutput calldata output,
        LimitOrderData calldata limit
    ) external returns (uint256 netTokenOut, uint256 netSyFee, uint256 netSyInterm);

    function swapExactTokenForYt(
        address receiver,
        address market,
        uint256 minYtOut,
        ApproxParams calldata guessYtOut,
        TokenInput calldata input,
        LimitOrderData calldata limit
    ) external payable returns (uint256 netYtOut, uint256 netSyFee, uint256 netSyInterm);

    function swapExactYtForToken(
        address receiver,
        address market,
        uint256 exactYtIn,
        TokenOutput calldata output,
        LimitOrderData calldata limit
    ) external returns (uint256 netTokenOut, uint256 netSyFee, uint256 netSyInterm);

    function mintPyFromSy(
        address receiver,
        address YT,
        uint256 netSyIn,
        uint256 minPyOut
    ) external returns (uint256 netPyOut);

    function redeemPyToToken(
        address receiver,
        address YT,
        uint256 netPyIn,
        TokenOutput calldata output
    ) external returns (uint256 netTokenOut);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @title   IPendleSyToken
 * @author  Dolomite
 *
 * @notice  Interface for interacting with Pendle's standard yield tokens (SYs).
 */
interface IPendleSyToken is IERC20 {

    function pause() external;

    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) external;

    function deposit(
        address receiver,
        address tokenIn,
        uint256 amountTokenToDeposit,
        uint256 minSharesOut
    ) external payable returns (uint256 amountSharesOut);

    function paused() external view returns (bool);

    function owner() external view returns (address);

    function getTokensIn() external view returns (address[] memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IIsolationModeTokenVaultV1 } from "@dolomite-exchange/modules-base/contracts/isolation-mode/interfaces/IIsolationModeTokenVaultV1.sol"; // solhint-disable-line max-line-length


/**
 * @title   IPendleYtGLP2024IsolationModeTokenVaultV1
 * @author  Dolomite
 *
 * @notice  Interface for a subclass of IsolationModeTokenVaultV1 that serves as the implementation for the user's proxy
 *          vault for ytGLP tokens.
 */
interface IPendleYtGLP2024IsolationModeTokenVaultV1 is IIsolationModeTokenVaultV1 {

    function redeemDueInterestAndRewards(
        bool _redeemInterest,
        bool _redeemRewards,
        bool[] memory _depositRewardsIntoDolomite,
        bool _depositInterestIntoDolomite
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IIsolationModeVaultFactory } from "@dolomite-exchange/modules-base/contracts/isolation-mode/interfaces/IIsolationModeVaultFactory.sol"; // solhint-disable-line max-line-length
import { IPendleGLPRegistry } from "./IPendleGLPRegistry.sol";

/**
 * @title   IPendleYtGLP2024IsolationModeVaultFactory
 * @author  Dolomite
 *
 * @notice  Interface for a subclass of IsolationModeVaultFactory that creates vaults for ytGLP tokens.
 */
interface IPendleYtGLP2024IsolationModeVaultFactory is IIsolationModeVaultFactory {
    // ================================================
    // ==================== Events ====================
    // ================================================

    event PendleGLPRegistrySet(address _pendleGLPRegistry);
    event YtMaturityTimestampSet(uint256 _ytMaturityTimestamp);

    // ===================================================
    // ==================== Functions ====================
    // ===================================================

    function ownerSetPendleGLPRegistry(address _pendleGLPRegistry) external;

    function ownerSetYtMaturityTimestamp(uint256 _ytMaturityTimstamp) external;

    function WETH() external view returns (address);

    function WETH_MARKET_ID() external view returns (uint256);

    function pendleGLPRegistry() external view returns (IPendleGLPRegistry);

    function ytMaturityTimestamp() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title   IPendleYtToken
 * @author  Dolomite
 *
 * @notice  Interface for interacting with Pendle's yield tokens (YTs).
 */
interface IPendleYtToken is IERC20 {

    /**
     * @notice  Redeems interests and rewards for `_user`
     * @dev     With YT yielding interest in the form of SY, which is redeemable by users, the reward distribution
     *          should be based on the amount of SYs that their YT currently represent, plus their dueInterest. It has
     *          been proven and tested that _rewardSharesUser will not change over time, unless users redeem their
     *          dueInterest or redeemPY. Due to this, it is required to update users' accruedReward STRICTLY BEFORE
     *          transferring out their interest.
     * @dev     Interest yield is denominated in the same unit as the interest bearing token
     * @dev     Reward yield is given out in a different unit than the interest bearing token
     *
     * @param  _user            The user whose interest and rewards will be redeemed
     * @param  _redeemInterest  Will only transfer out interest for user if true
     * @param  _redeemRewards   Will only transfer out rewards for user if true
     */
    function redeemDueInterestAndRewards(
        address _user,
        bool _redeemInterest,
        bool _redeemRewards
    ) external returns (uint256 interestOut, uint256[] memory rewardsOut);

    function getRewardTokens() external view returns (address[] memory);

    function expiry() external view returns (uint256);

    function isExpired() external view returns (bool);

    function SY() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { BaseRegistry } from "@dolomite-exchange/modules-base/contracts/general/BaseRegistry.sol";
import { Require } from "@dolomite-exchange/modules-base/contracts/protocol/lib/Require.sol";
import { IPendleGLPRegistry } from "./interfaces/IPendleGLPRegistry.sol";
import { IPendlePtMarket } from "./interfaces/IPendlePtMarket.sol";
import { IPendlePtOracle } from "./interfaces/IPendlePtOracle.sol";
import { IPendlePtToken } from "./interfaces/IPendlePtToken.sol";
import { IPendleRouter } from "./interfaces/IPendleRouter.sol";
import { IPendleSyToken } from "./interfaces/IPendleSyToken.sol";
import { IPendleYtToken } from "./interfaces/IPendleYtToken.sol";



/**
 * @title   PendleGLPRegistry
 * @author  Dolomite
 *
 * @notice  Implementation for a registry that contains all of the Pendle-related addresses. This registry is needed
 *          to offer uniform access to addresses in an effort to keep Dolomite's contracts as up-to-date as possible
 *          without having to deprecate the system and force users to migrate when Dolomite needs to point to new
 *          contracts or functions that Pendle introduces.
 */
contract PendleGLPRegistry is IPendleGLPRegistry, BaseRegistry {
    // ==================== Constants ====================

    bytes32 private constant _FILE = "PendleGLPRegistry";

    bytes32 private constant _PENDLE_ROUTER_SLOT = bytes32(uint256(keccak256("eip1967.proxy.pendleRouter")) - 1);
    bytes32 private constant _PENDLE_PT_GLP_MARKET_SLOT = bytes32(uint256(keccak256("eip1967.proxy.ptGlpMarket")) - 1);
    bytes32 private constant _PENDLE_PT_GLP_TOKEN_SLOT = bytes32(uint256(keccak256("eip1967.proxy.ptGlpToken")) - 1);
    bytes32 private constant _PENDLE_PT_ORACLE_SLOT = bytes32(uint256(keccak256("eip1967.proxy.ptOracle")) - 1);
    bytes32 private constant _PENDLE_SY_GLP_TOKEN_SLOT = bytes32(uint256(keccak256("eip1967.proxy.syGlpToken")) - 1);
    bytes32 private constant _PENDLE_YT_GLP_TOKEN_SLOT = bytes32(uint256(keccak256("eip1967.proxy.ytGlpToken")) - 1);

    // ==================== Initializer ====================

    function initialize(
        address _pendleRouter,
        address _ptGlpMarket,
        address _ptGlpToken,
        address _ptOracle,
        address _syGlpToken,
        address _ytGlpToken,
        address _dolomiteRegistry
    ) external initializer {
        _ownerSetPendleRouter(_pendleRouter);
        _ownerSetPtGlpMarket(_ptGlpMarket);
        _ownerSetPtOracle(_ptOracle);
        _ownerSetSyGlpToken(_syGlpToken);
        _ownerSetPtGlpToken(_ptGlpToken);
        _ownerSetYtGlpToken(_ytGlpToken);
        _ownerSetDolomiteRegistry(_dolomiteRegistry);
    }

    // ==================== Functions ====================

    function ownerSetPendleRouter(
        address _pendleRouter
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        _ownerSetPendleRouter(_pendleRouter);
    }

    function ownerSetPtGlpMarket(
        address _ptGlpMarket
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        _ownerSetPtGlpMarket(_ptGlpMarket);
    }

    function ownerSetPtOracle(
        address _ptOracle
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        _ownerSetPtOracle(_ptOracle);
    }

    function ownerSetSyGlpToken(
        address _syGlpToken
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        _ownerSetSyGlpToken(_syGlpToken);
    }

    function ownerSetPtGlpToken(
        address _ptGlpToken
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        _ownerSetPtGlpToken(_ptGlpToken);
    }

    function ownerSetYtGlpToken(
        address _ytGlpToken
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        _ownerSetYtGlpToken(_ytGlpToken);
    }

    // ==================== Views ====================

    function pendleRouter() external view returns (IPendleRouter) {
        return IPendleRouter(_getAddress(_PENDLE_ROUTER_SLOT));
    }

    function ptGlpMarket() external view returns (IPendlePtMarket) {
        return IPendlePtMarket(_getAddress(_PENDLE_PT_GLP_MARKET_SLOT));
    }

    function ptOracle() external view returns (IPendlePtOracle) {
        return IPendlePtOracle(_getAddress(_PENDLE_PT_ORACLE_SLOT));
    }

    function syGlpToken() external view returns (IPendleSyToken) {
        return IPendleSyToken(_getAddress(_PENDLE_SY_GLP_TOKEN_SLOT));
    }

    function ptGlpToken() external view returns (IPendlePtToken) {
        return IPendlePtToken(_getAddress(_PENDLE_PT_GLP_TOKEN_SLOT));
    }

    function ytGlpToken() external view returns (IPendleYtToken) {
        return IPendleYtToken(_getAddress(_PENDLE_YT_GLP_TOKEN_SLOT));
    }

    // ============================================================
    // ==================== Internal Functions ====================
    // ============================================================

    function _ownerSetPendleRouter(address _pendleRouter) internal {
        Require.that(
            _pendleRouter != address(0),
            _FILE,
            "Invalid pendleRouter address"
        );
        _setAddress(_PENDLE_ROUTER_SLOT, _pendleRouter);
        emit PendleRouterSet(_pendleRouter);
    }

    function _ownerSetPtGlpMarket(address _ptGlpMarket) internal {
        Require.that(
            _ptGlpMarket != address(0),
            _FILE,
            "Invalid ptGlpMarket address"
        );
        _setAddress(_PENDLE_PT_GLP_MARKET_SLOT, _ptGlpMarket);
        emit PtGlpMarketSet(_ptGlpMarket);
    }

    function _ownerSetPtOracle(address _ptOracle) internal {
        Require.that(
            _ptOracle != address(0),
            _FILE,
            "Invalid ptOracle address"
        );
        _setAddress(_PENDLE_PT_ORACLE_SLOT, _ptOracle);
        emit PtOracleSet(_ptOracle);
    }

    function _ownerSetSyGlpToken(address _syGlpToken) internal {
        Require.that(
            _syGlpToken != address(0),
            _FILE,
            "Invalid syGlpToken address"
        );
        _setAddress(_PENDLE_SY_GLP_TOKEN_SLOT, _syGlpToken);
        emit SyGlpTokenSet(_syGlpToken);
    }

    function _ownerSetPtGlpToken(address _ptGlpToken) internal {
        Require.that(
            _ptGlpToken != address(0),
            _FILE,
            "Invalid ptGlpToken address"
        );
        _setAddress(_PENDLE_PT_GLP_TOKEN_SLOT, _ptGlpToken);
        emit PtGlpTokenSet(_ptGlpToken);
    }

    function _ownerSetYtGlpToken(address _ytGlpToken) internal {
        Require.that(
            _ytGlpToken != address(0),
            _FILE,
            "Invalid ytGlpToken address"
        );
        _setAddress(_PENDLE_YT_GLP_TOKEN_SLOT, _ytGlpToken);
        emit YtGlpTokenSet(_ytGlpToken);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomitePriceOracle } from "@dolomite-exchange/modules-base/contracts/protocol/interfaces/IDolomitePriceOracle.sol"; // solhint-disable-line max-line-length
import { PendlePtPriceOracle } from "./PendlePtPriceOracle.sol";


/**
 * @title   PendlePtEEthPriceOracle
 * @author  Dolomite
 *
 * @notice  An implementation of the IDolomitePriceOracle interface that gets Pendle's pt price in USD terms.
 */
contract PendlePtEEthPriceOracle is PendlePtPriceOracle {

    // ============================ Constants ============================

    bytes32 private constant _FILE = "PendlePtEEthPriceOracle";
    uint256 public constant WE_ETH_ASSET_SCALE = 1 ether;

    // ============================ Constructor ============================

    constructor(
        address _dptToken,
        address _pendleRegistry,
        address _underlyingToken,
        address _dolomiteMargin
    ) PendlePtPriceOracle(_dptToken, _pendleRegistry, _underlyingToken, _dolomiteMargin) {}

    // ============================ Internal Functions ============================

    function _getCurrentPrice() internal view override returns (uint256) {
        // PT-weEth -> eEth
        uint256 ptExchangeRate = REGISTRY.ptOracle().getPtToAssetRate(address(REGISTRY.ptMarket()), TWAP_DURATION);
        // eEth -> weEth
        uint256 weETHExchangeRate = REGISTRY.dolomiteRegistry().chainlinkPriceOracle().getPrice(UNDERLYING_TOKEN).value;
        // weEth -> USD
        uint256 underlyingPrice = REGISTRY.dolomiteRegistry().redstonePriceOracle().getPrice(UNDERLYING_TOKEN).value;

        return _applyDeductionCoefficient(
            underlyingPrice * ptExchangeRate * WE_ETH_ASSET_SCALE / (PT_ASSET_SCALE * weETHExchangeRate)
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteRegistry } from "@dolomite-exchange/modules-base/contracts/interfaces/IDolomiteRegistry.sol";
import { IsolationModeTokenVaultV1 } from "@dolomite-exchange/modules-base/contracts/isolation-mode/abstract/IsolationModeTokenVaultV1.sol"; // solhint-disable-line max-line-length
import { IsolationModeTokenVaultV1WithPausable } from "@dolomite-exchange/modules-base/contracts/isolation-mode/abstract/IsolationModeTokenVaultV1WithPausable.sol"; // solhint-disable-line max-line-length
import { IPendleGLPRegistry } from "./interfaces/IPendleGLPRegistry.sol";
import { IPendlePtGLP2024IsolationModeTokenVaultV1 } from "./interfaces/IPendlePtGLP2024IsolationModeTokenVaultV1.sol";
import {IPendlePtGLPMar2024IsolationModeVaultFactory} from "./interfaces/IPendlePtGLP2024IsolationModeVaultFactory.sol";


/**
 * @title   PendlePtGLP2024IsolationModeTokenVaultV1
 * @author  Dolomite
 *
 * @notice  Implementation (for an upgradeable proxy) for a per-user vault that holds the ptGLP (March 2024 expiration)
 *          token that can be used to credit a user's Dolomite balance.
 */
contract PendlePtGLP2024IsolationModeTokenVaultV1 is
    IPendlePtGLP2024IsolationModeTokenVaultV1,
    IsolationModeTokenVaultV1WithPausable
{

    // ==================================================================
    // =========================== Constants ============================
    // ==================================================================

    bytes32 private constant _FILE = "PendlePtGLP2024UserVaultV1";

    // ==================================================================
    // ======================== Public Functions ========================
    // ==================================================================

    function registry() public view returns (IPendleGLPRegistry) {
        return IPendlePtGLPMar2024IsolationModeVaultFactory(VAULT_FACTORY()).pendlePtGLP2024Registry();
    }

    function dolomiteRegistry()
        public
        override
        view
        returns (IDolomiteRegistry)
    {
        return registry().dolomiteRegistry();
    }

    function isExternalRedemptionPaused() public override view returns (bool) {
        return registry().syGlpToken().paused();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IsolationModeUnwrapperTraderV2 } from "@dolomite-exchange/modules-base/contracts/isolation-mode/abstract/IsolationModeUnwrapperTraderV2.sol"; // solhint-disable-line max-line-length
import { Require } from "@dolomite-exchange/modules-base/contracts/protocol/lib/Require.sol";
import { IGmxRegistryV1 } from "@dolomite-exchange/modules-glp/contracts/interfaces/IGmxRegistryV1.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IPendleGLPRegistry } from "./interfaces/IPendleGLPRegistry.sol";
import { IPendlePtToken } from "./interfaces/IPendlePtToken.sol";
import { IPendleRouter } from "./interfaces/IPendleRouter.sol";


/**
 * @title   PendlePtGLPMar2024IsolationModeUnwrapperTraderV2
 * @author  Dolomite
 *
 * @notice  Used for unwrapping ptGLP (via swapping against the Pendle AMM then redeeming the underlying GLP to
 *          USDC).
 */
contract PendlePtGLPMar2024IsolationModeUnwrapperTraderV2 is IsolationModeUnwrapperTraderV2 {
    using SafeERC20 for IERC20;
    using SafeERC20 for IPendlePtToken;

    // ============ Constants ============

    bytes32 private constant _FILE = "PendlePtGLP2024UnwrapperV2";

    // ============ Constructor ============

    IPendleGLPRegistry public immutable PENDLE_REGISTRY; // solhint-disable-line var-name-mixedcase
    IGmxRegistryV1 public immutable GMX_REGISTRY; // solhint-disable-line var-name-mixedcase

    // ============ Constructor ============

    constructor(
        address _pendleRegistry,
        address _gmxRegistry,
        address _dptGlp,
        address _dolomiteMargin
    )
    IsolationModeUnwrapperTraderV2(
        _dptGlp,
        _dolomiteMargin,
        address(IPendleGLPRegistry(_pendleRegistry).dolomiteRegistry())
    ) {
        PENDLE_REGISTRY = IPendleGLPRegistry(_pendleRegistry);
        GMX_REGISTRY = IGmxRegistryV1(_gmxRegistry);
    }

    // ============================================
    // ============= Public Functions =============
    // ============================================

    function isValidOutputToken(address _outputToken) public override view returns (bool) {
        return GMX_REGISTRY.gmxVault().whitelistedTokens(_outputToken);
    }

    // ============================================
    // =========== Internal Functions =============
    // ============================================

    function _exchangeUnderlyingTokenToOutputToken(
        address,
        address,
        address _outputToken,
        uint256 _minOutputAmount,
        address,
        uint256 _inputAmount,
        bytes memory _extraOrderData
    )
        internal
        override
        returns (uint256)
    {
        (
            IPendleRouter.TokenOutput memory tokenOutput
        ) = abi.decode(_extraOrderData, (IPendleRouter.TokenOutput));

        // redeem ptGLP for GLP
        IPendleRouter pendleRouter = PENDLE_REGISTRY.pendleRouter();
        PENDLE_REGISTRY.ptGlpToken().safeApprove(address(pendleRouter), _inputAmount);
        (uint256 glpAmount,) = pendleRouter.swapExactPtForToken(
            /* _receiver */ address(this),
            address(PENDLE_REGISTRY.ptGlpMarket()),
            _inputAmount,
            tokenOutput
        );

        // redeem GLP for `_outputToken`; we don't need to approve sGLP because there is a handler that auto-approves
        // for this
        uint256 amountOut = GMX_REGISTRY.glpRewardsRouter().unstakeAndRedeemGlp(
            /* _tokenOut = */ _outputToken,
            glpAmount,
            _minOutputAmount,
            /* _receiver = */ address(this)
        );

        return amountOut;
    }

    function _getExchangeCost(
        address,
        address,
        uint256,
        bytes memory
    )
    internal
    override
    pure
    returns (uint256) {
        revert(string(abi.encodePacked(Require.stringifyTruncated(_FILE), ": getExchangeCost is not implemented")));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IsolationModeVaultFactory } from "@dolomite-exchange/modules-base/contracts/isolation-mode/abstract/IsolationModeVaultFactory.sol"; // solhint-disable-line max-line-length
import { IPendleGLPRegistry } from "./interfaces/IPendleGLPRegistry.sol";
import { IPendlePtGLPMar2024IsolationModeVaultFactory } from "./interfaces/IPendlePtGLP2024IsolationModeVaultFactory.sol";


/**
 * @title   PendlePtGLPMar2024IsolationModeVaultFactory
 * @author  Dolomite
 *
 * @notice  The wrapper around the ptGLP token that is used to create user vaults and manage the entry points that a
 *          user can use to interact with DolomiteMargin from the vault.
 */
contract PendlePtGLPMar2024IsolationModeVaultFactory is
    IPendlePtGLPMar2024IsolationModeVaultFactory,
    IsolationModeVaultFactory
{
    // ============ Constants ============

    bytes32 private constant _FILE = "PendlePtGLP2024VaultFactory"; // needed to be shortened to fit into 32 bytes

    // ============ Field Variables ============

    IPendleGLPRegistry public override pendlePtGLP2024Registry;

    // ============ Constructor ============

    constructor(
        address _pendlePtGLP2024Registry,
        address _ptGlp, // this serves as the underlying token
        address _borrowPositionProxy,
        address _userVaultImplementation,
        address _dolomiteMargin
    )
    IsolationModeVaultFactory(
        _ptGlp,
        _borrowPositionProxy,
        _userVaultImplementation,
        _dolomiteMargin
    ) {
        pendlePtGLP2024Registry = IPendleGLPRegistry(_pendlePtGLP2024Registry);
    }

    // ============ External Functions ============

    function ownerSetPendlePtGLP2024Registry(
        address _pendlePtGLP2024Registry
    )
    external
    override
    onlyDolomiteMarginOwner(msg.sender) {
        pendlePtGLP2024Registry = IPendleGLPRegistry(_pendlePtGLP2024Registry);
        emit PendlePtGLP2024RegistrySet(_pendlePtGLP2024Registry);
    }

    function allowableDebtMarketIds() external pure returns (uint256[] memory) {
        // allow all markets
        return new uint256[](0);
    }

    function allowableCollateralMarketIds() external pure returns (uint256[] memory) {
        // allow all markets
        return new uint256[](0);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IsolationModeWrapperTraderV2 } from "@dolomite-exchange/modules-base/contracts/isolation-mode/abstract/IsolationModeWrapperTraderV2.sol"; // solhint-disable-line max-line-length
import { Require } from "@dolomite-exchange/modules-base/contracts/protocol/lib/Require.sol";
import { IGmxRegistryV1 } from "@dolomite-exchange/modules-glp/contracts/interfaces/IGmxRegistryV1.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IPendleGLPRegistry } from "./interfaces/IPendleGLPRegistry.sol";
import { IPendleRouter } from "./interfaces/IPendleRouter.sol";

/**
 * @title   PendlePtGLPMar2024IsolationModeWrapperTraderV2
 * @author  Dolomite
 *
 * @notice  Used for wrapping ptGLP (via swapping against the Pendle AMM then redeeming the underlying GLP to
 *          USDC).
 */
contract PendlePtGLPMar2024IsolationModeWrapperTraderV2 is IsolationModeWrapperTraderV2 {
    using SafeERC20 for IERC20;

    // ============ Constants ============

    bytes32 private constant _FILE = "PendlePtGLP2024WrapperV2";

    // ============ Constructor ============

    IPendleGLPRegistry public immutable PENDLE_REGISTRY; // solhint-disable-line var-name-mixedcase
    IGmxRegistryV1 public immutable GMX_REGISTRY; // solhint-disable-line var-name-mixedcase

    // ============ Constructor ============

    constructor(
        address _pendleRegistry,
        address _gmxRegistry,
        address _dptGlp,
        address _dolomiteMargin
    )
    IsolationModeWrapperTraderV2(
        _dptGlp,
        _dolomiteMargin,
        address(IPendleGLPRegistry(_pendleRegistry).dolomiteRegistry())
    ) {
        PENDLE_REGISTRY = IPendleGLPRegistry(_pendleRegistry);
        GMX_REGISTRY = IGmxRegistryV1(_gmxRegistry);
    }

    // ============================================
    // ============= Public Functions =============
    // ============================================

    function isValidInputToken(address _inputToken) public override view returns (bool) {
        return GMX_REGISTRY.gmxVault().whitelistedTokens(_inputToken);
    }

    // ============================================
    // ============ Internal Functions ============
    // ============================================

    function _exchangeIntoUnderlyingToken(
        address,
        address,
        address,
        uint256 _minOutputAmount,
        address _inputToken,
        uint256 _inputAmount,
        bytes memory _extraOrderData
    )
        internal
        override
        returns (uint256)
    {
        (
            IPendleRouter.ApproxParams memory guessPtOut,
            IPendleRouter.TokenInput memory tokenInput
        ) = abi.decode(_extraOrderData, (IPendleRouter.ApproxParams, IPendleRouter.TokenInput));

        // approve input token and mint GLP
        IERC20(_inputToken).safeApprove(address(GMX_REGISTRY.glpManager()), _inputAmount);
        uint256 glpAmount = GMX_REGISTRY.glpRewardsRouter().mintAndStakeGlp(
            _inputToken,
            _inputAmount,
            /* _minUsdg = */ 0,
            /* _minGlp = */ 0
        );
        tokenInput.netTokenIn = glpAmount;

        uint256 ptGlpAmount;
        {
            // Create a new scope to avoid stack too deep errors
            // approve GLP and swap for ptGLP
            IPendleRouter pendleRouter = PENDLE_REGISTRY.pendleRouter();
            IERC20(GMX_REGISTRY.sGlp()).safeApprove(address(pendleRouter), glpAmount);
            (ptGlpAmount,) = pendleRouter.swapExactTokenForPt(
                /* _receiver = */ address(this),
                address(PENDLE_REGISTRY.ptGlpMarket()),
                _minOutputAmount,
                guessPtOut,
                tokenInput
            );
        }

        return ptGlpAmount;
    }

    function _getExchangeCost(
        address,
        address,
        uint256,
        bytes memory
    )
    internal
    override
    pure
    returns (uint256)
    {
        revert(string(abi.encodePacked(Require.stringifyTruncated(_FILE), ": getExchangeCost is not implemented")));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteMargin } from "@dolomite-exchange/modules-base/contracts/protocol/interfaces/IDolomiteMargin.sol";
import { IDolomitePriceOracle } from "@dolomite-exchange/modules-base/contracts/protocol/interfaces/IDolomitePriceOracle.sol"; // solhint-disable-line max-line-length
import { IDolomiteStructs } from "@dolomite-exchange/modules-base/contracts/protocol/interfaces/IDolomiteStructs.sol";

import { Require } from "@dolomite-exchange/modules-base/contracts/protocol/lib/Require.sol";

import { IPendleGLPRegistry } from "./interfaces/IPendleGLPRegistry.sol";

/**
 * @title   PendlePtGLPPriceOracle
 * @author  Dolomite
 *
 * @notice  An implementation of the IDolomitePriceOracle interface that gets Pendle's ptGLP price in USD terms.
 */
contract PendlePtGLPPriceOracle is IDolomitePriceOracle {

    // ============================ Constants ============================

    bytes32 private constant _FILE = "PendlePtGLPPriceOracle";
    uint32 public constant TWAP_DURATION = 900; // 15 minutes
    uint256 public constant PT_ASSET_SCALE = 1e18; // 18 decimals

    // ============================ Public State Variables ============================

    address immutable public DPT_GLP; // solhint-disable-line var-name-mixedcase
    IPendleGLPRegistry immutable public REGISTRY; // solhint-disable-line var-name-mixedcase
    IDolomiteMargin immutable public DOLOMITE_MARGIN; // solhint-disable-line var-name-mixedcase
    uint256 immutable public DFS_GLP_MARKET_ID; // solhint-disable-line var-name-mixedcase

    // ============================ Constructor ============================

    constructor(
        address _dptGlp,
        address _pendleGLPRegistry,
        address _dolomiteMargin,
        uint256 _dfsGlpMarketId
    ) {
        DPT_GLP = _dptGlp;
        REGISTRY = IPendleGLPRegistry(_pendleGLPRegistry);
        DOLOMITE_MARGIN = IDolomiteMargin(_dolomiteMargin);
        DFS_GLP_MARKET_ID = _dfsGlpMarketId;

        (
            bool increaseCardinalityRequired,,
            bool oldestObservationSatisfied
        ) = REGISTRY.ptOracle().getOracleState(address(REGISTRY.ptGlpMarket()), TWAP_DURATION);

        Require.that(
            !increaseCardinalityRequired && oldestObservationSatisfied,
            _FILE,
            "Oracle not ready yet"
        );
    }

    function getPrice(
        address _token
    )
    public
    view
    returns (IDolomiteStructs.MonetaryPrice memory) {
        Require.that(
            _token == address(DPT_GLP),
            _FILE,
            "invalid token",
            _token
        );
        Require.that(
            DOLOMITE_MARGIN.getMarketIsClosing(DOLOMITE_MARGIN.getMarketIdByTokenAddress(_token)),
            _FILE,
            "ptGLP cannot be borrowable"
        );

        return IDolomiteStructs.MonetaryPrice({
            value: _getCurrentPrice()
        });
    }

    // ============================ Internal Functions ============================

    function _getCurrentPrice() internal view returns (uint256) {
        uint256 glpPrice = DOLOMITE_MARGIN.getMarketPrice(DFS_GLP_MARKET_ID).value;
        uint256 ptExchangeRate = REGISTRY.ptOracle().getPtToAssetRate(address(REGISTRY.ptGlpMarket()), TWAP_DURATION);
        return glpPrice * ptExchangeRate / PT_ASSET_SCALE;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteRegistry } from "@dolomite-exchange/modules-base/contracts/interfaces/IDolomiteRegistry.sol";
import { IsolationModeTokenVaultV1 } from "@dolomite-exchange/modules-base/contracts/isolation-mode/abstract/IsolationModeTokenVaultV1.sol"; // solhint-disable-line max-line-length
import { IsolationModeTokenVaultV1WithPausable } from "@dolomite-exchange/modules-base/contracts/isolation-mode/abstract/IsolationModeTokenVaultV1WithPausable.sol"; // solhint-disable-line max-line-length
import { IPendlePtIsolationModeTokenVaultV1 } from "./interfaces/IPendlePtIsolationModeTokenVaultV1.sol";
import { IPendlePtIsolationModeVaultFactory } from "./interfaces/IPendlePtIsolationModeVaultFactory.sol";
import { IPendleRegistry } from "./interfaces/IPendleRegistry.sol";


/**
 * @title   PendlePtIsolationModeTokenVaultV1
 * @author  Dolomite
 *
 * @notice  Implementation (for an upgradeable proxy) for a per-user vault that holds the pt (Jun 2025 expiration)
 *          token that can be used to credit a user's Dolomite balance.
 */
contract PendlePtIsolationModeTokenVaultV1 is
    IPendlePtIsolationModeTokenVaultV1,
    IsolationModeTokenVaultV1WithPausable
{

    // ==================================================================
    // =========================== Constants ============================
    // ==================================================================

    bytes32 private constant _FILE = "PendlePtUserVaultV1";

    // ==================================================================
    // ======================== Public Functions ========================
    // ==================================================================

    function registry() public view returns (IPendleRegistry) {
        return IPendlePtIsolationModeVaultFactory(VAULT_FACTORY()).pendleRegistry();
    }

    function dolomiteRegistry()
        public
        override
        view
        returns (IDolomiteRegistry)
    {
        return registry().dolomiteRegistry();
    }

    function isExternalRedemptionPaused() public override view returns (bool) {
        return registry().syToken().paused();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IsolationModeUnwrapperTraderV2 } from "@dolomite-exchange/modules-base/contracts/isolation-mode/abstract/IsolationModeUnwrapperTraderV2.sol"; // solhint-disable-line max-line-length
import { Require } from "@dolomite-exchange/modules-base/contracts/protocol/lib/Require.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IPendlePtToken } from "./interfaces/IPendlePtToken.sol";
import { IPendleRegistry } from "./interfaces/IPendleRegistry.sol";
import { IPendleRouter } from "./interfaces/IPendleRouter.sol";


/**
 * @title   PendlePtIsolationModeUnwrapperTraderV2
 * @author  Dolomite
 *
 * @notice  Used for unwrapping pt (via swapping against the Pendle AMM)
 */
contract PendlePtIsolationModeUnwrapperTraderV2 is IsolationModeUnwrapperTraderV2 {
    using SafeERC20 for IERC20;
    using SafeERC20 for IPendlePtToken;

    // ============ Constants ============

    bytes32 private constant _FILE = "PendlePtUnwrapperV2";

    // ============ State Variables ============

    IPendleRegistry public immutable PENDLE_REGISTRY; // solhint-disable-line var-name-mixedcase
    IERC20 public immutable UNDERLYING_TOKEN; // solhint-disable-line var-name-mixedcase

    // ============ Constructor ============

    constructor(
        address _pendleRegistry,
        address _underlyingToken,
        address _dptToken,
        address _dolomiteMargin
    )
    IsolationModeUnwrapperTraderV2(
        _dptToken,
        _dolomiteMargin,
        address(IPendleRegistry(_pendleRegistry).dolomiteRegistry())
    ) {
        PENDLE_REGISTRY = IPendleRegistry(_pendleRegistry);
        UNDERLYING_TOKEN = IERC20(_underlyingToken);
    }

    // ============================================
    // ============= Public Functions =============
    // ============================================

    function isValidOutputToken(address _outputToken) public override view returns (bool) {
        return _outputToken == address(UNDERLYING_TOKEN);
    }

    // ============================================
    // =========== Internal Functions =============
    // ============================================

    function _exchangeUnderlyingTokenToOutputToken(
        address,
        address,
        address,
        uint256,
        address,
        uint256 _inputAmount,
        bytes memory _extraOrderData
    )
        internal
        override
        returns (uint256)
    {
        (
            IPendleRouter.TokenOutput memory tokenOutput
        ) = abi.decode(_extraOrderData, (IPendleRouter.TokenOutput));

        // redeem pt for underlying
        IPendleRouter pendleRouter = PENDLE_REGISTRY.pendleRouter();
        IERC20(VAULT_FACTORY.UNDERLYING_TOKEN()).safeApprove(address(pendleRouter), _inputAmount);
        (uint256 outputAmount,) = pendleRouter.swapExactPtForToken(
            /* _receiver */ address(this),
            address(PENDLE_REGISTRY.ptMarket()),
            _inputAmount,
            tokenOutput
        );

        return outputAmount;
    }

    function _getExchangeCost(
        address,
        address,
        uint256,
        bytes memory
    )
    internal
    override
    pure
    returns (uint256) {
        revert(string(abi.encodePacked(Require.stringifyTruncated(_FILE), ": getExchangeCost is not implemented")));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IsolationModeUnwrapperTraderV2 } from "@dolomite-exchange/modules-base/contracts/isolation-mode/abstract/IsolationModeUnwrapperTraderV2.sol"; // solhint-disable-line max-line-length
import { Require } from "@dolomite-exchange/modules-base/contracts/protocol/lib/Require.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IPendlePtMarket } from "./interfaces/IPendlePtMarket.sol";
import { IPendlePtToken } from "./interfaces/IPendlePtToken.sol";
import { IPendleRegistry } from "./interfaces/IPendleRegistry.sol";
import { IPendleRouterV3 } from "./interfaces/IPendleRouterV3.sol";


/**
 * @title   PendlePtIsolationModeUnwrapperTraderV3
 * @author  Dolomite
 *
 * @notice  Used for unwrapping pt (via swapping against the Pendle AMM)
 */
contract PendlePtIsolationModeUnwrapperTraderV3 is IsolationModeUnwrapperTraderV2 {
    using SafeERC20 for IERC20;
    using SafeERC20 for IPendlePtToken;

    // ============ Constants ============

    bytes32 private constant _FILE = "PendlePtUnwrapperV3";

    // ============ State Variables ============

    IPendleRegistry public immutable PENDLE_REGISTRY; // solhint-disable-line var-name-mixedcase
    IERC20 public immutable UNDERLYING_TOKEN; // solhint-disable-line var-name-mixedcase

    // ============ Constructor ============

    constructor(
        address _pendleRegistry,
        address _underlyingToken,
        address _dptToken,
        address _dolomiteMargin
    )
    IsolationModeUnwrapperTraderV2(
        _dptToken,
        _dolomiteMargin,
        address(IPendleRegistry(_pendleRegistry).dolomiteRegistry())
    ) {
        PENDLE_REGISTRY = IPendleRegistry(_pendleRegistry);
        UNDERLYING_TOKEN = IERC20(_underlyingToken);
    }

    // ============================================
    // ============= Public Functions =============
    // ============================================

    function isValidOutputToken(address _outputToken) public override view returns (bool) {
        return _outputToken == address(UNDERLYING_TOKEN);
    }

    // ============================================
    // =========== Internal Functions =============
    // ============================================

    function _exchangeUnderlyingTokenToOutputToken(
        address /* _tradeOriginator */,
        address /* _receiver */,
        address /* _outputToken */,
        uint256 /* _minOutputAmount */,
        address /* _inputToken */,
        uint256 _inputAmount,
        bytes memory _extraOrderData
    )
        internal
        override
        returns (uint256)
    {
        // redeem pt for underlying
        IPendleRouterV3 pendleRouter = IPendleRouterV3(address(PENDLE_REGISTRY.pendleRouter()));
        IERC20(VAULT_FACTORY.UNDERLYING_TOKEN()).safeApprove(address(pendleRouter), _inputAmount);

        uint256 outputAmount;
        IPendlePtMarket market = PENDLE_REGISTRY.ptMarket();
        if (!market.isExpired()) {
            (
                IPendleRouterV3.TokenOutput memory tokenOutput,
                IPendleRouterV3.LimitOrderData memory limitOrderData
            ) = abi.decode(_extraOrderData, (IPendleRouterV3.TokenOutput, IPendleRouterV3.LimitOrderData));
            (outputAmount,,) = pendleRouter.swapExactPtForToken(
                /* _receiver */ address(this),
                address(market),
                _inputAmount,
                tokenOutput,
                limitOrderData
            );
        } else {
            (IPendleRouterV3.TokenOutput memory tokenOutput) =
                                abi.decode(_extraOrderData, (IPendleRouterV3.TokenOutput));
            (,, address yt) = market.readTokens();
            outputAmount = pendleRouter.redeemPyToToken(
                /* _receiver */ address(this),
                yt,
                _inputAmount,
                tokenOutput
            );
        }

        return outputAmount;
    }

    function _getExchangeCost(
        address,
        address,
        uint256,
        bytes memory
    )
    internal
    override
    pure
    returns (uint256) {
        revert(string(abi.encodePacked(Require.stringifyTruncated(_FILE), ": getExchangeCost is not implemented")));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IsolationModeVaultFactory } from "@dolomite-exchange/modules-base/contracts/isolation-mode/abstract/IsolationModeVaultFactory.sol"; // solhint-disable-line max-line-length
import { IPendlePtIsolationModeVaultFactory } from "./interfaces/IPendlePtIsolationModeVaultFactory.sol";
import { IPendleRegistry } from "./interfaces/IPendleRegistry.sol";


/**
 * @title   PendlePtIsolationModeVaultFactory
 * @author  Dolomite
 *
 * @notice  The wrapper around the PT token that is used to create user vaults and manage the entry points that a
 *          user can use to interact with DolomiteMargin from the vault.
 */
contract PendlePtIsolationModeVaultFactory is
    IPendlePtIsolationModeVaultFactory,
    IsolationModeVaultFactory
{
    // ============ Constants ============

    bytes32 private constant _FILE = "PendlePtVaultFactory"; // needed to be shortened to fit into 32 bytes

    // ============ Field Variables ============

    IPendleRegistry public override pendleRegistry;

    // ============ Constructor ============

    constructor(
        address _pendleRegistry,
        address _ptToken, // this serves as the underlying token
        address _borrowPositionProxy,
        address _userVaultImplementation,
        address _dolomiteMargin
    )
    IsolationModeVaultFactory(
        _ptToken,
        _borrowPositionProxy,
        _userVaultImplementation,
        _dolomiteMargin
    ) {
        pendleRegistry = IPendleRegistry(_pendleRegistry);
    }

    // ============ External Functions ============

    function ownerSetPendleRegistry(
        address _pendleRegistry
    )
    external
    override
    onlyDolomiteMarginOwner(msg.sender) {
        pendleRegistry = IPendleRegistry(_pendleRegistry);
        emit PendleRegistrySet(_pendleRegistry);
    }

    function allowableDebtMarketIds() external pure returns (uint256[] memory) {
        // allow all markets
        return new uint256[](0);
    }

    function allowableCollateralMarketIds() external pure returns (uint256[] memory) {
        // allow all markets
        return new uint256[](0);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IsolationModeWrapperTraderV2 } from "@dolomite-exchange/modules-base/contracts/isolation-mode/abstract/IsolationModeWrapperTraderV2.sol"; // solhint-disable-line max-line-length
import { Require } from "@dolomite-exchange/modules-base/contracts/protocol/lib/Require.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IPendleRegistry } from "./interfaces/IPendleRegistry.sol";
import { IPendleRouter } from "./interfaces/IPendleRouter.sol";


/**
 * @title   PendlePtIsolationModeWrapperTraderV2
 * @author  Dolomite
 *
 * @notice  Used for wrapping pt (via swapping against the Pendle AMM)
 */
contract PendlePtIsolationModeWrapperTraderV2 is IsolationModeWrapperTraderV2 {
    using SafeERC20 for IERC20;

    // ============ Constants ============

    bytes32 private constant _FILE = "PendlePtWrapperV2";

    // ============ State Variables ============

    IPendleRegistry public immutable PENDLE_REGISTRY; // solhint-disable-line var-name-mixedcase
    IERC20 public immutable UNDERLYING_TOKEN; // solhint-disable-line var-name-mixedcase

    // ============ Constructor ============

    constructor(
        address _pendleRegistry,
        address _underlyingToken,
        address _dptToken,
        address _dolomiteMargin
    )
    IsolationModeWrapperTraderV2(
        _dptToken,
        _dolomiteMargin,
        address(IPendleRegistry(_pendleRegistry).dolomiteRegistry())
    ) {
        PENDLE_REGISTRY = IPendleRegistry(_pendleRegistry);
        UNDERLYING_TOKEN = IERC20(_underlyingToken);
    }

    // ============================================
    // ============= Public Functions =============
    // ============================================

    function isValidInputToken(address _inputToken) public override view returns (bool) {
        return _inputToken == address(UNDERLYING_TOKEN);
    }

    // ============================================
    // ============ Internal Functions ============
    // ============================================

    function _exchangeIntoUnderlyingToken(
        address,
        address,
        address,
        uint256 _minOutputAmount,
        address,
        uint256 _inputAmount,
        bytes memory _extraOrderData
    )
        internal
        override
        returns (uint256)
    {
        (
            IPendleRouter.ApproxParams memory guessPtOut,
            IPendleRouter.TokenInput memory tokenInput
        ) = abi.decode(_extraOrderData, (IPendleRouter.ApproxParams, IPendleRouter.TokenInput));

        tokenInput.netTokenIn = _inputAmount;

        IPendleRouter pendleRouter = PENDLE_REGISTRY.pendleRouter();
        UNDERLYING_TOKEN.safeApprove(address(pendleRouter), _inputAmount);
        (uint256 ptAmount,) = pendleRouter.swapExactTokenForPt(
            /* _receiver = */ address(this),
            address(PENDLE_REGISTRY.ptMarket()),
            _minOutputAmount,
            guessPtOut,
            tokenInput
        );

        return ptAmount;
    }

    function _getExchangeCost(
        address,
        address,
        uint256,
        bytes memory
    )
    internal
    override
    pure
    returns (uint256)
    {
        revert(string(abi.encodePacked(Require.stringifyTruncated(_FILE), ": getExchangeCost is not implemented")));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IsolationModeWrapperTraderV2 } from "@dolomite-exchange/modules-base/contracts/isolation-mode/abstract/IsolationModeWrapperTraderV2.sol"; // solhint-disable-line max-line-length
import { Require } from "@dolomite-exchange/modules-base/contracts/protocol/lib/Require.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IPendleRegistry } from "./interfaces/IPendleRegistry.sol";
import { IPendleRouterV3 } from "./interfaces/IPendleRouterV3.sol";


/**
 * @title   PendlePtIsolationModeWrapperTraderV3
 * @author  Dolomite
 *
 * @notice  Used for wrapping pt (via swapping against the Pendle AMM)
 */
contract PendlePtIsolationModeWrapperTraderV3 is IsolationModeWrapperTraderV2 {
    using SafeERC20 for IERC20;

    // ============ Constants ============

    bytes32 private constant _FILE = "PendlePtWrapperV3";

    // ============ State Variables ============

    IPendleRegistry public immutable PENDLE_REGISTRY; // solhint-disable-line var-name-mixedcase
    IERC20 public immutable UNDERLYING_TOKEN; // solhint-disable-line var-name-mixedcase

    // ============ Constructor ============

    constructor(
        address _pendleRegistry,
        address _underlyingToken,
        address _dptToken,
        address _dolomiteMargin
    )
    IsolationModeWrapperTraderV2(
        _dptToken,
        _dolomiteMargin,
        address(IPendleRegistry(_pendleRegistry).dolomiteRegistry())
    ) {
        PENDLE_REGISTRY = IPendleRegistry(_pendleRegistry);
        UNDERLYING_TOKEN = IERC20(_underlyingToken);
    }

    // ============================================
    // ============= Public Functions =============
    // ============================================

    function isValidInputToken(address _inputToken) public override view returns (bool) {
        return _inputToken == address(UNDERLYING_TOKEN);
    }

    // ============================================
    // ============ Internal Functions ============
    // ============================================

    function _exchangeIntoUnderlyingToken(
        address /* _tradeOriginator */,
        address /* _receiver */,
        address /* _outputTokenUnderlying */,
        uint256 _minOutputAmount,
        address /* _inputToken */,
        uint256 _inputAmount,
        bytes memory _extraOrderData
    )
        internal
        override
        returns (uint256)
    {
        (
            IPendleRouterV3.ApproxParams memory guessPtOut,
            IPendleRouterV3.TokenInput memory tokenInput,
            IPendleRouterV3.LimitOrderData memory limit
        ) = abi.decode(
            _extraOrderData,
            (IPendleRouterV3.ApproxParams, IPendleRouterV3.TokenInput, IPendleRouterV3.LimitOrderData)
        );

        tokenInput.netTokenIn = _inputAmount;

        IPendleRouterV3 pendleRouter = IPendleRouterV3(address(PENDLE_REGISTRY.pendleRouter()));
        UNDERLYING_TOKEN.safeApprove(address(pendleRouter), _inputAmount);
        (uint256 ptAmount,,) = pendleRouter.swapExactTokenForPt(
            /* _receiver = */ address(this),
            address(PENDLE_REGISTRY.ptMarket()),
            _minOutputAmount,
            guessPtOut,
            tokenInput,
            limit
        );

        return ptAmount;
    }

    function _getExchangeCost(
        address,
        address,
        uint256,
        bytes memory
    )
    internal
    override
    pure
    returns (uint256)
    {
        revert(string(abi.encodePacked(Require.stringifyTruncated(_FILE), ": getExchangeCost is not implemented")));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { OnlyDolomiteMargin } from "@dolomite-exchange/modules-base/contracts/helpers/OnlyDolomiteMargin.sol";
import { IDolomiteStructs } from "@dolomite-exchange/modules-base/contracts/protocol/interfaces/IDolomiteStructs.sol";
import { Require } from "@dolomite-exchange/modules-base/contracts/protocol/lib/Require.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IPendlePtPriceOracle } from "./interfaces/IPendlePtPriceOracle.sol";
import { IPendleRegistry } from "./interfaces/IPendleRegistry.sol";


/**
 * @title   PendlePtPriceOracle
 * @author  Dolomite
 *
 * @notice  An implementation of the IPendlePtPriceOracle interface that gets Pendle's pt price in USD terms.
 */
contract PendlePtPriceOracle is IPendlePtPriceOracle, OnlyDolomiteMargin {

    // ============================ Constants ============================

    bytes32 private constant _FILE = "PendlePtPriceOracle";
    uint32 public constant TWAP_DURATION = 900; // 15 minutes
    uint256 public constant DEDUCTION_COEFFICIENT_BASE = 1e18;

    // ============================ Public State Variables ============================

    address immutable public DPT_TOKEN; // solhint-disable-line var-name-mixedcase
    IPendleRegistry immutable public REGISTRY; // solhint-disable-line var-name-mixedcase
    address immutable public UNDERLYING_TOKEN; // solhint-disable-line var-name-mixedcase
    uint256 immutable public PT_ASSET_SCALE; // solhint-disable-line var-name-mixedcase
    uint256 public deductionCoefficient;

    // ============================ Constructor ============================

    constructor(
        address _dptToken,
        address _pendleRegistry,
        address _underlyingToken,
        address _dolomiteMargin
    ) OnlyDolomiteMargin(_dolomiteMargin) {
        DPT_TOKEN = _dptToken;
        REGISTRY = IPendleRegistry(_pendleRegistry);
        UNDERLYING_TOKEN = _underlyingToken;
        PT_ASSET_SCALE = uint256(10) ** uint256(IERC20Metadata(DPT_TOKEN).decimals());
        _ownerSetDeductionCoefficient(0);

        (
            bool increaseCardinalityRequired,,
            bool oldestObservationSatisfied
        ) = REGISTRY.ptOracle().getOracleState(address(REGISTRY.ptMarket()), TWAP_DURATION);

        Require.that(
            !increaseCardinalityRequired && oldestObservationSatisfied,
            _FILE,
            "Oracle not ready yet"
        );
    }

    function ownerSetDeductionCoefficient(uint256 _deductionCoefficient) external onlyDolomiteMarginOwner(msg.sender) {
        _ownerSetDeductionCoefficient(_deductionCoefficient);
    }

    function getPrice(
        address _token
    )
    public
    view
    returns (IDolomiteStructs.MonetaryPrice memory) {
        Require.that(
            _token == address(DPT_TOKEN),
            _FILE,
            "invalid token",
            _token
        );
        Require.that(
            DOLOMITE_MARGIN().getMarketIsClosing(DOLOMITE_MARGIN().getMarketIdByTokenAddress(_token)),
            _FILE,
            "PT cannot be borrowable"
        );

        return IDolomiteStructs.MonetaryPrice({
            value: _getCurrentPrice()
        });
    }

    // ============================ Internal Functions ============================

    function _applyDeductionCoefficient(uint256 _price) internal view returns (uint256) {
        return _price * (DEDUCTION_COEFFICIENT_BASE - deductionCoefficient) / DEDUCTION_COEFFICIENT_BASE;
    }

    function _ownerSetDeductionCoefficient(uint256 _deductionCoefficient) internal {
        deductionCoefficient = _deductionCoefficient;
        emit DeductionCoefficientSet(_deductionCoefficient);
    }

    function _getCurrentPrice() internal view virtual returns (uint256) {
        uint256 underlyingPrice = REGISTRY.dolomiteRegistry().chainlinkPriceOracle().getPrice(UNDERLYING_TOKEN).value;
        underlyingPrice = _applyDeductionCoefficient(underlyingPrice);

        uint256 ptExchangeRate = REGISTRY.ptOracle().getPtToAssetRate(address(REGISTRY.ptMarket()), TWAP_DURATION);
        return underlyingPrice * ptExchangeRate / PT_ASSET_SCALE;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { OnlyDolomiteMargin } from "@dolomite-exchange/modules-base/contracts/helpers/OnlyDolomiteMargin.sol";
import { IDolomiteStructs } from "@dolomite-exchange/modules-base/contracts/protocol/interfaces/IDolomiteStructs.sol";
import { Require } from "@dolomite-exchange/modules-base/contracts/protocol/lib/Require.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IPendlePtPriceOracle } from "./interfaces/IPendlePtPriceOracle.sol";
import { IPendleRegistry } from "./interfaces/IPendleRegistry.sol";


/**
 * @title   PendlePtPriceOracleV2
 * @author  Dolomite
 *
 * @notice  An implementation of the IPendlePtPriceOracle interface that gets Pendle's pt price in USD terms.
 */
contract PendlePtPriceOracleV2 is IPendlePtPriceOracle, OnlyDolomiteMargin {

    // ============================ Constants ============================

    bytes32 private constant _FILE = "PendlePtPriceOracle";
    uint32 public constant TWAP_DURATION = 900; // 15 minutes
    uint256 public constant DEDUCTION_COEFFICIENT_BASE = 1e18;

    // ============================ Public State Variables ============================

    address immutable public DPT_TOKEN; // solhint-disable-line var-name-mixedcase
    IPendleRegistry immutable public REGISTRY; // solhint-disable-line var-name-mixedcase
    uint256 immutable public PT_ASSET_SCALE; // solhint-disable-line var-name-mixedcase
    uint256 public deductionCoefficient;

    // ============================ Constructor ============================

    constructor(
        address _dptToken,
        address _pendleRegistry,
        address _dolomiteMargin
    ) OnlyDolomiteMargin(_dolomiteMargin) {
        DPT_TOKEN = _dptToken;
        REGISTRY = IPendleRegistry(_pendleRegistry);
        PT_ASSET_SCALE = uint256(10) ** uint256(IERC20Metadata(DPT_TOKEN).decimals());
        _ownerSetDeductionCoefficient(0);

        (
            bool increaseCardinalityRequired,,
            bool oldestObservationSatisfied
        ) = REGISTRY.ptOracle().getOracleState(address(REGISTRY.ptMarket()), TWAP_DURATION);

        Require.that(
            !increaseCardinalityRequired && oldestObservationSatisfied,
            _FILE,
            "Oracle not ready yet"
        );
    }

    function ownerSetDeductionCoefficient(uint256 _deductionCoefficient) external onlyDolomiteMarginOwner(msg.sender) {
        _ownerSetDeductionCoefficient(_deductionCoefficient);
    }

    function getPrice(
        address _token
    )
    public
    view
    returns (IDolomiteStructs.MonetaryPrice memory) {
        Require.that(
            _token == address(DPT_TOKEN),
            _FILE,
            "invalid token",
            _token
        );
        Require.that(
            DOLOMITE_MARGIN().getMarketIsClosing(DOLOMITE_MARGIN().getMarketIdByTokenAddress(_token)),
            _FILE,
            "PT cannot be borrowable"
        );

        return IDolomiteStructs.MonetaryPrice({
            value: _getCurrentPrice()
        });
    }

    function getDecimalsByToken(address _token) external view returns (uint8) {
        return IERC20Metadata(_token).decimals();
    }

    // ============================ Internal Functions ============================

    function _ownerSetDeductionCoefficient(uint256 _deductionCoefficient) internal {
        deductionCoefficient = _deductionCoefficient;
        emit DeductionCoefficientSet(_deductionCoefficient);
    }

    function _getCurrentPrice() internal view virtual returns (uint256) {
        uint256 ptExchangeRate = REGISTRY.ptOracle().getPtToAssetRate(address(REGISTRY.ptMarket()), TWAP_DURATION);
        return _applyDeductionCoefficient(ptExchangeRate);
    }

    function _applyDeductionCoefficient(uint256 _price) internal view returns (uint256) {
        return _price - (_price * deductionCoefficient / DEDUCTION_COEFFICIENT_BASE);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomitePriceOracle } from "@dolomite-exchange/modules-base/contracts/protocol/interfaces/IDolomitePriceOracle.sol"; // solhint-disable-line max-line-length
import { PendlePtPriceOracle } from "./PendlePtPriceOracle.sol";


/**
 * @title   PendlePtRsEthPriceOracle
 * @author  Dolomite
 *
 * @notice  An implementation of the IDolomitePriceOracle interface that gets Pendle's pt price in USD terms.
 */
contract PendlePtRsEthPriceOracle is PendlePtPriceOracle {

    // ============================ Constants ============================

    bytes32 private constant _FILE = "PendlePtRsEthPriceOracle";

    // ============================ Constructor ============================

    constructor(
        address _dptToken,
        address _pendleRegistry,
        address _underlyingToken,
        address _dolomiteMargin
    ) PendlePtPriceOracle(_dptToken, _pendleRegistry, _underlyingToken, _dolomiteMargin) {}

    // ============================ Internal Functions ============================

    function _getCurrentPrice() internal view override returns (uint256) {
        uint256 underlyingPrice = DOLOMITE_MARGIN().getMarketPrice(
            DOLOMITE_MARGIN().getMarketIdByTokenAddress(UNDERLYING_TOKEN)
        ).value;
        uint256 ptExchangeRate = REGISTRY.ptOracle().getPtToAssetRate(address(REGISTRY.ptMarket()), TWAP_DURATION);
        return _applyDeductionCoefficient(underlyingPrice * ptExchangeRate / PT_ASSET_SCALE);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { BaseRegistry } from "@dolomite-exchange/modules-base/contracts/general/BaseRegistry.sol";
import { Require } from "@dolomite-exchange/modules-base/contracts/protocol/lib/Require.sol";
import { IPendlePtMarket } from "./interfaces/IPendlePtMarket.sol";
import { IPendlePtOracle } from "./interfaces/IPendlePtOracle.sol";
import { IPendleRegistry } from "./interfaces/IPendleRegistry.sol";
import { IPendleRouter } from "./interfaces/IPendleRouter.sol";
import { IPendleSyToken } from "./interfaces/IPendleSyToken.sol";


/**
 * @title   PendleRegistry
 * @author  Dolomite
 *
 * @notice  Implementation for a registry that contains all of the Pendle-related addresses. This registry is needed
 *          to offer uniform access to addresses in an effort to keep Dolomite's contracts as up-to-date as possible
 *          without having to deprecate the system and force users to migrate when Dolomite needs to point to new
 *          contracts or functions that Pendle introduces.
 */
contract PendleRegistry is IPendleRegistry, BaseRegistry {

    // ==================== Constants ====================

    bytes32 private constant _FILE = "PendleRegistry";

    bytes32 private constant _PENDLE_ROUTER_SLOT = bytes32(uint256(keccak256("eip1967.proxy.pendleRouter")) - 1);
    bytes32 private constant _PENDLE_PT_MARKET_SLOT = bytes32(uint256(keccak256("eip1967.proxy.ptMarket")) - 1);
    bytes32 private constant _PENDLE_PT_ORACLE_SLOT = bytes32(uint256(keccak256("eip1967.proxy.ptOracle")) - 1);
    bytes32 private constant _PENDLE_SY_TOKEN_SLOT = bytes32(uint256(keccak256("eip1967.proxy.syToken")) - 1);

    // ==================== Initializer ====================

    function initialize(
        address _pendleRouter,
        address _ptMarket,
        address _ptOracle,
        address _syToken,
        address _dolomiteRegistry
    ) external initializer {
        _ownerSetPendleRouter(_pendleRouter);
        _ownerSetPtMarket(_ptMarket);
        _ownerSetPtOracle(_ptOracle);
        _ownerSetSyToken(_syToken);
        _ownerSetDolomiteRegistry(_dolomiteRegistry);
    }

    // ==================== Functions ====================

    function ownerSetPendleRouter(
        address _pendleRouter
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        _ownerSetPendleRouter(_pendleRouter);
    }

    function ownerSetPtMarket(
        address _ptMarket
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        _ownerSetPtMarket(_ptMarket);
    }

    function ownerSetPtOracle(
        address _ptOracle
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        _ownerSetPtOracle(_ptOracle);
    }

    function ownerSetSyToken(
        address _syToken
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        _ownerSetSyToken(_syToken);
    }

    // ==================== Views ====================

    function pendleRouter() external view returns (IPendleRouter) {
        return IPendleRouter(_getAddress(_PENDLE_ROUTER_SLOT));
    }

    function ptMarket() external view returns (IPendlePtMarket) {
        return IPendlePtMarket(_getAddress(_PENDLE_PT_MARKET_SLOT));
    }

    function ptOracle() external view returns (IPendlePtOracle) {
        return IPendlePtOracle(_getAddress(_PENDLE_PT_ORACLE_SLOT));
    }

    function syToken() external view returns (IPendleSyToken) {
        return IPendleSyToken(_getAddress(_PENDLE_SY_TOKEN_SLOT));
    }

    // ============================================================
    // ==================== Internal Functions ====================
    // ============================================================

    function _ownerSetPendleRouter(address _pendleRouter) internal {
        Require.that(
            _pendleRouter != address(0),
            _FILE,
            "Invalid pendleRouter address"
        );
        _setAddress(_PENDLE_ROUTER_SLOT, _pendleRouter);
        emit PendleRouterSet(_pendleRouter);
    }

    function _ownerSetPtMarket(address _ptMarket) internal {
        Require.that(
            _ptMarket != address(0),
            _FILE,
            "Invalid ptMarket address"
        );
        _setAddress(_PENDLE_PT_MARKET_SLOT, _ptMarket);
        emit PtMarketSet(_ptMarket);
    }

    function _ownerSetPtOracle(address _ptOracle) internal {
        Require.that(
            _ptOracle != address(0),
            _FILE,
            "Invalid ptOracle address"
        );
        _setAddress(_PENDLE_PT_ORACLE_SLOT, _ptOracle);
        emit PtOracleSet(_ptOracle);
    }

    function _ownerSetSyToken(address _syToken) internal {
        Require.that(
            _syToken != address(0),
            _FILE,
            "Invalid syToken address"
        );
        _setAddress(_PENDLE_SY_TOKEN_SLOT, _syToken);
        emit SyTokenSet(_syToken);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteRegistry } from "@dolomite-exchange/modules-base/contracts/interfaces/IDolomiteRegistry.sol";
import { IExpiry } from "@dolomite-exchange/modules-base/contracts/interfaces/IExpiry.sol";
import { IsolationModeTokenVaultV1 } from "@dolomite-exchange/modules-base/contracts/isolation-mode/abstract/IsolationModeTokenVaultV1.sol"; // solhint-disable-line max-line-length
import { IsolationModeTokenVaultV1WithPausable } from "@dolomite-exchange/modules-base/contracts/isolation-mode/abstract/IsolationModeTokenVaultV1WithPausable.sol"; // solhint-disable-line max-line-length
import { IIsolationModeVaultFactory } from "@dolomite-exchange/modules-base/contracts/isolation-mode/interfaces/IIsolationModeVaultFactory.sol"; // solhint-disable-line max-line-length
import { AccountActionLib } from "@dolomite-exchange/modules-base/contracts/lib/AccountActionLib.sol";
import { AccountBalanceLib } from "@dolomite-exchange/modules-base/contracts/lib/AccountBalanceLib.sol";
import { IDolomiteMargin } from "@dolomite-exchange/modules-base/contracts/protocol/interfaces/IDolomiteMargin.sol";
import { IDolomiteStructs } from "@dolomite-exchange/modules-base/contracts/protocol/interfaces/IDolomiteStructs.sol";
import { Require } from "@dolomite-exchange/modules-base/contracts/protocol/lib/Require.sol";
import { TypesLib } from "@dolomite-exchange/modules-base/contracts/protocol/lib/TypesLib.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IPendleGLPRegistry } from "./interfaces/IPendleGLPRegistry.sol";
import { IPendleYtGLP2024IsolationModeTokenVaultV1 } from "./interfaces/IPendleYtGLP2024IsolationModeTokenVaultV1.sol";
import { IPendleYtGLP2024IsolationModeVaultFactory } from "./interfaces/IPendleYtGLP2024IsolationModeVaultFactory.sol";
import { IPendleYtToken } from "./interfaces/IPendleYtToken.sol";


/**
 * @title   PendleYtGLP2024IsolationModeTokenVaultV1
 * @author  Dolomite
 *
 * @notice  Implementation (for an upgradeable proxy) for a per-user vault that holds the ytGLP (March 2024 expiration)
 *          token that can be used to credit a user's Dolomite balance.
 */
contract PendleYtGLP2024IsolationModeTokenVaultV1 is
    IPendleYtGLP2024IsolationModeTokenVaultV1,
    IsolationModeTokenVaultV1WithPausable
{
    using SafeERC20 for IERC20;
    using TypesLib for IDolomiteMargin.Wei;

    // ==================================================================
    // =========================== Constants ============================
    // ==================================================================

    bytes32 private constant _FILE = "PendleYtGLP2024UserVaultV1";
    uint256 private constant _ONE_WEEK = 1 weeks;
    uint256 private constant _SAFETY_BUFFER_SECONDS = 5 minutes;

    // ==================================================================
    // ======================== Public Functions ========================
    // ==================================================================

    function redeemDueInterestAndRewards(
        bool _redeemInterest,
        bool _redeemRewards,
        bool[] memory _depositRewardsIntoDolomite,
        bool _depositInterestIntoDolomite
    )
        external
        nonReentrant
        onlyVaultOwner(msg.sender)
    {
        _redeemDueInterestAndRewards(
            _redeemInterest,
            _redeemRewards,
            _depositRewardsIntoDolomite,
            _depositInterestIntoDolomite
        );
    }

    function registry() public view returns (IPendleGLPRegistry) {
        return IPendleYtGLP2024IsolationModeVaultFactory(VAULT_FACTORY()).pendleGLPRegistry();
    }

    function dolomiteRegistry()
        public
        override
        view
        returns (IDolomiteRegistry)
    {
        return registry().dolomiteRegistry();
    }

    function isExternalRedemptionPaused() public view override returns (bool) {
        return IPendleYtGLP2024IsolationModeVaultFactory(VAULT_FACTORY()).pendleGLPRegistry().syGlpToken().paused();
    }

    // ==================================================================
    // ======================== Internal Functions ========================
    // ==================================================================

    function _redeemDueInterestAndRewards(
        bool _redeemInterest,
        bool _redeemRewards,
        bool[] memory _depositRewardsIntoDolomite,
        bool _depositInterestIntoDolomite
    ) internal {
        address underlyingToken = UNDERLYING_TOKEN();
        address[] memory rewardTokens = IPendleYtToken(underlyingToken).getRewardTokens();
        address interestToken = IPendleYtToken(underlyingToken).SY();
        uint256 rewardTokenLength = rewardTokens.length;

        Require.that(
            _depositRewardsIntoDolomite.length == rewardTokenLength,
            _FILE,
            "Array length mismatch"
        );

        (
            uint256 interestAmount,
            uint256[] memory rewardAmounts
        ) = IPendleYtToken(underlyingToken).redeemDueInterestAndRewards(
            address(this),
            _redeemInterest,
            _redeemRewards
        );

        for (uint256 i; i < rewardTokenLength; ++i) {
            assert(rewardTokens[i] != underlyingToken);
            _depositOtherTokenIntoDolomiteMarginForVaultOwnerOrTransferOut(
                /* _toAccountNumber = */ 0,
                rewardTokens[i],
                rewardAmounts[i],
                _depositRewardsIntoDolomite[i]
            );
        }

        assert(interestToken != underlyingToken);
        _depositOtherTokenIntoDolomiteMarginForVaultOwnerOrTransferOut(
            /* _toAccountNumber = */ 0,
            interestToken,
            interestAmount,
            _depositInterestIntoDolomite
        );
    }

    function _depositOtherTokenIntoDolomiteMarginForVaultOwnerOrTransferOut(
        uint256 _toAccountNumber,
        address _token,
        uint256 _amountWei,
        bool _depositIntoDolomite
    ) internal {
        if (_depositIntoDolomite) {
            IDolomiteMargin dolomiteMargin = DOLOMITE_MARGIN();
            IERC20(_token).safeApprove(address(dolomiteMargin), _amountWei);
            uint256 marketId = dolomiteMargin.getMarketIdByTokenAddress(_token);
            IIsolationModeVaultFactory(VAULT_FACTORY()).depositOtherTokenIntoDolomiteMarginForVaultOwner(
                _toAccountNumber,
                marketId,
                _amountWei
            );
        } else {
            IERC20(_token).safeTransfer(msg.sender, _amountWei);
        }
    }

    function _openBorrowPosition(
        uint256 _fromAccountNumber,
        uint256 _toAccountNumber,
        uint256 _amountWei
    )
        internal
        override
    {
        uint256 ytMaturityTimestamp = IPendleYtGLP2024IsolationModeVaultFactory(VAULT_FACTORY()).ytMaturityTimestamp();
        Require.that(
            block.timestamp + _ONE_WEEK < ytMaturityTimestamp,
            _FILE,
            "Too close to expiry"
        );

        super._openBorrowPosition(_fromAccountNumber, _toAccountNumber, _amountWei);
    }

    function _swapExactInputForOutput(
        SwapExactInputForOutputParams memory _params
    )
        internal
        override
    {
        IPendleYtGLP2024IsolationModeVaultFactory vaultFactory = IPendleYtGLP2024IsolationModeVaultFactory(
            VAULT_FACTORY()
        );
        IDolomiteStructs.AccountInfo memory accountInfo = IDolomiteStructs.AccountInfo(
            address(this),
            _params.tradeAccountNumber
        );
        IDolomiteStructs.Wei memory balanceAfterWei = _getBalanceAfterWei(
            accountInfo,
            _params.marketIdsPath[0],
            _params.inputAmountWei,
            vaultFactory
        );

        // check if balanceAfterWei is negative and it is within 1 week of expiry. If so, revert
        uint256 ytMaturityTimestamp = vaultFactory.ytMaturityTimestamp();
        Require.that(
            block.timestamp + _ONE_WEEK < ytMaturityTimestamp
                || balanceAfterWei.isPositive()
                || balanceAfterWei.isZero(),
            _FILE,
            "Too close to expiry"
        );

        super._swapExactInputForOutput(
            _params
        );

        // if account balance is negative, set expiry
        if (balanceAfterWei.isNegative()) {
            _setExpirationForBorrowPosition(accountInfo, _params.marketIdsPath[0], ytMaturityTimestamp, vaultFactory);
        }
    }


    function _transferFromPositionWithOtherToken(
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber,
        uint256 _marketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) internal override {
        IPendleYtGLP2024IsolationModeVaultFactory vaultFactory = IPendleYtGLP2024IsolationModeVaultFactory(
            VAULT_FACTORY()
        );
        IDolomiteStructs.AccountInfo memory accountInfo = IDolomiteStructs.AccountInfo(
            address(this),
            _borrowAccountNumber
        );
        IDolomiteStructs.Wei memory balanceAfterWei = _getBalanceAfterWei(
            accountInfo,
            _marketId,
            _amountWei,
            vaultFactory
        );

        // check if balanceAfterWei is negative and it is within 1 week of expiry. If so, revert
        uint256 ytMaturityTimestamp = vaultFactory.ytMaturityTimestamp();
        Require.that(
            block.timestamp + _ONE_WEEK < ytMaturityTimestamp
                || balanceAfterWei.isPositive()
                || balanceAfterWei.isZero(),
            _FILE,
            "Too close to expiry"
        );

        super._transferFromPositionWithOtherToken(
            _borrowAccountNumber,
            _toAccountNumber,
            _marketId,
            _amountWei,
            _balanceCheckFlag
        );

        // if account balance is negative, set expiry
        if (balanceAfterWei.isNegative()) {
            _setExpirationForBorrowPosition(accountInfo, _marketId, ytMaturityTimestamp, vaultFactory);
        }
    }

    function _setExpirationForBorrowPosition(
        IDolomiteStructs.AccountInfo memory _accountInfo,
        uint256 _marketId,
        uint256 _ytMaturityTimestamp,
        IPendleYtGLP2024IsolationModeVaultFactory vaultFactory
    ) internal {
        IExpiry expiry = vaultFactory.pendleGLPRegistry().dolomiteRegistry().expiry();

        uint256 expirationTimestamp = _getExistingExpirationTimestampFromAccount(_accountInfo, expiry);
        Require.that(
            expirationTimestamp == 0 || expirationTimestamp > _SAFETY_BUFFER_SECONDS + block.timestamp,
            _FILE,
            "Position is about to expire"
        );
        if (expiry.getExpiry(_accountInfo, _marketId) != 0) {
            // Expiration already exists, return
            return;
        }

        uint256 expiryTimeDelta;
        if (expirationTimestamp == 0) {
            // If an expiry doesn't exist, use the min of 4 weeks or the time until 1-week before YT's expiration
            expiryTimeDelta = Math.min(4 * _ONE_WEEK, _ytMaturityTimestamp - _ONE_WEEK - block.timestamp);
        } else {
            expiryTimeDelta = expirationTimestamp - block.timestamp;
        }

        IDolomiteStructs.AccountInfo[] memory accounts = new IDolomiteStructs.AccountInfo[](1);
        accounts[0] = _accountInfo;

        IDolomiteStructs.ActionArgs[] memory actions = new IDolomiteStructs.ActionArgs[](1);
        actions[0] = AccountActionLib.encodeExpirationAction(
            accounts[0],
            /* _accountId = */ 0,
            _marketId,
            address(expiry),
            expiryTimeDelta
        );

        vaultFactory.DOLOMITE_MARGIN().operate(accounts, actions);
    }

    /**
     * @notice  Returns the expiration timestamp for any existing borrow position on the vault
     *
     * @param  _accountInfo The account whose expirations will be checked
     * @param  _expiry      The Expiry contract to check for expirations on the account
     * @return              The expiration timestamp for this borrow account if one exists, else returns 0
     */
    function _getExistingExpirationTimestampFromAccount(
        IDolomiteStructs.AccountInfo memory _accountInfo,
        IExpiry _expiry
    ) internal view returns (uint256) {
        IPendleYtGLP2024IsolationModeVaultFactory vaultFactory = IPendleYtGLP2024IsolationModeVaultFactory(
            VAULT_FACTORY()
        );

        uint256[] memory allowableDebtMarketIds = vaultFactory.allowableDebtMarketIds();
        uint256 allowableDebtMarketIdsLength = allowableDebtMarketIds.length;

        // Loop through all allowable debt markets checking for an expiry
        for (uint256 i = 0; i < allowableDebtMarketIdsLength; ++i) {
            uint256 existingExpiry = _expiry.getExpiry(_accountInfo, allowableDebtMarketIds[i]);
            if (existingExpiry != 0) {
                return existingExpiry;
            }
        }

        return 0;
    }

    function _getBalanceAfterWei(
        IDolomiteStructs.AccountInfo memory _accountInfo,
        uint256 _marketId,
        uint256 _inputAmountWei,
        IPendleYtGLP2024IsolationModeVaultFactory vaultFactory
    ) internal view returns (IDolomiteStructs.Wei memory balanceAfterWei) {
        IDolomiteStructs.Wei memory balanceBeforeWei = vaultFactory.DOLOMITE_MARGIN().getAccountWei(
            _accountInfo,
            _marketId
        );
        IDolomiteStructs.Wei memory deltaWei = IDolomiteStructs.Wei({
            sign: false,
            value: _inputAmountWei
        });
        balanceAfterWei = balanceBeforeWei.add(deltaWei);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IsolationModeUnwrapperTraderV2 } from "@dolomite-exchange/modules-base/contracts/isolation-mode/abstract/IsolationModeUnwrapperTraderV2.sol"; // solhint-disable-line max-line-length
import { Require } from "@dolomite-exchange/modules-base/contracts/protocol/lib/Require.sol";
import { IGmxRegistryV1 } from "@dolomite-exchange/modules-glp/contracts/interfaces/IGmxRegistryV1.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IPendleGLPRegistry } from "./interfaces/IPendleGLPRegistry.sol";
import { IPendleRouter } from "./interfaces/IPendleRouter.sol";
import { IPendleYtToken } from "./interfaces/IPendleYtToken.sol";


/**
 * @title   PendleYtGLP2024IsolationModeUnwrapperTraderV2
 * @author  Dolomite
 *
 * @notice  Used for unwrapping ytGLP (via swapping against the Pendle AMM then redeeming the underlying GLP to
 *          USDC).
 */
contract PendleYtGLP2024IsolationModeUnwrapperTraderV2 is IsolationModeUnwrapperTraderV2 {
    using SafeERC20 for IERC20;
    using SafeERC20 for IPendleYtToken;

    // ============ Constants ============

    bytes32 private constant _FILE = "PendleYtGLP2024UnwrapperV2";

    // ============ Constructor ============

    IPendleGLPRegistry public immutable PENDLE_REGISTRY; // solhint-disable-line var-name-mixedcase
    IGmxRegistryV1 public immutable GMX_REGISTRY; // solhint-disable-line var-name-mixedcase

    // ============ Constructor ============

    constructor(
        address _pendleRegistry,
        address _gmxRegistry,
        address _dytGlp,
        address _dolomiteMargin
    )
    IsolationModeUnwrapperTraderV2(
        _dytGlp,
        _dolomiteMargin,
        address(IGmxRegistryV1(_gmxRegistry).dolomiteRegistry())
    ) {
        PENDLE_REGISTRY = IPendleGLPRegistry(_pendleRegistry);
        GMX_REGISTRY = IGmxRegistryV1(_gmxRegistry);
    }

    // ============================================
    // ============= Public Functions =============
    // ============================================

    function isValidOutputToken(address _outputToken) public view override returns (bool) {
        return GMX_REGISTRY.gmxVault().whitelistedTokens(_outputToken);
    }

    // ============================================
    // =========== Internal Functions =============
    // ============================================

    function _exchangeUnderlyingTokenToOutputToken(
        address,
        address,
        address _outputToken,
        uint256 _minOutputAmount,
        address,
        uint256 _inputAmount,
        bytes memory _extraOrderData
    )
        internal
        override
        returns (uint256)
    {
        (
            IPendleRouter.TokenOutput memory tokenOutput
        ) = abi.decode(_extraOrderData, (IPendleRouter.TokenOutput));

        // redeem ytGLP for GLP
        IPendleRouter pendleRouter = PENDLE_REGISTRY.pendleRouter();
        PENDLE_REGISTRY.ytGlpToken().safeApprove(address(pendleRouter), _inputAmount);
        (uint256 glpAmount, ) = pendleRouter.swapExactYtForToken(
            /* _receiver */ address(this),
            address(PENDLE_REGISTRY.ptGlpMarket()),
            _inputAmount,
            tokenOutput
        );

        // redeem GLP for `_outputToken`; we don't need to approve sGLP because there is a handler that auto-approves
        // for this
        uint256 amountOut = GMX_REGISTRY.glpRewardsRouter().unstakeAndRedeemGlp(
            /* _tokenOut = */ _outputToken,
            glpAmount,
            _minOutputAmount,
            /* _receiver = */ address(this)
        );

        return amountOut;
    }

    function _getExchangeCost(
        address,
        address,
        uint256,
        bytes memory
    )
    internal
    override
    pure
    returns (uint256) {
        revert(string(abi.encodePacked(Require.stringifyTruncated(_FILE), ": getExchangeCost is not implemented")));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { SimpleIsolationModeVaultFactory } from "@dolomite-exchange/modules-base/contracts/isolation-mode/SimpleIsolationModeVaultFactory.sol"; // solhint-disable-line max-line-length
import { Require } from "@dolomite-exchange/modules-base/contracts/protocol/lib/Require.sol";
import { IPendleGLPRegistry } from "./interfaces/IPendleGLPRegistry.sol";
import { IPendleYtGLP2024IsolationModeVaultFactory } from "./interfaces/IPendleYtGLP2024IsolationModeVaultFactory.sol";
import { IPendleYtToken } from "./interfaces/IPendleYtToken.sol";



/**
 * @title   PendleYtGLP2024IsolationModeVaultFactory
 * @author  Dolomite
 *
 * @notice  The wrapper around the ytGLP token that is used to create user vaults and manage the entry points that a
 *          user can use to interact with DolomiteMargin from the vault.
 */
contract PendleYtGLP2024IsolationModeVaultFactory is
    IPendleYtGLP2024IsolationModeVaultFactory,
    SimpleIsolationModeVaultFactory
{
    // ============ Constants ============

    bytes32 private constant _FILE = "PendleYtGLP2024VaultFactory"; // needed to be shortened to fit into 32 bytes

    // ============ Field Variables ============

    address public immutable override WETH; // solhint-disable-line var-name-mixedcase
    uint256 public immutable override WETH_MARKET_ID; // solhint-disable-line var-name-mixedcase
    IPendleGLPRegistry public override pendleGLPRegistry;
    uint256 public override ytMaturityTimestamp;

    // ============ Constructor ============

    constructor(
        address _weth,
        uint256 _wethMarketId,
        address _pendleGLPRegistry,
        uint256[] memory _initialAllowableDebtMarketIds,
        uint256[] memory _initialAllowableCollateralMarketIds,
        address _ytGlp, // this serves as the underlying token
        address _borrowPositionProxyV2,
        address _userVaultImplementation,
        address _dolomiteMargin
    )
    SimpleIsolationModeVaultFactory(
        _initialAllowableDebtMarketIds,
        _initialAllowableCollateralMarketIds,
        _ytGlp,
        _borrowPositionProxyV2,
        _userVaultImplementation,
        _dolomiteMargin
    ) {
        WETH = _weth;
        WETH_MARKET_ID = _wethMarketId;
        pendleGLPRegistry = IPendleGLPRegistry(_pendleGLPRegistry);
        ytMaturityTimestamp = IPendleYtToken(UNDERLYING_TOKEN).expiry();
    }

    // ================================================
    // ============ External Functions ============
    // ================================================

    function ownerSetPendleGLPRegistry(
        address _pendleGLPRegistry
    )
    external
    override
    onlyDolomiteMarginOwner(msg.sender) {
        pendleGLPRegistry = IPendleGLPRegistry(_pendleGLPRegistry);
        emit PendleGLPRegistrySet(_pendleGLPRegistry);
    }

    function ownerSetYtMaturityTimestamp(
        uint256 _ytMaturityTimestamp
    )
    external
    override
    onlyDolomiteMarginOwner(msg.sender) {
        ytMaturityTimestamp = _ytMaturityTimestamp;
        emit YtMaturityTimestampSet(_ytMaturityTimestamp);
    }

    function _ownerSetAllowableDebtMarketIds(
        uint256[] memory _newAllowableDebtMarketIds
    ) internal override {
        Require.that(
            _newAllowableDebtMarketIds.length > 0,
            _FILE,
            "Invalid allowableDebtMarketIds"
        );

        super._ownerSetAllowableDebtMarketIds(_newAllowableDebtMarketIds);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IsolationModeWrapperTraderV2 } from "@dolomite-exchange/modules-base/contracts/isolation-mode/abstract/IsolationModeWrapperTraderV2.sol"; // solhint-disable-line max-line-length
import { Require } from "@dolomite-exchange/modules-base/contracts/protocol/lib/Require.sol";
import { IGmxRegistryV1 } from "@dolomite-exchange/modules-glp/contracts/interfaces/IGmxRegistryV1.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IPendleGLPRegistry } from "./interfaces/IPendleGLPRegistry.sol";
import { IPendleRouter } from "./interfaces/IPendleRouter.sol";


/**
 * @title   PendleYtGLP2024IsolationModeWrapperTraderV2
 * @author  Dolomite
 *
 * @notice  Used for wrapping ytGLP (via swapping against the Pendle AMM then redeeming the underlying GLP to
 *          USDC).
 */
contract PendleYtGLP2024IsolationModeWrapperTraderV2 is IsolationModeWrapperTraderV2 {
    using SafeERC20 for IERC20;

    // ============ Constants ============

    bytes32 private constant _FILE = "PendleYtGLP2024WrapperV2";

    // ============ Constructor ============

    IPendleGLPRegistry public immutable PENDLE_REGISTRY; // solhint-disable-line var-name-mixedcase
    IGmxRegistryV1 public immutable GMX_REGISTRY; // solhint-disable-line var-name-mixedcase

    // ============ Constructor ============

    constructor(
        address _pendleRegistry,
        address _gmxRegistry,
        address _dytGlp,
        address _dolomiteMargin
    )
    IsolationModeWrapperTraderV2(
        _dytGlp,
        _dolomiteMargin,
        address(IPendleGLPRegistry(_pendleRegistry).dolomiteRegistry())
    ) {
        PENDLE_REGISTRY = IPendleGLPRegistry(_pendleRegistry);
        GMX_REGISTRY = IGmxRegistryV1(_gmxRegistry);
    }

    // ============================================
    // ============= Public Functions =============
    // ============================================

    function isValidInputToken(address _inputToken) public view override returns (bool) {
        return GMX_REGISTRY.gmxVault().whitelistedTokens(_inputToken);
    }

    // ============================================
    // ============ Internal Functions ============
    // ============================================

    function _exchangeIntoUnderlyingToken(
        address,
        address,
        address,
        uint256 _minOutputAmount,
        address _inputToken,
        uint256 _inputAmount,
        bytes memory _extraOrderData
    )
        internal
        override
        returns (uint256)
    {
        (
            IPendleRouter.ApproxParams memory guessYtOut,
            IPendleRouter.TokenInput memory tokenInput
        ) = abi.decode(_extraOrderData, (IPendleRouter.ApproxParams, IPendleRouter.TokenInput));

        // approve input token and mint GLP
        IERC20(_inputToken).safeApprove(address(GMX_REGISTRY.glpManager()), _inputAmount);
        uint256 glpAmount = GMX_REGISTRY.glpRewardsRouter().mintAndStakeGlp(
            _inputToken,
            _inputAmount,
            /* _minUsdg = */ 0,
            /* _minGlp = */ 0
        );
        tokenInput.netTokenIn = glpAmount;

        uint256 ytGlpAmount;
        {
            // Create a new scope to avoid stack too deep errors
            // approve GLP and swap for ptGLP
            IPendleRouter pendleRouter = PENDLE_REGISTRY.pendleRouter();
            IERC20(GMX_REGISTRY.sGlp()).safeApprove(address(pendleRouter), glpAmount);
            (ytGlpAmount, ) = pendleRouter.swapExactTokenForYt(
                /* _receiver = */ address(this),
                address(PENDLE_REGISTRY.ptGlpMarket()),
                _minOutputAmount,
                guessYtOut,
                tokenInput
            );
        }

        return ytGlpAmount;
    }

    function _getExchangeCost(
        address,
        address,
        uint256,
        bytes memory
    )
    internal
    override
    pure
    returns (uint256)
    {
        revert(string(abi.encodePacked(Require.stringifyTruncated(_FILE), ": getExchangeCost is not implemented")));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteMargin } from "@dolomite-exchange/modules-base/contracts/protocol/interfaces/IDolomiteMargin.sol";
import { IDolomitePriceOracle } from "@dolomite-exchange/modules-base/contracts/protocol/interfaces/IDolomitePriceOracle.sol"; // solhint-disable-line max-line-length
import { IDolomiteStructs } from "@dolomite-exchange/modules-base/contracts/protocol/interfaces/IDolomiteStructs.sol";
import { Require } from "@dolomite-exchange/modules-base/contracts/protocol/lib/Require.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IPendleGLPRegistry } from "./interfaces/IPendleGLPRegistry.sol";


/**
 * @title   PendleYtGLPPriceOracle
 * @author  Dolomite
 *
 * @notice  An implementation of the IDolomitePriceOracle interface that gets Pendle's ytGLP price in USD terms.
 */
contract PendleYtGLPPriceOracle is IDolomitePriceOracle {

    // ============================ Constants ============================

    bytes32 private constant _FILE = "PendleYtGLPPriceOracle";
    uint32 public constant TWAP_DURATION = 900; // 15 minutes
    uint256 public constant FEE_PRECISION = 10_000;

    // ============================ Public State Variables ============================

    address public immutable DYT_GLP; // solhint-disable-line var-name-mixedcase
    IPendleGLPRegistry public immutable REGISTRY; // solhint-disable-line var-name-mixedcase
    IDolomiteMargin public immutable DOLOMITE_MARGIN; // solhint-disable-line var-name-mixedcase
    uint256 public immutable PT_ASSET_SCALE; // solhint-disable-line var-name-mixedcase
    uint256 public immutable DFS_GLP_MARKET_ID; // solhint-disable-line var-name-mixedcase

    // ============================ Constructor ============================

    constructor(
        address _dytGlp,
        address _pendleGLPRegistry,
        address _dolomiteMargin,
        uint256 _dfsGlpMarketId
    ) {
        DYT_GLP = _dytGlp;
        REGISTRY = IPendleGLPRegistry(_pendleGLPRegistry);
        DOLOMITE_MARGIN = IDolomiteMargin(_dolomiteMargin);
        DFS_GLP_MARKET_ID = _dfsGlpMarketId;
        PT_ASSET_SCALE = 10 ** uint256(IERC20Metadata(DYT_GLP).decimals());

        (
            bool increaseCardinalityRequired,,
            bool oldestObservationSatisfied
        ) = REGISTRY.ptOracle().getOracleState(address(REGISTRY.ptGlpMarket()), TWAP_DURATION);

        Require.that(
            !increaseCardinalityRequired && oldestObservationSatisfied,
            _FILE,
            "Oracle not ready yet"
        );
    }

    function getPrice(
        address _token
    )
    public
    view
    returns (IDolomiteStructs.MonetaryPrice memory) {
        Require.that(
            _token == address(DYT_GLP),
            _FILE,
            "Invalid token",
            _token
        );
        Require.that(
            DOLOMITE_MARGIN.getMarketIsClosing(DOLOMITE_MARGIN.getMarketIdByTokenAddress(_token)),
            _FILE,
            "ytGLP cannot be borrowable"
        );

        // disallow the number to be `0` since it will cause DolomiteMargin to throw an error
        return IDolomiteStructs.MonetaryPrice({
            value: Math.max(_getCurrentPrice(), 1)
        });
    }

    // ============================ Internal Functions ============================

    function _getCurrentPrice() internal view returns (uint256) {
        uint256 glpPrice = DOLOMITE_MARGIN.getMarketPrice(DFS_GLP_MARKET_ID).value;
        uint256 ptExchangeRate = REGISTRY.ptOracle().getPtToAssetRate(address(REGISTRY.ptGlpMarket()), TWAP_DURATION);
        return glpPrice * (PT_ASSET_SCALE - ptExchangeRate) / PT_ASSET_SCALE;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteTransformer } from "@dolomite-exchange/modules-base/contracts/interfaces/IDolomiteTransformer.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IPendleGLPRegistry } from "./interfaces/IPendleGLPRegistry.sol";
import { IPendleRouter } from "./interfaces/IPendleRouter.sol";


/**
 * @title   PtGLPTransformer
 * @author  Dolomite
 *
 * @notice  Contract for PtGLP transformer implementation
 */
contract PtGLPTransformer is IDolomiteTransformer {
    using SafeERC20 for IERC20;

    IPendleGLPRegistry public immutable PENDLE_REGISTRY; // solhint-disable-line var-name-mixedcase
    address public immutable inputToken;
    address public immutable outputToken;

    constructor(address _pendleRegistry, address _outputToken) {
        PENDLE_REGISTRY = IPendleGLPRegistry(_pendleRegistry);
        inputToken = address(PENDLE_REGISTRY.ptGlpToken());
        outputToken = _outputToken;
    }
    
    function transform(uint256 _inputAmount, bytes calldata /* extraData */) external returns (uint256) {
        IPendleRouter.SwapData memory swapData = IPendleRouter.SwapData({
            swapType: IPendleRouter.SwapType.NONE,
            extRouter: address(0),
            extCalldata: bytes(''),
            needScale: false
        });
        IPendleRouter.TokenOutput memory tokenOutput = IPendleRouter.TokenOutput({
            tokenOut: outputToken,
            minTokenOut: _inputAmount,
            tokenRedeemSy: outputToken,
            bulk: address(0),
            pendleSwap: address(0),
            swapData: swapData
        });

        IPendleRouter pendleRouter = PENDLE_REGISTRY.pendleRouter();
        IERC20(inputToken).safeApprove(address(pendleRouter), _inputAmount);
        uint256 glpAmount = pendleRouter.redeemPyToToken(
            /* _receiver */ address(this),
            address(PENDLE_REGISTRY.ytGlpToken()),
            _inputAmount,
            tokenOutput
        );

        assert(glpAmount == _inputAmount);
        return glpAmount;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { PendlePtPriceOracle } from "../PendlePtPriceOracle.sol";


/**
 * @title   TestPendlePtPriceOracle
 * @author  Dolomite
 *
 * @notice  Test contract for PendlePtPriceOracle
 */
contract TestPendlePtPriceOracle is PendlePtPriceOracle {
    
    constructor(
        address _dptToken,
        address _pendleRegistry,
        address _underlyingToken,
        address _dolomiteMargin
    ) PendlePtPriceOracle(_dptToken, _pendleRegistry, _underlyingToken, _dolomiteMargin) {}

    function testApplyDeductionCoefficient(uint256 _price) external view returns (uint256) {
        return _applyDeductionCoefficient(_price);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { PendleYtGLP2024IsolationModeTokenVaultV1 } from "../PendleYtGLP2024IsolationModeTokenVaultV1.sol"; // solhint-disable-line max-line-length


/**
 * @title   TestPendleYtGLP2024IsolationModeTokenVaultV1
 * @author  Dolomite
 *
 * @notice  Test implementation for exposing areas for coverage testing
 */
contract TestPendleYtGLP2024IsolationModeTokenVaultV1 is PendleYtGLP2024IsolationModeTokenVaultV1 {

    bytes32 private constant _FILE = "TestPendleYtGLP2024UserVaultV1";

    function callRedeemDueInterestAndRewardsTriggerReentrancy(
        bool _redeemInterest,
        bool _redeemRewards,
        bool[] memory _depositRewardsIntoDolomite,
        bool _depositInterestIntoDolomite
    ) external nonReentrant {
        // solhint-disable-next-line avoid-low-level-calls
        (bool isSuccessful, bytes memory result) = address(this).delegatecall(
            abi.encodeWithSignature(
                "redeemDueInterestAndRewards(bool,bool,bool[],bool)",
                _redeemInterest,
                _redeemRewards,
                _depositRewardsIntoDolomite,
                _depositInterestIntoDolomite
            )
        );
        if (!isSuccessful) {
            if (result.length < 68) {
                revert("No reversion message!");
            } else {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    result := add(result, 0x04) // Slice the sighash.
                }
            }
            (string memory errorMessage) = abi.decode(result, (string));
            revert(errorMessage);
        }
    }
}