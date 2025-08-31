// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "../lib/forge-std/src/Script.sol";
import {Test, console} from "../lib/forge-std/src/Test.sol";
import {LOVE20RoundViewer} from "../src/LOVE20RoundViewer.sol";

contract DeployRoundViewer is Script {
    function run(
        address launchAddress_,
        address stakeAddress_,
        address submitAddress_,
        address voteAddress_,
        address joinAddress_,
        address verifyAddress_,
        address mintAddress_
    ) external {
        console.log("Deploying RoundViewer...");

        vm.broadcast();
        LOVE20RoundViewer roundViewer = new LOVE20RoundViewer();

        vm.broadcast();
        roundViewer.init(
            launchAddress_, stakeAddress_, submitAddress_, voteAddress_, joinAddress_, verifyAddress_, mintAddress_
        );

        console.log("RoundViewer deployed at", address(roundViewer));
    }
}
