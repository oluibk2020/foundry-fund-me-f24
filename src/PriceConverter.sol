// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    //working with solidity ABI Interface
    function getVersion(AggregatorV3Interface priceFeed) internal  view returns (uint256)  {
        //Address - 0x694AA1769357215DE4FAC081bf1f309aDC325306
        //and ABI - Aggregatorv3Interface

        // AggregatorV3Interface priceData = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
       return  priceFeed.version(); //returns the version which is in uint256
    }

    function getPrice(AggregatorV3Interface priceFeed) internal view  returns (uint256) {
        //Address - 0x694AA1769357215DE4FAC081bf1f309aDC325306
        //and ABI - Aggregatorv3Interface
        // AggregatorV3Interface priceData = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
       (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        
        //price of ETH in terms of USD
        //answer returned of ETH are in 8 zeros i.e 1.00000000 - type int256 while
        //msg.value price is 18 zeros 1.e 1.000000000000000000 -type uint256
        //so we need them to match up, adding 10 more decimals

        return  uint256(answer * 1e10); // - adding 10 more decimals - converting TYPE int256 to uint256
    }

//get conversion rate in terms of usd of the ETH 
    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        // 1 ETH?
        // 2000_000000000000000000
        uint256 ethPrice = getPrice(priceFeed);
        // (2000_00000000000000000 * 1_000000000000000000) / 1e18
        // $2000 = 1 ETH
        uint256 ethAmountInUsd = (ethPrice * ethAmount)/ 1e18;
        return  ethAmountInUsd;
    }

}

//gas to create contract - 817513wei

