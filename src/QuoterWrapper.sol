// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IHooks} from "@v4-core/interfaces/IHooks.sol";
import {CurrencyLibrary, Currency} from "@v4-core/types/Currency.sol";
import {IQuoter} from "@v4-periphery/interfaces/IQuoter.sol";
import {Quoter} from "@v4-periphery/lens/Quoter.sol";
import {PoolKey} from "@v4-core/types/PoolKey.sol";

contract QuoterWrapper {
    Quoter public quoter;

    address public token0;
    address public token1;
    address public hook;

    PoolKey public pool;

    constructor(address _quoter, address _token0, address _token1, address _hook) {
        quoter = Quoter(_quoter);
        token0 = _token0;
        token1 = _token1;
        
        pool = PoolKey({
            currency0: Currency.wrap(_token0),
            currency1: Currency.wrap(_token1),
            fee: 0x800000,
            tickSpacing: 60,
            hooks: IHooks(_hook)
        });
    }

    function getOutputAmount(uint assetIn, uint amountIn) external returns (uint, uint) {
        if (assetIn == 0) {
            IQuoter.QuoteExactSingleParams memory  param = IQuoter.QuoteExactSingleParams({
                poolKey: pool,
                zeroForOne: true,
                recipient: address(this),
                exactAmount: uint128(amountIn),
                sqrtPriceLimitX96: 4295128740,
                hookData: ""
            });

            (int128[] memory deltaAmounts, uint160 sqrtPriceX96After, uint32 initializedTicksLoaded) = quoter.quoteExactInputSingle(param);

            uint amountOut = uint(-int256(deltaAmounts[1]));
            return (amountOut, uint(sqrtPriceX96After));

        } else {
            IQuoter.QuoteExactSingleParams memory param = IQuoter.QuoteExactSingleParams({
                poolKey: pool,
                zeroForOne: false,
                recipient: address(this),
                exactAmount: uint128(amountIn),
                sqrtPriceLimitX96: 5819260982861451012142998631604,
                hookData: ""
            });

            (int128[] memory deltaAmounts, uint160 sqrtPriceX96After, uint32 initializedTicksLoaded) = quoter.quoteExactInputSingle(param);
        
            uint amountOut = uint(-int256(deltaAmounts[0]));
            return (amountOut, uint(sqrtPriceX96After));
        }
    }

    function getInputAmount(uint assetIn, uint amountOut) external returns (uint, uint) {
        if (assetIn == 0) {
            IQuoter.QuoteExactSingleParams memory  param = IQuoter.QuoteExactSingleParams({
                poolKey: pool,
                zeroForOne: true,
                recipient: address(this),
                exactAmount: uint128(amountOut),
                sqrtPriceLimitX96: 4295128740,
                hookData: ""
            });

            (int128[] memory deltaAmounts, uint160 sqrtPriceX96After, uint32 initializedTicksLoaded) = quoter.quoteExactOutputSingle(param);

            uint amountIn = uint(int256(deltaAmounts[0]));

            return (amountIn, uint(sqrtPriceX96After));
        } else {
            IQuoter.QuoteExactSingleParams memory param = IQuoter.QuoteExactSingleParams({
                poolKey: pool,
                zeroForOne: false,
                recipient: address(this),
                exactAmount: uint128(amountOut),
                sqrtPriceLimitX96: 5819260982861451012142998631604,
                hookData: ""
            });
            
            (int128[] memory deltaAmounts, uint160 sqrtPriceX96After, uint32 initializedTicksLoaded) = quoter.quoteExactOutputSingle(param);

            uint amountIn = uint(int256(deltaAmounts[1]));

            return (amountIn, uint(sqrtPriceX96After));
        }
    }
}