// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StakeContract {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public stakeTimestamps;

    uint256 public constant APR = 20; // Yıllık yüzde 20 getiri
    uint256 public constant totalReward = 39000000 * 10 ** 18; // Toplam ödül miktarı, 18 ondalık basamak varsayılarak
    uint256 public totalStaked;
    uint256 public constant maxPoolCapacity = totalReward * 1000 / APR; // Maksimum stake miktarı hesaplanıyor

    IERC20 public stakingToken;

    event Staked(address indexed user, uint256 amount, uint256 time);
    event Unstaked(address indexed user, uint256 amount, uint256 reward, uint256 time);

    constructor(address _stakingToken) {
        stakingToken = IERC20(_stakingToken);
    }

    function stake(uint256 _amount) external {
        require(totalStaked + _amount <= maxPoolCapacity, "Pool capacity exceeded");
        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        uint256 currentStake = balances[msg.sender];
        if(currentStake > 0) {
            uint256 reward = calculateReward(msg.sender);
            require(stakingToken.transfer(msg.sender, reward), "Reward transfer failed");
        }

        balances[msg.sender] = currentStake + _amount;
        stakeTimestamps[msg.sender] = block.timestamp;
        totalStaked += _amount;

        emit Staked(msg.sender, _amount, block.timestamp);
    }

    function unstake() external {
        uint256 stakedAmount = balances[msg.sender];
        require(stakedAmount > 0, "Nothing to unstake");

        uint256 reward = calculateReward(msg.sender);
        require(stakingToken.transfer(msg.sender, stakedAmount + reward), "Transfer failed");

        totalStaked -= stakedAmount;
        balances[msg.sender] = 0;
        stakeTimestamps[msg.sender] = 0;

        emit Unstaked(msg.sender, stakedAmount, reward, block.timestamp);
    }

    function calculateReward(address _staker) public view returns (uint256) {
        uint256 stakedAmount = balances[_staker];
        uint256 stakedDuration = block.timestamp - stakeTimestamps[_staker];
        uint256 rewardRatePerSecond = APR * 10 ** 18 / 365 days; // Yıllık getiri oranını saniyelik getiriye çeviriyoruz
        return stakedAmount * rewardRatePerSecond * stakedDuration / 10 ** 18;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
