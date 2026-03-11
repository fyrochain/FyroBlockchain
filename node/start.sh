#!/bin/bash
# FyroChain Geth Node - Secure Production Mode

set -e

DATADIR="/root/fyrochain/node/data"

echo "[Node] Starting FyroChain PUBLIC RPC node..."
echo "[Node] Chain ID: 511 (FyroMainnet)"
echo "[Node] Data dir: $DATADIR"

exec geth \
  --datadir "$DATADIR" \
  --networkid 511 \
  --port 30311 \
  --http \
  --http.addr "127.0.0.1" \
  --http.port 8545 \
  --http.api "eth,net,web3,personal,miner,admin" \
  --http.corsdomain "https://fyrochain.org" \
  --http.vhosts "rpc.fyrochain.org" \
  --ws \
  --ws.addr "127.0.0.1" \
  --ws.port 8546 \
  --ws.api "eth,net,web3" \
  --syncmode full \
  --gcmode archive \
  --nodiscover \
  --maxpeers 20 \
  --mine \
  --miner.etherbase 0x173A9B143a7E304afc573cF57660AEf4887f0F6B \
  --unlock 0x173A9B143a7E304afc573cF57660AEf4887f0F6B \
  --password /root/fyrochain/node/password.txt \
  --allow-insecure-unlock \
  --verbosity 3 \
  2>&1 | tee -a /var/log/fyrochain/geth.log
