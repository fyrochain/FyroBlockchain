// db.js - PostgreSQL connection pool
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME || 'fyroscan',
  user: process.env.DB_USER || 'fyro',
  password: String(process.env.DB_PASSWORD || ''),
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

pool.on('error', (err) => {
  console.error('[DB] Unexpected pool error:', err.message);
});

// Test connection on startup
pool.query('SELECT NOW()', (err, res) => {
  if (err) {
    console.error('[DB] Connection failed:', err.message);
  } else {
    console.log('[DB] Connected to PostgreSQL at', res.rows[0].now);
  }
});

// Initialize schema
async function initSchema() {
  const client = await pool.connect();
  try {
    await client.query(`
      CREATE TABLE IF NOT EXISTS blocks (
        number BIGINT PRIMARY KEY,
        hash VARCHAR(66) UNIQUE NOT NULL,
        parent_hash VARCHAR(66),
        timestamp TIMESTAMP,
        miner VARCHAR(42),
        gas_used BIGINT DEFAULT 0,
        gas_limit BIGINT DEFAULT 0,
        tx_count INTEGER DEFAULT 0,
        size INTEGER DEFAULT 0,
        difficulty VARCHAR(50) DEFAULT '1',
        total_difficulty VARCHAR(50),
        extra_data TEXT,
        created_at TIMESTAMP DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS transactions (
        hash VARCHAR(66) PRIMARY KEY,
        block_number BIGINT REFERENCES blocks(number) ON DELETE CASCADE,
        from_addr VARCHAR(42),
        to_addr VARCHAR(42),
        value VARCHAR(78) DEFAULT '0',
        gas_price VARCHAR(50),
        gas_used BIGINT DEFAULT 0,
        gas BIGINT DEFAULT 0,
        nonce BIGINT DEFAULT 0,
        input TEXT DEFAULT '0x',
        status INTEGER DEFAULT 1,
        timestamp TIMESTAMP,
        created_at TIMESTAMP DEFAULT NOW()
      );

      CREATE INDEX IF NOT EXISTS idx_tx_from ON transactions(from_addr);
      CREATE INDEX IF NOT EXISTS idx_tx_to ON transactions(to_addr);
      CREATE INDEX IF NOT EXISTS idx_tx_block ON transactions(block_number);
      CREATE INDEX IF NOT EXISTS idx_blocks_timestamp ON blocks(timestamp DESC);
      CREATE INDEX IF NOT EXISTS idx_tx_timestamp ON transactions(timestamp DESC);
    `);
    console.log('[DB] Schema initialized');
  } catch (err) {
    console.error('[DB] Schema init error:', err.message);
  } finally {
    client.release();
  }
}

module.exports = { pool, initSchema };
