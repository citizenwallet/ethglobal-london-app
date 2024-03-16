// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title MyToken
 * @dev A simple ERC20 token.
 */
contract MyToken is
    ERC20Upgradeable,
    OwnableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event Minted(address indexed to, uint256 amount);

    function initialize(
        string memory name,
        string memory symbol
    ) public initializer {
        __ERC20_init(name, symbol);
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);

        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public {
        require(
            hasRole(MINTER_ROLE, msg.sender),
            "Must have minter role to mint"
        );
        _mint(to, amount);
        emit Minted(to, amount);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
