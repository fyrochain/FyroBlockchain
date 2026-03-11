#!/bin/bash
# Stop FyroChain Geth Node
echo "[Node] Stopping FyroChain node..."
pkill -f "geth.*networkid 511" && echo "[Node] Stopped." || echo "[Node] Node was not running."
