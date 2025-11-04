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

    function testActionVerificationMatrixPagedBasic() public view {
        // Test basic paging functionality: get first 2 verifiers
        VerificationMatrix memory matrix = viewer.actionVerificationMatrixPaged(
            address(0x123), // tokenAddress
            1, // round
            1, // actionId
            0, // verifierStart
            2 // verifierEnd
        );

        // Verify returned verifier count is 2
        assertEq(matrix.verifiers.length, 2, "Should have 2 verifiers");

        // Verify returned verifiers are the first 2
        assertEq(
            matrix.verifiers[0],
            address(0x1),
            "First verifier should be 0x1"
        );
        assertEq(
            matrix.verifiers[1],
            address(0x2),
            "Second verifier should be 0x2"
        );

        // Verify complete verifiees list (including zero address)
        assertEq(
            matrix.verifiees.length,
            3,
            "Should have 3 verifiees including zero address"
        );

        // Verify score matrix dimensions are correct
        assertEq(
            matrix.scores.length,
            2,
            "Score matrix should have 2 rows for 2 verifiers"
        );
        assertEq(
            matrix.scores[0].length,
            3,
            "Each row should have 3 columns for 3 verifiees"
        );
    }

    function testActionVerificationMatrixPagedFullRange() public view {
        // Test getting full range: 0 to 3 (all verifiers)
        VerificationMatrix memory matrix = viewer.actionVerificationMatrixPaged(
            address(0x123), // tokenAddress
            1, // round
            1, // actionId
            0, // verifierStart
            3 // verifierEnd
        );

        // Verify all 3 verifiers are returned
        assertEq(matrix.verifiers.length, 3, "Should have all 3 verifiers");

        assertEq(
            matrix.verifiers[0],
            address(0x1),
            "First verifier should be 0x1"
        );
        assertEq(
            matrix.verifiers[1],
            address(0x2),
            "Second verifier should be 0x2"
        );
        assertEq(
            matrix.verifiers[2],
            address(0x3),
            "Third verifier should be 0x3"
        );

        // Verify score matrix dimensions
        assertEq(matrix.scores.length, 3, "Score matrix should have 3 rows");
    }

    function testActionVerificationMatrixPagedMiddleRange() public view {
        // Test getting middle range: 2nd and 3rd verifiers
        VerificationMatrix memory matrix = viewer.actionVerificationMatrixPaged(
            address(0x123), // tokenAddress
            1, // round
            1, // actionId
            1, // verifierStart
            3 // verifierEnd
        );

        // Verify 2 verifiers are returned (indices 1 and 2)
        assertEq(matrix.verifiers.length, 2, "Should have 2 verifiers");

        assertEq(
            matrix.verifiers[0],
            address(0x2),
            "First verifier should be 0x2"
        );
        assertEq(
            matrix.verifiers[1],
            address(0x3),
            "Second verifier should be 0x3"
        );

        // Verify score matrix dimensions
        assertEq(matrix.scores.length, 2, "Score matrix should have 2 rows");

        // Verify specific scores
        assertEq(
            matrix.scores[0][0],
            75,
            "Verifier 0x2 should score 75 for 0xa"
        );
        assertEq(
            matrix.scores[1][0],
            95,
            "Verifier 0x3 should score 95 for 0xa"
        );
    }

    function testActionVerificationMatrixPagedSingleVerifier() public view {
        // Test getting a single verifier
        VerificationMatrix memory matrix = viewer.actionVerificationMatrixPaged(
            address(0x123), // tokenAddress
            1, // round
            1, // actionId
            1, // verifierStart
            2 // verifierEnd
        );

        // Verify only 1 verifier is returned
        assertEq(matrix.verifiers.length, 1, "Should have 1 verifier");

        assertEq(matrix.verifiers[0], address(0x2), "Verifier should be 0x2");

        // Verify score matrix dimensions
        assertEq(matrix.scores.length, 1, "Score matrix should have 1 row");
        assertEq(matrix.scores[0].length, 3, "Row should have 3 columns");

        // Verify the verifier's scores
        assertEq(
            matrix.scores[0][0],
            75,
            "Verifier 0x2 should score 75 for 0xa"
        );
        assertEq(
            matrix.scores[0][1],
            80,
            "Verifier 0x2 should score 80 for 0xb"
        );
        assertEq(
            matrix.scores[0][2],
            40,
            "Verifier 0x2 should score 40 for zero address"
        );
    }

    function testActionVerificationMatrixPagedAutoAdjustEndIndex() public view {
        // Test auto-adjustment of end index when it exceeds actual length
        VerificationMatrix memory matrix = viewer.actionVerificationMatrixPaged(
            address(0x123), // tokenAddress
            1, // round
            1, // actionId
            0, // verifierStart
            100 // verifierEnd (exceeds actual length 3)
        );

        // Verify auto-adjustment to actual length
        assertEq(
            matrix.verifiers.length,
            3,
            "Should auto-adjust to all 3 verifiers"
        );

        // Verify all verifiers are returned
        assertEq(
            matrix.verifiers[0],
            address(0x1),
            "First verifier should be 0x1"
        );
        assertEq(
            matrix.verifiers[1],
            address(0x2),
            "Second verifier should be 0x2"
        );
        assertEq(
            matrix.verifiers[2],
            address(0x3),
            "Third verifier should be 0x3"
        );
    }

    function testActionVerificationMatrixPagedStartIndexOutOfBounds() public {
        // Test start index out of bounds
        vm.expectRevert("Start index out of bounds");
        viewer.actionVerificationMatrixPaged(
            address(0x123), // tokenAddress
            1, // round
            1, // actionId
            3, // verifierStart (equals length, out of bounds)
            5 // verifierEnd
        );
    }

    function testActionVerificationMatrixPagedInvalidRange() public {
        // Test invalid range: start index >= end index
        vm.expectRevert("Invalid range");
        viewer.actionVerificationMatrixPaged(
            address(0x123), // tokenAddress
            1, // round
            1, // actionId
            2, // verifierStart
            2 // verifierEnd (equals start index)
        );
    }

    function testActionVerificationMatrixPagedInvalidRangeReversed() public {
        // Test invalid range: start index > end index
        vm.expectRevert("Invalid range");
        viewer.actionVerificationMatrixPaged(
            address(0x123), // tokenAddress
            1, // round
            1, // actionId
            2, // verifierStart
            1 // verifierEnd (less than start index)
        );
    }

    function testActionVerificationMatrixPagedScoresCorrectness() public view {
        // Test correctness of paged score matrix
        VerificationMatrix memory pagedMatrix = viewer
            .actionVerificationMatrixPaged(
                address(0x123), // tokenAddress
                1, // round
                1, // actionId
                0, // verifierStart
                2 // verifierEnd
            );

        // Verify all scores for first verifier (0x1)
        assertEq(
            pagedMatrix.scores[0][0],
            85,
            "Paged: Verifier 0x1 should score 85 for 0xa"
        );
        assertEq(
            pagedMatrix.scores[0][1],
            90,
            "Paged: Verifier 0x1 should score 90 for 0xb"
        );
        assertEq(
            pagedMatrix.scores[0][2],
            30,
            "Paged: Verifier 0x1 should score 30 for zero address"
        );

        // Verify all scores for second verifier (0x2)
        assertEq(
            pagedMatrix.scores[1][0],
            75,
            "Paged: Verifier 0x2 should score 75 for 0xa"
        );
        assertEq(
            pagedMatrix.scores[1][1],
            80,
            "Paged: Verifier 0x2 should score 80 for 0xb"
        );
        assertEq(
            pagedMatrix.scores[1][2],
            40,
            "Paged: Verifier 0x2 should score 40 for zero address"
        );
    }

    function testActionVerificationMatrixPagedConsistencyWithFullMatrix()
        public
        view
    {
        // Test consistency of paged results with full matrix
        // Get full matrix
        VerificationMatrix memory fullMatrix = viewer.actionVerificationMatrix(
            address(0x123), // tokenAddress
            1, // round
            1 // actionId
        );

        // Get paged matrix (first 2 verifiers)
        VerificationMatrix memory pagedMatrix = viewer
            .actionVerificationMatrixPaged(
                address(0x123), // tokenAddress
                1, // round
                1, // actionId
                0, // verifierStart
                2 // verifierEnd
            );

        // Verify verifiees list is consistent
        assertEq(
            pagedMatrix.verifiees.length,
            fullMatrix.verifiees.length,
            "Verifiees should be same"
        );
        for (uint256 i = 0; i < pagedMatrix.verifiees.length; i++) {
            assertEq(
                pagedMatrix.verifiees[i],
                fullMatrix.verifiees[i],
                "Each verifiee should match"
            );
        }

        // Verify paged verifiers match corresponding verifiers in full matrix
        for (uint256 i = 0; i < pagedMatrix.verifiers.length; i++) {
            assertEq(
                pagedMatrix.verifiers[i],
                fullMatrix.verifiers[i],
                "Paged verifiers should match full matrix"
            );

            // Verify scores match
            for (uint256 j = 0; j < pagedMatrix.verifiees.length; j++) {
                assertEq(
                    pagedMatrix.scores[i][j],
                    fullMatrix.scores[i][j],
                    "Scores should match"
                );
            }
        }
    }
}
