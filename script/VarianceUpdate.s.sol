// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IPoolManager} from "@v4-core/interfaces/IPoolManager.sol";
import {PoolManager} from "@v4-core/PoolManager.sol";
import {PoolSwapTest} from "@v4-core/test/PoolSwapTest.sol";
import {PoolModifyLiquidityTest} from "@v4-core/test/PoolModifyLiquidityTest.sol";
import {IHooks} from "@v4-core/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {HookMiner} from "contracts/utils/HookMiner.sol";
import {PoolKey} from "@v4-core/types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "@v4-core/types/Currency.sol";
import {PoolId, PoolIdLibrary} from "@v4-core/types/PoolId.sol";
import {CambrianUSDC} from "./mocks/CambrianUSDC.sol";
import {CambrianETH} from "./mocks/CambrianETH.sol";

import {CambrianClient} from "src/CambrianClient.sol";
import {VolatilityOracle} from "src/VolatilityOracle.sol";
import {FeeOracle} from "src/FeeOracle.sol";
import {Faucet} from "src/Faucet.sol";
import {OracleBasedFeeHook} from "src/OracleBasedFeeHook.sol";

contract DeploymentScript is Script {
    using CurrencyLibrary for Currency;

    // Set up Address
    address poolManagerAddr = vm.envAddress("POOL_MANAGER_ADDRESS");
    address swapRouterAddr = vm.envAddress("POOLSWAPTEST_ADDRESS");
    address liquidityRouterAddr = vm.envAddress("LIQUIDITY_ROUTER_ADDRESS");

    address hookAddr = vm.envAddress("HOOK_ADDRESS");
    address cambrianClientAddr = vm.envAddress("CLIENT_ADDRESS");
    address volatilityOracleAddr = vm.envAddress("VOLATILITY_ORACLE_ADDRESS");
    address feeOracleAddr = vm.envAddress("FEE_ORACLE_ADDRESS");
    address cethAddr = vm.envAddress("CETH_ADDRESS");
    address cusdcAddr = vm.envAddress("CUSDC_ADDRESS");

    // Set up Contract
    IPoolManager poolManager = IPoolManager(poolManagerAddr);
    PoolSwapTest swapRouter = PoolSwapTest(swapRouterAddr);
    PoolModifyLiquidityTest liquidityRouter = PoolModifyLiquidityTest(liquidityRouterAddr);
    CambrianClient cambrianClient = CambrianClient(cambrianClientAddr);
    VolatilityOracle volatilityOracle = VolatilityOracle(volatilityOracleAddr);

    // Set Up Tokens
    address token0 = uint160(cusdcAddr) < uint160(cethAddr) ? cusdcAddr : cethAddr;
    address token1 = uint160(cusdcAddr) < uint160(cethAddr) ? cethAddr : cusdcAddr;

    address deployer;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.rememberKey(deployerPrivateKey);

        vm.startBroadcast(deployer);

        //________________________________ Test Swap Addresses _________________________________________//
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/test/data/price.json");
        string memory json = vm.readFile(path);
        // Parse as string array first, then convert to uint256
        uint256[] memory prices = abi.decode(vm.parseJson(json), (uint256[]));

        uint256 variance = VolatilityOracle(cambrianClient.getVolatilityOracle()).updatePriceVariance(prices);
    }
}