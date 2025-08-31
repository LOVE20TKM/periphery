// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "./ILOVE20Submit.sol";

struct ActionVoter {
    address account;
    uint256 voteCount;
}

struct AccountVotingAction {
    uint256 actionId;
    uint256 round;
    uint256 myVoteCount;
    uint256 totalVoteCount;
}

struct VerificationMatrix {
    address[] verifiers;
    address[] verifiees;
    uint256[][] scores;
}

interface ILOVE20RoundViewer {
    function actionVoters(address tokenAddress, uint256 round, uint256 actionId)
        external
        view
        returns (ActionVoter[] memory voters);

    function accountVotingHistory(address tokenAddress, address account, uint256 startRound, uint256 endRound)
        external
        view
        returns (AccountVotingAction[] memory accountActions, ActionInfo[] memory uniqueActionInfos);

    function actionVerificationMatrix(address tokenAddress, uint256 round, uint256 actionId)
        external
        view
        returns (VerificationMatrix memory matrix);
}
