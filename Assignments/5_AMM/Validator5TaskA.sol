// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Import IERC20.sol
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Import the IAssignment4.sol
import "./interface/IAssignment5.sol";

// Import coin interface
import "./interface/IAssignment5Coin.sol";

// Import Helper
import "../../Helper.sol";

// import "BaseConfig.sol";
import "../../BaseConfig.sol";

contract Validator5TaskA is Helper, BaseConfig {
    // assignment contract interface
    IAssignment5 assignmentContract;

    // Address of the validator contract for task A
    address validatorAddress;

    constructor(address _configContractAddress) {
        initAdmin(
            _configContractAddress,
            "SS25 Ass 5 Validator - A"
        );
    }

    receive() external payable {}

    // Init contract
    function initContract(address _contractAddress, 
                          address _registryAddress,
                          address _coinAddress) 
        public {
        // Call the contract interface which needs to be tested and store it in the variable assignmentContract
        assignmentContract = IAssignment5(_contractAddress);

        validatorAddress = address(this);
    }

    /**
     * TEST EXERCISE A
     *
     * - test getTokenAddress function
     * - test mint function
     */
    function test() public payable returns (string memory, bool) {
        /*----------  EXERCISE A  ----------*/

        uint256 testCounter = 0;

        address tokenAddress = address(0);

        try assignmentContract.getTokenAddress() returns (
            address _tokenAddress
        ) {
            tokenAddress = _tokenAddress;
        } catch {
            return (
                "Error (A): Error with getTokenAddress",
                false
            );
        }

        if (tokenAddress == address(0)) {
            return (
                "Error (A): token address not correct",
                false
            );
        }

        uint256 tokenBalanceBeforeTaskB = IERC20(tokenAddress).balanceOf(
            validatorAddress
        );

        uint256 amount = 10000 gwei;

        try IAssignment5Coin(tokenAddress).mint(validatorAddress, amount) {
            uint256 tokenBalanceAfterTaskB = IERC20(tokenAddress).balanceOf(
                validatorAddress
            );

            if (tokenBalanceAfterTaskB - tokenBalanceBeforeTaskB == amount) {
                testCounter++;
            } else {
                return (
                    "Error (A): token balance for validator not correct",
                    false
                );
            }
        } catch {
            return ("Error (A): Error with mint function", false);
        }

        return ("Exercise A: All tests passed", true);
    }
}
