#!/bin/bash
# FyroChain Backup Script
# Cron: 0 2 * * * /root/fyrochain/scripts/backup.sh

BACKUP_DIR="/root/fyrochain-backups"
INSTALL_DIR="/root/fyrochain"
DATE=$(date '+%Y%m%d_%H%M%S')
KEEP_DAYS=7

mkdir -p "$BACKUP_DIR"

echo "[$(date)] Starting backup..."

# 1. PostgreSQL dump
pg_dump -U fyro fyroscan | gzip > "$BACKUP_DIR/db_${DATE}.sql.gz" 2>/dev/null && \
  echo "[✓] Database backed up" || echo "[✗] Database backup failed"

# 2. Validator keystore backup (CRITICAL)
cp -r "$INSTALL_DIR/node/data/keystore" "$BACKUP_DIR/keystore_${DATE}" 2>/dev/null && \
  echo "[✓] Keystore backed up" || echo "[✗] Keystore backup failed"

# 3. Config files
tar czf "$BACKUP_DIR/config_${DATE}.tar.gz" \
  "$INSTALL_DIR/node/genesis.json" \
  "$INSTALL_DIR/node/validator.address" \
  "$INSTALL_DIR/explorer/backend/.env" \
  2>/dev/null && echo "[✓] Config backed up"

# 4. Cleanup old backups
find "$BACKUP_DIR" -name "*.gz" -mtime +$KEEP_DAYS -delete 2>/dev/null
find "$BACKUP_DIR" -name "keystore_*" -mtime +$KEEP_DAYS -exec rm -rf {} + 2>/dev/null

echo "[$(date)] Backup complete. Files in: $BACKUP_DIR"
ls -lh "$BACKUP_DIR/" | tail -5
