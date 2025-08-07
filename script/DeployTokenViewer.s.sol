// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.17;

import "../lib/forge-std/src/Script.sol";
import {Test, console} from "../lib/forge-std/src/Test.sol";
import {LOVE20TokenViewer} from "../src/LOVE20TokenViewer.sol";

contract DeployTokenViewer is Script {
    function run(address launchAddress_, address stakeAddress_) external {
        console.log("Deploying TokenViewer...");

        vm.broadcast();
        LOVE20TokenViewer tokenViewer = new LOVE20TokenViewer();

        vm.broadcast();
        tokenViewer.init(launchAddress_, stakeAddress_);

        console.log("TokenViewer deployed at", address(tokenViewer));
    }
}
