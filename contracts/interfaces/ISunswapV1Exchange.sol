// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

interface ISunswapV1Exchange {
    function balanceOf(address owner) external view returns (uint);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function removeLiquidity(uint, uint, uint, uint) external returns (uint, uint);
    function tokenToTrxSwapInput(uint, uint, uint) external returns (uint);
    function trxToTokenSwapInput(uint, uint) external payable returns (uint);
}