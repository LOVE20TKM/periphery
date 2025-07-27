// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import "../lib/forge-std/src/Script.sol";
import {Test, console} from "../lib/forge-std/src/Test.sol";
import {LOVE20DataViewer} from "../src/LOVE20DataViewer.sol";

contract DeployDataViewer is Script {
    function run(
        address launchAddress_,
        address stakeAddress_,
        address submitAddress_,
        address voteAddress_,
        address joinAddress_,
        address verifyAddress_,
        address mintAddress_
    ) external {
        console.log("Deploying DataViewer...");

        vm.broadcast();
        LOVE20DataViewer dataViewer = new LOVE20DataViewer();

        vm.broadcast();
        dataViewer.init(
            launchAddress_,
            stakeAddress_,
            submitAddress_,
            voteAddress_,
            joinAddress_,
            verifyAddress_,
            mintAddress_
        );

        console.log("DataViewer deployed at", address(dataViewer));
    }
}
