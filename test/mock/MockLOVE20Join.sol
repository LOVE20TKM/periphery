// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "../../src/interfaces/ILOVE20Join.sol";

/**
 * @title MockILOVE20Join
 * @dev LOVE20Join接口的模拟实现
 */
contract MockILOVE20Join is ILOVE20Join {
    address internal _submitAddress;
    address internal _joinAddress;

    constructor(address submitAddress_, address joinAddress_) {
        _submitAddress = submitAddress_;
        _joinAddress = joinAddress_;
    }

    function currentRound() external pure override returns (uint256) {
        return 1;
    }

    function amountByActionId(
        address,
        uint256 actionId
    ) external pure override returns (uint256) {
        return 1000 * actionId;
    }

    function actionIdsByAccount(
        address,
        address
    ) external pure override returns (uint256[] memory) {
        uint256[] memory actionIds = new uint256[](1);
        actionIds[0] = 1;
        return actionIds;
    }

    function amountByActionIdByAccount(
        address,
        uint256 actionId,
        address
    ) external pure override returns (uint256) {
        return 500 * actionId;
    }

    function randomAccounts(
        address,
        uint256,
        uint256
    ) external pure override returns (address[] memory) {
        address[] memory accounts = new address[](2);
        accounts[0] = address(0x1);
        accounts[1] = address(0x2);
        return accounts;
    }

    function verificationInfoByRound(
        address,
        address,
        uint256,
        string memory,
        uint256
    ) external pure returns (string memory) {
        return "Verified Information";
    }

    // 添加缺失的接口实现
    function JOIN_END_PHASE_BLOCKS() external pure returns (uint256) {
        return 500;
    }

    function actionIdsByAccountCount(
        address,
        address
    ) external pure returns (uint256) {
        return 2;
    }

    function actionIdsByAccountAtIndex(
        address,
        address,
        uint256
    ) external pure returns (uint256) {
        return 1;
    }

    function amountByAccount(address, address) external pure returns (uint256) {
        return 1000;
    }

    function join(address, uint256, uint256, string[] memory) external pure {
        // Mock implementation
    }

    // IPhase接口实现
    function originBlocks() external pure returns (uint256) {
        return 100;
    }

    function phaseBlocks() external pure returns (uint256) {
        return 1000;
    }

    function prefixSum(
        address tokenAddress,
        uint256 actionId,
        uint256 index
    ) external pure returns (uint256) {
        tokenAddress;
        actionId;
        index;
        return 5000;
    }

    function prepareRandomAccountsIfNeeded(
        address,
        uint256
    ) external pure returns (address[] memory) {
        address[] memory accounts = new address[](2);
        accounts[0] = address(0x123);
        accounts[1] = address(0x456);
        return accounts;
    }

    function randomAccountsByRandomSeed(
        address,
        uint256,
        uint256
    ) external pure returns (address[] memory) {
        address[] memory accounts = new address[](2);
        accounts[0] = address(0x1);
        accounts[1] = address(0x2);
        return accounts;
    }

    function randomAddress() external pure returns (address) {
        return address(0x789);
    }

    function roundByBlockNumber(uint256) external pure returns (uint256) {
        return 1;
    }

    function submitAddress() external pure returns (address) {
        return address(0xabc);
    }

    function updateVerificationInfo(
        address,
        string memory,
        string memory
    ) external pure {
        // Mock implementation
    }

    function verificationInfoUpdateRoundsCount(
        address,
        address,
        string memory
    ) external pure returns (uint256) {
        return 3;
    }

    function verificationInfoUpdateRoundsAtIndex(
        address,
        address,
        string memory,
        uint256
    ) external pure returns (uint256) {
        return 1;
    }

    function voteAddress() external pure returns (address) {
        return address(0xdef);
    }

    function withdraw(address, uint256) external pure returns (uint256) {
        return 100; // Mock implementation - return amount withdrawn
    }

    function accountToIndex(
        address tokenAddress,
        uint256 actionId,
        address account
    ) external pure returns (uint256) {
        tokenAddress;
        actionId;
        account;
        return 1;
    }

    function indexToAccount(
        address tokenAddress,
        uint256 actionId,
        uint256 index
    ) external pure returns (address) {
        tokenAddress;
        actionId;
        index;
        return address(0x123);
    }

    function numOfAccounts(
        address tokenAddress,
        uint256 actionId
    ) external pure returns (uint256) {
        tokenAddress;
        actionId;
        return 100;
    }

    function randomAccountsByActionIdAtIndex(
        address tokenAddress,
        uint256 round,
        uint256 actionId,
        uint256 index
    ) external pure returns (address) {
        tokenAddress;
        round;
        actionId;
        index;
        return address(0x456);
    }

    function randomAccountsByActionIdCount(
        address tokenAddress,
        uint256 round,
        uint256 actionId
    ) external pure returns (uint256) {
        tokenAddress;
        round;
        actionId;
        return 5;
    }

    function randomAccountsByRandomSeed(
        address tokenAddress,
        uint256 actionId,
        uint256 randomSeed,
        uint256 num
    ) external pure returns (address[] memory) {
        tokenAddress;
        actionId;
        randomSeed;
        num;
        address[] memory accounts = new address[](2);
        accounts[0] = address(0x789);
        accounts[1] = address(0xabc);
        return accounts;
    }

    function updateVerificationInfo(
        address tokenAddress,
        uint256 actionId,
        string[] memory keys,
        string[] memory values
    ) external pure {
        tokenAddress;
        actionId;
        keys;
        values;
        // Mock implementation
    }

    function verificationInfo(
        address tokenAddress,
        address account,
        uint256 actionId,
        string calldata verificationKey
    ) external pure returns (string memory) {
        tokenAddress;
        account;
        actionId;
        verificationKey;
        return "Verified Information";
    }

    function verificationInfoUpdateRoundsAtIndex(
        address tokenAddress,
        address account,
        uint256 actionId,
        string calldata verificationKey,
        uint256 index
    ) external pure returns (uint256) {
        tokenAddress;
        account;
        actionId;
        verificationKey;
        index;
        return 1;
    }

    function verificationInfoUpdateRoundsCount(
        address tokenAddress,
        address account,
        uint256 actionId,
        string calldata verificationKey
    ) external pure returns (uint256) {
        tokenAddress;
        account;
        actionId;
        verificationKey;
        return 3;
    }
}
