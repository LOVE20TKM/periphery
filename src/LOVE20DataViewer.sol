// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import "./interfaces/ILOVE20Core.sol";

struct TokenInfo {
    address tokenAddress;
    string name;
    string symbol;
    uint256 decimals;
    string parentTokenSymbol;
    address slAddress;
    address stAddress;
    uint256 initialStakeRound;
}

struct PairInfoWithAccount {
    address pairAddress;
    uint256 balanceOfToken;
    uint256 balanceOfParentToken;
    uint256 allowanceOfToken;
    uint256 allowanceOfParentToken;
    uint256 pairReserveToken;
    uint256 pairReserveParentToken;
}

struct JoinableAction {
    uint256 actionId;
    uint256 votesNum;
    uint256 joinedAmount;
}

struct JoinableActionDetail {
    ActionInfo action;
    uint256 votesNum;
    uint256 joinedAmount;
}

struct JoinedAction {
    ActionInfo action;
    uint256 stakedAmount;
    uint256 votesNum;
    uint256 votePercent;
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
}

struct MyVerifyingAction {
    ActionInfo action;
    uint256 myVotesNum;
    uint256 totalVotesNum;
}

struct VerifiedAddress {
    address account;
    uint256 score;
    uint256 minted;
    uint256 unminted;
}

struct VerificationInfo {
    address account;
    string[] infos;
}

struct RewardInfo {
    uint256 round;
    uint256 minted;
    uint256 unminted;
}

