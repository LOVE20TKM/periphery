// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.17;

import "./interfaces/ILOVE20Stake.sol";
import "./interfaces/ILOVE20SLToken.sol";
import "./interfaces/ILOVE20Vote.sol";
import "./interfaces/ILOVE20Submit.sol";
import "./interfaces/ILOVE20Join.sol";
import "./interfaces/ILOVE20Verify.sol";
import "./interfaces/ILOVE20Mint.sol";
import "./interfaces/ILOVE20Token.sol";

struct VotingAction {
    ActionInfo action;
    address submitter;
    uint256 votesNum;
    uint256 myVotesNum;
}

struct JoinableAction {
    ActionInfo action;
    uint256 votesNum;
    bool hasReward;
    uint256 joinedAmount;
    uint256 joinedAmountOfAccount;
}

struct JoinedAction {
    ActionInfo action;
    uint256 votesNum;
    uint256 votePercentPerTenThousand;
    bool hasReward;
    uint256 joinedAmountOfAccount;
}

struct GovData {
    uint256 govVotes;
    uint256 slAmount;
    uint256 stAmount;
    uint256 tokenAmountForSl;
    uint256 parentTokenAmountForSl;
    uint256 rewardAvailable;
}

struct VerifyingAction {
    ActionInfo action;
    uint256 votesNum;
    uint256 verificationScore;
    uint256 myVotesNum;
    uint256 myVerificationScore;
}

struct MyVerifyingAction {
    ActionInfo action;
    uint256 totalVotesNum;
    uint256 myVotesNum;
    uint256 myVerificationScore;
}

struct VerifiedAddress {
    address account;
    uint256 score;
    uint256 reward;
    bool isMinted;
}

struct VerificationInfo {
    address account;
    string[] infos;
}

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

struct TokenStats {
    // Minting status
    uint256 maxSupply; // token.maxSupply()
    uint256 totalSupply; // token.totalSupply()
    uint256 reservedAvailable; // mintContract.reservedAvailable()
    uint256 rewardAvailable; // mintContract.rewardAvailable()
    // Minted token allocation
    uint256 pairReserveParentToken; // IUniswapV2Pair.getReserves()
    uint256 pairReserveToken; // IUniswapV2Pair.getReserves()
    uint256 totalLpSupply; // IUniswapV2Pair.getReserves()
    uint256 stakedTokenAmountForSt; // token.balanceOf(stContract)
    uint256 joinedTokenAmount; // token.balanceOf(joinContract)
    // SL/ST status
    uint256 totalSLSupply; // slContract.totalSupply()
    uint256 totalSTSupply; // stContract.totalSupply()
    uint256 parentTokenAmountForSl; // from slContract.tokenAmounts()
    uint256 tokenAmountForSl; // from slContract.tokenAmounts()
    // Launch status
    uint256 parentPool; //token.parentPool()
    // Governance status
    uint256 finishedRounds; // voteContract.currentRound() - stakeContract.initialStakeRound() - 2
    uint256 actionsCount; // submitContract.actionsCount()
    uint256 joiningActionsCount; // joinContract.votedActionIdsCount()
}

