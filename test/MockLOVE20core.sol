// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "../src/interfaces/ILOVE20Core.sol";

// Mock ILOVE20Launch interface
contract MockILOVE20Launch is ILOVE20Launch {
    address public parentTokenAddress;
    address public stakeAddress;

    constructor(address _parentTokenAddress, address _stakeAddress) {
        parentTokenAddress = _parentTokenAddress;
        stakeAddress = _stakeAddress;
    }

    function launches(address) external view override returns (LaunchInfo memory launchInfo_) {
        return LaunchInfo({
            parentTokenAddress: parentTokenAddress, 
            parentTokenFundraisingGoal: 1000000,
            secondHalfMinBlocks: 5000,
            launchAmount: 500000,
            startBlock: 100,
            secondHalfStartBlock: 5100,
            hasEnded: false,
            participantCount: 100,
            totalContributed: 1000000,
            totalExtraRefunded: 50000
        });
    }

    function tokenAddressBySymbol(string memory symbol) external view override returns (address) {
        symbol;
        return address(parentTokenAddress);
    }
}

contract MockILOVE20Stake is ILOVE20Stake {
    function initialStakeRound(address tokenAddress) external pure override returns (uint256) {
        tokenAddress;
        return 42;
    }

    function govVotesNum(address tokenAddress) external pure override returns (uint256) {
        tokenAddress;
        return 100;
    }
}

// Mock ILOVE20Submit interface
contract MockILOVE20Submit is ILOVE20Submit {
    function actionInfo(address tokenAddress, uint256 actionId) external view override returns (ActionInfo memory) {
        string[] memory verificationKeys = new string[](2);
        verificationKeys[0] = "twitter";
        verificationKeys[1] = "github";
        
        string[] memory verificationInfoGuides = new string[](2);
        verificationInfoGuides[0] = "Please input your twitter username";
        verificationInfoGuides[1] = "Please input your github username";
        
        ActionInfo memory actionInfo_ = ActionInfo({
            head: ActionHead({id: actionId, author: address(this), createAtBlock: block.number}),
            body: ActionBody({
                maxStake: 1000, 
                maxRandomAccounts: 10, 
                whiteList: new address[](1),
                action: "test", 
                consensus: "test", 
                verificationRule: "test", 
                verificationKeys: verificationKeys,
                verificationInfoGuides: verificationInfoGuides
            })
        });
        actionInfo_.body.whiteList[0] = tokenAddress;
        return actionInfo_;
    }

    function actionInfosByIds(address tokenAddress, uint256[] calldata actionIds) external view override returns (ActionInfo[] memory) {
        ActionInfo[] memory actionInfos = new ActionInfo[](actionIds.length);
        for (uint256 i = 0; i < actionIds.length; i++) {
            actionInfos[i] = this.actionInfo(tokenAddress, actionIds[i]);
        }
        return actionInfos;
    }
}

// Mock ILOVE20Vote interface
contract MockILOVE20Vote is ILOVE20Vote {
    function votesNums(address, uint256)
        external
        pure
        override
        returns (uint256[] memory actionIds, uint256[] memory votes)
    {
        actionIds = new uint256[](2);
        votes = new uint256[](2);
        actionIds[0] = 1;
        votes[0] = 100;
        actionIds[1] = 2;
        votes[1] = 200;
    }
}

// Mock ILOVE20Join interface
contract MockILOVE20Join is ILOVE20Join {

    address internal _submitAddress;
    address internal _joinAddress;  

    constructor(address submitAddress_, address joinAddress_) {
        _submitAddress = submitAddress_;
        _joinAddress = joinAddress_;
    }

    function amountByActionId(address, uint256 actionId) external pure override returns (uint256) {
        return 1000 * actionId;
    }

    function actionIdsByAccount(address, address) external pure override returns (uint256[] memory) {
        uint256[] memory actionIds = new uint256[](1);
        actionIds[0] = 1;
        return actionIds;
    }

    function amountByActionIdByAccount(address, uint256 actionId, address)
        external
        pure
        override
        returns (uint256)
    {
        return 500 * actionId;
    }

    function randomAccounts(address, uint256, uint256) external pure override returns (address[] memory) {
        address[] memory accounts = new address[](2);
        accounts[0] = address(0x1);
        accounts[1] = address(0x2);
        return accounts;
    }

    function verificationInfo(address, address, string memory) external pure override returns (string memory) {
        return "Verified Information";
    }

    function verificationInfosByAccount(address tokenAddress, uint256 actionId, address account)
        external
        view
        returns (string[] memory verificationInfos)
    {
        ActionInfo memory actionInfo = ILOVE20Submit(_submitAddress).actionInfo(tokenAddress, actionId);
        verificationInfos = new string[](actionInfo.body.verificationKeys.length);
        for (uint256 i = 0; i < actionInfo.body.verificationKeys.length; i++) {
            verificationInfos[i] = ILOVE20Join(_joinAddress).verificationInfo(tokenAddress, account, actionInfo.body.verificationKeys[i]);
        }
        return verificationInfos;
    }
}

// Mock ILOVE20Verify interface
contract MockILOVE20Verify is ILOVE20Verify {

    function scoreByActionIdByAccount(address, uint256, uint256, address) external pure override returns (uint256) {
        return 50;
    }

    function isActionIdWithReward(address, uint256, uint256) external pure override returns (bool) {
        return true;
    }
}

// Mock ILOVE20Mint interface
contract MockILOVE20Mint is ILOVE20Mint {
    function currentRound() external pure override returns (uint256) {
        return 1;
    }

    function actionRewardByActionIdByAccount(address, uint256, uint256, address account)
        external
        pure
        override
        returns (uint256)
    {
        if (account == address(0x1)) {
            return 25;
        } else if (account == address(0x2)) {
            return 50;
        }
        return 0;
    }

    function govRewardByAccount(address, uint256, address) external pure override returns (uint256, uint256, uint256) {
        return (50, 50, 50);
    }

    function govRewardMintedByAccount(address, uint256, address) external pure override returns (uint256) {
        return 50;
    }
}

// Mock IERC20 interface
contract MockERC20 is LOVE20Token, ILOVE20SLToken, IUniswapV2Pair {
    string private _symbol;
    address private _uniswapV2Pair;

    constructor(string memory symbol_) {
        _symbol = symbol_;
        _uniswapV2Pair = address(this);
    }

    function name() external pure override returns (string memory) {
        return "TEST";
    }

    function decimals() external pure override returns (uint256) {
        return 18;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function slAddress() external view returns (address) {
        return address(this);
    }

    function stAddress() external view returns (address) {
        return address(this);
    }

    function totalSupply() external pure returns (uint256) {
        return 1000000000000000000000000;
    }

    function balanceOf(address account) external pure returns (uint256) {
        account;
        return 1000;
    }

    function allowance(address owner, address spender) external pure returns (uint256) {
        owner;
        spender;
        return 1000;
    }

    function uniswapV2Pair() external view override returns (address) {
        return _uniswapV2Pair;
    }

    // 实现 IUniswapV2Pair 接口的必要函数
    function getReserves() external pure returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) {
        return (0, 0, 0);
    }

    // IUniswapV2Pair 接口需要的其他函数
    function token0() external view returns (address) {
        return address(this);
    }

    function token1() external view returns (address) {
        return address(this);
    }

}