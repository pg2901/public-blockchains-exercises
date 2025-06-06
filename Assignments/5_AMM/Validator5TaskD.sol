// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Import the IAssignment5.sol
import "./interface/IAssignment5.sol";

// Import the coin interface
import "./interface/IAssignment5Coin.sol";

// Import the registry to use as interface
import "./helper/Assignment5Registry.sol";

// Import Helper
import "../../Helper.sol";

// import "BaseConfig.sol";
import "../../BaseConfig.sol";

contract Validator5TaskD is Helper, BaseConfig {
    // assignment contract interface
    IAssignment5 assignmentContract;

    // Address of registry contract
    address registryAddress;

    // Address of test token contract
    address tokenTestAddress;

    // Address of exchange contract/ student contract
    address exchangeAddress;

    constructor(address _configContractAddress) {
        initAdmin(
            _configContractAddress,
            "SS25 Ass 5 Validator - D"
        );
    }

    receive() external payable {}

    // Init contract
    function initContract(
        address _contractAddress,
        address _registryAddress,
        address _coinAddress
    ) public {
        // Call the contract interface which needs to be tested and store it in the variable assignmentContract
        assignmentContract = IAssignment5(_contractAddress);

        // Set registry address
        registryAddress = _registryAddress;

        // Set test token address
        tokenTestAddress = _coinAddress;

        // Set exchange address

        exchangeAddress = _contractAddress;
    }

    /**
     * TEST EXERCISE D
     *
     * - test tokenToTokenSwap function
     */
    function test() public payable returns (string memory, bool) {
        /*----------  EXERCISE D  ----------*/

        address validatorAddress = address(this);
        address exchange2Address = Assignment5Registry(registryAddress)
            .getExchange(tokenTestAddress);

        IAssignment5Coin tokenStudent = IAssignment5Coin(
            assignmentContract.getTokenAddress()
        );

        IAssignment5Coin tokenTest = IAssignment5Coin(tokenTestAddress);

        IAssignment5 exchangeTest = IAssignment5(exchange2Address);

        // SWAP TOKENS

        // Collect balance before

        // Get student token before
        uint256 tokenStudentBalanceBefore = tokenStudent.balanceOf(
            validatorAddress
        );

        // Get test token before
        uint256 tokenTestBalanceBefore = tokenTest.balanceOf(validatorAddress);

        // SWAP

        uint256 tokensSold = 100 gwei;

        // Mint tokens for the validator
        tokenStudent.mint(validatorAddress, 1000 gwei);
        tokenTest.mint(validatorAddress, 1000 gwei);

        // Calculate eth amount
        uint256 tokensBought = getAmount(
            10 gwei,
            address(assignmentContract).balance - 10 gwei,
            getReserve(tokenTestAddress)
        );

        // Set Allowance
        tokenStudent.approve(address(assignmentContract), 1000 gwei);
        tokenTest.approve(address(assignmentContract), 1000 gwei);
        tokenTest.approve(address(exchangeTest), 1000 gwei);

        try exchangeTest.addLiquidity{value: 10 gwei}(200 gwei) {} catch Error(
            string memory _reason
        ) {
            return (
                string(
                    abi.encodePacked(
                        "Error (D): addLiquidity problem - ",
                        _reason
                    )
                ),
                false
            );
        }

        try
            assignmentContract.tokenToTokenSwap{value: 100 gwei}(
                tokensSold,
                tokensBought + 1,
                tokenTestAddress
            )
        {
            // Get student token after
            uint256 tokenStudentBalanceAfter = tokenStudent.balanceOf(
                validatorAddress
            );

            // Get test token after
            uint256 tokenTestBalanceAfter = tokenTest.balanceOf(
                validatorAddress
            );

            if (tokenStudentBalanceAfter <= tokenStudentBalanceBefore) {
                return (
                    "Error (D): The exchange token balance is not correct!",
                    false
                );
            }

            if (tokenTestBalanceAfter <= tokenTestBalanceBefore) {
                return (
                    "Error (D): The test token balance is not correct!",
                    false
                );
            }
        } catch Error(string memory _reason) {
            return (
                string(
                    abi.encodePacked(
                        "Error (D): TOKEN TO TOKEN - ",
                        _reason
                    )
                ),
                false
            );
        }

        return ("Exercise D: All tests passed!", true);
    }

    /*=============================================
    =                    HELPER                  =
    =============================================*/

    function getReserve(address tokenAddress) public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(exchangeAddress);
    }

    function getAmount(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) private pure returns (uint256) {
        uint256 inputAmountWithFee = inputAmount * 99;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;

        // return (inputAmount * outputReserve) / (inputReserve + inputAmount);

        require(denominator > 0, "ERR_ZERO_DENOMINATOR");
        return numerator / denominator;
    }

    /*=====          End of HELPER        ======*/
}
