// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("Alice_Test_User");
    uint256 constant USER_STARTING_BALANCE = 500 ether;
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();

        vm.deal(USER, USER_STARTING_BALANCE); //cheat code to give a user a starting balance
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); //hey the next line should fail, that means that it is successfully reverted
        fundMe.fund{value: 1000000000000000}(); // send 0 value since nothing was passed
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); //The next transaction would be sent by USER
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddFundsToArrayOfFunders() public {
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

    function testOnlyOwnerCanWithdraw() public funded { //added a user modifier
        vm.prank(USER); //another user
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdawAsASingleFunder()  public funded {
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Action
            uint256 gasStart = gasleft(); //1000
            vm.txGasPrice(GAS_PRICE);
            vm.prank(fundMe.getOwner()); //used 200 gas
            fundMe.withdraw();
            uint256 gasEnd = gasleft(); //800gas left
            uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
            console.log(gasUsed);
        //assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        //Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex;  i < numberOfFunders; i++) {
            
            hoax(address(i), SEND_VALUE); //CREAte an address with balaance
            fundMe.fund{value: SEND_VALUE}(); //the created user fund the smart contract
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Action
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //assert
        assertEq(address(fundMe).balance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, fundMe.getOwner().balance);

    }
    function testWithdrawFromMultipleFundersCheaperWithdraw() public funded {
        //Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex;  i < numberOfFunders; i++) {
            
            hoax(address(i), SEND_VALUE); //CREAte an address with balaance
            fundMe.fund{value: SEND_VALUE}(); //the created user fund the smart contract
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Action
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        //assert
        assertEq(address(fundMe).balance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, fundMe.getOwner().balance);

    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18); //assertEqual
    }

    function testOwnerIsMsgSender() public {
        // console.log(fundMe.i_owner(), msg.sender);
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();

        console.log(version);

        assertEq(version, 4);
    }
}
