// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Easy creation of ERC20 tokens.
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

// Import BaseAssignment.sol
import "../BaseAssignment.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

abstract contract IRegistry {
  function registerAMM(address _exchangeAddress) external {}
  function getExchange(address _tokenAddress) external view returns (address) {}
}

contract AMM is ERC20, BaseAssignment {
  IERC20 private tokenContract;
  uint256 private tokenPool;
  IRegistry private registry;

  event LiquidityAdded(address indexed caller, uint256 ethAmount, uint256 tokenAmount);
  event LiquidityRemoved(address indexed caller, uint256 ethAmount, uint256 tokenAmount);
  event TokenBought(address indexed caller, uint256 ethAmount, uint256 tokenAmount);
  event EthBought(address indexed caller, uint256 ethAmount, uint256 tokenAmount);

  constructor(string memory _name, string memory _symbol, address _tokenAddress, address _registryAddress, address _validatorAddress) ERC20(_name, _symbol) BaseAssignment(_validatorAddress) {
    tokenContract = IERC20(_tokenAddress);
    registry = IRegistry(_registryAddress);
  }

  function getConstantProduct() public view returns (uint256) {
    return (tokenPool * address(this).balance);
  }

  function getTokenPool() public view returns (uint256) {
    return tokenPool;
  }

  function getETHPool() public view returns (uint256) {
    return address(this).balance;
  }

  function getTokenAddress() public view returns (address) {
    return address(tokenContract);
  }

  function donateEther() external payable {}

  function addLiquidity(uint256 _tokenAmount) public payable returns (uint256) {
    // Given amount of Ether deposited, compute the amount of X to be transferred and execute it (approve)
    uint256 computedTokenAmount;
    if (msg.value == 0) {
      computedTokenAmount = _tokenAmount;
    } else if (tokenPool == 0) {
      computedTokenAmount = msg.value;
    } else {
      computedTokenAmount = (msg.value * tokenPool)/(address(this).balance - msg.value);
    }

    // console.log("Computed tokens from ETH sent is %o", computedTokenAmount);  

    // if computed X tokens is higher than tokenAmount, revert transaction
    require(computedTokenAmount <= _tokenAmount, "computed tokens higher than declared tokens");
    // calculate liquidity (share of pool for tokens and ETH sent)
    uint256 lpSupply = ERC20.totalSupply();
    // console.log("Current LP Token Supply is %o", lpSupply);
    uint256 lpTokenAmount;
    if (lpSupply == 0) {
      lpTokenAmount = computedTokenAmount;
    } else {
      lpTokenAmount = (computedTokenAmount * lpSupply)/tokenPool;
    }

    // console.log("Computed LP tokens from Liquidity Provided is %o", lpTokenAmount);

    // check if we have the allowance to call transferFrom
    require(tokenContract.allowance(msg.sender, address(this)) >= computedTokenAmount, "Provider needs to allow the AMM to transfer tokens first");
    tokenContract.transferFrom(msg.sender, address(this), computedTokenAmount);
    tokenPool += computedTokenAmount;

    // mint LP tokens
    ERC20._mint(msg.sender, lpTokenAmount);
  
    // emitting event
    emit LiquidityAdded(msg.sender, msg.value, computedTokenAmount);

    // returns number of LP tokens as uint256 value
    return lpTokenAmount;
  }

  function removeLiquidity(uint256 _lpAmount) public returns (uint256, uint256) {
    require(this.totalSupply() > 0, "No liquidity provided");
    require(this.balanceOf(msg.sender) >= _lpAmount, "Too high LP amount requested");

    uint256 computedTokenAmount = (_lpAmount * tokenPool)/this.totalSupply();
    uint256 computedETH = (_lpAmount * address(this).balance)/this.totalSupply();

    ERC20._burn(msg.sender, _lpAmount);
    (bool sent, ) = payable(msg.sender).call{value: computedETH}("");
    require(sent, "ETH transfer failed");
    tokenContract.transfer(msg.sender, computedTokenAmount);
    tokenPool -= computedTokenAmount;

    emit LiquidityRemoved(msg.sender, computedETH, computedTokenAmount);

    return (computedETH, computedTokenAmount);
  }

  function getTokenAmount(uint256 _ethSold) public view returns (uint256) {
    require(tokenPool > 0, "No tokens available to buy");
    uint256 ethSoldAfterFee = _ethSold * 99; //charging 1% fee and keeping the remains
    uint256 newETHbalance = (address(this).balance*100) + ethSoldAfterFee;
    uint256 amt = (tokenPool * ethSoldAfterFee)/newETHbalance; 
    return amt;
  }

  function getEthAmount(uint256 _tokenSold) public view returns (uint256) {
    require(address(this).balance > 0, "No ETH to buy");
    uint256 tokenSoldAfterFee = _tokenSold * 99; //charging 1% fee and keeping the remains
    uint256 newTokenPool = (tokenPool*100) + _tokenSold;
    uint256 amt = (address(this).balance * tokenSoldAfterFee)/newTokenPool;
    return amt;
  }

  function ethToToken(uint256 _minTokens) public payable {
    uint256 tokensToSell = this.getTokenAmount(msg.value);
    require(tokensToSell > _minTokens, "Received Token value too low");

    tokenContract.transfer(msg.sender, tokensToSell);

    emit TokenBought(msg.sender, msg.value, tokensToSell);
  }

  function tokenToEth(uint256 _tokensSold, uint256 _minEth) public {
    uint256 ethToSell = this.getEthAmount(_tokensSold);
    require(ethToSell > _minEth, "Received ETH value too low");

    tokenContract.transferFrom(msg.sender, address(this), _tokensSold);
    (bool sent, ) = msg.sender.call{value: ethToSell}("");
    require(sent, "Sending ETH failed");

    emit EthBought(msg.sender, ethToSell, _tokensSold);
  }

  function tokenToTokenSwap(uint256 _tokensSold, uint256 _minTokensBought, address _tokenAddress) public payable {
    address amm = registry.getExchange(_tokenAddress);
    require(amm != address(0), "Token to buy is not registered at registry!");

    AMM otherAMM = AMM(amm);

    // Get equivalent ETH amount of tokensSold
    uint256 eqEth = this.getEthAmount(_tokensSold);
    // Get equivalent minEth amount of minTokensBought
    uint256 eqMinEth = otherAMM.getEthAmount(_minTokensBought);

    require(eqEth >= eqMinEth, "Received Tokens too low");

    // Transfer tokens from sender to us
    tokenContract.transferFrom(msg.sender, address(this), _tokensSold);
    // Emit EthBought Event
    emit EthBought(msg.sender, eqEth, _tokensSold);
    // Send ETH to other AMM and receive tokens in this contract's balance
    otherAMM.ethToToken{value:eqEth}(_minTokensBought);
    
    // Get other Token Contract
    IERC20 otherTokenContract = IERC20(_tokenAddress);
    // Get our balance of the other token
    uint256 receivedTokens = otherTokenContract.balanceOf(address(this));
    require(receivedTokens >= _minTokensBought, "Received Tokens too low");
    // Transfer it to sender
    otherTokenContract.transfer(msg.sender, receivedTokens);
  }
}