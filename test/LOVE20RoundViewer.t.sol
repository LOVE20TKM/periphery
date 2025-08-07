// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "forge-std/Test.sol";

import "../src/LOVE20RoundViewer.sol";
import "./mock/MockLOVE20Stake.sol";
import "./mock/MockLOVE20Submit.sol";
import "./mock/MockLOVE20Vote.sol";
import "./mock/MockLOVE20Join.sol";
import "./mock/MockLOVE20Verify.sol";
import "./mock/MockLOVE20Mint.sol";
import "./mock/MockTokens.sol";

contract LOVE20RoundViewerTest is Test {
    LOVE20RoundViewer viewer;

    MockILOVE20Stake mockStake;
    MockILOVE20Submit mockSubmit;
    MockILOVE20Vote mockVote;
    MockILOVE20Join mockJoin;
    MockILOVE20Verify mockVerify;
    MockILOVE20Mint mockMint;
    MockLOVE20Token mockERC20;

    function setUp() public {
        mockERC20 = new MockLOVE20Token("TEST", address(0));
        mockStake = new MockILOVE20Stake();
        mockSubmit = new MockILOVE20Submit();
        mockVote = new MockILOVE20Vote();
        mockJoin = new MockILOVE20Join(address(mockSubmit), address(mockJoin));
        mockVerify = new MockILOVE20Verify();
        mockMint = new MockILOVE20Mint();

        viewer = new LOVE20RoundViewer();
        viewer.init(
            address(mockStake),
            address(mockSubmit),
            address(mockVote),
            address(mockJoin),
            address(mockVerify),
            address(mockMint)
        );
    }

    function testInitFunction() public view {
        assertEq(viewer.stakeAddress(), address(mockStake));
        assertEq(viewer.submitAddress(), address(mockSubmit));
        assertEq(viewer.voteAddress(), address(mockVote));
        assertEq(viewer.joinAddress(), address(mockJoin));
        assertEq(viewer.verifyAddress(), address(mockVerify));
        assertEq(viewer.mintAddress(), address(mockMint));
    }

    function testJoinedActions() public view {
        JoinedAction[] memory actions = viewer.joinedActions(
            address(mockERC20),
            address(this)
        );
        assertEq(actions.length, 1);
        assertEq(actions[0].action.head.id, 1);
        assertEq(actions[0].joinedAmountOfAccount, 500);
        assertEq(actions[0].hasReward, true);
    }

    function testJoinableActions() public view {
        JoinableAction[] memory joinableActions = viewer.joinableActions(
            address(mockERC20),
            1,
            address(this)
        );
        assertEq(joinableActions.length, 3);
        assertEq(joinableActions[0].action.head.id, 1);
        assertEq(joinableActions[0].votesNum, 100);
    }

    function testVerifingActions() public view {
        VerifyingAction[] memory actions = viewer.verifyingActions(
            address(mockERC20),
            1,
            address(this)
        );
        assertEq(actions.length, 3);
        assertEq(actions[0].action.head.id, 1);
        assertEq(actions[0].votesNum, 100);
    }

    function testGovData() public view {
        GovData memory govData = viewer.govData(address(mockERC20));
        assertEq(govData.govVotes, 100);
        assertEq(govData.rewardAvailable, 50);
    }

    function testVotesNums() public view {
        (uint256[] memory actionIds, uint256[] memory votes) = viewer.votesNums(
            address(mockERC20),
            1
        );
        assertEq(actionIds.length, 3);
        assertEq(votes.length, 3);
    }

    function testActionInfosByIds() public view {
        uint256[] memory actionIds = new uint256[](2);
        actionIds[0] = 1;
        actionIds[1] = 2;

        ActionInfo[] memory actionInfos = viewer.actionInfosByIds(
            address(mockERC20),
            actionIds
        );
        assertEq(actionInfos.length, 2);
    }

    function testActionInfosByPage() public view {
        ActionInfo[] memory actionInfos = viewer.actionInfosByPage(
            address(mockERC20),
            0,
            2
        );
        assertEq(actionInfos.length, 3);
    }

    function testVotingActions() public view {
        VotingAction[] memory actions = viewer.votingActions(
            address(mockERC20),
            1,
            address(this)
        );
        assertEq(actions.length, 2);
    }
}
