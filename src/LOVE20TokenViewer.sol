// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.17;

import {IUniswapV2Pair} from "../lib/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./interfaces/ILOVE20Launch.sol";
import "./interfaces/ILOVE20Token.sol";
import "./interfaces/ILOVE20Stake.sol";
import "./interfaces/ILOVE20SLToken.sol";

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
    uint256 allowanceOfToken;
    uint256 allowanceOfParentToken;
    uint256 pairReserveToken;
    uint256 pairReserveParentToken;
}

contract LOVE20TokenViewer {
    address public launchAddress;
    address public stakeAddress;

    bool public initialized;

    constructor() {}

    function init(address launchAddress_, address stakeAddress_) external {
        require(!initialized, "Already initialized");

        launchAddress = launchAddress_;
        stakeAddress = stakeAddress_;

        initialized = true;
    }

    //---------------- Token related functions ----------------
    function tokensByPage(
        uint256 start,
        uint256 end
    ) external view returns (address[] memory tokens) {
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

    function childTokensByPage(
        address parentTokenAddress,
        uint256 start,
        uint256 end
    ) external view returns (address[] memory tokens) {
        require(start <= end, "Invalid range");

        uint256 totalTokens = ILOVE20Launch(launchAddress).childTokensCount(
            parentTokenAddress
        );
        if (totalTokens == 0) {
            return new address[](0);
        }
        require(start < totalTokens, "Out of range");
        if (end >= totalTokens) {
            end = totalTokens - 1;
        }

        tokens = new address[](end - start + 1);
        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = ILOVE20Launch(launchAddress).childTokensAtIndex(
                parentTokenAddress,
                start + i
            );
        }
    }

    function launchingTokensByPage(
        uint start,
        uint end
    ) external view returns (address[] memory tokens) {
        require(start <= end, "Invalid range");

        uint256 totalTokens = ILOVE20Launch(launchAddress)
            .launchingTokensCount();
        if (totalTokens == 0) {
            return new address[](0);
        }
        require(start < totalTokens, "Out of range");
        if (end >= totalTokens) {
            end = totalTokens - 1;
        }

        tokens = new address[](end - start + 1);
        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = ILOVE20Launch(launchAddress).launchingTokensAtIndex(
                start + i
            );
        }
    }

    function launchedTokensByPage(
        uint start,
        uint end
    ) external view returns (address[] memory tokens) {
        require(start <= end, "Invalid range");

        uint256 totalTokens = ILOVE20Launch(launchAddress)
            .launchedTokensCount();
        if (totalTokens == 0) {
            return new address[](0);
        }
        require(start < totalTokens, "Out of range");
        if (end >= totalTokens) {
            end = totalTokens - 1;
        }

        tokens = new address[](end - start + 1);
        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = ILOVE20Launch(launchAddress).launchedTokensAtIndex(
                start + i
            );
        }
    }

    function launchingChildTokensByPage(
        address parentTokenAddress,
        uint start,
        uint end
    ) external view returns (address[] memory tokens) {
        require(start <= end, "Invalid range");

        uint256 totalTokens = ILOVE20Launch(launchAddress)
            .launchingChildTokensCount(parentTokenAddress);
        if (totalTokens == 0) {
            return new address[](0);
        }
        require(start < totalTokens, "Out of range");
        if (end >= totalTokens) {
            end = totalTokens - 1;
        }

        tokens = new address[](end - start + 1);
        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = ILOVE20Launch(launchAddress)
                .launchingChildTokensAtIndex(parentTokenAddress, start + i);
        }
    }

    function launchedChildTokensByPage(
        address parentTokenAddress,
        uint start,
        uint end
    ) external view returns (address[] memory tokens) {
        require(start <= end, "Invalid range");

        uint256 totalTokens = ILOVE20Launch(launchAddress)
            .launchedChildTokensCount(parentTokenAddress);
        if (totalTokens == 0) {
            return new address[](0);
        }
        require(start < totalTokens, "Out of range");
        if (end >= totalTokens) {
            end = totalTokens - 1;
        }

        tokens = new address[](end - start + 1);
        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = ILOVE20Launch(launchAddress).launchedChildTokensAtIndex(
                parentTokenAddress,
                start + i
            );
        }
    }

    function participatedTokensByPage(
        address account,
        uint start,
        uint end
    ) external view returns (address[] memory tokens) {
        require(start <= end, "Invalid range");

        uint256 totalTokens = ILOVE20Launch(launchAddress)
            .participatedTokensCount(account);
        if (totalTokens == 0) {
            return new address[](0);
        }
        require(start < totalTokens, "Out of range");
        if (end >= totalTokens) {
            end = totalTokens - 1;
        }

        tokens = new address[](end - start + 1);
        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = ILOVE20Launch(launchAddress).participatedTokensAtIndex(
                account,
                start + i
            );
        }
    }

    //---------------- Token Detail related functions ----------------

    function tokenDetail(
        address tokenAddress
    )
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
            parentTokenSymbol: ILOVE20Token(launchInfo.parentTokenAddress)
                .symbol(),
            parentTokenName: ILOVE20Token(launchInfo.parentTokenAddress).name(),
            slAddress: love20.slAddress(),
            stAddress: love20.stAddress(),
            uniswapV2PairAddress: ILOVE20SLToken(love20.slAddress())
                .uniswapV2Pair(),
            initialStakeRound: ILOVE20Stake(stakeAddress).initialStakeRound(
                tokenAddress
            )
        });
        return (tokenInfo, launchInfo);
    }

    function tokenDetailBySymbol(
        string memory symbol
    )
        external
        view
        returns (TokenInfo memory tokenInfo, LaunchInfo memory launchInfo)
    {
        address tokenAddress = ILOVE20Launch(launchAddress)
            .tokenAddressBySymbol(symbol);
        return tokenDetail(tokenAddress);
    }

    function tokenDetails(
        address[] memory tokenAddresses
    )
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

    function tokenPairInfoWithAccount(
        address account,
        address tokenAddress
    ) external view returns (PairInfoWithAccount memory pairInfo) {
        address parentTokenAddress = ILOVE20Token(tokenAddress)
            .parentTokenAddress();
        address slAddress = ILOVE20Token(tokenAddress).slAddress();
        address pairAddress;
        uint256 reserveToken;
        uint256 reserveParentToken;

        // get reserve0 and reserve1
        {
            pairAddress = ILOVE20SLToken(slAddress).uniswapV2Pair();
            (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairAddress)
                .getReserves();
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
            balanceOfParentToken: ILOVE20Token(parentTokenAddress).balanceOf(
                account
            ),
            allowanceOfToken: ILOVE20Token(tokenAddress).allowance(
                account,
                stakeAddress
            ),
            allowanceOfParentToken: ILOVE20Token(parentTokenAddress).allowance(
                account,
                stakeAddress
            ),
            pairReserveToken: reserveToken,
            pairReserveParentToken: reserveParentToken
        });
    }
}
