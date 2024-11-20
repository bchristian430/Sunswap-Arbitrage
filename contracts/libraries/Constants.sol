// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;
// a library for performing various math operations

import "../interfaces/IUniswapV1Factory.sol";
import "../interfaces/IUniswapV2Factory.sol";

library Constants {
    // Mainnet
    // IUniswapV1Factory internal constant factoryV1 = IUniswapV1Factory(0xeEd9e56a5CdDaA15eF0C42984884a8AFCf1BdEbb);
    // IUniswapV2Factory internal constant factoryV2 = IUniswapV2Factory(0x689AbaeeEd3F0BB3585773192e23224CAC25Dd41);
    // address internal constant WRAPPED_TRX = 0x891cdb91d149f23B1a45D9c5Ca78a88d0cB44C18;
    
    //Testnet
    IUniswapV1Factory internal constant factoryV1 = IUniswapV1Factory(0xE97E6ee12d3db8176242BB901fdB924cC938e2D9);
    IUniswapV2Factory internal constant factoryV2 = IUniswapV2Factory(0xc3bdaC99dFca480483f747D86Ee074BCFfe9Be55);
    address internal constant WRAPPED_TRX = 0xfb3b3134F13CcD2C81F4012E53024e8135d58FeE;
}
