// SPDX-License-Identifier: MIT
// 1. Pragma
pragma solidity ^0.8.18;
// 2. Imports

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol"; //remember to import in terminal with "forge install smartcontractkit/chainlink-brownie-contracts"
import {PriceConverter} from "./PriceConverter.sol";

//Error handler
error FundMe__NotOwner();

/**
 * @title A sample Funding Contract
 * @author Olugbenga Taiwo
 * @notice This contract is for creating a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
    using PriceConverter for uint256;

//let's learn about- constant or immutable keyword -- saves gas
    address[] private s_funders; //to store the senders addresses

    address private immutable i_owner; //it is immutable, that is once, it's set, cannot be changed again

    mapping (address funder => uint256 amountFunded) private s_addressToAmountFunded;

//constant variable because the value is set/initialized at declaration
    uint256 public constant MINIMUM_USD = 5e18; //converting the usd to wei - 5usd

    AggregatorV3Interface private s_priceFeed;

//constructor are like function that are immediately called when the contract is deployed
    constructor(address priceFeed) {
        i_owner = msg.sender; //this msg.sender address would be the deployer of the contract address
        s_priceFeed = AggregatorV3Interface(priceFeed);

    }

   

    //allow users send ETH and minimum usd through a function
    //payable allows the function to rececive payment
    function fund() public payable  {
        //what is revert
        //undo any actions that might have been done and send the remaining gas back
        

        //we use msg.value to get the wei(ETH) sent
        //we can use the require() for logical operation
        //msg.value is going to be the first params to be passed into the getConversionRate func
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "didn't send enough ETH"); // 1e18 means 1ETH which means 1000000000000000000(18 zeros)wei
       
       //push the sender address to array
        s_funders.push(msg.sender); // to get the sender address of the funds

        // assign address to the key and assign ETH to the value
        
        s_addressToAmountFunded[msg.sender]  +=  msg.value; //using the += to update the value of the key

    }

     function getVersion() public view returns (uint256) {
        // uint256 version = PriceConverter.getVersion();
       return  s_priceFeed.version();
    }

    function cheaperWithdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length;

        //looping through an array 
        for (uint256 funderIndex = 0; funderIndex < fundersLength; funderIndex++){
           address funder = s_funders[funderIndex]; 
           s_addressToAmountFunded[funder] = 0;
        }

        //resetting an array
        s_funders = new address[](0);

        //call - seems to be the best recommended - i commented out transfer and send
       (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Send Failed");

    }

// we added a modifier to allow only the owner access the content of the function
    function withdraw() public onlyOwner {

        //make sure the withdrawer address is the owner --- i used modifier instead
        // require(msg.sender == i_owner, "Must be owner");

        //code
        //for loop
        //[1,2,3,4] element
        //0,1,2,3 indexes

        //looping through an array 
        for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++){
           address funder = s_funders[funderIndex]; 
           s_addressToAmountFunded[funder] = 0;
        }

        //resetting an array
        s_funders = new address[](0);

        //actually withdraw the funds
        // 3 different ways to withdraw ETH- transfer, send and call
        //transfer(least recommended)
        // payable(msg.sender).transfer(address(this).balance); //transfer - automatically throws an error if the gas is above 2300 wei

        //send (recommended)
        // bool sendSuccess = payable (msg.sender).send(address(this).balance); //it returns a boolean if the gas is above 2300wei
        // require(sendSuccess, "Send Failed");

        //call - seems to be the best recommended - i commented out transfer and send
       (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Send Failed");

    }

    modifier onlyOwner(){
        // require(msg.sender == i_owner, "Sender must be the owner!");
        
        if (msg.sender != i_owner) { //we are using the new error Handler instead of require
            revert FundMe__NotOwner();
        }
        _; //this continues the code in the function where the modifier is called
    }

    //what happens if someone sends this contract ETH without using the send func.

    //receive()
    receive() external payable { 
        fund();
    }
    //fallback()
    fallback() external payable { 
        fund();
    }

    //view/Pure functions (Getter)
    function getAddressToAmountFunded(address fundingAddress) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner()  external view returns (address) {
        return i_owner;
    }

}