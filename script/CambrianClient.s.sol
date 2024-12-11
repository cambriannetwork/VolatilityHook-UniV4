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

contract CambrianClientDeploymentScript is Script {
    using CurrencyLibrary for Currency;

    address cambrianRouter = 0x10D52CC3dda5043A752478466e940B874C795991;

    address deployer;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.rememberKey(deployerPrivateKey);

        vm.startBroadcast(deployer);

        //________________________________ Deploy Cambrian Client ________________________________//
        CambrianClient cambrianClient = CambrianClient(0x13Cf34FDb8138aaFC8756ACcd54bC1749BD7a803);

        cambrianClient.executeQuery(20000000, 20000025);
    }
}
