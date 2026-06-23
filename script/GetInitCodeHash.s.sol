// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";

/*
 * Generate init code hash of UniswapV2Pair.sol for use in UniswapV2Library.sol.
 *
 * run:
 * forge script script/GetInitCodeHash.s.sol:GetInitCodeHash
 */
contract GetInitCodeHash is Script {
    function toHexString(bytes32 data) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function run() external view returns (bytes32 initCodeHash) {
        bytes memory initCode = vm.getCode("../core/out/UniswapV2Pair.sol/UniswapV2Pair.json");
        initCodeHash = keccak256(initCode);
        console.log("initCodeHash: ", toHexString(initCodeHash));
    }
}
