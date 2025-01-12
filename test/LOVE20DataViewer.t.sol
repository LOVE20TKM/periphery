// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "forge-std/Test.sol";
import "../src/LOVE20DataViewer.sol";

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
            parentTokenAddress: parentTokenAddress, // 这里使用构造函数中设置的 parentTokenAddress
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
        console.log("symbol@tokenAddressBySymbol", symbol);
        return address(parentTokenAddress);
    }
}

contract MockILOVE20Stake is ILOVE20Stake {
    function initialStakeRound(address tokenAddress) external pure override returns (uint256) {
        tokenAddress;
        return 42;
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
    function joinedAmountByActionId(address, uint256, uint256 actionId) external pure override returns (uint256) {
        return 1000 * actionId;
    }

    function stakedActionIdsByAccount(address, address) external pure override returns (uint256[] memory) {
        uint256[] memory actionIds = new uint256[](1);
        actionIds[0] = 1;
        return actionIds;
    }

    function lastJoinedRoundByAccountByActionId(address, address, uint256) external pure override returns (uint256) {
        return 1;
    }

    function stakedAmountByAccountByActionId(address, address, uint256 actionId)
        external
        pure
        override
        returns (uint256)
    {
        return 500 * actionId;
    }

    function verificationInfo(address, uint256, uint256, address) external pure override returns (string memory) {
        return "Verified Information";
    }
}

// Mock ILOVE20Verify interface
contract MockILOVE20Verify is ILOVE20Verify {
    function accountsForVerify(address, uint256, uint256) external pure override returns (address[] memory) {
        address[] memory accounts = new address[](2);
        accounts[0] = address(0x1);
        accounts[1] = address(0x2);
        return accounts;
    }

    function scoreByActionIdByAccount(address, uint256, uint256, address) external pure override returns (uint256) {
        return 50;
    }
}

// Mock ILOVE20Mint interface
contract MockILOVE20Mint is ILOVE20Mint {
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
contract MockERC20 is LOVE20Token {
    string private _symbol;

    constructor(string memory symbol_) {
        _symbol = symbol_;
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
}

contract LOVE20DataViewerTest is Test {
    LOVE20DataViewer viewer;
    address initSetter = address(this);

    MockILOVE20Launch mockLaunch;
    MockILOVE20Stake mockStake;
    MockILOVE20Vote mockVote;
    MockILOVE20Join mockJoin;
    MockILOVE20Verify mockVerify;
    MockILOVE20Mint mockMint;
    MockERC20 mockERC20;

    function setUp() public {
        // Deploy MockERC20 as parentToken
        mockERC20 = new MockERC20("TEST");
        mockStake = new MockILOVE20Stake();

        // Deploy MockILOVE20Launch with mockERC20's address
        mockLaunch = new MockILOVE20Launch(address(mockERC20), address(mockStake));

        // Deploy other mock contracts
        mockVote = new MockILOVE20Vote();
        mockJoin = new MockILOVE20Join();
        mockVerify = new MockILOVE20Verify();
        mockMint = new MockILOVE20Mint();

        // Deploy the contract under test
        viewer = new LOVE20DataViewer(initSetter);
    }

    // Test setInitSetter function
    function testSetInitSetter() public {
        address newSetter = address(0x123);
        viewer.setInitSetter(newSetter);
        assertEq(viewer.initSetter(), newSetter, "InitSetter should be updated");
    }

    // Test that only initSetter can call setInitSetter
    function testOnlyInitSetterCanSetInitSetter() public {
        address nonSetter = address(0x456);
        vm.prank(nonSetter);
        vm.expectRevert("msg.sender is not initSetter");
        viewer.setInitSetter(address(0x789));
    }

    // Test init function
    function testInitFunction() public {
        viewer.init(address(mockLaunch), address(mockVote), address(mockJoin), address(mockVerify), address(mockMint));

        assertEq(viewer.launchAddress(), address(mockLaunch), "launchAddress should be set correctly");
        assertEq(viewer.voteAddress(), address(mockVote), "voteAddress should be set correctly");
        assertEq(viewer.joinAddress(), address(mockJoin), "joinAddress should be set correctly");
        assertEq(viewer.verifyAddress(), address(mockVerify), "verifyAddress should be set correctly");
        assertEq(viewer.mintAddress(), address(mockMint), "mintAddress should be set correctly");
    }

    // Test joinableActions function
    function testJoinableActions() public {
        viewer.init(address(mockLaunch), address(mockVote), address(mockJoin), address(mockVerify), address(mockMint));

        JoinableAction[] memory actions = viewer.joinableActions(address(mockERC20), 1);
        assertEq(actions.length, 2, "Should return two JoinableActions");
        assertEq(actions[0].actionId, 1, "First actionId should be 1");
        assertEq(actions[0].votesNum, 100, "First votesNum should be 100");
        assertEq(actions[0].joinedAmount, 1000, "First joinedAmount should be 1000");
        assertEq(actions[1].actionId, 2, "Second actionId should be 2");
        assertEq(actions[1].votesNum, 200, "Second votesNum should be 200");
        assertEq(actions[1].joinedAmount, 2000, "Second joinedAmount should be 2000");
    }

    // Test joinedActions function
    function testJoinedActions() public {
        viewer.init(address(mockLaunch), address(mockVote), address(mockJoin), address(mockVerify), address(mockMint));

        JoinedAction[] memory actions = viewer.joinedActions(address(mockERC20), address(this));
        assertEq(actions.length, 1, "Should return one JoinedAction");
        assertEq(actions[0].actionId, 1, "actionId should be 1");
        assertEq(actions[0].lastJoinedRound, 1, "lastJoinedRound should be 1");
        assertEq(actions[0].stakedAmount, 500, "stakedAmount should be 500");
    }

    // Test verifiedAddressesByAction function
    function testVerifiedAddressesByAction() public {
        viewer.init(
            address(mockLaunch),
            address(mockVote),
            address(mockJoin),
            // address(0xDEF), // Removed randomAddress parameter
            address(mockVerify),
            address(mockMint)
        );

        VerifiedAddress[] memory verified = viewer.verifiedAddressesByAction(address(mockERC20), 1, 1);
        assertEq(verified.length, 2, "Should return two VerifiedAddresses");
        assertEq(verified[0].account, address(0x1), "First account should be 0x1");
        assertEq(verified[0].score, 50, "First score should be 50");
        assertEq(verified[0].reward, 25, "First reward should be 25");
        assertEq(verified[1].account, address(0x2), "Second account should be 0x2");
        assertEq(verified[1].score, 50, "Second score should be 50");
        assertEq(verified[1].reward, 50, "Second reward should be 50");
    }

    // Test govRewardsByAccountByRounds function
    function testGovRewardsByAccountByRounds() public {
        viewer.init(address(mockLaunch), address(mockVote), address(mockJoin), address(mockVerify), address(mockMint));

        GovReward[] memory rewards = viewer.govRewardsByAccountByRounds(address(mockERC20), address(this), 1, 2);

        assertEq(rewards.length, 2, "Should return two GovReward");
        assertEq(rewards[0].round, 1, "First round should be 1");
        assertEq(rewards[0].minted, 50, "First minted should be 50");
        assertEq(rewards[0].unminted, 100, "First unminted should be 100");
    }

    // Test verificationInfosByAction function
    function testVerificationInfosByAction() public {
        viewer.init(address(mockLaunch), address(mockVote), address(mockJoin), address(mockVerify), address(mockMint));

        (address[] memory accounts, string[] memory infos) = viewer.verificationInfosByAction(address(mockERC20), 1, 1);
        assertEq(accounts.length, 2, "Should return two accounts");
        assertEq(infos.length, 2, "Should return two infos");
        assertEq(accounts[0], address(0x1), "First account should be 0x1");
        assertEq(infos[0], "Verified Information", "First info should be 'Verified Information'");
        assertEq(accounts[1], address(0x2), "Second account should be 0x2");
        assertEq(infos[1], "Verified Information", "Second info should be 'Verified Information'");
    }

    // Test tokenDetail function
    function testTokenDetail() public {
        viewer.init(address(mockLaunch), address(mockVote), address(mockJoin), address(mockVerify), address(mockMint));

        (TokenInfo memory tokenInfo, LaunchInfo memory info) = viewer.tokenDetail(address(mockERC20));
        assertEq(tokenInfo.name, "TEST", "name should be 'TEST'");
        assertEq(tokenInfo.symbol, "TEST", "symbol should be 'TEST'");
        assertEq(tokenInfo.decimals, 18, "decimals should be 18");
        assertEq(tokenInfo.parentTokenSymbol, "TEST", "parentSymbol should be 'TEST'");
        assertNotEq(tokenInfo.slAddress, address(0), "slAddress should not be 0");
        assertNotEq(tokenInfo.stAddress, address(0), "stAddress should not be 0");
        assertEq(tokenInfo.initialStakeRound, 42, "initialStakeRound should be 42");
        assertEq(info.parentTokenAddress, address(mockERC20), "parentTokenAddress should be mockERC20's address");
        assertEq(info.parentTokenFundraisingGoal, 1000000, "parentTokenFundraisingGoal should be 1000000");
        assertEq(info.hasEnded, false, "hasEnded should be false");
    }

    // Test tokenDetailBySymbol function
    function testTokenDetailBySymbol() public {
        viewer.init(address(mockLaunch), address(mockVote), address(mockJoin), address(mockVerify), address(mockMint));
        (TokenInfo memory tokenInfo, LaunchInfo memory info) = viewer.tokenDetailBySymbol("TEST");
        assertEq(tokenInfo.symbol, "TEST", "symbol should be 'TEST'");
        assertEq(tokenInfo.name, "TEST", "name should be 'TEST'");
        assertEq(tokenInfo.decimals, 18, "decimals should be 18");
        assertEq(tokenInfo.parentTokenSymbol, "TEST", "parentSymbol should be 'TEST'");
        assertEq(tokenInfo.initialStakeRound, 42, "initialStakeRound should be 42");
        assertEq(info.parentTokenAddress, address(mockERC20), "parentTokenAddress should be mockERC20's address");
    }

    // Test tokenDetails function
    function testTokenDetails() public {
        viewer.init(
            address(mockLaunch),
            address(mockVote),
            address(mockJoin),
            // address(0xDEF), // Removed randomAddress parameter
            address(mockVerify),
            address(mockMint)
        );

        address[] memory tokenAddresses = new address[](2);
        tokenAddresses[0] = address(mockERC20);
        tokenAddresses[1] = address(mockERC20);

        (TokenInfo[] memory tokenInfos, LaunchInfo[] memory launchInfos) = viewer.tokenDetails(tokenAddresses);
        assertEq(tokenInfos.length, 2, "Should return two tokenInfos");
        assertEq(launchInfos.length, 2, "Should return two launchInfos");

        for (uint256 i = 0; i < tokenInfos.length; i++) {
            assertEq(tokenInfos[i].symbol, "TEST", "symbol should be 'TEST'");
            assertEq(tokenInfos[i].name, "TEST", "name should be 'TEST'");
            assertEq(tokenInfos[i].decimals, 18, "decimals should be 18");
            assertEq(tokenInfos[i].parentTokenSymbol, "TEST", "parentSymbol should be 'TEST'");
            assertEq(tokenInfos[i].initialStakeRound, 42, "initialStakeRound should be 42");
            assertEq(
                launchInfos[i].parentTokenAddress,
                address(mockERC20),
                "parentTokenAddress should be mockERC20's address"
            );
            // Continue adding other assertions...
        }
    }
}
