// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "./interfaces/ILOVE20Stake.sol";
import "./interfaces/ILOVE20SLToken.sol";
import "./interfaces/ILOVE20Vote.sol";
import "./interfaces/ILOVE20Join.sol";
import "./interfaces/ILOVE20Mint.sol";
import "./interfaces/ILOVE20Token.sol";
import "./interfaces/ILOVE20Submit.sol";

struct RewardInfo {
    uint256 round;
    uint256 reward;
    bool isMinted;
}

struct GovReward {
    uint256 round;
    uint256 reward;
    uint256 verifyReward;
    uint256 boostReward;
    bool isMinted;
}

struct ActionReward {
    uint256 actionId;
    uint256 round;
    uint256 reward;
    bool isMinted;
}

contract LOVE20MintViewer {
    address public stakeAddress;
    address public voteAddress;
    address public joinAddress;
    address public mintAddress;

    bool public initialized;

    constructor() {}

    function init(
        address stakeAddress_,
        address voteAddress_,
        address joinAddress_,
        address mintAddress_
    ) external {
        require(!initialized, "Already initialized");

        stakeAddress = stakeAddress_;
        voteAddress = voteAddress_;
        joinAddress = joinAddress_;
        mintAddress = mintAddress_;

        initialized = true;
    }

    function govRewardsByAccountByRounds(
        address tokenAddress,
        address account,
        uint256 startRound,
        uint256 endRound
    ) external view returns (GovReward[] memory rewards) {
        require(
            startRound <= endRound,
            "startRound must be less than or equal to endRound"
        );

        rewards = new GovReward[](endRound - startRound + 1);
        for (uint256 i = startRound; i <= endRound; i++) {
            (
                uint256 verifyReward,
                uint256 boostReward,
                ,
                bool isMinted
            ) = ILOVE20Mint(mintAddress).govRewardByAccount(
                    tokenAddress,
                    i,
                    account
                );

            rewards[i - startRound] = GovReward({
                round: i,
                reward: verifyReward + boostReward,
                verifyReward: verifyReward,
                boostReward: boostReward,
                isMinted: isMinted
            });
        }
    }

    function actionRewardsByAccountByActionIdByRounds(
        address tokenAddress,
        address account,
        uint256 actionId,
        uint256 startRound,
        uint256 endRound
    ) public view returns (RewardInfo[] memory rewards) {
        require(
            startRound <= endRound,
            "startRound must be less than or equal to endRound"
        );

        rewards = new RewardInfo[](endRound - startRound + 1);

        for (uint256 i = startRound; i <= endRound; i++) {
            uint256 reward = 0;
            bool isMinted = false;

            if (
                ILOVE20Mint(mintAddress).isActionIdWithReward(
                    tokenAddress,
                    i,
                    actionId
                )
            ) {
                (reward, isMinted) = ILOVE20Mint(mintAddress)
                    .actionRewardByActionIdByAccount(
                        tokenAddress,
                        i,
                        actionId,
                        account
                    );
            }

            rewards[i - startRound] = RewardInfo({
                round: i,
                reward: reward,
                isMinted: isMinted
            });
        }

        return rewards;
    }

    function actionRewardsByAccountOfLastRounds(
        address tokenAddress,
        address account,
        uint256 LastRounds
    )
        public
        view
        returns (ActionReward[] memory rewards)
    {
        // Got joined action ids
        uint256[] memory actionIds = ILOVE20Join(joinAddress)
            .actionIdsByAccount(tokenAddress, account);

        if (actionIds.length == 0) {
            return new ActionReward[](0);
        }

        // Got current mint round
        uint256 currentRound = ILOVE20Join(joinAddress).currentRound();
        if (currentRound <= 2) {
            return new ActionReward[](0);
        } else {
            currentRound = currentRound - 2;
        }
        uint256 startRound = LastRounds >= currentRound
            ? 0
            : currentRound - LastRounds;

        // Got result
        rewards = _collectActionRewards(
            tokenAddress,
            account,
            actionIds,
            startRound,
            currentRound
        );

        return rewards;
    }

    function _collectActionRewards(
        address tokenAddress,
        address account,
        uint256[] memory actionIds,
        uint256 startRound,
        uint256 endRound
    ) private view returns (ActionReward[] memory) {
        uint256 maxRewards = (endRound - startRound + 1) * actionIds.length;
        ActionReward[] memory temp = new ActionReward[](maxRewards);
        uint256 count = 0;

        for (uint256 i = 0; i < actionIds.length; i++) {
            count = _addActionRewards(
                tokenAddress,
                account,
                actionIds[i],
                startRound,
                endRound,
                temp,
                count
            );
        }

        assembly {
            mstore(temp, count)
        }
        return temp;
    }

    function _addActionRewards(
        address tokenAddress,
        address account,
        uint256 actionId,
        uint256 startRound,
        uint256 endRound,
        ActionReward[] memory rewards,
        uint256 startIndex
    ) private view returns (uint256) {
        uint256 currentIndex = startIndex;

        for (uint256 round = startRound; round <= endRound; round++) {
            if (
                ILOVE20Mint(mintAddress).isActionIdWithReward(
                    tokenAddress,
                    round,
                    actionId
                )
            ) {
                (uint256 reward, bool isMinted) = ILOVE20Mint(mintAddress)
                    .actionRewardByActionIdByAccount(
                        tokenAddress,
                        round,
                        actionId,
                        account
                    );

                if (reward > 0) {
                    rewards[currentIndex] = ActionReward({
                        actionId: actionId,
                        round: round,
                        reward: reward,
                        isMinted: isMinted
                    });
                    currentIndex++;
                }
            }
        }

        return currentIndex;
    }

    function hasUnmintedActionRewardOfLastRounds(
        address token,
        address account,
        uint256 latestRounds
    ) public view returns (bool) {
        // Got joined action ids
        uint256[] memory actionIds = ILOVE20Join(joinAddress)
            .actionIdsByAccount(token, account);

        if (actionIds.length == 0) {
            return false;
        }

        // Got current mint round
        uint256 currentRound = ILOVE20Join(joinAddress).currentRound();
        if (currentRound <= 2) {
            return false;
        } else {
            currentRound = currentRound - 2;
        }

        uint256 startRound = latestRounds >= currentRound
            ? 0
            : currentRound - latestRounds;

        // Got result
        for (uint256 i = 0; i < actionIds.length; i++) {
            for (uint256 round = startRound; round <= currentRound; round++) {
                if (
                    ILOVE20Mint(mintAddress).isActionIdWithReward(
                        token,
                        round,
                        actionIds[i]
                    )
                ) {
                    (uint256 reward, bool isMinted) = ILOVE20Mint(mintAddress)
                        .actionRewardByActionIdByAccount(
                            token,
                            round,
                            actionIds[i],
                            account
                        );

                    if (reward > 0 && !isMinted) {
                        return true;
                    }
                }
            }
        }

        return false;
    }

    function estimatedActionRewardOfCurrentRound(
        address tokenAddress
    ) external view returns (uint256) {
        uint256 realRound = ILOVE20Join(joinAddress).currentRound();
        uint256 leftReward = ILOVE20Mint(mintAddress).rewardAvailable(
            tokenAddress
        );

        if (
            realRound >
            ILOVE20Stake(stakeAddress).initialStakeRound(tokenAddress)
        ) {
            bool isPreRewardPrepared = ILOVE20Mint(mintAddress)
                .isRewardPrepared(tokenAddress, realRound - 1);
            if (!isPreRewardPrepared) {
                leftReward =
                    (leftReward *
                        (1000 -
                            ILOVE20Mint(mintAddress)
                                .ROUND_REWARD_GOV_PER_THOUSAND() -
                            ILOVE20Mint(mintAddress)
                                .ROUND_REWARD_ACTION_PER_THOUSAND())) /
                    1000;
            }
        }

        return
            (leftReward *
                ILOVE20Mint(mintAddress).ROUND_REWARD_ACTION_PER_THOUSAND()) /
            1000;
    }

    function estimatedGovRewardOfCurrentRound(
        address tokenAddress
    ) external view returns (uint256) {
        uint256 realRound = ILOVE20Vote(voteAddress).currentRound();
        uint256 relativeRound = realRound -
            ILOVE20Stake(stakeAddress).initialStakeRound(tokenAddress);
        uint256 leftReward = ILOVE20Mint(mintAddress).rewardAvailable(
            tokenAddress
        );

        if (relativeRound > 0) {
            leftReward =
                (leftReward *
                    (1000 -
                        ILOVE20Mint(mintAddress)
                            .ROUND_REWARD_GOV_PER_THOUSAND() -
                        ILOVE20Mint(mintAddress)
                            .ROUND_REWARD_ACTION_PER_THOUSAND())) /
                1000;
            if (relativeRound > 1) {
                bool isPreRewardPrepared = ILOVE20Mint(mintAddress)
                    .isRewardPrepared(tokenAddress, realRound - 2);
                if (!isPreRewardPrepared) {
                    leftReward =
                        (leftReward *
                            (1000 -
                                ILOVE20Mint(mintAddress)
                                    .ROUND_REWARD_GOV_PER_THOUSAND() -
                                ILOVE20Mint(mintAddress)
                                    .ROUND_REWARD_ACTION_PER_THOUSAND())) /
                        1000;
                }
            }
        }

        return
            (leftReward *
                ILOVE20Mint(mintAddress).ROUND_REWARD_GOV_PER_THOUSAND()) /
            1000;
    }
}
