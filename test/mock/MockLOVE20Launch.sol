// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "../../src/interfaces/ILOVE20Launch.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title MockILOVE20Launch
 * @dev LOVE20Launch interface mock implementation
 */
contract MockILOVE20Launch is ILOVE20Launch {
    address public parentTokenAddress;
    address public stakeAddress;

    constructor(address _parentTokenAddress, address _stakeAddress) {
        parentTokenAddress = _parentTokenAddress;
        stakeAddress = _stakeAddress;
    }

    function launchInfo(
        address
    ) external view override returns (LaunchInfo memory launchInfo_) {
        return
            LaunchInfo({
                parentTokenAddress: parentTokenAddress,
                parentTokenFundraisingGoal: 1000000,
                secondHalfMinBlocks: 5000,
                launchAmount: 500000,
                startBlock: 100,
                secondHalfStartBlock: 5100,
                endBlock: 1000,
                hasEnded: false,
                participantCount: 100,
                totalContributed: 1000000,
                totalExtraRefunded: 50000
            });
    }

    function tokenAddressBySymbol(
        string memory symbol
    ) external view override returns (address) {
        symbol;
        return address(parentTokenAddress);
    }

    function contribute(
        address tokenAddress,
        uint256 parentTokenAmount,
        address to
    ) external virtual override {
        // Mock implementation - just store values for testing
        tokenAddress;
        parentTokenAmount;
        to;
    }

    function tokensCount() external pure override returns (uint256) {
        return 2;
    }

    function tokensAtIndex(uint256) external view override returns (address) {
        return parentTokenAddress;
    }

    function childTokensCount(
        address
    ) external pure override returns (uint256) {
        return 2;
    }

    function childTokensAtIndex(
        address,
        uint256
    ) external view override returns (address) {
        return parentTokenAddress;
    }

    function launchingTokensCount() external pure override returns (uint256) {
        return 1;
    }

    function launchingTokensAtIndex(
        uint256
    ) external view override returns (address) {
        return parentTokenAddress;
    }

    function launchedTokensCount() external pure override returns (uint256) {
        return 1;
    }

    function launchedTokensAtIndex(
        uint256
    ) external view override returns (address) {
        return parentTokenAddress;
    }

    function launchingChildTokensCount(
        address
    ) external pure override returns (uint256) {
        return 1;
    }

    function launchingChildTokensAtIndex(
        address,
        uint256
    ) external view override returns (address) {
        return parentTokenAddress;
    }

    function launchedChildTokensCount(
        address
    ) external pure override returns (uint256) {
        return 1;
    }

    function launchedChildTokensAtIndex(
        address,
        uint256
    ) external view override returns (address) {
        return parentTokenAddress;
    }

    function participatedTokensCount(
        address
    ) external pure override returns (uint256) {
        return 1;
    }

    function participatedTokensAtIndex(
        address,
        uint256
    ) external view override returns (address) {
        return parentTokenAddress;
    }

    // Add missing interface implementations
    function FIRST_PARENT_TOKEN_FUNDRAISING_GOAL()
        external
        pure
        returns (uint256)
    {
        return 1000000;
    }

    function MIN_GOV_REWARD_MINTS_TO_LAUNCH() external pure returns (uint256) {
        return 100;
    }

    function PARENT_TOKEN_FUNDRAISING_GOAL() external pure returns (uint256) {
        return 1000000;
    }

    function SECOND_HALF_MIN_BLOCKS() external pure returns (uint256 blocks) {
        return 5000;
    }

    function TOKEN_SYMBOL_LENGTH() external pure returns (uint256 length) {
        return 10;
    }

    function WITHDRAW_WAITING_BLOCKS() external pure returns (uint256 blocks) {
        return 1000;
    }

    function childTokensByLauncherCount(
        address
    ) external pure returns (uint256) {
        return 1;
    }

    function childTokensByLauncherAtIndex(
        address,
        uint256
    ) external view returns (address) {
        return parentTokenAddress;
    }

    function claimInfo(
        address,
        address
    ) external pure returns (uint256, uint256, bool) {
        return (1000, 500, false);
    }

    function contributed(address, address) external pure returns (uint256) {
        return 500;
    }

    function isLOVE20Token(address) external pure returns (bool) {
        return true;
    }

    function lastContributedBlock(
        address,
        address
    ) external view returns (uint256) {
        return block.number - 10;
    }

    function mintAddress() external pure returns (address address_) {
        return address(0x456);
    }

    function submitAddress() external pure returns (address address_) {
        return address(0x789);
    }

    function tokenFactoryAddress() external pure returns (address address_) {
        return address(0xabc);
    }

    function withdraw(address) external pure {
        // Mock implementation
    }

    function claim(
        address tokenAddress
    ) external pure returns (uint256 receivedTokenAmount, uint256 extraRefund) {
        tokenAddress;
        return (1000, 500);
    }

    function launchToken(
        string memory tokenSymbol,
        address parentTokenAddress_
    ) external pure returns (address tokenAddress) {
        tokenSymbol;
        parentTokenAddress_;
        return address(0x123);
    }

    function remainingLaunchCount(
        address parentTokenAddress_,
        address account
    ) external pure returns (uint256 count) {
        parentTokenAddress_;
        account;
        return 3;
    }

    function childTokensByLauncherCount(
        address parentTokenAddress_,
        address account
    ) external pure returns (uint256 count) {
        parentTokenAddress_;
        account;
        return 2;
    }

    function childTokensByLauncherAtIndex(
        address parentTokenAddress_,
        address account,
        uint256 index
    ) external pure returns (address tokenAddress) {
        parentTokenAddress_;
        account;
        index;
        return address(0x456);
    }
}

/**
 * @title MockILOVE20LaunchForHub
 * @dev Extended Launch mock, supporting full contribute function implementation
 */
contract MockILOVE20LaunchForHub is MockILOVE20Launch {
    uint256 public lastContributeAmount;
    address public lastContributeToken;
    address public lastContributeTo;
    address public wethAddress;

    constructor(
        address _parentTokenAddress,
        address _stakeAddress
    ) MockILOVE20Launch(_parentTokenAddress, _stakeAddress) {}

    function setWethAddress(address _wethAddress) external {
        wethAddress = _wethAddress;
    }

    function contribute(
        address tokenAddress,
        uint256 amount,
        address to
    ) external override {
        lastContributeToken = tokenAddress;
        lastContributeAmount = amount;
        lastContributeTo = to;

        // Actually transfer WETH to launch contract
        if (wethAddress != address(0)) {
            IERC20 WETH = IERC20(wethAddress);
            WETH.transferFrom(msg.sender, address(this), amount);
        }
    }
}
