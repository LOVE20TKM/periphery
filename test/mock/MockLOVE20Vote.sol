// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "../../src/interfaces/ILOVE20Vote.sol";

/**
 * @title MockILOVE20Vote
 * @dev LOVE20Vote接口的模拟实现
 */
contract MockILOVE20Vote is ILOVE20Vote {
    function votesNumByActionId(
        address tokenAddress,
        uint256 round,
        uint256 actionId
    ) external pure override returns (uint256) {
        tokenAddress;
        round;
        actionId;
        return 100;
    }

    function votesNumsByAccount(
        address tokenAddress,
        uint256 round,
        address account
    )
        external
        pure
        override
        returns (uint256[] memory actionIds, uint256[] memory votes)
    {
        tokenAddress;
        round;
        account;
        actionIds = new uint256[](2);
        votes = new uint256[](2);
        actionIds[0] = 1;
        votes[0] = 100;
        actionIds[1] = 2;
        votes[1] = 200;
    }

    function votesNumByAccountByActionId(
        address tokenAddress,
        uint256 round,
        address account,
        uint256 actionId
    ) external pure returns (uint256) {
        tokenAddress;
        round;
        account;
        actionId;
        return 100;
    }

    function votedActionIdsCount(
        address tokenAddress,
        uint256 round
    ) external pure returns (uint256) {
        tokenAddress;
        round;
        return 3;
    }

    function votedActionIdsAtIndex(
        address tokenAddress,
        uint256 round,
        uint256 index
    ) external pure returns (uint256) {
        tokenAddress;
        round;
        index;
        return 1;
    }

    function accountVotedActionIdsCount(
        address tokenAddress,
        uint256 round,
        address account
    ) external pure returns (uint256) {
        tokenAddress;
        round;
        account;
        return 2;
    }

    function accountVotedActionIdsAtIndex(
        address tokenAddress,
        uint256 round,
        address account,
        uint256 index
    ) external pure returns (uint256) {
        tokenAddress;
        round;
        account;
        index;
        return 200;
    }

    // 添加缺失的接口实现
    function canVote(
        address tokenAddress,
        address account
    ) external pure returns (bool) {
        tokenAddress;
        account;
        return true;
    }

    // IPhase接口实现
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

    function isActionIdVoted(
        address tokenAddress,
        uint256 round,
        uint256 actionId
    ) external pure returns (bool) {
        tokenAddress;
        round;
        actionId;
        return true;
    }

    function maxVotesNum(address, address) external pure returns (uint256) {
        return 1000;
    }

    function stakeAddress() external pure returns (address) {
        return address(0x123);
    }

    function submitAddress() external pure returns (address) {
        return address(0x456);
    }

    function vote(address, uint256[] memory, uint256[] memory) external pure {
        // Mock implementation
    }

    function votesNum(address, uint256) external pure returns (uint256) {
        return 500;
    }

    function votesNumByAccount(
        address,
        uint256,
        address
    ) external pure returns (uint256) {
        return 100;
    }

    function votesNumsByAccountByActionIds(
        address,
        uint256,
        address,
        uint256[] memory
    ) external pure returns (uint256[] memory) {
        uint256[] memory votes = new uint256[](1);
        votes[0] = 100;
        return votes;
    }
}
