// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

interface ILOVE20Launch {
    function launches(
        address tokenAddress
    ) external view returns (LaunchInfo memory);
}

interface ILOVE20Vote {
    function votesNums(
        address tokenAddress,
        uint256 round
    )
        external
        view
        returns (uint256[] memory actionIds, uint256[] memory votes);
}

interface ILOVE20Join {
    function joinedAmountByActionId(
        address tokenAddress,
        uint256 round,
        uint256 actionId
    ) external view returns (uint256);

    function stakedActionIdsByAccount(
        address tokenAddress,
        address account
    ) external view returns (uint256[] memory);

    function lastJoinedRoundByAccountByActionId(
        address tokenAddress,
        address account,
        uint256 actionId
    ) external view returns (uint256);

    function stakedAmountByAccountByActionId(
        address tokenAddress,
        address account,
        uint256 actionId
    ) external view returns (uint256);

    function verificationInfo(
        address tokenAddress,
        uint256 round,
        uint256 actionId,
        address accountAddress
    ) external view returns (string memory);
}

interface ILOVE20Verify {
    function accountsForVerify(
        address tokenAddress,
        uint256 round,
        uint256 actionId
    ) external view returns (address[] memory);

    function scoreByActionIdByAccount(
        address tokenAddress,
        uint256 round,
        uint256 actionId,
        address account
    ) external view returns (uint256);
}

interface ILOVE20Mint {
    function actionRewardByActionIdByAccount(
        address tokenAddress,
        uint256 round,
        uint256 actionId,
        address accountAddress
    ) external view returns (uint256);

    function govRewardByAccount(
        address tokenAddress,
        uint256 round,
        address accountAddress
    ) external view returns (uint256 verifyReward, uint256 boostReward, uint256 burnReward);

    function govRewardMintedByAccount(
        address tokenAddress,
        uint256 round,
        address accountAddress
    ) external view returns (uint256);
}

interface IERC20 {
    function symbol() external view returns (string memory);
}

struct JoinableAction {
    uint256 actionId;
    uint256 votesNum;
    uint256 joinedAmount;
}

struct JoinedAction {
    uint256 actionId;
    uint256 lastJoinedRound;
    uint256 stakedAmount;
}

struct VerifiedAddress {
    address account;
    uint256 score;
    uint256 reward;
}

struct GovReward {
    uint256 round;
    uint256 minted;
    uint256 unminted;
}

struct LaunchInfo {
    address parentTokenAddress;
    uint256 parentTokenFundraisingGoal;
    uint256 secondHalfMinBlocks;
    uint256 launchAmount;
    uint256 startBlock;
    uint256 secondHalfStartBlock;
    bool hasEnded;
    uint256 participantCount;
    uint256 totalContributed;
    uint256 totalExtraRefunded;
}

