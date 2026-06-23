// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "forge-std/Test.sol";
import {IUniswapV2Factory} from "../lib/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "../lib/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router02} from "../lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract TestERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    function mint(address to, uint256 amount) external {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        if (from != msg.sender && allowance[from][msg.sender] != type(uint256).max) {
            require(allowance[from][msg.sender] >= amount, "ERC20: insufficient allowance");
            allowance[from][msg.sender] -= amount;
        }
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(balanceOf[from] >= amount, "ERC20: insufficient balance");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }
}

interface IUniswapV2Zap {
    struct ZapTokenParams {
        address tokenA;
        address tokenB;
        uint256 amountAIn;
        uint256 amountBIn;
        uint256 amountAMin;
        uint256 amountBMin;
        uint256 liquidityMin;
        address to;
        uint256 deadline;
    }

    function zapToken(ZapTokenParams calldata params)
        external
        returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function zapNativeToken(
        address token,
        uint256 amountTokenIn,
        uint256 amountTokenMin,
        uint256 amountNativeMin,
        uint256 liquidityMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountNative, uint256 liquidity);
}

contract UniswapV2ZapTest is Test {
    event ZapToken(
        address indexed account,
        address indexed tokenA,
        address indexed tokenB,
        address to,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );
    event ZapNativeToken(
        address indexed account,
        address indexed token,
        address indexed to,
        uint256 amountToken,
        uint256 amountNative,
        uint256 liquidity
    );

    error InsufficientLiquidityMinted();
    error PairMissingOrEmpty();

    IUniswapV2Factory public factory;
    IUniswapV2Router02 public router;
    IUniswapV2Zap public zap;
    TestERC20 public tokenA;
    TestERC20 public tokenB;
    TestERC20 public tokenC;
    TestERC20 public tokenD;
    address public weth;
    address public user = address(0x1234);
    address public recipient = address(0x5678);

    receive() external payable {}

    function setUp() public {
        weth = deployCode("out/WETH9.sol/WETH9.json");
        factory = IUniswapV2Factory(
            deployCode(
                _repoArtifact("/../core/out/UniswapV2Factory.sol/UniswapV2Factory.json"), abi.encode(address(this))
            )
        );
        router = IUniswapV2Router02(
            deployCode("out/UniswapV2Router02.sol/UniswapV2Router02.json", abi.encode(address(factory), weth))
        );
        zap = IUniswapV2Zap(deployCode("out/UniswapV2Zap.sol/UniswapV2Zap.json", abi.encode(address(router))));

        tokenA = new TestERC20("Token A", "TKA");
        tokenB = new TestERC20("Token B", "TKB");
        tokenC = new TestERC20("Token C", "TKC");
        tokenD = new TestERC20("Token D", "TKD");

        vm.deal(user, 100 ether);
        _seedTokenPair();
        _seedEthPair();
    }

    function _repoArtifact(string memory relativePath) internal view returns (string memory) {
        return string(abi.encodePacked(vm.projectRoot(), relativePath));
    }

    function testZapSingleTokenA() public {
        uint256 liquidityBefore = _pair(tokenA, tokenB).balanceOf(recipient);
        _mintAndApprove(100 ether, 0);

        vm.prank(user);
        (uint256 amountA, uint256 amountB, uint256 liquidity) = zap.zapToken(
            IUniswapV2Zap.ZapTokenParams({
                tokenA: address(tokenA),
                tokenB: address(tokenB),
                amountAIn: 100 ether,
                amountBIn: 0,
                amountAMin: 1,
                amountBMin: 1,
                liquidityMin: 1,
                to: recipient,
                deadline: block.timestamp + 1
            })
        );

        assertGt(amountA, 0, "amountA");
        assertGt(amountB, 0, "amountB");
        assertGt(liquidity, 0, "liquidity");
        assertGt(_pair(tokenA, tokenB).balanceOf(recipient), liquidityBefore, "recipient LP");
        _assertNoZapTokenDust(tokenA, tokenB);
    }

    function testZapSingleTokenB() public {
        uint256 liquidityBefore = _pair(tokenA, tokenB).balanceOf(recipient);
        _mintAndApprove(0, 100 ether);

        vm.prank(user);
        (uint256 amountA, uint256 amountB, uint256 liquidity) = zap.zapToken(
            IUniswapV2Zap.ZapTokenParams({
                tokenA: address(tokenA),
                tokenB: address(tokenB),
                amountAIn: 0,
                amountBIn: 100 ether,
                amountAMin: 1,
                amountBMin: 1,
                liquidityMin: 1,
                to: recipient,
                deadline: block.timestamp + 1
            })
        );

        assertGt(amountA, 0, "amountA");
        assertGt(amountB, 0, "amountB");
        assertGt(liquidity, 0, "liquidity");
        assertGt(_pair(tokenA, tokenB).balanceOf(recipient), liquidityBefore, "recipient LP");
        _assertNoZapTokenDust(tokenA, tokenB);
    }

    function testZapUnbalancedTokenPair() public {
        uint256 liquidityBefore = _pair(tokenA, tokenB).balanceOf(recipient);
        _mintAndApprove(200 ether, 10 ether);

        vm.prank(user);
        (uint256 amountA, uint256 amountB, uint256 liquidity) = zap.zapToken(
            IUniswapV2Zap.ZapTokenParams({
                tokenA: address(tokenA),
                tokenB: address(tokenB),
                amountAIn: 200 ether,
                amountBIn: 10 ether,
                amountAMin: 1,
                amountBMin: 1,
                liquidityMin: 1,
                to: recipient,
                deadline: block.timestamp + 1
            })
        );

        assertGt(amountA, 0, "amountA");
        assertGt(amountB, 0, "amountB");
        assertGt(liquidity, 0, "liquidity");
        assertGt(_pair(tokenA, tokenB).balanceOf(recipient), liquidityBefore, "recipient LP");
        _assertNoZapTokenDust(tokenA, tokenB);
    }

    function testZapTokenDoesNotRefundExistingBalances() public {
        uint256 existingA = 7 ether;
        uint256 existingB = 3 ether;
        tokenA.mint(address(zap), existingA);
        tokenB.mint(address(zap), existingB);
        _mintAndApprove(100 ether, 0);

        vm.prank(user);
        zap.zapToken(
            IUniswapV2Zap.ZapTokenParams({
                tokenA: address(tokenA),
                tokenB: address(tokenB),
                amountAIn: 100 ether,
                amountBIn: 0,
                amountAMin: 1,
                amountBMin: 1,
                liquidityMin: 1,
                to: recipient,
                deadline: block.timestamp + 1
            })
        );

        assertEq(tokenA.balanceOf(address(zap)), existingA, "existing tokenA stays");
        assertEq(tokenB.balanceOf(address(zap)), existingB, "existing tokenB stays");
    }

    function testZapTokenEmitsEvent() public {
        _mintAndApprove(100 ether, 0);

        vm.expectEmit(true, true, true, false, address(zap));
        emit ZapToken(user, address(tokenA), address(tokenB), recipient, 0, 0, 0);

        vm.prank(user);
        zap.zapToken(
            IUniswapV2Zap.ZapTokenParams({
                tokenA: address(tokenA),
                tokenB: address(tokenB),
                amountAIn: 100 ether,
                amountBIn: 0,
                amountAMin: 1,
                amountBMin: 1,
                liquidityMin: 1,
                to: recipient,
                deadline: block.timestamp + 1
            })
        );
    }

    function testZapNativeToken() public {
        address pair = factory.getPair(weth, address(tokenA));
        uint256 liquidityBefore = IUniswapV2Pair(pair).balanceOf(recipient);

        vm.prank(user);
        (uint256 amountToken, uint256 amountNative, uint256 liquidity) =
            zap.zapNativeToken{value: 10 ether}(address(tokenA), 0, 1, 1, 1, recipient, block.timestamp + 1);

        assertGt(amountToken, 0, "amountToken");
        assertGt(amountNative, 0, "amountNative");
        assertGt(liquidity, 0, "liquidity");
        assertGt(IUniswapV2Pair(pair).balanceOf(recipient), liquidityBefore, "recipient LP");
        assertEq(tokenA.balanceOf(address(zap)), 0, "zap token dust");
        assertEq(IERC20Like(weth).balanceOf(address(zap)), 0, "zap weth dust");
        assertEq(address(zap).balance, 0, "zap eth dust");
    }

    function testZapNativeTokenDoesNotRefundExistingBalances() public {
        uint256 existingToken = 7 ether;
        uint256 existingWrappedNative = 3 ether;
        tokenA.mint(address(zap), existingToken);
        IWrappedNativeLike(weth).deposit{value: existingWrappedNative}();
        IWrappedNativeLike(weth).transfer(address(zap), existingWrappedNative);

        vm.prank(user);
        zap.zapNativeToken{value: 10 ether}(address(tokenA), 0, 1, 1, 1, recipient, block.timestamp + 1);

        assertEq(tokenA.balanceOf(address(zap)), existingToken, "existing token stays");
        assertEq(IERC20Like(weth).balanceOf(address(zap)), existingWrappedNative, "existing wrapped native stays");
    }

    function testZapNativeTokenEmitsEvent() public {
        vm.expectEmit(true, true, true, false, address(zap));
        emit ZapNativeToken(user, address(tokenA), recipient, 0, 0, 0);

        vm.prank(user);
        zap.zapNativeToken{value: 10 ether}(address(tokenA), 0, 1, 1, 1, recipient, block.timestamp + 1);
    }

    function testExpiredDeadlineReverts() public {
        _mintAndApprove(100 ether, 0);

        vm.expectRevert(bytes("UniswapV2Router: EXPIRED"));
        vm.prank(user);
        zap.zapToken(
            IUniswapV2Zap.ZapTokenParams({
                tokenA: address(tokenA),
                tokenB: address(tokenB),
                amountAIn: 100 ether,
                amountBIn: 0,
                amountAMin: 1,
                amountBMin: 1,
                liquidityMin: 1,
                to: recipient,
                deadline: block.timestamp - 1
            })
        );
    }

    function testLiquidityMinReverts() public {
        _mintAndApprove(100 ether, 0);

        vm.expectRevert(InsufficientLiquidityMinted.selector);
        vm.prank(user);
        zap.zapToken(
            IUniswapV2Zap.ZapTokenParams({
                tokenA: address(tokenA),
                tokenB: address(tokenB),
                amountAIn: 100 ether,
                amountBIn: 0,
                amountAMin: 1,
                amountBMin: 1,
                liquidityMin: type(uint256).max,
                to: recipient,
                deadline: block.timestamp + 1
            })
        );
    }

    function testPairNotFoundSingleTokenReverts() public {
        tokenC.mint(user, 100 ether);
        vm.prank(user);
        tokenC.approve(address(zap), 100 ether);

        vm.expectRevert(PairMissingOrEmpty.selector);
        vm.prank(user);
        zap.zapToken(
            IUniswapV2Zap.ZapTokenParams({
                tokenA: address(tokenC),
                tokenB: address(tokenD),
                amountAIn: 100 ether,
                amountBIn: 0,
                amountAMin: 1,
                amountBMin: 1,
                liquidityMin: 1,
                to: recipient,
                deadline: block.timestamp + 1
            })
        );
    }

    function testPairNotFoundDualTokenCreatesPair() public {
        tokenC.mint(user, 100 ether);
        tokenD.mint(user, 200 ether);
        vm.startPrank(user);
        tokenC.approve(address(zap), 100 ether);
        tokenD.approve(address(zap), 200 ether);
        zap.zapToken(
            IUniswapV2Zap.ZapTokenParams({
                tokenA: address(tokenC),
                tokenB: address(tokenD),
                amountAIn: 100 ether,
                amountBIn: 200 ether,
                amountAMin: 1,
                amountBMin: 1,
                liquidityMin: 1,
                to: recipient,
                deadline: block.timestamp + 1
            })
        );
        vm.stopPrank();

        address pair = factory.getPair(address(tokenC), address(tokenD));
        assertTrue(pair != address(0), "pair created");
        assertGt(IUniswapV2Pair(pair).balanceOf(recipient), 0, "recipient LP");
        _assertNoZapTokenDust(tokenC, tokenD);
    }

    function testNoAdminFunctions() public {
        _assertNoSelector("owner()");
        _assertNoSelector("pause()");
        _assertNoSelector("recover(address,uint256)");
        _assertNoSelector("admin()");
    }

    function _seedTokenPair() internal {
        tokenA.mint(address(this), 1000 ether);
        tokenB.mint(address(this), 1000 ether);
        tokenA.approve(address(router), 1000 ether);
        tokenB.approve(address(router), 1000 ether);
        router.addLiquidity(
            address(tokenA), address(tokenB), 1000 ether, 1000 ether, 1, 1, address(this), block.timestamp + 1
        );
    }

    function _seedEthPair() internal {
        tokenA.mint(address(this), 1000 ether);
        tokenA.approve(address(router), 1000 ether);
        router.addLiquidityETH{value: 100 ether}(address(tokenA), 1000 ether, 1, 1, address(this), block.timestamp + 1);
    }

    function _mintAndApprove(uint256 amountA, uint256 amountB) internal {
        if (amountA > 0) {
            tokenA.mint(user, amountA);
        }
        if (amountB > 0) {
            tokenB.mint(user, amountB);
        }

        vm.startPrank(user);
        if (amountA > 0) {
            tokenA.approve(address(zap), amountA);
        }
        if (amountB > 0) {
            tokenB.approve(address(zap), amountB);
        }
        vm.stopPrank();
    }

    function _pair(TestERC20 token0, TestERC20 token1) internal view returns (IUniswapV2Pair) {
        return IUniswapV2Pair(factory.getPair(address(token0), address(token1)));
    }

    function _assertNoZapTokenDust(TestERC20 token0, TestERC20 token1) internal view {
        assertEq(token0.balanceOf(address(zap)), 0, "zap token0 dust");
        assertEq(token1.balanceOf(address(zap)), 0, "zap token1 dust");
    }

    function _assertNoSelector(string memory signature) internal {
        (bool ok,) = address(zap).call(abi.encodeWithSignature(signature));
        assertFalse(ok, signature);
    }
}

interface IERC20Like {
    function balanceOf(address owner) external view returns (uint256);
}

interface IWrappedNativeLike {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
}
