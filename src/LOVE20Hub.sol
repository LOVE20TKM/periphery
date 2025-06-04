// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import "./interfaces/ILOVE20Core.sol";

interface IWETH9 {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
}

interface IERC20 {
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

contract LOVE20Hub {
    address public WETHAddress;
    address public launchAddress;
    address public submitAddress;
    address public voteAddress;
    address public joinAddress;
    address public verifyAddress;
    address public mintAddress;

    bool public initialized;

    event ContributeWithETH(
        address indexed tokenAddress,
        address indexed to,
        uint256 ethAmount,
        uint256 wethAmount
    );

    constructor() {}

    function init(
        address WETHAddress_,
        address launchAddress_,
        address submitAddress_,
        address voteAddress_,
        address joinAddress_,
        address verifyAddress_,
        address mintAddress_
    ) external {
        require(!initialized, "Already initialized");

        WETHAddress = WETHAddress_;
        launchAddress = launchAddress_;
        submitAddress = submitAddress_;
        voteAddress = voteAddress_;
        joinAddress = joinAddress_;
        verifyAddress = verifyAddress_;
        mintAddress = mintAddress_;

        initialized = true;
    }

    function contributeWithETH(
        address tokenAddress,
        address to
    ) external payable {
        require(initialized, "Hub not initialized");
        require(msg.value > 0, "Must send ETH");
        require(tokenAddress != address(0), "Invalid token address");
        require(to != address(0), "Invalid recipient address");

        IWETH9(WETHAddress).deposit{value: msg.value}();
        IERC20(WETHAddress).approve(launchAddress, msg.value);
        ILOVE20Launch(launchAddress).contribute(tokenAddress, msg.value, to);

        emit ContributeWithETH(tokenAddress, to, msg.value, msg.value);
    }
}
