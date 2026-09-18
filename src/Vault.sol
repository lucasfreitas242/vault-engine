// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

contract Vault is Ownable {
    using PriceConverter for uint256;

    error Vault__ZeroDepositNotAllowed();
    error Vault__DepositBelowMinimum(uint256 sentUsd, uint256 minimumRequiredUsd);
    error Vault__InsufficientBalance(uint256 available, uint256 requested);
    error Vault__TransferFailed();

    uint256 public constant MINIMUM_USD = 10e18;

    AggregatorV3Interface private immutable i_priceFeed;

    mapping(address user => uint256 balance) private s_balances;
    uint256 private s_totalDeposits;

    event DepositMade(address indexed user, uint256 indexed amount, uint256 totalUserBalance);
    event Withdrawn(address indexed user, uint256 indexed amount, uint256 remainingUserBalance);

    constructor(address priceFeedAddress) Ownable(msg.sender) {
        i_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    /// @notice Permite o depósito de ETH nativo validando o valor mínimo em USD
    function deposit() external payable {
        if (msg.value == 0) {
            revert Vault__ZeroDepositNotAllowed();
        }

        uint256 sentUsd = msg.value.getConversionRate(i_priceFeed);
        if (sentUsd < MINIMUM_USD) {
            revert Vault__DepositBelowMinimum(sentUsd, MINIMUM_USD);
        }

        s_balances[msg.sender] += msg.value;
        s_totalDeposits += msg.value;

        emit DepositMade(msg.sender, msg.value, s_balances[msg.sender]);
    }

    /// @notice Realiza o saque seguindo o padrão Checks-Effects-Interactions
    function withdraw(uint256 amount) external {
        uint256 userBalance = s_balances[msg.sender];

        if (amount > userBalance) {
            revert Vault__InsufficientBalance(userBalance, amount);
        }

        s_balances[msg.sender] = userBalance - amount;
        s_totalDeposits -= amount;

        emit Withdrawn(msg.sender, amount, s_balances[msg.sender]);

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert Vault__TransferFailed();
        }
    }


    function getBalanceOf(address user) external view returns (uint256) {
        return s_balances[user];
    }

    function getTotalDeposits() external view returns (uint256) {
        return s_totalDeposits;
    }

    function getPriceFeed() external view returns (address) {
        return address(i_priceFeed);
    }
}