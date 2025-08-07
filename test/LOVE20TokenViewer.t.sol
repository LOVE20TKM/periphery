// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "forge-std/Test.sol";

import "../src/LOVE20TokenViewer.sol";
import "./mock/MockLOVE20Launch.sol";
import "./mock/MockLOVE20Stake.sol";
import "./mock/MockTokens.sol";

contract LOVE20TokenViewerTest is Test {
    LOVE20TokenViewer viewer;

    MockILOVE20Launch mockLaunch;
    MockILOVE20Stake mockStake;
    MockLOVE20Token mockERC20;
    MockLOVE20Token mockParentToken;

    function setUp() public {
        // Deploy MockLOVE20Token as parentToken
        mockParentToken = new MockLOVE20Token("PARENT", address(0));
        mockERC20 = new MockLOVE20Token("TEST", address(mockParentToken));
        mockStake = new MockILOVE20Stake();

        // Deploy MockILOVE20Launch with mockERC20's address
        mockLaunch = new MockILOVE20Launch(
            address(mockERC20),
            address(mockStake)
        );

        // Deploy the contract under test
        viewer = new LOVE20TokenViewer();
        viewer.init(address(mockLaunch), address(mockStake));
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
        }
    }

    // Test tokenPairInfoWithAccount function
    function testTokenPairInfoWithAccount() public view {
        PairInfoWithAccount memory pairInfo = viewer.tokenPairInfoWithAccount(
            address(this),
            address(mockERC20)
        );

        // pairAddress should be the Uniswap pair address, not the token address
        assertNotEq(
            pairInfo.pairAddress,
            address(0),
            "Pair address should not be zero"
        );
        assertEq(
            pairInfo.balanceOfToken,
            1000000 ether,
            "Incorrect token balance"
        );
        assertEq(
            pairInfo.balanceOfParentToken,
            1000000 ether,
            "Incorrect parent token balance"
        );
        assertEq(
            pairInfo.allowanceOfToken,
            1000000 ether,
            "Incorrect token allowance"
        );
        assertEq(
            pairInfo.allowanceOfParentToken,
            1000000 ether,
            "Incorrect parent token allowance"
        );
        assertEq(pairInfo.pairReserveToken, 0, "Incorrect pair reserve token");
        assertEq(
            pairInfo.pairReserveParentToken,
            0,
            "Incorrect pair reserve parent token"
        );
    }

    // Test tokensByPage function
    function testTokensByPage() public view {
        // Test normal range
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

        // Test single token
        tokens = viewer.tokensByPage(0, 0);
        assertEq(tokens.length, 1, "Should return one token");
        assertEq(tokens[0], address(mockERC20), "Token should be mockERC20");

        // Test when end exceeds range
        tokens = viewer.tokensByPage(0, 10);
        assertEq(
            tokens.length,
            2,
            "Should return two tokens when end exceeds range"
        );
    }

    // Test tokensByPage edge cases
    function testTokensByPageEdgeCases() public {
        // Test when start > end
        vm.expectRevert("Invalid range");
        viewer.tokensByPage(2, 1);

        // Test when start exceeds range
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

        // Test single token
        tokens = viewer.childTokensByPage(address(mockERC20), 1, 1);
        assertEq(tokens.length, 1, "Should return one child token");
        assertEq(
            tokens[0],
            address(mockERC20),
            "Child token should be mockERC20"
        );

        // Test boundary conditions
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

        // Test when end exceeds range
        tokens = viewer.launchingTokensByPage(0, 10);
        assertEq(
            tokens.length,
            1,
            "Should return one launching token when end exceeds range"
        );

        // Test boundary conditions
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

        // Test when end exceeds range
        tokens = viewer.launchedTokensByPage(0, 10);
        assertEq(
            tokens.length,
            1,
            "Should return one launched token when end exceeds range"
        );

        // Test boundary conditions
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

        // Test when end exceeds range
        tokens = viewer.launchingChildTokensByPage(address(mockERC20), 0, 10);
        assertEq(
            tokens.length,
            1,
            "Should return one launching child token when end exceeds range"
        );

        // Test boundary conditions
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

        // Test when end exceeds range
        tokens = viewer.launchedChildTokensByPage(address(mockERC20), 0, 10);
        assertEq(
            tokens.length,
            1,
            "Should return one launched child token when end exceeds range"
        );

        // Test boundary conditions
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

        // Test when end exceeds range
        tokens = viewer.participatedTokensByPage(address(this), 0, 10);
        assertEq(
            tokens.length,
            1,
            "Should return one participated token when end exceeds range"
        );

        // Test boundary conditions
        vm.expectRevert("Invalid range");
        viewer.participatedTokensByPage(address(this), 2, 1);

        vm.expectRevert("Out of range");
        viewer.participatedTokensByPage(address(this), 10, 20);
    }
}
