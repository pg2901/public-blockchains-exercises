// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Easy creation of ERC20 tokens.
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenTemplate is ERC20 {
  constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {

  }
}