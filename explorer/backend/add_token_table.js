
const { pool } = require('./db');

async function addTokenTable() {
  const client = await pool.connect();
  try {
    await client.query(`
      CREATE TABLE IF NOT EXISTS token_transfers (
        id SERIAL PRIMARY KEY,
        tx_hash VARCHAR(66),
        block_number BIGINT,
        from_addr VARCHAR(42),
        to_addr VARCHAR(42),
        token_contract VARCHAR(42),
        amount VARCHAR(78),
        timestamp TIMESTAMP,
        created_at TIMESTAMP DEFAULT NOW()
      );
      CREATE INDEX IF NOT EXISTS idx_tt_from ON token_transfers(from_addr);
      CREATE INDEX IF NOT EXISTS idx_tt_to ON token_transfers(to_addr);
      CREATE INDEX IF NOT EXISTS idx_tt_hash ON token_transfers(tx_hash);
    `);
    console.log('token_transfers table created!');
  } finally {
    client.release();
    process.exit(0);
  }
}
addTokenTable().catch(console.error);