contract LOVE20RoundViewer {
    address public stakeAddress;
    address public submitAddress;
    address public voteAddress;
    address public joinAddress;
    address public verifyAddress;
    address public mintAddress;

    bool public initialized;

    constructor() {}

    function init(
        address stakeAddress_,
        address submitAddress_,
        address voteAddress_,
        address joinAddress_,
        address verifyAddress_,
        address mintAddress_
    ) external {
        require(!initialized, "Already initialized");

        stakeAddress = stakeAddress_;
        submitAddress = submitAddress_;
        voteAddress = voteAddress_;
        joinAddress = joinAddress_;
        verifyAddress = verifyAddress_;
        mintAddress = mintAddress_;

        initialized = true;
    }

    //---------------- Action related functions ----------------

    function actionInfosByIds(
        address tokenAddress,
        uint256[] memory actionIds
    ) public view returns (ActionInfo[] memory) {
        ActionInfo[] memory infos = new ActionInfo[](actionIds.length);
        for (uint256 i = 0; i < actionIds.length; i++) {
            infos[i] = ILOVE20Submit(submitAddress).actionInfo(
                tokenAddress,
                actionIds[i]
            );
        }
        return infos;
    }

    function actionInfosByPage(
        address tokenAddress,
        uint256 start,
        uint256 end
    ) external view returns (ActionInfo[] memory) {
        require(start <= end, "Invalid range");
        uint256 totalActions = ILOVE20Submit(submitAddress).actionsCount(
            tokenAddress
        );
        if (totalActions == 0) {
            return new ActionInfo[](0);
        }
        require(start < totalActions, "Out of range");
        if (end >= totalActions) {
            end = totalActions - 1;
        }

        ActionInfo[] memory actions = new ActionInfo[](end - start + 1);
        for (uint256 i = 0; i < actions.length; i++) {
            actions[i] = ILOVE20Submit(submitAddress).actionsAtIndex(
                tokenAddress,
                start + i
            );
        }
        return actions;
    }

    //---------------- Submit related functions ----------------
    function actionSubmits(
        address tokenAddress,
        uint256 round
    ) external view returns (ActionSubmitInfo[] memory) {
        uint256 count = ILOVE20Submit(submitAddress).actionSubmitsCount(
            tokenAddress,
            round
        );
        ActionSubmitInfo[] memory submits = new ActionSubmitInfo[](count);

        for (uint256 i = 0; i < count; i++) {
            submits[i] = ILOVE20Submit(submitAddress).actionSubmitsAtIndex(
                tokenAddress,
                round,
                i
            );
        }
        return submits;
    }

    //---------------- Vote related functions ----------------

    function votesNums(
        address tokenAddress,
        uint256 round
    ) public view returns (uint256[] memory actionIds, uint256[] memory votes) {
        ILOVE20Vote voteContract = ILOVE20Vote(voteAddress);
        uint256 count = voteContract.votedActionIdsCount(tokenAddress, round);
        actionIds = new uint256[](count);
        votes = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            actionIds[i] = voteContract.votedActionIdsAtIndex(
                tokenAddress,
                round,
                i
            );
            votes[i] = voteContract.votesNumByActionId(
                tokenAddress,
                round,
                actionIds[i]
            );
        }
    }

    function votingActions(
        address tokenAddress,
        uint256 round,
        address account
    ) external view returns (VotingAction[] memory) {
        uint256 actionSubmitsCount = ILOVE20Submit(submitAddress)
            .actionSubmitsCount(tokenAddress, round);
        VotingAction[] memory votingActions_ = new VotingAction[](
            actionSubmitsCount
        );
        for (uint256 i = 0; i < actionSubmitsCount; i++) {
            ActionSubmitInfo memory _submitInfo = ILOVE20Submit(submitAddress)
                .actionSubmitsAtIndex(tokenAddress, round, i);
            votingActions_[i] = VotingAction({
                action: ILOVE20Submit(submitAddress).actionInfo(
                    tokenAddress,
                    _submitInfo.actionId
                ),
                submitter: _submitInfo.submitter,
                votesNum: ILOVE20Vote(voteAddress).votesNumByActionId(
                    tokenAddress,
                    round,
                    _submitInfo.actionId
                ),
                myVotesNum: ILOVE20Vote(voteAddress)
                    .votesNumByAccountByActionId(
                        tokenAddress,
                        round,
                        account,
                        _submitInfo.actionId
                    )
            });
        }
        return votingActions_;
    }

    function joinableActions(
        address tokenAddress,
        uint256 round,
        address account
    ) external view returns (JoinableAction[] memory) {
        (uint256[] memory actionIds, uint256[] memory votes) = votesNums(
            tokenAddress,
            round
        );
        ActionInfo[] memory actionInfos = actionInfosByIds(
            tokenAddress,
            actionIds
        );
        JoinableAction[] memory joinableActionDetails = new JoinableAction[](
            actionInfos.length
        );
        for (uint256 i = 0; i < actionInfos.length; i++) {
            joinableActionDetails[i] = JoinableAction({
                action: actionInfos[i],
                votesNum: votes[i],
                hasReward: ILOVE20Mint(mintAddress).isActionIdWithReward(
                    tokenAddress,
                    round,
                    actionIds[i]
                ),
                joinedAmount: ILOVE20Join(joinAddress).amountByActionId(
                    tokenAddress,
                    actionIds[i]
                ),
                joinedAmountOfAccount: ILOVE20Join(joinAddress)
                    .amountByActionIdByAccount(
                        tokenAddress,
                        actionIds[i],
                        account
                    )
            });
        }
        return joinableActionDetails;
    }

    function joinedActions(
        address tokenAddress,
        address account
    ) external view returns (JoinedAction[] memory) {
        // get voting info
        (
            uint256[] memory joinableActionIds,
            uint256[] memory votes,
            uint256 totalVotes
        ) = _getVotingInfo(tokenAddress);

        // get joined actions
        return
            _getJoinedActions(
                tokenAddress,
                account,
                joinableActionIds,
                votes,
                totalVotes
            );
    }

    function _getVotingInfo(
        address tokenAddress
    )
        internal
        view
        returns (
            uint256[] memory joinableActionIds,
            uint256[] memory votes,
            uint256 totalVotes
        )
    {
        uint256 round = ILOVE20Join(joinAddress).currentRound();
        (joinableActionIds, votes) = votesNums(tokenAddress, round);
        totalVotes = 0;
        for (uint256 i = 0; i < votes.length; i++) {
            totalVotes += votes[i];
        }
        return (joinableActionIds, votes, totalVotes);
    }

    function _getJoinedActions(
        address tokenAddress,
        address account,
        uint256[] memory joinableActionIds,
        uint256[] memory votes,
        uint256 totalVotes
    ) internal view returns (JoinedAction[] memory) {
        // get joined actions
        uint256[] memory actionIds = ILOVE20Join(joinAddress)
            .actionIdsByAccount(tokenAddress, account);
        ActionInfo[] memory actionInfos = actionInfosByIds(
            tokenAddress,
            actionIds
        );
        JoinedAction[] memory actions = new JoinedAction[](actionIds.length);

        // get current round
        uint256 round = ILOVE20Join(joinAddress).currentRound();

        // append action infos and votes num
        for (uint256 i = 0; i < actionIds.length; i++) {
            actions[i] = _createJoinedAction(
                tokenAddress,
                account,
                round,
                actionIds[i],
                actionInfos[i],
                joinableActionIds,
                votes,
                totalVotes
            );
        }
        return actions;
    }

    function _createJoinedAction(
        address tokenAddress,
        address account,
        uint256 round,
        uint256 actionId,
        ActionInfo memory actionInfo,
        uint256[] memory joinableActionIds,
        uint256[] memory votes,
        uint256 totalVotes
    ) internal view returns (JoinedAction memory) {
        uint256 currentVotes = _findVotes(joinableActionIds, votes, actionId);

        return
            JoinedAction({
                action: actionInfo,
                votesNum: currentVotes,
                votePercentPerTenThousand: totalVotes > 0
                    ? (currentVotes * 10000) / totalVotes
                    : 0,
                hasReward: ILOVE20Mint(mintAddress).isActionIdWithReward(
                    tokenAddress,
                    round,
                    actionId
                ),
                joinedAmountOfAccount: ILOVE20Join(joinAddress)
                    .amountByActionIdByAccount(tokenAddress, actionId, account)
            });
    }

    function _findVotes(
        uint256[] memory joinableActionIds,
        uint256[] memory votes,
        uint256 actionId
    ) internal pure returns (uint256) {
        for (uint256 j = 0; j < joinableActionIds.length; j++) {
            if (joinableActionIds[j] == actionId) {
                return votes[j];
            }
        }
        return 0;
    }

    //---------------- Verify related functions ----------------

    function verifyingActions(
        address tokenAddress,
        uint256 round,
        address account
    ) external view returns (VerifyingAction[] memory) {
        // 1. get action ids and votes num
        (uint256[] memory actionIds, uint256[] memory votes) = votesNums(
            tokenAddress,
            round
        );

        // 2. get action infos
        ActionInfo[] memory actionInfos = actionInfosByIds(
            tokenAddress,
            actionIds
        );

        // 3. get verification scores
        VerifyingAction[] memory actions = new VerifyingAction[](
            actionIds.length
        );
        for (uint256 i = 0; i < actionIds.length; i++) {
            actions[i] = VerifyingAction({
                action: actionInfos[i],
                votesNum: votes[i],
                verificationScore: ILOVE20Verify(verifyAddress).scoreByActionId(
                    tokenAddress,
                    round,
                    actionIds[i]
                ),
                myVotesNum: ILOVE20Vote(voteAddress)
                    .votesNumByAccountByActionId(
                        tokenAddress,
                        round,
                        account,
                        actionIds[i]
                    ),
                myVerificationScore: ILOVE20Verify(verifyAddress)
                    .scoreByActionIdByAccount(
                        tokenAddress,
                        round,
                        actionIds[i],
                        account
                    )
            });
        }

        return actions;
    }

    function verifyingActionsByAccount(
        address tokenAddress,
        uint256 round,
        address account
    ) external view returns (MyVerifyingAction[] memory) {
        // 1. get action ids and total votes num
        (uint256[] memory actionIds, uint256[] memory votes) = ILOVE20Vote(
            voteAddress
        ).votesNumsByAccount(tokenAddress, round, account);

        // 2. get action infos
        ActionInfo[] memory actionInfos = actionInfosByIds(
            tokenAddress,
            actionIds
        );

        // 3. get my votes num and total votes num
        MyVerifyingAction[] memory myActions = new MyVerifyingAction[](
            actionIds.length
        );
        for (uint256 i = 0; i < actionIds.length; i++) {
            myActions[i] = MyVerifyingAction({
                action: actionInfos[i],
                totalVotesNum: ILOVE20Vote(voteAddress).votesNumByActionId(
                    tokenAddress,
                    round,
                    actionIds[i]
                ),
                myVotesNum: votes[i],
                myVerificationScore: ILOVE20Verify(verifyAddress)
                    .scoreByActionIdByAccount(
                        tokenAddress,
                        round,
                        actionIds[i],
                        account
                    )
            });
        }
        return myActions;
    }

    //---------------- Verification related functions ----------------

    function verifiedAddressesByAction(
        address tokenAddress,
        uint256 round,
        uint256 actionId
    ) external view returns (VerifiedAddress[] memory) {
        address[] memory accounts = ILOVE20Join(joinAddress).randomAccounts(
            tokenAddress,
            round,
            actionId
        );
        VerifiedAddress[] memory verifiedAddresses = new VerifiedAddress[](
            accounts.length
        );
        for (uint256 i = 0; i < accounts.length; i++) {
            (uint256 reward, bool isMinted) = ILOVE20Mint(mintAddress)
                .actionRewardByActionIdByAccount(
                    tokenAddress,
                    round,
                    actionId,
                    accounts[i]
                );
            verifiedAddresses[i] = VerifiedAddress({
                account: accounts[i],
                score: ILOVE20Verify(verifyAddress).scoreByActionIdByAccount(
                    tokenAddress,
                    round,
                    actionId,
                    accounts[i]
                ),
                reward: reward,
                isMinted: isMinted
            });
        }
        return verifiedAddresses;
    }

    function verificationInfosByAction(
        address tokenAddress,
        uint256 round,
        uint256 actionId
    ) external view returns (VerificationInfo[] memory verificationInfos) {
        address[] memory accounts = ILOVE20Join(joinAddress).randomAccounts(
            tokenAddress,
            round,
            actionId
        );
        if (accounts.length == 0) {
            return new VerificationInfo[](0);
        }

        ActionInfo memory actionInfo = ILOVE20Submit(submitAddress).actionInfo(
            tokenAddress,
            actionId
        );
        uint256 keysLength = actionInfo.body.verificationKeys.length;

        verificationInfos = new VerificationInfo[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            verificationInfos[i].account = accounts[i];
            if (keysLength > 0) {
                verificationInfos[i].infos = new string[](keysLength);
                for (uint256 j = 0; j < keysLength; j++) {
                    verificationInfos[i].infos[j] = ILOVE20Join(joinAddress)
                        .verificationInfoByRound(
                            tokenAddress,
                            accounts[i],
                            actionId,
                            actionInfo.body.verificationKeys[j],
                            round
                        );
                }
            } else {
                verificationInfos[i].infos = new string[](0);
            }
        }
        return verificationInfos;
    }

    function verificationInfosByAccount(
        address tokenAddress,
        uint256 actionId,
        address account
    )
        external
        view
        returns (
            string[] memory verificationKeys,
            string[] memory verificationInfos
        )
    {
        ActionInfo memory actionInfo = ILOVE20Submit(submitAddress).actionInfo(
            tokenAddress,
            actionId
        );
        uint256 keysLength = actionInfo.body.verificationKeys.length;
        verificationInfos = new string[](keysLength);
        for (uint256 i = 0; i < keysLength; i++) {
            verificationInfos[i] = ILOVE20Join(joinAddress).verificationInfo(
                tokenAddress,
                account,
                actionId,
                actionInfo.body.verificationKeys[i]
            );
        }
        return (actionInfo.body.verificationKeys, verificationInfos);
    }

    //---------------- Reward/mint related functions ----------------

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
        returns (ActionInfo[] memory actions, ActionReward[] memory rewards)
    {
        // Got joined action ids
        uint256[] memory actionIds = ILOVE20Join(joinAddress)
            .actionIdsByAccount(tokenAddress, account);

        if (actionIds.length == 0) {
            return (new ActionInfo[](0), new ActionReward[](0));
        }

        // Got current mint round
        uint256 currentRound = ILOVE20Join(joinAddress).currentRound();
        if (currentRound <= 2) {
            return (new ActionInfo[](0), new ActionReward[](0));
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
        actions = actionInfosByIds(tokenAddress, actionIds);

        return (actions, rewards);
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

    //---------------- Statistics related functions ----------------

    function govData(
        address tokenAddress
    ) external view returns (GovData memory govData_) {
        ILOVE20Token love20 = ILOVE20Token(tokenAddress);
        uint256 slAmount = ILOVE20Token(love20.slAddress()).totalSupply();
        uint256 withdrawableTokenAmount = 0;
        uint256 withdrawableParentTokenAmount = 0;
        if (slAmount > 0) {
            (
                withdrawableTokenAmount,
                withdrawableParentTokenAmount,
                ,

            ) = ILOVE20SLToken(love20.slAddress()).tokenAmounts();
        }

        uint256 rewardAvailable = ILOVE20Mint(mintAddress).rewardAvailable(
            tokenAddress
        );

        govData_ = GovData({
            govVotes: ILOVE20Stake(stakeAddress).govVotesNum(tokenAddress),
            slAmount: slAmount,
            stAmount: ILOVE20Token(love20.stAddress()).totalSupply(),
            tokenAmountForSl: withdrawableTokenAmount,
            parentTokenAmountForSl: withdrawableParentTokenAmount,
            rewardAvailable: rewardAvailable
        });
        return govData_;
    }

    //---------------- Token statistics related functions ----------------
    function tokenStatistics(
        address tokenAddress
    ) external view returns (TokenStats memory) {
        ILOVE20Token love20 = ILOVE20Token(tokenAddress);
        ILOVE20SLToken sl = ILOVE20SLToken(love20.slAddress());

        TokenStats memory stats;

        // Basic token info
        stats.maxSupply = love20.maxSupply();
        stats.totalSupply = love20.totalSupply();
        stats.reservedAvailable = ILOVE20Mint(mintAddress).reservedAvailable(
            tokenAddress
        );
        stats.rewardAvailable = ILOVE20Mint(mintAddress).rewardAvailable(
            tokenAddress
        );

        // Pair reserves
        address pairAddress = sl.uniswapV2Pair();
        if (pairAddress != address(0)) {
            (
                stats.pairReserveToken,
                stats.pairReserveParentToken,
                stats.totalLpSupply
            ) = sl.uniswapV2PairReserves();
        }

        // Token balances
        stats.stakedTokenAmountForSt = love20.balanceOf(love20.stAddress());
        stats.joinedTokenAmount = love20.balanceOf(joinAddress);

        // SL/ST totals
        stats.totalSLSupply = sl.totalSupply();
        stats.totalSTSupply = ILOVE20Token(love20.stAddress()).totalSupply();

        // SL withdrawable amounts
        if (stats.totalSLSupply > 0) {
            (stats.tokenAmountForSl, stats.parentTokenAmountForSl, , ) = sl
                .tokenAmounts();
        }

        // Launch info
        stats.parentPool = love20.parentPool();

        // Governance info
        uint256 currentRound = ILOVE20Vote(voteAddress).currentRound();
        uint256 initialRound = ILOVE20Stake(stakeAddress).initialStakeRound(
            tokenAddress
        );
        if (currentRound > initialRound + 2) {
            stats.finishedRounds = currentRound - initialRound - 2;
        }

        stats.actionsCount = ILOVE20Submit(submitAddress).actionsCount(
            tokenAddress
        );

        uint256 joinRound = ILOVE20Join(joinAddress).currentRound();
        stats.joiningActionsCount = ILOVE20Vote(voteAddress)
            .votedActionIdsCount(tokenAddress, joinRound);

        return stats;
    }
}
