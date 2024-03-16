// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWithdrawable {
    function withdraw(IERC20 token, uint256 amount) external;
    function withdrawTo(IERC20 token, address to, uint256 amount) external;
}
