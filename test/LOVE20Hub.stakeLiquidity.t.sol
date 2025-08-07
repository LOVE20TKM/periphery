// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "forge-std/Test.sol";
import "../src/LOVE20Hub.sol";

import "./mock/MockWETH9.sol";
import "./mock/MockLOVE20Launch.sol";
import "./mock/MockLOVE20Stake.sol";
import "./mock/MockLOVE20Submit.sol";
import "./mock/MockLOVE20Vote.sol";
import "./mock/MockLOVE20Join.sol";
import "./mock/MockLOVE20Verify.sol";
import "./mock/MockLOVE20Mint.sol";
import "./mock/MockTokens.sol";

contract LOVE20HubStakeLiquidityTest is ILOVE20HubEvents, Test {
    LOVE20Hub public hub;
    MockWETH9 public mockWETH;
    MockILOVE20Launch public mockLaunch;
    MockILOVE20Stake public mockStake;
    MockILOVE20Submit public mockSubmit;
    MockILOVE20Vote public mockVote;
    MockILOVE20Join public mockJoin;
    MockILOVE20Verify public mockVerify;
    MockILOVE20Mint public mockMint;
    MockLOVE20Token public mockERC20;

    address public user = address(0x123);
    address public tokenAddress;

    function setUp() public {
        // Deploy Mock contracts
        mockWETH = new MockWETH9();
        mockERC20 = new MockLOVE20Token("TEST", address(0));
        mockStake = new MockILOVE20Stake();
        mockSubmit = new MockILOVE20Submit();
        mockLaunch = new MockILOVE20Launch(
            address(mockERC20),
            address(mockStake)
        );
        mockVote = new MockILOVE20Vote();
        mockJoin = new MockILOVE20Join(address(mockSubmit), address(mockJoin));
        mockVerify = new MockILOVE20Verify();
        mockMint = new MockILOVE20Mint();

        // Deploy Hub contract
        hub = new LOVE20Hub();

        // Set tokenAddress to the mockERC20 address so it has actual contract code
        tokenAddress = address(mockERC20);

        // Add ETH to test account
        vm.deal(user, 10 ether);
    }

    // ==================== stakeLiquidity Tests ====================

    /**
     * @dev Test successful stakeLiquidity execution
     */
    function testStakeLiquiditySuccess() public {
        // Initialize Hub contract
        _initializeHub();

        // Create a token with zero reserves for first liquidity addition
        MockERC20WithReserves mockTokenWithZeroReserves = new MockERC20WithReserves(
                0, // tokenReserve
                0 // parentTokenReserve
            );

        // Set test parameters
        uint256 tokenAmount = 1000 ether;
        uint256 parentTokenAmount = 2000 ether;
        uint256 tokenAmountMin = 900 ether;
        uint256 parentTokenAmountMin = 1800 ether;
        uint256 promisedWaitingPhases = 5;
        address recipient = address(0x789);

        // Setup user token balances
        _setupUserTokenBalances(user, tokenAmount, parentTokenAmount);

        // Test event emission
        vm.expectEmit(true, true, false, true);
        emit StakeLiquidity(
            address(mockTokenWithZeroReserves),
            recipient,
            tokenAmount,
            parentTokenAmount,
            tokenAmount,
            parentTokenAmount,
            promisedWaitingPhases
        );

        // Execute stakeLiquidity
        vm.prank(user);
        (uint256 govVotesAdded, uint256 slAmountAdded) = hub.stakeLiquidity(
            address(mockTokenWithZeroReserves),
            tokenAmount,
            parentTokenAmount,
            tokenAmountMin,
            parentTokenAmountMin,
            promisedWaitingPhases,
            recipient
        );

        // Verify return values
        assertEq(govVotesAdded, 100, "Gov votes should be correct");
        assertEq(slAmountAdded, 200, "SL amount should be correct");

        // Verify token transfers (simplified due to mock implementation)
        assertTrue(govVotesAdded > 0, "Should return correct gov votes");
        assertTrue(slAmountAdded > 0, "Should return correct SL amount");
    }

    /**
     * @dev Test invalid token address
     */
    function testStakeLiquidityInvalidTokenAddress() public {
        _initializeHub();

        vm.expectRevert("Invalid token address");
        vm.prank(user);
        hub.stakeLiquidity(
            address(0), // Invalid token address
            1000 ether,
            2000 ether,
            900 ether,
            1800 ether,
            5,
            user
        );
    }

    /**
     * @dev Test invalid recipient address
     */
    function testStakeLiquidityInvalidRecipientAddress() public {
        _initializeHub();

        vm.expectRevert("Invalid recipient address");
        vm.prank(user);
        hub.stakeLiquidity(
            tokenAddress,
            1000 ether,
            2000 ether,
            900 ether,
            1800 ether,
            5,
            address(0) // Invalid recipient address
        );
    }

    /**
     * @dev Test zero token amount
     */
    function testStakeLiquidityZeroTokenAmount() public {
        _initializeHub();

        vm.expectRevert("Token amount must be greater than 0");
        vm.prank(user);
        hub.stakeLiquidity(
            tokenAddress,
            0, // Zero token amount
            2000 ether,
            900 ether,
            1800 ether,
            5,
            user
        );
    }

    /**
     * @dev Test zero parent token amount
     */
    function testStakeLiquidityZeroParentTokenAmount() public {
        _initializeHub();

        vm.expectRevert("Parent token amount must be greater than 0");
        vm.prank(user);
        hub.stakeLiquidity(
            tokenAddress,
            1000 ether,
            0, // Zero parent token amount
            900 ether,
            1800 ether,
            5,
            user
        );
    }

    /**
     * @dev Test parent token address not found
     */
    function testStakeLiquidityParentTokenAddressNotFound() public {
        _initializeHub();

        // Create a mock token with zero parent token address
        MockERC20WithZeroParent mockTokenWithZeroParent = new MockERC20WithZeroParent();

        vm.expectRevert("Parent token address not found");
        vm.prank(user);
        hub.stakeLiquidity(
            address(mockTokenWithZeroParent),
            1000 ether,
            2000 ether,
            900 ether,
            1800 ether,
            5,
            user
        );
    }

    /**
     * @dev Test slippage protection - insufficient parent token amount
     */
    function testStakeLiquidityInsufficientParentTokenAmount() public {
        _initializeHub();

        // Create a mock token with reserves
        MockERC20WithReserves mockTokenWithReserves = new MockERC20WithReserves(
            1000 ether, // tokenReserve
            500 ether // parentTokenReserve
        );

        _setupUserTokenBalances(user, 2000 ether, 2000 ether);

        // Calculate parameters that will cause insufficient parent token amount
        // If tokenAmountDesired = 2000, parentTokenReserve = 500, tokenReserve = 1000
        // Then parentTokenAmountOptimal = 2000 * 500 / 1000 = 1000
        // If parentTokenAmountMin = 1500, it will trigger "INSUFFICIENT_PARENT_TOKEN_AMOUNT"
        vm.expectRevert("LOVE20Hub: INSUFFICIENT_PARENT_TOKEN_AMOUNT");
        vm.prank(user);
        hub.stakeLiquidity(
            address(mockTokenWithReserves),
            2000 ether,
            2000 ether,
            1000 ether,
            1500 ether, // Minimum parent token amount set too high
            5,
            user
        );
    }

    /**
     * @dev Test slippage protection - insufficient token amount
     */
    function testStakeLiquidityInsufficientTokenAmount() public {
        _initializeHub();

        // Create a mock token with reserves
        MockERC20WithReserves mockTokenWithReserves = new MockERC20WithReserves(
            500 ether, // tokenReserve
            1000 ether // parentTokenReserve
        );

        _setupUserTokenBalances(user, 2000 ether, 2000 ether);

        // Calculate parameters that will cause insufficient token amount
        // If parentTokenAmountDesired = 2000, tokenReserve = 500, parentTokenReserve = 1000
        // Then tokenAmountOptimal = 2000 * 500 / 1000 = 1000
        // If tokenAmountMin = 1500, it will trigger "INSUFFICIENT_TOKEN_AMOUNT"
        vm.expectRevert("LOVE20Hub: INSUFFICIENT_TOKEN_AMOUNT");
        vm.prank(user);
        hub.stakeLiquidity(
            address(mockTokenWithReserves),
            2000 ether,
            2000 ether,
            1500 ether, // Minimum token amount set too high
            1000 ether,
            5,
            user
        );
    }

    /**
     * @dev Test first liquidity addition (zero reserves)
     */
    function testStakeLiquidityFirstLiquidity() public {
        _initializeHub();

        // Create a mock token with zero reserves
        MockERC20WithReserves mockTokenWithZeroReserves = new MockERC20WithReserves(
                0, // tokenReserve = 0
                0 // parentTokenReserve = 0
            );

        uint256 tokenAmount = 1000 ether;
        uint256 parentTokenAmount = 2000 ether;

        _setupUserTokenBalances(user, tokenAmount, parentTokenAmount);

        // First liquidity addition should use desired amounts
        vm.prank(user);
        (uint256 govVotesAdded, uint256 slAmountAdded) = hub.stakeLiquidity(
            address(mockTokenWithZeroReserves),
            tokenAmount,
            parentTokenAmount,
            tokenAmount,
            parentTokenAmount,
            5,
            user
        );

        // Verify return values
        assertEq(govVotesAdded, 100, "Gov votes should be correct");
        assertEq(slAmountAdded, 200, "SL amount should be correct");
    }

    /**
     * @dev Test different waiting phases
     */
    function testStakeLiquidityDifferentWaitingPhases() public {
        _initializeHub();

        // Create a token with zero reserves for first liquidity addition
        MockERC20WithReserves mockTokenWithZeroReserves = new MockERC20WithReserves(
                0, // tokenReserve
                0 // parentTokenReserve
            );

        _setupUserTokenBalances(user, 1000 ether, 2000 ether);

        uint256[] memory phases = new uint256[](3);
        phases[0] = 1;
        phases[1] = 10;
        phases[2] = 100;

        for (uint256 i = 0; i < phases.length; i++) {
            vm.prank(user);
            (uint256 govVotesAdded, uint256 slAmountAdded) = hub.stakeLiquidity(
                address(mockTokenWithZeroReserves),
                100 ether,
                200 ether,
                90 ether,
                180 ether,
                phases[i],
                user
            );

            // Verify each call succeeds
            assertTrue(govVotesAdded > 0, "Gov votes should be greater than 0");
            assertTrue(slAmountAdded > 0, "SL amount should be greater than 0");
        }
    }

    /**
     * @dev Fuzz test - test various amount combinations
     */
    function testFuzzStakeLiquidity(
        uint256 tokenAmount,
        uint256 parentTokenAmount,
        uint256 promisedWaitingPhases
    ) public {
        // Limit parameter ranges
        vm.assume(tokenAmount > 0 && tokenAmount <= 1000000 ether);
        vm.assume(parentTokenAmount > 0 && parentTokenAmount <= 1000000 ether);
        vm.assume(promisedWaitingPhases > 0 && promisedWaitingPhases <= 1000);

        _initializeHub();

        // Create a token with zero reserves for first liquidity addition
        MockERC20WithReserves mockTokenWithZeroReserves = new MockERC20WithReserves(
                0, // tokenReserve
                0 // parentTokenReserve
            );

        _setupUserTokenBalances(user, tokenAmount, parentTokenAmount);

        // Set minimum values to 90% of desired values
        uint256 tokenAmountMin = (tokenAmount * 90) / 100;
        uint256 parentTokenAmountMin = (parentTokenAmount * 90) / 100;

        vm.prank(user);
        (uint256 govVotesAdded, uint256 slAmountAdded) = hub.stakeLiquidity(
            address(mockTokenWithZeroReserves),
            tokenAmount,
            parentTokenAmount,
            tokenAmountMin,
            parentTokenAmountMin,
            promisedWaitingPhases,
            user
        );

        // Verify return values
        assertEq(govVotesAdded, 100, "Gov votes should be correct");
        assertEq(slAmountAdded, 200, "SL amount should be correct");
    }

    /**
     * @dev Test boundary conditions - minimal amounts
     */
    function testStakeLiquidityMinimalAmounts() public {
        _initializeHub();

        // Create a mock token with zero reserves for first liquidity addition
        MockERC20WithReserves mockTokenWithZeroReserves = new MockERC20WithReserves(
                0, // tokenReserve
                0 // parentTokenReserve
            );

        uint256 minAmount = 1; // Minimal amount
        _setupUserTokenBalances(user, minAmount, minAmount);

        vm.prank(user);
        (uint256 govVotesAdded, uint256 slAmountAdded) = hub.stakeLiquidity(
            address(mockTokenWithZeroReserves),
            minAmount,
            minAmount,
            0, // Minimum value set to 0
            0, // Minimum value set to 0
            1,
            user
        );

        // Verify return values
        assertEq(govVotesAdded, 100, "Gov votes should be correct");
        assertEq(slAmountAdded, 200, "SL amount should be correct");
    }

    /**
     * @dev Test large amounts
     */
    function testStakeLiquidityLargeAmounts() public {
        _initializeHub();

        // Create a token with zero reserves for first liquidity addition
        MockERC20WithReserves mockTokenWithZeroReserves = new MockERC20WithReserves(
                0, // tokenReserve
                0 // parentTokenReserve
            );

        uint256 largeAmount = 1000000 ether;
        _setupUserTokenBalances(user, largeAmount, largeAmount);

        vm.prank(user);
        (uint256 govVotesAdded, uint256 slAmountAdded) = hub.stakeLiquidity(
            address(mockTokenWithZeroReserves),
            largeAmount,
            largeAmount,
            (largeAmount * 90) / 100, // 90% of large amount
            (largeAmount * 90) / 100, // 90% of large amount
            5,
            user
        );

        // Verify return values
        assertEq(govVotesAdded, 100, "Gov votes should be correct");
        assertEq(slAmountAdded, 200, "SL amount should be correct");
    }

    /**
     * @dev Test multiple users staking liquidity
     */
    function testStakeLiquidityMultipleUsers() public {
        _initializeHub();

        // Create a token with zero reserves for first liquidity addition
        MockERC20WithReserves mockTokenWithZeroReserves = new MockERC20WithReserves(
                0, // tokenReserve
                0 // parentTokenReserve
            );

        address[] memory users = new address[](3);
        users[0] = address(0x111);
        users[1] = address(0x222);
        users[2] = address(0x333);

        for (uint256 i = 0; i < users.length; i++) {
            _setupUserTokenBalances(users[i], 1000 ether, 2000 ether);

            vm.prank(users[i]);
            (uint256 govVotesAdded, uint256 slAmountAdded) = hub.stakeLiquidity(
                address(mockTokenWithZeroReserves),
                100 ether,
                200 ether,
                90 ether,
                180 ether,
                5,
                users[i]
            );

            // Verify each call succeeds
            assertTrue(govVotesAdded > 0, "Gov votes should be greater than 0");
            assertTrue(slAmountAdded > 0, "SL amount should be greater than 0");
        }
    }

    /**
     * @dev Test optimal amount calculation with specific reserve ratios
     */
    function testStakeLiquidityOptimalAmountCalculation() public {
        _initializeHub();

        // Create a mock token with specific reserves to test calculation logic
        MockERC20WithReserves mockTokenWithReserves = new MockERC20WithReserves(
            1000 ether, // tokenReserve
            2000 ether // parentTokenReserve
        );

        _setupUserTokenBalances(user, 3000 ether, 6000 ether);

        // With reserves 1000:2000 (1:2 ratio)
        // If we want to add 1500 token and 3000 parent token
        // Optimal parent token amount = 1500 * 2000 / 1000 = 3000
        // This should work without slippage issues
        vm.prank(user);
        (uint256 govVotesAdded, uint256 slAmountAdded) = hub.stakeLiquidity(
            address(mockTokenWithReserves),
            1500 ether, // tokenAmount
            3000 ether, // parentTokenAmount
            1400 ether, // tokenAmountMin (small buffer)
            2800 ether, // parentTokenAmountMin (small buffer)
            5,
            user
        );

        // Verify the function executed successfully
        assertEq(govVotesAdded, 100, "Gov votes should be correct");
        assertEq(slAmountAdded, 200, "SL amount should be correct");
    }

    /**
     * @dev Test edge case where optimal amount exceeded check is triggered
     */
    function testStakeLiquidityOptimalAmountExceeded() public {
        _initializeHub();

        // Create a mock token with reserves where tokenAmountOptimal would exceed tokenAmountDesired
        MockERC20WithReserves mockTokenWithReserves = new MockERC20WithReserves(
            2000 ether, // tokenReserve
            1000 ether // parentTokenReserve
        );

        _setupUserTokenBalances(user, 3000 ether, 3000 ether);

        // With reserves 2000:1000 (2:1 ratio)
        // If we want to add 1000 token and 2000 parent token
        // parentTokenAmountOptimal = 1000 * 1000 / 2000 = 500 (< 2000, so uses first path)
        // Since parentTokenAmountOptimal (500) < parentTokenAmountMin (1800),
        // this will trigger "INSUFFICIENT_PARENT_TOKEN_AMOUNT"

        vm.expectRevert("LOVE20Hub: INSUFFICIENT_PARENT_TOKEN_AMOUNT");
        vm.prank(user);
        hub.stakeLiquidity(
            address(mockTokenWithReserves),
            1000 ether, // tokenAmount
            2000 ether, // parentTokenAmount
            900 ether, // tokenAmountMin
            1800 ether, // parentTokenAmountMin (set higher than optimal 500 to trigger error)
            5,
            user
        );
    }

    // ==================== Helper Functions ====================

    /**
     * @dev Initialize Hub contract
     */
    function _initializeHub() internal {
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

    /**
     * @dev Setup sufficient token balances for user
     */
    function _setupUserTokenBalances(
        address targetUser,
        uint256 tokenAmount,
        uint256 parentTokenAmount
    ) internal pure {
        // Provide sufficient token balances for user
        // Note: In a real environment, this would require ERC20 transfer or mint functions
        // In our test environment, Mock contracts return fixed balances, so this is mainly documentation

        // If balance verification is needed, the following checks can be added:
        // assertTrue(IERC20(tokenAddress).balanceOf(targetUser) >= tokenAmount, "Insufficient user token balance");
        // assertTrue(IERC20(parentTokenAddress).balanceOf(targetUser) >= parentTokenAmount, "Insufficient user parent token balance");

        targetUser; // Avoid unused variable warning
        tokenAmount;
        parentTokenAmount;
    }
}
