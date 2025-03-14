// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "forge-std/Test.sol";
import "../src/interfaces/ILOVE20Core.sol";
import "../src/LOVE20DataViewer.sol";
import "./MockLOVE20core.sol";

contract LOVE20DataViewerTest is Test {
    LOVE20DataViewer viewer;
    address initSetter = address(this);

    MockILOVE20Launch mockLaunch;
    MockILOVE20Stake mockStake;
    MockILOVE20Submit mockSubmit;
    MockILOVE20Vote mockVote;
    MockILOVE20Join mockJoin;
    MockILOVE20Verify mockVerify;
    MockILOVE20Mint mockMint;
    MockERC20 mockERC20;

    function setUp() public {
        // Deploy MockERC20 as parentToken
        mockERC20 = new MockERC20("TEST");
        mockStake = new MockILOVE20Stake();
        mockSubmit = new MockILOVE20Submit();
        // Deploy MockILOVE20Launch with mockERC20's address
        mockLaunch = new MockILOVE20Launch(address(mockERC20), address(mockStake));

        // Deploy other mock contracts
        mockVote = new MockILOVE20Vote();
        mockJoin = new MockILOVE20Join(address(mockSubmit), address(mockJoin));
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
        viewer.init(address(mockLaunch), address(mockSubmit), address(mockVote), address(mockJoin), address(mockVerify), address(mockMint));

        assertEq(viewer.launchAddress(), address(mockLaunch), "launchAddress should be set correctly");
        assertEq(viewer.submitAddress(), address(mockSubmit), "submitAddress should be set correctly");
        assertEq(viewer.voteAddress(), address(mockVote), "voteAddress should be set correctly");
        assertEq(viewer.joinAddress(), address(mockJoin), "joinAddress should be set correctly");
        assertEq(viewer.verifyAddress(), address(mockVerify), "verifyAddress should be set correctly");
        assertEq(viewer.mintAddress(), address(mockMint), "mintAddress should be set correctly");
    }

    // Test tokenDetail function
    function testTokenDetail() public {
        viewer.init(address(mockLaunch), address(mockSubmit), address(mockVote), address(mockJoin), address(mockVerify), address(mockMint));

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
        viewer.init(address(mockLaunch), address(mockSubmit), address(mockVote), address(mockJoin), address(mockVerify), address(mockMint));
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
            address(mockSubmit),
            address(mockVote),
            address(mockJoin),
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

    // Test tokenPairInfoWithAccount function
    function tokenPairInfoWithAccount() public {
        viewer.init(
            address(mockLaunch),
            address(mockSubmit),
            address(mockVote),
            address(mockJoin),
            address(mockVerify),
            address(mockMint)
        );

        PairInfoWithAccount memory pairInfo = viewer.tokenPairInfoWithAccount(
            address(this),
            address(mockERC20),
            address(mockERC20)
        );

        assertEq(pairInfo.pairAddress, address(mockERC20), "Incorrect pair address");
        assertEq(pairInfo.balanceOfToken, 1000, "Incorrect token balance");
        assertEq(pairInfo.balanceOfParentToken, 1000, "Incorrect parent token balance");
        assertEq(pairInfo.allowanceOfToken, 1000, "Incorrect token allowance");
        assertEq(pairInfo.allowanceOfParentToken, 1000, "Incorrect parent token allowance");
        assertEq(pairInfo.pairReserveToken, 0, "Incorrect pair reserve token");
        assertEq(pairInfo.pairReserveParentToken, 0, "Incorrect pair reserve parent token");
    }

    // Test joinableActions function
    function testJoinableActions() public {
        viewer.init(address(mockLaunch), address(mockSubmit), address(mockVote), address(mockJoin), address(mockVerify), address(mockMint));

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
        viewer.init(address(mockLaunch), address(mockSubmit), address(mockVote), address(mockJoin), address(mockVerify), address(mockMint));

        JoinedAction[] memory actions = viewer.joinedActions(address(mockERC20), address(this));
        assertEq(actions.length, 1, "Should return one JoinedAction");
        assertEq(actions[0].actionId, 1, "actionId should be 1");
        assertEq(actions[0].stakedAmount, 500, "stakedAmount should be 500");
    }

    // // Test joinableActionDetailsWithJoinedInfos function
    // function testJoinableActionDetailsWithJoinedInfos() public {
    //     viewer.init(address(mockLaunch), address(mockSubmit), address(mockVote), address(mockJoin), address(mockVerify), address(mockMint));

    //     (JoinableActionDetail[] memory joinableActionDetails, JoinedAction[] memory joinedActions) = viewer.joinableActionDetailsWithJoinedInfos(address(mockERC20), 1, address(this));
    //     assertEq(joinedActions.length, 1, "Should return one JoinedAction");
    //     assertEq(joinedActions[0].actionId, 1, "actionId should be 1");
    //     assertEq(joinedActions[0].stakedAmount, 500, "stakedAmount should be 500");
    //     assertEq(joinableActionDetails.length, 2, "Should return two JoinableActionDetails");
    //     assertEq(joinableActionDetails[0].action.head.id, 1, "actionId should be 1");
    //     assertEq(joinableActionDetails[0].votesNum, 100, "votesNum should be 100");
    //     assertEq(joinableActionDetails[0].joinedAmount, 500, "joinedAmount should be 500");
    //     assertEq(joinableActionDetails[1].action.head.id, 2, "actionId should be 2");
    //     assertEq(joinableActionDetails[1].votesNum, 200, "votesNum should be 200");
    //     assertEq(joinableActionDetails[1].joinedAmount, 1000, "joinedAmount should be 1000");
    // }

    // Test verifiedAddressesByAction function
    function testVerifiedAddressesByAction() public {
        viewer.init(
            address(mockLaunch),
            address(mockSubmit),
            address(mockVote),
            address(mockJoin),
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

    // Test verificationInfosByAction function
    function testVerificationInfosByAction() public {
        viewer.init(address(mockLaunch), address(mockSubmit), address(mockVote), address(mockJoin), address(mockVerify), address(mockMint));

        VerificationInfo[] memory verificationInfos = viewer.verificationInfosByAction(address(mockERC20), 1, 1);
        assertEq(verificationInfos.length, 2, "Should return two accounts");
        assertEq(verificationInfos[0].account, address(0x1), "First account should be 0x1");
        assertEq(verificationInfos[0].infos[0], "Verified Information", "First info should be 'Verified Information'");
        assertEq(verificationInfos[1].account, address(0x2), "Second account should be 0x2");
        assertEq(verificationInfos[1].infos[0], "Verified Information", "Second info should be 'Verified Information'");
    }

    // Test verificationInfosByAccount function
    function testVerificationInfosByAccount() public {
        viewer.init(address(mockLaunch), address(mockSubmit), address(mockVote), address(mockJoin), address(mockVerify), address(mockMint));
        (string[] memory verificationKeys, string[] memory verificationInfos) = viewer.verificationInfosByAccount(address(mockERC20), 1, address(0x1));
        assertEq(verificationKeys.length, 2, "Should return two accounts");
        assertEq(verificationKeys[0], "twitter", "First info should be 'Verified Information'");
        assertEq(verificationKeys[1], "github", "Second info should be 'Verified Information'");
        assertEq(verificationInfos[0], "Verified Information", "First info should be 'Verified Information'");
        assertEq(verificationInfos[1], "Verified Information", "Second info should be 'Verified Information'");
    }

    // Test govData function
    function testGovData() public {
        viewer.init(address(mockLaunch), address(mockSubmit), address(mockVote), address(mockJoin), address(mockVerify), address(mockMint));

        GovData memory govData = viewer.govData(address(mockERC20));
        assertEq(govData.govVotes, 100, "govVotes should be 100");
        assertEq(govData.slAmount, 1000000000000000000000000, "slAmount should be 1000000000000000000000000");
        assertEq(govData.stAmount, 1000000000000000000000000, "stAmount should be 1000000000000000000000000");
        assertEq(govData.tokenAmountForSl, 1000000000000000000000000, "tokenAmountForSl should be 1000000000000000000000000");
        assertEq(govData.parentTokenAmountForSl, 1000000000000000000000000, "parentTokenAmountForSl should be 1000000000000000000000000");
        assertEq(govData.rewardAvailable, 50, "rewardAvailable should be 50");
    }

    // Test govRewardsByAccountByRounds function
    function testGovRewardsByAccountByRounds() public {
        viewer.init(address(mockLaunch), address(mockSubmit), address(mockVote), address(mockJoin), address(mockVerify), address(mockMint));

        GovReward[] memory rewards = viewer.govRewardsByAccountByRounds(address(mockERC20), address(this), 1, 2);

        assertEq(rewards.length, 2, "Should return two GovReward");
        assertEq(rewards[0].round, 1, "First round should be 1");
        assertEq(rewards[0].minted, 50, "First minted should be 50");
        assertEq(rewards[0].unminted, 100, "First unminted should be 100");
    }

    function testActionRewardRoundsByAccount() public {
        viewer.init(address(mockLaunch), address(mockSubmit), address(mockVote), address(mockJoin), address(mockVerify), address(mockMint));

        // Test case 1: Valid actionId, roundEnd is greater than currentRound
        uint256 actionId = 2;
        uint256 roundStart = 1;
        uint256 roundEnd = 2;
         (uint256[] memory rounds, uint256[] memory rewards) = viewer.actionRewardRoundsByAccount(address(mockERC20), address(0x1), actionId, roundStart, roundEnd);
        assertEq(rounds.length, 1, "Should return two rounds");
        assertEq(rewards.length, 1, "Should return two rewards");
        assertEq(rounds[0], 1, "First round should be 1");
        assertEq(rewards[0], 25, "First reward should be 25");

        // Test case 2: Valid actionId, roundEnd is equal to currentRound
        roundStart = 0;
        roundEnd = 1;
        (rounds, rewards) = viewer.actionRewardRoundsByAccount(address(mockERC20), address(0x1), actionId, roundStart, roundEnd);
        assertEq(rounds.length, 2, "Should return two rounds");
        assertEq(rewards.length, 2, "Should return two rewards");
        assertEq(rounds[0], 0, "First round should be 0");
        assertEq(rounds[1], 1, "Second round should be 1");
        assertEq(rewards[0], 25, "First reward should be 25");
        assertEq(rewards[1], 25, "Second reward should be 25");
    }
}   
