// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "../lib/forge-std/src/Script.sol";
import {console} from "../lib/forge-std/src/Test.sol";
import {UniswapV2Zap} from "../src/UniswapV2Zap.sol";

contract DeployUniswapV2Zap is Script {
    address public uniswapV2ZapAddress;

    function run(address router) external {
        require(router != address(0), "Router address cannot be 0");

        vm.broadcast();
        UniswapV2Zap zap = new UniswapV2Zap(router);
        uniswapV2ZapAddress = address(zap);

        console.log("uniswapV2ZapAddress: ", uniswapV2ZapAddress);
    }
}
