pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {ClientBase} from "@cambrian/contracts/ClientBase.sol";
import {CambrianQuery, CambrianEvent, Report} from "@cambrian/contracts/Cambrian.sol";
import {IClient} from "@cambrian/contracts/IClient.sol";
import {CambrianRouter} from "@cambrian/contracts/CambrianRouter.sol";

contract Client is ClientBase, Ownable, IClient {
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

    constructor()
        Ownable(msg.sender)
        ClientBase(
            CambrianRouter(0x37E7E71FE679EcFecA67cA3c097498604fa29B5e),
            CambrianQuery(
                block.chainid,
                address(this),
                "name=Swap&network=1&signature=c42079f94a6350d7e6235f29174924f928cc2ac818eb64fed8004e115fbcca67&topic_count=3&data_length=160"
            )
        )
    {}

    function executeQuery(uint64 startBlock, uint64 endBlock) external onlyOwner returns (bytes32) {
        bytes32 messageId = execute(startBlock, endBlock);
        messages[messageId] = 0;
        return messageId;
    }

    function handleSuccess(bytes32 messageId, CambrianEvent[] memory events, Report calldata report)
        external
        override
    {
        // to be overrided by custom app
        // handle events
    }

    function handleStatus(bytes32 messageId, Report calldata report) external override {
        // to be overrided by custom app
        // handle errors also
    }
}
