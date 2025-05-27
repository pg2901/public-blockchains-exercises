// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Import IERC20.sol
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Import the IAssignment5.sol
import "./interface/IAssignment5.sol";

// Import coin interface
import "./interface/IAssignment5Coin.sol";

// Import Helper
import "../../Helper.sol";

// import "BaseConfig.sol";
import "../../BaseConfig.sol";

contract Validator5TaskB is Helper, BaseConfig {
    // assignment contract interface
    IAssignment5 assignmentContract;

    // Address of the validator contract for task A
    address validatorAddress;

    // Address of exchange contract/ student contract
    address exchangeAddress;

    constructor(address _configContractAddress) {
        initAdmin(
            _configContractAddress,
            "SS25 Ass 5 Validator - B"
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

        // Set Address for convenience
        validatorAddress = address(this);
        exchangeAddress = address(_contractAddress);
    }

    function test() public payable returns (string memory, bool) {
        // Prepare

        address tokenAddress = address(0);

        try assignmentContract.getTokenAddress() returns (
            address _tokenAddress
        ) {
            tokenAddress = _tokenAddress;
        } catch {
            return (
                "Error (B): Error with getTokenAddress",
                false
            );
        }

        // check that token address is no address(0)
        if (tokenAddress == address(0)) {
            return (
                "Error (B): token address is address(0)",
                false
            );
        }

        // TEST 1: Test AddLiquidity function
        (string memory message1, bool success1) = testAddLiquidity(
            tokenAddress
        );
        if (!success1) return (message1, false);

        // TEST 2: Test RemoveLiquidity function
        (string memory message2, bool success2) = testRemoveLiquidity(
            tokenAddress
        );
        if (!success2) return (message2, false);

        // TEST 3: Test Swap function
        (string memory message3, bool success3) = testGetTokenAmount(
            tokenAddress
        );
        if (!success3) return (message3, false);

        // TEST 4: Test Get Eth Amount function
        (string memory message4, bool success4) = testGetEthAmount(
            tokenAddress
        );
        if (!success4) return (message4, false);

        // TEST 5: Test Eth to Token Swap function
        (string memory message5, bool success5) = testEthToToken(tokenAddress);
        if (!success5) return (message5, false);

        // TEST 6: Test Token to Eth Swap function
        (string memory message6, bool success6) = testTokenToEth(tokenAddress);
        if (!success6) return (message6, false);

        return ("Ex B: All tests passed", true);
    }

    /**
     * TEST EXERCISE B
     * - test addLiquidity function
     */
    function testAddLiquidity(address tokenAddress)
        public
        payable
        returns (string memory, bool)
    {
        /*----------  EXERCISE B  ----------*/

        // Add some liquidity if reserve is empty
        // Prepare test
        // Mint 100 wei tokens to the validator address
        IAssignment5Coin(tokenAddress).mint(validatorAddress, 100 gwei);
        IAssignment5Coin(tokenAddress).approve(exchangeAddress, 100 gwei);

        try assignmentContract.addLiquidity{value: 0}(100 gwei) {
            // Check if the liquidity is added
            if (assignmentContract.totalSupply() == 0) {
                return (
                    "Error (B - addLiquidity): liquidity is 0",
                    false
                );
            }
        } catch {
            return (
                "Error (B - addLiquidity): Error with the addLiquidity() function",
                false
            );
        }

        // TEST START --->

        // throw error if the reserve is empty
        if (exchangeAddress.balance == 0) {
            return (
                "Error (B - addLiquidity): eth balance of the exchange is empty",
                false
            );
        }

        // ETH amount to send
        uint256 testMsgValue = 100 gwei;

        // Calculate the amount of tokens to buy
        uint256 ethReserve = (exchangeAddress.balance + testMsgValue) -
            testMsgValue;
        uint256 tokenReserve = getReserve(tokenAddress);
        uint256 tokenAmount = (testMsgValue * tokenReserve) / ethReserve;

        // Token amount to buy
        uint256 testTokenAmount = tokenAmount;

        // Mint some tokens for the validator to add to liquidity pool
        if (
            testTokenAmount >
            IAssignment5Coin(tokenAddress).balanceOf(validatorAddress)
        ) {
            IAssignment5Coin(tokenAddress).mint(
                validatorAddress,
                testTokenAmount
            );
        }

        uint256 liquidity = (assignmentContract.totalSupply() * testMsgValue) /
            ethReserve;

        // Throw error > liquidity cannot be 0
        if (liquidity == 0) {
            return (
                "Error (B - addLiquidity): expected liquidity is 0. Add some funds to the exchange to ensure testing works",
                false
            );
        }

        // Set Allowance
        IERC20(tokenAddress).approve(exchangeAddress, testTokenAmount);

        // Token of validatorAddress before
        uint256 tokenBalanceBefore = IERC20(tokenAddress).balanceOf(
            validatorAddress
        );

        // Exchange token before
        uint256 exchangeTokenBalanceBefore = assignmentContract.balanceOf(
            validatorAddress
        );

        // addLiquidity function
        try
            assignmentContract.addLiquidity{value: testMsgValue}(
                testTokenAmount
            )
        returns (uint256 gotLiquidity) {
            if (gotLiquidity != liquidity) {
                return (
                    string.concat(
                        "Error (B - addLiquidity): calculated liquidity not correct! Expected: ",
                        Strings.toString(liquidity),
                        " Actual: ",
                        Strings.toString(gotLiquidity)
                    ),
                    false
                );
            }

            // Token of validatorAddress after
            uint256 tokenBalanceAfter = IERC20(tokenAddress).balanceOf(
                validatorAddress
            );

            if (tokenBalanceBefore - testTokenAmount != tokenBalanceAfter) {
                return (
                    "Error (B - addLiquidity): token balance for validator not correct",
                    false
                );
            }

            // Exchange token after
            uint256 exchangeTokenBalanceAfter = assignmentContract.balanceOf(
                validatorAddress
            );

            if (
                exchangeTokenBalanceBefore + liquidity !=
                exchangeTokenBalanceAfter
            ) {
                return (
                    "Error (B - addLiquidity): exchange token balance not correct",
                    false
                );
            }

            // check if total supply increased
            if (assignmentContract.totalSupply() == 0) {
                return (
                    "Error (B - addLiquidity): total supply is 0, should be larger than 0",
                    false
                );
            }
        } catch Error(string memory _reason) {
            return (
                buildErrorMessage(
                    "Error (B - addLiquidity)",
                    "Error with the addLiquidity function",
                    _reason
                ),
                false
            );
        }

        return ("Exercise B (addLiquidity): Passed", true);
    }

    /**
     * TEST EXERCISE B
     * - test removeLiquidity function
     */
    function testRemoveLiquidity(address tokenAddress)
        public
        payable
        returns (string memory, bool)
    {
        // Prepare test
        // Mint 100 wei tokens to the validator address
        IAssignment5Coin(tokenAddress).mint(validatorAddress, 100 wei);
        IAssignment5Coin(tokenAddress).approve(exchangeAddress, 100 wei);
        assignmentContract.addLiquidity{value: 100 wei}(100 wei);

        // Prepare end

        uint256 testRemoveAmount = 1;

        uint256 exchangeBalanceBefore = assignmentContract.balanceOf(
            validatorAddress
        );

        uint256 supply = assignmentContract.totalSupply();

        if (supply == 0) {
            return (
                "Error (B - removeLiquidity): total supply is 0, should be larger than 0",
                false
            );
        }

        uint256 ethAmount = (exchangeAddress.balance * testRemoveAmount) /
            supply;

        uint256 tokenAmount = (getReserve(tokenAddress) * testRemoveAmount) /
            supply;

        // Get eth balance of validator before
        uint256 ethBalanceBefore = validatorAddress.balance;
        uint256 tokenBalanceBefore = IERC20(tokenAddress).balanceOf(
            validatorAddress
        );

        try assignmentContract.removeLiquidity(testRemoveAmount) {
            // Get eth balance of validator after

            uint256 ethBalanceAfter = validatorAddress.balance;
            uint256 tokenBalanceAfter = IERC20(tokenAddress).balanceOf(
                validatorAddress
            );
            uint256 exchangeBalanceAfter = assignmentContract.balanceOf(
                validatorAddress
            );

            if (
                exchangeBalanceBefore - testRemoveAmount != exchangeBalanceAfter
            ) {
                return (
                    "Error (B - removeLiquidity): Burning of exchange token did not work properly",
                    false
                );
            }

            if (ethBalanceBefore + ethAmount != ethBalanceAfter) {
                return (
                    "Error (B - removeLiquidity): ETH balance not correct",
                    false
                );
            }

            if (tokenBalanceBefore + tokenAmount != tokenBalanceAfter) {
                return (
                    "Error (B - removeLiquidity): token balance not correct",
                    false
                );
            }
        } catch Error(string memory _reason) {
            return (
                string(
                    abi.encodePacked(
                        "Error (B - removeLiquidity): Error with the removeLiquidity function",
                        _reason
                    )
                ),
                false
            );
        }

        return ("Exercise B (removeLiquidity): Passed", true);
    }

    /**
     * TEST EXERCISE B
     * - test getTokenAmount function
     */
    function testGetTokenAmount(address tokenAddress)
        public
        payable
        returns (string memory, bool)
    {
        // ethSold
        uint256 ethSold = 0.001 ether;

        uint256 expectedTokenAmount = getAmount(
            ethSold,
            exchangeAddress.balance,
            getReserve(tokenAddress)
        );

        try assignmentContract.getTokenAmount(ethSold) returns (
            uint256 realTokenAmount
        ) {
            if (expectedTokenAmount != realTokenAmount) {
                return (
                    "Error (B - getTokenAmount): token amount not correct",
                    false
                );
            }
        } catch Error(string memory _reason) {
            return (
                string(
                    abi.encodePacked(
                        "Error (B - getTokenAmount): Error with the getTokenAmount function",
                        _reason
                    )
                ),
                false
            );
        }

        return ("Exercise B (getTokenAmount): Passed", true);
    }

    /**
     * TEST EXERCISE B
     * - test getEthAmount function
     */
    function testGetEthAmount(address tokenAddress)
        public
        payable
        returns (string memory, bool)
    {
        // tokenSold
        uint256 tokenSold = 1;

        uint256 expectedEthAmount = getAmount(
            tokenSold,
            getReserve(tokenAddress),
            exchangeAddress.balance
        );

        try assignmentContract.getEthAmount(tokenSold) returns (
            uint256 realEthAmount
        ) {
            if (expectedEthAmount != realEthAmount) {
                return (
                    "Error (B - getEthAmount): ETH amount not correct",
                    false
                );
            }
        } catch Error(string memory _reason) {
            return (
                string(
                    abi.encodePacked(
                        "Error (B - getEthAmount): Error with the getEthAmount function",
                        _reason
                    )
                ),
                false
            );
        }

        return ("Exercise B (getEthAmount): Passed", true);
    }

    /**
     * TEST EXERCISE B
     * - test ethToToken function
     */
    function testEthToToken(address tokenAddress)
        public
        payable
        returns (string memory, bool)
    {
        uint256 msgValue = 100 gwei;

        // Mint 1000 wei tokens to the exchange address
        IAssignment5Coin(tokenAddress).mint(exchangeAddress, 1000 wei);

        uint256 expectedTokenBought = getAmount(
            msgValue,
            exchangeAddress.balance,
            getReserve(tokenAddress)
        );

        if (expectedTokenBought == 0) {
            return (
                "Error (B - ethToToken): expected token bought is 0, should be larger than 0",
                false
            );
        }

        // Set minToken to expectedTokenBought - 10 wei
        uint256 minToken = expectedTokenBought - 10 wei;

        uint256 tokenBalanceBefore = IERC20(tokenAddress).balanceOf(
            validatorAddress
        );

        try assignmentContract.ethToToken{value: msgValue}(minToken) {
            uint256 tokenBalanceAfter = IERC20(tokenAddress).balanceOf(
                validatorAddress
            );

            if (tokenBalanceBefore + expectedTokenBought != tokenBalanceAfter) {
                return (
                    "Error (B - ethToToken): token balance not correct",
                    false
                );
            }
        } catch Error(string memory _reason) {
            return (
                string(
                    abi.encodePacked(
                        "Error (B - ethToToken): Error with the ethToToken function! - ",
                        _reason
                    )
                ),
                false
            );
        }

        return ("Exercise B (ethToToken): Passed", true);
    }

    /**
     * TEST EXERCISE B
     * - test tokenToEth function
     */
    function testTokenToEth(address tokenAddress)
        public
        payable
        returns (string memory, bool)
    {
        uint256 tokenSold = 100 gwei;

        uint256 expectedEthBought = getAmount(
            tokenSold,
            (exchangeAddress.balance),
            getReserve(tokenAddress)
        );

        if (expectedEthBought == 0) {
            return (
                "Error (B - tokenToEth): expected ETH bought is 0",
                false
            );
        }

        if (expectedEthBought >= exchangeAddress.balance) {
            return (
                "Error (B - tokenToEth): validator address does not have enough ETH",
                false
            );
        }

        if (tokenSold >= IERC20(tokenAddress).balanceOf(validatorAddress)) {
            IAssignment5Coin(tokenAddress).mint(validatorAddress, tokenSold);
        }

        uint256 minEth = expectedEthBought - 1 wei;

        uint256 ethBalanceBefore = validatorAddress.balance;
        uint256 tokenBalanceBefore = IERC20(tokenAddress).balanceOf(
            validatorAddress
        );

        IERC20(tokenAddress).approve(exchangeAddress, tokenSold);

        try assignmentContract.tokenToEth(tokenSold, minEth) {
            uint256 ethBalanceAfter = validatorAddress.balance;
            uint256 tokenBalanceAfter = IERC20(tokenAddress).balanceOf(
                validatorAddress
            );

            if (tokenBalanceBefore - tokenSold != tokenBalanceAfter) {
                return (
                    "Error (B - tokenToEth): token balance not correct",
                    false
                );
            }

            if (ethBalanceBefore + expectedEthBought != ethBalanceAfter) {
                return (
                    "Error (B - tokenToEth): ETH balance not correct",
                    false
                );
            }
        } catch Error(string memory _reason) {
            return (
                string(
                    abi.encodePacked(
                        "Error (B - tokenToEth): Error with the tokenToEth function",
                        _reason
                    )
                ),
                false
            );
        }

        return ("Exercise B (tokenToEth): Passed", true);
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
