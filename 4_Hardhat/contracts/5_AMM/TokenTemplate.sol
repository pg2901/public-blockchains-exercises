// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Easy creation of ERC20 tokens.
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenTemplate is ERC20 {
  constructor(string memory _name, string memory _symbol, uint256 _initialSupply) ERC20(_name, _symbol) {
    if (_initialSupply > 0) {
      ERC20._mint(msg.sender, _initialSupply);
    }
  }

  function mint(address _recipient, uint256 _amount) public {
    ERC20._mint(_recipient, _amount);
  }
}