const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config();
const { pool, initSchema } = require('./db');
const { startSync } = require('./sync');
const app = express();
const PORT = process.env.PORT || 4000;
app.use(cors());
app.use(express.json());
app.get('/api/stats', async (req, res) => {
  try {
    const [blockRes, txRes, latestRes] = await Promise.all([
      pool.query('SELECT COUNT(*) as count FROM blocks'),
      pool.query('SELECT COUNT(*) as count FROM transactions'),
      pool.query('SELECT MAX(number) as latest FROM blocks')
    ]);
    res.json({ totalBlocks: parseInt(blockRes.rows[0].count), totalTxns: parseInt(txRes.rows[0].count), latestBlock: parseInt(latestRes.rows[0].latest || 0), networkName: process.env.NETWORK_NAME || 'FyroMainnet', chainId: parseInt(process.env.CHAIN_ID || '511'), tokenSymbol: process.env.TOKEN_SYMBOL || 'FYRO' });
  } catch (err) { console.error(err); res.status(500).json({ error: 'Internal server error' }); }
});
app.get('/api/blocks', async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page || '1'));
    const limit = Math.min(50, parseInt(req.query.limit || '20'));
    const offset = (page - 1) * limit;
    const [dataRes, countRes] = await Promise.all([
      pool.query('SELECT number, hash, timestamp, miner, tx_count FROM blocks ORDER BY number DESC LIMIT $1 OFFSET $2', [limit, offset]),
      pool.query('SELECT COUNT(*) as count FROM blocks')
    ]);
    res.json({ data: dataRes.rows, total: parseInt(countRes.rows[0].count), page, limit, totalPages: Math.ceil(parseInt(countRes.rows[0].count) / limit) });
  } catch (err) { console.error(err); res.status(500).json({ error: 'Failed to fetch blocks' }); }
});
app.get('/api/block/:id', async (req, res) => {
  try {
    const blockId = req.params.id;
    const query = blockId.startsWith('0x') ? 'SELECT * FROM blocks WHERE hash = $1' : 'SELECT * FROM blocks WHERE number = $1';
    const params = blockId.startsWith('0x') ? [blockId] : [parseInt(blockId)];
    const blockRes = await pool.query(query, params);
    if (blockRes.rows.length === 0) return res.status(404).json({ error: 'Block not found' });
    const txRes = await pool.query('SELECT hash, from_addr, to_addr, value, gas_used, status FROM transactions WHERE block_number = $1', [blockRes.rows[0].number]);
    res.json({ block: blockRes.rows[0], transactions: txRes.rows });
  } catch (err) { console.error(err); res.status(500).json({ error: 'Failed to fetch block' }); }
});
app.get('/api/transactions', async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page || '1'));
    const limit = Math.min(50, parseInt(req.query.limit || '20'));
    const offset = (page - 1) * limit;
    const [dataRes, countRes] = await Promise.all([
      pool.query('SELECT hash, from_addr, to_addr, value, block_number, timestamp, status FROM transactions ORDER BY timestamp DESC LIMIT $1 OFFSET $2', [limit, offset]),
      pool.query('SELECT COUNT(*) as count FROM transactions')
    ]);
    res.json({ data: dataRes.rows, total: parseInt(countRes.rows[0].count), page, limit, totalPages: Math.ceil(parseInt(countRes.rows[0].count) / limit) });
  } catch (err) { console.error(err); res.status(500).json({ error: 'Failed to fetch transactions' }); }
});

app.get('/api/address/:addr', async (req, res) => {
  try {
    const addr = req.params.addr.toLowerCase();
    const [sentRes, receivedRes, tokenRes] = await Promise.all([
      pool.query('SELECT hash, from_addr, to_addr, value, block_number, timestamp, status FROM transactions WHERE LOWER(from_addr) = $1 ORDER BY timestamp DESC LIMIT 50', [addr]),
      pool.query('SELECT hash, from_addr, to_addr, value, block_number, timestamp, status FROM transactions WHERE LOWER(to_addr) = $1 ORDER BY timestamp DESC LIMIT 50', [addr]),
      pool.query('SELECT tx_hash, from_addr, to_addr, amount, timestamp FROM token_transfers WHERE LOWER(from_addr) = $1 OR LOWER(to_addr) = $1 ORDER BY timestamp DESC LIMIT 50', [addr])
    ]);
    const allTxns = [...sentRes.rows, ...receivedRes.rows].sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp)).slice(0, 50);
    res.json({ address: addr, transactions: allTxns, tokenTransfers: tokenRes.rows });
  } catch (err) { console.error(err); res.status(500).json({ error: 'Failed to fetch address' }); }
});

app.get('/api/token-transfers', async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page || '1'));
    const limit = Math.min(50, parseInt(req.query.limit || '20'));
    const offset = (page - 1) * limit;
    const [dataRes, countRes] = await Promise.all([
      pool.query('SELECT tx_hash, from_addr, to_addr, amount, timestamp FROM token_transfers ORDER BY timestamp DESC LIMIT $1 OFFSET $2', [limit, offset]),
      pool.query('SELECT COUNT(*) as count FROM token_transfers')
    ]);
    res.json({ data: dataRes.rows, total: parseInt(countRes.rows[0].count), page, limit });
  } catch (err) { console.error(err); res.status(500).json({ error: 'Failed to fetch token transfers' }); }
});

app.get('/api/tx/:hash', async (req, res) => {
  try {
    const txRes = await pool.query('SELECT * FROM transactions WHERE hash = $1', [req.params.hash]);
    if (txRes.rows.length === 0) return res.status(404).json({ error: 'Transaction not found' });
    const tokenRes = await pool.query('SELECT from_addr, to_addr, amount FROM token_transfers WHERE tx_hash = $1', [req.params.hash]);
    const tx = txRes.rows[0];
    if (tokenRes.rows.length > 0) {
      tx.token_transfer = tokenRes.rows[0];
      tx.token_amount = tokenRes.rows[0].amount;
    }
    res.json(tx);
  } catch (err) { console.error(err); res.status(500).json({ error: 'Failed to fetch transaction' }); }
});
app.get('/api/search/:query', async (req, res) => {
  try {
    const q = req.params.query.trim();
    if (q.startsWith('0x') && q.length === 66) {
      const txRes = await pool.query('SELECT hash FROM transactions WHERE hash = $1', [q]);
      if (txRes.rows.length > 0) return res.json({ redirect: `/tx.html?hash=${q}` });
      const blockRes = await pool.query('SELECT number FROM blocks WHERE hash = $1', [q]);
      if (blockRes.rows.length > 0) return res.json({ redirect: `/block.html?number=${blockRes.rows[0].number}` });
    }
    if (q.startsWith('0x') && q.length === 42) return res.json({ redirect: `/address.html?addr=${q}` });
    if (!isNaN(q)) return res.json({ redirect: `/block.html?number=${q}` });
    res.status(404).json({ error: 'Not found' });
  } catch (err) { console.error(err); res.status(500).json({ error: 'Search failed' }); }
});
app.use(express.static(path.join(__dirname, '../frontend')));
app.get('*', (req, res) => { res.sendFile(path.join(__dirname, '../frontend/index.html')); });
async function main() {
  await initSchema();
  app.listen(PORT, () => { console.log(`Explorer running on port ${PORT}`); });
  await startSync();
}
main().catch(err => { console.error('Startup error:', err); process.exit(1); });
