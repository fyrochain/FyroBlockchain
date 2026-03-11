function getCliqueSignerFromBlock(block) {
  try {
    const extra = block.extraData;
    if (extra && extra.length >= 172) { return ('0x' + extra.slice(66, 106)).toLowerCase(); }
  } catch(e) {}
  return (block.miner || '0x0000000000000000000000000000000000000000').toLowerCase();
}
// sync.js - Blockchain synchronization engine
const { Web3 } = require('web3');
const { pool, initSchema } = require('./db');
require('dotenv').config();

const RPC_URL = process.env.RPC_URL || 'http://localhost:8545';
let web3;
let isSyncing = false;
let lastSyncedBlock = 0;

async function connectWeb3() {
  try {
    web3 = new Web3(new Web3.providers.HttpProvider(RPC_URL));
    const chainId = await web3.eth.getChainId();
    console.log(`[Sync] Connected to chain ID: ${chainId}`);
    return true;
  } catch (err) {
    console.error('[Sync] Web3 connection failed:', err.message);
    return false;
  }
}

async function getLastSyncedBlock() {
  try {
    const res = await pool.query('SELECT MAX(number) AS max FROM blocks');
    return parseInt(res.rows[0].max || '0');
  } catch {
    return 0;
  }
}

async function syncBlock(blockNumber) {
  const client = await pool.connect();
  try {
    // Check if already synced
    const exists = await client.query('SELECT 1 FROM blocks WHERE number = $1', [blockNumber]);
    if (exists.rowCount > 0) return;

    const block = await web3.eth.getBlock(blockNumber, true);
    if (!block) return;

    await client.query('BEGIN');

    // Insert block
    const timestamp = new Date(Number(block.timestamp) * 1000);
    await client.query(`
      INSERT INTO blocks (number, hash, parent_hash, timestamp, miner, gas_used, gas_limit, tx_count, size, difficulty, total_difficulty, extra_data)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
      ON CONFLICT (number) DO NOTHING
    `, [
      Number(block.number),
      block.hash,
      block.parentHash,
      timestamp,
      getCliqueSignerFromBlock(block),
      Number(block.gasUsed),
      Number(block.gasLimit),
      block.transactions?.length || 0,
      Number(block.size || 0),
      block.difficulty?.toString() || '1',
      block.totalDifficulty?.toString() || '1',
      block.extraData || '0x'
    ]);

    // Insert transactions
    if (block.transactions && block.transactions.length > 0) {
      for (const tx of block.transactions) {
        try {
          let receipt = null;
          try {
            receipt = await web3.eth.getTransactionReceipt(tx.hash);
          } catch (e) { /* no receipt yet */ }

          await client.query(`
            INSERT INTO transactions (hash, block_number, from_addr, to_addr, value, gas_price, gas_used, gas, nonce, input, status, timestamp)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
            ON CONFLICT (hash) DO NOTHING
          `, [
            tx.hash,
            Number(block.number),
            tx.from?.toLowerCase(),
            tx.to?.toLowerCase() || null,
            tx.value?.toString() || '0',
            tx.gasPrice?.toString() || '0',
            receipt ? Number(receipt.gasUsed) : 0,
            Number(tx.gas || 0),
            Number(tx.nonce || 0),
            tx.input || '0x',
            receipt ? Number(receipt.status) : 1,
            timestamp
          ]);
        } catch (txErr) {
          console.error(`[Sync] Error inserting tx ${tx.hash}:`, txErr.message);
        }
      }
    }

    await syncTokenTransfers(client, block);
    await client.query('COMMIT');
    console.log(`[Sync] Block ${blockNumber} synced (${block.transactions?.length || 0} txns)`);
  } catch (err) {
    await client.query('ROLLBACK').catch(() => {});
    console.error(`[Sync] Error syncing block ${blockNumber}:`, err.message);
    throw err;
  } finally {
    client.release();
  }
}


// ERC-20 Transfer event signature
const TRANSFER_TOPIC = '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef';
const FYRO_TOKEN = '0xe50b94e63324408c2456e90f769721d1ca8bdd42';

async function syncTokenTransfers(client, block) {
  try {
    const logs = await web3.eth.getPastLogs({
      fromBlock: Number(block.number),
      toBlock: Number(block.number),
      address: FYRO_TOKEN,
      topics: [TRANSFER_TOPIC]
    });
    for (const log of logs) {
      try {
        const from = '0x' + log.topics[1].slice(26);
        const to = '0x' + log.topics[2].slice(26);
        const amount = BigInt(log.data).toString();
        await client.query(`
          INSERT INTO token_transfers (tx_hash, block_number, from_addr, to_addr, token_contract, amount, timestamp)
          VALUES ($1, $2, $3, $4, $5, $6, $7)
          ON CONFLICT DO NOTHING
        `, [log.transactionHash, Number(block.number), from.toLowerCase(), to.toLowerCase(), FYRO_TOKEN, amount, new Date(Number(block.timestamp) * 1000)]);
      } catch(e) {}
    }
  } catch(e) {
    console.error('[Sync] Token transfer error:', e.message);
  }
}

async function syncLatest() {
  if (isSyncing) return;
  isSyncing = true;

  try {
    if (!web3) {
      const ok = await connectWeb3();
      if (!ok) return;
    }

    const latestBlock = Number(await web3.eth.getBlockNumber());
    if (lastSyncedBlock === 0) {
      lastSyncedBlock = await getLastSyncedBlock();
    }

    if (latestBlock <= lastSyncedBlock) return;

    // Sync up to 50 blocks at a time to avoid overwhelming DB
    const toSync = Math.min(latestBlock, lastSyncedBlock + 50);

    for (let i = lastSyncedBlock + 1; i <= toSync; i++) {
      await syncBlock(i);
      lastSyncedBlock = i;
    }

    if (toSync < latestBlock) {
      console.log(`[Sync] Behind by ${latestBlock - toSync} blocks, will catch up next cycle`);
    }
  } catch (err) {
    console.error('[Sync] Sync error:', err.message);
    web3 = null; // Force reconnect
  } finally {
    isSyncing = false;
  }
}

async function startSync() {
  console.log('[Sync] Starting blockchain sync...');
  await initSchema();

  const ok = await connectWeb3();
  if (!ok) {
    console.error('[Sync] Cannot connect to node. Will retry...');
  }

  // Initial sync
  await syncLatest();

  // Poll every 10 seconds
  setInterval(syncLatest, 10000);
  console.log('[Sync] Sync engine running (polling every 10s)');
}

module.exports = { startSync, syncLatest };

// If run directly
if (require.main === module) {
  startSync().catch(console.error);
}
