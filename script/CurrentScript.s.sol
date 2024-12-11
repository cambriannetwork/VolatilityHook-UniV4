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

    address create2 = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
    address cambrianRouter = 0x10D52CC3dda5043A752478466e940B874C795991;

    IPoolManager poolManager = IPoolManager(0x75E7c1Fd26DeFf28C7d1e82564ad5c24ca10dB14);
    PoolSwapTest swapRouter = PoolSwapTest(0xB8b53649b87F0e1eb3923305490a5cB288083f82);
    PoolModifyLiquidityTest lpRouter = PoolModifyLiquidityTest(0x2b925D1036E2E17F79CF9bB44ef91B95a3f9a084);

    address client = 0x13Cf34FDb8138aaFC8756ACcd54bC1749BD7a803;
    address volatilityOracle = 0x0d02Ae251d73984f312604966Dbb7c8d78b505Bf;
    address hook = 0xd178AD794E3638a46aF863cdC6cEA608A60AA080;

    address deployer;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.rememberKey(deployerPrivateKey);

        vm.startBroadcast(deployer);

        //________________________________ Deploy Tokens _________________________________________//
        CambrianETH eth = new CambrianETH();
        CambrianUSDC usdc = new CambrianUSDC();

        //________________________________ Deploy Verifier/Oracle ________________________________//
        FeeOracle feeOracle = new FeeOracle(volatilityOracle);

        //________________________________ Create Pool ___________________________________________//
        address token0 = address(usdc);
        address token1 = address(eth);

        console.log(token0);
        console.log(token1);

        console.log(uint160(token0) < uint160(token1));

        uint24 swapFee = 0x800000;
        int24 tickSpacing = 60;

        uint160 startingPrice = 1584563250285286784856227840;

        PoolKey memory pool = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: swapFee,
            tickSpacing: tickSpacing,
            hooks: IHooks(hook)
        });

        IERC20(token0).approve(address(poolManager), type(uint256).max);
        IERC20(token1).approve(address(poolManager), type(uint256).max);

        // approve tokens to the LP Router
        IERC20(token0).approve(address(lpRouter), type(uint256).max);
        IERC20(token1).approve(address(lpRouter), type(uint256).max);

        // optionally specify hookData if the hook depends on arbitrary data for liquidity modification
        bytes memory hookData = new bytes(0);

        //Create pool
        poolManager.initialize(pool, startingPrice, hookData);

        // Provide 10_000e18 worth of liquidity on the range of [-600, 600]
        lpRouter.modifyLiquidity(pool, IPoolManager.ModifyLiquidityParams(-887220, 887220, 10000000e18, 0), hookData);

        //________________________________ Faucet Deployment ___________________________________________//
        // Faucet faucet = new Faucet(address(eth), address(usdc));
        // IERC20(address(eth)).transfer(address(faucet), IERC20(address(eth)).balanceOf(deployer));
        // IERC20(address(usdc)).transfer(address(faucet), IERC20(address(usdc)).balanceOf(deployer));
    }
}
