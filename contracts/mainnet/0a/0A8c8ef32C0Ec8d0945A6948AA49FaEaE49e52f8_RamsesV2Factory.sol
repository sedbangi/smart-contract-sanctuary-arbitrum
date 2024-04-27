// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Proxy.sol";
import "../utils/Address.sol";
import "./IBeacon.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from a {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy {
    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 private constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializating the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) public payable {
        assert(_BEACON_SLOT == bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1));
        _setBeacon(beacon, data);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address beacon) {
        bytes32 slot = _BEACON_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            beacon := sload(slot)
        }
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_beacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        require(
            Address.isContract(beacon),
            "BeaconProxy: beacon is not a contract"
        );
        require(
            Address.isContract(IBeacon(beacon).implementation()),
            "BeaconProxy: beacon implementation is not a contract"
        );
        bytes32 slot = _BEACON_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, beacon)
        }

        if (data.length > 0) {
            Address.functionDelegateCall(_implementation(), data, "BeaconProxy: function call failed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6 || ^0.8.13;
pragma abicoder v2;

interface IVoter {
    function _ve() external view returns (address);

    function governor() external view returns (address);

    function emergencyCouncil() external view returns (address);

    function attachTokenToGauge(uint256 _tokenId, address account) external;

    function detachTokenFromGauge(uint256 _tokenId, address account) external;

    function emitDeposit(
        uint256 _tokenId,
        address account,
        uint256 amount
    ) external;

    function emitWithdraw(
        uint256 _tokenId,
        address account,
        uint256 amount
    ) external;

    function isWhitelisted(address token) external view returns (bool);

    function notifyRewardAmount(uint256 amount) external;

    function distribute(address _gauge) external;

    function gauges(address pool) external view returns (address gauge);

    function feeDistributers(
        address gauge
    ) external view returns (address feeDistributor);

    function gaugefactory() external view returns (address);

    function feeDistributorFactory() external view returns (address);

    function minter() external view returns (address);

    function factory() external view returns (address);

    function length() external view returns (uint256);

    function pools(uint256) external view returns (address);

    function isAlive(address) external view returns (bool);

    function stale(uint256 tokenId) external view returns (bool);

    function partnerNFT(uint256 tokenId) external view returns (bool);

    function setXRamRatio(uint256 _xRamRatio) external;

    function setGaugeXRamRatio(
        address[] calldata _gauges,
        uint256[] calldata _xRamRatios
    ) external;

    function resetGaugeXRamRatio(address[] calldata _gauges) external;

    function whitelist(address _token) external;

    function forbid(address _token, bool _status) external;

    function killGauge(address _gauge) external;

    function reviveGauge(address _gauge) external;

    function whitelistOperator() external view returns (address);

    function gaugeXRamRatio(address gauge) external view returns (uint256);

    function clawBackUnusedEmissions(address[] calldata _gauges) external;

    function resetVotes(uint256[] calldata tokenIds) external;

    function syncLegacyGaugeRewards(address[] calldata _gauges) external;

    function whitelistGaugeRewards(
        address[] calldata _gauges,
        address[] calldata _rewards
    ) external;

    function removeGaugeRewards(
        address[] calldata _gauges,
        address[] calldata _rewards
    ) external;

    function base() external view returns (address ram);

    function xRamAddress() external view returns (address _xRamAddress);

    function addClGaugeReward(address gauge, address reward) external;

    function removeClGaugeReward(address gauge, address reward) external;

    function designateStale(uint256 _tokenId, bool _status) external;

    function customGaugeForPool(
        address pool
    ) external view returns (address customGauge);

    function designatePartnerNFT(uint256 _tokenId, bool _status) external;

    function isGauge(address gauge) external view returns (bool _isGauge);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6 || ^0.8.13;
pragma abicoder v2;

interface IVotingEscrow {
    struct Point {
        int128 bias;
        int128 slope; // # -dweight / dt
        uint256 ts;
        uint256 blk; // block
    }

    struct LockedBalance {
        int128 amount;
        uint256 end;
    }

    function token() external view returns (address);

    function team() external returns (address);

    function epoch() external view returns (uint256);

    function point_history(uint256 loc) external view returns (Point memory);

    function user_point_history(
        uint256 tokenId,
        uint256 loc
    ) external view returns (Point memory);

    function user_point_epoch(uint256 tokenId) external view returns (uint256);

    function ownerOf(uint256) external view returns (address);

    function isApprovedOrOwner(address, uint256) external view returns (bool);

    function transferFrom(address, address, uint256) external;

    function voting(uint256 tokenId) external;

    function abstain(uint256 tokenId) external;

    function attach(uint256 tokenId) external;

    function detach(uint256 tokenId) external;

    function checkpoint() external;

    function deposit_for(uint256 tokenId, uint256 value) external;

    function create_lock_for(
        uint256,
        uint256,
        address
    ) external returns (uint256);

    function balanceOfNFT(uint256) external view returns (uint256);

    function balanceOfNFTAt(uint256, uint256) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function locked__end(uint256) external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function tokenOfOwnerByIndex(
        address,
        uint256
    ) external view returns (uint256);

    function locked(uint256) external view returns (LockedBalance memory);

    function isDelegate(
        address _operator,
        uint256 _tokenId
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "@openzeppelin-3.4.1/contracts/proxy/BeaconProxy.sol";

contract RamsesBeaconProxy is BeaconProxy {
    // Doing so the CREATE2 hash is easier to calculate
    constructor() payable BeaconProxy(msg.sender, "") {}
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.8.0;

import './../../v2/libraries/FullMath.sol';
import './../../v2/libraries/FixedPoint96.sol';

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                uint256(liquidity) << FixedPoint96.RESOLUTION,
                sqrtRatioBX96 - sqrtRatioAX96,
                sqrtRatioBX96
            ) / sqrtRatioAX96;
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IRamsesV2PoolActions#flash
/// @notice Any contract that calls IRamsesV2PoolActions#flash must implement this interface
interface IRamsesV2FlashCallback {
    /// @notice Called to `msg.sender` after transferring to the recipient from IRamsesV2Pool#flash.
    /// @dev In the implementation you must repay the pool the tokens sent by flash plus the computed fee amounts.
    /// The caller of this method must be checked to be a RamsesV2Pool deployed by the canonical RamsesV2Factory.
    /// @param fee0 The fee amount in token0 due to the pool by the end of the flash
    /// @param fee1 The fee amount in token1 due to the pool by the end of the flash
    /// @param data Any data passed through by the caller via the IRamsesV2PoolActions#flash call
    function ramsesV2FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IRamsesV2PoolActions#mint
/// @notice Any contract that calls IRamsesV2PoolActions#mint must implement this interface
interface IRamsesV2MintCallback {
    /// @notice Called to `msg.sender` after minting liquidity to a position from IRamsesV2Pool#mint.
    /// @dev In the implementation you must pay the pool tokens owed for the minted liquidity.
    /// The caller of this method must be checked to be a RamsesV2Pool deployed by the canonical RamsesV2Factory.
    /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
    /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
    /// @param data Any data passed through by the caller via the IRamsesV2PoolActions#mint call
    function ramsesV2MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IRamsesV2PoolActions#swap
/// @notice Any contract that calls IRamsesV2PoolActions#swap must implement this interface
interface IRamsesV2SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IRamsesV2Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a RamsesV2Pool deployed by the canonical RamsesV2Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IRamsesV2PoolActions#swap call
    function ramsesV2SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Minimal ERC20 interface for Ramses
/// @notice Contains a subset of the full ERC20 interface that is used in Ramses V2
interface IERC20Minimal {
    /// @notice Returns the balance of a token
    /// @param account The account for which to look up the number of tokens it has, i.e. its balance
    /// @return The number of tokens held by the account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfers the amount of token from the `msg.sender` to the recipient
    /// @param recipient The account that will receive the amount transferred
    /// @param amount The number of tokens to send from the sender to the recipient
    /// @return Returns true for a successful transfer, false for an unsuccessful transfer
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Returns the current allowance given to a spender by an owner
    /// @param owner The account of the token owner
    /// @param spender The account of the token spender
    /// @return The current allowance granted by `owner` to `spender`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets the allowance of a spender from the `msg.sender` to the value `amount`
    /// @param spender The account which will be allowed to spend a given amount of the owners tokens
    /// @param amount The amount of tokens allowed to be used by `spender`
    /// @return Returns true for a successful approval, false for unsuccessful
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers `amount` tokens from `sender` to `recipient` up to the allowance given to the `msg.sender`
    /// @param sender The account from which the transfer will be initiated
    /// @param recipient The recipient of the transfer
    /// @param amount The amount of the transfer
    /// @return Returns true for a successful transfer, false for unsuccessful
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// @notice Event emitted when tokens are transferred from one address to another, either via `#transfer` or `#transferFrom`.
    /// @param from The account from which the tokens were sent, i.e. the balance decreased
    /// @param to The account to which the tokens were sent, i.e. the balance increased
    /// @param value The amount of tokens that were transferred
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Event emitted when the approval amount for the spender of a given owner's tokens changes.
    /// @param owner The account that approved spending of its tokens
    /// @param spender The account for which the spending allowance was modified
    /// @param value The new allowance from the owner to the spender
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Ramses V2 Factory
/// @notice The Ramses V2 Factory facilitates creation of Ramses V2 pools and control over the protocol fees
interface IRamsesV2Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Emitted when pairs implementation is changed
    /// @param oldImplementation The previous implementation
    /// @param newImplementation The new implementation
    event ImplementationChanged(
        address indexed oldImplementation,
        address indexed newImplementation
    );

    /// @notice Emitted when the fee collector is changed
    /// @param oldFeeCollector The previous implementation
    /// @param newFeeCollector The new implementation
    event FeeCollectorChanged(
        address indexed oldFeeCollector,
        address indexed newFeeCollector
    );

    /// @notice Emitted when the protocol fee is changed
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(
        uint8 feeProtocol0Old,
        uint8 feeProtocol1Old,
        uint8 feeProtocol0New,
        uint8 feeProtocol1New
    );

    /// @notice Emitted when the protocol fee is changed
    /// @param pool The pool address
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetPoolFeeProtocol(
        address pool,
        uint8 feeProtocol0Old,
        uint8 feeProtocol1Old,
        uint8 feeProtocol0New,
        uint8 feeProtocol1New
    );

    /// @notice Emitted when the feeSetter of the factory is changed
    /// @param oldSetter The feeSetter before the setter was changed
    /// @param newSetter The feeSetter after the setter was changed
    event FeeSetterChanged(
        address indexed oldSetter,
        address indexed newSetter
    );

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the RamsesV2 NFP Manager
    function nfpManager() external view returns (address);

    /// @notice Returns the Ramses Voting Sscrow (veRam)
    function veRam() external view returns (address);

    /// @notice Returns Ramses Voter
    function voter() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Returns the address of the fee collector contract
    /// @dev Fee collector decides where the protocol fees go (fee distributor, treasury, etc.)
    function feeCollector() external view returns (address);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;

    /// @notice returns the default protocol fee.
    function feeProtocol() external view returns (uint8);

    /// @notice returns the protocol fee for both tokens of a pool.
    function poolFeeProtocol(address pool) external view returns (uint8);

    /// @notice Sets the default protocol's % share of the fees
    /// @param feeProtocol new default protocol fee for token0 and token1
    function setFeeProtocol(uint8 feeProtocol) external;

    /// @notice Sets the default protocol's % share of the fees
    /// @param pool the pool address
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setPoolFeeProtocol(
        address pool,
        uint8 feeProtocol0,
        uint8 feeProtocol1
    ) external;

    /// @notice Sets the fee collector address
    /// @param _feeCollector the fee collector address
    function setFeeCollector(address _feeCollector) external;

    function setFee(address _pool, uint24 _fee) external;

    /// @notice Sets the default protocol's % share of the fees
    /// @param pool the pool address
    /// @param feeProtocol new protocol fee for the pool for token0 and token1
    function setPoolFeeProtocol(address pool, uint8 feeProtocol) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "./pool/IRamsesV2PoolImmutables.sol";
import "./pool/IRamsesV2PoolState.sol";
import "./pool/IRamsesV2PoolDerivedState.sol";
import "./pool/IRamsesV2PoolActions.sol";
import "./pool/IRamsesV2PoolOwnerActions.sol";
import "./pool/IRamsesV2PoolEvents.sol";

/// @title The interface for a Ramses V2 Pool
/// @notice A Ramses pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IRamsesV2Pool is
    IRamsesV2PoolImmutables,
    IRamsesV2PoolState,
    IRamsesV2PoolDerivedState,
    IRamsesV2PoolActions,
    IRamsesV2PoolOwnerActions,
    IRamsesV2PoolEvents
{
    /// @notice Initializes a pool with parameters provided
    function initialize(
        address _factory,
        address _nfpManager,
        address _veRam,
        address _voter,
        address _token0,
        address _token1,
        uint24 _fee,
        int24 _tickSpacing
    ) external;

    function _advancePeriod() external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title An interface for a contract that is capable of deploying Ramses V2 Pools
/// @notice A contract that constructs a pool must implement this to pass arguments to the pool
/// @dev The store and retrieve method of supplying constructor arguments for CREATE2 isn't needed anymore
/// since we now use a beacon pattern
interface IRamsesV2PoolDeployer {

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IRamsesV2PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position at index 0
    /// @dev The caller of this method receives a callback in the form of IRamsesV2MintCallback#ramsesV2MintCallback
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

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IRamsesV2MintCallback#ramsesV2MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param index The index for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param veRamTokenId The veRam tokenId to attach to the position
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        uint256 index,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        uint256 veRamTokenId,
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

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param index The index of the position to be collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        uint256 index,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position at index 0
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

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param index The index for which the liquidity will be burned
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        uint256 index,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param index The index for which the liquidity will be burned
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @param veRamTokenId The veRam Token Id to attach
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        uint256 index,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        uint256 veRamTokenId
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IRamsesV2SwapCallback#ramsesV2SwapCallback
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
    /// @dev The caller of this method receives a callback in the form of IRamsesV2FlashCallback#ramsesV2FlashCallback
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
    function increaseObservationCardinalityNext(
        uint16 observationCardinalityNext
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IRamsesV2PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerBoostedLiquidityPeriodX128s Cumulative seconds per boosted liquidity-in-range value as of each `secondsAgos` from the current block timestamp
    function observe(
        uint32[] calldata secondsAgos
    )
        external
        view
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulativeX128s,
            uint160[] memory secondsPerBoostedLiquidityPeriodX128s
        );

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken. Boosted data is only valid if it's within the same period
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsPerBoostedLiquidityInsideX128 The snapshot of seconds per boosted liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(
        int24 tickLower,
        int24 tickUpper
    )
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint160 secondsPerBoostedLiquidityInsideX128,
            uint32 secondsInside
        );

    /// @notice Returns the seconds per liquidity and seconds inside a tick range for a period
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsPerBoostedLiquidityInsideX128 The snapshot of seconds per boosted liquidity for the range
    function periodCumulativesInside(
        uint32 period,
        int24 tickLower,
        int24 tickUpper
    )
        external
        view
        returns (
            uint160 secondsPerLiquidityInsideX128,
            uint160 secondsPerBoostedLiquidityInsideX128
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IRamsesV2PoolEvents {
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
    event SetFeeProtocol(
        uint8 feeProtocol0Old,
        uint8 feeProtocol1Old,
        uint8 feeProtocol0New,
        uint8 feeProtocol1New
    );

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(
        address indexed sender,
        address indexed recipient,
        uint128 amount0,
        uint128 amount1
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IRamsesV2PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IRamsesV2Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The contract that manages RamsesV2 NFPs, which must adhere to the INonfungiblePositionManager interface
    /// @return The contract address
    function nfpManager() external view returns (address);

    /// @notice The contract that manages veRamses NFTs, which must adhere to the IVotinEscrow interface
    /// @return The contract address
    function veRam() external view returns (address);

    /// @notice The contract that manages Ramses votes, which must adhere to the IVoter interface
    /// @return The contract address
    function voter() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee the pool was initialized with
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

    /// @notice returns the current fee set for the pool
    function currentFee() external view returns (uint24);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IRamsesV2PoolOwnerActions {
    /// @notice Set the protocol's % share of the fees
    /// @dev Fees start at 50%, with 5% increments
    function setFeeProtocol() external;

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

    function setFee(uint24 _fee) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IRamsesV2PoolState {
    /// @notice reads arbitrary storage slots and returns the bytes
    /// @param slots The slots to read from
    /// @return returnData The data read from the slots
    function readStorage(
        bytes32[] calldata slots
    ) external view returns (bytes32[] memory returnData);

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

    /// @notice Returns the last tick of a given period
    /// @param period The period in question
    /// @return previousPeriod The period before current period
    /// @dev this is because there might be periods without trades
    ///  startTick The start tick of the period
    ///  lastTick The last tick of the period, if the period is finished
    ///  endSecondsPerLiquidityPeriodX128 Seconds per liquidity at period's end
    ///  endSecondsPerBoostedLiquidityPeriodX128 Seconds per boosted liquidity at period's end
    function periods(
        uint256 period
    )
        external
        view
        returns (
            uint32 previousPeriod,
            int24 startTick,
            int24 lastTick,
            uint160 endSecondsPerLiquidityCumulativeX128,
            uint160 endSecondsPerBoostedLiquidityCumulativeX128,
            uint32 boostedInRange
        );

    /// @notice The last period where a trade or liquidity change happened
    function lastPeriod() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees()
        external
        view
        returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice The currently in range derived liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function boostedLiquidity() external view returns (uint128);

    /// @notice Get the boost information for a specific position at a period
    /// @return boostAmount the amount of boost this position has for this period,
    /// veRamAmount the amount of veRam attached to this position for this period,
    /// secondsDebtX96 used to account for changes in the deposit amount during the period
    /// boostedSecondsDebtX96 used to account for changes in the boostAmount and veRam locked during the period,
    function boostInfos(
        uint256 period,
        bytes32 key
    )
        external
        view
        returns (
            uint128 boostAmount,
            int128 veRamAmount,
            int256 secondsDebtX96,
            int256 boostedSecondsDebtX96
        );

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
    function ticks(
        int24 tick
    )
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint128 boostedLiquidityGross,
            int128 boostedLiquidityNet,
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
    /// Returns attachedVeRamId the veRam tokenId attached to the position
    function positions(
        bytes32 key
    )
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1,
            uint256 attachedVeRamId
        );

    /// @notice Returns a period's total boost amount and total veRam attached
    /// @param period Period timestamp
    /// @return totalBoostAmount The total amount of boost this period has,
    /// Returns totalVeRamAmount The total amount of veRam attached to this period
    function boostInfos(
        uint256 period
    ) external view returns (uint128 totalBoostAmount, int128 totalVeRamAmount);

    /// @notice Get the period seconds debt of a specific position
    /// @param period the period number
    /// @param recipient recipient address
    /// @param index position index
    /// @param tickLower lower bound of range
    /// @param tickUpper upper bound of range
    /// @return secondsDebtX96 seconds the position was not in range for the period
    /// @return boostedSecondsDebtX96 boosted seconds the period
    function positionPeriodDebt(
        uint256 period,
        address recipient,
        uint256 index,
        int24 tickLower,
        int24 tickUpper
    )
        external
        view
        returns (int256 secondsDebtX96, int256 boostedSecondsDebtX96);

    /// @notice get the period seconds in range of a specific position
    /// @param period the period number
    /// @param owner owner address
    /// @param index position index
    /// @param tickLower lower bound of range
    /// @param tickUpper upper bound of range
    /// @return periodSecondsInsideX96 seconds the position was not in range for the period
    /// @return periodBoostedSecondsInsideX96 boosted seconds the period
    function positionPeriodSecondsInRange(
        uint256 period,
        address owner,
        uint256 index,
        int24 tickLower,
        int24 tickUpper
    )
        external
        view
        returns (
            uint256 periodSecondsInsideX96,
            uint256 periodBoostedSecondsInsideX96
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(
        uint256 index
    )
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized,
            uint160 secondsPerBoostedLiquidityPeriodX128
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title BitMath
/// @dev This library provides functionality for computing bit properties of an unsigned integer
library BitMath {
    /// @notice Returns the index of the most significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     x >= 2**mostSignificantBit(x) and x < 2**(mostSignificantBit(x)+1)
    /// @param x the value for which to compute the most significant bit, must be greater than 0
    /// @return r the index of the most significant bit
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0);

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }

    /// @notice Returns the index of the least significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     (x & 2**leastSignificantBit(x)) != 0 and (x & (2**(leastSignificantBit(x)) - 1)) == 0)
    /// @param x the value for which to compute the least significant bit, must be greater than 0
    /// @return r the index of the least significant bit
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0);

        r = 255;
        if (x & type(uint128).max > 0) {
            r -= 128;
        } else {
            x >>= 128;
        }
        if (x & type(uint64).max > 0) {
            r -= 64;
        } else {
            x >>= 64;
        }
        if (x & type(uint32).max > 0) {
            r -= 32;
        } else {
            x >>= 32;
        }
        if (x & type(uint16).max > 0) {
            r -= 16;
        } else {
            x >>= 16;
        }
        if (x & type(uint8).max > 0) {
            r -= 8;
        } else {
            x >>= 8;
        }
        if (x & 0xf > 0) {
            r -= 4;
        } else {
            x >>= 4;
        }
        if (x & 0x3 > 0) {
            r -= 2;
        } else {
            x >>= 2;
        }
        if (x & 0x1 > 0) r -= 1;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint128
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
library FixedPoint128 {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint32
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
library FixedPoint32 {
    uint8 internal constant RESOLUTION = 32;
    uint256 internal constant Q32 = 0x100000000;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.8.0;

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
    function mulDivRoundingUp(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
import './FullMath.sol';
import './SafeCast.sol';
import '@openzeppelin-3.4.1/contracts/math/Math.sol';

/// @title Math library for liquidity
library LiquidityMath {
    /// @notice Add a signed liquidity delta to liquidity and revert if it overflows or underflows
    /// @param x The liquidity before change
    /// @param y The delta by which liquidity should be changed
    /// @return z The liquidity delta
    function addDelta(uint128 x, int128 y) internal pure returns (uint128 z) {
        if (y < 0) {
            require((z = x - uint128(-y)) < x, 'LS');
        } else {
            require((z = x + uint128(y)) >= x, 'LA');
        }
    }

    /// @notice Add a signed liquidity delta to liquidity and revert if it overflows or underflows
    /// @param x The liquidity before change
    /// @param y The delta by which liquidity should be changed
    /// @return z The liquidity delta
    function addDelta256(uint256 x, int256 y) internal pure returns (uint256 z) {
        if (y < 0) {
            require((z = x - uint256(-y)) < x, 'LS');
        } else {
            require((z = x + uint256(y)) >= x, 'LA');
        }
    }

    function calculateBoostedLiquidity(
        uint128 liquidity,
        int128 veRamAmount,
        int128 totalVeRamAmount
    ) internal pure returns (uint256 veRamRatio, uint128 boostedLiquidity) {
        veRamRatio = FullMath.mulDiv(
            uint256(veRamAmount),
            1.5e18,
            totalVeRamAmount != 0 ? uint256(totalVeRamAmount) : 1
        );

        // users acheive full boost if their veRAM is >=10% of the total veRAM attached to the pool
        // full boost is 1x original + 1.5x boost
        //uint256 boostRatio = Math.min(veRamRatio * 10, 1.5e18); // veRamAmount and totalVeRamAmount can't go below 0
        /*
        if (veRamRatio > 1e16) {
            boostRatio = 1.5e18;
        }
        */
        uint256 boostRatio = 1.5e18;

        boostedLiquidity = SafeCast.toUint128(FullMath.mulDiv(liquidity, boostRatio, 1e18));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    /// @notice Returns x + y, reverts if overflows or underflows
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0));
    }

    /// @notice Returns x - y, reverts if overflows or underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x - y) <= x == (y >= 0));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.8.0;

import './Tick.sol';
import './States.sol';

/// @title Oracle
/// @notice Provides price and liquidity data useful for a wide variety of system designs
/// @dev Instances of stored oracle data, "observations", are collected in the oracle array
/// Every pool is initialized with an oracle array length of 1. Anyone can pay the SSTOREs to increase the
/// maximum length of the oracle array. New slots will be added when the array is fully populated.
/// Observations are overwritten when the full length of the oracle array is populated.
/// The most recent observation is available, independent of the length of the oracle array, by passing 0 to observe()
library Oracle {
    /// @notice Transforms a previous observation into a new observation, given the passage of time and the current tick and liquidity values
    /// @dev blockTimestamp _must_ be chronologically equal to or greater than last.blockTimestamp, safe for 0 or 1 overflows
    /// @param last The specified observation to be transformed
    /// @param blockTimestamp The timestamp of the new observation
    /// @param tick The active tick at the time of the new observation
    /// @param liquidity The total in-range liquidity at the time of the new observation
    /// @return Observation The newly populated observation
    function transform(
        Observation memory last,
        uint32 blockTimestamp,
        int24 tick,
        uint128 liquidity,
        uint128 boostedLiquidity
    ) internal pure returns (Observation memory) {
        uint32 delta = blockTimestamp - last.blockTimestamp;
        return
            Observation({
                blockTimestamp: blockTimestamp,
                tickCumulative: last.tickCumulative + int56(tick) * delta,
                secondsPerLiquidityCumulativeX128: last.secondsPerLiquidityCumulativeX128 +
                    ((uint160(delta) << 128) / (liquidity > 0 ? liquidity : 1)),
                secondsPerBoostedLiquidityPeriodX128: last.secondsPerBoostedLiquidityPeriodX128 +
                    ((uint160(delta) << 128) / (boostedLiquidity > 0 ? boostedLiquidity : 1)),
                initialized: true,
                boostedInRange: boostedLiquidity > 0 ? last.boostedInRange + delta : last.boostedInRange
            });
    }

    /// @notice Initialize the oracle array by writing the first slot. Called once for the lifecycle of the observations array
    /// @param self The stored oracle array
    /// @param time The time of the oracle initialization, via block.timestamp truncated to uint32
    /// @return cardinality The number of populated elements in the oracle array
    /// @return cardinalityNext The new length of the oracle array, independent of population
    function initialize(
        Observation[65535] storage self,
        uint32 time
    ) external returns (uint16 cardinality, uint16 cardinalityNext) {
        self[0] = Observation({
            blockTimestamp: time,
            tickCumulative: 0,
            secondsPerLiquidityCumulativeX128: 0,
            secondsPerBoostedLiquidityPeriodX128: 0,
            initialized: true,
            boostedInRange: 0
        });
        return (1, 1);
    }

    /// @notice Writes an oracle observation to the array
    /// @dev Writable at most once per block. Index represents the most recently written element. cardinality and index must be tracked publicly.
    /// If the index is at the end of the allowable array length (according to cardinality), and the next cardinality
    /// is greater than the current one, cardinality may be increased. This restriction is created to preserve ordering.
    /// @param self The stored oracle array
    /// @param index The index of the observation that was most recently written to the observations array
    /// @param blockTimestamp The timestamp of the new observation
    /// @param tick The active tick at the time of the new observation
    /// @param liquidity The total in-range liquidity at the time of the new observation
    /// @param cardinality The number of populated elements in the oracle array
    /// @param cardinalityNext The new length of the oracle array, independent of population
    /// @return indexUpdated The new index of the most recently written element in the oracle array
    /// @return cardinalityUpdated The new cardinality of the oracle array
    function write(
        Observation[65535] storage self,
        uint16 index,
        uint32 blockTimestamp,
        int24 tick,
        uint128 liquidity,
        uint128 boostedLiquidity,
        uint16 cardinality,
        uint16 cardinalityNext
    ) external returns (uint16 indexUpdated, uint16 cardinalityUpdated) {
        Observation memory last = self[index];

        // early return if we've already written an observation this block
        if (last.blockTimestamp == blockTimestamp) return (index, cardinality);

        // if the conditions are right, we can bump the cardinality
        if (cardinalityNext > cardinality && index == (cardinality - 1)) {
            cardinalityUpdated = cardinalityNext;
        } else {
            cardinalityUpdated = cardinality;
        }

        indexUpdated = (index + 1) % cardinalityUpdated;
        self[indexUpdated] = transform(last, blockTimestamp, tick, liquidity, boostedLiquidity);
    }

    /// @notice Prepares the oracle array to store up to `next` observations
    /// @param self The stored oracle array
    /// @param current The current next cardinality of the oracle array
    /// @param next The proposed next cardinality which will be populated in the oracle array
    /// @return next The next cardinality which will be populated in the oracle array
    function grow(Observation[65535] storage self, uint16 current, uint16 next) external returns (uint16) {
        require(current > 0, 'I');
        // no-op if the passed next value isn't greater than the current next value
        if (next <= current) return current;
        // store in each slot to prevent fresh SSTOREs in swaps
        // this data will not be used because the initialized boolean is still false
        for (uint16 i = current; i < next; i++) self[i].blockTimestamp = 1;
        return next;
    }

    /// @notice comparator for 32-bit timestamps
    /// @dev safe for 0 or 1 overflows, a and b _must_ be chronologically before or equal to time
    /// @param time A timestamp truncated to 32 bits
    /// @param a A comparison timestamp from which to determine the relative position of `time`
    /// @param b From which to determine the relative position of `time`
    /// @return bool Whether `a` is chronologically <= `b`
    function lte(uint32 time, uint32 a, uint32 b) internal pure returns (bool) {
        // if there hasn't been overflow, no need to adjust
        if (a <= time && b <= time) return a <= b;

        uint256 aAdjusted = a > time ? a : a + 2 ** 32;
        uint256 bAdjusted = b > time ? b : b + 2 ** 32;

        return aAdjusted <= bAdjusted;
    }

    /// @notice Fetches the observations beforeOrAt and atOrAfter a target, i.e. where [beforeOrAt, atOrAfter] is satisfied.
    /// The result may be the same observation, or adjacent observations.
    /// @dev The answer must be contained in the array, used when the target is located within the stored observation
    /// boundaries: older than the most recent observation and younger, or the same age as, the oldest observation
    /// @param self The stored oracle array
    /// @param time The current block.timestamp
    /// @param target The timestamp at which the reserved observation should be for
    /// @param index The index of the observation that was most recently written to the observations array
    /// @param cardinality The number of populated elements in the oracle array
    /// @return beforeOrAt The observation recorded before, or at, the target
    /// @return atOrAfter The observation recorded at, or after, the target
    function binarySearch(
        Observation[65535] storage self,
        uint32 time,
        uint32 target,
        uint16 index,
        uint16 cardinality
    ) internal view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {
        uint256 l = (index + 1) % cardinality; // oldest observation
        uint256 r = l + cardinality - 1; // newest observation
        uint256 i;
        while (true) {
            i = (l + r) / 2;

            beforeOrAt = self[i % cardinality];

            // we've landed on an uninitialized tick, keep searching higher (more recently)
            if (!beforeOrAt.initialized) {
                l = i + 1;
                continue;
            }

            atOrAfter = self[(i + 1) % cardinality];

            bool targetAtOrAfter = lte(time, beforeOrAt.blockTimestamp, target);

            // check if we've found the answer!
            if (targetAtOrAfter && lte(time, target, atOrAfter.blockTimestamp)) break;

            if (!targetAtOrAfter) r = i - 1;
            else l = i + 1;
        }
    }

    /// @notice Fetches the observations beforeOrAt and atOrAfter a given target, i.e. where [beforeOrAt, atOrAfter] is satisfied
    /// @dev Assumes there is at least 1 initialized observation.
    /// Used by observeSingle() to compute the counterfactual accumulator values as of a given block timestamp.
    /// @param self The stored oracle array
    /// @param time The current block.timestamp
    /// @param target The timestamp at which the reserved observation should be for
    /// @param tick The active tick at the time of the returned or simulated observation
    /// @param index The index of the observation that was most recently written to the observations array
    /// @param liquidity The total pool liquidity at the time of the call
    /// @param cardinality The number of populated elements in the oracle array
    /// @return beforeOrAt The observation which occurred at, or before, the given timestamp
    /// @return atOrAfter The observation which occurred at, or after, the given timestamp
    function getSurroundingObservations(
        Observation[65535] storage self,
        uint32 time,
        uint32 target,
        int24 tick,
        uint16 index,
        uint128 liquidity,
        uint128 boostedLiquidity,
        uint16 cardinality
    ) internal view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {
        // optimistically set before to the newest observation
        beforeOrAt = self[index];

        // if the target is chronologically at or after the newest observation, we can early return
        if (lte(time, beforeOrAt.blockTimestamp, target)) {
            if (beforeOrAt.blockTimestamp == target) {
                // if newest observation equals target, we're in the same block, so we can ignore atOrAfter
                return (beforeOrAt, atOrAfter);
            } else {
                // otherwise, we need to transform
                return (beforeOrAt, transform(beforeOrAt, target, tick, liquidity, boostedLiquidity));
            }
        }

        // now, set before to the oldest observation
        beforeOrAt = self[(index + 1) % cardinality];
        if (!beforeOrAt.initialized) beforeOrAt = self[0];

        // ensure that the target is chronologically at or after the oldest observation
        require(lte(time, beforeOrAt.blockTimestamp, target), 'OLD');

        // if we've reached this point, we have to binary search
        return binarySearch(self, time, target, index, cardinality);
    }

    /// @dev Reverts if an observation at or before the desired observation timestamp does not exist.
    /// 0 may be passed as `secondsAgo' to return the current cumulative values.
    /// If called with a timestamp falling between two observations, returns the counterfactual accumulator values
    /// at exactly the timestamp between the two observations.
    /// @param self The stored oracle array
    /// @param time The current block timestamp
    /// @param secondsAgo The amount of time to look back, in seconds, at which point to return an observation
    /// @param tick The current tick
    /// @param index The index of the observation that was most recently written to the observations array
    /// @param liquidity The current in-range pool liquidity
    /// @param cardinality The number of populated elements in the oracle array
    /// @return tickCumulative The tick * time elapsed since the pool was first initialized, as of `secondsAgo`
    /// @return secondsPerLiquidityCumulativeX128 The time elapsed / max(1, liquidity) since the pool was first initialized, as of `secondsAgo`
    function observeSingle(
        Observation[65535] storage self,
        uint32 time,
        uint32 secondsAgo,
        int24 tick,
        uint16 index,
        uint128 liquidity,
        uint128 boostedLiquidity,
        uint16 cardinality
    )
        public
        view
        returns (
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            uint160 periodSecondsPerBoostedLiquidityX128
        )
    {
        if (secondsAgo == 0) {
            Observation memory last = self[index];
            if (last.blockTimestamp != time) {
                last = transform(last, time, tick, liquidity, boostedLiquidity);
            }
            return (
                last.tickCumulative,
                last.secondsPerLiquidityCumulativeX128,
                last.secondsPerBoostedLiquidityPeriodX128
            );
        }

        uint32 target = time - secondsAgo;

        (Observation memory beforeOrAt, Observation memory atOrAfter) = getSurroundingObservations(
            self,
            time,
            target,
            tick,
            index,
            liquidity,
            boostedLiquidity,
            cardinality
        );

        if (target == beforeOrAt.blockTimestamp) {
            // we're at the left boundary
            return (
                beforeOrAt.tickCumulative,
                beforeOrAt.secondsPerLiquidityCumulativeX128,
                beforeOrAt.secondsPerBoostedLiquidityPeriodX128
            );
        } else if (target == atOrAfter.blockTimestamp) {
            // we're at the right boundary
            return (
                atOrAfter.tickCumulative,
                atOrAfter.secondsPerLiquidityCumulativeX128,
                atOrAfter.secondsPerBoostedLiquidityPeriodX128
            );
        } else {
            // we're in the middle
            uint32 observationTimeDelta = atOrAfter.blockTimestamp - beforeOrAt.blockTimestamp;
            uint32 targetDelta = target - beforeOrAt.blockTimestamp;
            return (
                beforeOrAt.tickCumulative +
                    ((atOrAfter.tickCumulative - beforeOrAt.tickCumulative) / observationTimeDelta) *
                    targetDelta,
                beforeOrAt.secondsPerLiquidityCumulativeX128 +
                    uint160(
                        (uint256(
                            atOrAfter.secondsPerLiquidityCumulativeX128 - beforeOrAt.secondsPerLiquidityCumulativeX128
                        ) * targetDelta) / observationTimeDelta
                    ),
                beforeOrAt.secondsPerBoostedLiquidityPeriodX128 +
                    uint160(
                        (uint256(
                            atOrAfter.secondsPerBoostedLiquidityPeriodX128 -
                                beforeOrAt.secondsPerBoostedLiquidityPeriodX128
                        ) * targetDelta) / observationTimeDelta
                    )
            );
        }
    }

    /// @notice Returns the accumulator values as of each time seconds ago from the given time in the array of `secondsAgos`
    /// @dev Reverts if `secondsAgos` > oldest observation
    /// @param self The stored oracle array
    /// @param time The current block.timestamp
    /// @param secondsAgos Each amount of time to look back, in seconds, at which point to return an observation
    /// @param tick The current tick
    /// @param index The index of the observation that was most recently written to the observations array
    /// @param liquidity The current in-range pool liquidity
    /// @param cardinality The number of populated elements in the oracle array
    /// @return tickCumulatives The tick * time elapsed since the pool was first initialized, as of each `secondsAgo`
    /// @return secondsPerLiquidityCumulativeX128s The cumulative seconds / max(1, liquidity) since the pool was first initialized, as of each `secondsAgo`
    function observe(
        Observation[65535] storage self,
        uint32 time,
        uint32[] memory secondsAgos,
        int24 tick,
        uint16 index,
        uint128 liquidity,
        uint128 boostedLiquidity,
        uint16 cardinality
    )
        external
        view
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulativeX128s,
            uint160[] memory periodSecondsPerBoostedLiquidityX128s
        )
    {
        require(cardinality > 0, 'I');

        tickCumulatives = new int56[](secondsAgos.length);
        secondsPerLiquidityCumulativeX128s = new uint160[](secondsAgos.length);
        periodSecondsPerBoostedLiquidityX128s = new uint160[](secondsAgos.length);

        for (uint256 i = 0; i < secondsAgos.length; i++) {
            (
                tickCumulatives[i],
                secondsPerLiquidityCumulativeX128s[i],
                periodSecondsPerBoostedLiquidityX128s[i]
            ) = observeSingle(self, time, secondsAgos[i], tick, index, liquidity, boostedLiquidity, cardinality);
        }
    }

    function newPeriod(
        Observation[65535] storage self,
        uint16 index,
        uint256 period
    )
        external
        returns (
            uint160 secondsPerLiquidityCumulativeX128,
            uint160 secondsPerBoostedLiquidityCumulativeX128,
            uint32 boostedInRange
        )
    {
        Observation memory last = self[index];
        States.PoolStates storage states = States.getStorage();

        uint32 delta = uint32(period) * 1 weeks - last.blockTimestamp;

        secondsPerLiquidityCumulativeX128 =
            last.secondsPerLiquidityCumulativeX128 +
            ((uint160(delta) << 128) / (states.liquidity > 0 ? states.liquidity : 1));

        secondsPerBoostedLiquidityCumulativeX128 =
            last.secondsPerBoostedLiquidityPeriodX128 +
            ((uint160(delta) << 128) / (states.boostedLiquidity > 0 ? states.boostedLiquidity : 1));

        boostedInRange = states.boostedLiquidity > 0 ? last.boostedInRange + delta : last.boostedInRange;

        self[index] = Observation({
            blockTimestamp: uint32(period) * 1 weeks,
            tickCumulative: last.tickCumulative + int56(states.slot0.tick) * delta,
            secondsPerLiquidityCumulativeX128: secondsPerLiquidityCumulativeX128,
            secondsPerBoostedLiquidityPeriodX128: secondsPerBoostedLiquidityCumulativeX128,
            initialized: last.initialized,
            boostedInRange: 0
        });
    }

    struct SnapShot {
        int56 tickCumulativeLower;
        int56 tickCumulativeUpper;
        uint160 secondsPerLiquidityOutsideLowerX128;
        uint160 secondsPerLiquidityOutsideUpperX128;
        uint160 secondsPerBoostedLiquidityOutsideLowerX128;
        uint160 secondsPerBoostedLiquidityOutsideUpperX128;
        uint32 secondsOutsideLower;
        uint32 secondsOutsideUpper;
    }

    struct SnapshotCumulativesInsideCache {
        uint32 time;
        int56 tickCumulative;
        uint160 secondsPerLiquidityCumulativeX128;
        uint160 secondsPerBoostedLiquidityCumulativeX128;
    }

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken. Boosted data is only valid if it's within the same period
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsPerBoostedLiquidityInsideX128 The snapshot of seconds per boosted liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(
        int24 tickLower,
        int24 tickUpper
    )
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint160 secondsPerBoostedLiquidityInsideX128,
            uint32 secondsInside
        )
    {
        States.PoolStates storage states = States.getStorage();

        TickInfo storage lower = states._ticks[tickLower];
        TickInfo storage upper = states._ticks[tickUpper];

        SnapShot memory snapshot;

        {
            uint256 period = States._blockTimestamp() / 1 weeks;
            bool initializedLower;
            (
                snapshot.tickCumulativeLower,
                snapshot.secondsPerLiquidityOutsideLowerX128,
                snapshot.secondsPerBoostedLiquidityOutsideLowerX128,
                snapshot.secondsOutsideLower,
                initializedLower
            ) = (
                lower.tickCumulativeOutside,
                lower.secondsPerLiquidityOutsideX128,
                uint160(lower.periodSecondsPerBoostedLiquidityOutsideX128[period]),
                lower.secondsOutside,
                lower.initialized
            );
            require(initializedLower);

            bool initializedUpper;
            (
                snapshot.tickCumulativeUpper,
                snapshot.secondsPerLiquidityOutsideUpperX128,
                snapshot.secondsPerBoostedLiquidityOutsideUpperX128,
                snapshot.secondsOutsideUpper,
                initializedUpper
            ) = (
                upper.tickCumulativeOutside,
                upper.secondsPerLiquidityOutsideX128,
                uint160(upper.periodSecondsPerBoostedLiquidityOutsideX128[period]),
                upper.secondsOutside,
                upper.initialized
            );
            require(initializedUpper);
        }

        Slot0 memory _slot0 = states.slot0;

        if (_slot0.tick < tickLower) {
            return (
                snapshot.tickCumulativeLower - snapshot.tickCumulativeUpper,
                snapshot.secondsPerLiquidityOutsideLowerX128 - snapshot.secondsPerLiquidityOutsideUpperX128,
                snapshot.secondsPerBoostedLiquidityOutsideLowerX128 -
                    snapshot.secondsPerBoostedLiquidityOutsideUpperX128,
                snapshot.secondsOutsideLower - snapshot.secondsOutsideUpper
            );
        } else if (_slot0.tick < tickUpper) {
            SnapshotCumulativesInsideCache memory cache;
            cache.time = States._blockTimestamp();
            (
                cache.tickCumulative,
                cache.secondsPerLiquidityCumulativeX128,
                cache.secondsPerBoostedLiquidityCumulativeX128
            ) = observeSingle(
                states.observations,
                cache.time,
                0,
                _slot0.tick,
                _slot0.observationIndex,
                states.liquidity,
                states.boostedLiquidity,
                _slot0.observationCardinality
            );
            return (
                cache.tickCumulative - snapshot.tickCumulativeLower - snapshot.tickCumulativeUpper,
                cache.secondsPerLiquidityCumulativeX128 -
                    snapshot.secondsPerLiquidityOutsideLowerX128 -
                    snapshot.secondsPerLiquidityOutsideUpperX128,
                cache.secondsPerBoostedLiquidityCumulativeX128 -
                    snapshot.secondsPerBoostedLiquidityOutsideLowerX128 -
                    snapshot.secondsPerBoostedLiquidityOutsideUpperX128,
                cache.time - snapshot.secondsOutsideLower - snapshot.secondsOutsideUpper
            );
        } else {
            return (
                snapshot.tickCumulativeUpper - snapshot.tickCumulativeLower,
                snapshot.secondsPerLiquidityOutsideUpperX128 - snapshot.secondsPerLiquidityOutsideLowerX128,
                snapshot.secondsPerBoostedLiquidityOutsideUpperX128 -
                    snapshot.secondsPerBoostedLiquidityOutsideLowerX128,
                snapshot.secondsOutsideUpper - snapshot.secondsOutsideLower
            );
        }
    }

    /// @notice Returns the seconds per liquidity and seconds inside a tick range for a period
    /// @dev This does not ensure the range is a valid range
    /// @param period The timestamp of the period
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsPerBoostedLiquidityInsideX128 The snapshot of seconds per boosted liquidity for the range
    function periodCumulativesInside(
        uint32 period,
        int24 tickLower,
        int24 tickUpper
    ) external view returns (uint160 secondsPerLiquidityInsideX128, uint160 secondsPerBoostedLiquidityInsideX128) {
        States.PoolStates storage states = States.getStorage();

        TickInfo storage lower = states._ticks[tickLower];
        TickInfo storage upper = states._ticks[tickUpper];

        SnapShot memory snapshot;

        {
            int24 startTick = states.periods[period].startTick;
            uint256 previousPeriod = states.periods[period].previousPeriod;

            (snapshot.secondsPerLiquidityOutsideLowerX128, snapshot.secondsPerBoostedLiquidityOutsideLowerX128) = (
                uint160(lower.periodSecondsPerLiquidityOutsideX128[period]),
                uint160(lower.periodSecondsPerBoostedLiquidityOutsideX128[period])
            );
            if (tickLower <= startTick && snapshot.secondsPerLiquidityOutsideLowerX128 == 0) {
                snapshot.secondsPerLiquidityOutsideLowerX128 = states
                    .periods[previousPeriod]
                    .endSecondsPerLiquidityPeriodX128;
            }

            // separate conditions because liquidity and boosted liquidity can be different
            if (tickLower <= startTick && snapshot.secondsPerBoostedLiquidityOutsideLowerX128 == 0) {
                snapshot.secondsPerBoostedLiquidityOutsideLowerX128 = states
                    .periods[previousPeriod]
                    .endSecondsPerBoostedLiquidityPeriodX128;
            }

            (snapshot.secondsPerLiquidityOutsideUpperX128, snapshot.secondsPerBoostedLiquidityOutsideUpperX128) = (
                uint160(upper.periodSecondsPerLiquidityOutsideX128[period]),
                uint160(upper.periodSecondsPerBoostedLiquidityOutsideX128[period])
            );
            if (tickUpper <= startTick && snapshot.secondsPerLiquidityOutsideUpperX128 == 0) {
                snapshot.secondsPerLiquidityOutsideUpperX128 = states
                    .periods[previousPeriod]
                    .endSecondsPerLiquidityPeriodX128;
            }

            // separate conditions because liquidity and boosted liquidity can be different
            if (tickUpper <= startTick && snapshot.secondsPerBoostedLiquidityOutsideUpperX128 == 0) {
                snapshot.secondsPerBoostedLiquidityOutsideUpperX128 = states
                    .periods[previousPeriod]
                    .endSecondsPerBoostedLiquidityPeriodX128;
            }
        }

        int24 lastTick;
        uint256 currentPeriod = states.lastPeriod;
        {
            // if period is already finalized, use period's last tick, if not, use current tick
            if (currentPeriod > period) {
                lastTick = states.periods[period].lastTick;
            } else {
                lastTick = states.slot0.tick;
            }
        }

        if (lastTick < tickLower) {
            return (
                snapshot.secondsPerLiquidityOutsideLowerX128 - snapshot.secondsPerLiquidityOutsideUpperX128,
                snapshot.secondsPerBoostedLiquidityOutsideLowerX128 -
                    snapshot.secondsPerBoostedLiquidityOutsideUpperX128
            );
        } else if (lastTick < tickUpper) {
            SnapshotCumulativesInsideCache memory cache;
            // if period's on-going, observeSingle, if finalized, use endSecondsPerLiquidityPeriodX128
            if (currentPeriod <= period) {
                cache.time = States._blockTimestamp();
                // limit to the end of period
                if (cache.time > currentPeriod * 1 weeks + 1 weeks) {
                    cache.time = uint32(currentPeriod * 1 weeks + 1 weeks);
                }

                Slot0 memory _slot0 = states.slot0;

                (
                    ,
                    cache.secondsPerLiquidityCumulativeX128,
                    cache.secondsPerBoostedLiquidityCumulativeX128
                ) = observeSingle(
                    states.observations,
                    cache.time,
                    0,
                    _slot0.tick,
                    _slot0.observationIndex,
                    states.liquidity,
                    states.boostedLiquidity,
                    _slot0.observationCardinality
                );
            } else {
                cache.secondsPerLiquidityCumulativeX128 = states.periods[period].endSecondsPerLiquidityPeriodX128;
                cache.secondsPerBoostedLiquidityCumulativeX128 = states
                    .periods[period]
                    .endSecondsPerBoostedLiquidityPeriodX128;
            }

            return (
                cache.secondsPerLiquidityCumulativeX128 -
                    snapshot.secondsPerLiquidityOutsideLowerX128 -
                    snapshot.secondsPerLiquidityOutsideUpperX128,
                cache.secondsPerBoostedLiquidityCumulativeX128 -
                    snapshot.secondsPerBoostedLiquidityOutsideLowerX128 -
                    snapshot.secondsPerBoostedLiquidityOutsideUpperX128
            );
        } else {
            return (
                snapshot.secondsPerLiquidityOutsideUpperX128 - snapshot.secondsPerLiquidityOutsideLowerX128,
                snapshot.secondsPerBoostedLiquidityOutsideUpperX128 -
                    snapshot.secondsPerBoostedLiquidityOutsideLowerX128
            );
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.8.0;
pragma abicoder v2;

import './FullMath.sol';
import './FixedPoint128.sol';
import './FixedPoint32.sol';
import './LiquidityMath.sol';
import './SqrtPriceMath.sol';
import './States.sol';
import './Tick.sol';
import './TickMath.sol';
import './TickBitmap.sol';
import './Oracle.sol';

import '../../v2-periphery/libraries/LiquidityAmounts.sol';

import '../../interfaces/IVotingEscrow.sol';
import '../../interfaces/IVoter.sol';

/// @title Position
/// @notice Positions represent an owner address' liquidity between a lower and upper tick boundary
/// @dev Positions store additional state for tracking fees owed to the position
library Position {
    // no limit if a your veRam reaches a threshold
    // if veRamRatio is more than 2.5% of total (1% * 1.5e18 =  1.5e+16)
    uint256 internal constant veRamUncapThreshold = 15000000000000000;

    /// @notice Returns the hash used to store positions in a mapping
    /// @param owner The address of the position owner
    /// @param index The index of the position
    /// @param tickLower The lower tick boundary of the position
    /// @param tickUpper The upper tick boundary of the position
    /// @return _hash The hash used to store positions in a mapping
    function positionHash(
        address owner,
        uint256 index,
        int24 tickLower,
        int24 tickUpper
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner, index, tickLower, tickUpper));
    }

    /// @notice Returns the Info struct of a position, given an owner and position boundaries
    /// @param self The mapping containing all user positions
    /// @param owner The address of the position owner
    /// @param index The index of the position
    /// @param tickLower The lower tick boundary of the position
    /// @param tickUpper The upper tick boundary of the position
    /// @return position The position info struct of the given owners' position
    function get(
        mapping(bytes32 => PositionInfo) storage self,
        address owner,
        uint256 index,
        int24 tickLower,
        int24 tickUpper
    ) public view returns (PositionInfo storage position) {
        position = self[positionHash(owner, index, tickLower, tickUpper)];
    }

    /// @notice Returns the BoostInfo struct of a position, given an owner, index, and position boundaries
    /// @param self The mapping containing all user boosted positions within the period
    /// @param owner The address of the position owner
    /// @param index The index of the position
    /// @param tickLower The lower tick boundary of the position
    /// @param tickUpper The upper tick boundary of the position
    /// @return position The position BoostInfo struct of the given owners' position within the period
    function get(
        PeriodBoostInfo storage self,
        address owner,
        uint256 index,
        int24 tickLower,
        int24 tickUpper
    ) public view returns (BoostInfo storage position) {
        position = self.positions[positionHash(owner, index, tickLower, tickUpper)];
    }

    /// @notice Credits accumulated fees to a user's position
    /// @param self The individual position to update
    /// @param liquidityDelta The change in pool liquidity as a result of the position update
    /// @param feeGrowthInside0X128 The all-time fee growth in token0, per unit of liquidity, inside the position's tick boundaries
    /// @param feeGrowthInside1X128 The all-time fee growth in token1, per unit of liquidity, inside the position's tick boundaries
    function _updatePositionLiquidity(
        PositionInfo storage self,
        States.PoolStates storage states,
        uint256 period,
        bytes32 _positionHash,
        int128 liquidityDelta,
        uint256 feeGrowthInside0X128,
        uint256 feeGrowthInside1X128
    ) internal {
        PositionInfo memory _self = self;

        uint128 liquidityNext;
        if (liquidityDelta == 0) {
            require(_self.liquidity > 0, 'NP'); // disallow pokes for 0 liquidity positions
            liquidityNext = _self.liquidity;
        } else {
            liquidityNext = LiquidityMath.addDelta(_self.liquidity, liquidityDelta);
        }

        // calculate accumulated fees
        uint128 tokensOwed0 = uint128(
            FullMath.mulDiv(feeGrowthInside0X128 - _self.feeGrowthInside0LastX128, _self.liquidity, FixedPoint128.Q128)
        );
        uint128 tokensOwed1 = uint128(
            FullMath.mulDiv(feeGrowthInside1X128 - _self.feeGrowthInside1LastX128, _self.liquidity, FixedPoint128.Q128)
        );

        // update the position
        if (liquidityDelta != 0) {
            self.liquidity = liquidityNext;
        }
        self.feeGrowthInside0LastX128 = feeGrowthInside0X128;
        self.feeGrowthInside1LastX128 = feeGrowthInside1X128;
        if (tokensOwed0 > 0 || tokensOwed1 > 0) {
            // overflow is acceptable, have to withdraw before you hit type(uint128).max fees
            self.tokensOwed0 += tokensOwed0;
            self.tokensOwed1 += tokensOwed1;
        }

        // write checkpoint, push a checkpoint if the last period is different, overwrite if not
        uint256 checkpointLength = states.positionCheckpoints[_positionHash].length;
        if (checkpointLength == 0 || states.positionCheckpoints[_positionHash][checkpointLength - 1].period != period) {
            states.positionCheckpoints[_positionHash].push(
                PositionCheckpoint({period: period, liquidity: liquidityNext})
            );
        } else {
            states.positionCheckpoints[_positionHash][checkpointLength - 1].liquidity = liquidityNext;
        }
    }

    /// @notice Updates boosted balances to a user's position
    /// @param self The individual boosted position to update
    /// @param boostedLiquidityDelta The change in pool liquidity as a result of the position update
    /// @param secondsPerBoostedLiquidityPeriodX128 The seconds in range gained per unit of liquidity, inside the position's tick boundaries for this period
    function _updateBoostedPosition(
        BoostInfo storage self,
        int128 liquidityDelta,
        int128 boostedLiquidityDelta,
        uint160 secondsPerLiquidityPeriodX128,
        uint160 secondsPerBoostedLiquidityPeriodX128
    ) internal {
        // negative expected sometimes, which is allowed
        int160 secondsPerLiquidityPeriodIntX128 = int160(secondsPerLiquidityPeriodX128);
        int160 secondsPerBoostedLiquidityPeriodIntX128 = int160(secondsPerBoostedLiquidityPeriodX128);

        self.boostAmount = LiquidityMath.addDelta(self.boostAmount, boostedLiquidityDelta);

        int160 secondsPerLiquidityPeriodStartX128 = self.secondsPerLiquidityPeriodStartX128;
        int160 secondsPerBoostedLiquidityPeriodStartX128 = self.secondsPerBoostedLiquidityPeriodStartX128;

        // take the difference to make the delta positive or zero
        secondsPerLiquidityPeriodIntX128 -= secondsPerLiquidityPeriodStartX128;
        secondsPerBoostedLiquidityPeriodIntX128 -= secondsPerBoostedLiquidityPeriodStartX128;

        // these int should never be negative
        if (secondsPerLiquidityPeriodIntX128 < 0) {
            secondsPerLiquidityPeriodIntX128 = 0;
        }
        if (secondsPerBoostedLiquidityPeriodIntX128 < 0) {
            secondsPerBoostedLiquidityPeriodIntX128 = 0;
        }

        int256 secondsDebtDeltaX96 = SafeCast.toInt256(
            FullMath.mulDivRoundingUp(
                liquidityDelta > 0 ? uint256(liquidityDelta) : uint256(-liquidityDelta),
                uint256(secondsPerLiquidityPeriodIntX128),
                FixedPoint32.Q32
            )
        );

        int256 boostedSecondsDebtDeltaX96 = SafeCast.toInt256(
            FullMath.mulDivRoundingUp(
                boostedLiquidityDelta > 0 ? uint256(boostedLiquidityDelta) : uint256(-boostedLiquidityDelta),
                uint256(secondsPerBoostedLiquidityPeriodIntX128),
                FixedPoint32.Q32
            )
        );

        self.boostedSecondsDebtX96 = boostedLiquidityDelta > 0
            ? self.boostedSecondsDebtX96 + boostedSecondsDebtDeltaX96
            : self.boostedSecondsDebtX96 - boostedSecondsDebtDeltaX96; // can't overflow since each period is way less than uint31

        self.secondsDebtX96 = liquidityDelta > 0
            ? self.secondsDebtX96 + secondsDebtDeltaX96
            : self.secondsDebtX96 - secondsDebtDeltaX96; // can't overflow since each period is way less than uint31
    }

    /// @notice Initializes secondsPerLiquidityPeriodStartX128 for a position
    /// @param self The individual boosted position to update
    /// @param position The individual position
    /// @param secondsInRangeParams Parameters used to find the seconds in range
    /// @param secondsPerLiquidityPeriodX128 The seconds in range gained per unit of liquidity, inside the position's tick boundaries for this period
    /// @param secondsPerBoostedLiquidityPeriodX128 The seconds in range gained per unit of liquidity, inside the position's tick boundaries for this period
    function initializeSecondsStart(
        BoostInfo storage self,
        PositionInfo storage position,
        PositionPeriodSecondsInRangeParams memory secondsInRangeParams,
        uint160 secondsPerLiquidityPeriodX128,
        uint160 secondsPerBoostedLiquidityPeriodX128
    ) internal {
        // record initialized
        self.initialized = true;

        // record owed tokens if liquidity > 0 (means position existed before period change)
        if (position.liquidity > 0) {
            (uint256 periodSecondsInsideX96, uint256 periodBoostedSecondsInsideX96) = positionPeriodSecondsInRange(
                secondsInRangeParams
            );

            self.secondsDebtX96 = -int256(periodSecondsInsideX96);
            self.boostedSecondsDebtX96 = -int256(periodBoostedSecondsInsideX96);
        }

        // convert uint to int
        // negative expected sometimes, which is allowed
        int160 secondsPerLiquidityPeriodIntX128 = int160(secondsPerLiquidityPeriodX128);
        int160 secondsPerBoostedLiquidityPeriodIntX128 = int160(secondsPerBoostedLiquidityPeriodX128);

        self.secondsPerLiquidityPeriodStartX128 = secondsPerLiquidityPeriodIntX128;

        self.secondsPerBoostedLiquidityPeriodStartX128 = secondsPerBoostedLiquidityPeriodIntX128;
    }

    struct ModifyPositionParams {
        // the address that owns the position
        address owner;
        uint256 index;
        // the lower and upper tick of the position
        int24 tickLower;
        int24 tickUpper;
        // any change in liquidity
        int128 liquidityDelta;
        uint256 veRamTokenId;
    }

    /// @dev Effect some changes to a position
    /// @param params the position details and the change to the position's liquidity to effect
    /// @return position a storage pointer referencing the position with the given owner and tick range
    /// @return amount0 the amount of token0 owed to the pool, negative if the pool should pay the recipient
    /// @return amount1 the amount of token1 owed to the pool, negative if the pool should pay the recipient
    function _modifyPosition(
        ModifyPositionParams memory params
    ) external returns (PositionInfo storage position, int256 amount0, int256 amount1) {
        States.PoolStates storage states = States.getStorage();

        // check ticks
        require(params.tickLower < params.tickUpper, 'TLU');
        require(params.tickLower >= TickMath.MIN_TICK, 'TLM');
        require(params.tickUpper <= TickMath.MAX_TICK, 'TUM');

        Slot0 memory _slot0 = states.slot0; // SLOAD for gas optimization

        int128 boostedLiquidityDelta;
        (position, boostedLiquidityDelta) = _updatePosition(
            UpdatePositionParams({
                owner: params.owner,
                index: params.index,
                tickLower: params.tickLower,
                tickUpper: params.tickUpper,
                liquidityDelta: params.liquidityDelta,
                tick: _slot0.tick,
                veRamTokenId: params.veRamTokenId
            })
        );

        if (params.liquidityDelta != 0 || boostedLiquidityDelta != 0) {
            if (_slot0.tick < params.tickLower) {
                // current tick is below the passed range; liquidity can only become in range by crossing from left to
                // right, when we'll need _more_ token0 (it's becoming more valuable) so user must provide it
                amount0 = SqrtPriceMath.getAmount0Delta(
                    TickMath.getSqrtRatioAtTick(params.tickLower),
                    TickMath.getSqrtRatioAtTick(params.tickUpper),
                    params.liquidityDelta
                );
            } else if (_slot0.tick < params.tickUpper) {
                // current tick is inside the passed range
                uint128 liquidityBefore = states.liquidity; // SLOAD for gas optimization
                uint128 boostedLiquidityBefore = states.boostedLiquidity;

                // write an oracle entry
                (states.slot0.observationIndex, states.slot0.observationCardinality) = Oracle.write(
                    states.observations,
                    _slot0.observationIndex,
                    States._blockTimestamp(),
                    _slot0.tick,
                    liquidityBefore,
                    boostedLiquidityBefore,
                    _slot0.observationCardinality,
                    _slot0.observationCardinalityNext
                );

                amount0 = SqrtPriceMath.getAmount0Delta(
                    _slot0.sqrtPriceX96,
                    TickMath.getSqrtRatioAtTick(params.tickUpper),
                    params.liquidityDelta
                );
                amount1 = SqrtPriceMath.getAmount1Delta(
                    TickMath.getSqrtRatioAtTick(params.tickLower),
                    _slot0.sqrtPriceX96,
                    params.liquidityDelta
                );

                states.liquidity = LiquidityMath.addDelta(liquidityBefore, params.liquidityDelta);
                states.boostedLiquidity = LiquidityMath.addDelta(boostedLiquidityBefore, boostedLiquidityDelta);
            } else {
                // current tick is above the passed range; liquidity can only become in range by crossing from right to
                // left, when we'll need _more_ token1 (it's becoming more valuable) so user must provide it
                amount1 = SqrtPriceMath.getAmount1Delta(
                    TickMath.getSqrtRatioAtTick(params.tickLower),
                    TickMath.getSqrtRatioAtTick(params.tickUpper),
                    params.liquidityDelta
                );
            }
        }
    }

    struct UpdatePositionParams {
        // the owner of the position
        address owner;
        // the index of the position
        uint256 index;
        // the lower tick of the position's tick range
        int24 tickLower;
        // the upper tick of the position's tick range
        int24 tickUpper;
        // the amount liquidity changes by
        int128 liquidityDelta;
        // the current tick, passed to avoid sloads
        int24 tick;
        // the veRamTokenId to be attached
        uint256 veRamTokenId;
    }

    struct UpdatePositionCache {
        uint256 feeGrowthGlobal0X128;
        uint256 feeGrowthGlobal1X128;
        bool flippedUpper;
        bool flippedLower;
        uint256 feeGrowthInside0X128;
        uint256 feeGrowthInside1X128;
    }

    struct ObservationCache {
        int56 tickCumulative;
        uint160 secondsPerLiquidityCumulativeX128;
        uint160 secondsPerBoostedLiquidityPeriodX128;
    }

    struct PoolBalanceCache {
        uint256 hypBalance0;
        uint256 hypBalance1;
        uint256 poolBalance0;
        uint256 poolBalance1;
    }

    struct BoostedLiquidityCache {
        uint256 veRamRatio;
        uint256 newBoostedLiquidity;
        uint160 lowerSqrtRatioX96;
        uint160 upperSqrtRatioX96;
        uint160 currentSqrtRatioX96;
    }

    struct VeRamBoostCache {
        uint256 veRamBoostUsedRatio;
        uint256 positionBoostUsedRatio;
    }

    /// @dev Gets and updates a position with the given liquidity delta
    /// @param params the position details and the change to the position's liquidity to effect
    function _updatePosition(
        UpdatePositionParams memory params
    ) private returns (PositionInfo storage position, int128 boostedLiquidityDelta) {
        States.PoolStates storage states = States.getStorage();

        uint256 period = States._blockTimestamp() / 1 weeks;

        bytes32 _positionHash = positionHash(params.owner, params.index, params.tickLower, params.tickUpper);
        position = states.positions[_positionHash];
        BoostInfo storage boostedPosition = states.boostInfos[period].positions[_positionHash];

        {
            // this is needed to determine attachment and newBoostedLiquidity
            uint128 newLiquidity = LiquidityMath.addDelta(position.liquidity, params.liquidityDelta);

            // detach if new liquidity is 0
            if (newLiquidity == 0) {
                _switchAttached(position, boostedPosition, 0, period, _positionHash);
                params.veRamTokenId = 0;
            }

            // type(uint256).max serves as a signal to not switch attachment
            if (params.veRamTokenId != type(uint256).max) {
                _switchAttached(position, boostedPosition, params.veRamTokenId, period, _positionHash);
            }

            {
                BoostedLiquidityCache memory boostedLiquidityCache;
                (boostedLiquidityCache.veRamRatio, boostedLiquidityCache.newBoostedLiquidity) = LiquidityMath
                    .calculateBoostedLiquidity(
                        newLiquidity,
                        boostedPosition.veRamAmount,
                        states.boostInfos[period].totalVeRamAmount
                    );

                if (boostedLiquidityCache.newBoostedLiquidity > 0) {
                    PoolBalanceCache memory poolBalanceCache;

                    poolBalanceCache.poolBalance0 = States.balance0();
                    poolBalanceCache.poolBalance1 = States.balance1();

                    boostedLiquidityCache.lowerSqrtRatioX96 = TickMath.getSqrtRatioAtTick(params.tickLower);

                    boostedLiquidityCache.upperSqrtRatioX96 = TickMath.getSqrtRatioAtTick(params.tickUpper);

                    boostedLiquidityCache.currentSqrtRatioX96 = states.slot0.sqrtPriceX96;

                    // boosted liquidity cap
                    // no limit if a your veRam reaches a threshold
                    uint160 midSqrtRatioX96 = TickMath.getSqrtRatioAtTick((params.tickLower + params.tickUpper) / 2);

                    // check max balance allowed
                    {
                        uint256 maxBalance0 = LiquidityAmounts.getAmount0ForLiquidity(
                            midSqrtRatioX96,
                            boostedLiquidityCache.upperSqrtRatioX96,
                            type(uint128).max
                        );
                        uint256 maxBalance1 = LiquidityAmounts.getAmount1ForLiquidity(
                            boostedLiquidityCache.lowerSqrtRatioX96,
                            midSqrtRatioX96,
                            type(uint128).max
                        );

                        if (poolBalanceCache.poolBalance0 > maxBalance0) {
                            poolBalanceCache.hypBalance0 = maxBalance0;
                        } else {
                            poolBalanceCache.hypBalance0 = poolBalanceCache.poolBalance0;
                        }
                        if (poolBalanceCache.poolBalance1 > maxBalance1) {
                            poolBalanceCache.hypBalance1 = maxBalance1;
                        } else {
                            poolBalanceCache.hypBalance1 = poolBalanceCache.poolBalance1;
                        }
                    }

                    // hypothetical liquidity is found by using all of balance0 and balance1
                    // at this position's midpoint and range
                    // using midpoint to discourage making out of range positions
                    uint256 hypotheticalLiquidity = LiquidityAmounts.getLiquidityForAmounts(
                        midSqrtRatioX96,
                        boostedLiquidityCache.lowerSqrtRatioX96,
                        boostedLiquidityCache.upperSqrtRatioX96,
                        poolBalanceCache.hypBalance0,
                        poolBalanceCache.hypBalance1
                    );

                    // limit newBoostedLiquidity to a portion of hypotheticalLiquidity based on how much veRam is attached
                    uint256 boostedLiquidityCap = FullMath.mulDiv(
                        hypotheticalLiquidity,
                        boostedLiquidityCache.veRamRatio,
                        1e18
                    );

                    if (boostedLiquidityCache.newBoostedLiquidity > boostedLiquidityCap) {
                        boostedLiquidityCache.newBoostedLiquidity = boostedLiquidityCap;
                    }
                    /*
                    // veRam boost available
                    uint256 veRamBoostAvailable;
                    VeRamBoostCache memory veRamBoostCache;
                    {
                        // fetch existing data
                        veRamBoostCache.positionBoostUsedRatio = states
                            .boostInfos[period]
                            .veRamInfos[params.veRamTokenId]
                            .positionBoostUsedRatio[_positionHash];

                        veRamBoostCache.veRamBoostUsedRatio = states
                            .boostInfos[period]
                            .veRamInfos[params.veRamTokenId]
                            .veRamBoostUsedRatio;

                        // prevents underflows
                        veRamBoostCache.veRamBoostUsedRatio = veRamBoostCache.veRamBoostUsedRatio >
                            veRamBoostCache.positionBoostUsedRatio
                            ? veRamBoostCache.veRamBoostUsedRatio - veRamBoostCache.positionBoostUsedRatio
                            : 0;

                        uint256 veRamBoostAvailableRatio = 1e18 > veRamBoostCache.veRamBoostUsedRatio
                            ? 1e18 - veRamBoostCache.veRamBoostUsedRatio
                            : 0;

                        // no limit if a your veRam reaches a threshold
                        // hypothetical balances still have to be calculated in case
                        // the veRam falls below threshold later
                        if (boostedLiquidityCache.veRamRatio >= veRamUncapThreshold) {
                            veRamBoostAvailableRatio = 1e18;
                        }

                        // assign hypBalances
                        {
                            uint256 maxBalance0 = 0;
                            uint256 maxBalance1 = 0;

                            if (boostedLiquidityCache.currentSqrtRatioX96 < boostedLiquidityCache.lowerSqrtRatioX96) {
                                maxBalance0 = LiquidityAmounts.getAmount0ForLiquidity(
                                    boostedLiquidityCache.lowerSqrtRatioX96,
                                    boostedLiquidityCache.upperSqrtRatioX96,
                                    type(uint128).max
                                );
                            } else if (
                                boostedLiquidityCache.currentSqrtRatioX96 < boostedLiquidityCache.upperSqrtRatioX96
                            ) {
                                maxBalance0 = LiquidityAmounts.getAmount0ForLiquidity(
                                    boostedLiquidityCache.currentSqrtRatioX96,
                                    boostedLiquidityCache.upperSqrtRatioX96,
                                    type(uint128).max
                                );
                                maxBalance1 = LiquidityAmounts.getAmount1ForLiquidity(
                                    boostedLiquidityCache.lowerSqrtRatioX96,
                                    boostedLiquidityCache.currentSqrtRatioX96,
                                    type(uint128).max
                                );
                            } else {
                                maxBalance1 = LiquidityAmounts.getAmount1ForLiquidity(
                                    boostedLiquidityCache.lowerSqrtRatioX96,
                                    boostedLiquidityCache.upperSqrtRatioX96,
                                    type(uint128).max
                                );
                            }

                            if (poolBalanceCache.poolBalance0 > maxBalance0) {
                                poolBalanceCache.hypBalance0 = maxBalance0;
                            } else {
                                poolBalanceCache.hypBalance0 = poolBalanceCache.poolBalance0;
                            }
                            if (poolBalanceCache.poolBalance1 > maxBalance1) {
                                poolBalanceCache.hypBalance1 = maxBalance1;
                            } else {
                                poolBalanceCache.hypBalance1 = poolBalanceCache.poolBalance1;
                            }
                        }

                        // hypothetical liquidity is found by using all of balance0 and balance1
                        // at current price to determine % boost used since boost will fill up fast otherwise
                        uint256 hypotheticalLiquidity = LiquidityAmounts.getLiquidityForAmounts(
                            boostedLiquidityCache.currentSqrtRatioX96,
                            boostedLiquidityCache.lowerSqrtRatioX96,
                            boostedLiquidityCache.upperSqrtRatioX96,
                            poolBalanceCache.hypBalance0,
                            poolBalanceCache.hypBalance1
                        );

                        hypotheticalLiquidity = FullMath.mulDiv(
                            hypotheticalLiquidity,
                            boostedLiquidityCache.veRamRatio,
                            1e18
                        );

                        veRamBoostAvailable = FullMath.mulDiv(hypotheticalLiquidity, veRamBoostAvailableRatio, 1e18);

                        if (
                            boostedLiquidityCache.newBoostedLiquidity > veRamBoostAvailable &&
                            boostedLiquidityCache.veRamRatio < veRamUncapThreshold
                        ) {
                            boostedLiquidityCache.newBoostedLiquidity = veRamBoostAvailable;
                        }

                        veRamBoostCache.positionBoostUsedRatio = hypotheticalLiquidity == 0
                            ? 0
                            : FullMath.mulDiv(boostedLiquidityCache.newBoostedLiquidity, 1e18, hypotheticalLiquidity);
                    }
                    

                    // update veRamBoostUsedRatio and positionBoostUsedRatio
                    states.boostInfos[period].veRamInfos[params.veRamTokenId].positionBoostUsedRatio[
                        _positionHash
                    ] = veRamBoostCache.positionBoostUsedRatio;

                    states.boostInfos[period].veRamInfos[params.veRamTokenId].veRamBoostUsedRatio = uint128(
                        veRamBoostCache.veRamBoostUsedRatio + veRamBoostCache.positionBoostUsedRatio
                    );
                    */
                }

                boostedLiquidityDelta = int128(boostedLiquidityCache.newBoostedLiquidity - boostedPosition.boostAmount);
            }
        }

        UpdatePositionCache memory cache;

        cache.feeGrowthGlobal0X128 = states.feeGrowthGlobal0X128; // SLOAD for gas optimization
        cache.feeGrowthGlobal1X128 = states.feeGrowthGlobal1X128; // SLOAD for gas optimization

        // if we need to update the ticks, do it
        if (params.liquidityDelta != 0 || boostedLiquidityDelta != 0) {
            uint32 time = States._blockTimestamp();
            ObservationCache memory observationCache;
            (
                observationCache.tickCumulative,
                observationCache.secondsPerLiquidityCumulativeX128,
                observationCache.secondsPerBoostedLiquidityPeriodX128
            ) = Oracle.observeSingle(
                states.observations,
                time,
                0,
                states.slot0.tick,
                states.slot0.observationIndex,
                states.liquidity,
                states.boostedLiquidity,
                states.slot0.observationCardinality
            );

            cache.flippedLower = Tick.update(
                states._ticks,
                Tick.UpdateTickParams(
                    params.tickLower,
                    params.tick,
                    params.liquidityDelta,
                    boostedLiquidityDelta,
                    cache.feeGrowthGlobal0X128,
                    cache.feeGrowthGlobal1X128,
                    observationCache.secondsPerLiquidityCumulativeX128,
                    observationCache.secondsPerBoostedLiquidityPeriodX128,
                    observationCache.tickCumulative,
                    time,
                    false,
                    states.maxLiquidityPerTick
                )
            );
            cache.flippedUpper = Tick.update(
                states._ticks,
                Tick.UpdateTickParams(
                    params.tickUpper,
                    params.tick,
                    params.liquidityDelta,
                    boostedLiquidityDelta,
                    cache.feeGrowthGlobal0X128,
                    cache.feeGrowthGlobal1X128,
                    observationCache.secondsPerLiquidityCumulativeX128,
                    observationCache.secondsPerBoostedLiquidityPeriodX128,
                    observationCache.tickCumulative,
                    time,
                    true,
                    states.maxLiquidityPerTick
                )
            );

            if (cache.flippedLower) {
                TickBitmap.flipTick(states.tickBitmap, params.tickLower, states.tickSpacing);
            }
            if (cache.flippedUpper) {
                TickBitmap.flipTick(states.tickBitmap, params.tickUpper, states.tickSpacing);
            }
        }

        (cache.feeGrowthInside0X128, cache.feeGrowthInside1X128) = Tick.getFeeGrowthInside(
            states._ticks,
            params.tickLower,
            params.tickUpper,
            params.tick,
            cache.feeGrowthGlobal0X128,
            cache.feeGrowthGlobal1X128
        );

        {
            (uint160 secondsPerLiquidityPeriodX128, uint160 secondsPerBoostedLiquidityPeriodX128) = Oracle
                .periodCumulativesInside(uint32(period), params.tickLower, params.tickUpper);

            if (!boostedPosition.initialized) {
                initializeSecondsStart(
                    boostedPosition,
                    position,
                    PositionPeriodSecondsInRangeParams({
                        period: period,
                        owner: params.owner,
                        index: params.index,
                        tickLower: params.tickLower,
                        tickUpper: params.tickUpper
                    }),
                    secondsPerLiquidityPeriodX128,
                    secondsPerBoostedLiquidityPeriodX128
                );
            }

            _updatePositionLiquidity(
                position,
                states,
                period,
                _positionHash,
                params.liquidityDelta,
                cache.feeGrowthInside0X128,
                cache.feeGrowthInside1X128
            );

            _updateBoostedPosition(
                boostedPosition,
                params.liquidityDelta,
                boostedLiquidityDelta,
                secondsPerLiquidityPeriodX128,
                secondsPerBoostedLiquidityPeriodX128
            );
        }

        // clear any tick data that is no longer needed
        if (params.liquidityDelta < 0) {
            if (cache.flippedLower) {
                Tick.clear(states._ticks, params.tickLower);
            }
            if (cache.flippedUpper) {
                Tick.clear(states._ticks, params.tickUpper);
            }
        }
    }

    /// @notice updates attached veRam tokenId and veRam amount
    /// @dev can only be called in _updatePostion since boostedSecondsDebt needs to be updated when this is called
    /// @param position the user's position
    /// @param boostedPosition the user's boosted position
    /// @param veRamTokenId the veRam tokenId to switch to
    /// @param _positionHash the position's hash identifier
    function _switchAttached(
        PositionInfo storage position,
        BoostInfo storage boostedPosition,
        uint256 veRamTokenId,
        uint256 period,
        bytes32 _positionHash
    ) private {
        States.PoolStates storage states = States.getStorage();
        address _veRam = states.veRam;

        require(
            veRamTokenId == 0 ||
                msg.sender == states.nfpManager ||
                IVotingEscrow(_veRam).isApprovedOrOwner(msg.sender, veRamTokenId),
            'TNA' // tokenId not authorized
        );

        int128 veRamAmountDelta;
        uint256 oldAttached = position.attachedVeRamId;

        // call detach and attach if needed
        if (veRamTokenId != oldAttached) {
            address _voter = states.voter;

            // detach, remove position from VeRamAttachments, and update total veRamAmount
            if (oldAttached != 0) {
                // call voter to notify detachment
                IVoter(_voter).detachTokenFromGauge(oldAttached, IVotingEscrow(_veRam).ownerOf(oldAttached));

                // update times attached and veRamAmountDelta
                uint128 timesAttached = states.boostInfos[period].veRamInfos[oldAttached].timesAttached;

                // only modify veRamAmountDelta if this is the last time
                // this veRam has been used to attach to a position
                if (timesAttached == 1) {
                    veRamAmountDelta -= boostedPosition.veRamAmount;
                }

                // update times this veRam NFT has been attached to this pool
                states.boostInfos[period].veRamInfos[oldAttached].timesAttached = timesAttached - 1;

                // update veRamBoostUsedRatio and positionBoostUsedRatio
                uint256 positionBoostUsedRatio = states
                    .boostInfos[period]
                    .veRamInfos[oldAttached]
                    .positionBoostUsedRatio[_positionHash];

                states.boostInfos[period].veRamInfos[oldAttached].veRamBoostUsedRatio -= uint128(
                    positionBoostUsedRatio
                );

                states.boostInfos[period].veRamInfos[oldAttached].positionBoostUsedRatio[_positionHash] = 0;
            }

            if (veRamTokenId != 0) {
                // call voter to notify attachment
                IVoter(_voter).attachTokenToGauge(veRamTokenId, IVotingEscrow(_veRam).ownerOf(veRamTokenId));
            }

            position.attachedVeRamId = veRamTokenId;
        }

        if (veRamTokenId != 0) {
            // record new attachment amount
            int128 veRamAmountAfter = int128(IVotingEscrow(_veRam).balanceOfNFT(veRamTokenId)); // can't overflow because bias is lower than locked, which is an int128
            boostedPosition.veRamAmount = veRamAmountAfter;

            // update times attached and veRamAmountDelta
            uint128 timesAttached = states.boostInfos[period].veRamInfos[veRamTokenId].timesAttached;

            // only add to veRam total amount if it's newly attached to the pool
            if (timesAttached == 0) {
                veRamAmountDelta += veRamAmountAfter;
            }

            // update times attached
            states.boostInfos[period].veRamInfos[veRamTokenId].timesAttached = timesAttached + 1;
        } else {
            boostedPosition.veRamAmount = 0;
        }

        // update total veRam amount
        int128 totalVeRamAmount = states.boostInfos[period].totalVeRamAmount;
        totalVeRamAmount += veRamAmountDelta;
        if (totalVeRamAmount < 0) {
            totalVeRamAmount = 0;
        }

        states.boostInfos[period].totalVeRamAmount = totalVeRamAmount;
    }

    /// @notice gets the checkpoint directly before the period
    /// @dev returns the 0th index if there's no checkpoints
    /// @param checkpoints the position's checkpoints in storage
    /// @param period the period of interest
    function getCheckpoint(
        PositionCheckpoint[] storage checkpoints,
        uint256 period
    ) internal view returns (uint256 checkpointIndex, uint256 checkpointPeriod) {
        {
            uint256 checkpointLength = checkpoints.length;

            // return 0 if length is 0
            if (checkpointLength == 0) {
                return (0, 0);
            }

            checkpointPeriod = checkpoints[0].period;

            // return 0 if first checkpoint happened after period
            if (checkpointPeriod > period) {
                return (0, 0);
            }

            checkpointIndex = checkpointLength - 1;
        }

        checkpointPeriod = checkpoints[checkpointIndex].period;

        // Find relevant checkpoint if latest checkpoint isn't before period of interest
        if (checkpointPeriod > period) {
            uint256 lower = 0;
            uint256 upper = checkpointIndex;

            while (upper > lower) {
                uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
                checkpointPeriod = checkpoints[center].period;
                if (checkpointPeriod == period) {
                    checkpointIndex = center;
                    return (checkpointIndex, checkpointPeriod);
                } else if (checkpointPeriod < period) {
                    lower = center;
                } else {
                    upper = center - 1;
                }
            }
            checkpointIndex = lower;
            checkpointPeriod = checkpoints[checkpointIndex].period;
        }

        return (checkpointIndex, checkpointPeriod);
    }

    struct PositionPeriodSecondsInRangeParams {
        uint256 period;
        address owner;
        uint256 index;
        int24 tickLower;
        int24 tickUpper;
    }

    // Get the period seconds in range of a specific position
    /// @return periodSecondsInsideX96 seconds the position was not in range for the period
    /// @return periodBoostedSecondsInsideX96 boosted seconds the period
    function positionPeriodSecondsInRange(
        PositionPeriodSecondsInRangeParams memory params
    ) public view returns (uint256 periodSecondsInsideX96, uint256 periodBoostedSecondsInsideX96) {
        States.PoolStates storage states = States.getStorage();

        {
            uint256 currentPeriod = states.lastPeriod;
            require(params.period <= currentPeriod, 'FTR'); // Future period, or current period hasn't been updated
        }

        bytes32 _positionHash = positionHash(params.owner, params.index, params.tickLower, params.tickUpper);

        uint256 liquidity;
        uint256 boostedLiquidity;
        int160 secondsPerLiquidityPeriodStartX128;
        int160 secondsPerBoostedLiquidityPeriodStartX128;

        {
            PositionCheckpoint[] storage checkpoints = states.positionCheckpoints[_positionHash];

            // get checkpoint at period, or last checkpoint before the period
            (uint256 checkpointIndex, uint256 checkpointPeriod) = getCheckpoint(checkpoints, params.period);

            // Return 0s if checkpointPeriod is 0
            if (checkpointPeriod == 0) {
                return (0, 0);
            }

            liquidity = checkpoints[checkpointIndex].liquidity;
            // use period instead of checkpoint period for boosted liquidity because it needs to be renewed weekly
            boostedLiquidity = states.boostInfos[params.period].positions[_positionHash].boostAmount;

            secondsPerLiquidityPeriodStartX128 = states
                .boostInfos[params.period]
                .positions[_positionHash]
                .secondsPerLiquidityPeriodStartX128;
            secondsPerBoostedLiquidityPeriodStartX128 = states
                .boostInfos[params.period]
                .positions[_positionHash]
                .secondsPerBoostedLiquidityPeriodStartX128;
        }

        (uint160 secondsPerLiquidityInsideX128, uint160 secondsPerBoostedLiquidityInsideX128) = Oracle
            .periodCumulativesInside(uint32(params.period), params.tickLower, params.tickUpper);

        // underflow will be protected by sanity check
        secondsPerLiquidityInsideX128 = uint160(
            int160(secondsPerLiquidityInsideX128) - secondsPerLiquidityPeriodStartX128
        );

        secondsPerBoostedLiquidityInsideX128 = uint160(
            int160(secondsPerBoostedLiquidityInsideX128) - secondsPerBoostedLiquidityPeriodStartX128
        );

        BoostInfo storage boostPosition = states.boostInfos[params.period].positions[_positionHash];

        int256 secondsDebtX96 = boostPosition.secondsDebtX96;
        int256 boostedSecondsDebtX96 = boostPosition.boostedSecondsDebtX96;

        // addDelta checks for under and overflows
        periodSecondsInsideX96 = FullMath.mulDiv(liquidity, secondsPerLiquidityInsideX128, FixedPoint32.Q32);

        // Need to check if secondsDebtX96>periodSecondsInsideX96, since rounding can cause underflows
        if (secondsDebtX96 < 0 || periodSecondsInsideX96 > uint256(secondsDebtX96)) {
            periodSecondsInsideX96 = LiquidityMath.addDelta256(periodSecondsInsideX96, -secondsDebtX96);
        } else {
            periodSecondsInsideX96 = 0;
        }

        // addDelta checks for under and overflows
        periodBoostedSecondsInsideX96 = FullMath.mulDiv(
            boostedLiquidity,
            secondsPerBoostedLiquidityInsideX128,
            FixedPoint32.Q32
        );

        // Need to check if secondsDebtX96>periodSecondsInsideX96, since rounding can cause underflows
        if (boostedSecondsDebtX96 < 0 || periodBoostedSecondsInsideX96 > uint256(boostedSecondsDebtX96)) {
            periodBoostedSecondsInsideX96 = LiquidityMath.addDelta256(
                periodBoostedSecondsInsideX96,
                -boostedSecondsDebtX96
            );
        } else {
            periodBoostedSecondsInsideX96 = 0;
        }

        // sanity
        if (periodSecondsInsideX96 > 1 weeks * FixedPoint96.Q96) {
            periodSecondsInsideX96 = 0;
        }

        if (periodBoostedSecondsInsideX96 > 1 weeks * FixedPoint96.Q96) {
            periodBoostedSecondsInsideX96 = 0;
        }
        // require(periodSecondsInsideX96 <= 1 weeks * FixedPoint96.Q96);
        // require(periodBoostedSecondsInsideX96 <= 1 weeks * FixedPoint96.Q96);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.8.0;
pragma abicoder v2;

import './States.sol';
import './TransferHelper.sol';
import '../interfaces/IRamsesV2Factory.sol';
import '../interfaces/pool/IRamsesV2PoolOwnerActions.sol';
import '../interfaces/pool/IRamsesV2PoolEvents.sol';

library ProtocolActions {
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

    event FeeAdjustment(uint24 oldFee, uint24 newFee);

    /// @notice Set the protocol's % share of the fees
    /// @dev Fees start at 50%, with 5% increments
    function setFeeProtocol() external {
        States.PoolStates storage states = States.getStorage();

        uint8 feeProtocolOld = states.slot0.feeProtocol;

        uint8 feeProtocol = IRamsesV2Factory(states.factory).poolFeeProtocol(address(this));

        if (feeProtocol != feeProtocolOld) {
            states.slot0.feeProtocol = feeProtocol;

            emit SetFeeProtocol(feeProtocolOld % 16, feeProtocolOld >> 4, feeProtocol % 16, feeProtocol >> 4);
        }
    }

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
    ) external returns (uint128 amount0, uint128 amount1) {
        States.PoolStates storage states = States.getStorage();
        require(msg.sender == IRamsesV2Factory(states.factory).feeCollector());

        amount0 = amount0Requested > states.protocolFees.token0 ? states.protocolFees.token0 : amount0Requested;
        amount1 = amount1Requested > states.protocolFees.token1 ? states.protocolFees.token1 : amount1Requested;

        if (amount0 > 0) {
            if (amount0 == states.protocolFees.token0) amount0--; // ensure that the slot is not cleared, for gas savings
            states.protocolFees.token0 -= amount0;
            TransferHelper.safeTransfer(states.token0, recipient, amount0);
        }
        if (amount1 > 0) {
            if (amount1 == states.protocolFees.token1) amount1--; // ensure that the slot is not cleared, for gas savings
            states.protocolFees.token1 -= amount1;
            TransferHelper.safeTransfer(states.token1, recipient, amount1);
        }

        emit CollectProtocol(msg.sender, recipient, amount0, amount1);
    }

    function setFee(uint24 _fee) external {
        States.PoolStates storage states = States.getStorage();

        require(msg.sender == states.factory, 'AUTH');
        require(_fee <= 100000);

        uint24 _oldFee = states.fee;
        states.fee = _fee;

        emit FeeAdjustment(_oldFee, _fee);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a uint128, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint128(uint256 y) internal pure returns (uint128 z) {
        require((z = uint128(y)) == y);
    }

    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y);
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2 ** 255);
        z = int256(y);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './LowGasSafeMath.sol';
import './SafeCast.sol';

import './FullMath.sol';
import './UnsafeMath.sol';
import './FixedPoint96.sol';

/// @title Functions based on Q64.96 sqrt price and liquidity
/// @notice Contains the math that uses square root of price as a Q64.96 and liquidity to compute deltas
library SqrtPriceMath {
    using LowGasSafeMath for uint256;
    using SafeCast for uint256;

    /// @notice Gets the next sqrt price given a delta of token0
    /// @dev Always rounds up, because in the exact output case (increasing price) we need to move the price at least
    /// far enough to get the desired output amount, and in the exact input case (decreasing price) we need to move the
    /// price less in order to not send too much output.
    /// The most precise formula for this is liquidity * sqrtPX96 / (liquidity +- amount * sqrtPX96),
    /// if this is impossible because of overflow, we calculate liquidity / (liquidity / sqrtPX96 +- amount).
    /// @param sqrtPX96 The starting price, i.e. before accounting for the token0 delta
    /// @param liquidity The amount of usable liquidity
    /// @param amount How much of token0 to add or remove from virtual reserves
    /// @param add Whether to add or remove the amount of token0
    /// @return The price after adding or removing amount, depending on add
    function getNextSqrtPriceFromAmount0RoundingUp(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amount,
        bool add
    ) internal pure returns (uint160) {
        // we short circuit amount == 0 because the result is otherwise not guaranteed to equal the input price
        if (amount == 0) return sqrtPX96;
        uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;

        if (add) {
            uint256 product;
            if ((product = amount * sqrtPX96) / amount == sqrtPX96) {
                uint256 denominator = numerator1 + product;
                if (denominator >= numerator1)
                    // always fits in 160 bits
                    return uint160(FullMath.mulDivRoundingUp(numerator1, sqrtPX96, denominator));
            }

            return uint160(UnsafeMath.divRoundingUp(numerator1, (numerator1 / sqrtPX96).add(amount)));
        } else {
            uint256 product;
            // if the product overflows, we know the denominator underflows
            // in addition, we must check that the denominator does not underflow
            require((product = amount * sqrtPX96) / amount == sqrtPX96 && numerator1 > product);
            uint256 denominator = numerator1 - product;
            return FullMath.mulDivRoundingUp(numerator1, sqrtPX96, denominator).toUint160();
        }
    }

    /// @notice Gets the next sqrt price given a delta of token1
    /// @dev Always rounds down, because in the exact output case (decreasing price) we need to move the price at least
    /// far enough to get the desired output amount, and in the exact input case (increasing price) we need to move the
    /// price less in order to not send too much output.
    /// The formula we compute is within <1 wei of the lossless version: sqrtPX96 +- amount / liquidity
    /// @param sqrtPX96 The starting price, i.e., before accounting for the token1 delta
    /// @param liquidity The amount of usable liquidity
    /// @param amount How much of token1 to add, or remove, from virtual reserves
    /// @param add Whether to add, or remove, the amount of token1
    /// @return The price after adding or removing `amount`
    function getNextSqrtPriceFromAmount1RoundingDown(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amount,
        bool add
    ) internal pure returns (uint160) {
        // if we're adding (subtracting), rounding down requires rounding the quotient down (up)
        // in both cases, avoid a mulDiv for most inputs
        if (add) {
            uint256 quotient = (
                amount <= type(uint160).max
                    ? (amount << FixedPoint96.RESOLUTION) / liquidity
                    : FullMath.mulDiv(amount, FixedPoint96.Q96, liquidity)
            );

            return uint256(sqrtPX96).add(quotient).toUint160();
        } else {
            uint256 quotient = (
                amount <= type(uint160).max
                    ? UnsafeMath.divRoundingUp(amount << FixedPoint96.RESOLUTION, liquidity)
                    : FullMath.mulDivRoundingUp(amount, FixedPoint96.Q96, liquidity)
            );

            require(sqrtPX96 > quotient);
            // always fits 160 bits
            return uint160(sqrtPX96 - quotient);
        }
    }

    /// @notice Gets the next sqrt price given an input amount of token0 or token1
    /// @dev Throws if price or liquidity are 0, or if the next price is out of bounds
    /// @param sqrtPX96 The starting price, i.e., before accounting for the input amount
    /// @param liquidity The amount of usable liquidity
    /// @param amountIn How much of token0, or token1, is being swapped in
    /// @param zeroForOne Whether the amount in is token0 or token1
    /// @return sqrtQX96 The price after adding the input amount to token0 or token1
    function getNextSqrtPriceFromInput(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amountIn,
        bool zeroForOne
    ) internal pure returns (uint160 sqrtQX96) {
        require(sqrtPX96 > 0);
        require(liquidity > 0);

        // round to make sure that we don't pass the target price
        return
            zeroForOne
                ? getNextSqrtPriceFromAmount0RoundingUp(sqrtPX96, liquidity, amountIn, true)
                : getNextSqrtPriceFromAmount1RoundingDown(sqrtPX96, liquidity, amountIn, true);
    }

    /// @notice Gets the next sqrt price given an output amount of token0 or token1
    /// @dev Throws if price or liquidity are 0 or the next price is out of bounds
    /// @param sqrtPX96 The starting price before accounting for the output amount
    /// @param liquidity The amount of usable liquidity
    /// @param amountOut How much of token0, or token1, is being swapped out
    /// @param zeroForOne Whether the amount out is token0 or token1
    /// @return sqrtQX96 The price after removing the output amount of token0 or token1
    function getNextSqrtPriceFromOutput(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amountOut,
        bool zeroForOne
    ) internal pure returns (uint160 sqrtQX96) {
        require(sqrtPX96 > 0);
        require(liquidity > 0);

        // round to make sure that we pass the target price
        return
            zeroForOne
                ? getNextSqrtPriceFromAmount1RoundingDown(sqrtPX96, liquidity, amountOut, false)
                : getNextSqrtPriceFromAmount0RoundingUp(sqrtPX96, liquidity, amountOut, false);
    }

    /// @notice Gets the amount0 delta between two prices
    /// @dev Calculates liquidity / sqrt(lower) - liquidity / sqrt(upper),
    /// i.e. liquidity * (sqrt(upper) - sqrt(lower)) / (sqrt(upper) * sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up or down
    /// @return amount0 Amount of token0 required to cover a position of size liquidity between the two passed prices
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;
        uint256 numerator2 = sqrtRatioBX96 - sqrtRatioAX96;

        require(sqrtRatioAX96 > 0);

        return
            roundUp
                ? UnsafeMath.divRoundingUp(
                    FullMath.mulDivRoundingUp(numerator1, numerator2, sqrtRatioBX96),
                    sqrtRatioAX96
                )
                : FullMath.mulDiv(numerator1, numerator2, sqrtRatioBX96) / sqrtRatioAX96;
    }

    /// @notice Gets the amount1 delta between two prices
    /// @dev Calculates liquidity * (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up, or down
    /// @return amount1 Amount of token1 required to cover a position of size liquidity between the two passed prices
    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            roundUp
                ? FullMath.mulDivRoundingUp(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96)
                : FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

    /// @notice Helper that gets signed token0 delta
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The change in liquidity for which to compute the amount0 delta
    /// @return amount0 Amount of token0 corresponding to the passed liquidityDelta between the two prices
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        int128 liquidity
    ) internal pure returns (int256 amount0) {
        return
            liquidity < 0
                ? -getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(-liquidity), false).toInt256()
                : getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(liquidity), true).toInt256();
    }

    /// @notice Helper that gets signed token1 delta
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The change in liquidity for which to compute the amount1 delta
    /// @return amount1 Amount of token1 corresponding to the passed liquidityDelta between the two prices
    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        int128 liquidity
    ) internal pure returns (int256 amount1) {
        return
            liquidity < 0
                ? -getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(-liquidity), false).toInt256()
                : getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(liquidity), true).toInt256();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.9.0;

import './../interfaces/IERC20Minimal.sol';

struct Slot0 {
    // the current price
    uint160 sqrtPriceX96;
    // the current tick
    int24 tick;
    // the most-recently updated index of the observations array
    uint16 observationIndex;
    // the current maximum number of observations that are being stored
    uint16 observationCardinality;
    // the next maximum number of observations to store, triggered in observations.write
    uint16 observationCardinalityNext;
    // the current protocol fee as a percentage of the swap fee taken on withdrawal
    // represented as an integer denominator (1/x)%
    uint8 feeProtocol;
    // whether the pool is locked
    bool unlocked;
}

struct Observation {
    // the block timestamp of the observation
    uint32 blockTimestamp;
    // the tick accumulator, i.e. tick * time elapsed since the pool was first initialized
    int56 tickCumulative;
    // the seconds per liquidity, i.e. seconds elapsed / max(1, liquidity) since the pool was first initialized
    uint160 secondsPerLiquidityCumulativeX128;
    // whether or not the observation is initialized
    bool initialized;
    // see secondsPerLiquidityCumulativeX128 but with boost, only valid if timestamp < new period
    // recorded at the end to not breakup struct slot
    uint160 secondsPerBoostedLiquidityPeriodX128;
    // the seconds boosted positions were in range in this period
    uint32 boostedInRange;
}

// info stored for each user's position
struct PositionInfo {
    // the amount of liquidity owned by this position
    uint128 liquidity;
    // fee growth per unit of liquidity as of the last update to liquidity or fees owed
    uint256 feeGrowthInside0LastX128;
    uint256 feeGrowthInside1LastX128;
    // the fees owed to the position owner in token0/token1
    uint128 tokensOwed0;
    uint128 tokensOwed1;
    uint256 attachedVeRamId;
}

struct PeriodBoostInfo {
    // the total amount of boost this period has
    uint128 totalBoostAmount;
    // the total amount of veRam attached to this period
    int128 totalVeRamAmount;
    // individual positions' boost info for this period
    mapping(bytes32 => BoostInfo) positions;
    // how a veRam NFT has been attached to this pool
    mapping(uint256 => VeRamInfo) veRamInfos;
}

struct VeRamInfo {
    // how many times a veRAM NFT has been attached to this pool
    uint128 timesAttached;
    // boost ratio used, out of 1e18
    uint128 veRamBoostUsedRatio;
    // how much boost ratio is used by each position
    mapping(bytes32 => uint256) positionBoostUsedRatio;
}

struct BoostInfo {
    // the amount of boost this position has for this period
    uint128 boostAmount;
    // the amount of veRam attached to this position for this period
    int128 veRamAmount;
    // used to account for changes in the boostAmount and veRam locked during the period
    int256 boostedSecondsDebtX96;
    // used to account for changes in the deposit amount
    int256 secondsDebtX96;
    // used to check if starting seconds have already been written
    bool initialized;
    // used to account for changes in secondsPerLiquidity
    int160 secondsPerLiquidityPeriodStartX128;
    int160 secondsPerBoostedLiquidityPeriodStartX128;
}

// info stored for each initialized individual tick
struct TickInfo {
    // the total position liquidity that references this tick
    uint128 liquidityGross;
    // amount of net liquidity added (subtracted) when tick is crossed from left to right (right to left),
    int128 liquidityNet;
    // the total position boosted liquidity that references this tick
    uint128 cleanUnusedSlot;
    // clean unused slot
    int128 cleanUnusedSlot2;
    // fee growth per unit of liquidity on the _other_ side of this tick (relative to the current tick)
    // only has relative meaning, not absolute — the value depends on when the tick is initialized
    uint256 feeGrowthOutside0X128;
    uint256 feeGrowthOutside1X128;
    // the cumulative tick value on the other side of the tick
    int56 tickCumulativeOutside;
    // the seconds per unit of liquidity on the _other_ side of this tick (relative to the current tick)
    // only has relative meaning, not absolute — the value depends on when the tick is initialized
    uint160 secondsPerLiquidityOutsideX128;
    // the seconds spent on the other side of the tick (relative to the current tick)
    // only has relative meaning, not absolute — the value depends on when the tick is initialized
    uint32 secondsOutside;
    // true iff the tick is initialized, i.e. the value is exactly equivalent to the expression liquidityGross != 0
    // these 8 bits are set to prevent fresh sstores when crossing newly initialized ticks
    bool initialized;
    // secondsPerLiquidityOutsideX128 separated into periods, placed here to preserve struct slots
    mapping(uint256 => uint256) periodSecondsPerLiquidityOutsideX128;
    // see secondsPerLiquidityOutsideX128, for boosted liquidity
    mapping(uint256 => uint256) periodSecondsPerBoostedLiquidityOutsideX128;
    // the total position boosted liquidity that references this tick
    mapping(uint256 => uint128) boostedLiquidityGross;
    // period amount of net boosted liquidity added (subtracted) when tick is crossed from left to right (right to left),
    mapping(uint256 => int128) boostedLiquidityNet;
}

// info stored for each period
struct PeriodInfo {
    uint32 previousPeriod;
    int24 startTick;
    int24 lastTick;
    uint160 endSecondsPerLiquidityPeriodX128;
    uint160 endSecondsPerBoostedLiquidityPeriodX128;
    uint32 boostedInRange;
}

// accumulated protocol fees in token0/token1 units
struct ProtocolFees {
    uint128 token0;
    uint128 token1;
}

// Position period and liquidity
struct PositionCheckpoint {
    uint256 period;
    uint256 liquidity;
}

library States {
    bytes32 public constant STATES_SLOT = keccak256('states.storage');

    struct PoolStates {
        address factory;
        address nfpManager;
        address veRam;
        address voter;
        address token0;
        address token1;
        uint24 fee;
        int24 tickSpacing;
        uint128 maxLiquidityPerTick;
        Slot0 slot0;
        mapping(uint256 => PeriodInfo) periods;
        uint256 lastPeriod;
        uint256 feeGrowthGlobal0X128;
        uint256 feeGrowthGlobal1X128;
        ProtocolFees protocolFees;
        uint128 liquidity;
        uint128 boostedLiquidity;
        mapping(int24 => TickInfo) _ticks;
        mapping(int16 => uint256) tickBitmap;
        mapping(bytes32 => PositionInfo) positions;
        mapping(uint256 => PeriodBoostInfo) boostInfos;
        mapping(bytes32 => uint256) cleanUnusedSlot;
        Observation[65535] observations;
        mapping(bytes32 => PositionCheckpoint[]) positionCheckpoints;
        uint24 initialFee;
    }

    // Return state storage struct for reading and writing
    function getStorage() internal pure returns (PoolStates storage storageStruct) {
        bytes32 position = STATES_SLOT;
        assembly {
            storageStruct.slot := position
        }
    }

    /// @dev Returns the block timestamp truncated to 32 bits, i.e. mod 2**32. This method is overridden in tests.
    function _blockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp); // truncation is desired
    }

    /// @dev Get the pool's balance of token0
    /// @dev This function is gas optimized to avoid a redundant extcodesize check in addition to the returndatasize
    /// check
    function balance0() internal view returns (uint256) {
        PoolStates storage states = getStorage();

        (bool success, bytes memory data) = states.token0.staticcall(
            abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, address(this))
        );
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }

    /// @dev Get the pool's balance of token1
    /// @dev This function is gas optimized to avoid a redundant extcodesize check in addition to the returndatasize
    /// check
    function balance1() internal view returns (uint256) {
        PoolStates storage states = getStorage();

        (bool success, bytes memory data) = states.token1.staticcall(
            abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, address(this))
        );
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './FullMath.sol';
import './SqrtPriceMath.sol';

/// @title Computes the result of a swap within ticks
/// @notice Contains methods for computing the result of a swap within a single tick price range, i.e., a single tick.
library SwapMath {
    /// @notice Computes the result of swapping some amount in, or amount out, given the parameters of the swap
    /// @dev The fee, plus the amount in, will never exceed the amount remaining if the swap's `amountSpecified` is positive
    /// @param sqrtRatioCurrentX96 The current sqrt price of the pool
    /// @param sqrtRatioTargetX96 The price that cannot be exceeded, from which the direction of the swap is inferred
    /// @param liquidity The usable liquidity
    /// @param amountRemaining How much input or output amount is remaining to be swapped in/out
    /// @param feePips The fee taken from the input amount, expressed in hundredths of a bip
    /// @return sqrtRatioNextX96 The price after swapping the amount in/out, not to exceed the price target
    /// @return amountIn The amount to be swapped in, of either token0 or token1, based on the direction of the swap
    /// @return amountOut The amount to be received, of either token0 or token1, based on the direction of the swap
    /// @return feeAmount The amount of input that will be taken as a fee
    function computeSwapStep(
        uint160 sqrtRatioCurrentX96,
        uint160 sqrtRatioTargetX96,
        uint128 liquidity,
        int256 amountRemaining,
        uint24 feePips
    )
        internal
        pure
        returns (
            uint160 sqrtRatioNextX96,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount
        )
    {
        bool zeroForOne = sqrtRatioCurrentX96 >= sqrtRatioTargetX96;
        bool exactIn = amountRemaining >= 0;

        if (exactIn) {
            uint256 amountRemainingLessFee = FullMath.mulDiv(uint256(amountRemaining), 1e6 - feePips, 1e6);
            amountIn = zeroForOne
                ? SqrtPriceMath.getAmount0Delta(sqrtRatioTargetX96, sqrtRatioCurrentX96, liquidity, true)
                : SqrtPriceMath.getAmount1Delta(sqrtRatioCurrentX96, sqrtRatioTargetX96, liquidity, true);
            if (amountRemainingLessFee >= amountIn) sqrtRatioNextX96 = sqrtRatioTargetX96;
            else
                sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromInput(
                    sqrtRatioCurrentX96,
                    liquidity,
                    amountRemainingLessFee,
                    zeroForOne
                );
        } else {
            amountOut = zeroForOne
                ? SqrtPriceMath.getAmount1Delta(sqrtRatioTargetX96, sqrtRatioCurrentX96, liquidity, false)
                : SqrtPriceMath.getAmount0Delta(sqrtRatioCurrentX96, sqrtRatioTargetX96, liquidity, false);
            if (uint256(-amountRemaining) >= amountOut) sqrtRatioNextX96 = sqrtRatioTargetX96;
            else
                sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromOutput(
                    sqrtRatioCurrentX96,
                    liquidity,
                    uint256(-amountRemaining),
                    zeroForOne
                );
        }

        bool max = sqrtRatioTargetX96 == sqrtRatioNextX96;

        // get the input/output amounts
        if (zeroForOne) {
            amountIn = max && exactIn
                ? amountIn
                : SqrtPriceMath.getAmount0Delta(sqrtRatioNextX96, sqrtRatioCurrentX96, liquidity, true);
            amountOut = max && !exactIn
                ? amountOut
                : SqrtPriceMath.getAmount1Delta(sqrtRatioNextX96, sqrtRatioCurrentX96, liquidity, false);
        } else {
            amountIn = max && exactIn
                ? amountIn
                : SqrtPriceMath.getAmount1Delta(sqrtRatioCurrentX96, sqrtRatioNextX96, liquidity, true);
            amountOut = max && !exactIn
                ? amountOut
                : SqrtPriceMath.getAmount0Delta(sqrtRatioCurrentX96, sqrtRatioNextX96, liquidity, false);
        }

        // cap the output amount to not exceed the remaining output amount
        if (!exactIn && amountOut > uint256(-amountRemaining)) {
            amountOut = uint256(-amountRemaining);
        }

        if (exactIn && sqrtRatioNextX96 != sqrtRatioTargetX96) {
            // we didn't reach the target, so take the remainder of the maximum input as fee
            feeAmount = uint256(amountRemaining) - amountIn;
        } else {
            feeAmount = FullMath.mulDivRoundingUp(amountIn, feePips, 1e6 - feePips);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.8.0;
pragma abicoder v2;

import './LowGasSafeMath.sol';
import './SafeCast.sol';

import './TickMath.sol';
import './LiquidityMath.sol';
import './States.sol';

/// @title Tick
/// @notice Contains functions for managing tick processes and relevant calculations
library Tick {
    using LowGasSafeMath for int256;
    using SafeCast for int256;

    /// @notice Derives max liquidity per tick from given tick spacing
    /// @dev Executed within the pool constructor
    /// @param tickSpacing The amount of required tick separation, realized in multiples of `tickSpacing`
    ///     e.g., a tickSpacing of 3 requires ticks to be initialized every 3rd tick i.e., ..., -6, -3, 0, 3, 6, ...
    /// @return The max liquidity per tick
    function tickSpacingToMaxLiquidityPerTick(int24 tickSpacing) external pure returns (uint128) {
        int24 minTick = (TickMath.MIN_TICK / tickSpacing) * tickSpacing;
        int24 maxTick = (TickMath.MAX_TICK / tickSpacing) * tickSpacing;
        uint24 numTicks = uint24((maxTick - minTick) / tickSpacing) + 1;
        return type(uint128).max / numTicks;
    }

    /// @notice Retrieves fee growth data
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param tickLower The lower tick boundary of the position
    /// @param tickUpper The upper tick boundary of the position
    /// @param tickCurrent The current tick
    /// @param feeGrowthGlobal0X128 The all-time global fee growth, per unit of liquidity, in token0
    /// @param feeGrowthGlobal1X128 The all-time global fee growth, per unit of liquidity, in token1
    /// @return feeGrowthInside0X128 The all-time fee growth in token0, per unit of liquidity, inside the position's tick boundaries
    /// @return feeGrowthInside1X128 The all-time fee growth in token1, per unit of liquidity, inside the position's tick boundaries
    function getFeeGrowthInside(
        mapping(int24 => TickInfo) storage self,
        int24 tickLower,
        int24 tickUpper,
        int24 tickCurrent,
        uint256 feeGrowthGlobal0X128,
        uint256 feeGrowthGlobal1X128
    ) internal view returns (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) {
        TickInfo storage lower = self[tickLower];
        TickInfo storage upper = self[tickUpper];

        // calculate fee growth below
        uint256 feeGrowthBelow0X128;
        uint256 feeGrowthBelow1X128;
        if (tickCurrent >= tickLower) {
            feeGrowthBelow0X128 = lower.feeGrowthOutside0X128;
            feeGrowthBelow1X128 = lower.feeGrowthOutside1X128;
        } else {
            feeGrowthBelow0X128 = feeGrowthGlobal0X128 - lower.feeGrowthOutside0X128;
            feeGrowthBelow1X128 = feeGrowthGlobal1X128 - lower.feeGrowthOutside1X128;
        }

        // calculate fee growth above
        uint256 feeGrowthAbove0X128;
        uint256 feeGrowthAbove1X128;
        if (tickCurrent < tickUpper) {
            feeGrowthAbove0X128 = upper.feeGrowthOutside0X128;
            feeGrowthAbove1X128 = upper.feeGrowthOutside1X128;
        } else {
            feeGrowthAbove0X128 = feeGrowthGlobal0X128 - upper.feeGrowthOutside0X128;
            feeGrowthAbove1X128 = feeGrowthGlobal1X128 - upper.feeGrowthOutside1X128;
        }

        feeGrowthInside0X128 = feeGrowthGlobal0X128 - feeGrowthBelow0X128 - feeGrowthAbove0X128;
        feeGrowthInside1X128 = feeGrowthGlobal1X128 - feeGrowthBelow1X128 - feeGrowthAbove1X128;
    }

    /// @notice Retrieves fee growth data
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param tickLower The lower tick boundary of the position
    /// @param tickUpper The upper tick boundary of the position
    /// @param tickCurrent The current tick
    /// @param endSecondsPerBoostedLiquidityPeriodX128 The seconds in range, per unit of liquidity
    /// @param period The period's timestamp
    /// @return secondsInsidePerBoostedLiquidityX128 The seconds per unit of liquidity, inside the position's tick boundaries
    function getSecondsInsidePerBoostedLiquidity(
        mapping(int24 => TickInfo) storage self,
        int24 tickLower,
        int24 tickUpper,
        int24 tickCurrent,
        uint256 endSecondsPerBoostedLiquidityPeriodX128,
        uint256 period
    ) external view returns (uint256 secondsInsidePerBoostedLiquidityX128) {
        TickInfo storage lower = self[tickLower];
        TickInfo storage upper = self[tickUpper];

        // calculate secondInside growth below
        uint256 secondsInsidePerBoostedLiquidityBelowX128;
        if (tickCurrent >= tickLower) {
            secondsInsidePerBoostedLiquidityBelowX128 = lower.periodSecondsPerBoostedLiquidityOutsideX128[period];
        } else {
            secondsInsidePerBoostedLiquidityBelowX128 =
                endSecondsPerBoostedLiquidityPeriodX128 -
                lower.periodSecondsPerBoostedLiquidityOutsideX128[period];
        }

        // calculate secondsInside growth above
        uint256 secondsInsidePerBoostedLiquidityAboveX128;
        if (tickCurrent < tickUpper) {
            secondsInsidePerBoostedLiquidityAboveX128 = upper.periodSecondsPerBoostedLiquidityOutsideX128[period];
        } else {
            secondsInsidePerBoostedLiquidityAboveX128 =
                endSecondsPerBoostedLiquidityPeriodX128 -
                upper.periodSecondsPerBoostedLiquidityOutsideX128[period];
        }

        secondsInsidePerBoostedLiquidityX128 =
            endSecondsPerBoostedLiquidityPeriodX128 -
            secondsInsidePerBoostedLiquidityBelowX128 -
            secondsInsidePerBoostedLiquidityAboveX128;
    }

    struct UpdateTickParams {
        // the tick that will be updated
        int24 tick;
        // the current tick
        int24 tickCurrent;
        // a new amount of liquidity to be added (subtracted) when tick is crossed from left to right (right to left)
        int128 liquidityDelta;
        // a new amount of boosted liquidity to be added (subtracted) when tick is crossed from left to right (right to left)
        int128 boostedLiquidityDelta;
        // the all-time global fee growth, per unit of liquidity, in token0
        uint256 feeGrowthGlobal0X128;
        // the all-time global fee growth, per unit of liquidity, in token1
        uint256 feeGrowthGlobal1X128;
        // The all-time seconds per max(1, liquidity) of the pool
        uint160 secondsPerLiquidityCumulativeX128;
        // The period seconds per max(1, boostedLiquidity) of the pool
        uint160 secondsPerBoostedLiquidityPeriodX128;
        // the tick * time elapsed since the pool was first initialized
        int56 tickCumulative;
        // the current block timestamp cast to a uint32
        uint32 time;
        // true for updating a position's upper tick, or false for updating a position's lower tick
        bool upper;
        // the maximum liquidity allocation for a single tick
        uint128 maxLiquidity;
    }

    /// @notice Updates a tick and returns true if the tick was flipped from initialized to uninitialized, or vice versa
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param params the tick details and changes
    /// @return flipped Whether the tick was flipped from initialized to uninitialized, or vice versa
    function update(
        mapping(int24 => TickInfo) storage self,
        UpdateTickParams memory params
    ) internal returns (bool flipped) {
        TickInfo storage info = self[params.tick];

        uint128 liquidityGrossBefore = info.liquidityGross;
        uint128 liquidityGrossAfter = LiquidityMath.addDelta(liquidityGrossBefore, params.liquidityDelta);

        require(liquidityGrossAfter <= params.maxLiquidity, 'LO');

        flipped = (liquidityGrossAfter == 0) != (liquidityGrossBefore == 0);

        if (liquidityGrossBefore == 0) {
            // by convention, we assume that all growth before a tick was initialized happened _below_ the tick
            if (params.tick <= params.tickCurrent) {
                info.feeGrowthOutside0X128 = params.feeGrowthGlobal0X128;
                info.feeGrowthOutside1X128 = params.feeGrowthGlobal1X128;
                info.secondsPerLiquidityOutsideX128 = params.secondsPerLiquidityCumulativeX128;
                info.tickCumulativeOutside = params.tickCumulative;
                info.secondsOutside = params.time;
            }
            info.initialized = true;
        }

        info.liquidityGross = liquidityGrossAfter;
        info.boostedLiquidityGross[params.time / 1 weeks] = LiquidityMath.addDelta(
            info.boostedLiquidityGross[params.time / 1 weeks],
            params.boostedLiquidityDelta
        );

        // when the lower (upper) tick is crossed left to right (right to left), liquidity must be added (removed)
        info.liquidityNet = params.upper
            ? int256(info.liquidityNet).sub(params.liquidityDelta).toInt128()
            : int256(info.liquidityNet).add(params.liquidityDelta).toInt128();

        // when the lower (upper) tick is crossed left to right (right to left), liquidity must be added (removed)
        info.boostedLiquidityNet[params.time / 1 weeks] = params.upper
            ? int256(info.boostedLiquidityNet[params.time / 1 weeks]).sub(params.boostedLiquidityDelta).toInt128()
            : int256(info.boostedLiquidityNet[params.time / 1 weeks]).add(params.boostedLiquidityDelta).toInt128();
    }

    /// @notice Clears tick data
    /// @param self The mapping containing all initialized tick information for initialized ticks
    /// @param tick The tick that will be cleared
    function clear(mapping(int24 => TickInfo) storage self, int24 tick) internal {
        delete self[tick];
    }

    struct CrossParams {
        // The destination tick of the transition
        int24 tick;
        // The all-time global fee growth, per unit of liquidity, in token0
        uint256 feeGrowthGlobal0X128;
        // The all-time global fee growth, per unit of liquidity, in token1
        uint256 feeGrowthGlobal1X128;
        // The current seconds per liquidity
        uint160 secondsPerLiquidityCumulativeX128;
        // The current seconds per boosted liquidity
        uint160 secondsPerBoostedLiquidityCumulativeX128;
        // The previous period end's seconds per liquidity
        uint256 endSecondsPerLiquidityPeriodX128;
        // The previous period end's seconds per boosted liquidity
        uint256 endSecondsPerBoostedLiquidityPeriodX128;
        // The starting tick of the period
        int24 periodStartTick;
        // The tick * time elapsed since the pool was first initialized
        int56 tickCumulative;
        // The current block.timestamp
        uint32 time;
    }

    /// @notice Transitions to next tick as needed by price movement
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param params Structured cross params
    /// @return liquidityNet The amount of liquidity added (subtracted) when tick is crossed from left to right (right to left)
    /// @return boostedLiquidityNet The amount of liquidity added (subtracted) when tick is crossed from left to right (right to left)
    function cross(
        mapping(int24 => TickInfo) storage self,
        CrossParams calldata params
    ) external returns (int128 liquidityNet, int128 boostedLiquidityNet) {
        TickInfo storage info = self[params.tick];
        uint256 period = params.time / 1 weeks;

        info.feeGrowthOutside0X128 = params.feeGrowthGlobal0X128 - info.feeGrowthOutside0X128;
        info.feeGrowthOutside1X128 = params.feeGrowthGlobal1X128 - info.feeGrowthOutside1X128;
        info.secondsPerLiquidityOutsideX128 =
            params.secondsPerLiquidityCumulativeX128 -
            info.secondsPerLiquidityOutsideX128;

        {
            uint256 periodSecondsPerLiquidityOutsideX128;
            uint256 periodSecondsPerLiquidityOutsideBeforeX128 = info.periodSecondsPerLiquidityOutsideX128[period];
            if (params.tick <= params.periodStartTick && periodSecondsPerLiquidityOutsideBeforeX128 == 0) {
                periodSecondsPerLiquidityOutsideX128 =
                    params.secondsPerLiquidityCumulativeX128 -
                    periodSecondsPerLiquidityOutsideBeforeX128 -
                    params.endSecondsPerLiquidityPeriodX128;
            } else {
                periodSecondsPerLiquidityOutsideX128 =
                    params.secondsPerLiquidityCumulativeX128 -
                    periodSecondsPerLiquidityOutsideBeforeX128;
            }
            info.periodSecondsPerLiquidityOutsideX128[period] = periodSecondsPerLiquidityOutsideX128;
        }
        {
            uint256 periodSecondsPerBoostedLiquidityOutsideX128;
            uint256 periodSecondsPerBoostedLiquidityOutsideBeforeX128 = info
                .periodSecondsPerBoostedLiquidityOutsideX128[period];
            if (params.tick <= params.periodStartTick && periodSecondsPerBoostedLiquidityOutsideBeforeX128 == 0) {
                periodSecondsPerBoostedLiquidityOutsideX128 =
                    params.secondsPerBoostedLiquidityCumulativeX128 -
                    periodSecondsPerBoostedLiquidityOutsideBeforeX128 -
                    params.endSecondsPerBoostedLiquidityPeriodX128;
            } else {
                periodSecondsPerBoostedLiquidityOutsideX128 =
                    params.secondsPerBoostedLiquidityCumulativeX128 -
                    periodSecondsPerBoostedLiquidityOutsideBeforeX128;
            }

            info.periodSecondsPerBoostedLiquidityOutsideX128[period] = periodSecondsPerBoostedLiquidityOutsideX128;
        }
        info.tickCumulativeOutside = params.tickCumulative - info.tickCumulativeOutside;
        info.secondsOutside = params.time - info.secondsOutside;
        liquidityNet = info.liquidityNet;
        boostedLiquidityNet = info.boostedLiquidityNet[period];
    }

    /// @dev Common checks for valid tick inputs.
    function checkTicks(int24 tickLower, int24 tickUpper) external pure {
        require(tickLower < tickUpper, 'TLU');
        require(tickLower >= TickMath.MIN_TICK, 'TLM');
        require(tickUpper <= TickMath.MAX_TICK, 'TUM');
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <=0.7.6;

import './BitMath.sol';

/// @title Packed tick initialized state library
/// @notice Stores a packed mapping of tick index to its initialized state
/// @dev The mapping uses int16 for keys since ticks are represented as int24 and there are 256 (2^8) values per word.
library TickBitmap {
    /// @notice Computes the position in the mapping where the initialized bit for a tick lives
    /// @param tick The tick for which to compute the position
    /// @return wordPos The key in the mapping containing the word in which the bit is stored
    /// @return bitPos The bit position in the word where the flag is stored
    function position(int24 tick) private pure returns (int16 wordPos, uint8 bitPos) {
        wordPos = int16(tick >> 8);
        bitPos = uint8(tick % 256);
    }

    /// @notice Flips the initialized state for a given tick from false to true, or vice versa
    /// @param self The mapping in which to flip the tick
    /// @param tick The tick to flip
    /// @param tickSpacing The spacing between usable ticks
    function flipTick(mapping(int16 => uint256) storage self, int24 tick, int24 tickSpacing) internal {
        require(tick % tickSpacing == 0); // ensure that the tick is spaced
        (int16 wordPos, uint8 bitPos) = position(tick / tickSpacing);
        uint256 mask = 1 << bitPos;
        self[wordPos] ^= mask;
    }

    /// @notice Returns the next initialized tick contained in the same word (or adjacent word) as the tick that is either
    /// to the left (less than or equal to) or right (greater than) of the given tick
    /// @param self The mapping in which to compute the next initialized tick
    /// @param tick The starting tick
    /// @param tickSpacing The spacing between usable ticks
    /// @param lte Whether to search for the next initialized tick to the left (less than or equal to the starting tick)
    /// @return next The next initialized or uninitialized tick up to 256 ticks away from the current tick
    /// @return initialized Whether the next tick is initialized, as the function only searches within up to 256 ticks
    function nextInitializedTickWithinOneWord(
        mapping(int16 => uint256) storage self,
        int24 tick,
        int24 tickSpacing,
        bool lte
    ) internal view returns (int24 next, bool initialized) {
        int24 compressed = tick / tickSpacing;
        if (tick < 0 && tick % tickSpacing != 0) compressed--; // round towards negative infinity

        if (lte) {
            (int16 wordPos, uint8 bitPos) = position(compressed);
            // all the 1s at or to the right of the current bitPos
            uint256 mask = (1 << bitPos) - 1 + (1 << bitPos);
            uint256 masked = self[wordPos] & mask;

            // if there are no initialized ticks to the right of or at the current tick, return rightmost in the word
            initialized = masked != 0;
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            next = initialized
                ? (compressed - int24(bitPos - BitMath.mostSignificantBit(masked))) * tickSpacing
                : (compressed - int24(bitPos)) * tickSpacing;
        } else {
            // start from the word of the next tick, since the current tick state doesn't matter
            (int16 wordPos, uint8 bitPos) = position(compressed + 1);
            // all the 1s at or to the left of the bitPos
            uint256 mask = ~((1 << bitPos) - 1);
            uint256 masked = self[wordPos] & mask;

            // if there are no initialized ticks to the left of the current tick, return leftmost in the word
            initialized = masked != 0;
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            next = initialized
                ? (compressed + 1 + int24(BitMath.leastSignificantBit(masked) - bitPos)) * tickSpacing
                : (compressed + 1 + int24(type(uint8).max - bitPos)) * tickSpacing;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.8.0;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '../interfaces/IERC20Minimal.sol';

/// @title TransferHelper
/// @notice Contains helper methods for interacting with ERC20 tokens that do not consistently return true/false
library TransferHelper {
    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Calls transfer on token contract, errors with TF if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20Minimal.transfer.selector, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TF');
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math functions that do not check inputs or outputs
/// @notice Contains methods that perform common math functions but do not do any overflow or underflow checks
library UnsafeMath {
    /// @notice Returns ceil(x / y)
    /// @dev division by 0 has unspecified behavior, and must be checked externally
    /// @param x The dividend
    /// @param y The divisor
    /// @return z The quotient, ceil(x / y)
    function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import "./interfaces/IRamsesV2Factory.sol";

import "./RamsesV2PoolDeployer.sol";

import "./RamsesV2Pool.sol";

import "../interfaces/IVoter.sol";

import "@openzeppelin-3.4.1/contracts/proxy/Initializable.sol";

/// @title Canonical Ramses V2 factory
/// @notice Deploys Ramses V2 pools and manages ownership and control over pool protocol fees
contract RamsesV2Factory is
    IRamsesV2Factory,
    RamsesV2PoolDeployer,
    Initializable
{
    bytes32 public constant POOL_INIT_CODE_HASH =
        0x1565b129f2d1790f12d45301b9b084335626f0c92410bc43130763b69971135d;

    /// @inheritdoc IRamsesV2Factory
    address public override owner;
    /// @inheritdoc IRamsesV2Factory
    address public override nfpManager;
    /// @inheritdoc IRamsesV2Factory
    address public override veRam;
    /// @inheritdoc IRamsesV2Factory
    address public override voter;

    /// @inheritdoc IRamsesV2Factory
    mapping(uint24 => int24) public override feeAmountTickSpacing;
    /// @inheritdoc IRamsesV2Factory
    mapping(address => mapping(address => mapping(uint24 => address)))
        public
        override getPool;

    /// @inheritdoc IRamsesV2Factory
    address public override feeCollector;

    /// @inheritdoc IRamsesV2Factory
    uint8 public override feeProtocol;

    // pool specific fee protocol if set
    mapping(address => uint8) _poolFeeProtocol;

    address public feeSetter;

    /// @dev prevents implementation from being initialized later
    constructor() initializer() {}

    function initialize(
        address _nfpManager,
        address _veRam,
        address _voter,
        address _implementation
    ) public initializer {
        owner = msg.sender;
        nfpManager = _nfpManager;
        veRam = _veRam;
        voter = _voter;
        implementation = _implementation;

        emit OwnerChanged(address(0), msg.sender);

        feeAmountTickSpacing[100] = 1;
        emit FeeAmountEnabled(100, 1);
        feeAmountTickSpacing[500] = 10;
        emit FeeAmountEnabled(500, 10);
        feeAmountTickSpacing[3000] = 60;
        emit FeeAmountEnabled(3000, 60);
        feeAmountTickSpacing[10000] = 200;
        emit FeeAmountEnabled(10000, 200);
    }

    function setFeeSetter(address _newFeeSetter) external {
        require(msg.sender == feeSetter, "AUTH");
        emit FeeSetterChanged(feeSetter, _newFeeSetter);
        feeSetter = _newFeeSetter;
    }

    function setFee(address _pool, uint24 _fee) external override {
        require(msg.sender == feeSetter, "AUTH");

        IRamsesV2Pool(_pool).setFee(_fee);
    }

    /// @inheritdoc IRamsesV2Factory
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external override returns (address pool) {
        require(tokenA != tokenB, "IT");
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "A0");
        int24 tickSpacing = feeAmountTickSpacing[fee];
        require(tickSpacing != 0, "T0");
        require(getPool[token0][token1][fee] == address(0), "PE");
        pool = _deploy(
            address(this),
            nfpManager,
            veRam,
            voter,
            token0,
            token1,
            fee,
            tickSpacing
        );
        getPool[token0][token1][fee] = pool;
        // populate mapping in the reverse direction, deliberate choice to avoid the cost of comparing addresses
        getPool[token1][token0][fee] = pool;
        emit PoolCreated(token0, token1, fee, tickSpacing, pool);
    }

    /// @inheritdoc IRamsesV2Factory
    function setOwner(address _owner) external override {
        require(msg.sender == owner, "AUTH");
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }

    /// @inheritdoc IRamsesV2Factory
    function enableFeeAmount(uint24 fee, int24 tickSpacing) public override {
        require(msg.sender == owner, "AUTH");
        require(fee < 1000000);
        // tick spacing is capped at 16384 to prevent the situation where tickSpacing is so large that
        // TickBitmap#nextInitializedTickWithinOneWord overflows int24 container from a valid tick
        // 16384 ticks represents a >5x price change with ticks of 1 bips
        require(tickSpacing > 0 && tickSpacing < 16384);
        require(feeAmountTickSpacing[fee] == 0);

        feeAmountTickSpacing[fee] = tickSpacing;
        emit FeeAmountEnabled(fee, tickSpacing);
    }

    /// @dev Sets implementation for beacon proxies
    /// @param _implementation new implementation address
    function setImplementation(address _implementation) external {
        require(msg.sender == owner, "AUTH");
        emit ImplementationChanged(implementation, _implementation);
        implementation = _implementation;
    }

    /// @inheritdoc IRamsesV2Factory
    function setFeeCollector(address _feeCollector) external override {
        require(msg.sender == owner, "AUTH");

        emit FeeCollectorChanged(feeCollector, _feeCollector);
        feeCollector = _feeCollector;
    }

    /// @inheritdoc IRamsesV2Factory
    function setFeeProtocol(uint8 _feeProtocol) external override {
        require(msg.sender == feeSetter, "AUTH");

        require(_feeProtocol <= 10, "FTL");

        uint8 feeProtocolOld = feeProtocol;

        feeProtocol = _feeProtocol + (_feeProtocol << 4);

        emit SetFeeProtocol(
            feeProtocolOld % 16,
            feeProtocolOld >> 4,
            feeProtocol,
            feeProtocol
        );
    }

    /// @inheritdoc IRamsesV2Factory
    function setPoolFeeProtocol(
        address pool,
        uint8 feeProtocol0,
        uint8 feeProtocol1
    ) external override {
        require(msg.sender == feeSetter, "AUTH");

        require((feeProtocol0 <= 10) && (feeProtocol1 <= 10), "FTL");

        uint8 feeProtocolOld = poolFeeProtocol(pool);

        _poolFeeProtocol[pool] = feeProtocol0 + (feeProtocol1 << 4);

        emit SetPoolFeeProtocol(
            pool,
            feeProtocolOld % 16,
            feeProtocolOld >> 4,
            feeProtocol0,
            feeProtocol1
        );

        IRamsesV2Pool(pool).setFeeProtocol();
    }

    function setPoolFeeProtocol(
        address pool,
        uint8 _feeProtocol
    ) external override {
        require(msg.sender == feeSetter, "AUTH");

        require(_feeProtocol <= 10, "FTL");

        uint8 feeProtocolOld = poolFeeProtocol(pool);

        _poolFeeProtocol[pool] = _feeProtocol;

        emit SetPoolFeeProtocol(
            pool,
            feeProtocolOld % 16,
            feeProtocolOld >> 4,
            _feeProtocol % 16,
            _feeProtocol >> 4
        );
        IRamsesV2Pool(pool).setFeeProtocol();
    }

    /// @inheritdoc IRamsesV2Factory
    function poolFeeProtocol(
        address pool
    ) public view override returns (uint8 __poolFeeProtocol) {
        if (IVoter(voter).gauges(pool) == address(0)) {
            return 0;
        }

        __poolFeeProtocol = _poolFeeProtocol[pool];

        if (__poolFeeProtocol == 0) {
            __poolFeeProtocol = feeProtocol;
        }

        return __poolFeeProtocol;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import "./interfaces/IRamsesV2Pool.sol";

import "./libraries/LowGasSafeMath.sol";
import "./libraries/SafeCast.sol";
import "./libraries/Tick.sol";
import "./libraries/TickBitmap.sol";
import "./libraries/Position.sol";
import "./libraries/Oracle.sol";
import "./libraries/States.sol";
import "./libraries/ProtocolActions.sol";

import "./libraries/FullMath.sol";
import "./libraries/FixedPoint128.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/TickMath.sol";
import "./libraries/LiquidityMath.sol";
import "./libraries/SqrtPriceMath.sol";
import "./libraries/SwapMath.sol";

import "./interfaces/IRamsesV2PoolDeployer.sol";
import "./interfaces/IRamsesV2Factory.sol";
import "./interfaces/callback/IRamsesV2MintCallback.sol";
import "./interfaces/callback/IRamsesV2SwapCallback.sol";
import "./interfaces/callback/IRamsesV2FlashCallback.sol";

import "./../interfaces/IVotingEscrow.sol";
import "./../interfaces/IVoter.sol";

import "@openzeppelin-3.4.1/contracts/proxy/Initializable.sol";

contract RamsesV2Pool is IRamsesV2Pool, Initializable {
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;
    using TickBitmap for mapping(int16 => uint256);

    // To avoid stack-too-deep
    struct TokenAmounts {
        uint256 token0;
        uint256 token1;
    }

    // To avoid stack-too-deep
    struct TokenAmountInts {
        int256 token0;
        int256 token1;
    }

    bytes32 STATES_SLOT = keccak256("states.storage");

    /// @dev Mutually exclusive reentrancy protection into the pool to/from a method. This method also prevents entrance
    /// to a function before the pool is initialized. The reentrancy guard is required throughout the contract because
    /// we use balance checks to determine the payment status of interactions such as mint, swap and flash.
    modifier lock() {
        _lock();
        _;
        _unlock();
    }

    // separated for code size
    function _lock() internal {
        States.PoolStates storage states = States.getStorage();

        require(states.slot0.unlocked, "LOK");
        states.slot0.unlocked = false;
    }

    function _unlock() internal {
        States.getStorage().slot0.unlocked = true;
    }

    /// @dev Advances period if it's a new week
    modifier advancePeriod() {
        _advancePeriod();
        _;
    }

    /// @dev Advances period if it's a new week
    function _advancePeriod() public override {
        States.PoolStates storage states = States.getStorage();

        // if in new week, record lastTick for previous period
        // also record secondsPerLiquidityCumulativeX128 for the start of the new period
        uint256 _lastPeriod = states.lastPeriod;
        if ((States._blockTimestamp() / 1 weeks) != _lastPeriod) {
            Slot0 memory _slot0 = states.slot0;
            uint256 period = States._blockTimestamp() / 1 weeks;
            states.lastPeriod = period;

            // start new period in obervations
            (
                uint160 secondsPerLiquidityCumulativeX128,
                uint160 secondsPerBoostedLiquidityCumulativeX128,
                uint32 boostedInRange
            ) = Oracle.newPeriod(
                    states.observations,
                    _slot0.observationIndex,
                    period
                );

            // reset boostedLiquidity
            states.boostedLiquidity = 0;

            // record last tick and secondsPerLiquidityCumulativeX128 for old period
            states.periods[_lastPeriod].lastTick = _slot0.tick;
            states
                .periods[_lastPeriod]
                .endSecondsPerLiquidityPeriodX128 = secondsPerLiquidityCumulativeX128;
            states
                .periods[_lastPeriod]
                .endSecondsPerBoostedLiquidityPeriodX128 = secondsPerBoostedLiquidityCumulativeX128;
            states.periods[_lastPeriod].boostedInRange = boostedInRange;

            // record start tick and secondsPerLiquidityCumulativeX128 for new period
            PeriodInfo memory _newPeriod;

            _newPeriod.previousPeriod = uint32(_lastPeriod);
            _newPeriod.startTick = _slot0.tick;
            states.periods[period] = _newPeriod;
        }
    }

    /// @dev prevents implementation from being initialized later
    constructor() initializer() {}

    /// @dev initilializes
    function initialize(
        address _factory,
        address _nfpManager,
        address _veRam,
        address _voter,
        address _token0,
        address _token1,
        uint24 _fee,
        int24 _tickSpacing
    ) public override initializer {
        States.PoolStates storage states = States.getStorage();

        states.factory = _factory;
        states.nfpManager = _nfpManager;
        states.veRam = _veRam;
        states.voter = _voter;
        states.token0 = _token0;
        states.token1 = _token1;
        states.fee = _fee;
        states.initialFee = _fee;
        states.tickSpacing = _tickSpacing;

        states.maxLiquidityPerTick = Tick.tickSpacingToMaxLiquidityPerTick(
            _tickSpacing
        );
    }

    /// View Functions

    // Get the address of the factory that created the pool
    /// @inheritdoc IRamsesV2PoolImmutables
    function factory() external view override returns (address) {
        return States.getStorage().factory;
    }

    // Get the address of the NFP manager for the pool
    /// @inheritdoc IRamsesV2PoolImmutables
    function nfpManager() external view override returns (address) {
        return States.getStorage().nfpManager;
    }

    // Get the address of the veRAM token for the pool
    /// @inheritdoc IRamsesV2PoolImmutables
    function veRam() external view override returns (address) {
        return States.getStorage().veRam;
    }

    // Get the address of the voter contract for the pool
    /// @inheritdoc IRamsesV2PoolImmutables
    function voter() external view override returns (address) {
        return States.getStorage().voter;
    }

    // Get the address of the first token in the pool
    /// @inheritdoc IRamsesV2PoolImmutables
    function token0() external view override returns (address) {
        return States.getStorage().token0;
    }

    // Get the address of the second token in the pool
    /// @inheritdoc IRamsesV2PoolImmutables
    function token1() external view override returns (address) {
        return States.getStorage().token1;
    }

    // Get the fee charged by the pool for swaps and liquidity provision
    /// @inheritdoc IRamsesV2PoolImmutables
    function fee() external view override returns (uint24) {
        return States.getStorage().initialFee;
    }

    // Get the tick spacing for the pool
    /// @inheritdoc IRamsesV2PoolImmutables
    function tickSpacing() external view override returns (int24) {
        return States.getStorage().tickSpacing;
    }

    // Get the maximum amount of liquidity that can be added to the pool at each tick
    /// @inheritdoc IRamsesV2PoolImmutables
    function maxLiquidityPerTick() external view override returns (uint128) {
        return States.getStorage().maxLiquidityPerTick;
    }

    /// @inheritdoc IRamsesV2PoolImmutables
    function currentFee() external view override returns (uint24) {
        return States.getStorage().fee;
    }

    /// @inheritdoc IRamsesV2PoolState
    function readStorage(
        bytes32[] calldata slots
    ) external view override returns (bytes32[] memory returnData) {
        uint256 slotsLength = slots.length;
        returnData = new bytes32[](slotsLength);

        for (uint256 i = 0; i < slotsLength; ++i) {
            bytes32 slot = slots[i];
            bytes32 _returnData;
            assembly {
                _returnData := sload(slot)
            }
            returnData[i] = _returnData;
        }
    }

    // Get the Slot0 struct for the pool
    /// @inheritdoc IRamsesV2PoolState
    function slot0()
        external
        view
        override
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        )
    {
        Slot0 memory _slot0 = States.getStorage().slot0;

        return (
            _slot0.sqrtPriceX96,
            _slot0.tick,
            _slot0.observationIndex,
            _slot0.observationCardinality,
            _slot0.observationCardinalityNext,
            _slot0.feeProtocol,
            _slot0.unlocked
        );
    }

    // Get the PeriodInfo struct for a given period in the pool
    /// @inheritdoc IRamsesV2PoolState
    function periods(
        uint256 period
    )
        external
        view
        override
        returns (
            uint32 previousPeriod,
            int24 startTick,
            int24 lastTick,
            uint160 endSecondsPerLiquidityPeriodX128,
            uint160 endSecondsPerBoostedLiquidityPeriodX128,
            uint32 boostedInRange
        )
    {
        PeriodInfo memory periodData = States.getStorage().periods[period];
        return (
            periodData.previousPeriod,
            periodData.startTick,
            periodData.lastTick,
            periodData.endSecondsPerLiquidityPeriodX128,
            periodData.endSecondsPerBoostedLiquidityPeriodX128,
            periodData.boostedInRange
        );
    }

    // Get the index of the last period in the pool
    /// @inheritdoc IRamsesV2PoolState
    function lastPeriod() external view override returns (uint256) {
        return States.getStorage().lastPeriod;
    }

    // Get the accumulated fee growth for the first token in the pool
    /// @inheritdoc IRamsesV2PoolState
    function feeGrowthGlobal0X128() external view override returns (uint256) {
        return States.getStorage().feeGrowthGlobal0X128;
    }

    // Get the accumulated fee growth for the second token in the pool
    /// @inheritdoc IRamsesV2PoolState
    function feeGrowthGlobal1X128() external view override returns (uint256) {
        return States.getStorage().feeGrowthGlobal1X128;
    }

    // Get the protocol fees accumulated by the pool
    /// @inheritdoc IRamsesV2PoolState
    function protocolFees()
        external
        view
        override
        returns (uint128 token0, uint128 token1)
    {
        ProtocolFees memory protocolFeesData = States.getStorage().protocolFees;
        return (protocolFeesData.token0, protocolFeesData.token1);
    }

    // Get the total liquidity of the pool
    /// @inheritdoc IRamsesV2PoolState
    function liquidity() external view override returns (uint128) {
        return States.getStorage().liquidity;
    }

    // Get the boosted liquidity of the pool
    /// @inheritdoc IRamsesV2PoolState
    function boostedLiquidity() external view override returns (uint128) {
        return States.getStorage().boostedLiquidity;
    }

    // Get the ticks of the pool
    /// @inheritdoc IRamsesV2PoolState
    function ticks(
        int24 tick
    )
        external
        view
        override
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint128 boostedLiquidityGross,
            int128 boostedLiquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        )
    {
        uint256 period = States._blockTimestamp() / 1 weeks;
        TickInfo storage tickData = States.getStorage()._ticks[tick];
        liquidityGross = tickData.liquidityGross;
        liquidityNet = tickData.liquidityNet;
        boostedLiquidityGross = tickData.boostedLiquidityGross[period];
        boostedLiquidityNet = tickData.boostedLiquidityNet[period];
        feeGrowthOutside0X128 = tickData.feeGrowthOutside0X128;
        feeGrowthOutside1X128 = tickData.feeGrowthOutside1X128;
        tickCumulativeOutside = tickData.tickCumulativeOutside;
        secondsPerLiquidityOutsideX128 = tickData
            .secondsPerLiquidityOutsideX128;
        secondsOutside = tickData.secondsOutside;
        initialized = tickData.initialized;
    }

    // Get the tick bitmap of the pool
    /// @inheritdoc IRamsesV2PoolState
    function tickBitmap(int16 tick) external view override returns (uint256) {
        return States.getStorage().tickBitmap[tick];
    }

    // Get information about a specific position in the pool
    /// @inheritdoc IRamsesV2PoolState
    function positions(
        bytes32 key
    )
        external
        view
        override
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1,
            uint256 attachedVeRamId
        )
    {
        PositionInfo memory positionData = States.getStorage().positions[key];
        return (
            positionData.liquidity,
            positionData.feeGrowthInside0LastX128,
            positionData.feeGrowthInside1LastX128,
            positionData.tokensOwed0,
            positionData.tokensOwed1,
            positionData.attachedVeRamId
        );
    }

    // Get the boost information for a specific period
    /// @inheritdoc IRamsesV2PoolState
    function boostInfos(
        uint256 period
    )
        external
        view
        override
        returns (uint128 totalBoostAmount, int128 totalVeRamAmount)
    {
        PeriodBoostInfo storage periodBoostInfoData = States
            .getStorage()
            .boostInfos[period];
        return (
            periodBoostInfoData.totalBoostAmount,
            periodBoostInfoData.totalVeRamAmount
        );
    }

    // Get the boost information for a specific position at a period
    /// @inheritdoc IRamsesV2PoolState
    function boostInfos(
        uint256 period,
        bytes32 key
    )
        external
        view
        override
        returns (
            uint128 boostAmount,
            int128 veRamAmount,
            int256 secondsDebtX96,
            int256 boostedSecondsDebtX96
        )
    {
        BoostInfo memory boostInfo = States
            .getStorage()
            .boostInfos[period]
            .positions[key];
        return (
            boostInfo.boostAmount,
            boostInfo.veRamAmount,
            boostInfo.secondsDebtX96,
            boostInfo.boostedSecondsDebtX96
        );
    }

    // Get the period seconds debt of a specific position
    /// @inheritdoc IRamsesV2PoolState
    function positionPeriodDebt(
        uint256 period,
        address owner,
        uint256 index,
        int24 tickLower,
        int24 tickUpper
    )
        external
        view
        override
        returns (int256 secondsDebtX96, int256 boostedSecondsDebtX96)
    {
        States.PoolStates storage states = States.getStorage();
        BoostInfo storage position = Position.get(
            states.boostInfos[period],
            owner,
            index,
            tickLower,
            tickUpper
        );

        secondsDebtX96 = position.secondsDebtX96;
        boostedSecondsDebtX96 = position.boostedSecondsDebtX96;

        return (secondsDebtX96, boostedSecondsDebtX96);
    }

    // Get the period seconds in range of a specific position
    /// @inheritdoc IRamsesV2PoolState
    function positionPeriodSecondsInRange(
        uint256 period,
        address owner,
        uint256 index,
        int24 tickLower,
        int24 tickUpper
    )
        external
        view
        override
        returns (
            uint256 periodSecondsInsideX96,
            uint256 periodBoostedSecondsInsideX96
        )
    {
        (periodSecondsInsideX96, periodBoostedSecondsInsideX96) = Position
            .positionPeriodSecondsInRange(
                Position.PositionPeriodSecondsInRangeParams({
                    period: period,
                    owner: owner,
                    index: index,
                    tickLower: tickLower,
                    tickUpper: tickUpper
                })
            );

        return (periodSecondsInsideX96, periodBoostedSecondsInsideX96);
    }

    // Get the observations recorded by the pool
    /// @inheritdoc IRamsesV2PoolState
    function observations(
        uint256 index
    )
        external
        view
        override
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized,
            uint160 secondsPerBoostedLiquidityPeriodX128
        )
    {
        Observation memory observationData = States.getStorage().observations[
            index
        ];
        return (
            observationData.blockTimestamp,
            observationData.tickCumulative,
            observationData.secondsPerLiquidityCumulativeX128,
            observationData.initialized,
            observationData.secondsPerBoostedLiquidityPeriodX128
        );
    }

    /// @inheritdoc IRamsesV2PoolDerivedState
    function snapshotCumulativesInside(
        int24 tickLower,
        int24 tickUpper
    )
        external
        view
        override
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint160 secondsPerBoostedLiquidityInsideX128,
            uint32 secondsInside
        )
    {
        // check ticks
        require(tickLower < tickUpper, "TLU");
        require(tickLower >= TickMath.MIN_TICK, "TLM");
        require(tickUpper <= TickMath.MAX_TICK, "TUM");

        return Oracle.snapshotCumulativesInside(tickLower, tickUpper);
    }

    /// @inheritdoc IRamsesV2PoolDerivedState
    function periodCumulativesInside(
        uint32 period,
        int24 tickLower,
        int24 tickUpper
    )
        external
        view
        override
        returns (
            uint160 secondsPerLiquidityInsideX128,
            uint160 secondsPerBoostedLiquidityInsideX128
        )
    {
        return Oracle.periodCumulativesInside(period, tickLower, tickUpper);
    }

    /// @inheritdoc IRamsesV2PoolDerivedState
    function observe(
        uint32[] calldata secondsAgos
    )
        external
        view
        override
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulativeX128s,
            uint160[] memory secondsPerBoostedLiquidityPeriodX128s
        )
    {
        States.PoolStates storage states = States.getStorage();

        return
            Oracle.observe(
                states.observations,
                States._blockTimestamp(),
                secondsAgos,
                states.slot0.tick,
                states.slot0.observationIndex,
                states.liquidity,
                states.boostedLiquidity,
                states.slot0.observationCardinality
            );
    }

    /// @inheritdoc IRamsesV2PoolActions
    function increaseObservationCardinalityNext(
        uint16 observationCardinalityNext
    ) external override lock {
        States.PoolStates storage states = States.getStorage();

        uint16 observationCardinalityNextOld = states
            .slot0
            .observationCardinalityNext; // for the event
        uint16 observationCardinalityNextNew = Oracle.grow(
            states.observations,
            observationCardinalityNextOld,
            observationCardinalityNext
        );
        states.slot0.observationCardinalityNext = observationCardinalityNextNew;
        if (observationCardinalityNextOld != observationCardinalityNextNew)
            emit IncreaseObservationCardinalityNext(
                observationCardinalityNextOld,
                observationCardinalityNextNew
            );
    }

    /// @inheritdoc IRamsesV2PoolActions
    /// @dev not locked because it initializes unlocked
    function initialize(uint160 sqrtPriceX96) external override {
        States.PoolStates storage states = States.getStorage();

        require(states.slot0.sqrtPriceX96 == 0, "AI");

        int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);

        (uint16 cardinality, uint16 cardinalityNext) = Oracle.initialize(
            states.observations,
            0
        );

        _advancePeriod();

        states.slot0 = Slot0({
            sqrtPriceX96: sqrtPriceX96,
            tick: tick,
            observationIndex: 0,
            observationCardinality: cardinality,
            observationCardinalityNext: cardinalityNext,
            feeProtocol: 0,
            unlocked: true
        });

        emit Initialize(sqrtPriceX96, tick);
    }

    /// @inheritdoc IRamsesV2PoolActions
    /// @dev lock and advancePeriod is applied indirectly in mint()
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external override returns (uint256 amount0, uint256 amount1) {
        return
            mint(
                recipient,
                0,
                tickLower,
                tickUpper,
                amount,
                type(uint256).max,
                data
            );
    }

    /// @inheritdoc IRamsesV2PoolActions
    function mint(
        address recipient,
        uint256 index,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        uint256 veRamTokenId,
        bytes calldata data
    )
        public
        override
        lock
        advancePeriod
        returns (uint256 amount0, uint256 amount1)
    {
        require(amount > 0);
        if (veRamTokenId != type(uint256).max) {
            require(recipient == msg.sender);
        }

        TokenAmountInts memory amountInt;
        (, amountInt.token0, amountInt.token1) = Position._modifyPosition(
            Position.ModifyPositionParams({
                owner: recipient,
                index: index,
                tickLower: tickLower,
                tickUpper: tickUpper,
                liquidityDelta: int256(amount).toInt128(),
                veRamTokenId: veRamTokenId
            })
        );

        amount0 = uint256(amountInt.token0);
        amount1 = uint256(amountInt.token1);

        uint256 balance0Before;
        uint256 balance1Before;
        if (amount0 > 0) balance0Before = States.balance0();
        if (amount1 > 0) balance1Before = States.balance1();
        IRamsesV2MintCallback(msg.sender).ramsesV2MintCallback(
            amount0,
            amount1,
            data
        );
        if (amount0 > 0)
            require(balance0Before.add(amount0) <= States.balance0(), "M0");
        if (amount1 > 0)
            require(balance1Before.add(amount1) <= States.balance1(), "M1");

        emit Mint(
            msg.sender,
            recipient,
            tickLower,
            tickUpper,
            amount,
            amount0,
            amount1
        );
    }

    /// @inheritdoc IRamsesV2PoolActions
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external override returns (uint128 amount0, uint128 amount1) {
        return
            collect(
                recipient,
                0,
                tickLower,
                tickUpper,
                amount0Requested,
                amount1Requested
            );
    }

    /// @inheritdoc IRamsesV2PoolActions
    function collect(
        address recipient,
        uint256 index,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) public override lock returns (uint128 amount0, uint128 amount1) {
        States.PoolStates storage states = States.getStorage();

        // we don't need to checkTicks here, because invalid positions will never have non-zero tokensOwed{0,1}
        PositionInfo storage position = Position.get(
            states.positions,
            msg.sender,
            index,
            tickLower,
            tickUpper
        );

        amount0 = amount0Requested > position.tokensOwed0
            ? position.tokensOwed0
            : amount0Requested;
        amount1 = amount1Requested > position.tokensOwed1
            ? position.tokensOwed1
            : amount1Requested;

        if (amount0 > 0) {
            position.tokensOwed0 -= amount0;
            TransferHelper.safeTransfer(states.token0, recipient, amount0);
        }
        if (amount1 > 0) {
            position.tokensOwed1 -= amount1;
            TransferHelper.safeTransfer(states.token1, recipient, amount1);
        }

        emit Collect(
            msg.sender,
            recipient,
            tickLower,
            tickUpper,
            amount0,
            amount1
        );
    }

    /// @inheritdoc IRamsesV2PoolActions
    /// @dev lock and advancePeriod is applied indirectly in burn()
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external override returns (uint256 amount0, uint256 amount1) {
        return burn(0, tickLower, tickUpper, amount, type(uint256).max);
    }

    /// @dev lock and advancePeriod is applied indirectly in burn()
    /// @inheritdoc IRamsesV2PoolActions
    function burn(
        uint256 index,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external override returns (uint256 amount0, uint256 amount1) {
        return burn(index, tickLower, tickUpper, amount, type(uint256).max);
    }

    /// @inheritdoc IRamsesV2PoolActions
    function burn(
        uint256 index,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        uint256 veRamTokenId
    )
        public
        override
        lock
        advancePeriod
        returns (uint256 amount0, uint256 amount1)
    {
        (
            PositionInfo storage position,
            int256 amount0Int,
            int256 amount1Int
        ) = Position._modifyPosition(
                Position.ModifyPositionParams({
                    owner: msg.sender,
                    index: index,
                    tickLower: tickLower,
                    tickUpper: tickUpper,
                    liquidityDelta: -int256(amount).toInt128(),
                    veRamTokenId: veRamTokenId
                })
            );

        amount0 = uint256(-amount0Int);
        amount1 = uint256(-amount1Int);

        if (amount0 > 0 || amount1 > 0) {
            (position.tokensOwed0, position.tokensOwed1) = (
                position.tokensOwed0 + uint128(amount0),
                position.tokensOwed1 + uint128(amount1)
            );
        }

        emit Burn(msg.sender, tickLower, tickUpper, amount, amount0, amount1);
    }

    struct SwapCache {
        // the protocol fee for the input token
        uint8 feeProtocol;
        // liquidity at the beginning of the swap
        uint128 liquidityStart;
        // boosted liquidity at the beginning of the swap
        uint128 boostedLiquidityStart;
        // the timestamp of the current block
        uint32 blockTimestamp;
        // the current value of the tick accumulator, computed only if we cross an initialized tick
        int56 tickCumulative;
        // the current value of seconds per liquidity accumulator, computed only if we cross an initialized tick
        uint160 secondsPerLiquidityCumulativeX128;
        // the current value of seconds per boosted liquidity accumulator, computed only if we cross an initialized tick
        uint160 secondsPerBoostedLiquidityPeriodX128;
        // whether we've computed and cached the above two accumulators
        bool computedLatestObservation;
        // whether the swap has exactInput
        bool exactInput;
        // timestamp of the previous period
        uint32 previousPeriod;
    }

    // the top level state of the swap, the results of which are recorded in storage at the end
    struct SwapState {
        // the amount remaining to be swapped in/out of the input/output asset
        int256 amountSpecifiedRemaining;
        // the amount already swapped out/in of the output/input asset
        int256 amountCalculated;
        // current sqrt(price)
        uint160 sqrtPriceX96;
        // the tick associated with the current price
        int24 tick;
        // the global fee growth of the input token
        uint256 feeGrowthGlobalX128;
        // amount of input token paid as protocol fee
        uint128 protocolFee;
        // the current liquidity in range
        uint128 liquidity;
        // the current boosted liquidity in range
        uint128 boostedLiquidity;
        // seconds per liquidity at the end of the previous period
        uint256 endSecondsPerLiquidityPeriodX128;
        // seconds per boosted liquidity at the end of the previous period
        uint256 endSecondsPerBoostedLiquidityPeriodX128;
        // starting tick of the current period
        int24 periodStartTick;
    }

    struct StepComputations {
        // the price at the beginning of the step
        uint160 sqrtPriceStartX96;
        // the next tick to swap to from the current tick in the swap direction
        int24 tickNext;
        // whether tickNext is initialized or not
        bool initialized;
        // sqrt(price) for the next tick (1/0)
        uint160 sqrtPriceNextX96;
        // how much is being swapped in in this step
        uint256 amountIn;
        // how much is being swapped out
        uint256 amountOut;
        // how much fee is being paid in
        uint256 feeAmount;
    }

    struct CrossCache {
        int128 liquidityNet;
        int128 boostedLiquidityNet;
        uint256 feeGrowthGlobal0X128;
        uint256 feeGrowthGlobal1X128;
    }

    /// @inheritdoc IRamsesV2PoolActions
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external override advancePeriod returns (int256 amount0, int256 amount1) {
        States.PoolStates storage states = States.getStorage();

        require(amountSpecified != 0, "AS");

        Slot0 memory slot0Start = states.slot0;

        require(slot0Start.unlocked, "LOK");
        require(
            zeroForOne
                ? sqrtPriceLimitX96 < slot0Start.sqrtPriceX96 &&
                    sqrtPriceLimitX96 > TickMath.MIN_SQRT_RATIO
                : sqrtPriceLimitX96 > slot0Start.sqrtPriceX96 &&
                    sqrtPriceLimitX96 < TickMath.MAX_SQRT_RATIO,
            "SPL"
        );

        states.slot0.unlocked = false;

        SwapCache memory cache;
        SwapState memory state;

        {
            uint256 period = States._blockTimestamp() / 1 weeks;

            cache = SwapCache({
                liquidityStart: states.liquidity,
                boostedLiquidityStart: states.boostedLiquidity,
                blockTimestamp: States._blockTimestamp(),
                feeProtocol: zeroForOne
                    ? (slot0Start.feeProtocol % 16)
                    : (slot0Start.feeProtocol >> 4),
                secondsPerLiquidityCumulativeX128: 0,
                secondsPerBoostedLiquidityPeriodX128: 0,
                tickCumulative: 0,
                computedLatestObservation: false,
                exactInput: amountSpecified > 0,
                previousPeriod: states.periods[period].previousPeriod
            });

            state = SwapState({
                amountSpecifiedRemaining: amountSpecified,
                amountCalculated: 0,
                sqrtPriceX96: slot0Start.sqrtPriceX96,
                tick: slot0Start.tick,
                feeGrowthGlobalX128: zeroForOne
                    ? states.feeGrowthGlobal0X128
                    : states.feeGrowthGlobal1X128,
                protocolFee: 0,
                liquidity: cache.liquidityStart,
                boostedLiquidity: cache.boostedLiquidityStart,
                endSecondsPerLiquidityPeriodX128: states
                    .periods[cache.previousPeriod]
                    .endSecondsPerLiquidityPeriodX128,
                endSecondsPerBoostedLiquidityPeriodX128: states
                    .periods[cache.previousPeriod]
                    .endSecondsPerBoostedLiquidityPeriodX128,
                periodStartTick: states.periods[period].startTick
            });
        }

        // continue swapping as long as we haven't used the entire input/output and haven't reached the price limit
        while (
            state.amountSpecifiedRemaining != 0 &&
            state.sqrtPriceX96 != sqrtPriceLimitX96
        ) {
            StepComputations memory step;

            step.sqrtPriceStartX96 = state.sqrtPriceX96;

            (step.tickNext, step.initialized) = TickBitmap
                .nextInitializedTickWithinOneWord(
                    states.tickBitmap,
                    state.tick,
                    states.tickSpacing,
                    zeroForOne
                );

            // ensure that we do not overshoot the min/max tick, as the tick bitmap is not aware of these bounds
            if (step.tickNext < TickMath.MIN_TICK) {
                step.tickNext = TickMath.MIN_TICK;
            } else if (step.tickNext > TickMath.MAX_TICK) {
                step.tickNext = TickMath.MAX_TICK;
            }

            // get the price for the next tick
            step.sqrtPriceNextX96 = TickMath.getSqrtRatioAtTick(step.tickNext);

            // compute values to swap to the target tick, price limit, or point where input/output amount is exhausted
            (
                state.sqrtPriceX96,
                step.amountIn,
                step.amountOut,
                step.feeAmount
            ) = SwapMath.computeSwapStep(
                state.sqrtPriceX96,
                (
                    zeroForOne
                        ? step.sqrtPriceNextX96 < sqrtPriceLimitX96
                        : step.sqrtPriceNextX96 > sqrtPriceLimitX96
                )
                    ? sqrtPriceLimitX96
                    : step.sqrtPriceNextX96,
                state.liquidity,
                state.amountSpecifiedRemaining,
                states.fee
            );

            if (cache.exactInput) {
                state.amountSpecifiedRemaining -= (step.amountIn +
                    step.feeAmount).toInt256();
                state.amountCalculated = state.amountCalculated.sub(
                    step.amountOut.toInt256()
                );
            } else {
                state.amountSpecifiedRemaining += step.amountOut.toInt256();
                state.amountCalculated = state.amountCalculated.add(
                    (step.amountIn + step.feeAmount).toInt256()
                );
            }

            // if the protocol fee is on, calculate how much is owed, decrement feeAmount, and increment protocolFee
            if (cache.feeProtocol > 0) {
                uint256 delta = (step.feeAmount *
                    (cache.feeProtocol * 5 + 50)) / 100;
                step.feeAmount -= delta;
                state.protocolFee += uint128(delta);
            }

            // update global fee tracker
            if (state.liquidity > 0)
                state.feeGrowthGlobalX128 += FullMath.mulDiv(
                    step.feeAmount,
                    FixedPoint128.Q128,
                    state.liquidity
                );

            // shift tick if we reached the next price
            if (state.sqrtPriceX96 == step.sqrtPriceNextX96) {
                // if the tick is initialized, run the tick transition
                if (step.initialized) {
                    // check for the placeholder value, which we replace with the actual value the first time the swap
                    // crosses an initialized tick
                    if (!cache.computedLatestObservation) {
                        (
                            cache.tickCumulative,
                            cache.secondsPerLiquidityCumulativeX128,
                            cache.secondsPerBoostedLiquidityPeriodX128
                        ) = Oracle.observeSingle(
                            states.observations,
                            cache.blockTimestamp,
                            0,
                            slot0Start.tick,
                            slot0Start.observationIndex,
                            cache.liquidityStart,
                            cache.boostedLiquidityStart,
                            slot0Start.observationCardinality
                        );
                        cache.computedLatestObservation = true;
                    }
                    CrossCache memory crossCache; // stack too deep

                    if (zeroForOne) {
                        // yes, one uses state and the other uses states, this is not a typo
                        crossCache.feeGrowthGlobal0X128 = state
                            .feeGrowthGlobalX128;
                        crossCache.feeGrowthGlobal1X128 = states
                            .feeGrowthGlobal1X128;
                    } else {
                        crossCache.feeGrowthGlobal0X128 = states
                            .feeGrowthGlobal0X128;
                        crossCache.feeGrowthGlobal1X128 = state
                            .feeGrowthGlobalX128;
                    }
                    (
                        crossCache.liquidityNet,
                        crossCache.boostedLiquidityNet
                    ) = Tick.cross(
                        states._ticks,
                        Tick.CrossParams(
                            step.tickNext,
                            crossCache.feeGrowthGlobal0X128,
                            crossCache.feeGrowthGlobal1X128,
                            cache.secondsPerLiquidityCumulativeX128,
                            cache.secondsPerBoostedLiquidityPeriodX128,
                            state.endSecondsPerLiquidityPeriodX128,
                            state.endSecondsPerBoostedLiquidityPeriodX128,
                            state.periodStartTick,
                            cache.tickCumulative,
                            cache.blockTimestamp
                        )
                    );
                    // if we're moving leftward, we interpret liquidityNet as the opposite sign
                    // safe because liquidityNet cannot be type(int128).min
                    if (zeroForOne) {
                        crossCache.liquidityNet = -crossCache.liquidityNet;
                        crossCache.boostedLiquidityNet = -crossCache
                            .boostedLiquidityNet;
                    }

                    state.liquidity = LiquidityMath.addDelta(
                        state.liquidity,
                        crossCache.liquidityNet
                    );
                    state.boostedLiquidity = LiquidityMath.addDelta(
                        state.boostedLiquidity,
                        crossCache.boostedLiquidityNet
                    );
                }

                state.tick = zeroForOne ? step.tickNext - 1 : step.tickNext;
            } else if (state.sqrtPriceX96 != step.sqrtPriceStartX96) {
                // recompute unless we're on a lower tick boundary (i.e. already transitioned ticks), and haven't moved
                state.tick = TickMath.getTickAtSqrtRatio(state.sqrtPriceX96);
            }
        }

        // update tick and write an oracle entry if the tick change
        if (state.tick != slot0Start.tick) {
            (uint16 observationIndex, uint16 observationCardinality) = Oracle
                .write(
                    states.observations,
                    slot0Start.observationIndex,
                    cache.blockTimestamp,
                    slot0Start.tick,
                    cache.liquidityStart,
                    cache.boostedLiquidityStart,
                    slot0Start.observationCardinality,
                    slot0Start.observationCardinalityNext
                );
            (
                states.slot0.sqrtPriceX96,
                states.slot0.tick,
                states.slot0.observationIndex,
                states.slot0.observationCardinality
            ) = (
                state.sqrtPriceX96,
                state.tick,
                observationIndex,
                observationCardinality
            );
        } else {
            // otherwise just update the price
            states.slot0.sqrtPriceX96 = state.sqrtPriceX96;
        }

        // update liquidity if it changed
        if (cache.liquidityStart != state.liquidity) {
            states.liquidity = state.liquidity;
        }

        // update if boosted changed, need a separate check because boosted can change without liquidity changing
        if (cache.boostedLiquidityStart != state.boostedLiquidity) {
            states.boostedLiquidity = state.boostedLiquidity;
        }

        // update fee growth global and, if necessary, protocol fees
        // overflow is acceptable, protocol has to withdraw before it hits type(uint128).max fees
        if (zeroForOne) {
            states.feeGrowthGlobal0X128 = state.feeGrowthGlobalX128;
            if (state.protocolFee > 0)
                states.protocolFees.token0 += state.protocolFee;
        } else {
            states.feeGrowthGlobal1X128 = state.feeGrowthGlobalX128;
            if (state.protocolFee > 0)
                states.protocolFees.token1 += state.protocolFee;
        }

        (amount0, amount1) = zeroForOne == cache.exactInput
            ? (
                amountSpecified - state.amountSpecifiedRemaining,
                state.amountCalculated
            )
            : (
                state.amountCalculated,
                amountSpecified - state.amountSpecifiedRemaining
            );

        // do the transfers and collect payment
        if (zeroForOne) {
            if (amount1 < 0)
                TransferHelper.safeTransfer(
                    states.token1,
                    recipient,
                    uint256(-amount1)
                );

            uint256 balance0Before = States.balance0();
            IRamsesV2SwapCallback(msg.sender).ramsesV2SwapCallback(
                amount0,
                amount1,
                data
            );
            require(
                balance0Before.add(uint256(amount0)) <= States.balance0(),
                "IIA"
            );
        } else {
            if (amount0 < 0)
                TransferHelper.safeTransfer(
                    states.token0,
                    recipient,
                    uint256(-amount0)
                );

            uint256 balance1Before = States.balance1();
            IRamsesV2SwapCallback(msg.sender).ramsesV2SwapCallback(
                amount0,
                amount1,
                data
            );
            require(
                balance1Before.add(uint256(amount1)) <= States.balance1(),
                "IIA"
            );
        }

        emit Swap(
            msg.sender,
            recipient,
            amount0,
            amount1,
            state.sqrtPriceX96,
            state.liquidity,
            state.tick
        );
        states.slot0.unlocked = true;
    }

    /// @inheritdoc IRamsesV2PoolActions
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override lock {
        States.PoolStates storage states = States.getStorage();

        uint128 _liquidity = states.liquidity;
        require(_liquidity > 0, "L");

        uint256 fee0 = FullMath.mulDivRoundingUp(amount0, states.fee, 1e6);
        uint256 fee1 = FullMath.mulDivRoundingUp(amount1, states.fee, 1e6);
        uint256 balance0Before = States.balance0();
        uint256 balance1Before = States.balance1();

        if (amount0 > 0)
            TransferHelper.safeTransfer(states.token0, recipient, amount0);
        if (amount1 > 0)
            TransferHelper.safeTransfer(states.token1, recipient, amount1);

        IRamsesV2FlashCallback(msg.sender).ramsesV2FlashCallback(
            fee0,
            fee1,
            data
        );

        TokenAmounts memory balanceAfter;
        balanceAfter.token0 = States.balance0();
        balanceAfter.token1 = States.balance1();

        require(balance0Before.add(fee0) <= balanceAfter.token0, "F0");
        require(balance1Before.add(fee1) <= balanceAfter.token1, "F1");

        // sub is safe because we know balanceAfter is gt balanceBefore by at least fee
        TokenAmounts memory paid;
        paid.token0 = balanceAfter.token0 - balance0Before;
        paid.token1 = balanceAfter.token1 - balance1Before;

        if (paid.token0 > 0) {
            uint8 feeProtocol0 = states.slot0.feeProtocol % 16;
            uint256 fees0 = feeProtocol0 == 0 ? 0 : paid.token0 / feeProtocol0;
            if (uint128(fees0) > 0)
                states.protocolFees.token0 += uint128(fees0);
            states.feeGrowthGlobal0X128 += FullMath.mulDiv(
                paid.token0 - fees0,
                FixedPoint128.Q128,
                _liquidity
            );
        }
        if (paid.token1 > 0) {
            uint8 feeProtocol1 = states.slot0.feeProtocol >> 4;
            uint256 fees1 = feeProtocol1 == 0 ? 0 : paid.token1 / feeProtocol1;
            if (uint128(fees1) > 0)
                states.protocolFees.token1 += uint128(fees1);
            states.feeGrowthGlobal1X128 += FullMath.mulDiv(
                paid.token1 - fees1,
                FixedPoint128.Q128,
                _liquidity
            );
        }

        emit Flash(
            msg.sender,
            recipient,
            amount0,
            amount1,
            paid.token0,
            paid.token1
        );
    }

    /// @inheritdoc IRamsesV2PoolOwnerActions
    function setFeeProtocol() external override lock {
        ProtocolActions.setFeeProtocol();
    }

    function setFee(uint24 _fee) external override {
        ProtocolActions.setFee(_fee);
    }

    /// @inheritdoc IRamsesV2PoolOwnerActions
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external override lock returns (uint128 amount0, uint128 amount1) {
        return
            ProtocolActions.collectProtocol(
                recipient,
                amount0Requested,
                amount1Requested
            );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import "./interfaces/IRamsesV2PoolDeployer.sol";
import "./interfaces/IRamsesV2Pool.sol";

import "./../RamsesBeaconProxy.sol";

import "@openzeppelin-3.4.1/contracts/proxy/IBeacon.sol";

contract RamsesV2PoolDeployer is IRamsesV2PoolDeployer, IBeacon {
    /// @inheritdoc IBeacon
    address public override implementation;

    /// @dev Deploys a pool with the given parameters by transiently setting the parameters storage slot and then
    /// clearing it after deploying the pool.
    /// @param factory The contract address of the Ramses V2 factory
    /// @param nfpManager The contract address of the Ramses V2 NFP Manager
    /// @param veRam The contract address of the Ramses Voting Escrow
    /// @param voter The contract address of the Ramses Voter
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The spacing between usable ticks
    function _deploy(
        address factory,
        address nfpManager,
        address veRam,
        address voter,
        address token0,
        address token1,
        uint24 fee,
        int24 tickSpacing
    ) internal returns (address pool) {
        pool = address(
            new RamsesBeaconProxy{
                salt: keccak256(abi.encode(token0, token1, fee))
            }()
        );
        IRamsesV2Pool(pool).initialize(
            factory,
            nfpManager,
            veRam,
            voter,
            token0,
            token1,
            fee,
            tickSpacing
        );
    }
}