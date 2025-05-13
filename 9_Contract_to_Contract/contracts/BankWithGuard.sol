// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract BankWithGuard {
    mapping(address => uint) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        uint bal = balances[msg.sender];
        require(bal > 0);

        bool sent = payable(msg.sender).send(bal);
        require(sent, "Failed to send Ether");

        balances[msg.sender] = 0;
    }
}