// CalculationV1.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IVolatilityOracle} from "./interfaces/IVolatilityOracle.sol";

contract FeeOracle is Ownable {
    uint256 public STANDARD_VOLUME = 150;
    uint256 public VOLUME_DECIMALS = 1e18;

    uint256 public STANDARD_VARIANCE = 30;
    uint256 public VARIANCE_DECIMALS = 1e7;

    uint256 public CONSTANT_FACTOR = 5;
    uint256 public MIN_FEE = 100;

    IVolatilityOracle public volatilityOracle;

    event BaseFeeUpdated(uint256 baseFee);

    constructor(address _volatilityOracle) Ownable(msg.sender) {
        volatilityOracle = IVolatilityOracle(_volatilityOracle);
    }

    function getFee(uint256 volume) external view returns (uint24) {
        uint256 scaled_volume = volume / STANDARD_VOLUME;
        uint256 scaled_variance = volatilityOracle.getPriceVariance() / STANDARD_VARIANCE;

        uint256 fee =
            MIN_FEE + (CONSTANT_FACTOR * scaled_volume * scaled_variance * 100) / VOLUME_DECIMALS / VARIANCE_DECIMALS;

        return uint24(fee);
    }

    function setVolatilityOracle(address _volatilityOracle) public onlyOwner {
        volatilityOracle = IVolatilityOracle(_volatilityOracle);
    }

    function setMinFee(uint256 _minFee) public onlyOwner {
        MIN_FEE = _minFee;
    }

    function setStandardVolume(uint256 _standardVolume) public onlyOwner {
        STANDARD_VOLUME = _standardVolume;
    }

    function setStandardVariance(uint256 _standardVariance) public onlyOwner {
        STANDARD_VARIANCE = _standardVariance;
    }

    function setConstantFactor(uint256 _constantFactor) public onlyOwner {
        CONSTANT_FACTOR = _constantFactor;
    }
}
