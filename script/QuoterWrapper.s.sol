// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {PoolModifyLiquidityTest} from "@v4-core/test/PoolModifyLiquidityTest.sol";
import {IPoolManager} from "@v4-core/interfaces/IPoolManager.sol";
import {PoolManager} from "@v4-core/PoolManager.sol";
import {IHooks} from "@v4-core/interfaces/IHooks.sol";
import {PoolKey} from "@v4-core/types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "@v4-core/types/Currency.sol";
import {PoolId, PoolIdLibrary} from "@v4-core/types/PoolId.sol";
import {QuoterWrapper} from "contracts/QuoterWrapper.sol";
import {Faucet} from "contracts/Faucet.sol";
import {Quoter} from "@v4-periphery/lens/Quoter.sol";
import {IQuoter} from "@v4-periphery/interfaces/IQuoter.sol";

contract QuoterWrapperDeployment is Script {
    using CurrencyLibrary for Currency;

    Quoter quoter = Quoter(0x52f09Df7814BF3274812785b9fb249020e7412d0);

    address cethAddr = vm.envAddress("CETH_ADDRESS");
    address cusdcAddr = vm.envAddress("CUSDC_ADDRESS");
    address hook = vm.envAddress("HOOK_ADDRESS");

    address deployer;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.rememberKey(deployerPrivateKey);

        vm.startBroadcast(deployer);

        QuoterWrapper quoterWrapper = new QuoterWrapper(address(quoter), cethAddr, cusdcAddr, hook);

        console.log("_________________Wrapper_________________________");
        (uint256 amount, uint256 sqrtPrice) = quoterWrapper.getOutputAmount(0, 1e18);
        console.log("Amount in: ", amount / 1e18);
        console.log("Sqrt Price After: ", sqrtPrice);

        (amount, sqrtPrice) = quoterWrapper.getOutputAmount(1, 3600e18);
        console.log("Amount in: ", amount / 1e18);
        console.log("Sqrt Price After: ", sqrtPrice);

        (amount, sqrtPrice) = quoterWrapper.getInputAmount(0, 3600e18);
        console.log("Amount in: ", amount / 1e18);
        console.log("Sqrt Price After: ", sqrtPrice);

        (amount, sqrtPrice) = quoterWrapper.getInputAmount(1, 1e18);
        console.log("Amount in: ", amount / 1e18);
        console.log("Sqrt Price After: ", sqrtPrice);
    }
}
