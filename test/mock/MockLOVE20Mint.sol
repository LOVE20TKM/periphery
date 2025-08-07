// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "../../src/interfaces/ILOVE20Mint.sol";

/**
 * @title MockILOVE20Mint
 * @dev LOVE20Mint接口的模拟实现
 */
contract MockILOVE20Mint is ILOVE20Mint {
    function currentRound() external pure returns (uint256) {
        return 1;
    }

    function actionRewardByActionIdByAccount(
        address,
        uint256,
        uint256,
        address account
    ) external pure override returns (uint256 reward, bool isMinted) {
        if (account == address(0x1)) {
            return (25, true);
        } else if (account == address(0x2)) {
            return (50, false);
        }
        return (0, false);
    }

    function actionRewardMintedByAccount(
        address,
        uint256,
        uint256,
        address account
    ) external pure override returns (uint256) {
        if (account == address(0x1)) {
            return 50;
        } else if (account == address(0x2)) {
            return 0;
        }
        return 0;
    }

    function govRewardByAccount(
        address,
        uint256,
        address
    ) external pure override returns (uint256, uint256, uint256, bool) {
        return (50, 50, 50, true);
    }

    function govRewardMintedByAccount(
        address,
        uint256,
        address
    ) external pure override returns (uint256) {
        return 50;
    }

    function rewardAvailable(address) external pure returns (uint256) {
        return 50;
    }

    // Add missing interface implementations
    function ACTION_REWARD_MIN_VOTE_PER_THOUSAND()
        external
        pure
        returns (uint256)
    {
        return 100;
    }

    function MAX_GOV_BOOST_REWARD_MULTIPLIER() external pure returns (uint256) {
        return 5;
    }

    function ROUND_REWARD_ACTION_PER_THOUSAND()
        external
        pure
        returns (uint256)
    {
        return 200;
    }

    function ROUND_REWARD_GOV_PER_THOUSAND() external pure returns (uint256) {
        return 300;
    }

    function boostRewardBurned(address, uint256) external pure returns (bool) {
        return false;
    }

    function calculateRoundGovReward(
        address,
        uint256
    ) external pure returns (uint256) {
        return 1500;
    }

    function govBoostReward(
        address,
        uint256,
        address
    ) external pure returns (uint256) {
        return 200;
    }

    function govReward(address, uint256) external pure returns (uint256) {
        return 800;
    }

    function govVerifyReward(
        address,
        uint256,
        address
    ) external pure returns (uint256) {
        return 150;
    }

    function isActionIdWithReward(
        address,
        uint256,
        uint256
    ) external pure returns (bool) {
        return true;
    }

    function isRewardPrepared(address, uint256) external pure returns (bool) {
        return true;
    }

    function mintActionReward(
        address,
        uint256,
        uint256,
        address
    ) external pure {
        // Mock implementation
    }

    function mintGovReward(address, uint256, address) external pure {
        // Mock implementation
    }

    function prepareRewardIfNeeded(address) external pure {
        // Mock implementation
    }

    function reservedAvailable(
        address,
        uint256
    ) external pure returns (uint256) {
        return 2000;
    }

    function rewardBurned(address) external pure returns (uint256) {
        return 100;
    }

    function rewardMinted(address) external pure returns (uint256) {
        return 5000;
    }

    function rewardReserved(address, uint256) external pure returns (uint256) {
        return 3000;
    }

    function stakeAddress() external pure returns (address) {
        return address(0x123);
    }

    function verifyAddress() external pure returns (address) {
        return address(0x456);
    }

    function voteAddress() external pure returns (address) {
        return address(0x789);
    }

    function actionReward(
        address tokenAddress,
        uint256 round
    ) external pure returns (uint256) {
        tokenAddress;
        round;
        return 500;
    }

    function actionRewardBurned(
        address tokenAddress,
        uint256 round
    ) external pure returns (bool) {
        tokenAddress;
        round;
        return false;
    }

    function calculateRoundActionReward(
        address tokenAddress
    ) external pure returns (uint256) {
        tokenAddress;
        return 1000;
    }

    function calculateRoundGovReward(
        address tokenAddress
    ) external pure returns (uint256) {
        tokenAddress;
        return 1500;
    }

    function govBoostReward(
        address tokenAddress,
        uint256 round
    ) external pure returns (uint256) {
        tokenAddress;
        round;
        return 200;
    }

    function govVerifyReward(
        address tokenAddress,
        uint256 round
    ) external pure returns (uint256) {
        tokenAddress;
        round;
        return 150;
    }

    function mintActionReward(
        address tokenAddress,
        uint256 round,
        uint256 actionId
    ) external pure returns (uint256) {
        tokenAddress;
        round;
        actionId;
        return 500;
    }

    function mintGovReward(
        address tokenAddress,
        uint256 round
    )
        external
        pure
        returns (uint256 verifyReward, uint256 boostReward, uint256 burnReward)
    {
        tokenAddress;
        round;
        return (100, 50, 25);
    }

    function numOfMintGovRewardByAccount(
        address tokenAddress,
        address account
    ) external pure returns (uint256) {
        tokenAddress;
        account;
        return 3;
    }

    function reservedAvailable(
        address tokenAddress
    ) external pure returns (uint256) {
        tokenAddress;
        return 2000;
    }

    function rewardReserved(
        address tokenAddress
    ) external pure returns (uint256) {
        tokenAddress;
        return 3000;
    }
}
