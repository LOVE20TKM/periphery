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
    struct ZapQuote {
        bool hasLiquidity;
        bool willSwap;
        address swapTokenIn;
        address swapTokenOut;
        uint256 amountToSwap;
        uint256 amountOutFromSwap;
        uint256 amountAUsed;
        uint256 amountBUsed;
        uint256 liquidity;
        uint256 reserveAAfter;
        uint256 reserveBAfter;
    }

    struct ZapNativeQuote {
        bool hasLiquidity;
        bool willSwap;
        address swapTokenIn;
        address swapTokenOut;
        uint256 amountToSwap;
        uint256 amountOutFromSwap;
        uint256 amountTokenUsed;
        uint256 amountNativeUsed;
        uint256 liquidity;
        uint256 reserveTokenAfter;
        uint256 reserveNativeAfter;
    }

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

    function quoteZapToken(address tokenA, address tokenB, uint256 amountAIn, uint256 amountBIn)
        external
        view
        returns (ZapQuote memory quote);

    function quoteZapNativeToken(address token, uint256 amountTokenIn, uint256 amountNativeIn)
        external
        view
        returns (ZapNativeQuote memory quote);

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

contract RouterStub {
    address public factory;
    address public WETH;

    constructor(address factory_, address weth_) {
        factory = factory_;
        WETH = weth_;
    }
}

contract NativeSender {
    function sendNative(address to) external payable {
        (bool ok, bytes memory returndata) = to.call{value: msg.value}("");
        if (!ok) {
            assembly {
                revert(add(returndata, 32), mload(returndata))
            }
        }
    }
}

