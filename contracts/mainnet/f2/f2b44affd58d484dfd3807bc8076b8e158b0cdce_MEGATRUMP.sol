/**
 *Submitted for verification at Arbiscan.io on 2024-05-27
*/

/**
 *Submitted for verification at basescan.org on 2024-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MEGATRUMP {
    string public name = "PARAM LABS";
    string public symbol = "PARAM";
    uint8 public decimals = 18;
    uint256 public totalSupply = 10000000000 * (10 ** uint256(decimals));

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(to != address(0), "Invalid recipient");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);

        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        require(spender != address(0), "Invalid spender");

        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);

        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(from != address(0), "Invalid sender");
        require(to != address(0), "Invalid recipient");
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Allowance exceeded");

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;

        emit Transfer(from, to, value);

        return true;
    }
}