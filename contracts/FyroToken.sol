// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FyroToken is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 21_000_000 * 10**18;

    // Halving config — 210,000 blocks (~7 days on FyroChain)
    uint256 public blockReward = 50 * 10**18;
    uint256 public lastHalvingBlock;
    uint256 public halvingInterval = 210_000;
    uint256 public halvingCount = 0;
    uint256 public maxHalvings = 64;

    // Anti-abuse: track last mint block
    uint256 public lastMintBlock;

    event Halving(uint256 newReward, uint256 halvingNumber);
    event RewardMinted(address indexed miner, uint256 amount);

    constructor() ERC20("FyroChain", "FYRO") Ownable(msg.sender) {
        lastHalvingBlock = block.number;
        lastMintBlock = block.number;
        // 10% team allocation — 2.1M FYRO
        _mint(msg.sender, 2_100_000 * 10**18);
    }

    // One reward per block — called by your mining script
    function mintBlockReward(address miner) external onlyOwner {
        require(block.number > lastMintBlock, "Already minted this block");
        require(miner != address(0), "Invalid miner address");
        _checkHalving();
        require(totalSupply() + blockReward <= MAX_SUPPLY, "Max supply reached");
        lastMintBlock = block.number;
        _mint(miner, blockReward);
        emit RewardMinted(miner, blockReward);
    }

    function _checkHalving() internal {
        if (halvingCount < maxHalvings &&
            block.number >= lastHalvingBlock + halvingInterval) {
            blockReward = blockReward / 2;
            lastHalvingBlock = block.number;
            halvingCount++;
            emit Halving(blockReward, halvingCount);
        }
    }

    // Anyone can burn their own tokens
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    // --- View functions ---
    function remainingSupply() external view returns (uint256) {
        return MAX_SUPPLY - totalSupply();
    }

    function currentReward() external view returns (uint256) {
        return blockReward / 10**18; // Returns in FYRO (not wei)
    }

    function nextHalvingBlock() external view returns (uint256) {
        return lastHalvingBlock + halvingInterval;
    }

    function blocksUntilHalving() external view returns (uint256) {
        uint256 next = lastHalvingBlock + halvingInterval;
        if (block.number >= next) return 0;
        return next - block.number;
    }
}
