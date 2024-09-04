// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {MyToken} from "../src/MyToken.sol";
import {stdJson} from "../lib/forge-std/src/StdJson.sol";

contract MintPetal is Script {
    using stdJson for string;

    uint256 public DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 public deployerKey;

    struct MintData {
        address petalAddress;
        uint256[] teamAmounts;
        address[] teamSAFEs;
    }

    function run() public {
        string memory filePath = "./script/Data/mintData.json"; // petalAddress needs to be the proxy!
        vm.assertTrue(vm.isFile(filePath));
        string memory json = vm.readFile(filePath);
        bytes memory mintDetails = json.parseRaw("");
        MintData memory mintData = abi.decode(mintDetails, (MintData));

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

        console.log(mintData.petalAddress);
        MyToken petal = MyToken(mintData.petalAddress);

        vm.startBroadcast(deployerKey);

        for (uint256 i; i < mintData.teamSAFEs.length; i++) {
            console.log("Balance before mint of", mintData.teamSAFEs[i], petal.balanceOf(mintData.teamSAFEs[i]));

            petal.mint(mintData.teamSAFEs[i], mintData.teamAmounts[i]);

            console.log("Balance after mint of", mintData.teamSAFEs[i], petal.balanceOf(mintData.teamSAFEs[i]));
        }

        vm.stopBroadcast();
    }
}
