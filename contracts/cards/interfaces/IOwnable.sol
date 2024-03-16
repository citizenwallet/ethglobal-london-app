// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IOwnable {
    function owner() external view returns (address);
    function transferOwnership(address newOwner) external;
}
