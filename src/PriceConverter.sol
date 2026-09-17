// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    error PriceConverter__InvalidPrice();
    error PriceConverter__StalePrice();

    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (
            uint80 roundId,
            int256 price,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        if (price <= 0 || answeredInRound < roundId) {
            revert PriceConverter__InvalidPrice();
        }

        if (block.timestamp - updatedAt > 3 hours) {
            revert PriceConverter__StalePrice();
        }

        // forge-lint: disable-next-line(unsafe-typecast)
        return uint256(price) * 1e10;
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        return (ethPrice * ethAmount) / 1e18;
    }
}