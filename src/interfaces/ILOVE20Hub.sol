// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.17;
interface ILOVE20HubEvents {
    // Events
    event ContributeFirstTokenWithETH(
        address indexed tokenAddress,
        address indexed to,
        uint256 amount
    );

    event StakeLiquidity(
        address indexed tokenAddress,
        address indexed to,
        uint256 tokenAmountDesired,
        uint256 parentTokenAmountDesired,
        uint256 tokenAmountReal,
        uint256 parentTokenAmountReal,
        uint256 promisedWaitingPhases
    );
}

interface ILOVE20Hub {
    // State variables (view functions)
    function WETHAddress() external view returns (address);
    function launchAddress() external view returns (address);
    function stakeAddress() external view returns (address);
    function submitAddress() external view returns (address);
    function voteAddress() external view returns (address);
    function joinAddress() external view returns (address);
    function verifyAddress() external view returns (address);
    function mintAddress() external view returns (address);
    function initialized() external view returns (bool);

    // Functions
    function init(
        address WETHAddress_,
        address launchAddress_,
        address stakeAddress_,
        address submitAddress_,
        address voteAddress_,
        address joinAddress_,
        address verifyAddress_,
        address mintAddress_
    ) external;

    function contributeFirstTokenWithETH(
        address tokenAddress,
        address to
    ) external payable;

    function stakeLiquidity(
        address tokenAddress,
        uint256 tokenAmount,
        uint256 parentTokenAmount,
        uint256 tokenAmountMin,
        uint256 parentTokenAmountMin,
        uint256 promisedWaitingPhases,
        address to
    ) external returns (uint256 govVotesAdded, uint256 slAmountAdded);
}
