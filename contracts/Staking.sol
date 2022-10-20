//stake : Lock tokens into our smart contract
//widhdraw : unlock tokens and pull out of the contract
// claimReward: users get their reward token

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error Staking__TransferFailed();
error Staking_NeedsMoreThanZero();

contract Staking {
  IERC20 public s_stakingToken;
  IERC20 public s_rewardToken;

  //someones address -> how much they staked
  mapping(address => uint256) public s_balances;

  // mapping of how much each address has been paid
  mapping(address => uint256) public s_userRewardPerTokenPaid;

  // mapping of how much rewards each user has
  mapping(address => uint256) public s_rewards;

  uint256 public constant REWARD_RATE = 100;
  uint256 public s_totalSupply;
  uint256 public s_rewardPerTokenStored;
  uint256 public s_lastUpdateTime;

  modifier updateReward(address account) {
    //how much reward per token?
    s_rewardPerTokenStored = rewardPerToken();
    s_lastUpdateTime = block.timestamp;
    s_rewards[account] = earned(account);
    s_userRewardPerTokenPaid[account] = s_rewardPerTokenStored;
    _;
  }
  modifier moreThanZero(uint256 amount) {
    if (amount == 0) {
      revert Staking_NeedsMoreThanZero();
    }
    _;
  }

  constructor(address stakingToken, address rewardToken) {
    s_stakingToken = IERC20(stakingToken);
    s_rewardToken = IERC20(rewardToken);
  }

  function earned(address account) public view returns (uint256) {
    uint256 currentBalance = s_balances[account];

    // how much they have been paid already
    uint256 amountPaid = s_userRewardPerTokenPaid[account];
    uint256 currentRewardPertoken = rewardPerToken();
    uint256 pastRewards = s_rewards[account];

    uint256 _earned = ((currentBalance * (currentRewardPertoken - amountPaid)) /
      1e18) + pastRewards;
    return _earned;
  }

  function rewardPerToken() public view returns (uint256) {
    if (s_totalSupply == 0) {
      return s_rewardPerTokenStored;
    }
    // 1e18 -> 18 decimal places ->convert into wei
    return
      s_rewardPerTokenStored +
      (((block.timestamp - s_lastUpdateTime) * REWARD_RATE * 1e18) /
        s_totalSupply);
  }

  // just a specific token
  function stake(uint256 amount)
    external
    updateReward(msg.sender)
    moreThanZero(amount)
  {
    // keep track of how much this user has staked
    // keep track of how much token we have total
    // transfer the tokens to this contact

    s_balances[msg.sender] += amount;
    s_totalSupply += amount;

    bool sucess = s_stakingToken.transferFrom(
      msg.sender,
      address(this),
      amount
    );
    //require(sucess, "Failed");
    if (!sucess) {
      revert Staking__TransferFailed();
    }
  }

  function withdraw(uint256 amount)
    external
    updateReward(msg.sender)
    moreThanZero(amount)
  {
    s_balances[msg.sender] -= amount;
    s_totalSupply -= amount;
    bool sucess = s_stakingToken.transfer(msg.sender, amount);
    if (!sucess) {
      revert Staking__TransferFailed();
    }
  }

  function claimReward() external updateReward(msg.sender) {
    // How much reward do they get?
    // The contract is going emit X tokens per second
    // And disperse them all to token stakers

    uint256 reward = s_rewards[msg.sender];
    bool success = s_rewardToken.transfer(msg.sender, reward);
    if (!success) {
      revert Staking__TransferFailed();
    }
  }
}
