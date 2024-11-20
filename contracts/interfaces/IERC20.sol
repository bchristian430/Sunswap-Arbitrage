// SPDX-License-Identifier: MIT 
pragma solidity >=0.8.0;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
  function transfer(address to, uint256 value) external returns (bool);
  function balanceOf(address who) external view returns (uint256);
  function approve(address spender, uint256 value) external returns (bool);
  function allowance(address _owner, address _spender) external view returns (uint256);
}