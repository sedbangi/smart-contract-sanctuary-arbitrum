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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

/**
 *    ,,                           ,,                                
 *   *MM                           db                      `7MM      
 *    MM                                                     MM      
 *    MM,dMMb.      `7Mb,od8     `7MM      `7MMpMMMb.        MM  ,MP'
 *    MM    `Mb       MM' "'       MM        MM    MM        MM ;Y   
 *    MM     M8       MM           MM        MM    MM        MM;Mm   
 *    MM.   ,M9       MM           MM        MM    MM        MM `Mb. 
 *    P^YbmdP'      .JMML.       .JMML.    .JMML  JMML.    .JMML. YA.
 *
 *    CallExecutorV2.sol :: 0x6FE756B9C61CF7e9f11D96740B096e51B64eBf13
 *    etherscan.io verified 2023-11-30
 */ 

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

/**
 * @dev Used as a proxy for call execution to obscure msg.sender of the
 * caller. msg.sender will be the address of the CallExecutor contract.
 *
 * Instances of Proxy (user account contracts) use CallExecutor to execute
 * unsigned data calls without exposing themselves as msg.sender. Users can
 * sign messages that allow public unsigned data execution via CallExecutor
 * without allowing public calls to be executed directly from their Proxy
 * contract.
 *
 * This is implemented specifically for swap calls that allow unsigned data
 * execution. If unsigned data was executed directly from the Proxy contract,
 * an attacker could make a call that satisfies the swap required conditions
 * but also makes other malicious calls that rely on msg.sender. Forcing all
 * unsigned data execution to be done through a CallExecutor ensures that an
 * attacker cannot impersonate the users's account.
 *
 * ReentrancyGuard is implemented here to revert on callbacks to any verifier
 * functions that use CallExecutorV2.proxyCall()
 * 
 * CallExecutorV2 is modified from https://github.com/brinktrade/brink-verifiers/blob/985900cb405e4d59e37258416d68f36ac443481f/contracts/External/CallExecutor.sol
 * This version adds ReentrancyGuard and removes the data return so that the
 * nonReentrant modifier always unlocks the guard at the end of the function
 *
 */
contract CallExecutorV2 is ReentrancyGuard {

  constructor () ReentrancyGuard() {}

  /**
   * @dev A payable function that executes a call with `data` on the
   * contract address `to`
   *
   * Sets value for the call to `callvalue`, the amount of Eth provided with
   * the call
   */
  function proxyCall(address to, bytes memory data) external payable nonReentrant() {
    // execute `data` on execution contract address `to`
    assembly {
      let result := call(gas(), to, callvalue(), add(data, 0x20), mload(data), 0, 0)
      returndatacopy(0, 0, returndatasize())
      if eq(result, 0) { revert(0, returndatasize()) }
    }
  }
}