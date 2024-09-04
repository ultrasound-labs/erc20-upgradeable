// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../src/MyToken.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/Script.sol";

contract DeployUUPSProxy is Script {
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

        vm.startBroadcast(deployerKey);

        address _implementation = 0xB7194045FCe73e6B42F6bba4208a1a0df3c12Fbe; // Replace with your token address

        // Encode the initializer function call
        bytes memory data = abi.encodeWithSelector(
            MyToken(_implementation).initialize.selector,
            msg.sender // Initial owner/admin of the contract
        );

        // Deploy the proxy contract with the implementation address and initializer
        ERC1967Proxy proxy = new ERC1967Proxy(_implementation, data);

        vm.stopBroadcast();
        // Log the proxy address
        console.log("UUPS Proxy Address:", address(proxy));
    }
}
