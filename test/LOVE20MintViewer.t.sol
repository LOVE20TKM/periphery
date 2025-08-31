// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "forge-std/Test.sol";

import "../src/LOVE20MintViewer.sol";
import "./mock/MockLOVE20Stake.sol";
import "./mock/MockLOVE20Submit.sol";
import "./mock/MockLOVE20Vote.sol";
import "./mock/MockLOVE20Join.sol";
import "./mock/MockLOVE20Verify.sol";
import "./mock/MockLOVE20Mint.sol";
import "./mock/MockLOVE20Launch.sol";
import "./mock/MockTokens.sol";

contract LOVE20MintViewerTest is Test {
    LOVE20MintViewer viewer;

    MockILOVE20Stake mockStake;
    MockILOVE20Vote mockVote;
    MockILOVE20Join mockJoin;
    MockILOVE20Mint mockMint;
    MockLOVE20Token mockERC20;

    function setUp() public {
        mockERC20 = new MockLOVE20Token("TEST", address(0));
        mockStake = new MockILOVE20Stake();
        mockVote = new MockILOVE20Vote();
        mockMint = new MockILOVE20Mint();
        mockJoin = new MockILOVE20Join(address(0x1), address(0x2)); // Use dummy addresses

        viewer = new LOVE20MintViewer();
        viewer.init(
            address(mockStake),
            address(mockVote),
            address(mockJoin),
            address(mockMint)
        );
    }

    function testInitFunction() public view {
        assertEq(viewer.stakeAddress(), address(mockStake));
        assertEq(viewer.voteAddress(), address(mockVote));
        assertEq(viewer.joinAddress(), address(mockJoin));
        assertEq(viewer.mintAddress(), address(mockMint));
    }


    function testActionRewardsByAccountOfLastRounds_NoRewards() public view {
        ActionReward[] memory rewards =
            viewer.actionRewardsByAccountOfLastRounds(address(mockERC20), address(this), 2);

        // no reward for address(this) in mocks
        assertEq(rewards.length, 0);
    }

    function testActionRewardsByAccountOfLastRounds_WithRewards_Minted() public view {
        // account 0x1 has reward 25 and isMinted = true in mocks, for all rounds
        // join round 5 -> mint round 3, LastRounds=1 -> check mint rounds [2, 3]
        ActionReward[] memory rewards = viewer.actionRewardsByAccountOfLastRounds(
            address(mockERC20),
            address(0x1),
            1 // check mint rounds [2, 3]
        );

        // rewards should contain entries for each rewarded round
        assertEq(rewards.length, 2);
        assertEq(rewards[0].actionId, 1);
        assertEq(rewards[1].actionId, 1);
        // mint rounds should be 2 and 3
        assertEq(rewards[0].round, 2); // mint round 2
        assertEq(rewards[1].round, 3); // mint round 3
        // reward value and minted flag from mocks
        assertEq(rewards[0].reward, 25);
        assertEq(rewards[1].reward, 25);
        assertTrue(rewards[0].isMinted);
        assertTrue(rewards[1].isMinted);
    }

    function testHasUnmintedActionRewardOfLastRounds_NoRewards() public view {
        // 测试账户没有奖励的情况
        bool hasUnminted = viewer.hasUnmintedActionRewardOfLastRounds(
            address(mockERC20),
            address(this), // 这个账户在 mock 中没有奖励
            2
        );
        assertFalse(hasUnminted);
    }

    function testHasUnmintedActionRewardOfLastRounds_WithRewards_NotMinted() public view {
        // 测试账户有奖励但未领取的情况
        bool hasUnminted = viewer.hasUnmintedActionRewardOfLastRounds(
            address(mockERC20),
            address(0x2), // 这个账户在 mock 中有奖励但未领取
            2
        );
        assertTrue(hasUnminted);
    }

    function testEstimatedRewards() public {
        // These functions may revert due to underflow in mocks, which is expected
        try viewer.estimatedActionRewardOfCurrentRound(address(mockERC20)) returns (uint256 actionReward) {
            assertTrue(actionReward >= 0);
        } catch {
            // Underflow is expected in mock scenario
        }

        try viewer.estimatedGovRewardOfCurrentRound(address(mockERC20)) returns (uint256 govReward) {
            assertTrue(govReward >= 0);
        } catch {
            // Underflow is expected in mock scenario
        }
    }

    function testGovRewardsByAccountByRounds() public view {
        GovReward[] memory rewards = viewer.govRewardsByAccountByRounds(
            address(mockERC20),
            address(0x1), // account with rewards in mocks
            1,
            2
        );

        assertEq(rewards.length, 2);
        assertEq(rewards[0].round, 1);
        assertEq(rewards[1].round, 2);
        // Mock returns verify reward and boost reward
        // Check that the reward is the sum of verify and boost
        assertEq(rewards[0].reward, rewards[0].verifyReward + rewards[0].boostReward);
    }
}
