// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "forge-std/Test.sol";

import "../src/LOVE20DataViewer.sol";
import "./mock/MockLOVE20Launch.sol";
import "./mock/MockLOVE20Stake.sol";
import "./mock/MockLOVE20Submit.sol";
import "./mock/MockLOVE20Vote.sol";
import "./mock/MockLOVE20Join.sol";
import "./mock/MockLOVE20Verify.sol";
import "./mock/MockLOVE20Mint.sol";
import "./mock/MockTokens.sol";

contract LOVE20DataViewerTest is Test {
    LOVE20DataViewer viewer;

    MockILOVE20Launch mockLaunch;
    MockILOVE20Stake mockStake;
    MockILOVE20Submit mockSubmit;
    MockILOVE20Vote mockVote;
    MockILOVE20Join mockJoin;
    MockILOVE20Verify mockVerify;
    MockILOVE20Mint mockMint;
    MockLOVE20Token mockERC20;

    function setUp() public {
        // Deploy MockLOVE20Token as parentToken
        mockERC20 = new MockLOVE20Token("TEST");
        mockStake = new MockILOVE20Stake();
        mockSubmit = new MockILOVE20Submit();
        // Deploy MockILOVE20Launch with mockERC20's address
        mockLaunch = new MockILOVE20Launch(
            address(mockERC20),
            address(mockStake)
        );

        // Deploy other mock contracts
        mockVote = new MockILOVE20Vote();
        mockJoin = new MockILOVE20Join(address(mockSubmit), address(mockJoin));
        mockVerify = new MockILOVE20Verify();
        mockMint = new MockILOVE20Mint();

        // Deploy the contract under test
        viewer = new LOVE20DataViewer();
        viewer.init(
            address(mockLaunch),
            address(mockStake),
            address(mockSubmit),
            address(mockVote),
            address(mockJoin),
            address(mockVerify),
            address(mockMint)
        );
    }

    // Test init function
    function testInitFunction() public view {
        assertEq(
            viewer.launchAddress(),
            address(mockLaunch),
            "launchAddress should be set correctly"
        );
        assertEq(
            viewer.stakeAddress(),
            address(mockStake),
            "stakeAddress should be set correctly"
        );
        assertEq(
            viewer.submitAddress(),
            address(mockSubmit),
            "submitAddress should be set correctly"
        );
        assertEq(
            viewer.voteAddress(),
            address(mockVote),
            "voteAddress should be set correctly"
        );
        assertEq(
            viewer.joinAddress(),
            address(mockJoin),
            "joinAddress should be set correctly"
        );
        assertEq(
            viewer.verifyAddress(),
            address(mockVerify),
            "verifyAddress should be set correctly"
        );
        assertEq(
            viewer.mintAddress(),
            address(mockMint),
            "mintAddress should be set correctly"
        );
    }

    // Test tokenDetail function
    function testTokenDetail() public view {
        (TokenInfo memory tokenInfo, LaunchInfo memory info) = viewer
            .tokenDetail(address(mockERC20));
        assertEq(tokenInfo.name, "TEST", "name should be 'TEST'");
        assertEq(tokenInfo.symbol, "TEST", "symbol should be 'TEST'");
        assertEq(tokenInfo.decimals, 18, "decimals should be 18");
        assertEq(
            tokenInfo.parentTokenSymbol,
            "TEST",
            "parentSymbol should be 'TEST'"
        );
        assertNotEq(
            tokenInfo.slAddress,
            address(0),
            "slAddress should not be 0"
        );
        assertNotEq(
            tokenInfo.stAddress,
            address(0),
            "stAddress should not be 0"
        );
        assertEq(
            tokenInfo.initialStakeRound,
            42,
            "initialStakeRound should be 42"
        );
        assertEq(
            info.parentTokenAddress,
            address(mockERC20),
            "parentTokenAddress should be mockERC20's address"
        );
        assertEq(
            info.parentTokenFundraisingGoal,
            1000000,
            "parentTokenFundraisingGoal should be 1000000"
        );
        assertEq(info.hasEnded, false, "hasEnded should be false");
    }

    // Test tokenDetailBySymbol function
    function testTokenDetailBySymbol() public view {
        (TokenInfo memory tokenInfo, LaunchInfo memory info) = viewer
            .tokenDetailBySymbol("TEST");
        assertEq(tokenInfo.symbol, "TEST", "symbol should be 'TEST'");
        assertEq(tokenInfo.name, "TEST", "name should be 'TEST'");
        assertEq(tokenInfo.decimals, 18, "decimals should be 18");
        assertEq(
            tokenInfo.parentTokenSymbol,
            "TEST",
            "parentSymbol should be 'TEST'"
        );
        assertEq(
            tokenInfo.initialStakeRound,
            42,
            "initialStakeRound should be 42"
        );
        assertEq(
            info.parentTokenAddress,
            address(mockERC20),
            "parentTokenAddress should be mockERC20's address"
        );
    }

    // Test tokenDetails function
    function testTokenDetails() public view {
        address[] memory tokenAddresses = new address[](2);
        tokenAddresses[0] = address(mockERC20);
        tokenAddresses[1] = address(mockERC20);

        (
            TokenInfo[] memory tokenInfos,
            LaunchInfo[] memory launchInfos
        ) = viewer.tokenDetails(tokenAddresses);
        assertEq(tokenInfos.length, 2, "Should return two tokenInfos");
        assertEq(launchInfos.length, 2, "Should return two launchInfos");

        for (uint256 i = 0; i < tokenInfos.length; i++) {
            assertEq(tokenInfos[i].symbol, "TEST", "symbol should be 'TEST'");
            assertEq(tokenInfos[i].name, "TEST", "name should be 'TEST'");
            assertEq(tokenInfos[i].decimals, 18, "decimals should be 18");
            assertEq(
                tokenInfos[i].parentTokenSymbol,
                "TEST",
                "parentSymbol should be 'TEST'"
            );
            assertEq(
                tokenInfos[i].initialStakeRound,
                42,
                "initialStakeRound should be 42"
            );
            assertEq(
                launchInfos[i].parentTokenAddress,
                address(mockERC20),
                "parentTokenAddress should be mockERC20's address"
            );
            // Continue adding other assertions...
        }
    }

    // Test tokenPairInfoWithAccount function
    function tokenPairInfoWithAccount() public view {
        PairInfoWithAccount memory pairInfo = viewer.tokenPairInfoWithAccount(
            address(this),
            address(mockERC20)
        );

        assertEq(
            pairInfo.pairAddress,
            address(mockERC20),
            "Incorrect pair address"
        );
        assertEq(pairInfo.balanceOfToken, 1000, "Incorrect token balance");
        assertEq(
            pairInfo.balanceOfParentToken,
            1000,
            "Incorrect parent token balance"
        );
        assertEq(pairInfo.allowanceOfToken, 1000, "Incorrect token allowance");
        assertEq(
            pairInfo.allowanceOfParentToken,
            1000,
            "Incorrect parent token allowance"
        );
        assertEq(pairInfo.pairReserveToken, 0, "Incorrect pair reserve token");
        assertEq(
            pairInfo.pairReserveParentToken,
            0,
            "Incorrect pair reserve parent token"
        );
    }

    // Test joinedActions function
    function testJoinedActions() public view {
        JoinedAction[] memory actions = viewer.joinedActions(
            address(mockERC20),
            address(this)
        );
        assertEq(actions.length, 1, "Should return one JoinedAction");
        assertEq(actions[0].action.head.id, 1, "actionId should be 1");
        assertEq(
            actions[0].joinedAmountOfAccount,
            500,
            "joinedAmountOfAccount should be 500"
        );
        assertEq(actions[0].hasReward, true, "hasReward should be true");
    }

    // Test joinableActions function
    function testJoinableActions() public view {
        JoinableAction[] memory joinableActions = viewer.joinableActions(
            address(mockERC20),
            1,
            address(this)
        );

        assertEq(
            joinableActions[0].joinedAmountOfAccount,
            500,
            "joinedAmountOfAccount should be 500"
        );
        assertEq(
            joinableActions.length,
            3,
            "Should return three JoinableActions"
        );
        assertEq(joinableActions[0].action.head.id, 1, "actionId should be 1");
        assertEq(joinableActions[0].votesNum, 100, "votesNum should be 100");
        assertEq(
            joinableActions[0].joinedAmount,
            1000,
            "joinedAmount should be 1000"
        );
        assertEq(
            joinableActions[0].hasReward,
            true,
            "First action hasReward should be true"
        );
        assertEq(joinableActions[1].action.head.id, 1, "actionId should be 1");
        assertEq(joinableActions[1].votesNum, 100, "votesNum should be 100");
        assertEq(
            joinableActions[1].joinedAmount,
            1000,
            "joinedAmount should be 1000"
        );
        assertEq(
            joinableActions[1].hasReward,
            true,
            "Second action hasReward should be true"
        );
        assertEq(joinableActions[2].action.head.id, 1, "actionId should be 1");
        assertEq(joinableActions[2].votesNum, 100, "votesNum should be 100");
        assertEq(
            joinableActions[2].joinedAmount,
            1000,
            "joinedAmount should be 1000"
        );
        assertEq(
            joinableActions[2].hasReward,
            true,
            "Third action hasReward should be true"
        );
    }

    // test verifingActions function
    function testVerifingActions() public view {
        VerifyingAction[] memory actions = viewer.verifyingActions(
            address(mockERC20),
            1,
            address(this)
        );

        // Verify array length
        assertEq(actions.length, 3, "Should return three VerifyingActions");

        // Verify first Action
        assertEq(actions[0].action.head.id, 1, "First action id should be 1");
        assertEq(actions[0].votesNum, 100, "First action votes should be 100");
        assertEq(
            actions[0].verificationScore,
            50,
            "First action verification score should be 50"
        );
        assertEq(
            actions[0].myVotesNum,
            100,
            "My votes for first action should be 100"
        );
        assertEq(
            actions[0].myVerificationScore,
            50,
            "My verification score for first action should be 50"
        );

        // Verify second Action
        assertEq(actions[1].action.head.id, 1, "Second action id should be 1");
        assertEq(actions[1].votesNum, 100, "Second action votes should be 100");
        assertEq(
            actions[1].verificationScore,
            50,
            "Second action verification score should be 50"
        );
        assertEq(
            actions[1].myVotesNum,
            100,
            "My votes for second action should be 100"
        );
        assertEq(
            actions[1].myVerificationScore,
            50,
            "My verification score for second action should be 50"
        );

        // Verify third Action
        assertEq(actions[2].action.head.id, 1, "Third action id should be 1");
        assertEq(actions[2].votesNum, 100, "Third action votes should be 100");
        assertEq(
            actions[2].verificationScore,
            50,
            "Third action verification score should be 50"
        );
        assertEq(
            actions[2].myVotesNum,
            100,
            "My votes for third action should be 100"
        );
        assertEq(
            actions[2].myVerificationScore,
            50,
            "My verification score for third action should be 50"
        );
    }

    // Test verifyingActionsByAccount function
    function testVerifingActionsByAccount() public view {
        MyVerifyingAction[] memory myActions = viewer.verifyingActionsByAccount(
            address(mockERC20),
            1,
            address(this)
        );

        // Verify array length
        assertEq(myActions.length, 2, "Should return two MyVerifyingActions");

        // Verify first Action
        assertEq(myActions[0].action.head.id, 1, "First action id should be 1");
        assertEq(
            myActions[0].myVotesNum,
            100,
            "My votes for first action should be 100"
        );
        assertEq(
            myActions[0].totalVotesNum,
            100,
            "Total votes for first action should be 100"
        );
        assertEq(
            myActions[0].myVerificationScore,
            50,
            "My verification score for first action should be 50"
        );

        // Verify second Action
        assertEq(
            myActions[1].action.head.id,
            2,
            "Second action id should be 2"
        );
        assertEq(
            myActions[1].myVotesNum,
            200,
            "My votes for second action should be 200"
        );
        assertEq(
            myActions[1].totalVotesNum,
            100,
            "Total votes for second action should be 100"
        );
        assertEq(
            myActions[1].myVerificationScore,
            50,
            "My verification score for second action should be 50"
        );
    }

    // Test verifiedAddressesByAction function
    function testVerifiedAddressesByAction() public view {
        VerifiedAddress[] memory verified = viewer.verifiedAddressesByAction(
            address(mockERC20),
            1,
            1
        );
        assertEq(verified.length, 2, "Should return two VerifiedAddresses");
        assertEq(
            verified[0].account,
            address(0x1),
            "First account should be 0x1"
        );
        assertEq(verified[0].score, 50, "First score should be 50");
        assertEq(verified[0].reward, 25, "First reward should be 25");
        assertEq(verified[0].isMinted, true, "First isMinted should be true");
        assertEq(
            verified[1].account,
            address(0x2),
            "Second account should be 0x2"
        );
        assertEq(verified[1].score, 50, "Second score should be 50");
        assertEq(verified[1].reward, 50, "Second reward should be 50");
        assertEq(
            verified[1].isMinted,
            false,
            "Second isMinted should be false"
        );
    }

    // Test verificationInfosByAction function
    function testVerificationInfosByAction() public view {
        VerificationInfo[] memory verificationInfos = viewer
            .verificationInfosByAction(address(mockERC20), 1, 1);
        assertEq(verificationInfos.length, 2, "Should return two accounts");
        assertEq(
            verificationInfos[0].account,
            address(0x1),
            "First account should be 0x1"
        );
        assertEq(
            verificationInfos[0].infos[0],
            "Verified Information",
            "First info should be 'Verified Information'"
        );
        assertEq(
            verificationInfos[1].account,
            address(0x2),
            "Second account should be 0x2"
        );
        assertEq(
            verificationInfos[1].infos[0],
            "Verified Information",
            "Second info should be 'Verified Information'"
        );
    }

    // Test verificationInfosByAccount function
    function testVerificationInfosByAccount() public view {
        (
            string[] memory verificationKeys,
            string[] memory verificationInfos
        ) = viewer.verificationInfosByAccount(
                address(mockERC20),
                1,
                address(0x1)
            );
        assertEq(verificationKeys.length, 2, "Should return two accounts");
        assertEq(
            verificationKeys[0],
            "twitter",
            "First info should be 'Verified Information'"
        );
        assertEq(
            verificationKeys[1],
            "github",
            "Second info should be 'Verified Information'"
        );
        assertEq(
            verificationInfos[0],
            "Verified Information",
            "First info should be 'Verified Information'"
        );
        assertEq(
            verificationInfos[1],
            "Verified Information",
            "Second info should be 'Verified Information'"
        );
    }

    // Test govData function
    function testGovData() public view {
        GovData memory govData = viewer.govData(address(mockERC20));
        assertEq(govData.govVotes, 100, "govVotes should be 100");
        assertEq(
            govData.slAmount,
            1000000000000000000000000,
            "slAmount should be 1000000000000000000000000"
        );
        assertEq(
            govData.stAmount,
            1000000000000000000000000,
            "stAmount should be 1000000000000000000000000"
        );
        assertEq(
            govData.tokenAmountForSl,
            1000000000000000000000000,
            "tokenAmountForSl should be 1000000000000000000000000"
        );
        assertEq(
            govData.parentTokenAmountForSl,
            1000000000000000000000000,
            "parentTokenAmountForSl should be 1000000000000000000000000"
        );
        assertEq(govData.rewardAvailable, 50, "rewardAvailable should be 50");
    }

    // Test govRewardsByAccountByRounds function
    function testGovRewardsByAccountByRounds() public view {
        RewardInfo[] memory rewards = viewer.govRewardsByAccountByRounds(
            address(mockERC20),
            address(this),
            1,
            2
        );

        assertEq(rewards.length, 2, "Should return two RewardInfo");
        assertEq(rewards[0].round, 1, "First round should be 1");
        assertEq(rewards[0].reward, 100, "First reward should be 100");
        assertEq(rewards[0].isMinted, true, "First isMinted should be true");
        assertEq(rewards[1].round, 2, "Second round should be 2");
        assertEq(rewards[1].reward, 100, "Second reward should be 100");
        assertEq(rewards[1].isMinted, true, "Second isMinted should be true");
    }

    function testActionRewardRoundsByAccount() public view {
        // Test case 1: Valid actionId, roundEnd is greater than currentRound
        uint256 actionId = 2;
        uint256 roundStart = 1;
        uint256 roundEnd = 2;
        RewardInfo[] memory rewards = viewer
            .actionRewardsByAccountByActionIdByRounds(
                address(mockERC20),
                address(0x1),
                actionId,
                roundStart,
                roundEnd
            );
        assertEq(rewards.length, 2, "Should return two rewards");
        assertEq(rewards[0].reward, 25, "First reward should be 25");
        assertEq(rewards[0].isMinted, true, "First isMinted should be true");
        assertEq(rewards[1].reward, 25, "Second reward should be 25");
        assertEq(rewards[1].isMinted, true, "Second isMinted should be false");

        // Test case 2: Valid actionId, roundEnd is equal to currentRound
        roundStart = 0;
        roundEnd = 1;
        rewards = viewer.actionRewardsByAccountByActionIdByRounds(
            address(mockERC20),
            address(0x2),
            actionId,
            roundStart,
            roundEnd
        );
        assertEq(rewards.length, 2, "Should return two rewards");
        assertEq(rewards[0].reward, 50, "First reward should be 25");
        assertEq(rewards[0].isMinted, false, "First isMinted should be true");
        assertEq(rewards[1].reward, 50, "Second reward should be 50");
        assertEq(rewards[1].isMinted, false, "Second isMinted should be false");
    }

    // Test tokensByPage function
    function testTokensByPage() public view {
        // 测试正常范围
        address[] memory tokens = viewer.tokensByPage(0, 1);
        assertEq(tokens.length, 2, "Should return two tokens");
        assertEq(
            tokens[0],
            address(mockERC20),
            "First token should be mockERC20"
        );
        assertEq(
            tokens[1],
            address(mockERC20),
            "Second token should be mockERC20"
        );

        // 测试单个 token
        tokens = viewer.tokensByPage(0, 0);
        assertEq(tokens.length, 1, "Should return one token");
        assertEq(tokens[0], address(mockERC20), "Token should be mockERC20");

        // 测试 end 超出范围的情况
        tokens = viewer.tokensByPage(0, 10);
        assertEq(
            tokens.length,
            2,
            "Should return two tokens when end exceeds range"
        );
    }

    // Test tokensByPage edge cases
    function testTokensByPageEdgeCases() public {
        // 测试 start > end 的情况
        vm.expectRevert("Invalid range");
        viewer.tokensByPage(2, 1);

        // 测试 start 超出范围的情况
        vm.expectRevert("Out of range");
        viewer.tokensByPage(10, 20);
    }

    // Test childTokensByPage function
    function testChildTokensByPage() public {
        address[] memory tokens = viewer.childTokensByPage(
            address(mockERC20),
            0,
            1
        );
        assertEq(tokens.length, 2, "Should return two child tokens");
        assertEq(
            tokens[0],
            address(mockERC20),
            "First child token should be mockERC20"
        );
        assertEq(
            tokens[1],
            address(mockERC20),
            "Second child token should be mockERC20"
        );

        // 测试单个 token
        tokens = viewer.childTokensByPage(address(mockERC20), 1, 1);
        assertEq(tokens.length, 1, "Should return one child token");
        assertEq(
            tokens[0],
            address(mockERC20),
            "Child token should be mockERC20"
        );

        // 测试边界情况
        vm.expectRevert("Invalid range");
        viewer.childTokensByPage(address(mockERC20), 2, 1);

        vm.expectRevert("Out of range");
        viewer.childTokensByPage(address(mockERC20), 10, 20);
    }

    // Test launchingTokensByPage function
    function testLaunchingTokensByPage() public {
        address[] memory tokens = viewer.launchingTokensByPage(0, 0);
        assertEq(tokens.length, 1, "Should return one launching token");
        assertEq(
            tokens[0],
            address(mockERC20),
            "Launching token should be mockERC20"
        );

        // 测试 end 超出范围的情况
        tokens = viewer.launchingTokensByPage(0, 10);
        assertEq(
            tokens.length,
            1,
            "Should return one launching token when end exceeds range"
        );

        // 测试边界情况
        vm.expectRevert("Invalid range");
        viewer.launchingTokensByPage(2, 1);

        vm.expectRevert("Out of range");
        viewer.launchingTokensByPage(10, 20);
    }

    // Test launchedTokensByPage function
    function testLaunchedTokensByPage() public {
        address[] memory tokens = viewer.launchedTokensByPage(0, 0);
        assertEq(tokens.length, 1, "Should return one launched token");
        assertEq(
            tokens[0],
            address(mockERC20),
            "Launched token should be mockERC20"
        );

        // 测试 end 超出范围的情况
        tokens = viewer.launchedTokensByPage(0, 10);
        assertEq(
            tokens.length,
            1,
            "Should return one launched token when end exceeds range"
        );

        // 测试边界情况
        vm.expectRevert("Invalid range");
        viewer.launchedTokensByPage(2, 1);

        vm.expectRevert("Out of range");
        viewer.launchedTokensByPage(10, 20);
    }

    // Test launchingChildTokensByPage function
    function testLaunchingChildTokensByPage() public {
        address[] memory tokens = viewer.launchingChildTokensByPage(
            address(mockERC20),
            0,
            0
        );
        assertEq(tokens.length, 1, "Should return one launching child token");
        assertEq(
            tokens[0],
            address(mockERC20),
            "Launching child token should be mockERC20"
        );

        // 测试 end 超出范围的情况
        tokens = viewer.launchingChildTokensByPage(address(mockERC20), 0, 10);
        assertEq(
            tokens.length,
            1,
            "Should return one launching child token when end exceeds range"
        );

        // 测试边界情况
        vm.expectRevert("Invalid range");
        viewer.launchingChildTokensByPage(address(mockERC20), 2, 1);

        vm.expectRevert("Out of range");
        viewer.launchingChildTokensByPage(address(mockERC20), 10, 20);
    }

    // Test launchedChildTokensByPage function
    function testLaunchedChildTokensByPage() public {
        address[] memory tokens = viewer.launchedChildTokensByPage(
            address(mockERC20),
            0,
            0
        );
        assertEq(tokens.length, 1, "Should return one launched child token");
        assertEq(
            tokens[0],
            address(mockERC20),
            "Launched child token should be mockERC20"
        );

        // 测试 end 超出范围的情况
        tokens = viewer.launchedChildTokensByPage(address(mockERC20), 0, 10);
        assertEq(
            tokens.length,
            1,
            "Should return one launched child token when end exceeds range"
        );

        // 测试边界情况
        vm.expectRevert("Invalid range");
        viewer.launchedChildTokensByPage(address(mockERC20), 2, 1);

        vm.expectRevert("Out of range");
        viewer.launchedChildTokensByPage(address(mockERC20), 10, 20);
    }

    // Test participatedTokensByPage function
    function testParticipatedTokensByPage() public {
        address[] memory tokens = viewer.participatedTokensByPage(
            address(this),
            0,
            0
        );
        assertEq(tokens.length, 1, "Should return one participated token");
        assertEq(
            tokens[0],
            address(mockERC20),
            "Participated token should be mockERC20"
        );

        // 测试 end 超出范围的情况
        tokens = viewer.participatedTokensByPage(address(this), 0, 10);
        assertEq(
            tokens.length,
            1,
            "Should return one participated token when end exceeds range"
        );

        // 测试边界情况
        vm.expectRevert("Invalid range");
        viewer.participatedTokensByPage(address(this), 2, 1);

        vm.expectRevert("Out of range");
        viewer.participatedTokensByPage(address(this), 10, 20);
    }

    // Test actionSubmits function
    function testActionSubmits() public view {
        ActionSubmitInfo[] memory submits = viewer.actionSubmits(
            address(mockERC20),
            1
        );

        assertEq(submits.length, 2, "Should return two ActionSubmitInfo");

        // 验证第一个提交信息
        assertEq(submits[0].actionId, 0, "First submit actionId should be 0");
        assertEq(
            submits[0].submitter,
            address(mockSubmit),
            "First submitter should be mockSubmit address"
        );

        // 验证第二个提交信息
        assertEq(submits[1].actionId, 1, "Second submit actionId should be 1");
        assertEq(
            submits[1].submitter,
            address(mockSubmit),
            "Second submitter should be mockSubmit address"
        );
    }

    // Test actionInfosByIds function
    function testActionInfosByIds() public view {
        uint256[] memory actionIds = new uint256[](2);
        actionIds[0] = 1;
        actionIds[1] = 2;

        ActionInfo[] memory actionInfos = viewer.actionInfosByIds(
            address(mockERC20),
            actionIds
        );

        assertEq(actionInfos.length, 2, "Should return two ActionInfo");

        // 验证第一个 ActionInfo
        assertEq(actionInfos[0].head.id, 1, "First action id should be 1");
        assertEq(
            actionInfos[0].head.author,
            address(mockSubmit),
            "First action author should be mockSubmit"
        );
        assertEq(
            actionInfos[0].body.title,
            "test",
            "First action title should be 'test'"
        );
        assertEq(
            actionInfos[0].body.minStake,
            10,
            "First action minStake should be 10"
        );
        assertEq(
            actionInfos[0].body.verificationKeys.length,
            2,
            "First action should have 2 verification keys"
        );
        assertEq(
            actionInfos[0].body.verificationKeys[0],
            "twitter",
            "First verification key should be 'twitter'"
        );

        // 验证第二个 ActionInfo
        assertEq(actionInfos[1].head.id, 2, "Second action id should be 2");
        assertEq(
            actionInfos[1].head.author,
            address(mockSubmit),
            "Second action author should be mockSubmit"
        );
        assertEq(
            actionInfos[1].body.title,
            "test",
            "Second action title should be 'test'"
        );
    }

    // Test actionInfosByIds with empty array
    function testActionInfosByIdsEmpty() public view {
        uint256[] memory actionIds = new uint256[](0);
        ActionInfo[] memory actionInfos = viewer.actionInfosByIds(
            address(mockERC20),
            actionIds
        );

        assertEq(actionInfos.length, 0, "Should return empty array");
    }

    // Test actionInfosByPage function
    function testActionInfosByPage() public view {
        // 测试正常范围查询
        ActionInfo[] memory actionInfos = viewer.actionInfosByPage(
            address(mockERC20),
            0,
            2
        );
        assertEq(actionInfos.length, 3, "Should return three ActionInfo");

        // 验证返回的 action 信息
        assertEq(actionInfos[0].head.id, 0, "First action id should be 0");
        assertEq(actionInfos[1].head.id, 1, "Second action id should be 1");
        assertEq(actionInfos[2].head.id, 2, "Third action id should be 2");

        // 测试单个 action
        actionInfos = viewer.actionInfosByPage(address(mockERC20), 1, 1);
        assertEq(actionInfos.length, 1, "Should return one ActionInfo");
        assertEq(actionInfos[0].head.id, 1, "Action id should be 1");

        // 测试 end 超出范围的情况
        actionInfos = viewer.actionInfosByPage(address(mockERC20), 0, 10);
        assertEq(
            actionInfos.length,
            3,
            "Should return three ActionInfo when end exceeds range"
        );
    }

    // Test actionInfosByPage edge cases
    function testActionInfosByPageEdgeCases() public {
        // 测试 start > end 的情况
        vm.expectRevert("Invalid range");
        viewer.actionInfosByPage(address(mockERC20), 2, 1);

        // 测试 start 超出范围的情况
        vm.expectRevert("Out of range");
        viewer.actionInfosByPage(address(mockERC20), 10, 20);
    }

    // Test votesNums function
    function testVotesNums() public view {
        (uint256[] memory actionIds, uint256[] memory votes) = viewer.votesNums(
            address(mockERC20),
            1
        );

        assertEq(actionIds.length, 3, "Should return three actionIds");
        assertEq(votes.length, 3, "Should return three votes");

        // 验证 actionIds (MockILOVE20Vote.votedActionIdsAtIndex 总是返回 1)
        assertEq(actionIds[0], 1, "First actionId should be 1");
        assertEq(actionIds[1], 1, "Second actionId should be 1");
        assertEq(actionIds[2], 1, "Third actionId should be 1");

        // 验证 votes (MockILOVE20Vote.votesNumByActionId 总是返回 100)
        assertEq(votes[0], 100, "First votes should be 100");
        assertEq(votes[1], 100, "Second votes should be 100");
        assertEq(votes[2], 100, "Third votes should be 100");
    }

    // Test votingActions function
    function testVotingActions() public view {
        address tokenAddress = address(mockERC20);
        uint256 round = 1;
        address account = address(0x123);

        VotingAction[] memory actions = viewer.votingActions(
            tokenAddress,
            round,
            account
        );

        // Verify returned array length
        assertEq(actions.length, 2, "Should return 2 voting actions");

        // Verify first voting action data
        assertEq(actions[0].action.head.id, 0, "First action ID should be 0");
        assertEq(
            actions[0].action.head.author,
            address(mockSubmit),
            "First action author should be mockSubmit address"
        );
        assertEq(
            actions[0].action.head.createAtBlock,
            block.number,
            "First action create block should be current block"
        );
        assertEq(
            actions[0].action.body.minStake,
            10,
            "First action min stake should be 10"
        );
        assertEq(
            actions[0].action.body.maxRandomAccounts,
            10,
            "First action max random accounts should be 10"
        );
        assertEq(
            actions[0].action.body.whiteListAddress,
            tokenAddress,
            "First action whitelist address should be tokenAddress"
        );
        assertEq(
            actions[0].action.body.title,
            "test",
            "First action title should be 'test'"
        );
        assertEq(
            actions[0].action.body.verificationRule,
            "test",
            "First action verification rule should be 'test'"
        );
        assertEq(
            actions[0].submitter,
            address(mockSubmit),
            "First action submitter should be mockSubmit address"
        );
        assertEq(
            actions[0].votesNum,
            100,
            "First action total votes should be 100"
        );
        assertEq(
            actions[0].myVotesNum,
            100,
            "First action my votes should be 100"
        );

        // Verify second voting action data
        assertEq(actions[1].action.head.id, 1, "Second action ID should be 1");
        assertEq(
            actions[1].action.head.author,
            address(mockSubmit),
            "Second action author should be mockSubmit address"
        );
        assertEq(
            actions[1].action.head.createAtBlock,
            block.number,
            "Second action create block should be current block"
        );
        assertEq(
            actions[1].action.body.minStake,
            10,
            "Second action min stake should be 10"
        );
        assertEq(
            actions[1].action.body.maxRandomAccounts,
            10,
            "Second action max random accounts should be 10"
        );
        assertEq(
            actions[1].action.body.whiteListAddress,
            tokenAddress,
            "Second action whitelist address should be tokenAddress"
        );
        assertEq(
            actions[1].action.body.title,
            "test",
            "Second action title should be 'test'"
        );
        assertEq(
            actions[1].action.body.verificationRule,
            "test",
            "Second action verification rule should be 'test'"
        );
        assertEq(
            actions[1].submitter,
            address(mockSubmit),
            "Second action submitter should be mockSubmit address"
        );
        assertEq(
            actions[1].votesNum,
            100,
            "Second action total votes should be 100"
        );
        assertEq(
            actions[1].myVotesNum,
            100,
            "Second action my votes should be 100"
        );

        // Verify verification keys array
        assertEq(
            actions[0].action.body.verificationKeys.length,
            2,
            "First action verification keys array length should be 2"
        );
        assertEq(
            actions[0].action.body.verificationKeys[0],
            "twitter",
            "First verification key should be 'twitter'"
        );
        assertEq(
            actions[0].action.body.verificationKeys[1],
            "github",
            "Second verification key should be 'github'"
        );

        // Verify verification info guides array
        assertEq(
            actions[0].action.body.verificationInfoGuides.length,
            2,
            "First action verification info guides array length should be 2"
        );
        assertEq(
            actions[0].action.body.verificationInfoGuides[0],
            "Please input your twitter username",
            "First verification info guide should be twitter guide"
        );
        assertEq(
            actions[0].action.body.verificationInfoGuides[1],
            "Please input your github username",
            "Second verification info guide should be github guide"
        );
    }

    // Test votingActions with different account
    function testVotingActionsWithDifferentAccount() public view {
        address tokenAddress = address(mockERC20);
        uint256 round = 1;
        address account1 = address(0x123);
        address account2 = address(0x456);

        VotingAction[] memory actions1 = viewer.votingActions(
            tokenAddress,
            round,
            account1
        );
        VotingAction[] memory actions2 = viewer.votingActions(
            tokenAddress,
            round,
            account2
        );

        // Verify both accounts return same array length
        assertEq(
            actions1.length,
            actions2.length,
            "Different accounts should return same array length"
        );

        // Verify action info is same, but my votes may differ
        for (uint256 i = 0; i < actions1.length; i++) {
            assertEq(
                actions1[i].action.head.id,
                actions2[i].action.head.id,
                "Different accounts should have same action ID"
            );
            assertEq(
                actions1[i].action.head.author,
                actions2[i].action.head.author,
                "Different accounts should have same action author"
            );
            assertEq(
                actions1[i].action.body.title,
                actions2[i].action.body.title,
                "Different accounts should have same action title"
            );
            assertEq(
                actions1[i].votesNum,
                actions2[i].votesNum,
                "Different accounts should have same total votes"
            );
            // myVotesNum may differ depending on specific account voting
        }
    }

    // Test votingActions with large number of submits
    function testVotingActionsWithLargeSubmits() public view {
        address tokenAddress = address(mockERC20);
        uint256 round = 1;
        address account = address(0x123);

        // Test with large number of submits (mock returns 2, which is reasonable test range)
        VotingAction[] memory actions = viewer.votingActions(
            tokenAddress,
            round,
            account
        );

        // Verify array length
        assertEq(
            actions.length,
            2,
            "Should return correct number of voting actions"
        );

        // Verify all actions have correct data structure
        for (uint256 i = 0; i < actions.length; i++) {
            assertEq(
                actions[i].action.head.id,
                i,
                "Action ID should be in sequence"
            );
            assertEq(
                actions[i].submitter,
                address(mockSubmit),
                "Submitter should be mockSubmit address"
            );
            assertEq(actions[i].votesNum, 100, "Total votes should be 100");
            assertEq(actions[i].myVotesNum, 100, "My votes should be 100");
        }
    }
}
