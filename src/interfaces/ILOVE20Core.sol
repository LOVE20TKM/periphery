// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

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

    function isActionIdWithReward(address tokenAddress, uint256 round, uint256 actionId)
        external
        view
        returns (bool);
}

interface ILOVE20Mint {
    function currentRound() external view returns (uint256);

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

    function rewardAvailable(
        address tokenAddress
    ) external view returns (uint256);
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

    function tokenAmountsBySlAmount(
        uint256 slAmount
    ) external view returns (uint256 tokenAmount, uint256 parentTokenAmount);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
}
