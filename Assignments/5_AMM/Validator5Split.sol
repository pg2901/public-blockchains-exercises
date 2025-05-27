// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Import the Interfaces
import "./interface/IAssignment5.sol";
import "./interface/IAssignment5Coin.sol";

// Import the registry contract to use as Interface
import "./helper/Assignment5Registry.sol";

// Import the exchange
import "./helper/Assignment5Exchange.sol";

// Import the Coin
import "./helper/Assignment5Coin.sol";

// Import the base assignment validator contract
import "../../BaseValidator.sol";

// Test interface
import "./interface/ITest.sol";

// Import Task A, B, C, D
// import "./Validator5TaskA.sol";
// import "./Validator5TaskB.sol";
// import "./Validator5TaskD.sol";

// Give the contract a name and inherit from the base assignment validator
contract Validator5Split is BaseValidator {
    // Contract to validate
    IAssignment5 assignmentContract;

    // Task A, B, C and D
    ITest validatorTaskA;
    ITest validatorTaskB;
    ITest validatorTaskD;

    // Validator5TaskA validatorTaskA;
    // Validator5TaskB validatorTaskB;
    // Validator5TaskD validatorTaskD;

    // Registry contract
    Assignment5Registry registryContract;

    // Coin contract
    Assignment5Coin coinContract;

    // Exchange contract
    Assignment5Exchange exchangeContract;

    constructor(address _configContractAddress, 
        address valAAddress, address valBAddress, address valDAddress)
        payable
        BaseValidator(
            _configContractAddress,
            "SS25 Assignment 5 Validator Contract - Base",
            0.2 ether) 
    {

        // 20000 gwei

        validatorTaskA = ITest(valAAddress);
        validatorTaskB = ITest(valBAddress);
        validatorTaskD = ITest(valDAddress);

        // Assign contracts to the list of helper contracts
        addHelperContracts(valAAddress);
        addHelperContracts(valBAddress);
        addHelperContracts(valDAddress);

        // Create a new coin contract
        coinContract = new Assignment5Coin(
            "SS25 Coin - Assignment 5",
            "SS25",
            _configContractAddress
        );
        addHelperContracts(address(coinContract));

        // Create a new exchange contract
        exchangeContract = new Assignment5Exchange{value: 2000 gwei}(
            address(coinContract),
            _configContractAddress
        );
        addHelperContracts(address(exchangeContract));

        // Create a new registry contract
        registryContract = new Assignment5Registry(
            _configContractAddress,
            address(exchangeContract)
        );
        addHelperContracts(address(registryContract));
    }

    // Fallback function to make sure the contract can receive ether
    receive() external payable {}

    // Test the assignment
    function test(address _contractAddress)
        public
        payable
        override(BaseValidator)
        returns (uint256)
    {
        uint256 testId = createTestHistory(_contractAddress);

        // Call the contract interface which needs to be tested and store it in the variable assignmentContract
        assignmentContract = IAssignment5(_contractAddress);

        // Prepare and donate ether
        if (!donateEther()) {
            // Add the result to the history
            appendTestResult("Error with donateEther", false, 0);
            return testId;
        }

        /*----------  EXERCISE A  ----------*/

        // Init the task A contract
        validatorTaskA.initContract(_contractAddress, address(0), address(0));

        // if (hasFunction(address(validatorTaskA), "test", 0.02 ether)) {
            // Run tests
            (string memory messageA, bool successA) = validatorTaskA
                .test{value: 0.02 ether}();
            if (successA) {
                // Add the result to the history
                appendTestResult(messageA, true, 1);
            } else {
                // Add the result to the history
                appendTestResult(messageA, false, 0);
            }
        // } else {
        //     appendTestResult(
        //         "A: Some of the required functions not correctly implemented.",
        //         false,
        //         0
        //     );
        // }

        /*----------  EXERCISE B  ----------*/

        // Init the task B contract
        validatorTaskB.initContract(_contractAddress, address(0), address(0));

        if (
            hasFunction(address(validatorTaskB), "test()", 1000 gwei)
        ) {
            // Run tests
            (string memory messageB, bool successB) = validatorTaskB
                .test{value: 1000 gwei}();
            if (successB) {
                // Add the result to the history
                appendTestResult(messageB, true, 13);
            } else {
                // Add the result to the history
                appendTestResult(messageB, false, 0);
            }
        } else {
            appendTestResult(
                "B: Some of the required functions not correctly implemented.",
                false,
                0
            );
        }

        /*----------  EXERCISE C  ----------*/

        appendTestResult("C: Events will be tested offline.", true, 1);

        /*----------  EXERCISE D  ----------*/

        // Init the task D contract
        validatorTaskD.initContract(
            _contractAddress,
            address(registryContract),
            address(coinContract)
        );

        if (hasFunction(address(validatorTaskD), "test()", 200 gwei)) {
            // Run tests
            (string memory messageD, bool successD) = validatorTaskD
                .test{value: 200 gwei}();

            if (successD) {
                // Add the result to the history
                appendTestResult(messageD, true, 8);
            } else {
                // Add the result to the history
                appendTestResult(messageD, false, 0);
            }
        } else {
            appendTestResult(
                "D: Some of the required functions not correctly implemented.",
                false,
                0
            );
        }

        return testId;
    }

    /*=============================================
    =                    HELPER                  =
    =============================================*/

    // Donate ether to the contract if the balance is 0
    function donateEther() public payable returns (bool) {
        if (address(assignmentContract).balance == 0) {
            try assignmentContract.donateEther{value: 100 gwei}() {
                return true;
            } catch {
                return false;
            }
        }
        return true;
    }

    /*=====          End of HELPER        ======*/
}
