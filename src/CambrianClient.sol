pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {Log, IClient} from "@cambrian/Cambrian.sol";
import {ClientBase} from "@cambrian/ClientBase.sol";
import {CambrianRouter} from "@cambrian/CambrianRouter.sol";
import {VolatilityOracle} from "./VolatilityOracle.sol";

contract CambrianClient is IClient, ClientBase, Ownable {
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

    constructor(address _router)
        Ownable(msg.sender)
        ClientBase(
            CambrianRouter(_router),
            "name=Swap&network=1&address=88e6a0c2ddd26feeb64f039a2c41296fcb3f5640&signature=c42079f94a6350d7e6235f29174924f928cc2ac818eb64fed8004e115fbcca67&topic_count=3&data_length=160"
        )
    {
        volatilityOracle = new VolatilityOracle();
    }

    function executeQuery(uint64 startBlock, uint64 endBlock) external returns (uint256) {
        uint256 messageId = execute(startBlock, endBlock);
        messages[messageId] = 0;
        return messageId;
    }

    function handleSuccess(uint256 messageId, bytes memory data, Log[] calldata logs) external override {
        // Decode Swap data and extract sqrtPriceX96 values
        Swap[] memory swaps = abi.decode(data, (Swap[]));

        if (swaps.length != 0) {
            uint256[] memory prices = new uint256[](swaps.length);
            for (uint256 i = 0; i < swaps.length; i++) {
                uint256 amount0;
                uint256 amount1;
                if (swaps[i].amount0 < 0) {
                    amount0 = uint256(-swaps[i].amount0);
                    amount1 = uint256(swaps[i].amount1);
                } else {
                    amount0 = uint256(swaps[i].amount0);
                    amount1 = uint256(-swaps[i].amount1);
                }
                prices[i] = amount1 * 1000 / amount0;
            }
            volatilityOracle.updatePriceVariance(prices);
        } else {
            volatilityOracle.forceUpdatePriceVariance(0);
        }
    }

    function handleStatus(uint256 messageId, uint8 status, string calldata message) external override {}

    function getVolatilityOracle() public view returns (address) {
        return address(volatilityOracle);
    }
}
