// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {Staking} from "../src/Staking.sol";
import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DeployAll} from "../script/DeployAll.s.sol";
import {SampleToken} from "../src/SampleToken.sol";

contract StakingTest is Test {
    Staking public staking;
    SampleToken public sampleToken;
    DeployAll public deployer;
    uint256 public constant STK_INITIAL_SUPPLY = 500_000 ether;

    function setUp() public {
        // Deploy the contracts
        deployer = new DeployAll();
        (sampleToken,,, staking) = deployer.run();
    }

    function testStake() public {
        // Check initial balances
        assertEq(staking.totalStaked(), 0);

        // Approve and stake tokens
        uint256 stakeAmount = 10 ether;
        sampleToken.approve(address(staking), stakeAmount);
        staking.stake(stakeAmount);

        // Check balances after staking
        assertEq(staking.totalStaked(), stakeAmount);
        assertEq(sampleToken.balanceOf(address(this)), STK_INITIAL_SUPPLY - stakeAmount);
    }

    function testWithdraw() public {
        assertEq(staking.totalStaked(), 0);

        // Stake tokens first
        uint256 stakeAmount = 10 ether;
        sampleToken.approve(address(staking), stakeAmount);
        staking.stake(stakeAmount);

        // Withdraw the stake
        staking.withdraw(0);

        // Check balances after withdrawal
        assertEq(staking.totalStaked(), 0);
        assertEq(sampleToken.balanceOf(address(this)), STK_INITIAL_SUPPLY);
    }

    function testClaimRewards() public {
        // Stake tokens first
        uint256 stakeAmount = 1000 ether;
        sampleToken.approve(address(staking), stakeAmount);
        staking.stake(stakeAmount);

        // Warp time to simulate rewards
        vm.warp(block.timestamp + 90 days);

        // Claim rewards
        staking.claimRewards(0);

        // Check balances after claiming rewards
        uint256 expectedRewards = (stakeAmount * staking.APR_90_DAYS() * 90 days) / (365 days * 10000); // 1% for 30 days
        (,,, uint256 rewardAfterClaiming,) = staking.userStakes(address(this), 0);
        assertEq(sampleToken.balanceOf(address(this)), STK_INITIAL_SUPPLY + expectedRewards - stakeAmount);
        assertEq(rewardAfterClaiming, 0);
    }

    function testInvalidStakeId() public {
        // Attempt to withdraw with an invalid stake ID
        vm.startPrank(address(this));
        vm.expectRevert("Invalid stake ID");
        staking.withdraw(999);
        vm.stopPrank();
    }

    function testInvalidStakeIdClaim() public {
        // Attempt to claim rewards with an invalid stake ID
        vm.startPrank(address(this));
        vm.expectRevert("Invalid stake ID");
        staking.claimRewards(999);
        vm.stopPrank();
    }
}
