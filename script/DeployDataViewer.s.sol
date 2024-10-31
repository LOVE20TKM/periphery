// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import "../lib/forge-std/src/Script.sol";
import {Test, console} from "../lib/forge-std/src/Test.sol";
import {LOVE20DataViewer} from "../src/LOVE20DataViewer.sol";

contract DeployDataViewer is Script {
    function run(
        address launchAddress_,
        address voteAddress_,
        address joinAddress_,
        // address randomAddress_, // Removed randomAddress parameter
        address verifyAddress_,
        address mintAddress_
    ) external {
        console.log("Deploying DataViewer...");

        vm.broadcast();
        LOVE20DataViewer dataViewer = new LOVE20DataViewer(msg.sender);

        vm.broadcast();
        dataViewer.init(launchAddress_, voteAddress_, joinAddress_, verifyAddress_, mintAddress_);

        console.log("DataViewer deployed at", address(dataViewer));
    }
}
