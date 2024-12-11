// CalculationV1.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {ICambrianClient} from "./interfaces/ICambrianClient.sol";

import "forge-std/console.sol";

contract VolatilityOracle is Ownable {
    ICambrianClient public cambrianClient;

    uint256 public priceVariance;

    event VarianceUpdate(uint256 variance, uint256 timestamp);

    constructor() Ownable(msg.sender) {
        priceVariance = 0;
    }

    function updatePriceVariance(uint256[] memory prices) public onlyOwner returns (uint256) {
        uint256 mean = 0;

        for (uint256 i = 0; i < prices.length; i++) {
            mean += prices[i];
        }

        mean /= prices.length;

        uint256 variance = 0;
        for (uint256 i = 0; i < prices.length; i++) {
            if (prices[i] > mean) {
                variance += (prices[i] - mean) * (prices[i] - mean);
            } else {
                variance += (mean - prices[i]) * (mean - prices[i]);
            }
        }
        variance /= prices.length;
        priceVariance = variance;

        emit VarianceUpdate(variance, block.timestamp);

        return variance;
    }

    function forceUpdatePriceVariance(uint256 variance) public onlyOwner {
        priceVariance = variance;
    }

    function getPriceVariance() public view returns (uint256) {
        return priceVariance;
    }
}