contract RejectNativeZapCaller {
    IUniswapV2Zap public zap;

    constructor(IUniswapV2Zap zap_) {
        zap = zap_;
    }

    function zapNativeToken(address token, address to, uint256 deadline) external payable {
        zap.zapNativeToken{value: msg.value}(token, 0, 1, 1, 1, to, deadline);
    }

    receive() external payable {
        revert("NATIVE_REJECTED");
    }
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

    error ZeroRouter();
    error ZeroFactory();
    error ZeroWrappedNativeToken();
    error NativeTokenNotAccepted();
    error ZeroTokenA();
    error ZeroTokenB();
    error ZeroToken();
    error IdenticalTokens();
    error WrappedNativeToken();
    error ZeroTo();
    error ZeroAmount();
    error InsufficientLiquidityMinted();
    error PairMissingOrEmpty();
    error InsufficientLiquidity();
    error AmountTooLarge();
    error NativeTransferFailed();

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

    function testConstructorRevertsForInvalidRouterConfig() public {
        vm.expectRevert(ZeroRouter.selector);
        deployCode("out/UniswapV2Zap.sol/UniswapV2Zap.json", abi.encode(address(0)));

        RouterStub zeroFactoryRouter = new RouterStub(address(0), weth);
        vm.expectRevert(ZeroFactory.selector);
        deployCode("out/UniswapV2Zap.sol/UniswapV2Zap.json", abi.encode(address(zeroFactoryRouter)));

        RouterStub zeroWethRouter = new RouterStub(address(factory), address(0));
        vm.expectRevert(ZeroWrappedNativeToken.selector);
        deployCode("out/UniswapV2Zap.sol/UniswapV2Zap.json", abi.encode(address(zeroWethRouter)));
    }

    function testZapTokenParamValidationReverts() public {
        IUniswapV2Zap.ZapTokenParams memory params = IUniswapV2Zap.ZapTokenParams({
            tokenA: address(tokenA),
            tokenB: address(tokenB),
            amountAIn: 1,
            amountBIn: 0,
            amountAMin: 1,
            amountBMin: 1,
            liquidityMin: 1,
            to: recipient,
            deadline: block.timestamp + 1
        });

        params.tokenA = address(0);
        vm.expectRevert(ZeroTokenA.selector);
        zap.zapToken(params);

        params.tokenA = address(tokenA);
        params.tokenB = address(0);
        vm.expectRevert(ZeroTokenB.selector);
        zap.zapToken(params);

        params.tokenB = address(tokenA);
        vm.expectRevert(IdenticalTokens.selector);
        zap.zapToken(params);

        params.tokenB = address(tokenB);
        params.to = address(0);
        vm.expectRevert(ZeroTo.selector);
        zap.zapToken(params);

        params.to = recipient;
        params.amountAIn = 0;
        params.amountBIn = 0;
        vm.expectRevert(ZeroAmount.selector);
        zap.zapToken(params);
    }

    function testZapNativeTokenParamValidationReverts() public {
        vm.expectRevert(ZeroToken.selector);
        zap.zapNativeToken(address(0), 0, 1, 1, 1, recipient, block.timestamp + 1);

        vm.expectRevert(WrappedNativeToken.selector);
        zap.zapNativeToken(weth, 0, 1, 1, 1, recipient, block.timestamp + 1);

        vm.expectRevert(ZeroTo.selector);
        zap.zapNativeToken{value: 1}(address(tokenA), 0, 1, 1, 1, address(0), block.timestamp + 1);

        vm.expectRevert(ZeroAmount.selector);
        zap.zapNativeToken(address(tokenA), 0, 1, 1, 1, recipient, block.timestamp + 1);
    }

    function testQuoteParamValidationReverts() public {
        vm.expectRevert(ZeroTokenA.selector);
        zap.quoteZapToken(address(0), address(tokenB), 1, 0);

        vm.expectRevert(ZeroTokenB.selector);
        zap.quoteZapToken(address(tokenA), address(0), 1, 0);

        vm.expectRevert(IdenticalTokens.selector);
        zap.quoteZapToken(address(tokenA), address(tokenA), 1, 0);

        vm.expectRevert(ZeroAmount.selector);
        zap.quoteZapToken(address(tokenA), address(tokenB), 0, 0);

        vm.expectRevert(ZeroToken.selector);
        zap.quoteZapNativeToken(address(0), 1, 0);

        vm.expectRevert(WrappedNativeToken.selector);
        zap.quoteZapNativeToken(weth, 1, 0);

        vm.expectRevert(ZeroAmount.selector);
        zap.quoteZapNativeToken(address(tokenA), 0, 0);
    }

    function testReceiveRejectsNonWrappedNative() public {
        NativeSender sender = new NativeSender();

        vm.expectRevert(NativeTokenNotAccepted.selector);
        sender.sendNative{value: 1}(address(zap));
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

    function testFuzzQuoteZapTokenMatchesActualForRandomPools(
        uint256 reserveASeed,
        uint256 reserveBSeed,
        uint256 amountASeed,
        uint256 amountBSeed,
        uint8 mode
    ) public {
        TestERC20 tokenX = new TestERC20("Token X", "TKX");
        TestERC20 tokenY = new TestERC20("Token Y", "TKY");
        uint256 reserveA = bound(reserveASeed, 1_000 ether, 1_000_000 ether);
        uint256 reserveB = bound(reserveBSeed, 1_000 ether, 1_000_000 ether);
        _seedPair(tokenX, tokenY, reserveA, reserveB);

        uint256 amountAIn = mode % 3 == 1 ? 0 : bound(amountASeed, 1 ether, reserveA / 2);
        uint256 amountBIn = mode % 3 == 0 ? 0 : bound(amountBSeed, 1 ether, reserveB / 2);

        IUniswapV2Zap.ZapQuote memory quote = zap.quoteZapToken(address(tokenX), address(tokenY), amountAIn, amountBIn);
        tokenX.mint(user, amountAIn);
        tokenY.mint(user, amountBIn);
        vm.startPrank(user);
        tokenX.approve(address(zap), amountAIn);
        tokenY.approve(address(zap), amountBIn);
        (uint256 amountA, uint256 amountB, uint256 liquidity) = zap.zapToken(
            IUniswapV2Zap.ZapTokenParams({
                tokenA: address(tokenX),
                tokenB: address(tokenY),
                amountAIn: amountAIn,
                amountBIn: amountBIn,
                amountAMin: 1,
                amountBMin: 1,
                liquidityMin: 1,
                to: recipient,
                deadline: block.timestamp + 1
            })
        );
        vm.stopPrank();

        (uint256 reserveAAfter, uint256 reserveBAfter) = _pairReserves(tokenX, tokenY);
        assertEq(amountA, quote.amountAUsed, "amount A used");
        assertEq(amountB, quote.amountBUsed, "amount B used");
        assertEq(liquidity, quote.liquidity, "liquidity");
        assertEq(reserveAAfter, quote.reserveAAfter, "reserve A after");
        assertEq(reserveBAfter, quote.reserveBAfter, "reserve B after");
        _assertUserTokenBalancesMatchQuote(tokenX, tokenY, amountAIn, amountBIn, quote);
        _assertNoZapTokenDust(tokenX, tokenY);
    }

    function testFuzzQuoteZapNativeTokenMatchesActual(uint256 amountTokenSeed, uint256 amountNativeSeed, uint8 mode)
        public
    {
        uint256 amountTokenIn = mode % 2 == 0 ? 0 : bound(amountTokenSeed, 1 ether, 100 ether);
        uint256 amountNativeIn = mode % 2 == 0 ? bound(amountNativeSeed, 1 ether, 20 ether) : 0;

        IUniswapV2Zap.ZapNativeQuote memory quote =
            zap.quoteZapNativeToken(address(tokenA), amountTokenIn, amountNativeIn);

        tokenA.mint(user, amountTokenIn);
        vm.startPrank(user);
        tokenA.approve(address(zap), amountTokenIn);
        (uint256 amountToken, uint256 amountNative, uint256 liquidity) = zap.zapNativeToken{value: amountNativeIn}(
            address(tokenA), amountTokenIn, 1, 1, 1, recipient, block.timestamp + 1
        );
        vm.stopPrank();

        (uint256 reserveNativeAfter, uint256 reserveTokenAfter) = _pairReserves(weth, address(tokenA));
        assertEq(amountToken, quote.amountTokenUsed, "token used");
        assertEq(amountNative, quote.amountNativeUsed, "native used");
        assertEq(liquidity, quote.liquidity, "liquidity");
        assertEq(reserveTokenAfter, quote.reserveTokenAfter, "reserve token after");
        assertEq(reserveNativeAfter, quote.reserveNativeAfter, "reserve native after");
        assertEq(
            tokenA.balanceOf(user),
            amountTokenIn + (quote.swapTokenOut == address(tokenA) ? quote.amountOutFromSwap : 0) - amountToken
                - (quote.swapTokenIn == address(tokenA) ? quote.amountToSwap : 0),
            "user token refund"
        );
        assertEq(
            user.balance,
            100 ether + (quote.swapTokenOut == weth ? quote.amountOutFromSwap : 0) - amountNative
                - (quote.swapTokenIn == weth ? quote.amountToSwap : 0),
            "user native refund"
        );
        assertEq(tokenA.balanceOf(address(zap)), 0, "zap token dust");
        assertEq(IERC20Like(weth).balanceOf(address(zap)), 0, "zap weth dust");
        assertEq(address(zap).balance, 0, "zap eth dust");
    }

    function testQuoteZapTokenMatchesZapResult() public {
        IUniswapV2Zap.ZapQuote memory quote = _assertQuoteMatchesZapResult(100 ether, 0);

        assertTrue(quote.hasLiquidity, "has liquidity");
        assertTrue(quote.willSwap, "will swap");
        assertEq(quote.swapTokenIn, address(tokenA), "swap token in");
        assertEq(quote.swapTokenOut, address(tokenB), "swap token out");
        assertGt(quote.amountToSwap, 0, "amount to swap");
        assertGt(quote.amountOutFromSwap, 0, "amount out from swap");
    }

    function testQuoteZapTokenMatchesZapResultWhenSwappingTokenB() public {
        IUniswapV2Zap.ZapQuote memory quote = _assertQuoteMatchesZapResult(0, 100 ether);

        assertTrue(quote.hasLiquidity, "has liquidity");
        assertTrue(quote.willSwap, "will swap");
        assertEq(quote.swapTokenIn, address(tokenB), "swap token in");
        assertEq(quote.swapTokenOut, address(tokenA), "swap token out");
        assertGt(quote.amountToSwap, 0, "amount to swap");
        assertGt(quote.amountOutFromSwap, 0, "amount out from swap");
    }

    function testQuoteZapTokenUsesAllInputsWhenAlreadyBalanced() public {
        IUniswapV2Zap.ZapQuote memory quote = _assertQuoteMatchesZapResult(10 ether, 10 ether);

        assertTrue(quote.hasLiquidity, "has liquidity");
        assertFalse(quote.willSwap, "will swap");
        assertEq(quote.amountToSwap, 0, "amount to swap");
        assertEq(quote.amountOutFromSwap, 0, "amount out from swap");
        assertEq(quote.amountAUsed, 10 ether, "amount A used");
        assertEq(quote.amountBUsed, 10 ether, "amount B used");
    }

    function testQuoteZapTokenNewPairMinimumMintableLiquidity() public {
        IUniswapV2Zap.ZapQuote memory quote = zap.quoteZapToken(address(tokenC), address(tokenD), 1001, 1001);

        assertFalse(quote.hasLiquidity, "has liquidity");
        assertFalse(quote.willSwap, "will swap");
        assertEq(quote.amountAUsed, 1001, "amount A used");
        assertEq(quote.amountBUsed, 1001, "amount B used");
        assertEq(quote.liquidity, 1, "liquidity");
        assertEq(quote.reserveAAfter, 1001, "reserve A after");
        assertEq(quote.reserveBAfter, 1001, "reserve B after");

        tokenC.mint(user, 1001);
        tokenD.mint(user, 1001);
        vm.startPrank(user);
        tokenC.approve(address(zap), 1001);
        tokenD.approve(address(zap), 1001);
        (uint256 amountA, uint256 amountB, uint256 liquidity) = zap.zapToken(
            IUniswapV2Zap.ZapTokenParams({
                tokenA: address(tokenC),
                tokenB: address(tokenD),
                amountAIn: 1001,
                amountBIn: 1001,
                amountAMin: 1,
                amountBMin: 1,
                liquidityMin: 1,
                to: recipient,
                deadline: block.timestamp + 1
            })
        );
        vm.stopPrank();

        assertEq(amountA, quote.amountAUsed, "amount A used after zap");
        assertEq(amountB, quote.amountBUsed, "amount B used after zap");
        assertEq(liquidity, 1, "minimum LP minted");
    }

    function testQuoteZapTokenUsesCallerTokenOrder() public view {
        IUniswapV2Zap.ZapQuote memory quote = zap.quoteZapToken(address(tokenB), address(tokenA), 100 ether, 0);

        assertTrue(quote.hasLiquidity, "has liquidity");
        assertTrue(quote.willSwap, "will swap");
        assertEq(quote.swapTokenIn, address(tokenB), "swap token in");
        assertEq(quote.swapTokenOut, address(tokenA), "swap token out");
        assertGt(quote.reserveAAfter, 0, "reserve A after");
        assertGt(quote.reserveBAfter, 0, "reserve B after");
    }

    function testQuoteZapNativeTokenUsesWrappedNativeAsTokenA() public view {
        IUniswapV2Zap.ZapNativeQuote memory quote = zap.quoteZapNativeToken(address(tokenA), 0, 10 ether);

        assertTrue(quote.hasLiquidity, "has liquidity");
        assertTrue(quote.willSwap, "will swap");
        assertEq(quote.swapTokenIn, weth, "swap token in");
        assertEq(quote.swapTokenOut, address(tokenA), "swap token out");
        assertGt(quote.amountNativeUsed, 0, "native used");
        assertGt(quote.amountTokenUsed, 0, "token used");
    }

    function testQuoteZapNativeTokenLiquidityMatchesZapResult() public {
        IUniswapV2Zap.ZapNativeQuote memory quote = zap.quoteZapNativeToken(address(tokenA), 0, 10 ether);

        vm.prank(user);
        (uint256 amountToken, uint256 amountNative, uint256 liquidity) =
            zap.zapNativeToken{value: 10 ether}(address(tokenA), 0, 1, 1, 1, recipient, block.timestamp + 1);

        assertEq(amountToken, quote.amountTokenUsed, "token used");
        assertEq(amountNative, quote.amountNativeUsed, "native used");
        assertEq(liquidity, quote.liquidity, "liquidity");
    }

    function testQuoteZapTokenLiquidityMatchesZapResultWhenFeeOn() public {
        factory.setFeeTo(address(0xfee));
        _mintAndApprove(10 ether, 10 ether);

        vm.prank(user);
        zap.zapToken(
            IUniswapV2Zap.ZapTokenParams({
                tokenA: address(tokenA),
                tokenB: address(tokenB),
                amountAIn: 10 ether,
                amountBIn: 10 ether,
                amountAMin: 1,
                amountBMin: 1,
                liquidityMin: 1,
                to: recipient,
                deadline: block.timestamp + 1
            })
        );

        address pair = factory.getPair(address(tokenA), address(tokenB));
        tokenA.mint(pair, 100 ether);
        IUniswapV2Pair(pair).sync();

        IUniswapV2Zap.ZapQuote memory quote = zap.quoteZapToken(address(tokenA), address(tokenB), 10 ether, 0);
        _mintAndApprove(10 ether, 0);

        vm.prank(user);
        (,, uint256 liquidity) = zap.zapToken(
            IUniswapV2Zap.ZapTokenParams({
                tokenA: address(tokenA),
                tokenB: address(tokenB),
                amountAIn: 10 ether,
                amountBIn: 0,
                amountAMin: 1,
                amountBMin: 1,
                liquidityMin: 1,
                to: recipient,
                deadline: block.timestamp + 1
            })
        );

        assertEq(liquidity, quote.liquidity, "liquidity");
    }

    function testQuoteZapTokenSingleSidedSmallPoolUsesFormulaPrecision() public {
        uint256 reserveA = 2_857_911_946_302;
        uint256 reserveB = 2_330_969_554_244_432_846;
        uint256 amountBIn = 6_992_700_000_000_000_000;

        tokenC.mint(address(this), reserveA);
        tokenD.mint(address(this), reserveB);
        tokenC.approve(address(router), reserveA);
        tokenD.approve(address(router), reserveB);
        router.addLiquidity(
            address(tokenC), address(tokenD), reserveA, reserveB, 1, 1, address(this), block.timestamp + 1
        );

        IUniswapV2Pair pair = _pair(tokenC, tokenD);
        uint256 expectedSwap = _formulaSwapAmount(reserveB, reserveA, amountBIn, 0);
        uint256 expectedAmountOut = router.getAmountOut(expectedSwap, reserveB, reserveA);
        uint256 expectedLiquidity = (expectedAmountOut * pair.totalSupply()) / (reserveA - expectedAmountOut);

        IUniswapV2Zap.ZapQuote memory quote = zap.quoteZapToken(address(tokenC), address(tokenD), 0, amountBIn);

        assertEq(quote.amountToSwap, expectedSwap, "amount to swap");
        assertEq(quote.amountOutFromSwap, expectedAmountOut, "amount out");
        assertEq(quote.liquidity, expectedLiquidity, "liquidity");
    }

    function testQuoteZapTokenUnbalancedPairUsesFormulaPrecision() public view {
        uint256 amountAIn = 200 ether;
        uint256 amountBIn = 10 ether;
        uint256 expectedSwap = _formulaSwapAmount(1000 ether, 1000 ether, amountAIn, amountBIn);
        uint256 expectedAmountOut = router.getAmountOut(expectedSwap, 1000 ether, 1000 ether);

        IUniswapV2Zap.ZapQuote memory quote = zap.quoteZapToken(address(tokenA), address(tokenB), amountAIn, amountBIn);

        assertEq(quote.amountToSwap, expectedSwap, "amount to swap");
        assertEq(quote.amountOutFromSwap, expectedAmountOut, "amount out");
    }

    function testQuoteZapTokenRevertsWhenInputCannotMintLiquidity() public {
        address pair = factory.getPair(address(tokenA), address(tokenB));
        tokenA.mint(pair, 1000 ether);
        tokenB.mint(pair, 1000 ether);
        IUniswapV2Pair(pair).sync();

        vm.expectRevert(InsufficientLiquidityMinted.selector);
        zap.quoteZapToken(address(tokenA), address(tokenB), 1, 1);
    }

    function testQuoteZapTokenRevertsWhenNewPairInputCannotMintLiquidity() public {
        vm.expectRevert(InsufficientLiquidityMinted.selector);
        zap.quoteZapToken(address(tokenC), address(tokenD), 1, 1);
    }

    function testQuoteZapTokenRevertsWhenAmountTooLarge() public {
        vm.expectRevert(AmountTooLarge.selector);
        zap.quoteZapToken(address(tokenA), address(tokenB), uint256(type(uint112).max) + 1, 0);
    }

    function testQuoteZapTokenHandlesMalformedPairStates() public {
        factory.createPair(address(tokenC), address(tokenD));
        vm.expectRevert(PairMissingOrEmpty.selector);
        zap.quoteZapToken(address(tokenC), address(tokenD), 1, 0);

        TestERC20 tokenE = new TestERC20("Token E", "TKE");
        TestERC20 tokenF = new TestERC20("Token F", "TKF");
        address oneSidedPair = factory.createPair(address(tokenE), address(tokenF));
        tokenE.mint(oneSidedPair, 1 ether);
        IUniswapV2Pair(oneSidedPair).sync();
        vm.expectRevert(InsufficientLiquidity.selector);
        zap.quoteZapToken(address(tokenE), address(tokenF), 1 ether, 0);

        TestERC20 tokenG = new TestERC20("Token G", "TKG");
        TestERC20 tokenH = new TestERC20("Token H", "TKH");
        address syncedPair = factory.createPair(address(tokenG), address(tokenH));
        tokenG.mint(syncedPair, 1001);
        tokenH.mint(syncedPair, 1001);
        IUniswapV2Pair(syncedPair).sync();

        IUniswapV2Zap.ZapQuote memory quote = zap.quoteZapToken(address(tokenG), address(tokenH), 1001, 1001);
        assertEq(quote.liquidity, 1, "liquidity");
    }

    function testQuoteZapTokenFeeOnWithoutGrowthDoesNotMintProtocolFee() public {
        factory.setFeeTo(address(0xfee));

        IUniswapV2Zap.ZapQuote memory zeroKLastQuote =
            zap.quoteZapToken(address(tokenA), address(tokenB), 10 ether, 10 ether);
        assertEq(zeroKLastQuote.liquidity, 10 ether, "zero kLast liquidity");

        tokenA.mint(address(this), 10 ether);
        tokenB.mint(address(this), 10 ether);
        tokenA.approve(address(router), 10 ether);
        tokenB.approve(address(router), 10 ether);
        router.addLiquidity(
            address(tokenA), address(tokenB), 10 ether, 10 ether, 1, 1, address(this), block.timestamp + 1
        );

        IUniswapV2Zap.ZapQuote memory noGrowthQuote =
            zap.quoteZapToken(address(tokenA), address(tokenB), 10 ether, 10 ether);
        assertEq(noGrowthQuote.liquidity, 10 ether, "no growth liquidity");
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

    function testZapNativeTokenRevertsWhenNativeRefundFails() public {
        RejectNativeZapCaller caller = new RejectNativeZapCaller(zap);

        vm.expectRevert(NativeTransferFailed.selector);
        caller.zapNativeToken{value: 10 ether}(address(tokenA), recipient, block.timestamp + 1);
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

    function testAmountAMinReverts() public {
        IUniswapV2Zap.ZapQuote memory quote = zap.quoteZapToken(address(tokenA), address(tokenB), 100 ether, 0);
        _mintAndApprove(100 ether, 0);

        vm.expectRevert(bytes("UniswapV2Router: INSUFFICIENT_A_AMOUNT"));
        vm.prank(user);
        zap.zapToken(
            IUniswapV2Zap.ZapTokenParams({
                tokenA: address(tokenA),
                tokenB: address(tokenB),
                amountAIn: 100 ether,
                amountBIn: 0,
                amountAMin: quote.amountAUsed + 1,
                amountBMin: 1,
                liquidityMin: 1,
                to: recipient,
                deadline: block.timestamp + 1
            })
        );
    }

    function testAmountBMinReverts() public {
        _mintAndApprove(10 ether, 10 ether);

        vm.expectRevert(bytes("UniswapV2Router: INSUFFICIENT_B_AMOUNT"));
        vm.prank(user);
        zap.zapToken(
            IUniswapV2Zap.ZapTokenParams({
                tokenA: address(tokenA),
                tokenB: address(tokenB),
                amountAIn: 10 ether,
                amountBIn: 10 ether,
                amountAMin: 1,
                amountBMin: type(uint256).max,
                liquidityMin: 1,
                to: recipient,
                deadline: block.timestamp + 1
            })
        );
    }

    function testNativeAmountMinReverts() public {
        tokenA.mint(user, 100 ether);
        vm.prank(user);
        tokenA.approve(address(zap), 100 ether);

        vm.expectRevert(bytes("UniswapV2Router: INSUFFICIENT_B_AMOUNT"));
        vm.prank(user);
        zap.zapNativeToken{value: 10 ether}(
            address(tokenA), 100 ether, type(uint256).max, 1, 1, recipient, block.timestamp + 1
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

    function _seedPair(TestERC20 token0, TestERC20 token1, uint256 amount0, uint256 amount1) internal {
        token0.mint(address(this), amount0);
        token1.mint(address(this), amount1);
        token0.approve(address(router), amount0);
        token1.approve(address(router), amount1);
        router.addLiquidity(
            address(token0), address(token1), amount0, amount1, 1, 1, address(this), block.timestamp + 1
        );
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
        return _pair(address(token0), address(token1));
    }

    function _pair(address token0, address token1) internal view returns (IUniswapV2Pair) {
        return IUniswapV2Pair(factory.getPair(token0, token1));
    }

    function _pairReserves(TestERC20 token0, TestERC20 token1)
        internal
        view
        returns (uint256 reserve0, uint256 reserve1)
    {
        return _pairReserves(address(token0), address(token1));
    }

    function _pairReserves(address token0, address token1) internal view returns (uint256 reserve0, uint256 reserve1) {
        IUniswapV2Pair pair = _pair(token0, token1);
        (uint112 reserveA, uint112 reserveB,) = pair.getReserves();
        (reserve0, reserve1) =
            token0 == pair.token0() ? (uint256(reserveA), uint256(reserveB)) : (uint256(reserveB), uint256(reserveA));
    }

    function _assertQuoteMatchesZapResult(uint256 amountAIn, uint256 amountBIn)
        internal
        returns (IUniswapV2Zap.ZapQuote memory quote)
    {
        (uint256 reserveABefore, uint256 reserveBBefore) = _pairReserves(tokenA, tokenB);
        quote = zap.quoteZapToken(address(tokenA), address(tokenB), amountAIn, amountBIn);

        if (quote.willSwap) {
            if (quote.swapTokenIn == address(tokenA)) {
                assertEq(
                    quote.amountOutFromSwap,
                    router.getAmountOut(quote.amountToSwap, reserveABefore, reserveBBefore),
                    "router amount out"
                );
            } else {
                assertEq(
                    quote.amountOutFromSwap,
                    router.getAmountOut(quote.amountToSwap, reserveBBefore, reserveABefore),
                    "router amount out"
                );
            }
        }

        _mintAndApprove(amountAIn, amountBIn);

        vm.prank(user);
        (uint256 amountA, uint256 amountB, uint256 liquidity) = zap.zapToken(
            IUniswapV2Zap.ZapTokenParams({
                tokenA: address(tokenA),
                tokenB: address(tokenB),
                amountAIn: amountAIn,
                amountBIn: amountBIn,
                amountAMin: 1,
                amountBMin: 1,
                liquidityMin: 1,
                to: recipient,
                deadline: block.timestamp + 1
            })
        );

        (uint256 reserveA, uint256 reserveB) = _pairReserves(tokenA, tokenB);
        assertEq(amountA, quote.amountAUsed, "amount A used");
        assertEq(amountB, quote.amountBUsed, "amount B used");
        assertEq(liquidity, quote.liquidity, "liquidity");
        assertEq(reserveA, quote.reserveAAfter, "reserve A after");
        assertEq(reserveB, quote.reserveBAfter, "reserve B after");
        _assertNoZapTokenDust(tokenA, tokenB);
    }

    function _assertNoZapTokenDust(TestERC20 token0, TestERC20 token1) internal view {
        assertEq(token0.balanceOf(address(zap)), 0, "zap token0 dust");
        assertEq(token1.balanceOf(address(zap)), 0, "zap token1 dust");
    }

    function _assertUserTokenBalancesMatchQuote(
        TestERC20 token0,
        TestERC20 token1,
        uint256 amount0In,
        uint256 amount1In,
        IUniswapV2Zap.ZapQuote memory quote
    ) internal view {
        assertEq(
            token0.balanceOf(user),
            amount0In + (quote.swapTokenOut == address(token0) ? quote.amountOutFromSwap : 0) - quote.amountAUsed
                - (quote.swapTokenIn == address(token0) ? quote.amountToSwap : 0),
            "user token0 refund"
        );
        assertEq(
            token1.balanceOf(user),
            amount1In + (quote.swapTokenOut == address(token1) ? quote.amountOutFromSwap : 0) - quote.amountBUsed
                - (quote.swapTokenIn == address(token1) ? quote.amountToSwap : 0),
            "user token1 refund"
        );
    }

    function _assertNoSelector(string memory signature) internal {
        (bool ok,) = address(zap).call(abi.encodeWithSignature(signature));
        assertFalse(ok, signature);
    }

    function _formulaSwapAmount(uint256 reserveIn, uint256 reserveOut, uint256 amountIn, uint256 amountOutAlready)
        internal
        pure
        returns (uint256)
    {
        uint256 imbalance = amountIn * reserveOut - reserveIn * amountOutAlready;
        uint256 denominator = reserveOut + amountOutAlready;
        return (
            sqrt(reserveIn * reserveIn * 3_988_009 + (reserveIn * imbalance * 3_988_000) / denominator)
                - reserveIn * 1_997
        ) / 1_994;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

interface IERC20Like {
    function balanceOf(address owner) external view returns (uint256);
}

interface IWrappedNativeLike {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
}
