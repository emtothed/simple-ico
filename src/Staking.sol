// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {console} from "forge-std/console.sol";

contract Staking is ReentrancyGuard {
    IERC20 public immutable stakingToken;

    uint256 public constant APR_30_DAYS = 200; // 2% = 100 basis points
    uint256 public constant APR_90_DAYS = 800; // 8% = 800 basis points
    uint256 public constant APR_180_DAYS = 2000; // 20% = 2000 basis points

    struct StakeInfo {
        uint256 amount;
        uint256 startTime;
        uint256 lastRewardCalculation;
        uint256 rewards;
        bool active;
    }

    mapping(address => StakeInfo[]) public userStakes;
    uint256 public totalStaked;

    event Staked(address indexed user, uint256 stakeId, uint256 amount);
    event Withdrawn(address indexed user, uint256 stakeId, uint256 amount);
    event RewardClaimed(address indexed user, uint256 stakeId, uint256 amount);

    constructor(address _stakingToken) {
        stakingToken = IERC20(_stakingToken);
    }

    function stake(uint256 _amount) external {
        require(_amount > 0, "Cannot stake 0");
        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        StakeInfo memory newStake = StakeInfo({
            amount: _amount,
            startTime: block.timestamp,
            lastRewardCalculation: block.timestamp,
            rewards: 0,
            active: true
        });

        userStakes[msg.sender].push(newStake);
        totalStaked += _amount;

        emit Staked(msg.sender, userStakes[msg.sender].length - 1, _amount);
    }

    function withdraw(uint256 _stakeId) external nonReentrant {
        require(_stakeId < userStakes[msg.sender].length, "Invalid stake ID");
        require(userStakes[msg.sender][_stakeId].active, "Staking position not active");

        _updateRewards(msg.sender, _stakeId);

        userStakes[msg.sender][_stakeId].active = false;
        totalStaked -= userStakes[msg.sender][_stakeId].amount;

        require(stakingToken.transfer(msg.sender, userStakes[msg.sender][_stakeId].amount), "Transfer failed");
        emit Withdrawn(msg.sender, _stakeId, userStakes[msg.sender][_stakeId].amount);
    }

    function withdrawAll() external nonReentrant {
        uint256 totalAmount = 0;

        for (uint256 i = 0; i < userStakes[msg.sender].length; i++) {
            if (userStakes[msg.sender][i].active) {
                _updateRewards(msg.sender, i);
                userStakes[msg.sender][i].active = false;
                totalAmount += userStakes[msg.sender][i].amount;
                emit Withdrawn(msg.sender, i, userStakes[msg.sender][i].amount);
            }
        }

        require(totalAmount > 0, "No active stakes");
        totalStaked -= totalAmount;
        require(stakingToken.transfer(msg.sender, totalAmount), "Transfer failed");
    }

    /// checked until here
    function claimRewards(uint256 _stakeId) external nonReentrant {
        require(_stakeId < userStakes[msg.sender].length, "Invalid stake ID");
        require(userStakes[msg.sender][_stakeId].active, "Staking posotion not active");

        _updateRewards(msg.sender, _stakeId);

        uint256 rewards = userStakes[msg.sender][_stakeId].rewards;
        console.log("rewards -----> ", rewards / 1e18, ".", rewards % 1e18);
        require(rewards > 0, "No rewards to claim");
        userStakes[msg.sender][_stakeId].rewards = 0;
        require(stakingToken.transfer(msg.sender, rewards), "Transfer failed");
        emit RewardClaimed(msg.sender, _stakeId, rewards);
    }

    function _updateRewards(address _user, uint256 _stakeId) internal {
        StakeInfo memory stake = userStakes[_user][_stakeId];
        if (!stake.active) return;

        uint256 duration = block.timestamp - stake.lastRewardCalculation;
        if (duration > 0) {
            uint256 timeFromStart = block.timestamp - stake.startTime;
            uint256 apr = _getAPR(timeFromStart);
            uint256 reward = (stake.amount * apr * duration) / (365 days * 10000);
            userStakes[_user][_stakeId].rewards += reward;
            userStakes[_user][_stakeId].lastRewardCalculation = block.timestamp;
        }
    }

    function _getAPR(uint256 _duration) internal pure returns (uint256) {
        if (_duration <= 30 days) {
            return APR_30_DAYS;
        } else if (_duration <= 90 days) {
            return APR_90_DAYS;
        } else if (_duration <= 180 days) {
            return APR_180_DAYS;
        } else {
            return 0;
        }
    }

    function getStakeInfo(address _user, uint256 _stakeId)
        external
        view
        returns (uint256 stakedAmount, uint256 startTime, uint256 pendingRewards)
    {
        require(_stakeId < userStakes[_user].length, "Invalid stake ID");
        StakeInfo memory stake = userStakes[_user][_stakeId];
        uint256 newRewards = 0;

        if (stake.amount > 0) {
            uint256 duration = block.timestamp - stake.lastRewardCalculation;
            uint256 timeFromStart = block.timestamp - stake.startTime;
            uint256 apr = _getAPR(timeFromStart);
            newRewards = (stake.amount * apr * duration) / (365 days * 10000);
        }

        return (stake.amount, stake.startTime, stake.rewards + newRewards);
    }

    function getUserStakeCount(address _user) external view returns (uint256) {
        return userStakes[_user].length;
    }

    function getUserTotalStaked(address _user) public view returns (uint256 total) {
        for (uint256 i = 0; i < userStakes[_user].length; i++) {
            if (userStakes[_user][i].active) {
                total += userStakes[_user][i].amount;
            }
        }
        return total;
    }
}
