// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

interface ILOVE20Launch {
    function launches(address tokenAddress) external view returns (LaunchInfo memory);
    function tokenAddressBySymbol(string memory symbol) external view returns (address);
    function stakeAddress() external view returns (address);
}

interface ILOVE20Stake {
    function govVotesNum(address tokenAddress) external view returns (uint256);
    function initialStakeRound(address tokenAddress) external view returns (uint256);
}

interface ILOVE20Submit {
    function actionInfo(
        address tokenAddress,
        uint256 actionId
    ) external view returns (ActionInfo memory);
    function actionInfosByIds(
        address tokenAddress,
        uint256[] calldata actionIds
    ) external view returns (ActionInfo[] memory);
}

interface ILOVE20Vote {
    function votesNums(address tokenAddress, uint256 round)
        external
        view
        returns (uint256[] memory actionIds, uint256[] memory votes);
}

interface ILOVE20Join {
    function amountByActionId(address tokenAddress, uint256 actionId)
        external
        view
        returns (uint256);

    function actionIdsByAccount(address tokenAddress, address account) external view returns (uint256[] memory);

    function amountByActionIdByAccount(address tokenAddress, uint256 actionId, address account)
        external
        view
        returns (uint256);

    function randomAccounts(address tokenAddress, uint256 round, uint256 actionId)
        external
        view
        returns (address[] memory);

    function verificationInfo(
        address tokenAddress,
        address accountAddress,
        string memory verificationKey
    ) external view returns (string memory);
}

interface ILOVE20Verify {

    function scoreByActionIdByAccount(address tokenAddress, uint256 round, uint256 actionId, address account)
        external
        view
        returns (uint256);
}

interface ILOVE20Mint {
    function actionRewardByActionIdByAccount(
        address tokenAddress,
        uint256 round,
        uint256 actionId,
        address accountAddress
    ) external view returns (uint256);

    function govRewardByAccount(address tokenAddress, uint256 round, address accountAddress)
        external
        view
        returns (uint256 verifyReward, uint256 boostReward, uint256 burnReward);

    function govRewardMintedByAccount(address tokenAddress, uint256 round, address accountAddress)
        external
        view
        returns (uint256);
}

interface LOVE20Token {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256);
    function slAddress() external view returns (address);
    function stAddress() external view returns (address);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

interface ILOVE20SLToken {
    function uniswapV2Pair() external view returns (address);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

struct ActionHead {
    // managed by contract
    uint256 id;
    address author;
    uint256 createAtBlock;
}

struct ActionBody {
    // max token amount for staking
    uint256 maxStake;
    // max random accounts for verification
    uint256 maxRandomAccounts;
    // contract must comply with IWhiteList. If not set, all users can join the action.
    address[] whiteList;
    // action info
    string action;
    string consensus;
    string verificationRule;
    // guide for inputting verification info
    string[] verificationKeys;
    string[] verificationInfoGuides;
}

struct ActionInfo {
    ActionHead head;
    ActionBody body;
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

struct GovData {
    uint256 govVotes;
    uint256 slAmount;
    uint256 stAmount;
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

struct VerificationInfo {
    address account;
    string[] infos;
}

struct AccountPairInfo {
    address pairAddress;
    uint256 balanceOfToken;
    uint256 balanceOfParentToken;
    uint256 allowanceOfToken;
    uint256 allowanceOfParentToken;
    uint256 pairReserveToken;
    uint256 pairReserveParentToken;
}

contract LOVE20DataViewer {
    address public initSetter;

    address public launchAddress;
    address public submitAddress;
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

    function accountPair(address account, address tokenAddress, address parentTokenAddress)
        external
        view
        returns (AccountPairInfo memory pairInfo)
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
        pairInfo = AccountPairInfo({
            pairAddress: pairAddress,
            balanceOfToken: LOVE20Token(tokenAddress).balanceOf(account),
            balanceOfParentToken: LOVE20Token(parentTokenAddress).balanceOf(account),
            allowanceOfToken: LOVE20Token(tokenAddress).allowance(account, stakeAddress),
            allowanceOfParentToken: LOVE20Token(parentTokenAddress).allowance(account, stakeAddress),
            pairReserveToken: reserveToken,
            pairReserveParentToken: reserveParentToken
        });
    }
}
