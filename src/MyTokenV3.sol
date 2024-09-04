// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {KYC} from "./KYC.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @custom:oz-upgrades-from MyTokenV2
contract MyTokenV3 is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    ERC20PermitUpgradeable,
    ERC20VotesUpgradeable,
    ERC20BurnableUpgradeable,
    KYC,
    UUPSUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public reinitializer(3) {
        __ERC20_init("MyTokenV3", "MTKV3");
        __Ownable_init(initialOwner);
        __ERC20Permit_init("MyTokenV3");
        __ERC20Burnable_init();
        __ERC20Votes_init();
        __KYC_init();
        __UUPSUpgradeable_init();

        registerSuccessfulKYC(initialOwner);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
        onlyKYC(to)
    {
        ERC20VotesUpgradeable._update(from, to, value);
    }

    function nonces(address owner) public view override(ERC20PermitUpgradeable, NoncesUpgradeable) returns (uint256) {
        return ERC20PermitUpgradeable.nonces(owner);
    }

    // KYC functions
    function registerSuccessfulKYC(address user) public onlyOwner {
        _registerSuccessfulKYC(user);
    }

    function banUser(address user) public onlyOwner {
        _banUser(user);
    }
}
