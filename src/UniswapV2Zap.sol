// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {IUniswapV2Factory} from "../lib/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "../lib/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router02} from "../lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface IWrappedNative {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}

contract UniswapV2Zap is ReentrancyGuard {
    using SafeERC20 for IERC20;

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
    error PairMissingOrEmpty();
    error InsufficientLiquidity();
    error InvalidRatio();
    error InsufficientLiquidityMinted();
    error NativeTransferFailed();

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

    IUniswapV2Router02 public immutable router;
    address public immutable factory;
    address public immutable wrappedNativeToken;

    constructor(address router_) {
        if (router_ == address(0)) revert ZeroRouter();

        router = IUniswapV2Router02(router_);
        factory = IUniswapV2Router02(router_).factory();
        wrappedNativeToken = IUniswapV2Router02(router_).WETH();

        if (factory == address(0)) revert ZeroFactory();
        if (wrappedNativeToken == address(0)) revert ZeroWrappedNativeToken();
    }

    receive() external payable {
        if (msg.sender != wrappedNativeToken) revert NativeTokenNotAccepted();
    }

    function zapToken(ZapTokenParams calldata params)
        external
        nonReentrant
        returns (uint256 amountA, uint256 amountB, uint256 liquidity)
    {
        _validatePair(params.tokenA, params.tokenB);
        if (params.to == address(0)) revert ZeroTo();
        if (params.amountAIn == 0 && params.amountBIn == 0) revert ZeroAmount();

        uint256 balanceABefore = IERC20(params.tokenA).balanceOf(address(this));
        uint256 balanceBBefore = IERC20(params.tokenB).balanceOf(address(this));

        if (params.amountAIn > 0) {
            IERC20(params.tokenA).safeTransferFrom(msg.sender, address(this), params.amountAIn);
        }
        if (params.amountBIn > 0) {
            IERC20(params.tokenB).safeTransferFrom(msg.sender, address(this), params.amountBIn);
        }

        (amountA, amountB, liquidity) = _zapPair(
            ZapTokenParams({
                tokenA: params.tokenA,
                tokenB: params.tokenB,
                amountAIn: params.amountAIn,
                amountBIn: params.amountBIn,
                amountAMin: params.amountAMin,
                amountBMin: params.amountBMin,
                liquidityMin: params.liquidityMin,
                to: params.to,
                deadline: params.deadline
            })
        );

        _refundTokenExcess(params.tokenA, msg.sender, balanceABefore);
        _refundTokenExcess(params.tokenB, msg.sender, balanceBBefore);

        emit ZapToken(msg.sender, params.tokenA, params.tokenB, params.to, amountA, amountB, liquidity);
    }

    function zapNativeToken(
        address token,
        uint256 amountTokenIn,
        uint256 amountTokenMin,
        uint256 amountNativeMin,
        uint256 liquidityMin,
        address to,
        uint256 deadline
    ) external payable nonReentrant returns (uint256 amountToken, uint256 amountNative, uint256 liquidity) {
        if (token == address(0)) revert ZeroToken();
        if (token == wrappedNativeToken) revert WrappedNativeToken();
        if (to == address(0)) revert ZeroTo();
        if (msg.value == 0 && amountTokenIn == 0) revert ZeroAmount();

        uint256 tokenBalanceBefore = IERC20(token).balanceOf(address(this));
        uint256 wrappedNativeBalanceBefore = IERC20(wrappedNativeToken).balanceOf(address(this));

        if (amountTokenIn > 0) {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amountTokenIn);
        }
        if (msg.value > 0) {
            IWrappedNative(wrappedNativeToken).deposit{value: msg.value}();
        }

        (amountNative, amountToken, liquidity) = _zapPair(
            ZapTokenParams({
                tokenA: wrappedNativeToken,
                tokenB: token,
                amountAIn: msg.value,
                amountBIn: amountTokenIn,
                amountAMin: amountNativeMin,
                amountBMin: amountTokenMin,
                liquidityMin: liquidityMin,
                to: to,
                deadline: deadline
            })
        );

        _refundTokenExcess(token, msg.sender, tokenBalanceBefore);
        _refundWrappedNativeExcessAsNative(msg.sender, wrappedNativeBalanceBefore);

        emit ZapNativeToken(msg.sender, token, to, amountToken, amountNative, liquidity);
    }

    function _zapPair(ZapTokenParams memory params)
        internal
        returns (uint256 amountA, uint256 amountB, uint256 liquidity)
    {
        (uint256 reserveA, uint256 reserveB, bool hasLiquidity) = _reserves(params.tokenA, params.tokenB);

        if (!hasLiquidity) {
            if (params.amountAIn == 0 || params.amountBIn == 0) revert PairMissingOrEmpty();
        } else if (params.amountAIn * reserveB >= reserveA * params.amountBIn) {
            (params.amountAIn, params.amountBIn) = _swapExcess(
                params.tokenA, params.tokenB, reserveA, reserveB, params.amountAIn, params.amountBIn, params.deadline
            );
        } else {
            (params.amountBIn, params.amountAIn) = _swapExcess(
                params.tokenB, params.tokenA, reserveB, reserveA, params.amountBIn, params.amountAIn, params.deadline
            );
        }

        _approveToken(params.tokenA, params.amountAIn);
        _approveToken(params.tokenB, params.amountBIn);

        (amountA, amountB, liquidity) = router.addLiquidity(
            params.tokenA,
            params.tokenB,
            params.amountAIn,
            params.amountBIn,
            params.amountAMin,
            params.amountBMin,
            params.to,
            params.deadline
        );

        if (liquidity < params.liquidityMin) revert InsufficientLiquidityMinted();

        _approveToken(params.tokenA, 0);
        _approveToken(params.tokenB, 0);
    }

    function _swapExcess(
        address tokenIn,
        address tokenOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 amountIn,
        uint256 amountOutAlready,
        uint256 deadline
    ) internal returns (uint256 amountInAfterSwap, uint256 amountOutAfterSwap) {
        uint256 amountToSwap = _calcAmountToSwap(reserveIn, reserveOut, amountIn, amountOutAlready);
        amountInAfterSwap = amountIn;
        amountOutAfterSwap = amountOutAlready;

        if (amountToSwap == 0) {
            return (amountInAfterSwap, amountOutAfterSwap);
        }

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        _approveToken(tokenIn, amountToSwap);
        uint256[] memory amounts = router.swapExactTokensForTokens(amountToSwap, 1, path, address(this), deadline);

        amountInAfterSwap = amountIn - amountToSwap;
        amountOutAfterSwap = amountOutAlready + amounts[1];
    }

    function _calcAmountToSwap(uint256 reserveIn, uint256 reserveOut, uint256 amountIn, uint256 amountOutAlready)
        internal
        pure
        returns (uint256 amountToSwap)
    {
        if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();
        if (amountIn * reserveOut < reserveIn * amountOutAlready) revert InvalidRatio();

        uint256 left = 0;
        uint256 right = amountIn;
        uint256 tolerance = amountIn / 10000;
        if (tolerance == 0) tolerance = 1;

        uint256 reserveInTimes1000 = reserveIn * 1000;
        uint256 reserveProductTimes1000 = reserveInTimes1000 * reserveOut;

        while (left + tolerance < right) {
            amountToSwap = (left + right) / 2;

            uint256 newReserveIn = reserveIn + amountToSwap;
            uint256 newReserveOut = reserveProductTimes1000 / (reserveInTimes1000 + 997 * amountToSwap);
            uint256 newAmountIn = amountIn - amountToSwap;
            uint256 newAmountOut = amountOutAlready + (reserveOut - newReserveOut);

            if (newAmountIn * newReserveOut >= newReserveIn * newAmountOut) {
                left = amountToSwap;
            } else {
                right = amountToSwap;
            }
        }

        return left;
    }

    function _reserves(address tokenA, address tokenB)
        internal
        view
        returns (uint256 reserveA, uint256 reserveB, bool hasLiquidity)
    {
        address pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
        if (pair == address(0)) {
            return (0, 0, false);
        }

        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(pair).getReserves();
        if (reserve0 == 0 && reserve1 == 0) {
            return (0, 0, false);
        }

        address token0 = IUniswapV2Pair(pair).token0();
        (reserveA, reserveB) =
            tokenA == token0 ? (uint256(reserve0), uint256(reserve1)) : (uint256(reserve1), uint256(reserve0));
        hasLiquidity = true;
    }

    function _validatePair(address tokenA, address tokenB) internal pure {
        if (tokenA == address(0)) revert ZeroTokenA();
        if (tokenB == address(0)) revert ZeroTokenB();
        if (tokenA == tokenB) revert IdenticalTokens();
    }

    function _approveToken(address token, uint256 amount) internal {
        IERC20(token).forceApprove(address(router), amount);
    }

    function _refundTokenExcess(address token, address to, uint256 balanceBefore) internal {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > balanceBefore) {
            IERC20(token).safeTransfer(to, balance - balanceBefore);
        }
    }

    function _refundWrappedNativeExcessAsNative(address to, uint256 balanceBefore) internal {
        uint256 balance = IERC20(wrappedNativeToken).balanceOf(address(this));
        if (balance > balanceBefore) {
            uint256 refund = balance - balanceBefore;
            IWrappedNative(wrappedNativeToken).withdraw(refund);
            _transferNative(to, refund);
        }
    }

    function _transferNative(address to, uint256 amount) internal {
        (bool success,) = to.call{value: amount}("");
        if (!success) revert NativeTransferFailed();
    }
}
