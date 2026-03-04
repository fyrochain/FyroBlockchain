#!/bin/bash
# FyroChain Health Check Script
# Run via cron: */5 * * * * /root/fyrochain/scripts/health-check.sh

LOG="/var/log/fyrochain/health.log"
NOTIFY_EMAIL=""  # Set to receive alerts: admin@fyrochain.com
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

check() {
  local name=$1; local cmd=$2; local fix=$3
  if eval "$cmd" &>/dev/null; then
    echo "[$TIMESTAMP] [OK] $name" >> "$LOG"
  else
    echo "[$TIMESTAMP] [FAIL] $name - attempting fix" | tee -a "$LOG"
    eval "$fix" &>/dev/null || true
    sleep 5
    if ! eval "$cmd" &>/dev/null; then
      echo "[$TIMESTAMP] [CRITICAL] $name still down after fix" >> "$LOG"
      [ -n "$NOTIFY_EMAIL" ] && echo "FyroChain: $name is DOWN on $(hostname)" | mail -s "⚠️ FyroChain Alert" "$NOTIFY_EMAIL" 2>/dev/null
    fi
  fi
}

check "Geth Node" \
  "systemctl is-active --quiet fyrochain-node" \
  "systemctl restart fyrochain-node"

check "FyroScan Backend" \
  "curl -sf http://localhost:3001/health" \
  "systemctl restart fyroscan-backend"

check "PostgreSQL" \
  "systemctl is-active --quiet postgresql" \
  "systemctl restart postgresql"

check "Nginx" \
  "systemctl is-active --quiet nginx" \
  "systemctl restart nginx"

check "RPC Responding" \
  "curl -sf -X POST http://localhost:8545 -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"eth_blockNumber\",\"params\":[],\"id\":1}'" \
  "systemctl restart fyrochain-node"

# Disk space check
DISK_USAGE=$(df /root --output=pcent | tail -1 | tr -d '% ')
if [ "$DISK_USAGE" -gt 85 ]; then
  echo "[$TIMESTAMP] [WARN] Disk usage ${DISK_USAGE}% - consider cleanup" >> "$LOG"
fi
