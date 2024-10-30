// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "../lib/forge-std/src/Script.sol";
import {Test, console} from "../lib/forge-std/src/Test.sol";

contract DeployUniswapV2 is Script {
    address public uniswapV2Router02Address;

    struct DeployParams {
        address factory;
        address WETH;
    }

    function _checkParams(DeployParams memory params) internal pure {
        require(params.factory != address(0), "Factory address cannot be 0");
        require(params.WETH != address(0), "WETH address cannot be 0");
    }

    function run(DeployParams memory params) external {
        _checkParams(params);

        uint256 gasLimit = 50_000_000;
        uint256 gasPrice = 3 gwei;

        vm.txGasPrice(gasPrice);
        vm.deal(msg.sender, gasLimit * gasPrice);

        // Paid: 0.001591183704402696 ETH (2414728 gas * 0.658949457 gwei)
        vm.broadcast();
        uniswapV2Router02Address = deployCode(
            "UniswapV2Router02.sol:UniswapV2Router02",
            abi.encode(params.factory, params.WETH)
        );

        console.log("uniswapV2Router02Address: ", uniswapV2Router02Address);
    }
}
