// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "forge-std/Test.sol";
import "../src/LOVE20Hub.sol";
import "../src/interfaces/ILOVE20Hub.sol";

import "./mock/MockWETH9.sol";
import "./mock/MockLOVE20Launch.sol";
import "./mock/MockLOVE20Stake.sol";
import "./mock/MockLOVE20Submit.sol";
import "./mock/MockLOVE20Vote.sol";
import "./mock/MockLOVE20Join.sol";
import "./mock/MockLOVE20Verify.sol";
import "./mock/MockLOVE20Mint.sol";
import "./mock/MockTokens.sol";

contract LOVE20HubTest is ILOVE20HubEvents, Test {
    LOVE20Hub public hub;
    MockWETH9 public mockWETH;
    MockILOVE20LaunchForHub public mockLaunch;
    MockILOVE20Stake public mockStake;
    MockILOVE20Submit public mockSubmit;
    MockILOVE20Vote public mockVote;
    MockILOVE20Join public mockJoin;
    MockILOVE20Verify public mockVerify;
    MockILOVE20Mint public mockMint;
    MockLOVE20Token public mockERC20;

    address public user = address(0x123);
    address public tokenAddress = address(0x456);

    function setUp() public {
        // Deploy Mock contracts
        mockWETH = new MockWETH9();
        mockERC20 = new MockLOVE20Token("TEST");
        mockStake = new MockILOVE20Stake();
        mockSubmit = new MockILOVE20Submit();
        mockLaunch = new MockILOVE20LaunchForHub(
            address(mockERC20),
            address(mockStake)
        );
        mockVote = new MockILOVE20Vote();
        mockJoin = new MockILOVE20Join(address(mockSubmit), address(mockJoin));
        mockVerify = new MockILOVE20Verify();
        mockMint = new MockILOVE20Mint();

        // Set WETH address for mockLaunch
        mockLaunch.setWethAddress(address(mockWETH));

        // Deploy Hub contract
        hub = new LOVE20Hub();

        // Add ETH to test account
        vm.deal(user, 10 ether);
    }

    function testInit() public {
        // Test initialization functionality
        hub.init(
            address(mockWETH),
            address(mockLaunch),
            address(mockStake),
            address(mockSubmit),
            address(mockVote),
            address(mockJoin),
            address(mockVerify),
            address(mockMint)
        );

        // Verify all addresses are set correctly
        assertEq(
            hub.WETHAddress(),
            address(mockWETH),
            "WETH address should be set correctly"
        );
        assertEq(
            hub.launchAddress(),
            address(mockLaunch),
            "Launch address should be set correctly"
        );
        assertEq(
            hub.submitAddress(),
            address(mockSubmit),
            "Submit address should be set correctly"
        );
        assertEq(
            hub.voteAddress(),
            address(mockVote),
            "Vote address should be set correctly"
        );
        assertEq(
            hub.joinAddress(),
            address(mockJoin),
            "Join address should be set correctly"
        );
        assertEq(
            hub.verifyAddress(),
            address(mockVerify),
            "Verify address should be set correctly"
        );
        assertEq(
            hub.mintAddress(),
            address(mockMint),
            "Mint address should be set correctly"
        );
        assertTrue(
            hub.initialized(),
            "Contract should be marked as initialized"
        );
    }

    function testInitAlreadyInitialized() public {
        // Initialize once first
        hub.init(
            address(mockWETH),
            address(mockLaunch),
            address(mockStake),
            address(mockSubmit),
            address(mockVote),
            address(mockJoin),
            address(mockVerify),
            address(mockMint)
        );

        // Attempting to initialize again should fail
        vm.expectRevert("Already initialized");
        hub.init(
            address(mockWETH),
            address(mockLaunch),
            address(mockStake),
            address(mockSubmit),
            address(mockVote),
            address(mockJoin),
            address(mockVerify),
            address(mockMint)
        );
    }

    function testContributeWithETH() public {
        // Initialize Hub first
        hub.init(
            address(mockWETH),
            address(mockLaunch),
            address(mockStake),
            address(mockSubmit),
            address(mockVote),
            address(mockJoin),
            address(mockVerify),
            address(mockMint)
        );

        uint256 contributeAmount = 1 ether;

        // Test successful contribution
        vm.prank(user);
        hub.contributeFirstTokenWithETH{value: contributeAmount}(
            tokenAddress,
            user
        );

        // Verify WETH balance
        assertEq(
            mockWETH.balanceOf(address(mockLaunch)),
            contributeAmount,
            "Hub should hold WETH"
        );

        // Verify Launch contract received correct calls
        assertEq(
            mockLaunch.lastContributeToken(),
            tokenAddress,
            "Passed token address should be correct"
        );
        assertEq(
            mockLaunch.lastContributeAmount(),
            contributeAmount,
            "Passed amount should be correct"
        );
        assertEq(
            mockLaunch.lastContributeTo(),
            user,
            "Passed recipient address should be correct"
        );
    }

    function testContributeWithETHZeroValue() public {
        // Initialize Hub
        hub.init(
            address(mockWETH),
            address(mockLaunch),
            address(mockStake),
            address(mockSubmit),
            address(mockVote),
            address(mockJoin),
            address(mockVerify),
            address(mockMint)
        );

        // Sending 0 ETH should fail
        vm.expectRevert("Must send ETH");
        vm.prank(user);
        hub.contributeFirstTokenWithETH{value: 0}(tokenAddress, user);
    }

    function testContributeWithETHInvalidTokenAddress() public {
        // Initialize Hub
        hub.init(
            address(mockWETH),
            address(mockLaunch),
            address(mockStake),
            address(mockSubmit),
            address(mockVote),
            address(mockJoin),
            address(mockVerify),
            address(mockMint)
        );

        // Invalid token address should fail
        vm.expectRevert("Invalid token address");
        vm.prank(user);
        hub.contributeFirstTokenWithETH{value: 1 ether}(address(0), user);
    }

    function testContributeWithETHInvalidRecipientAddress() public {
        // Initialize Hub
        hub.init(
            address(mockWETH),
            address(mockLaunch),
            address(mockStake),
            address(mockSubmit),
            address(mockVote),
            address(mockJoin),
            address(mockVerify),
            address(mockMint)
        );

        // Invalid recipient address should fail
        vm.expectRevert("Invalid recipient address");
        vm.prank(user);
        hub.contributeFirstTokenWithETH{value: 1 ether}(
            tokenAddress,
            address(0)
        );
    }

    function testContributeWithETHEvent() public {
        // Initialize Hub
        hub.init(
            address(mockWETH),
            address(mockLaunch),
            address(mockStake),
            address(mockSubmit),
            address(mockVote),
            address(mockJoin),
            address(mockVerify),
            address(mockMint)
        );

        uint256 contributeAmount = 1 ether;

        // Test event emission
        vm.expectEmit(true, true, false, true);
        emit ContributeFirstTokenWithETH(tokenAddress, user, contributeAmount);

        vm.prank(user);
        hub.contributeFirstTokenWithETH{value: contributeAmount}(
            tokenAddress,
            user
        );
    }

    function testMultipleContributions() public {
        // Initialize Hub
        hub.init(
            address(mockWETH),
            address(mockLaunch),
            address(mockStake),
            address(mockSubmit),
            address(mockVote),
            address(mockJoin),
            address(mockVerify),
            address(mockMint)
        );

        uint256 firstAmount = 1 ether;
        uint256 secondAmount = 2 ether;

        // First contribution
        vm.prank(user);
        hub.contributeFirstTokenWithETH{value: firstAmount}(tokenAddress, user);

        // Second contribution
        vm.prank(user);
        hub.contributeFirstTokenWithETH{value: secondAmount}(
            tokenAddress,
            user
        );

        // Verify total WETH balance
        assertEq(
            mockWETH.balanceOf(address(mockLaunch)),
            firstAmount + secondAmount,
            "Hub should hold all WETH"
        );
    }

    function testFuzzContributeWithETH(uint256 amount) public {
        // Limit amount range to avoid overflow
        vm.assume(amount > 0 && amount <= 100 ether);

        // Initialize Hub
        hub.init(
            address(mockWETH),
            address(mockLaunch),
            address(mockStake),
            address(mockSubmit),
            address(mockVote),
            address(mockJoin),
            address(mockVerify),
            address(mockMint)
        );

        // Provide sufficient ETH to user
        vm.deal(user, amount);

        // Execute contribution
        vm.prank(user);
        hub.contributeFirstTokenWithETH{value: amount}(tokenAddress, user);

        // Verify results
        assertEq(
            mockWETH.balanceOf(address(mockLaunch)),
            amount,
            "Hub should hold correct amount of WETH"
        );
        assertEq(
            mockLaunch.lastContributeAmount(),
            amount,
            "Passed amount should be correct"
        );
    }
}
