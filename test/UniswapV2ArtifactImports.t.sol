// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "../lib/v2-periphery/contracts/UniswapV2Router02.sol";
import "../lib/v2-periphery/contracts/test/WETH9.sol";

contract UniswapV2ArtifactImports {
    function routerCreationCodeHash() external pure returns (bytes32) {
        return keccak256(type(UniswapV2Router02).creationCode);
    }

    function wethCreationCodeHash() external pure returns (bytes32) {
        return keccak256(type(WETH9).creationCode);
    }

    function testCompileRealUniswapV2Artifacts() external pure {}
}
