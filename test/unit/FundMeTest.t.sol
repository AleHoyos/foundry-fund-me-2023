// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    //In this contract, we are inheritating everything from the 'Test' contract.
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1; //We set this constant to use in the txGasPrice cheatcode.

    function setUp() external {
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306); //The fundMe variable of type FundMe is equal to a new FundMe contract. We are deploying our FundMe contract.
        //On all of our tests, the first thing that happens is to create this setUp function, which is where we are going to deploy our contract.
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18); //We are calling this variable from the FundMe contract.
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender); //We are calling this variable from the FundMe contract.
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        //We are testing whether the condition of sending at least 5 ETH is working correctly.
        vm.expectRevert(); //With this, we are expecting the next line to revert.
        fundMe.fund(); //As we are not sending any value and the condition is to send at least 5 eth, it reverts.
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); //With this, we are saying that the next TX will be sent by USER.
        fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        //First we need to fund it:
        vm.prank(USER);
        //fundMe.fund{value: SEND_VALUE}();

        //As the USER is not the owner and should not be able to withdraw, we expect a revert:
        vm.expectRevert(); //With this, we are going to pretend being the USER for the next TX line.
        //vm.prank(USER);
        fundMe.withdraw(); //This is the line that is expected to revert because is a TX line (it skips the 'vm').
    }

    function testWithdrawWithASingleFunder() public funded {
        //Arrange:
        uint256 startingOwnerBalance = fundMe.getOwner().balance; //We get the owner's starting balance.
        uint256 startingFundMeBalance = address(fundMe).balance; //This is the actual balance of the FundMe contract (sin e it's funded, it's equal to SEND_VALUE).

        //Act:
        uint256 gasStart = gasleft(); //If we sent 1000 gas.
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner()); //And this costed 200 gas.
        fundMe.withdraw(); //By calling this transaction, should it have spent gas?

        uint256 gasEnd = gasleft(); //Then we would have 800 gas.
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; //Gas used from the withdraw() transaction is equal to that.
        console.log(gasUsed);

        //Assert.
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0); //The 'endingFundMeBalance' should be equal to zero because the owner withdraw all the funds.
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public {
        //Arrange.
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act.
        vm.startPrank(fundMe.getOwner()); //Anything in between start and stop prank is going to be pretended to be sent by that address.
        fundMe.withdraw();
        vm.stopPrank();

        //Assert.
        assert(address(fundMe).balance == 0); //Check if we removed all of the funds from fundMe.
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }

    function testWithdrawFromMultipleFundersCheaper() public {
        //Arrange.
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act.
        vm.startPrank(fundMe.getOwner()); //Anything in between start and stop prank is going to be pretended to be sent by that address.
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        //Assert.
        assert(address(fundMe).balance == 0); //Check if we removed all of the funds from fundMe.
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
}
