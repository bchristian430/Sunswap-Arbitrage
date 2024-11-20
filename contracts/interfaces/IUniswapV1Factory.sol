// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

interface IUniswapV1Factory {
    function getExchange(address token) external view returns (address payable);
}