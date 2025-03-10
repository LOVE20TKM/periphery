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
    uint256 actionId;
    uint256 stakedAmount;
}

struct GovData {
    uint256 govVotes;
    uint256 slAmount;
    uint256 stAmount;
}

struct VerifiedAddress {
    address account;
    uint256 score;
    uint256 reward;
}

struct VerificationInfo {
    address account;
    string[] infos;
}

struct GovReward {
    uint256 round;
    uint256 minted;
    uint256 unminted;
}

contract LOVE20DataViewer {
    address public initSetter;

    address public launchAddress;
    address public submitAddress;
    address public voteAddress;
    address public joinAddress;
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
        address submitAddress_,
        address voteAddress_,
        address joinAddress_,
        address verifyAddress_,
        address mintAddress_
    ) external onlyInitSetter {
        launchAddress = launchAddress_;
        submitAddress = submitAddress_;
        voteAddress = voteAddress_;
        joinAddress = joinAddress_;
        verifyAddress = verifyAddress_;
        mintAddress = mintAddress_;
    }


    //---------------- Token related functions ----------------

    function tokenDetail(address tokenAddress)
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
            parentTokenSymbol: LOVE20Token(launchInfo.parentTokenAddress).symbol(),
            slAddress: love20.slAddress(),
            stAddress: love20.stAddress(),
            initialStakeRound: ILOVE20Stake(stakeAddress).initialStakeRound(tokenAddress)
        });
        return (tokenInfo, launchInfo);
    }

    function tokenDetails(address[] memory tokenAddresses)
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

    function tokenDetailBySymbol(string memory symbol)
        external
        view
        returns (TokenInfo memory tokenInfo, LaunchInfo memory launchInfo)
    {
        address tokenAddress = ILOVE20Launch(launchAddress).tokenAddressBySymbol(symbol);
        return tokenDetail(tokenAddress);
    }

    function tokenPairInfoWithAccount(address account, address tokenAddress, address parentTokenAddress)
        external
        view
        returns (PairInfoWithAccount memory pairInfo)
    {
        address slAddress = LOVE20Token(tokenAddress).slAddress();
        address pairAddress;
        uint256 reserveToken;
        uint256 reserveParentToken;

        // get reserve0 and reserve1
        if (slAddress != address(0)) {
            pairAddress = ILOVE20SLToken(slAddress).uniswapV2Pair();
            (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairAddress).getReserves();
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
            balanceOfParentToken: LOVE20Token(parentTokenAddress).balanceOf(account),
            allowanceOfToken: LOVE20Token(tokenAddress).allowance(account, stakeAddress),
            allowanceOfParentToken: LOVE20Token(parentTokenAddress).allowance(account, stakeAddress),
            pairReserveToken: reserveToken,
            pairReserveParentToken: reserveParentToken
        });
    }


    //---------------- Action related functions ----------------

    function joinableActions(address tokenAddress, uint256 round) external view returns (JoinableAction[] memory) {
        (uint256[] memory actionIds, uint256[] memory votes) = ILOVE20Vote(voteAddress).votesNums(tokenAddress, round);
        JoinableAction[] memory actions = new JoinableAction[](actionIds.length);
        for (uint256 i = 0; i < actionIds.length; i++) {
            actions[i] = JoinableAction({
                actionId: actionIds[i],
                votesNum: votes[i],
                joinedAmount: ILOVE20Join(joinAddress).amountByActionId(tokenAddress, actionIds[i])
            });
        }
        return actions;
    }

    function joinableActionDetailsWithJoinedInfos(address tokenAddress, uint256 round, address account)
        external
        view
        returns (JoinableActionDetail[] memory, JoinedAction[] memory)
    {
        (uint256[] memory actionIds, uint256[] memory votes) = ILOVE20Vote(voteAddress).votesNums(tokenAddress, round);
        ActionInfo[] memory actionInfos = ILOVE20Submit(submitAddress).actionInfosByIds(tokenAddress, actionIds);
        JoinableActionDetail[] memory joinableActionDetails = new JoinableActionDetail[](actionInfos.length);
        for (uint256 i = 0; i < actionInfos.length; i++) {
            joinableActionDetails[i] = JoinableActionDetail({
                action: actionInfos[i],
                votesNum: votes[i],
                joinedAmount: ILOVE20Join(joinAddress).amountByActionIdByAccount(tokenAddress, actionIds[i], account)
            });
        }
        JoinedAction[] memory joinedActions_ = this.joinedActions(tokenAddress, account);
        return (joinableActionDetails, joinedActions_);
    }

    function joinedActions(address tokenAddress, address account) external view returns (JoinedAction[] memory) {
        uint256[] memory actionIds = ILOVE20Join(joinAddress).actionIdsByAccount(tokenAddress, account);
        JoinedAction[] memory actions = new JoinedAction[](actionIds.length);
        for (uint256 i = 0; i < actionIds.length; i++) {
            actions[i] = JoinedAction({
                actionId: actionIds[i],
                stakedAmount: ILOVE20Join(joinAddress).amountByActionIdByAccount(tokenAddress, actionIds[i], account)
            });
        }
        return actions;
    }


    //---------------- Gov related functions ----------------

    function govData(address tokenAddress)
        external
        view
        returns (GovData memory govData_)
    {
        LOVE20Token love20 = LOVE20Token(tokenAddress);
        address stakeAddress = ILOVE20Launch(launchAddress).stakeAddress();
        govData_ = GovData({
            govVotes: ILOVE20Stake(stakeAddress).govVotesNum(tokenAddress),
            slAmount: LOVE20Token(love20.slAddress()).totalSupply(),
            stAmount: LOVE20Token(love20.stAddress()).totalSupply()
        });
        return govData_;
    }


    //---------------- Verification related functions ----------------

    function verifiedAddressesByAction(address tokenAddress, uint256 round, uint256 actionId)
        external
        view
        returns (VerifiedAddress[] memory)
    {
        address[] memory accounts = ILOVE20Join(joinAddress).randomAccounts(tokenAddress, round, actionId);
        VerifiedAddress[] memory verifiedAddresses = new VerifiedAddress[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            verifiedAddresses[i] = VerifiedAddress({
                account: accounts[i],
                score: ILOVE20Verify(verifyAddress).scoreByActionIdByAccount(tokenAddress, round, actionId, accounts[i]),
                reward: ILOVE20Mint(mintAddress).actionRewardByActionIdByAccount(tokenAddress, round, actionId, accounts[i])
            });
        }
        return verifiedAddresses;
    }

    function verificationInfosByAction(address tokenAddress, uint256 round, uint256 actionId)
        external
        view
        returns (VerificationInfo[] memory verificationInfos)
    {
        address[] memory accounts = ILOVE20Join(joinAddress).randomAccounts(tokenAddress, round, actionId);
        if (accounts.length == 0) {
            return new VerificationInfo[](0);
        }

        ActionInfo memory actionInfo = ILOVE20Submit(submitAddress).actionInfo(tokenAddress, actionId);
        uint256 keysLength = actionInfo.body.verificationKeys.length;
        
        verificationInfos = new VerificationInfo[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            verificationInfos[i].account = accounts[i];
            if (keysLength > 0) {
                verificationInfos[i].infos = new string[](keysLength);
                for (uint256 j = 0; j < keysLength; j++) {
                    verificationInfos[i].infos[j] = ILOVE20Join(joinAddress).verificationInfo(tokenAddress, accounts[i], actionInfo.body.verificationKeys[j]);
                }
            } else {
                verificationInfos[i].infos = new string[](0);
            }
        }
        return verificationInfos;
    }
    
    function verificationInfosByAccount(address tokenAddress, uint256 actionId, address account)
        external
        view
        returns (string[] memory verificationKeys, string[] memory verificationInfos)
    {
        uint256 amount = ILOVE20Join(joinAddress).amountByActionIdByAccount(tokenAddress, actionId, account);
        if (amount == 0) {
            return (new string[](0), new string[](0));
        }

        ActionInfo memory actionInfo = ILOVE20Submit(submitAddress).actionInfo(tokenAddress, actionId);
        uint256 keysLength = actionInfo.body.verificationKeys.length;
        verificationInfos = new string[](keysLength);
        for (uint256 i = 0; i < keysLength; i++) {
            verificationInfos[i] = ILOVE20Join(joinAddress).verificationInfo(tokenAddress, account, actionInfo.body.verificationKeys[i]);
        }
        return (actionInfo.body.verificationKeys, verificationInfos);
    }

    //---------------- Reward/mint related functions ----------------

    function govRewardsByAccountByRounds(address tokenAddress, address account, uint256 startRound, uint256 endRound)
        external
        view
        returns (GovReward[] memory rewards)
    {
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
            (uint256 verifyReward, uint256 boostReward,) =
                ILOVE20Mint(mintAddress).govRewardByAccount(tokenAddress, i, account);
            rewards[i - minRound] = GovReward({
                round: i,
                unminted: verifyReward + boostReward,
                minted: ILOVE20Mint(mintAddress).govRewardMintedByAccount(tokenAddress, i, account)
            });
        }
    }

    function actionRewardRoundsByAccount(
        address tokenAddress,
        address accountAddress,
        uint256 actionId,
        uint256 startRound,
        uint256 endRound
    ) public view returns (uint256[] memory rounds, uint256[] memory rewards) {
        require(startRound <= endRound, "startRound must be less than or equal to endRound");

        uint256 currentRound = ILOVE20Mint(mintAddress).currentRound();
        uint256 effectiveRoundEnd = endRound > currentRound ? currentRound : endRound;
        
        // 首先计算有效奖励的数量
        uint256 validCount = 0;
        for (uint256 round = startRound; round <= effectiveRoundEnd; round++) {
            (bool hasReward, ) = _getRewardForRound(tokenAddress, accountAddress, actionId, round);
            if (hasReward) {
                validCount++;
            }
        }
        
        // Create arrays with exact size
        rounds = new uint256[](validCount);
        rewards = new uint256[](validCount);
        
        // 填充数组
        uint256 index = 0;
        for (uint256 round = startRound; round <= effectiveRoundEnd; round++) {
            (bool hasReward, uint256 reward) = _getRewardForRound(tokenAddress, accountAddress, actionId, round);
            if (hasReward) {
                rounds[index] = round;
                rewards[index] = reward;
                index++;
            }
        }
        
        return (rounds, rewards);
    }
    function _getRewardForRound(
        address tokenAddress,
        address accountAddress,
        uint256 actionId,
        uint256 round
    ) private view returns (bool hasReward, uint256 reward) {
        if (!ILOVE20Verify(verifyAddress).isActionIdWithReward(tokenAddress, round, actionId)) {
            return (false, 0);
        }
        
        reward = ILOVE20Mint(mintAddress).actionRewardByActionIdByAccount(
            tokenAddress,
            round,
            actionId,
            accountAddress
        );
        
        return (reward > 0, reward);
    }
}