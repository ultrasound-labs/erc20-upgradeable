// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../src/MyToken.sol";
import "forge-std/Script.sol";

contract DeployTokenImplementation is Script {
    uint256 public DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 public deployerKey;

    function run() public {
        if (block.chainid == 73571) {
            // tenderly testnet
            deployerKey = vm.envUint("TENDERLY_PRIVATE_KEY");
        } else if (block.chainid == 1) {
            // ethereum
            deployerKey = vm.envUint("PRIVATE_KEY_MAINNET");
        } else {
            // local evm (anvil)
            // block.chainid == 31337
            deployerKey = DEFAULT_ANVIL_PRIVATE_KEY;
        }

        // Use address provided in config to broadcast transactions
        vm.startBroadcast(deployerKey);
        // Deploy the ERC-20 token
        MyToken implementation = new MyToken();
        // Stop broadcasting calls from our address
        vm.stopBroadcast();
        // Log the token address
        console.log("Token Implementation Address:", address(implementation));
    }
}
