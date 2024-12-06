pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {Log, IClient} from "@cambrian/Cambrian.sol";
import {ClientBase} from "@cambrian/ClientBase.sol";
import {CambrianRouter} from "@cambrian/CambrianRouter.sol";

import {VolatilityOracle} from "./VolatilityOracle.sol";

contract CambrianClient is ClientBase, IClient, Ownable {
    VolatilityOracle public volatilityOracle;

    mapping(uint256 => uint8) messages;

    struct Swap {
        address sender;
        address recipient;
        int256 amount0;
        int256 amount1;
        uint160 sqrtPriceX96;
        uint128 liquidity;
        int24 tick;
    }

    constructor(
        address _router,
        address _volatilityOracle
    )
        Ownable(msg.sender)
        ClientBase(
            CambrianRouter(_router),
            "event=Swap(address indexed sender, address indexed recipient, int256 amount0, int256 amount1, uint160 sqrtPriceX96, uint128 liquidity, int24 tick)&network=1"
        )
    {
        volatilityOracle = VolatilityOracle(_volatilityOracle);
    }

    function executeQuery(
        uint64 startBlock,
        uint64 endBlock
    ) external onlyOwner returns (uint256) {
        uint256 messageId = execute(startBlock, endBlock);
        messages[messageId] = 0;
        return messageId;
    }

    function handleSuccess(
        uint256 /*messageId*/,
        bytes memory data,
        Log[] calldata logs
    ) external override {
        Swap[] memory sdata = abi.decode(data, (Swap[]));
        handleData(sdata, logs);
    }

    function handleData(Swap[] memory swaps, Log[] calldata /*logs*/) public {
        uint160[] memory prices = new uint160[](swaps.length);
        for (uint256 i = 0; i < swaps.length; i++) {
            prices[i] = swaps[i].sqrtPriceX96;
        }

        // Calculate volatility using only the prices
        volatilityOracle.updatePriceVariance(prices);
    }

    function handleStatus(
        uint256 messageId,
        uint8 status,
        string calldata message
    ) external override {
        // handle status
    }
}
