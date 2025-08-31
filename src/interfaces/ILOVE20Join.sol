// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.8.17;

import {IPhase} from "./IPhase.sol";

interface ILOVE20JoinEvents {
    // Events
    event Join(
        address indexed tokenAddress,
        uint256 currentRound,
        uint256 indexed actionId,
        address indexed account,
        uint256 additionalStakeAmount
    );

    event Withdraw(
        address indexed tokenAddress,
        uint256 currentRound,
        uint256 indexed actionId,
        address indexed account,
        uint256 amount
    );

    event UpdateVerificationInfo(
        address indexed tokenAddress,
        address indexed account,
        uint256 indexed actionId,
        string verificationKey,
        uint256 round,
        string verificationInfo
    );

    event PrepareRandomAccounts(
        address indexed tokenAddress, uint256 round, uint256 indexed actionId, address[] accounts
    );
}

interface ILOVE20JoinErrors {
    // Custom errors
    error AlreadyInitialized();
    error LastBlocksOfPhaseCannotJoin();
    error ActionNotVoted();
    error AmountIsZero();
    error JoinedAmountIsZero();
    error NotWhiteListAddress();
    error JoinAmountLessThanMinStake();
}

interface ILOVE20Join is ILOVE20JoinEvents, ILOVE20JoinErrors, IPhase {
    function submitAddress() external view returns (address);
    function voteAddress() external view returns (address);
    function randomAddress() external view returns (address);

    function JOIN_END_PHASE_BLOCKS() external view returns (uint256);

    // ------ verification info ------
    function updateVerificationInfo(
        address tokenAddress,
        uint256 actionId,
        string[] memory verificationKeys,
        string[] memory verificationInfos
    ) external;

    function verificationInfo(address tokenAddress, address account, uint256 actionId, string calldata verificationKey)
        external
        view
        returns (string memory);

    function verificationInfoByRound(
        address tokenAddress,
        address account,
        uint256 actionId,
        string calldata verificationKey,
        uint256 round
    ) external view returns (string memory);

    function verificationInfoUpdateRoundsCount(
        address tokenAddress,
        address account,
        uint256 actionId,
        string calldata verificationKey
    ) external view returns (uint256);

    function verificationInfoUpdateRoundsAtIndex(
        address tokenAddress,
        address account,
        uint256 actionId,
        string calldata verificationKey,
        uint256 index
    ) external view returns (uint256);

    // ------ join & withdraw ------
    function join(address tokenAddress, uint256 actionId, uint256 additionalAmount, string[] calldata verificationInfos)
        external;

    function withdraw(address tokenAddress, uint256 actionId) external returns (uint256);

    // ------ random accounts ------
    function prepareRandomAccountsIfNeeded(address tokenAddress, uint256 actionId)
        external
        returns (address[] memory);

    function randomAccounts(address tokenAddress, uint256 round, uint256 actionId)
        external
        view
        returns (address[] memory);

    function randomAccountsByRandomSeed(address tokenAddress, uint256 actionId, uint256 randomSeed, uint256 num)
        external
        view
        returns (address[] memory);

    function randomAccountsByActionIdCount(address tokenAddress, uint256 round, uint256 actionId)
        external
        view
        returns (uint256);

    function randomAccountsByActionIdAtIndex(address tokenAddress, uint256 round, uint256 actionId, uint256 index)
        external
        view
        returns (address);

    // ------ joined amount ------

    function amountByActionId(address tokenAddress, uint256 actionId) external view returns (uint256);

    function amountByActionIdByAccount(address tokenAddress, uint256 actionId, address account)
        external
        view
        returns (uint256);

    function amountByAccount(address tokenAddress, address account) external view returns (uint256);

    // ------ joined action ids ------
    function actionIdsByAccount(address tokenAddress, address account) external view returns (uint256[] memory);

    function actionIdsByAccountCount(address tokenAddress, address account) external view returns (uint256);

    function actionIdsByAccountAtIndex(address tokenAddress, address account, uint256 index)
        external
        view
        returns (uint256);

    // ------ index & account ------
    function numOfAccounts(address tokenAddress, uint256 actionId) external view returns (uint256);

    // 1-indexed
    function indexToAccount(address tokenAddress, uint256 actionId, uint256 index) external view returns (address);

    function accountToIndex(address tokenAddress, uint256 actionId, address account) external view returns (uint256);

    function prefixSum(address tokenAddress, uint256 actionId, uint256 index) external view returns (uint256);
}
