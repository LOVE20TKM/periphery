// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "../../src/interfaces/ILOVE20Verify.sol";

/**
 * @title MockILOVE20Verify
 * @dev LOVE20Verify接口的模拟实现
 */
contract MockILOVE20Verify is ILOVE20Verify {
    function scoreByActionIdByAccount(
        address,
        uint256,
        uint256,
        address
    ) external pure override returns (uint256) {
        return 50;
    }

    function isActionIdWithReward(
        address,
        uint256,
        uint256
    ) external pure returns (bool) {
        return true;
    }

    function scoreByActionId(
        address tokenAddress,
        uint256 round,
        uint256 actionId
    ) external pure returns (uint256) {
        tokenAddress;
        round;
        actionId;
        return 50;
    }

    // Add missing interface implementations
    function RANDOM_SEED_UPDATE_MIN_PER_TEN_THOUSAND()
        external
        pure
        returns (uint256)
    {
        return 100;
    }

    function abstentionScoreWithReward(
        address,
        uint256,
        uint256
    ) external pure returns (uint256) {
        return 30;
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

    function firstTokenAddress() external pure returns (address) {
        return address(0x123);
    }

    function joinAddress() external pure returns (address) {
        return address(0x456);
    }

    function randomAddress() external pure returns (address) {
        return address(0x789);
    }

    function score(address, uint256, uint256) external pure returns (uint256) {
        return 75;
    }

    function scoreByVerifier(
        address,
        uint256,
        address
    ) external pure returns (uint256) {
        return 60;
    }

    function scoreByVerifierByActionId(
        address,
        uint256,
        address,
        uint256
    ) external pure returns (uint256) {
        return 65;
    }

    function scoreWithReward(
        address,
        uint256,
        uint256
    ) external pure returns (uint256) {
        return 80;
    }

    function stakeAddress() external pure returns (address) {
        return address(0xabc);
    }

    function stakedAmountOfVerifiers(
        address,
        uint256,
        uint256
    ) external pure returns (uint256) {
        return 5000;
    }

    function verify(address, uint256, uint256, uint256) external pure {
        // Mock implementation
    }

    function voteAddress() external pure returns (address) {
        return address(0xdef);
    }

    function score(
        address tokenAddress,
        uint256 round
    ) external pure returns (uint256) {
        tokenAddress;
        round;
        return 100;
    }

    function scoreWithReward(
        address tokenAddress,
        uint256 round
    ) external pure returns (uint256) {
        tokenAddress;
        round;
        return 150;
    }

    function abstentionScoreWithReward(
        address tokenAddress,
        uint256 round
    ) external pure returns (uint256) {
        tokenAddress;
        round;
        return 50;
    }

    function verify(
        address tokenAddress,
        uint256 actionId,
        uint256 abstentionScore,
        uint256[] calldata scores
    ) external pure {
        tokenAddress;
        actionId;
        abstentionScore;
        scores;
        // Mock implementation
    }

    function stakedAmountOfVerifiers(
        address tokenAddress,
        uint256 round
    ) external pure returns (uint256) {
        tokenAddress;
        round;
        return 1000;
    }

    function scoreByVerifierByActionIdByAccount(
        address tokenAddress,
        uint256 round,
        address verifier,
        uint256 actionId,
        address account
    ) external pure returns (uint256) {
        tokenAddress;
        round;
        actionId;

        // 弃权票（零地址）的处理
        if (account == address(0)) {
            // 不同验证者的弃权票分数
            if (verifier == address(0x1)) return 30;
            if (verifier == address(0x2)) return 40;
            if (verifier == address(0x3)) return 50;
            return 35; // 默认弃权票分数
        }

        // 正常被验证者的分数
        if (verifier == address(0x1) && account == address(0xa)) return 85;
        if (verifier == address(0x1) && account == address(0xb)) return 90;
        if (verifier == address(0x2) && account == address(0xa)) return 75;
        if (verifier == address(0x2) && account == address(0xb)) return 80;
        if (verifier == address(0x3) && account == address(0xa)) return 95;
        if (verifier == address(0x3) && account == address(0xb)) return 70;
        return 60; // 默认分数
    }
}
