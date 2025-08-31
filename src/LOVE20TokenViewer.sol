// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {IUniswapV2Pair} from "../lib/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./interfaces/ILOVE20Launch.sol";
import "./interfaces/ILOVE20Token.sol";
import "./interfaces/ILOVE20Stake.sol";
import "./interfaces/ILOVE20SLToken.sol";
import "./interfaces/ILOVE20Vote.sol";
import "./interfaces/ILOVE20Submit.sol";
import "./interfaces/ILOVE20Join.sol";
import "./interfaces/ILOVE20Verify.sol";
import "./interfaces/ILOVE20Mint.sol";

struct TokenInfo {
    address tokenAddress;
    string name;
    string symbol;
    uint256 decimals;
    address parentTokenAddress;
    string parentTokenSymbol;
    string parentTokenName;
    address slAddress;
    address stAddress;
    address uniswapV2PairAddress;
    uint256 initialStakeRound;
}

struct PairInfoWithAccount {
    address pairAddress;
    uint256 balanceOfToken;
    uint256 balanceOfParentToken;
    uint256 pairReserveToken;
    uint256 pairReserveParentToken;
}


struct TokenStats {
    // Minting status
    uint256 maxSupply; // token.maxSupply()
    uint256 totalSupply; // token.totalSupply()
    uint256 reservedAvailable; // mintContract.reservedAvailable()
    uint256 rewardAvailable; // mintContract.rewardAvailable()
    // Minted token allocation
    uint256 pairReserveParentToken; // IUniswapV2Pair.getReserves()
    uint256 pairReserveToken; // IUniswapV2Pair.getReserves()
    uint256 totalLpSupply; // IUniswapV2Pair.getReserves()
    uint256 stakedTokenAmountForSt; // token.balanceOf(stContract)
    uint256 joinedTokenAmount; // token.balanceOf(joinContract)
    // SL/ST status
    uint256 totalSLSupply; // slContract.totalSupply()
    uint256 totalSTSupply; // stContract.totalSupply()
    uint256 parentTokenAmountForSl; // from slContract.tokenAmounts()
    uint256 tokenAmountForSl; // from slContract.tokenAmounts()
    // Launch status
    uint256 parentPool; //token.parentPool()
    // Governance status
    uint256 finishedRounds; // voteContract.currentRound() - stakeContract.initialStakeRound() - 2
    uint256 actionsCount; // submitContract.actionsCount()
    uint256 joiningActionsCount; // joinContract.votedActionIdsCount()
    // Child token status
    uint256 childTokensCount; // launchContract.childTokensCount()
    uint256 launchingChildTokensCount; // launchContract.launchingChildTokensCount()
    uint256 launchedChildTokensCount; // launchContract.launchedChildTokensCount()
}

