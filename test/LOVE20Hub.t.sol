// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "forge-std/Test.sol";
import "../src/LOVE20Hub.sol";
import "../src/interfaces/ILOVE20Core.sol";
import "./MockLOVE20core.sol";

// Mock WETH9 contract
contract MockWETH9 {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 wad) external {
        require(balanceOf[msg.sender] >= wad, "Insufficient balance");
        balanceOf[msg.sender] -= wad;
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        return true;
    }
}

// Extended MockILOVE20Launch to support contribute function
contract MockILOVE20LaunchForHub is MockILOVE20Launch {
    uint256 public lastContributeAmount;
    address public lastContributeToken;
    address public lastContributeTo;

    constructor(
        address _parentTokenAddress,
        address _stakeAddress
    ) MockILOVE20Launch(_parentTokenAddress, _stakeAddress) {}

    function contribute(
        address tokenAddress,
        uint256 amount,
        address to
    ) external override {
        lastContributeToken = tokenAddress;
        lastContributeAmount = amount;
        lastContributeTo = to;

        // Get WETH from Hub contract - use the actual WETH address from Hub
        LOVE20Hub hub = LOVE20Hub(msg.sender);
        address wethAddress = hub.WETHAddress();

        IERC20(wethAddress).transferFrom(msg.sender, address(this), amount);
    }
}

contract LOVE20HubTest is Test {
    LOVE20Hub public hub;
    MockWETH9 public mockWETH;
    MockILOVE20LaunchForHub public mockLaunch;
    MockILOVE20Stake public mockStake;
    MockILOVE20Submit public mockSubmit;
    MockILOVE20Vote public mockVote;
    MockILOVE20Join public mockJoin;
    MockILOVE20Verify public mockVerify;
    MockILOVE20Mint public mockMint;
    MockERC20 public mockERC20;

    address public user = address(0x123);
    address public tokenAddress = address(0x456);

    // Event declaration for testing
    event ContributeWithETH(
        address indexed tokenAddress,
        address indexed to,
        uint256 ethAmount,
        uint256 wethAmount
    );

    function setUp() public {
        // Deploy Mock contracts
        mockWETH = new MockWETH9();
        mockERC20 = new MockERC20("TEST");
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
        hub.contributeWithETH{value: contributeAmount}(tokenAddress, user);

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

    function testContributeWithETHNotInitialized() public {
        // Should fail when not initialized
        vm.expectRevert("Hub not initialized");
        vm.prank(user);
        hub.contributeWithETH{value: 1 ether}(tokenAddress, user);
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
        hub.contributeWithETH{value: 0}(tokenAddress, user);
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
        hub.contributeWithETH{value: 1 ether}(address(0), user);
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
        hub.contributeWithETH{value: 1 ether}(tokenAddress, address(0));
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
        emit ContributeWithETH(
            tokenAddress,
            user,
            contributeAmount,
            contributeAmount
        );

        vm.prank(user);
        hub.contributeWithETH{value: contributeAmount}(tokenAddress, user);
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
        hub.contributeWithETH{value: firstAmount}(tokenAddress, user);

        // Second contribution
        vm.prank(user);
        hub.contributeWithETH{value: secondAmount}(tokenAddress, user);

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
        hub.contributeWithETH{value: amount}(tokenAddress, user);

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
