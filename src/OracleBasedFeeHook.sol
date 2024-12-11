// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// v4-core imports
import {IPoolManager} from "@v4-core/interfaces/IPoolManager.sol";
import {Hooks} from "@v4-core/libraries/Hooks.sol";
import {LPFeeLibrary} from "@v4-core/libraries/LPFeeLibrary.sol";
import {StateLibrary} from "@v4-core/libraries/StateLibrary.sol";
import {PoolKey} from "@v4-core/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@v4-core/types/PoolId.sol";
import {BalanceDelta} from "@v4-core/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@v4-core/types/BeforeSwapDelta.sol";

// v4-periphery imports
import {BaseHook} from "@v4-periphery/BaseHook.sol";

// OpenZeppelin imports
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Local imports
import {FeeOracle} from "./FeeOracle.sol";

contract OracleBasedFeeHook is BaseHook, Ownable {
    using LPFeeLibrary for uint24;
    using StateLibrary for IPoolManager;
    using PoolIdLibrary for PoolKey;

    error MustUseDynamicFee();

    uint256 public constant MIN_FEE = 1000;
    address public DEV_WALLET;

    FeeOracle public feeOracle;

    event FeeUpdate(uint256 indexed newFee, uint256 timestamp);

    constructor(IPoolManager _poolManager, address _feeOracle, address _devWallet)
        BaseHook(_poolManager)
        Ownable(_devWallet)
    {
        feeOracle = FeeOracle(_feeOracle);
        DEV_WALLET = _devWallet;
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: true,
            afterInitialize: false,
            beforeAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterAddLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    function beforeInitialize(address, PoolKey calldata key, uint160, bytes calldata)
        external
        pure
        override
        returns (bytes4)
    {
        if (!key.fee.isDynamicFee()) revert MustUseDynamicFee();
        return this.beforeInitialize.selector;
    }

    function abs(int256 x) private pure returns (uint256) {
        if (x >= 0) {
            return uint256(x);
        }
        return uint256(-x);
    }

    function beforeSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata swapData, bytes calldata)
        external
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        // Update fee based on the oracle
        uint24 fee = feeOracle.getFee(abs(swapData.amountSpecified));
        poolManager.updateDynamicLPFee(key, fee);
        emit FeeUpdate(fee, block.timestamp);

        return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    function setFeeOracle(address _feeOracle) external onlyOwner {
        feeOracle = FeeOracle(_feeOracle);
    }
}
