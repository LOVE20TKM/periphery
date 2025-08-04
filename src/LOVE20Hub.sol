// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.17;

import "./interfaces/ILOVE20Core.sol";

interface IWETH9 {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
}

interface IERC20 {
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

contract LOVE20Hub {
    address public WETHAddress;
    address public launchAddress;
    address public stakeAddress;
    address public submitAddress;
    address public voteAddress;
    address public joinAddress;
    address public verifyAddress;
    address public mintAddress;

    bool public initialized;

    event ContributeWithETH(
        address indexed tokenAddress,
        address indexed to,
        uint256 ethAmount,
        uint256 wethAmount
    );

    constructor() {}

    function init(
        address WETHAddress_,
        address launchAddress_,
        address stakeAddress_,
        address submitAddress_,
        address voteAddress_,
        address joinAddress_,
        address verifyAddress_,
        address mintAddress_
    ) external {
        require(!initialized, "Already initialized");

        WETHAddress = WETHAddress_;
        launchAddress = launchAddress_;
        stakeAddress = stakeAddress_;
        submitAddress = submitAddress_;
        voteAddress = voteAddress_;
        joinAddress = joinAddress_;
        verifyAddress = verifyAddress_;
        mintAddress = mintAddress_;

        initialized = true;
    }

    function contributeWithETH(
        address tokenAddress,
        address to
    ) external payable {
        require(initialized, "Hub not initialized");
        require(msg.value > 0, "Must send ETH");
        require(tokenAddress != address(0), "Invalid token address");
        require(to != address(0), "Invalid recipient address");

        IWETH9(WETHAddress).deposit{value: msg.value}();
        IERC20(WETHAddress).approve(launchAddress, msg.value);
        ILOVE20Launch(launchAddress).contribute(tokenAddress, msg.value, to);

        emit ContributeWithETH(tokenAddress, to, msg.value, msg.value);
    }

    // Get reserves of the pair contract
    function _getReserves(
        address tokenAddress
    ) internal view returns (uint256 tokenReserve, uint256 parentTokenReserve) {
        address slAddress = ILOVE20Token(tokenAddress).slAddress();
        address pairAddress = ILOVE20SLToken(slAddress).uniswapV2Pair();

        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pairAddress)
            .getReserves();

        address token0 = IUniswapV2Pair(pairAddress).token0();
        if (tokenAddress == token0) {
            (tokenReserve, parentTokenReserve) = (
                uint256(reserve0),
                uint256(reserve1)
            );
        } else {
            (tokenReserve, parentTokenReserve) = (
                uint256(reserve1),
                uint256(reserve0)
            );
        }
    }

    // Calculate optimal liquidity amounts considering slippage
    function _calculateOptimalAmounts(
        address tokenAddress,
        uint256 tokenAmountDesired,
        uint256 parentTokenAmountDesired,
        uint256 tokenAmountMin,
        uint256 parentTokenAmountMin
    ) internal view returns (uint256 tokenAmount, uint256 parentTokenAmount) {
        (uint256 tokenReserve, uint256 parentTokenReserve) = _getReserves(
            tokenAddress
        );

        if (tokenReserve == 0 && parentTokenReserve == 0) {
            // Use desired amounts if first liquidity addition
            (tokenAmount, parentTokenAmount) = (
                tokenAmountDesired,
                parentTokenAmountDesired
            );
        } else {
            // Calculate optimal amounts based on current reserves ratio
            uint256 parentTokenAmountOptimal = (tokenAmountDesired *
                parentTokenReserve) / tokenReserve;

            if (parentTokenAmountOptimal <= parentTokenAmountDesired) {
                require(
                    parentTokenAmountOptimal >= parentTokenAmountMin,
                    "LOVE20Hub: INSUFFICIENT_PARENT_TOKEN_AMOUNT"
                );
                (tokenAmount, parentTokenAmount) = (
                    tokenAmountDesired,
                    parentTokenAmountOptimal
                );
            } else {
                uint256 tokenAmountOptimal = (parentTokenAmountDesired *
                    tokenReserve) / parentTokenReserve;
                require(
                    tokenAmountOptimal <= tokenAmountDesired,
                    "LOVE20Hub: OPTIMAL_AMOUNT_EXCEEDED"
                );
                require(
                    tokenAmountOptimal >= tokenAmountMin,
                    "LOVE20Hub: INSUFFICIENT_TOKEN_AMOUNT"
                );
                (tokenAmount, parentTokenAmount) = (
                    tokenAmountOptimal,
                    parentTokenAmountDesired
                );
            }
        }
    }

    function stakeLiquidity(
        address tokenAddress,
        uint256 tokenAmount,
        uint256 parentTokenAmount,
        uint256 tokenAmountMin,
        uint256 parentTokenAmountMin,
        uint256 promisedWaitingPhases,
        address to
    ) external returns (uint256 govVotesAdded, uint256 slAmountAdded) {
        require(tokenAddress != address(0), "Invalid token address");
        require(to != address(0), "Invalid recipient address");
        require(tokenAmount > 0, "Token amount must be greater than 0");
        require(
            parentTokenAmount > 0,
            "Parent token amount must be greater than 0"
        );

        address parentTokenAddress = ILOVE20Token(tokenAddress)
            .parentTokenAddress();
        require(
            parentTokenAddress != address(0),
            "Parent token address not found"
        );

        // Calculate optimal amounts considering slippage
        (
            uint256 optimalTokenAmount,
            uint256 optimalParentTokenAmount
        ) = _calculateOptimalAmounts(
                tokenAddress,
                tokenAmount,
                parentTokenAmount,
                tokenAmountMin,
                parentTokenAmountMin
            );

        // Transfer tokens from sender, and approve to stake contract
        IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            optimalTokenAmount
        );
        IERC20(parentTokenAddress).transferFrom(
            msg.sender,
            address(this),
            optimalParentTokenAmount
        );
        IERC20(tokenAddress).approve(stakeAddress, optimalTokenAmount);
        IERC20(parentTokenAddress).approve(
            stakeAddress,
            optimalParentTokenAmount
        );

        //
        (govVotesAdded, slAmountAdded) = ILOVE20Stake(stakeAddress)
            .stakeLiquidity(
                tokenAddress,
                optimalTokenAmount,
                optimalParentTokenAmount,
                promisedWaitingPhases,
                to
            );
    }
}
