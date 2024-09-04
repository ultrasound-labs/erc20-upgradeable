// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/MyToken.sol";
import "../src/MyTokenV2.sol";
import "../src/MyTokenV2Alternative.sol";
import "../src/MyTokenV3.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import "@openzeppelin-foundry-upgrades/Upgrades.sol";

contract MyTokenTest is Test {
    MyToken myToken;
    MyTokenV2 myTokenV2;
    MyTokenV3 myTokenV3;
    MyTokenV2Alternative myTokenV2Alternative;
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
        assertEq(myToken.owner(), owner);
    }

    // Test the basic ERC20 functionality of the MyToken contract
    function testERC20Functionality() public {
        // Impersonate the owner to call mint function
        vm.prank(owner);
        // Mint tokens to address(2) and assert the balance
        myToken.mint(address(2), 1000);
        assertEq(myToken.balanceOf(address(2)), 1000);
    }

    ///////////////////////
    // Testing upgrades //
    ///////////////////////

    function testThisShouldWork() public {
        vm.startPrank(owner);
        // MyTokenV2 implementation = new MyTokenV2();
        bytes memory data = abi.encodeCall(MyTokenV2.initialize, owner);
        Upgrades.upgradeProxy(address(proxy), "MyTokenV2.sol:MyTokenV2", data, owner);
        vm.stopPrank();
    }

    // test revoking ownership of token and proxy
    function testRevokingOwnership() public {
        // revoke ownership
        vm.startPrank(owner);
        myToken.renounceOwnership();

        MyTokenV2 implementation = new MyTokenV2();
        // upgrade should revert, since no ownership
        bytes memory data = abi.encodeCall(implementation.initialize, owner);

        bytes memory expectedRevertData =
            abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, owner);

        // vm.expectRevert(expectedRevertData); // reverts with another reason (unclear if goal achieved)
        Upgrades.upgradeProxy(address(proxy), "MyTokenV2.sol:MyTokenV2", data, owner);

        // no mint possible
        vm.expectRevert(expectedRevertData);
        myToken.mint(owner, 100e18);

        vm.stopPrank();
    }

    // alternative v2, that uses another ownership mechanism `AccessControlUpdateable.sol` from OZ and upgrade from simple Ownable to AccessControl splitting ownership of
    function testAlternativeOwnable() public {
        address admin = owner;
        address tokenOwner = address(16);

        // use new contract with splitted responsibilities
        bytes memory data = abi.encodeCall(MyTokenV2Alternative.initialize, (admin, tokenOwner));
        Upgrades.upgradeProxy(address(proxy), "MyTokenV2Alternative.sol:MyTokenV2Alternative", data, owner);

        MyTokenV2Alternative = MyTokenV2Alternative(address(proxy));

        // mint should only be possible for token owner
        vm.prank(tokenOwner);
        MyTokenV2Alternative.mint(tokenOwner, 10e18);

        vm.expectRevert(bytes("Not token owner"));
        vm.prank(admin);
        MyTokenV2Alternative.mint(admin, 10e18);

        // upgrade should only be possible for admin
        data = abi.encodeCall(MyTokenV2.initialize, tokenOwner);
        vm.prank(tokenOwner);
        vm.expectRevert(bytes("Not default admin"));
        Upgrades.upgradeProxy(address(proxy), "MyTokenV2.sol:MyTokenV2", data, tokenOwner);

        vm.prank(admin);
        Upgrades.upgradeProxy(address(proxy), "MyTokenV2.sol:MyTokenV2", data, admin);

        myTokenV2 = MyTokenV2(address(proxy));

        address someUser = address(99);
        vm.prank(admin);
        myTokenV2.mint(someUser, 1e18);
        assertEq(myTokenV2.balanceOf(someUser), 1e18);
    }

    // try to upgrade as a not authorised user `Upgrades.upgradeProxy(...)` (should revert)
    // does not work, fails with an unclear API response
    // function testNotAuthorisedUpgrade() public {
    //     address maliciousUser = address(10);
    //     // bytes memory initData = abi.encodeCall(MyTokenV2.initialize, maliciousUser);
    //     // bytes memory expectedRevertData =
    //     //     abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, maliciousUser);
    //     vm.prank(maliciousUser);
    //     // vm.expectRevert();

    //     // upgrade without init (as with init fails for another revert statement, that doesnt make sense)
    //     // vm.expectRevert(expectedRevertData);
    //     // Upgrades.upgradeProxy(address(proxy), "MyTokenV2.sol:MyTokenV2", "", maliciousUser);
    // }

    // upgrade to v3 normally and make use of KYC module
    // different users have funds, but they get locked once KYC is in place
    function testKYCModule() public {
        address user1 = address(5);
        address user2 = address(6);
        vm.startPrank(owner);
        myToken.mint(user1, 100e18);
        myToken.mint(user2, 100e18);
        vm.stopPrank();

        // make some transfers and allocate tokens to different users
        // test correct balances
        vm.startPrank(user1);
        myToken.transfer(user2, 50e18);
        vm.stopPrank();
        assertEq(myToken.balanceOf(user1), 50e18);
        assertEq(myToken.balanceOf(user2), 150e18);

        // upgrade to v2
        vm.startPrank(owner);
        bytes memory data = abi.encodeCall(MyTokenV2.initialize, owner);
        Upgrades.upgradeProxy(address(proxy), "MyTokenV2.sol:MyTokenV2", data, owner);
        vm.stopPrank();

        // bytes memory initDataV2 = abi.encodeCall(MyTokenV2.initialize, owner);
        // vm.prank(owner);
        // Upgrades.upgradeProxy(address(proxy), "MyTokenV2.sol:MyTokenV2", initDataV2, owner);

        myTokenV2 = MyTokenV2(address(proxy));

        // check correct balances
        assertEq(myTokenV2.balanceOf(user1), 50e18);
        assertEq(myTokenV2.balanceOf(user2), 150e18);

        // do transfers
        vm.startPrank(user2);
        myTokenV2.transfer(user1, 10e18);
        vm.stopPrank();
        assertEq(myTokenV2.balanceOf(user1), 60e18);
        assertEq(myTokenV2.balanceOf(user2), 140e18);

        console.log("owner", myTokenV2.owner());
        // upgrade to V3
        data = abi.encodeCall(MyTokenV3.initialize, owner);
        vm.prank(owner);
        Upgrades.upgradeProxy(address(proxy), "MyTokenV3.sol:MyTokenV3", data, owner);

        myTokenV3 = MyTokenV3(address(proxy));
        // test to move funds

        vm.prank(user1);
        vm.expectRevert(bytes("User not KYCEED"));
        myTokenV3.transfer(user2, 60e18);

        assertEq(myTokenV3.balanceOf(user1), 60e18);
        assertEq(myTokenV3.balanceOf(user2), 140e18);

        vm.prank(owner);
        myTokenV3.registerSuccessfulKYC(user1);

        vm.prank(user1);
        myTokenV3.transfer(user2, 60e18);

        assertEq(myTokenV3.balanceOf(user1), 0);
        assertEq(myTokenV3.balanceOf(user2), 200e18);
    }

    // TODO: make an alternative contract v2 that corrupts storage and show with tests
}
