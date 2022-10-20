const { ethers, deployments } = require("hardhat");
const { moveBlocks } = require("../utils/move-blocks");
const { moveTime } = require("../utils/move-time");

const SECONDS_IN_A_DAY = 86400;
const SECONDS_IN_A_YEAR = 31449600;

describe("Staking Test", async function () {
  let staking, rewardToken, deployer, stakeAmount;

  this.beforeEach(async function () {
    const accounts = await ethers.getSigners();
    const deployer = await accounts[0];
    await deployments.fixture(["all"]);
    rewardToken = await ethers.getContract("RewardToken");
    staking = await ethers.getContract("Staking");
    stakeAmount = ethers.utils.parseEther("100000");
  });

  it("Allows users to stake and claim reward", async function () {
    await rewardToken.approve(staking.address, stakeAmount);
    await staking.stake(stakeAmount);
    const startingEarned = await staking.earned(deployer.address);
    console.log(`Starting Earned ${startingEarned}`);

    await moveTime(SECONDS_IN_A_DAY);
    await moveBlocks(1);
    const endingEarned = await staking.earned(deployer.address);
    console.log(`Ending Earned ${endingEarned}`);
  });
});
