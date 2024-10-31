// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "../lib/forge-std/src/Script.sol";
import "../lib/v2-periphery/contracts/UniswapV2Router02.sol";
import {Test, console} from "../lib/forge-std/src/Test.sol";

contract DeployUniswapV2 is Script {
    address public uniswapV2Router02Address;

    function _checkParams(address factory, address WETH) internal pure {
        require(factory != address(0), "Factory address cannot be 0");
        require(WETH != address(0), "WETH address cannot be 0");
    }

    function run(address factory, address WETH) external {
        _checkParams(factory, WETH);

        uint256 gasLimit = 50_000_000;
        uint256 gasPrice = 3 * 10 ** 9;

        vm.txGasPrice(gasPrice);
        vm.deal(msg.sender, gasLimit * gasPrice);

        // Paid: 0.001591183704402696 ETH (2414728 gas * 0.658949457 gwei)
        vm.broadcast();
        uniswapV2Router02Address = deployCode("UniswapV2Router02.sol:UniswapV2Router02", abi.encode(factory, WETH));

        console.log("uniswapV2Router02Address: ", uniswapV2Router02Address);
    }
}
