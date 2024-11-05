// CalculationV1.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {ICambrianClient} from "./interfaces/ICambrianClient.sol";

contract VolatilityOracle is Ownable {
    ICambrianClient public cambrianClient;

    uint256 public priceVariance;

    event PriceVarianceUpdated(uint256 priceVariance);

    constructor(address _cambrianClient) Ownable(msg.sender) {
        cambrianClient = ICambrianClient(_cambrianClient);
    }

    function updatePriceVariance(uint256[] memory prices) public returns (uint256) {
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

        emit PriceVarianceUpdated(variance);

        return variance;
    }
}
