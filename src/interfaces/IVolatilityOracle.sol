// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IVolatilityOracle {
    function getPriceVariance() external returns (uint256);
}
