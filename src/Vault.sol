// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Vault is Ownable {
    // Custom Errors para economia de gas e precisão em auditoria
    error Vault__ZeroDepositNotAllowed();
    error Vault__InsufficientBalance(uint256 available, uint256 requested);
    error Vault__TransferFailed();

    // Storage: mapping de saldos individuais e acumulador global
    mapping(address user => uint256 balance) private s_balances;
    uint256 private s_totalDeposits;

    // Eventos essenciais para indexação e tracking off-chain
    event DepositMade(address indexed user, uint256 indexed amount, uint256 totalUserBalance);
    event Withdrawn(address indexed user, uint256 indexed amount, uint256 remainingUserBalance);

    constructor() Ownable(msg.sender) {}

    /// @notice Permite o depósito de ETH nativo no cofre
    function deposit() external payable {
        if (msg.value == 0) {
            revert Vault__ZeroDepositNotAllowed();
        }

        s_balances[msg.sender] += msg.value;
        s_totalDeposits += msg.value;

        emit DepositMade(msg.sender, msg.value, s_balances[msg.sender]);
    }

    /// @notice Realiza o saque parcial ou total seguindo o padrão Checks-Effects-Interactions
    /// @param amount Quantidade em wei a ser sacada
    function withdraw(uint256 amount) external {
        uint256 userBalance = s_balances[msg.sender];

        // 1. Checks
        if (amount > userBalance) {
            revert Vault__InsufficientBalance(userBalance, amount);
        }

        // 2. Effects (atualiza o storage antes da transferência para mitigar reentrancy)
        s_balances[msg.sender] = userBalance - amount;
        s_totalDeposits -= amount;

        emit Withdrawn(msg.sender, amount, s_balances[msg.sender]);

        // 3. Interactions (transferência de ETH nativo via call de baixo nível)
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert Vault__TransferFailed();
        }
    }

    // --- Getters ---

    function getBalanceOf(address user) external view returns (uint256) {
        return s_balances[user];
    }

    function getTotalDeposits() external view returns (uint256) {
        return s_totalDeposits;
    }
}