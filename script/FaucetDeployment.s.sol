// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PoolModifyLiquidityTest} from "@v4-core/test/PoolModifyLiquidityTest.sol";
import {IPoolManager} from "@v4-core/interfaces/IPoolManager.sol";
import {PoolManager} from "@v4-core/PoolManager.sol";
import {IHooks} from "@v4-core/interfaces/IHooks.sol";
import {PoolKey} from "@v4-core/types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "@v4-core/types/Currency.sol";
import {PoolId, PoolIdLibrary} from "@v4-core/types/PoolId.sol";
import {Faucet} from "contracts/Faucet.sol";

contract FaucetDeployment is Script {
    using CurrencyLibrary for Currency;

    // Set up Address
    address cethAddr = vm.envAddress("CETH_ADDRESS");
    address cusdcAddr = vm.envAddress("CUSDC_ADDRESS");

    address deployer;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.rememberKey(deployerPrivateKey);

        vm.startBroadcast(deployer);

        // Deploy Faucet
        Faucet faucet = new Faucet(cethAddr, cusdcAddr);
        console.log("Faucet Deployed");
        console.log("CETH Balance: ", IERC20(cethAddr).balanceOf(deployer));
        console.log("CUSDC Balance: ", IERC20(cusdcAddr).balanceOf(deployer));
        IERC20(cethAddr).transfer(address(faucet), IERC20(cethAddr).balanceOf(deployer) - 100e18);
        IERC20(cusdcAddr).transfer(address(faucet), IERC20(cusdcAddr).balanceOf(deployer) - 100e18);
    }
}
