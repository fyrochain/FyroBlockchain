
const { ethers } = require("ethers");

const RPC = "https://rpc.fyrochain.org";

const PRIVATE_KEY = "e315736f734a4d2f6c78c9f6edae35611fadea5fe226e9e37d31e5f3813d5ed9";

const CONTRACT = "0x21213B659c7440ad62E4b5E55246E4750EEa24D4";

const MINER = "0xe9a314cf480911d18cf97bf29feafb82e01af986";

const ABI = ["function mintBlockReward(address miner) external","function totalSupply() view returns (uint256)"];

async function mint() {

  const provider = new ethers.JsonRpcProvider(RPC);

  const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

  const contract = new ethers.Contract(CONTRACT, ABI, wallet);

  try {

    const tx = await contract.mintBlockReward(MINER);

    await tx.wait();

    const supply = await contract.totalSupply();

    console.log(`Minted 50 FYRO | Total: ${ethers.formatEther(supply)} FYRO`);

  } catch(e) { console.log("Skip:", e.reason || e.message); }

}

setInterval(mint, 6000);

mint();

