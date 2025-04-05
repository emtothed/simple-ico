// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {TokenICO} from "../src/TokenICO.sol";
import {SampleToken} from "../src/SampleToken.sol";
import {UsdtToken} from "../src/UsdtToken.sol";
import {Staking} from "../src/Staking.sol";

contract DeployAll is Script {
    uint256 public constant INITIAL_SUPPLY = 1_000_000 ether;
    uint256 public constant ICO_DURATION = 5 minutes;

    function run() external returns (SampleToken, UsdtToken, TokenICO, Staking) {
        vm.startBroadcast(msg.sender);

        // Deploy token
        SampleToken sampleToken = new SampleToken(INITIAL_SUPPLY);

        // Deploy USDT token
        UsdtToken usdtToken = UsdtToken(vm.envAddress("USDT_ADDRESS"));
        if (block.chainid == 31337) {
            usdtToken = new UsdtToken(INITIAL_SUPPLY);
        }

        // Deploy ICO and Transfer ICO allocation to ICO contract
        TokenICO ico = new TokenICO(address(sampleToken), address(usdtToken), ICO_DURATION);
        sampleToken.transfer(address(ico), 400_000 ether);

        // Deploy staking contract and Transfer staking allocation to staking contract
        Staking stakingContract = new Staking(address(sampleToken));
        sampleToken.transfer(address(stakingContract), 100_000 ether);

        console.log("UsdtToken deployed at:", address(usdtToken));
        console.log("SimpleToken deployed at:", address(sampleToken));
        console.log("ICO contract deployed at:", address(ico));
        console.log("Staking contract deployed at:", address(stakingContract));

        vm.stopBroadcast();
        return (sampleToken, usdtToken, ico, stakingContract);
    }
}
