// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";

contract VaultTest is Test {
    Vault public vault;
    address public alice = makeAddr("alice");
    uint256 public constant INITIAL_BALANCE = 10 ether;

    function setUp() public {
        vault = new Vault();
        vm.deal(alice, INITIAL_BALANCE);
    }

    function test_DepositSucceedsAndUpdatesBalance() public {
        vm.prank(alice);
        vault.deposit{value: 1 ether}();

        assertEq(vault.getBalanceOf(alice), 1 ether);
        assertEq(vault.getTotalDeposits(), 1 ether);
    }

    function test_RevertWhen_DepositIsZero() public {
        vm.prank(alice);
        vm.expectRevert(Vault.Vault__ZeroDepositNotAllowed.selector);
        vault.deposit{value: 0}();
    }

    function test_WithdrawSucceedsAndTransfersEth() public {
        vm.startPrank(alice);
        vault.deposit{value: 2 ether}();

        vault.withdraw(1 ether);

        assertEq(vault.getBalanceOf(alice), 1 ether);
        assertEq(vault.getTotalDeposits(), 1 ether);
        assertEq(alice.balance, INITIAL_BALANCE - 1 ether);
        vm.stopPrank();
    }

    function test_RevertWhen_WithdrawExceedsBalance() public {
        vm.startPrank(alice);
        vault.deposit{value: 1 ether}();

        vm.expectRevert(
            abi.encodeWithSelector(Vault.Vault__InsufficientBalance.selector, 1 ether, 2 ether)
        );
        vault.withdraw(2 ether);
        vm.stopPrank();
    }

    function testFuzz_DepositAndWithdraw(uint96 amount) public {
        vm.assume(amount > 0 && amount <= INITIAL_BALANCE);

        vm.startPrank(alice);
        vault.deposit{value: amount}();
        assertEq(vault.getBalanceOf(alice), amount);

        vault.withdraw(amount);
        assertEq(vault.getBalanceOf(alice), 0);
        assertEq(alice.balance, INITIAL_BALANCE);
        vm.stopPrank();
    }
}