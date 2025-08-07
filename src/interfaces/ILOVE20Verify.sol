// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {IPhase} from "./IPhase.sol";

interface ILOVE20VerifyErrors {
    error AlreadyInitialized();
    error ScoresAndAccountsLengthMismatch();
    error ScoresExceedVotesNum();
    error ScoresMustIncrease();
}

interface ILOVE20VerifyEvents {
    event Verify(
        address indexed tokenAddress,
        uint256 round,
        address indexed verifier,
        uint256 indexed actionId,
        uint256 abstentionScore,
        uint256[] scores
    );
}

interface ILOVE20Verify is IPhase, ILOVE20VerifyErrors, ILOVE20VerifyEvents {
    function firstTokenAddress() external view returns (address);
    function randomAddress() external view returns (address);

    function stakeAddress() external view returns (address);
    function voteAddress() external view returns (address);
    function joinAddress() external view returns (address);

    function RANDOM_SEED_UPDATE_MIN_PER_TEN_THOUSAND()
        external
        view
        returns (uint256);

    function score(
        address tokenAddress,
        uint256 round
    ) external view returns (uint256);

    function scoreWithReward(
        address tokenAddress,
        uint256 round
    ) external view returns (uint256);

    function abstentionScoreWithReward(
        address tokenAddress,
        uint256 round
    ) external view returns (uint256);

    function scoreByActionId(
        address tokenAddress,
        uint256 round,
        uint256 actionId
    ) external view returns (uint256);

    function scoreByActionIdByAccount(
        address tokenAddress,
        uint256 round,
        uint256 actionId,
        address account
    ) external view returns (uint256);

    function scoreByVerifier(
        address tokenAddress,
        uint256 round,
        address verifier
    ) external view returns (uint256);

    function scoreByVerifierByActionId(
        address tokenAddress,
        uint256 round,
        address verifier,
        uint256 actionId
    ) external view returns (uint256);

    function verify(
        address tokenAddress,
        uint256 actionId,
        uint256 abstentionScore,
        uint256[] calldata scores
    ) external;

    function stakedAmountOfVerifiers(
        address tokenAddress,
        uint256 round
    ) external view returns (uint256);
}