contract LOVE20DataViewer {
    address public launchAddress;
    address public submitAddress;
    address public voteAddress;
    address public joinAddress;
    address public verifyAddress;
    address public mintAddress;

    bool public initialized;

    constructor() {}

    function init(
        address launchAddress_,
        address submitAddress_,
        address voteAddress_,
        address joinAddress_,
        address verifyAddress_,
        address mintAddress_
    ) external {
        require(!initialized, "Already initialized");

        launchAddress = launchAddress_;
        submitAddress = submitAddress_;
        voteAddress = voteAddress_;
        joinAddress = joinAddress_;
        verifyAddress = verifyAddress_;
        mintAddress = mintAddress_;

        initialized = true;
    }

    //---------------- Token related functions ----------------

    function tokenDetail(
        address tokenAddress
    )
        public
        view
        returns (TokenInfo memory tokenInfo, LaunchInfo memory launchInfo)
    {
        launchInfo = ILOVE20Launch(launchAddress).launches(tokenAddress);
        address stakeAddress = ILOVE20Launch(launchAddress).stakeAddress();
        LOVE20Token love20 = LOVE20Token(tokenAddress);
        tokenInfo = TokenInfo({
            tokenAddress: tokenAddress,
            name: love20.name(),
            symbol: love20.symbol(),
            decimals: love20.decimals(),
            parentTokenSymbol: LOVE20Token(launchInfo.parentTokenAddress)
                .symbol(),
            slAddress: love20.slAddress(),
            stAddress: love20.stAddress(),
            initialStakeRound: ILOVE20Stake(stakeAddress).initialStakeRound(
                tokenAddress
            )
        });
        return (tokenInfo, launchInfo);
    }

    function tokenDetails(
        address[] memory tokenAddresses
    )
        external
        view
        returns (TokenInfo[] memory tokenInfos, LaunchInfo[] memory launchInfos)
    {
        tokenInfos = new TokenInfo[](tokenAddresses.length);
        launchInfos = new LaunchInfo[](tokenAddresses.length);
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            (tokenInfos[i], launchInfos[i]) = tokenDetail(tokenAddresses[i]);
        }

        return (tokenInfos, launchInfos);
    }

    function tokenDetailBySymbol(
        string memory symbol
    )
        external
        view
        returns (TokenInfo memory tokenInfo, LaunchInfo memory launchInfo)
    {
        address tokenAddress = ILOVE20Launch(launchAddress)
            .tokenAddressBySymbol(symbol);
        return tokenDetail(tokenAddress);
    }

    function tokenPairInfoWithAccount(
        address account,
        address tokenAddress,
        address parentTokenAddress
    ) external view returns (PairInfoWithAccount memory pairInfo) {
        address slAddress = LOVE20Token(tokenAddress).slAddress();
        address pairAddress;
        uint256 reserveToken;
        uint256 reserveParentToken;

        // get reserve0 and reserve1
        {
            pairAddress = ILOVE20SLToken(slAddress).uniswapV2Pair();
            (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairAddress)
                .getReserves();
            address token0 = IUniswapV2Pair(pairAddress).token0();
            address token1 = IUniswapV2Pair(pairAddress).token1();

            if (token0 == tokenAddress && token1 == parentTokenAddress) {
                reserveToken = reserve0;
                reserveParentToken = reserve1;
            } else if (token0 == parentTokenAddress && token1 == tokenAddress) {
                reserveToken = reserve1;
                reserveParentToken = reserve0;
            } else {
                revert("token address or parent token address is not correct");
            }
        }

        // get other info
        address stakeAddress = ILOVE20Launch(launchAddress).stakeAddress();
        pairInfo = PairInfoWithAccount({
            pairAddress: pairAddress,
            balanceOfToken: LOVE20Token(tokenAddress).balanceOf(account),
            balanceOfParentToken: LOVE20Token(parentTokenAddress).balanceOf(
                account
            ),
            allowanceOfToken: LOVE20Token(tokenAddress).allowance(
                account,
                stakeAddress
            ),
            allowanceOfParentToken: LOVE20Token(parentTokenAddress).allowance(
                account,
                stakeAddress
            ),
            pairReserveToken: reserveToken,
            pairReserveParentToken: reserveParentToken
        });
    }

    //---------------- Action related functions ----------------

    function joinableActions(
        address tokenAddress,
        uint256 round,
        address account
    )
        external
        view
        returns (JoinableActionDetail[] memory, JoinedAction[] memory)
    {
        (uint256[] memory actionIds, uint256[] memory votes) = ILOVE20Vote(
            voteAddress
        ).votesNums(tokenAddress, round);
        ActionInfo[] memory actionInfos = ILOVE20Submit(submitAddress)
            .actionInfosByIds(tokenAddress, actionIds);
        JoinableActionDetail[]
            memory joinableActionDetails = new JoinableActionDetail[](
                actionInfos.length
            );
        for (uint256 i = 0; i < actionInfos.length; i++) {
            joinableActionDetails[i] = JoinableActionDetail({
                action: actionInfos[i],
                votesNum: votes[i],
                joinedAmount: ILOVE20Join(joinAddress).amountByActionId(
                    tokenAddress,
                    actionIds[i]
                )
            });
        }
        JoinedAction[] memory joinedActions_ = this.joinedActions(
            tokenAddress,
            account
        );
        return (joinableActionDetails, joinedActions_);
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
        (joinableActionIds, votes) = ILOVE20Vote(voteAddress).votesNums(
            tokenAddress,
            round
        );
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
        ActionInfo[] memory actionInfos = ILOVE20Submit(submitAddress)
            .actionInfosByIds(tokenAddress, actionIds);
        JoinedAction[] memory actions = new JoinedAction[](actionIds.length);

        // append action infos and votes num
        for (uint256 i = 0; i < actionIds.length; i++) {
            uint256 currentVotes = _findVotes(
                joinableActionIds,
                votes,
                actionIds[i]
            );

            actions[i] = JoinedAction({
                action: actionInfos[i],
                stakedAmount: ILOVE20Join(joinAddress)
                    .amountByActionIdByAccount(
                        tokenAddress,
                        actionIds[i],
                        account
                    ),
                votesNum: currentVotes,
                votePercent: totalVotes > 0
                    ? (currentVotes * 10000) / totalVotes
                    : 0
            });
        }
        return actions;
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

    function verifyingActions(
        address tokenAddress,
        uint256 round,
        address account
    ) external view returns (VerifyingAction[] memory) {
        // 1. get action ids and votes num
        (uint256[] memory actionIds, uint256[] memory votes) = ILOVE20Vote(
            voteAddress
        ).votesNums(tokenAddress, round);

        // 2. get action infos
        ActionInfo[] memory actionInfos = ILOVE20Submit(submitAddress)
            .actionInfosByIds(tokenAddress, actionIds);

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
                    )
            });
        }

        return actions;
    }

    function verifingActionsByAccount(
        address tokenAddress,
        uint256 round,
        address account
    ) external view returns (MyVerifyingAction[] memory) {
        // 1. get action ids and total votes num
        (uint256[] memory actionIds, uint256[] memory votes) = ILOVE20Vote(
            voteAddress
        ).votesNumsByAccount(tokenAddress, round, account);

        // 2. get action infos
        ActionInfo[] memory actionInfos = ILOVE20Submit(submitAddress)
            .actionInfosByIds(tokenAddress, actionIds);

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
                myVotesNum: votes[i]
            });
        }
        return myActions;
    }

    //---------------- Gov related functions ----------------

    function govData(
        address tokenAddress
    ) external view returns (GovData memory govData_) {
        LOVE20Token love20 = LOVE20Token(tokenAddress);
        uint256 slAmount = LOVE20Token(love20.slAddress()).totalSupply();

        address stakeAddress = ILOVE20Launch(launchAddress).stakeAddress();
        (uint256 tokenAmount, uint256 parentTokenAmount) = ILOVE20SLToken(
            love20.slAddress()
        ).tokenAmountsBySlAmount(slAmount);
        uint256 rewardAvailable = ILOVE20Mint(mintAddress).rewardAvailable(
            tokenAddress
        );

        govData_ = GovData({
            govVotes: ILOVE20Stake(stakeAddress).govVotesNum(tokenAddress),
            slAmount: slAmount,
            stAmount: LOVE20Token(love20.stAddress()).totalSupply(),
            tokenAmountForSl: tokenAmount,
            parentTokenAmountForSl: parentTokenAmount,
            rewardAvailable: rewardAvailable
        });
        return govData_;
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
            verifiedAddresses[i] = VerifiedAddress({
                account: accounts[i],
                score: ILOVE20Verify(verifyAddress).scoreByActionIdByAccount(
                    tokenAddress,
                    round,
                    actionId,
                    accounts[i]
                ),
                minted: ILOVE20Mint(mintAddress).actionRewardMintedByAccount(
                    tokenAddress,
                    round,
                    actionId,
                    accounts[i]
                ),
                unminted: ILOVE20Mint(mintAddress)
                    .actionRewardByActionIdByAccount(
                        tokenAddress,
                        round,
                        actionId,
                        accounts[i]
                    )
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
                        .verificationInfo(
                            tokenAddress,
                            accounts[i],
                            actionInfo.body.verificationKeys[j]
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
    ) external view returns (RewardInfo[] memory rewards) {
        require(
            startRound <= endRound,
            "startRound must be less than or equal to endRound"
        );

        rewards = new RewardInfo[](endRound - startRound + 1);
        for (uint256 i = startRound; i <= endRound; i++) {
            (uint256 verifyReward, uint256 boostReward, ) = ILOVE20Mint(
                mintAddress
            ).govRewardByAccount(tokenAddress, i, account);
            rewards[i - startRound] = RewardInfo({
                round: i,
                minted: ILOVE20Mint(mintAddress).govRewardMintedByAccount(
                    tokenAddress,
                    i,
                    account
                ),
                unminted: verifyReward + boostReward
            });
        }
    }

    function actionRewardsByAccountByActionIdByRounds(
        address tokenAddress,
        address accountAddress,
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
            uint256 minted = 0;
            uint256 unminted = 0;

            if (
                ILOVE20Verify(verifyAddress).isActionIdWithReward(
                    tokenAddress,
                    i,
                    actionId
                )
            ) {
                minted = ILOVE20Mint(mintAddress).actionRewardMintedByAccount(
                    tokenAddress,
                    i,
                    actionId,
                    accountAddress
                );
                unminted = ILOVE20Mint(mintAddress)
                    .actionRewardByActionIdByAccount(
                        tokenAddress,
                        i,
                        actionId,
                        accountAddress
                    );
            }

            rewards[i - startRound] = RewardInfo({
                round: i,
                minted: minted,
                unminted: unminted
            });
        }

        return rewards;
    }
}
