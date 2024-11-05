// CalculationV1.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IVolatilityOracle} from "./interfaces/IVolatilityOracle.sol";

contract FeeOracle is Ownable {
    uint256 public ETH_VOL_SCALE = 150;
    uint256 public MIN_FEE = 0;

    IVolatilityOracle public volatilityOracle;

    constructor(address _volatilityOracle) Ownable(msg.sender) {
        volatilityOracle = IVolatilityOracle(_volatilityOracle);
    }

    function getFee(uint256 volume, uint160 currentPrice) external returns (uint24) {
        return calculateFeeDecimal(volume, volatilityOracle.getPriceVariance(), currentPrice);
    }

    /// @notice Calculates fee percentage as a decimal with 18 decimals precision
    /// @param volume The trading volume
    /// @param variance The price variance (expected as a decimal, e.g., 0.5 = 0.5e18)
    /// @param price The current price as a decimal (e.g., 2000.5 = 2000.5e18)
    /// @return feePercent The fee percentage as a decimal (e.g., 0.01 = 1% = 0.01e18)
    function calculateFeeDecimal(uint256 volume, uint256 variance, uint256 price) public view returns (uint24) {
        // Scale volume by ETH_VOL_SCALE
        uint256 scaledVolume = (volume * 1e18) / ETH_VOL_SCALE;

        // Calculate base fee with constant factor
        uint256 constantFactor = 2e18; // 2.0 in fixed point
        uint256 feePerLot = MIN_FEE + ((constantFactor * scaledVolume * variance) / 1e36);

        // Convert to percentage of price
        uint256 feePercent = (feePerLot * 1e18) / price;

        // Convert to basis points (1 bp = 0.01%)
        return uint24((feePercent * 10000) / 1e18);
    }

    function setMinFee(uint256 _minFee) public onlyOwner {
        MIN_FEE = _minFee;
    }
}
