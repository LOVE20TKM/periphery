// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import "../lib/forge-std/src/Script.sol";
import {Test, console} from "../lib/forge-std/src/Test.sol";
import {LOVE20Hub} from "../src/LOVE20Hub.sol";

contract DeployHub is Script {
    function run(
        address WETHAddress_,
        address launchAddress_,
        address submitAddress_,
        address voteAddress_,
        address joinAddress_,
        address verifyAddress_,
        address mintAddress_
    ) external {
        console.log("Deploying Hub contract...");

        vm.broadcast();
        LOVE20Hub hub = new LOVE20Hub();

        vm.broadcast();
        hub.init(
            WETHAddress_,
            launchAddress_,
            submitAddress_,
            voteAddress_,
            joinAddress_,
            verifyAddress_,
            mintAddress_
        );

        console.log("Hub contract deployed, address:", address(hub));
    }
}
