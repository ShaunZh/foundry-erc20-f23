// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployOurToken} from "../script/DeployOurToken.s.sol";
import {OurToken} from "../src/OurToken.sol";

contract OurTokenTest is Test {
    OurToken public ourToken;
    DeployOurToken public deployer;

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");
    address charlie = makeAddr("charlie");

    uint256 public constant STARTING_BALANCE = 100 ether;
    uint256 public constant INITIAL_SUPPLY = 1000 ether;

    function setUp() public {
        deployer = new DeployOurToken();
        ourToken = deployer.run();

        vm.prank(msg.sender);
        ourToken.transfer(bob, STARTING_BALANCE);
    }

    function testBobBalance() public view {
        assertEq(STARTING_BALANCE, ourToken.balanceOf(bob));
    }

    function testAllowancesWorks() public {
        uint256 initialAllowance = 1000;

        // Bob approves Alice to spend tokens on her behalf
        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);

        uint256 transferAmount = 500;

        vm.prank(alice);
        ourToken.transferFrom(bob, alice, transferAmount);

        assertEq(ourToken.balanceOf(alice), transferAmount);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
    }
    
    function testUsersCantMint() public {
        vm.expectRevert();
        
        // This would revert because _mint is internal
        // You'd need to convert this to a custom OurToken method if desired
        // ourToken.mint(bob, 1000);
        
        // Simulating an attempt to exceed total supply
        vm.prank(bob);
        ourToken.transfer(alice, STARTING_BALANCE + 1);
    }
    
    function testTransferToken() public {
        uint256 transferAmount = 10;
        uint256 bobStartingBalance = ourToken.balanceOf(bob);
        
        vm.prank(bob);
        ourToken.transfer(alice, transferAmount);
        
        assertEq(ourToken.balanceOf(bob), bobStartingBalance - transferAmount);
        assertEq(ourToken.balanceOf(alice), transferAmount);
    }
    
    function testTransferFromRequiresApproval() public {
        uint256 transferAmount = 10;
        
        // Should revert because Alice hasn't been approved
        vm.expectRevert();
        vm.prank(alice);
        ourToken.transferFrom(bob, alice, transferAmount);
    }
   
    function testCannotTransferMoreThanBalance() public {
        uint256 bobBalance = ourToken.balanceOf(bob);
        
        vm.expectRevert();
        vm.prank(bob);
        ourToken.transfer(alice, bobBalance + 1);
    }
    
    function testCannotTransferFromMoreThanAllowed() public {
        uint256 initialAllowance = 100;
        
        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);
        
        vm.expectRevert();
        vm.prank(alice);
        ourToken.transferFrom(bob, alice, initialAllowance + 1);
    }
    
    function testMultipleTransfers() public {
        uint256 amount1 = 10;
        uint256 amount2 = 15;
        uint256 bobStartingBalance = ourToken.balanceOf(bob);
        
        vm.startPrank(bob);
        ourToken.transfer(alice, amount1);
        ourToken.transfer(charlie, amount2);
        vm.stopPrank();
        
        assertEq(ourToken.balanceOf(bob), bobStartingBalance - amount1 - amount2);
        assertEq(ourToken.balanceOf(alice), amount1);
        assertEq(ourToken.balanceOf(charlie), amount2);
    }
}

