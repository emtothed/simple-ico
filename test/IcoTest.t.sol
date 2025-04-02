// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console, Test} from "forge-std/Test.sol";
import {UsdtToken} from "../src/UsdtToken.sol";
import {SampleToken} from "../src/SampleToken.sol";
import {TokenICO} from "../src/TokenICO.sol";
import {DeployICO} from "../script/DeployICO.s.sol";

contract IcoTest is Test {
    TokenICO public ico;
    UsdtToken public usdtToken;
    SampleToken public sampleToken;
    DeployICO public deployer;

    function setUp() public {
        // Deploy the tokens and ICO contract
        vm.prank(address(this));
        deployer = new DeployICO();

        (sampleToken, usdtToken, ico) = deployer.run();
    }

    function testIco() public {
        // Check initial balances
        assertEq(ico.totalSold(), 0);
        assertEq(ico.saleFinalized(), false);

        uint256 initialSampleTokenAmount = sampleToken.balanceOf(address(this));
        uint256 initialUsdtTokenAmount = usdtToken.balanceOf(address(this));

        // Simulate a purchase
        uint256 purchaseAmount = 10 ether; // 10 tokens
        vm.startPrank(address(this));
        usdtToken.approve(address(ico), purchaseAmount * 2);
        ico.buyTokens(purchaseAmount);
        vm.stopPrank();

        // Check balances after purchase
        assertEq(ico.totalSold(), purchaseAmount);
        assertEq(ico.addressToContributions(address(this)), purchaseAmount);
        assertEq(usdtToken.balanceOf(address(ico)), purchaseAmount * 2);
        assertEq(sampleToken.balanceOf(address(this)), initialSampleTokenAmount + purchaseAmount);

        // Finalize the sale
        purchaseAmount = 399990 ether;
        vm.startPrank(address(this));
        usdtToken.approve(address(ico), purchaseAmount * 2);
        ico.buyTokens(purchaseAmount);
        vm.stopPrank();

        // Warp time forward by 1 week
        vm.warp(block.timestamp + 1 weeks);
        vm.startPrank(address(this));
        ico.finalizeSale();
        vm.stopPrank();

        // Check finalization
        assertEq(ico.saleFinalized(), true);
        assertEq(ico.totalSold(), 400000 ether);
        assertEq(usdtToken.balanceOf(address(this)), initialUsdtTokenAmount);
    }
}
