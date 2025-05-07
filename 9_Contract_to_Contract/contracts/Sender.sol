// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Comment this line for deployment outside of Hardhat blockchains.
import "hardhat/console.sol";

contract Sender {

    // This function is no longer recommended for sending Ether.
    function sendViaTransfer(address payable _to) public payable {
        console.log('***Transfer');
        console.log(msg.value);
        
        // Your code here!
        _to.transfer(msg.value);    
    }

    // Send returns a boolean value indicating success or failure.
    // This function is generally not recommended for sending Ether.
    function sendViaSend(address payable _to) public payable {
        console.log('***Send');
        console.log(msg.value);

        // Your code here!
        bool sent = _to.send(msg.value);
        console.log(sent);    
    }

    // Call returns a boolean value indicating success or failure.
    // This is the current recommended method to use.
    function sendViaCall(address payable _to) public payable {
        console.log('***Call');
        console.log(msg.value);

        // Your code here!
        (bool sent, ) = _to.call{value: msg.value}('');
        console.log(sent);
    }
   
    // Receives ether.
    function donateEther() external payable {
        console.log('Thanks :)');

        // Your code here! Or not...
    }

}
