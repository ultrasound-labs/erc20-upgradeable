// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/MyToken.sol";
import "../src/MyTokenV2.sol";
import "../src/MyTokenV3.sol";
import "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {Upgrades} from "lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

contract MyTokenTest is Test {
    MyToken myToken;
    MyTokenV2 myTokenV2;
    MyTokenV3 myTokenV3;
    ERC1967Proxy proxy;
    address owner;

    // Set up the test environment before running tests
    function setUp() public {
        // Deploy the token implementation
        MyToken implementation = new MyToken();
        // Define the owner address
        owner = vm.addr(1);

        vm.startPrank(owner);
        // Deploy the proxy and initialize the contract through the proxy
        proxy = new ERC1967Proxy(address(implementation), abi.encodeCall(implementation.initialize, owner));
        vm.stopPrank();

        // remember: Call your contract's functions as normal, but remember to always use the proxy address:
        // Attach the MyToken interface to the deployed proxy
        myToken = MyToken(address(proxy));
        // Emit the owner address for debugging purposes
        emit log_address(owner);
    }

    function testSetUp() public view {
        assertEq(myToken.balanceOf(owner), 1000000 * 10 ** myToken.decimals());
    }

    // Test the basic ERC20 functionality of the MyToken contract
    function testERC20Functionality() public {
        // Impersonate the owner to call mint function
        vm.prank(owner);
        // Mint tokens to address(2) and assert the balance
        myToken.mint(address(2), 1000);
        assertEq(myToken.balanceOf(address(2)), 1000);
    }

    // Test ownership //

    // not owner tries to mint
    function testNotAllowedMint() public {
        address someUser = address(10);

        bytes memory expectedRevertData =
            abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, someUser);

        vm.prank(someUser);
        vm.expectRevert(expectedRevertData);
        myToken.mint(someUser, 1e18);
    }

    function testChangeRightfulOwner() public {
        assertEq(myToken.owner(), owner);
        address newOwner = address(2);
        vm.prank(owner);
        myToken.transferOwnership(newOwner);
        assertEq(myToken.owner(), newOwner);

        // new owner can mint
        vm.prank(newOwner);
        myToken.mint(newOwner, 1e18);
        assertEq(myToken.balanceOf(newOwner), 1e18);
    }

    // try to transfer as owner
    function testERC20AsOwner() public {
        address beneficiary = address(3);
        vm.prank(owner);
        myToken.transfer(beneficiary, 1e18);
        assertEq(myToken.balanceOf(beneficiary), 1e18);
    }

    ///////////////////////
    // Testing upgrades //
    ///////////////////////

    // Test the upgradeability of the MyToken contract
    function testSimpleUpgradeability() public {
        vm.startPrank(owner);
        bytes memory data = abi.encodeCall(MyTokenV2.initialize, owner);
        // Upgrade the proxy to a new version; MyTokenV2
        Upgrades.upgradeProxy(address(proxy), "MyTokenV2.sol:MyTokenV2", data, owner);
        vm.stopPrank();
        myTokenV2 = MyTokenV2(address(proxy));
        assertEq(myTokenV2.name(), "MyTokenV2");
        assertEq(myTokenV2.symbol(), "MTKV2");
        assertEq(myTokenV2.balanceOf(owner), 2000000 * 10 ** myToken.decimals());
    }

    function testUpgradeWithoutInit() public {
        vm.startPrank(owner);
        Upgrades.upgradeProxy(address(proxy), "MyTokenV2.sol:MyTokenV2", "", owner);
        vm.stopPrank();
        myTokenV2 = MyTokenV2(address(proxy));

        // as initialisation was not triggered
        assertEq(myTokenV2.name(), "MyToken");
        assertEq(myTokenV2.symbol(), "MTK");
        assertEq(myTokenV2.balanceOf(owner), 1000000 * 10 ** myToken.decimals());
    }

    // test revoking ownership of token and proxy
    function testRevokingOwnership() public {
        // revoke ownership
        vm.startPrank(owner);
        myToken.renounceOwnership();

        // upgrade should revert, since no ownership
        bytes memory data = abi.encodeCall(MyTokenV2.initialize, owner);

        bytes memory expectedRevertData =
            abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, owner);

        // vm.expectRevert(expectedRevertData); // reverts with another reason (unclear if goal achieved)

        // Upgrades.upgradeProxy(address(proxy), "MyTokenV2.sol:MyTokenV2", data, owner); fails

        // no mint possible
        vm.expectRevert(expectedRevertData);
        myToken.mint(owner, 100e18);

        vm.stopPrank();
    }

    // upgrade and not initialise introduces vulnerability, if new implementation is initializable
    function testUpgradeWithoutInitAndMaliciousUser() public {
        vm.startPrank(owner);
        Upgrades.upgradeProxy(address(proxy), "MyTokenV2.sol:MyTokenV2", "", owner);
        vm.stopPrank();
        myTokenV2 = MyTokenV2(address(proxy));

        // who is owner?
        console.log("owner", myTokenV2.owner()); // still rightful owner

        // as initialisation was not triggered, but since it uses reinitializer it can be called
        assertEq(myTokenV2.name(), "MyToken");
        assertEq(myTokenV2.symbol(), "MTK");
        assertEq(myTokenV2.balanceOf(owner), 1000000 * 10 ** myToken.decimals());

        address maliciousUser = address(10);

        vm.startPrank(maliciousUser);

        // this emits OwnershipTransferred(previousOwner: 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, newOwner: PointEvaluation: [0x000000000000000000000000000000000000000A])
        myTokenV2.initialize(maliciousUser);

        // now the contract is initialised
        assertEq(myTokenV2.name(), "MyTokenV2");
        assertEq(myTokenV2.symbol(), "MTKV2");

        // and not the right owner
        assertEq(myTokenV2.owner(), maliciousUser);

        myToken.mint(maliciousUser, 1000000 * 10 ** myToken.decimals());
        assertEq(myTokenV2.balanceOf(maliciousUser), 2000000 * 10 ** myToken.decimals());

        vm.stopPrank();

        // malicious owner can upgrade to V3
        vm.startPrank(maliciousUser);
        bytes memory data = abi.encodeCall(MyTokenV3.initialize, maliciousUser);
        Upgrades.upgradeProxy(address(proxy), "MyTokenV3.sol:MyTokenV3", data, maliciousUser);

        myTokenV3 = MyTokenV3(address(proxy));
        assertEq(myTokenV3.owner(), maliciousUser);

        vm.stopPrank();
    }
}
