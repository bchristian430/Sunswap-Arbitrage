// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

interface IUniswapV1Exchange {
    function tokenToTrxSwapInput(uint tokens_sold, uint min_trx, uint deadline) external returns (uint);
    function trxToTokenTransferInput(uint, uint, address) external payable returns(uint);
}