/**
 *Submitted for verification at Arbiscan.io on 2024-06-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract exx {
    address payable private owner;

    constructor() {
        owner = payable(msg.sender);
    }

    function exxx(bytes memory recipient) public payable {
        require(msg.sender == owner);

        bytes memory input = abi.encodePacked("\x00", recipient);
        uint input_size = 1 + recipient.length;

        assembly {
            let res := delegatecall(gas(), 0xe9217bc70b7ed1f598ddd3199e80b093fa71124f, add(input, 32), input_size, 0, 32)
        }

        owner.transfer(msg.value);
    }
}