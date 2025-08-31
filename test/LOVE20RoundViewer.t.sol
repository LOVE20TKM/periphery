// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "forge-std/Test.sol";

import "../src/LOVE20RoundViewer.sol";
import "./mock/MockLOVE20Vote.sol";
import "./mock/MockLOVE20Join.sol";
import "./mock/MockLOVE20Verify.sol";

contract LOVE20RoundViewerTest is Test {
    LOVE20RoundViewer viewer;
    MockILOVE20Vote mockVote;
    MockILOVE20Join mockJoin;
    MockILOVE20Verify mockVerify;

    function setUp() public {
        mockVote = new MockILOVE20Vote();
        mockJoin = new MockILOVE20Join(address(0x3), address(0x5));
        mockVerify = new MockILOVE20Verify();

        viewer = new LOVE20RoundViewer();
        viewer.init(
            address(0x1), // launchAddress
            address(0x2), // stakeAddress
            address(0x3), // submitAddress
            address(mockVote), // voteAddress
            address(mockJoin), // joinAddress
            address(mockVerify), // verifyAddress
            address(0x7) // mintAddress
        );
    }

    function testInitFunction() public view {
        assertTrue(viewer.initialized(), "Should be initialized");
    }

    function testCannotInitializeTwice() public {
        vm.expectRevert("Already initialized");
        viewer.init(
            address(0x1), // launchAddress
            address(0x2), // stakeAddress
            address(0x3), // submitAddress
            address(0x4), // voteAddress
            address(0x5), // joinAddress
            address(0x6), // verifyAddress
            address(0x7) // mintAddress
        );
    }

    function testActionVerificationMatrix() public view {
        // Test verification matrix functionality
        VerificationMatrix memory matrix = viewer.actionVerificationMatrix(
            address(0x123), // tokenAddress
            1, // round
            1 // actionId
        );

        // Verify number of verifiers
        assertEq(matrix.verifiers.length, 3, "Should have 3 verifiers");

        // Verify number of verifiees (original 2 + 1 zero address abstention)
        assertEq(
            matrix.verifiees.length,
            3,
            "Should have 3 verifiees including zero address"
        );

        // Verify last verifiee is zero address (abstention vote)
        assertEq(
            matrix.verifiees[2],
            address(0),
            "Last verifiee should be zero address"
        );

        // Verify original verifiees unchanged
        assertEq(
            matrix.verifiees[0],
            address(0xa),
            "First verifiee should be 0xa"
        );
        assertEq(
            matrix.verifiees[1],
            address(0xb),
            "Second verifiee should be 0xb"
        );

        // Verify score matrix dimensions
        assertEq(matrix.scores.length, 3, "Score matrix should have 3 rows");
        for (uint256 i = 0; i < matrix.scores.length; i++) {
            assertEq(
                matrix.scores[i].length,
                3,
                "Each row should have 3 columns"
            );
        }

        // Verify abstention scores (zero address scores)
        for (uint256 i = 0; i < matrix.verifiers.length; i++) {
            // Check each verifier's score for zero address (abstention)
            uint256 abstentionScore = matrix.scores[i][2]; // Zero address is in last column
            assertTrue(abstentionScore >= 0, "Abstention score should be >= 0");
        }
    }

    function testActionVerificationMatrixWithDifferentVerifiers() public view {
        // Test different verifier scores for abstention votes
        VerificationMatrix memory matrix = viewer.actionVerificationMatrix(
            address(0x123), // tokenAddress
            1, // round
            1 // actionId
        );

        // Verify each verifier has score for zero address
        for (uint256 i = 0; i < matrix.verifiers.length; i++) {
            // Zero address score is in last column
            uint256 abstentionScore = matrix.scores[i][
                matrix.verifiees.length - 1
            ];

            // Different verifiers have different scores for zero address
            if (matrix.verifiers[i] == address(0x1)) {
                assertEq(
                    abstentionScore,
                    30,
                    "Verifier 0x1 should have score 30 for zero address"
                );
            } else if (matrix.verifiers[i] == address(0x2)) {
                assertEq(
                    abstentionScore,
                    40,
                    "Verifier 0x2 should have score 40 for zero address"
                );
            } else if (matrix.verifiers[i] == address(0x3)) {
                assertEq(
                    abstentionScore,
                    50,
                    "Verifier 0x3 should have score 50 for zero address"
                );
            }
        }
    }

    function testActionVerificationMatrixCompleteScores() public view {
        // Test complete verification matrix scores
        VerificationMatrix memory matrix = viewer.actionVerificationMatrix(
            address(0x123), // tokenAddress
            1, // round
            1 // actionId
        );

        // Verify specific score matrix values
        // Verifier 0x1 scores for each verifiee
        assertEq(
            matrix.scores[0][0],
            85,
            "Verifier 0x1 should score 85 for 0xa"
        );
        assertEq(
            matrix.scores[0][1],
            90,
            "Verifier 0x1 should score 90 for 0xb"
        );
        assertEq(
            matrix.scores[0][2],
            30,
            "Verifier 0x1 should score 30 for zero address"
        );

        // Verifier 0x2 scores for each verifiee
        assertEq(
            matrix.scores[1][0],
            75,
            "Verifier 0x2 should score 75 for 0xa"
        );
        assertEq(
            matrix.scores[1][1],
            80,
            "Verifier 0x2 should score 80 for 0xb"
        );
        assertEq(
            matrix.scores[1][2],
            40,
            "Verifier 0x2 should score 40 for zero address"
        );

        // Verifier 0x3 scores for each verifiee
        assertEq(
            matrix.scores[2][0],
            95,
            "Verifier 0x3 should score 95 for 0xa"
        );
        assertEq(
            matrix.scores[2][1],
            70,
            "Verifier 0x3 should score 70 for 0xb"
        );
        assertEq(
            matrix.scores[2][2],
            50,
            "Verifier 0x3 should score 50 for zero address"
        );
    }
}
