// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.17;

struct LaunchInfo {
    address parentTokenAddress;
    uint256 parentTokenFundraisingGoal;
    uint256 secondHalfMinBlocks;
    uint256 launchAmount;
    uint256 startBlock;
    uint256 secondHalfStartBlock;
    uint256 endBlock;
    bool hasEnded;
    uint256 participantCount;
    uint256 totalContributed;
    uint256 totalExtraRefunded;
}

struct ActionHead {
    // managed by contract
    uint256 id;
    address author;
    uint256 createAtBlock;
}

struct ActionBody {
    uint256 minStake;
    uint256 maxRandomAccounts;
    address whiteListAddress;
    string title;
    string verificationRule;
    string[] verificationKeys;
    string[] verificationInfoGuides;
}

struct ActionInfo {
    ActionHead head;
    ActionBody body;
}

struct ActionSubmitInfo {
    address submitter;
    uint256 actionId;
}

interface ILOVE20Launch {
    function launchInfo(
        address tokenAddress
    ) external view returns (LaunchInfo memory);
    function tokenAddressBySymbol(
        string memory symbol
    ) external view returns (address);
    function stakeAddress() external view returns (address);
    function contribute(
        address tokenAddress,
        uint256 parentTokenAmount,
        address to
    ) external;

    function tokensCount() external view returns (uint256 count);
    function tokensAtIndex(
        uint256 index
    ) external view returns (address tokenAddress);

    function childTokensCount(
        address parentTokenAddress
    ) external view returns (uint256 count);

    function childTokensAtIndex(
        address parentTokenAddress,
        uint256 index
    ) external view returns (address tokenAddress);

    function launchingTokensCount() external view returns (uint256 count);

    function launchingTokensAtIndex(
        uint256 index
    ) external view returns (address tokenAddress);

    function launchedTokensCount() external view returns (uint256 count);

    function launchedTokensAtIndex(
        uint256 index
    ) external view returns (address tokenAddress);

    function launchingChildTokensCount(
        address parentTokenAddress
    ) external view returns (uint256 count);

    function launchingChildTokensAtIndex(
        address parentTokenAddress,
        uint256 index
    ) external view returns (address tokenAddress);

    function launchedChildTokensCount(
        address parentTokenAddress
    ) external view returns (uint256 count);

    function launchedChildTokensAtIndex(
        address parentTokenAddress,
        uint256 index
    ) external view returns (address tokenAddress);

    function participatedTokensCount(
        address account
    ) external view returns (uint256 count);

    function participatedTokensAtIndex(
        address account,
        uint256 index
    ) external view returns (address tokenAddress);
}

interface ILOVE20Stake {
    function govVotesNum(address tokenAddress) external view returns (uint256);
    function initialStakeRound(
        address tokenAddress
    ) external view returns (uint256);
    function stakeLiquidity(
        address tokenAddress,
        uint256 tokenAmountForLP,
        uint256 parentTokenAmountForLP,
        uint256 promisedWaitingPhases,
        address to
    ) external returns (uint256 govVotesAdded, uint256 slAmountAdded);
}

interface ILOVE20Submit {
    function actionInfo(
        address tokenAddress,
        uint256 actionId
    ) external view returns (ActionInfo memory);

    function actionsCount(address tokenAddress) external view returns (uint256);
    function actionsAtIndex(
        address tokenAddress,
        uint256 index
    ) external view returns (ActionInfo memory);

    function actionSubmitsCount(
        address tokenAddress,
        uint256 round
    ) external view returns (uint256);

    function actionSubmitsAtIndex(
        address tokenAddress,
        uint256 round,
        uint256 index
    ) external view returns (ActionSubmitInfo memory);
}

interface ILOVE20Vote {
    function votesNumByAccountByActionId(
        address tokenAddress,
        uint256 round,
        address account,
        uint256 actionId
    ) external view returns (uint256);

    function votesNumByActionId(
        address tokenAddress,
        uint256 round,
        uint256 actionId
    ) external view returns (uint256);

    function votesNumsByAccount(
        address tokenAddress,
        uint256 round,
        address account
    )
        external
        view
        returns (uint256[] memory actionIds, uint256[] memory votes);

    function votedActionIdsCount(
        address tokenAddress,
        uint256 round
    ) external view returns (uint256);

    function votedActionIdsAtIndex(
        address tokenAddress,
        uint256 round,
        uint256 index
    ) external view returns (uint256);

    function accountVotedActionIdsCount(
        address tokenAddress,
        uint256 round,
        address account
    ) external view returns (uint256);

    function accountVotedActionIdsAtIndex(
        address tokenAddress,
        uint256 round,
        address account,
        uint256 index
    ) external view returns (uint256);
}

interface ILOVE20Join {
    function currentRound() external view returns (uint256);

    function amountByActionId(
        address tokenAddress,
        uint256 actionId
    ) external view returns (uint256);

    function actionIdsByAccount(
        address tokenAddress,
        address account
    ) external view returns (uint256[] memory);

    function amountByActionIdByAccount(
        address tokenAddress,
        uint256 actionId,
        address account
    ) external view returns (uint256);

    function randomAccounts(
        address tokenAddress,
        uint256 round,
        uint256 actionId
    ) external view returns (address[] memory);

    function verificationInfo(
        address tokenAddress,
        address account,
        string memory verificationKey
    ) external view returns (string memory);

    function verificationInfoByRound(
        address tokenAddress,
        address account,
        uint256 actionId,
        string memory verificationKey,
        uint256 round
    ) external view returns (string memory);
}

interface ILOVE20Verify {
    function scoreByActionId(
        address tokenAddress,
        uint256 round,
        uint256 actionId
    ) external view returns (uint256);

    function scoreByActionIdByAccount(
        address tokenAddress,
        uint256 round,
        uint256 actionId,
        address account
    ) external view returns (uint256);

    function isActionIdWithReward(
        address tokenAddress,
        uint256 round,
        uint256 actionId
    ) external view returns (bool);
}

interface ILOVE20Mint {
    function currentRound() external view returns (uint256);

    function actionRewardByActionIdByAccount(
        address tokenAddress,
        uint256 round,
        uint256 actionId,
        address account
    ) external view returns (uint256 reward, bool isMinted);

    function govRewardByAccount(
        address tokenAddress,
        uint256 round,
        address account
    )
        external
        view
        returns (
            uint256 verifyReward,
            uint256 boostReward,
            uint256 burnReward,
            bool isMinted
        );

    function govRewardMintedByAccount(
        address tokenAddress,
        uint256 round,
        address account
    ) external view returns (uint256);

    function actionRewardMintedByAccount(
        address tokenAddress,
        uint256 round,
        uint256 actionId,
        address account
    ) external view returns (uint256);

    function rewardAvailable(
        address tokenAddress
    ) external view returns (uint256);
}

interface ILOVE20Token {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256);
    function parentTokenAddress() external view returns (address);
    function slAddress() external view returns (address);
    function stAddress() external view returns (address);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
}

interface ILOVE20SLToken {
    function uniswapV2Pair() external view returns (address);

    function tokenAmountsBySlAmount(
        uint256 slAmount
    ) external view returns (uint256 tokenAmount, uint256 parentTokenAmount);
}

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
}
