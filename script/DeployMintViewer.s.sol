// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "../lib/forge-std/src/Script.sol";
import {Test, console} from "../lib/forge-std/src/Test.sol";
import {LOVE20MintViewer} from "../src/LOVE20MintViewer.sol";

contract DeployMintViewer is Script {
    function run(
        address stakeAddress_,
        address voteAddress_,
        address joinAddress_,
        address mintAddress_
    ) external {
        console.log("Deploying MintViewer...");

        vm.broadcast();
        LOVE20MintViewer mintViewer = new LOVE20MintViewer();

        vm.broadcast();
        mintViewer.init(
            stakeAddress_, voteAddress_, joinAddress_, mintAddress_
        );

        console.log("MintViewer deployed at", address(mintViewer));
    }
}
