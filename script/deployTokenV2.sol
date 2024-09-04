// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../src/MyToken.sol";
import "../src/MyTokenV2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin-foundry-upgrades/Upgrades.sol";
import "forge-std/Script.sol";

contract DeployV2AndUpgrade is Script {
    uint256 public DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 public deployerKey;

    function run() public {
        PetalToken v1 = PetalToken(0x765793b54bDe86886538973bB15E1ff1F4c722B7); // replace with proxy address
        address v1Owner = v1.owner();
        console.log(v1Owner);
        address payable proxyAddr = payable(0x765793b54bDe86886538973bB15E1ff1F4c722B7); // replace with proxy address
        ERC1967Proxy proxy = ERC1967Proxy(proxyAddr);

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

        // Upgrade
        bytes memory data = abi.encodeCall(MyTokenV2.initialize, v1Owner);
        Upgrades.upgradeProxy(address(proxy), "MyTokenV2.sol:MyTokenV2", data, v1Owner);

        // Stop broadcasting calls from our address
        vm.stopBroadcast();
    }
}
