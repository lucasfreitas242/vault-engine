// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {MockV3Aggregator} from "./mocks/MockV3Aggregator.sol";
import {PriceConverter} from "../src/PriceConverter.sol";

contract VaultTest is Test {
    Vault public vault;
    MockV3Aggregator public mockPriceFeed;

    address public alice = makeAddr("alice");
    uint256 public constant INITIAL_BALANCE = 10 ether;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_ETH_PRICE = 2000e8; 

    function setUp() public {
        mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_ETH_PRICE);
        vault = new Vault(address(mockPriceFeed));
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

    function test_RevertWhen_DepositIsBelowMinimumUsd() public {
        uint256 sentWei = 0.001 ether;
        uint256 expectedSentUsd = 2e18;
        uint256 minimumRequiredUsd = vault.MINIMUM_USD();

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                Vault.Vault__DepositBelowMinimum.selector,
                expectedSentUsd,
                minimumRequiredUsd
            )
        );
        vault.deposit{value: sentWei}();
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
        vm.assume(amount >= 0.005 ether && amount <= INITIAL_BALANCE);

        vm.startPrank(alice);
        vault.deposit{value: amount}();
        assertEq(vault.getBalanceOf(alice), amount);

        vault.withdraw(amount);
        assertEq(vault.getBalanceOf(alice), 0);
        assertEq(alice.balance, INITIAL_BALANCE);
        vm.stopPrank();
    }

    function test_RevertWhen_OraclePriceIsStale() public {
        vm.warp(block.timestamp + 3 hours + 1 seconds);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(PriceConverter.PriceConverter__StalePrice.selector));
        vault.deposit{value: 1 ether}();
    }

    function test_RevertWhen_OraclePriceIsInvalid() public {
        mockPriceFeed.updateAnswer(0);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(PriceConverter.PriceConverter__InvalidPrice.selector));
        vault.deposit{value: 1 ether}();
    }
}