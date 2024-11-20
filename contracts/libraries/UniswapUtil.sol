// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import "../interfaces/IERC20.sol";
import "../interfaces/IUniswapV1Factory.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../libraries/Constants.sol";

// a library for performing various uniswap operations
library UniswapUtil {
    
    // Mainnet
    // IUniswapV1Factory internal constant factoryV1 = IUniswapV1Factory(0xeEd9e56a5CdDaA15eF0C42984884a8AFCf1BdEbb);
    // IUniswapV2Factory internal constant factoryV2 = IUniswapV2Factory(0x689AbaeeEd3F0BB3585773192e23224CAC25Dd41);
    // address internal constant WRAPPED_TRX = 0x891cdb91d149f23B1a45D9c5Ca78a88d0cB44C18;
    
    //Testnet
    // IUniswapV1Factory private constant factoryV1 = IUniswapV1Factory(0xE97E6ee12d3db8176242BB901fdB924cC938e2D9);
    // IUniswapV2Factory private constant factoryV2 = IUniswapV2Factory(0xc3bdaC99dFca480483f747D86Ee074BCFfe9Be55);
    // address private constant WRAPPED_TRX = 0xfb3b3134F13CcD2C81F4012E53024e8135d58FeE;
    
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        if (amountOut == 0) {
            return 0;
        }
        
        if (reserveIn == 0 || reserveOut == 0) {
            return 0;
        }
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * 997;
        amountIn = numerator / denominator + 1;
    }
    
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        if (amountIn == 0) {
            return 0;
        }
        
        if (reserveIn == 0 || reserveOut == 0) {
            return 0;
        }
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
    
    function getV1Pair(address token) internal view returns (address) {
        return Constants.factoryV1.getExchange(token);
    }
    
    function getReservesV1(address token) internal view returns (uint reserve0, uint reserve1, address pair) {
        pair = getV1Pair(token);
        
        if (pair == address(0)) {
            return (0, 0, address(0));
        }
        
        reserve0 = pair.balance;
        reserve1 = IERC20(token).balanceOf(pair);
    }
    
    function getV2Pair(address token0, address token1) internal view returns (address pair) {
        pair = Constants.factoryV2.getPair(token0, token1);
    }
    
    function getReservesV2(address token0, address token1) internal view returns (uint reserve0, uint reserve1, address pair) {
        pair = getV2Pair(token0, token1);
        
        if (pair == address(0)) {
            return (0, 0, address(0));
        }
        
        if (token0 < token1) {
            (reserve0, reserve1, ) = IUniswapV2Pair(pair).getReserves();
        } else {
            (reserve1, reserve0, ) = IUniswapV2Pair(pair).getReserves();
        }
    }
}