contract LOVE20TokenViewer {
    address public launchAddress;
    address public stakeAddress;
    address public submitAddress;
    address public voteAddress;
    address public joinAddress;
    address public verifyAddress;
    address public mintAddress;

    bool public initialized;

    constructor() {}

    function init(
        address launchAddress_,
        address stakeAddress_,
        address submitAddress_,
        address voteAddress_,
        address joinAddress_,
        address verifyAddress_,
        address mintAddress_
    ) external {
        require(!initialized, "Already initialized");

        launchAddress = launchAddress_;
        stakeAddress = stakeAddress_;
        submitAddress = submitAddress_;
        voteAddress = voteAddress_;
        joinAddress = joinAddress_;
        verifyAddress = verifyAddress_;
        mintAddress = mintAddress_;

        initialized = true;
    }

    //---------------- Token related functions ----------------
    function tokensByPage(uint256 start, uint256 end) external view returns (address[] memory tokens) {
        uint256 totalTokens = ILOVE20Launch(launchAddress).tokensCount();
        require(start <= end, "Invalid range");
        require(start < totalTokens, "Out of range");
        if (end >= totalTokens) {
            end = totalTokens - 1;
        }

        tokens = new address[](end - start + 1);
        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = ILOVE20Launch(launchAddress).tokensAtIndex(start + i);
        }
    }

    function childTokensByPage(address parentTokenAddress, uint256 start, uint256 end)
        external
        view
        returns (address[] memory tokens)
    {
        require(start <= end, "Invalid range");

        uint256 totalTokens = ILOVE20Launch(launchAddress).childTokensCount(parentTokenAddress);
        if (totalTokens == 0) {
            return new address[](0);
        }
        require(start < totalTokens, "Out of range");
        if (end >= totalTokens) {
            end = totalTokens - 1;
        }

        tokens = new address[](end - start + 1);
        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = ILOVE20Launch(launchAddress).childTokensAtIndex(parentTokenAddress, start + i);
        }
    }

    function launchingTokensByPage(uint256 start, uint256 end) external view returns (address[] memory tokens) {
        require(start <= end, "Invalid range");

        uint256 totalTokens = ILOVE20Launch(launchAddress).launchingTokensCount();
        if (totalTokens == 0) {
            return new address[](0);
        }
        require(start < totalTokens, "Out of range");
        if (end >= totalTokens) {
            end = totalTokens - 1;
        }

        tokens = new address[](end - start + 1);
        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = ILOVE20Launch(launchAddress).launchingTokensAtIndex(start + i);
        }
    }

    function launchedTokensByPage(uint256 start, uint256 end) external view returns (address[] memory tokens) {
        require(start <= end, "Invalid range");

        uint256 totalTokens = ILOVE20Launch(launchAddress).launchedTokensCount();
        if (totalTokens == 0) {
            return new address[](0);
        }
        require(start < totalTokens, "Out of range");
        if (end >= totalTokens) {
            end = totalTokens - 1;
        }

        tokens = new address[](end - start + 1);
        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = ILOVE20Launch(launchAddress).launchedTokensAtIndex(start + i);
        }
    }

    function launchingChildTokensByPage(address parentTokenAddress, uint256 start, uint256 end)
        external
        view
        returns (address[] memory tokens)
    {
        require(start <= end, "Invalid range");

        uint256 totalTokens = ILOVE20Launch(launchAddress).launchingChildTokensCount(parentTokenAddress);
        if (totalTokens == 0) {
            return new address[](0);
        }
        require(start < totalTokens, "Out of range");
        if (end >= totalTokens) {
            end = totalTokens - 1;
        }

        tokens = new address[](end - start + 1);
        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = ILOVE20Launch(launchAddress).launchingChildTokensAtIndex(parentTokenAddress, start + i);
        }
    }

    function launchedChildTokensByPage(address parentTokenAddress, uint256 start, uint256 end)
        external
        view
        returns (address[] memory tokens)
    {
        require(start <= end, "Invalid range");

        uint256 totalTokens = ILOVE20Launch(launchAddress).launchedChildTokensCount(parentTokenAddress);
        if (totalTokens == 0) {
            return new address[](0);
        }
        require(start < totalTokens, "Out of range");
        if (end >= totalTokens) {
            end = totalTokens - 1;
        }

        tokens = new address[](end - start + 1);
        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = ILOVE20Launch(launchAddress).launchedChildTokensAtIndex(parentTokenAddress, start + i);
        }
    }

    function participatedTokensByPage(address account, uint256 start, uint256 end)
        external
        view
        returns (address[] memory tokens)
    {
        require(start <= end, "Invalid range");

        uint256 totalTokens = ILOVE20Launch(launchAddress).participatedTokensCount(account);
        if (totalTokens == 0) {
            return new address[](0);
        }
        require(start < totalTokens, "Out of range");
        if (end >= totalTokens) {
            end = totalTokens - 1;
        }

        tokens = new address[](end - start + 1);
        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = ILOVE20Launch(launchAddress).participatedTokensAtIndex(account, start + i);
        }
    }

    //---------------- Token Detail related functions ----------------

    function tokenDetail(address tokenAddress)
        public
        view
        returns (TokenInfo memory tokenInfo, LaunchInfo memory launchInfo)
    {
        require(tokenAddress != address(0), "Invalid token address");

        launchInfo = ILOVE20Launch(launchAddress).launchInfo(tokenAddress);
        ILOVE20Token love20 = ILOVE20Token(tokenAddress);
        tokenInfo = TokenInfo({
            tokenAddress: tokenAddress,
            name: love20.name(),
            symbol: love20.symbol(),
            decimals: love20.decimals(),
            parentTokenAddress: launchInfo.parentTokenAddress,
            parentTokenSymbol: ILOVE20Token(launchInfo.parentTokenAddress).symbol(),
            parentTokenName: ILOVE20Token(launchInfo.parentTokenAddress).name(),
            slAddress: love20.slAddress(),
            stAddress: love20.stAddress(),
            uniswapV2PairAddress: ILOVE20SLToken(love20.slAddress()).uniswapV2Pair(),
            initialStakeRound: ILOVE20Stake(stakeAddress).initialStakeRound(tokenAddress)
        });
        return (tokenInfo, launchInfo);
    }

    function tokenDetailBySymbol(string memory symbol)
        external
        view
        returns (TokenInfo memory tokenInfo, LaunchInfo memory launchInfo)
    {
        address tokenAddress = ILOVE20Launch(launchAddress).tokenAddressBySymbol(symbol);
        return tokenDetail(tokenAddress);
    }

    function tokenDetails(address[] memory tokenAddresses)
        external
        view
        returns (TokenInfo[] memory tokenInfos, LaunchInfo[] memory launchInfos)
    {
        tokenInfos = new TokenInfo[](tokenAddresses.length);
        launchInfos = new LaunchInfo[](tokenAddresses.length);
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            (tokenInfos[i], launchInfos[i]) = tokenDetail(tokenAddresses[i]);
        }

        return (tokenInfos, launchInfos);
    }

    function tokenPairInfoWithAccount(address account, address tokenAddress)
        external
        view
        returns (PairInfoWithAccount memory pairInfo)
    {
        address parentTokenAddress = ILOVE20Token(tokenAddress).parentTokenAddress();
        address slAddress = ILOVE20Token(tokenAddress).slAddress();
        address pairAddress;
        uint256 reserveToken;
        uint256 reserveParentToken;

        // get reserve0 and reserve1
        {
            pairAddress = ILOVE20SLToken(slAddress).uniswapV2Pair();
            (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pairAddress).getReserves();
            address token0 = IUniswapV2Pair(pairAddress).token0();
            address token1 = IUniswapV2Pair(pairAddress).token1();

            if (token0 == tokenAddress && token1 == parentTokenAddress) {
                reserveToken = reserve0;
                reserveParentToken = reserve1;
            } else if (token0 == parentTokenAddress && token1 == tokenAddress) {
                reserveToken = reserve1;
                reserveParentToken = reserve0;
            } else {
                revert("token address or parent token address is not correct");
            }
        }

        // get other info
        pairInfo = PairInfoWithAccount({
            pairAddress: pairAddress,
            balanceOfToken: ILOVE20Token(tokenAddress).balanceOf(account),
            balanceOfParentToken: ILOVE20Token(parentTokenAddress).balanceOf(account),
            pairReserveToken: reserveToken,
            pairReserveParentToken: reserveParentToken
        });
    }


    //---------------- Token statistics related functions ----------------
    function tokenStatistics(address tokenAddress) external view returns (TokenStats memory) {
        ILOVE20Token love20 = ILOVE20Token(tokenAddress);
        ILOVE20SLToken sl = ILOVE20SLToken(love20.slAddress());

        TokenStats memory stats;

        // Basic token info
        stats.maxSupply = love20.maxSupply();
        stats.totalSupply = love20.totalSupply();
        stats.reservedAvailable = ILOVE20Mint(mintAddress).reservedAvailable(tokenAddress);
        stats.rewardAvailable = ILOVE20Mint(mintAddress).rewardAvailable(tokenAddress);

        // Pair reserves
        address pairAddress = sl.uniswapV2Pair();
        if (pairAddress != address(0)) {
            (stats.pairReserveToken, stats.pairReserveParentToken, stats.totalLpSupply) = sl.uniswapV2PairReserves();
        }

        // Token balances
        stats.stakedTokenAmountForSt = love20.balanceOf(love20.stAddress());
        stats.joinedTokenAmount = love20.balanceOf(joinAddress);

        // SL/ST totals
        stats.totalSLSupply = sl.totalSupply();
        stats.totalSTSupply = ILOVE20Token(love20.stAddress()).totalSupply();

        // SL withdrawable amounts
        if (stats.totalSLSupply > 0) {
            (stats.tokenAmountForSl, stats.parentTokenAmountForSl,,) = sl.tokenAmounts();
        }

        // Launch info
        stats.parentPool = love20.parentPool();

        // Governance info
        uint256 currentRound = ILOVE20Vote(voteAddress).currentRound();
        uint256 initialRound = ILOVE20Stake(stakeAddress).initialStakeRound(tokenAddress);
        if (currentRound > initialRound + 2) {
            stats.finishedRounds = currentRound - initialRound - 2;
        }

        stats.actionsCount = ILOVE20Submit(submitAddress).actionsCount(tokenAddress);

        uint256 joinRound = ILOVE20Join(joinAddress).currentRound();
        stats.joiningActionsCount = ILOVE20Vote(voteAddress).votedActionIdsCount(tokenAddress, joinRound);

        // Child token status
        stats.childTokensCount = ILOVE20Launch(launchAddress).childTokensCount(tokenAddress);
        stats.launchingChildTokensCount = ILOVE20Launch(launchAddress).launchingChildTokensCount(tokenAddress);
        stats.launchedChildTokensCount = ILOVE20Launch(launchAddress).launchedChildTokensCount(tokenAddress);

        return stats;
    }
}
