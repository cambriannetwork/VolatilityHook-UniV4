pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {IPoolManager} from "@v4-core/interfaces/IPoolManager.sol";
import {Currency, CurrencyLibrary} from "@v4-core/types/Currency.sol";
import {LPFeeLibrary} from "@v4-core/libraries/LPFeeLibrary.sol";
import {Hooks} from "@v4-core/libraries/Hooks.sol";
import {IHooks} from "@v4-core/interfaces/IHooks.sol";
import {PoolKey} from "@v4-core/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@v4-core/types/PoolId.sol";
import {PoolSwapTest} from "@v4-core/test/PoolSwapTest.sol";
import {PoolModifyLiquidityTest} from "@v4-core/test/PoolModifyLiquidityTest.sol";
import {TickMath} from "@v4-core/libraries/TickMath.sol";
import {OracleBasedFeeHook} from "../src/OracleBasedFeeHook.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {HookMiner} from "contracts/utils/HookMiner.sol";
import {BalanceDelta} from "@v4-core/types/BalanceDelta.sol";
import {QuoterWrapper} from "contracts/QuoterWrapper.sol";
import {Quoter} from "@v4-periphery/lens/Quoter.sol";
import {IQuoter} from "@v4-periphery/interfaces/IQuoter.sol";
import {CambrianClient} from "../src/CambrianClient.sol";
import {VolatilityOracle} from "../src/VolatilityOracle.sol";
import {FeeOracle} from "../src/FeeOracle.sol";
import {CambrianETH} from "../script/mocks/CambrianETH.sol";
import {CambrianUSDC} from "../script/mocks/CambrianUSDC.sol";
import {OracleBasedFeeHook} from "../src/OracleBasedFeeHook.sol";
import {console} from "forge-std/console.sol";

contract TestUniV4 is Test {
    Quoter quoter;
    QuoterWrapper quoterWrapper;

    address create2 = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
    address cambrianRouter = 0x10D52CC3dda5043A752478466e940B874C795991;
    address deployer = 0xe77B8D62D71AE7379f88cc364a48Bb49588CFB98;

    IPoolManager poolManager = IPoolManager(0x75E7c1Fd26DeFf28C7d1e82564ad5c24ca10dB14);
    PoolSwapTest swapRouter = PoolSwapTest(0xB8b53649b87F0e1eb3923305490a5cB288083f82);
    PoolModifyLiquidityTest lpRouter = PoolModifyLiquidityTest(0x2b925D1036E2E17F79CF9bB44ef91B95a3f9a084);

    address token0;
    address token1;

    CambrianUSDC usdc;
    CambrianETH eth;

    VolatilityOracle volatilityOracle;
    FeeOracle feeOracle;
    CambrianClient cambrianClient;

    PoolKey pool;

    function setUp() public {
        vm.createSelectFork("https://sepolia.gateway.tenderly.co");

        // Deploy Tokens
        usdc = new CambrianUSDC();
        eth = new CambrianETH();

        // Deploy Cambrian Client
        cambrianClient = new CambrianClient(cambrianRouter);

        // Deploy Fee Oracle
        feeOracle = new FeeOracle(cambrianClient.getVolatilityOracle());

        // Deploy Hook
        uint160 flags = uint160(Hooks.BEFORE_INITIALIZE_FLAG | Hooks.BEFORE_SWAP_FLAG);

        (, bytes32 salt) = HookMiner.find(
            address(this),
            flags,
            type(OracleBasedFeeHook).creationCode,
            abi.encode(IPoolManager(poolManager), address(feeOracle), deployer)
        );

        OracleBasedFeeHook hook =
            new OracleBasedFeeHook{salt: salt}(IPoolManager(poolManager), address(feeOracle), deployer);

        //________________________________ Create Pool ___________________________________________//
        token0 = uint160(address(usdc)) < uint160(address(eth)) ? address(usdc) : address(eth);
        token1 = uint160(address(usdc)) < uint160(address(eth)) ? address(eth) : address(usdc);

        uint24 swapFee = 0x800000;
        int24 tickSpacing = 60;

        uint160 startingPrice = 4411237397794263893240602165248;

        pool = PoolKey({
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

        // logging the pool ID
        PoolId id = PoolIdLibrary.toId(pool);
        bytes32 idBytes = PoolId.unwrap(id);

        //Create pool
        poolManager.initialize(pool, startingPrice, hookData);

        // Provide 10_000e18 worth of liquidity on the range of [-600, 600]
        lpRouter.modifyLiquidity(pool, IPoolManager.ModifyLiquidityParams(-887220, 887220, 10000000e18, 0), hookData);
    }

    function testCambrianClient() public {
        // Test execute query
        cambrianClient.executeQuery(0, 100000);
    }

    function testVolatilityOracle() public {
        // Read prices from JSON file
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/test/data/price.json");
        string memory json = vm.readFile(path);
        // Parse as string array first, then convert to uint256
        uint256[] memory prices = abi.decode(vm.parseJson(json), (uint256[]));

        uint256 variance = VolatilityOracle(cambrianClient.getVolatilityOracle()).updatePriceVariance(prices);
        console.log("Variance: ", variance);
    }

    function testFeeOracle() public {
        uint256 volume = 10e18;

        // Read prices from JSON file
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/test/data/price.json");
        string memory json = vm.readFile(path);
        // Parse as string array first, then convert to uint256
        uint256[] memory prices = abi.decode(vm.parseJson(json), (uint256[]));

        uint256 variance = VolatilityOracle(cambrianClient.getVolatilityOracle()).updatePriceVariance(prices);
        console.log("Variance: ", variance);

        uint256 fee = feeOracle.getFee(volume);
        console.log("Fee: ", fee);
    }

    function testSwap() public {
        // Read prices from JSON file
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/test/data/price.json");
        string memory json = vm.readFile(path);
        // Parse as string array first, then convert to uint256
        uint256[] memory prices = abi.decode(vm.parseJson(json), (uint256[]));

        uint256 variance = VolatilityOracle(cambrianClient.getVolatilityOracle()).updatePriceVariance(prices);

        // approve tokens to the swap router
        IERC20(token0).approve(address(swapRouter), type(uint256).max);
        IERC20(token1).approve(address(swapRouter), type(uint256).max);

        bytes memory hookData = new bytes(0);

        PoolSwapTest.TestSettings memory testSettings =
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false});

        //Swap 1e18 token0 into token1 params
        IPoolManager.SwapParams memory params_0 =
            IPoolManager.SwapParams({zeroForOne: true, amountSpecified: -1e18, sqrtPriceLimitX96: 4295128740});

        swapRouter.swap(pool, params_0, testSettings, hookData);

        //Swap 3100 into token1 params
        IPoolManager.SwapParams memory params_1 = IPoolManager.SwapParams({
            zeroForOne: false,
            amountSpecified: -3600e18,
            sqrtPriceLimitX96: 5819260982861451012142998631604
        });

        swapRouter.swap(pool, params_1, testSettings, hookData);
    }
}
