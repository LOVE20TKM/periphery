// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "../../src/interfaces/ILOVE20Stake.sol";

/**
 * @title MockILOVE20Stake
 * @dev LOVE20Stake接口的模拟实现
 */
contract MockILOVE20Stake is ILOVE20Stake {
    function initialStakeRound(address tokenAddress) external pure override returns (uint256) {
        tokenAddress;
        return 42;
    }

    function govVotesNum(address tokenAddress) external pure override returns (uint256) {
        tokenAddress;
        return 100;
    }

    function stakeLiquidity(
        address tokenAddress,
        uint256 tokenAmountForLP,
        uint256 parentTokenAmountForLP,
        uint256 promisedWaitingPhases,
        address to
    ) external pure returns (uint256 govVotesAdded, uint256 slAmountAdded) {
        tokenAddress;
        tokenAmountForLP;
        parentTokenAmountForLP;
        promisedWaitingPhases;
        to;
        return (100, 200);
    }

    // Add missing interface implementations
    function PROMISED_WAITING_PHASES_MAX() external pure returns (uint256) {
        return 10;
    }

    function PROMISED_WAITING_PHASES_MIN() external pure returns (uint256) {
        return 1;
    }

    function accountStakeStatus(address, address) external pure returns (AccountStakeStatus memory) {
        return AccountStakeStatus({
            slAmount: 100,
            stAmount: 50,
            promisedWaitingPhases: 2,
            requestedUnstakeRound: 0,
            govVotes: 1000
        });
    }

    function caculateGovVotes(address, uint256, address) external pure returns (uint256) {
        return 150;
    }

    function cumulatedTokenAmount(address, uint256) external pure returns (uint256) {
        return 5000;
    }

    function cumulatedTokenAmountByAccount(address, uint256, address) external pure returns (uint256) {
        return 1000;
    }

    // IPhase interface implementation
    function originBlocks() external pure returns (uint256) {
        return 100;
    }

    function phaseBlocks() external pure returns (uint256) {
        return 1000;
    }

    function currentRound() external pure returns (uint256) {
        return 1;
    }

    function roundByBlockNumber(uint256) external pure returns (uint256) {
        return 1;
    }

    function stakeToken(address, uint256, uint256, address) external pure returns (uint256 govVotesAdded) {
        return 100; // Mock implementation
    }

    function stakeTokenUpdatedRoundsCount(address) external pure returns (uint256) {
        return 3;
    }

    function stakeTokenUpdatedRoundsAtIndex(address, uint256) external pure returns (uint256) {
        return 1;
    }

    function stakeTokenUpdatedRoundsByAccountCount(address, address) external pure returns (uint256) {
        return 2;
    }

    function stakeTokenUpdatedRoundsByAccountAtIndex(address, address, uint256) external pure returns (uint256) {
        return 1;
    }

    function unstake(address) external pure {
        // Mock implementation
    }

    function validGovVotes(address, uint256, address) external pure returns (uint256) {
        return 80;
    }

    function withdraw(address) external pure {
        // Mock implementation
    }

    function caculateGovVotes(uint256 lpAmount, uint256 promisedWaitingPhases) external pure returns (uint256) {
        return lpAmount * promisedWaitingPhases;
    }

    function validGovVotes(address tokenAddress, address account) external pure returns (uint256) {
        tokenAddress;
        account;
        return 500;
    }
}
