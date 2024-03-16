// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@account-abstraction/contracts/interfaces/UserOperation.sol";

interface ITokenEntryPoint {
    function handleOps(
        UserOperation[] calldata ops,
        address payable /*beneficiary*/
    ) external;
}
