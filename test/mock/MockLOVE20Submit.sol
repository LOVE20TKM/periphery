// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "../../src/interfaces/ILOVE20Submit.sol";

/**
 * @title MockILOVE20Submit
 * @dev LOVE20Submit接口的模拟实现
 */
contract MockILOVE20Submit is ILOVE20Submit {
    function actionsCount(address) external pure override returns (uint256) {
        return 3;
    }

    function actionsAtIndex(
        address,
        uint256 index
    ) external view override returns (ActionInfo memory) {
        return this.actionInfo(address(0), index);
    }

    function actionSubmitsCount(
        address,
        uint256
    ) external pure override returns (uint256) {
        return 2;
    }

    function actionSubmitsAtIndex(
        address,
        uint256,
        uint256 index
    ) external view override returns (ActionSubmitInfo memory) {
        return ActionSubmitInfo({actionId: index, submitter: address(this)});
    }

    function actionInfo(
        address tokenAddress,
        uint256 actionId
    ) external view override returns (ActionInfo memory) {
        string[] memory verificationKeys = new string[](2);
        verificationKeys[0] = "twitter";
        verificationKeys[1] = "github";

        string[] memory verificationInfoGuides = new string[](2);
        verificationInfoGuides[0] = "Please input your twitter username";
        verificationInfoGuides[1] = "Please input your github username";

        ActionInfo memory actionInfo_ = ActionInfo({
            head: ActionHead({
                id: actionId,
                author: address(this),
                createAtBlock: block.number
            }),
            body: ActionBody({
                minStake: 10,
                maxRandomAccounts: 10,
                whiteListAddress: tokenAddress,
                title: "test",
                verificationRule: "test",
                verificationKeys: verificationKeys,
                verificationInfoGuides: verificationInfoGuides
            })
        });
        return actionInfo_;
    }

    // 添加缺失的接口实现
    function MAX_VERIFICATION_KEY_LENGTH() external pure returns (uint256) {
        return 50;
    }

    function SUBMIT_MIN_PER_THOUSAND() external pure returns (uint256) {
        return 100;
    }

    function authorActionIdsCount(address) external pure returns (uint256) {
        return 2;
    }

    function authorActionIdsAtIndex(
        address,
        uint256
    ) external pure returns (uint256) {
        return 1;
    }

    function canJoin(address, uint256, address) external pure returns (bool) {
        return true;
    }

    function canSubmit(address, address) external pure returns (bool) {
        return true;
    }

    // IPhase接口实现
    function originBlocks() external pure returns (uint256) {
        return 100;
    }

    function phaseBlocks() external pure returns (uint256) {
        return 1000;
    }

    function currentRound() external pure returns (uint256) {
        return 1;
    }

    function roundByBlockNumber(uint256) external pure returns (uint256) {
        return 1;
    }

    function stakeAddress() external pure returns (address) {
        return address(0x123);
    }

    function submit(address, uint256) external pure {
        // Mock implementation
    }

    function isSubmitted(
        address tokenAddress,
        uint256 round,
        uint256 actionId
    ) external pure returns (bool) {
        tokenAddress;
        round;
        actionId;
        return false;
    }

    function submitInfo(
        address tokenAddress,
        uint256 round,
        uint256 actionId
    ) external pure returns (ActionSubmitInfo memory) {
        tokenAddress;
        round;
        actionId;
        return
            ActionSubmitInfo({submitter: address(0x123), actionId: actionId});
    }

    function submitInfoBySubmitter(
        address tokenAddress,
        uint256 round,
        address submitter
    ) external pure returns (ActionSubmitInfo memory) {
        tokenAddress;
        round;
        submitter;
        return ActionSubmitInfo({submitter: submitter, actionId: 1});
    }

    function submitNewAction(
        address tokenAddress,
        ActionBody calldata actionBody
    ) external pure returns (uint256 actionId) {
        tokenAddress;
        actionBody;
        return 1;
    }

    function authorActionIdsCount(
        address tokenAddress,
        address author
    ) external pure returns (uint256) {
        tokenAddress;
        author;
        return 2;
    }

    function authorActionIdsAtIndex(
        address tokenAddress,
        address author,
        uint256 index
    ) external pure returns (uint256) {
        tokenAddress;
        author;
        index;
        return index + 1;
    }
}
