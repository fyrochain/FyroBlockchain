#!/bin/bash
# FyroChain Node Monitor - Auto-restart on failure
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/fyrochain/monitor.log"

while true; do
  if ! pgrep -f "geth.*networkid 511" > /dev/null; then
    echo "[$(date)] [Monitor] Node not running, restarting..." | tee -a "$LOG_FILE"
    bash "$SCRIPT_DIR/start.sh" &
    sleep 15
  else
    sleep 30
  fi
done
