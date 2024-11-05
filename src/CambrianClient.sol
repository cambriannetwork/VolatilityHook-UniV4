pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {CambrianQuery, CambrianEvent, Report} from "@cambrian/Cambrian.sol";
import {ClientBase} from "@cambrian/ClientBase.sol";
import {CambrianRouter} from "@cambrian/CambrianRouter.sol";

import {VolatilityOracle} from "./VolatilityOracle.sol";

contract CambrianClient is ClientBase, IClient, Ownable {
    VolatilityOracle public volatilityOracle;

    mapping(bytes32 => uint8) messages;

    struct Swap {
        address sender;
        address recipient;
        int256 amount0;
        int256 amount1;
        uint160 sqrtPriceX96;
        uint128 liquidity;
        int24 tick;
    }

    constructor(address _router, address _volatilityOracle)
        Ownable(msg.sender)
        ClientBase(
            CambrianRouter(_router),
            CambrianQuery(
                "name=Swap&network=1&signature=c42079f94a6350d7e6235f29174924f928cc2ac818eb64fed8004e115fbcca67&topic_count=3&data_length=160"
            )
        )
    {
        volatilityOracle = VolatilityOracle(_volatilityOracle);
    }

    function executeQuery(uint64 startBlock, uint64 endBlock) external onlyOwner returns (bytes32) {
        bytes32 messageId = execute(startBlock, endBlock);
        messages[messageId] = 0;
        return messageId;
    }

    function handleSuccess(bytes32 messageId, CambrianEvent[] memory events, Report calldata report)
        external
        override
    {
        // Decode Swap data and extract sqrtPriceX96 values
        uint160[] memory prices = new uint160[](events.length);
        for (uint256 i = 0; i < events.length; i++) {
            Swap memory swap = abi.decode(events[i].data, (Swap));
            prices[i] = swap.sqrtPriceX96;
        }

        // Calculate volatility using only the prices
        uint256 volatility = volatilityOracle.updatePriceVariance(prices);
    }
}
