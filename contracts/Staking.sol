// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NativeTokenStaking is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public rewardToken;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public rewardPool;

    uint256 public constant STAKING_PERIOD_90_DAYS = 90 days;
    uint256 public constant STAKING_PERIOD_180_DAYS = 180 days;
    uint256 public constant STAKING_PERIOD_365_DAYS = 365 days;

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public stakingEndTime;

    uint256 private _totalSupply;

    /* ========== EVENTS ========== */

    event Staked(
        address indexed user,
        uint256 amount,
        uint256 stakingPeriod,
        uint256 claimTime
    );
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _rewardToken,
        uint256 _rewardPool,
        uint256 numberOfMonths
    ) {
        require(
            numberOfMonths > 0,
            "Staking period must be greater than 0 months"
        );

        rewardToken = IERC20(_rewardToken);
        rewardPool = _rewardPool;
        lastUpdateTime = block.timestamp;

        uint256 stakingDurationInSeconds = numberOfMonths * 30 days;
        rewardRate = (rewardPool * 1e18) / stakingDurationInSeconds;
    }

    /* ========== FUNCTIONS ========== */

    function stake(uint256 stakingPeriod) external payable nonReentrant {
        require(msg.value > 0, "Cannot stake 0 tokens");
        require(
            stakingPeriod == STAKING_PERIOD_90_DAYS ||
                stakingPeriod == STAKING_PERIOD_180_DAYS ||
                stakingPeriod == STAKING_PERIOD_365_DAYS,
            "Invalid staking period"
        );

        updateReward(msg.sender);

        _totalSupply += msg.value;
        balances[msg.sender] += msg.value;
        stakingEndTime[msg.sender] = block.timestamp + stakingPeriod;

        emit Staked(
            msg.sender,
            msg.value,
            stakingPeriod,
            stakingEndTime[msg.sender]
        );
    }

    function unstake(uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot unstake 0 tokens");
        require(
            block.timestamp >= stakingEndTime[msg.sender],
            "Staking period not ended"
        );
        require(balances[msg.sender] >= amount, "Insufficient balance");

        updateReward(msg.sender);

        _totalSupply -= amount;
        balances[msg.sender] -= amount;

        payable(msg.sender).transfer(amount);

        emit Withdrawn(msg.sender, amount);
    }

    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot withdraw 0 tokens");
        require(
            block.timestamp >= stakingEndTime[msg.sender],
            "Staking period not ended"
        );
        require(balances[msg.sender] >= amount, "Insufficient balance");

        updateReward(msg.sender);

        _totalSupply -= amount;
        balances[msg.sender] -= amount;

        payable(msg.sender).transfer(amount);

        emit Withdrawn(msg.sender, amount);
    }

    function getReward() external nonReentrant {
        updateReward(msg.sender);
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards available");
        rewards[msg.sender] = 0;
        rewardPool -= reward;
        rewardToken.safeTransfer(msg.sender, reward);

        emit RewardPaid(msg.sender, reward);
    }

    function getTotalStaked(address account) external view returns (uint256) {
        return balances[account];
    }

    function getExpectedReward(
        address account
    ) external view returns (uint256) {
        return earned(account);
    }

    function updateReward(address account) internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            ((rewardRate * (block.timestamp - lastUpdateTime)) / _totalSupply);
    }

    function earned(address account) public view returns (uint256) {
        return
            ((balances[account] *
                (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) +
            rewards[account];
    }

    function recoverUnclaimedRewards() external onlyOwner {
        uint256 remainingRewards = rewardToken.balanceOf(address(this)) -
            rewardPool;
        require(remainingRewards > 0, "No unclaimed rewards available");
        rewardToken.safeTransfer(owner(), remainingRewards);
    }

    function emergencyWithdraw() external nonReentrant {
        uint256 stakedAmount = balances[msg.sender];
        require(stakedAmount > 0, "No staked tokens to withdraw");

        balances[msg.sender] = 0;
        _totalSupply -= stakedAmount;

        payable(msg.sender).transfer(stakedAmount);

        emit Withdrawn(msg.sender, stakedAmount);
    }

    fallback() external payable {
        revert("Direct transfers not allowed");
    }

    receive() external payable {
        revert("Direct transfers not allowed");
    }
}

// erc20 address 0x001AeC1c7EE7fF4c96Cbf6fbFdBb53aEc8B12d42

// https://thirdweb.com/lisk-sepolia-testnet/0xAc6A88836FCCaA9476512408A490A77A46BB421F
