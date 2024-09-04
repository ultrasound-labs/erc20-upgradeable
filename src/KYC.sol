// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract KYC is Initializable {
    /**
     * @dev Storage of the KYC contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:petal.storage.kyc
     */
    struct KYCStorage {
        /**
         * @dev list of addresses that are underwent KYC
         */
        mapping(address => bool) whitelisted;
    }

    // keccak256(abi.encode(uint256(keccak256("petal.storage.kyc")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant KYC_STORAGE = 0x4954d0a772b5e980c523148ba97dd62bef2699ee2a17d33a53fa697fffa58000;

    function _getKYCStorage() private pure returns (KYCStorage storage $) {
        assembly {
            $.slot := KYC_STORAGE
        }
    }

    function __KYC_init() internal onlyInitializing {}

    modifier onlyKYC(address user) {
        require(_checkIfKYC(user), "User not KYCEED");
        _;
    }

    function _checkIfKYC(address user) internal view returns (bool) {
        KYCStorage storage $ = _getKYCStorage();
        return $.whitelisted[user];
    }

    function checkIfKYC(address user) public view returns (bool) {
        return _checkIfKYC(user);
    }

    function _registerSuccessfulKYC(address user) internal {
        KYCStorage storage $ = _getKYCStorage();
        $.whitelisted[user] = true;
    }

    function _banUser(address user) internal {
        KYCStorage storage $ = _getKYCStorage();
        $.whitelisted[user] = false;
    }
}
