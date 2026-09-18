// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title MockV3Aggregator
 * @notice Mock simples da Chainlink para simular retornos de preço em ambiente de teste local
 */
contract MockV3Aggregator {
    uint8 public decimals;
    int256 public latestAnswer;
    uint256 public latestTimestamp;
    uint80 public latestRound;

    constructor(uint8 _decimals, int256 _initialAnswer) {
        decimals = _decimals;
        updateAnswer(_initialAnswer);
    }

    function updateAnswer(int256 _answer) public {
        latestAnswer = _answer;
        latestTimestamp = block.timestamp;
        latestRound++;
    }

    function updateRoundData(
        uint80 _roundId,
        int256 _answer,
        uint256 _timestamp,
        uint256 /* _startedAt */
    ) public {
        latestRound = _roundId;
        latestAnswer = _answer;
        latestTimestamp = _timestamp;
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (latestRound, latestAnswer, latestTimestamp, latestTimestamp, latestRound);
    }
}