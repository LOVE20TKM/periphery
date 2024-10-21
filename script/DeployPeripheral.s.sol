// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import "../lib/forge-std/src/Script.sol";
import {Test, console} from "../lib/forge-std/src/Test.sol";
import {LOVE20DataViewer} from "../src/LOVE20DataViewer.sol";

contract DeployPeripheral is Script {
    function run(
        address launchAddress_,
        address voteAddress_,
        address joinAddress_,
        // address randomAddress_, // Removed randomAddress parameter
        address verifyAddress_,
        address mintAddress_
    ) external {
        console.log("Deploying Peripheral...");

        vm.broadcast();
        LOVE20DataViewer dataViewer = new LOVE20DataViewer(address(this));
        dataViewer.init(
            launchAddress_,
            voteAddress_,
            joinAddress_,
            verifyAddress_,
            mintAddress_
        );

        console.log("Peripheral deployed at", address(dataViewer));
    }
}
