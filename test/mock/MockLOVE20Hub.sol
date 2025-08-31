// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ILOVE20HubEvents, ILOVE20Hub} from "../../src/interfaces/ILOVE20Hub.sol";

/**
 * @title MockLOVE20Hub
 * @dev Minimal mock implementation for ILOVE20Hub used in tests
 */
contract MockLOVE20Hub is ILOVE20HubEvents, ILOVE20Hub {
    address public override WETHAddress;
    address public override launchAddress;
    address public override stakeAddress;
    address public override submitAddress;
    address public override voteAddress;
    address public override joinAddress;
    address public override verifyAddress;
    address public override mintAddress;

    bool public override initialized;

    function init(
        address WETHAddress_,
        address launchAddress_,
        address stakeAddress_,
        address submitAddress_,
        address voteAddress_,
        address joinAddress_,
        address verifyAddress_,
        address mintAddress_
    ) external override {
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

    function contributeFirstTokenWithETH(address tokenAddress, address to) external payable override {
        // No-op for tests; only emit event to simulate behavior
        emit ContributeFirstTokenWithETH({tokenAddress: tokenAddress, to: to, amount: msg.value});
    }

    function stakeLiquidity(
        address tokenAddress,
        uint256 tokenAmount,
        uint256 parentTokenAmount,
        uint256, /*tokenAmountMin*/
        uint256, /*parentTokenAmountMin*/
        uint256 promisedWaitingPhases,
        address to
    ) external override returns (uint256 govVotesAdded, uint256 slAmountAdded) {
        // Return fixed values suitable for tests and emit event
        govVotesAdded = 100;
        slAmountAdded = 200;

        emit StakeLiquidity({
            tokenAddress: tokenAddress,
            to: to,
            tokenAmountDesired: tokenAmount,
            parentTokenAmountDesired: parentTokenAmount,
            tokenAmountReal: tokenAmount,
            parentTokenAmountReal: parentTokenAmount,
            promisedWaitingPhases: promisedWaitingPhases
        });
    }
}