contract LOVE20DataViewer {
    address public initSetter;

    address public launchAddress;
    address public voteAddress;
    address public joinAddress;
    // address public randomAddress; // Removed randomAddress
    address public verifyAddress;
    address public mintAddress;

    constructor(address initSetter_) {
        initSetter = initSetter_;
    }

    modifier onlyInitSetter() {
        require(msg.sender == initSetter, "msg.sender is not initSetter");
        _;
    }

    function setInitSetter(address newInitSetter) external onlyInitSetter {
        initSetter = newInitSetter;
    }

    function init(
        address launchAddress_,
        address voteAddress_,
        address joinAddress_,
        address verifyAddress_,
        address mintAddress_
    ) external onlyInitSetter {
        launchAddress = launchAddress_;
        voteAddress = voteAddress_;
        joinAddress = joinAddress_;
        verifyAddress = verifyAddress_;
        mintAddress = mintAddress_;
    }

    function joinableActions(
        address tokenAddress,
        uint256 round
    ) external view returns (JoinableAction[] memory) {
        (uint256[] memory actionIds, uint256[] memory votes) = ILOVE20Vote(
            voteAddress
        ).votesNums(tokenAddress, round);
        JoinableAction[] memory actions = new JoinableAction[](
            actionIds.length
        );
        for (uint256 i = 0; i < actionIds.length; i++) {
            actions[i] = JoinableAction({
                actionId: actionIds[i],
                votesNum: votes[i],
                joinedAmount: ILOVE20Join(joinAddress).joinedAmountByActionId(
                    tokenAddress,
                    round,
                    actionIds[i]
                )
            });
        }
        return actions;
    }

    function joinedActions(
        address tokenAddress,
        address account
    ) external view returns (JoinedAction[] memory) {
        uint256[] memory actionIds = ILOVE20Join(joinAddress)
            .stakedActionIdsByAccount(tokenAddress, account);
        JoinedAction[] memory actions = new JoinedAction[](actionIds.length);
        for (uint256 i = 0; i < actionIds.length; i++) {
            actions[i] = JoinedAction({
                actionId: actionIds[i],
                lastJoinedRound: ILOVE20Join(joinAddress)
                    .lastJoinedRoundByAccountByActionId(
                        tokenAddress,
                        account,
                        actionIds[i]
                    ),
                stakedAmount: ILOVE20Join(joinAddress)
                    .stakedAmountByAccountByActionId(
                        tokenAddress,
                        account,
                        actionIds[i]
                    )
            });
        }
        return actions;
    }

    function verifiedAddressesByAction(
        address tokenAddress,
        uint256 round,
        uint256 actionId
    ) external view returns (VerifiedAddress[] memory) {
        address[] memory accounts = ILOVE20Verify(verifyAddress)
            .accountsForVerify(tokenAddress, round, actionId);
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
                reward: ILOVE20Mint(mintAddress)
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

    function govRewardsByAccountByRounds(
        address tokenAddress,
        address account,
        uint256 startRound,
        uint256 endRound
    ) external view returns (GovReward[] memory rewards) {

        require(startRound >= 0, "startRound < 0");
        require(endRound >= 0, "endRound < 0");

        uint256 minRound = startRound;
        uint256 maxRound = endRound;
        if (startRound > endRound) {
            minRound = endRound;
            maxRound = startRound;
        }
        rewards = new GovReward[](maxRound - minRound + 1);
        for (uint256 i = minRound; i <= maxRound; i++) {
            (uint256 verifyReward, uint256 boostReward, ) = ILOVE20Mint(mintAddress)
                .govRewardByAccount(tokenAddress, i, account);
            rewards[i - minRound] = GovReward({
                round: i,
                unminted: verifyReward + boostReward,
                minted: ILOVE20Mint(mintAddress).govRewardMintedByAccount(
                    tokenAddress,
                    i,
                    account
                )
            });
        }
    }

    function verificationInfosByAction(
        address tokenAddress,
        uint256 round,
        uint256 actionId
    ) external view returns (address[] memory accounts, string[] memory infos) {
        accounts = ILOVE20Verify(verifyAddress).accountsForVerify(
            tokenAddress,
            round,
            actionId
        );
        infos = new string[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            infos[i] = ILOVE20Join(joinAddress).verificationInfo(
                tokenAddress,
                round,
                actionId,
                accounts[i]
            );
        }
        return (accounts, infos);
    }

    function tokenDetail(
        address tokenAddress
    )
        public
        view
        returns (
            string memory symbol,
            string memory parentTokenSymbol,
            LaunchInfo memory launchInfo
        )
    {
        launchInfo = ILOVE20Launch(launchAddress).launches(tokenAddress);
        return (
            IERC20(tokenAddress).symbol(),
            IERC20(launchInfo.parentTokenAddress).symbol(),
            launchInfo
        );
    }

    function tokenDetails(
        address[] memory tokenAddresses
    )
        external
        view
        returns (
            string[] memory symbols,
            string[] memory parentTokenSymbols,
            LaunchInfo[] memory launchInfos
        )
    {
        symbols = new string[](tokenAddresses.length);
        parentTokenSymbols = new string[](tokenAddresses.length);
        launchInfos = new LaunchInfo[](tokenAddresses.length);
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            (symbols[i], parentTokenSymbols[i], launchInfos[i]) = tokenDetail(
                tokenAddresses[i]
            );
        }

        return (symbols, parentTokenSymbols, launchInfos);
    }
}
