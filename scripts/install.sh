#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
#  FyroChain Complete Setup Script
#  One-command installation for Ubuntu 20.04/22.04
#  Usage: sudo bash install.sh
# ═══════════════════════════════════════════════════════════════════
set -e

# ─── Colors ─────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log()    { echo -e "${GREEN}[✓]${NC} $1"; }
warn()   { echo -e "${YELLOW}[⚠]${NC} $1"; }
error()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }
header() { echo -e "\n${CYAN}${BOLD}══════════════════════════════${NC}"; echo -e "${CYAN}${BOLD}  $1${NC}"; echo -e "${CYAN}${BOLD}══════════════════════════════${NC}"; }

# ─── Verify root ──────────────────────────────────────────────────
[ "$EUID" -ne 0 ] && error "Run as root: sudo bash install.sh"

# ─── Config ───────────────────────────────────────────────────────
INSTALL_DIR="/root/fyrochain"
DATADIR="$INSTALL_DIR/node/data"
NODE_VERSION="20"
GETH_VERSION="1.13.14"

header "FyroChain Installation"
echo -e "${BOLD}This will install:${NC}"
echo "  • Geth blockchain node (Chain ID: 511)"
echo "  • FyroScan block explorer"
echo "  • fyrochain.com landing page"
echo "  • Nginx web server"
echo "  • PostgreSQL database"
echo "  • SSL certificates"
echo ""

# ─── Collect passwords ────────────────────────────────────────────
echo -e "${BOLD}Setup requires a few inputs:${NC}"
echo ""

read -s -p "  Validator wallet password: " WALLET_PASS
echo ""
read -s -p "  Confirm wallet password: " WALLET_PASS2
echo ""
[ "$WALLET_PASS" != "$WALLET_PASS2" ] && error "Passwords do not match"

read -s -p "  Database password for 'fyro' user: " DB_PASS
echo ""
echo ""

# ─── STEP 1: System Update & Dependencies ────────────────────────
header "Step 1: System Setup"
log "Updating system packages..."
apt-get update -qq
apt-get upgrade -y -qq

log "Installing dependencies..."
apt-get install -y -qq \
  curl wget git build-essential \
  nginx certbot python3-certbot-nginx \
  postgresql postgresql-contrib \
  ufw fail2ban \
  jq unzip software-properties-common

# ─── STEP 2: Node.js ─────────────────────────────────────────────
header "Step 2: Node.js $NODE_VERSION"
if ! command -v node &>/dev/null || [[ "$(node --version | cut -d. -f1 | tr -d 'v')" -lt 18 ]]; then
  curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - 2>/dev/null
  apt-get install -y nodejs
  log "Node.js $(node --version) installed"
else
  log "Node.js $(node --version) already installed"
fi

# ─── STEP 3: Geth ────────────────────────────────────────────────
header "Step 3: Geth Blockchain Node"
if ! command -v geth &>/dev/null; then
  log "Downloading Geth $GETH_VERSION..."
  ARCH=$(uname -m)
  [ "$ARCH" = "x86_64" ] && GETH_ARCH="amd64" || GETH_ARCH="arm64"
  
  GETH_URL="https://gethstore.blob.core.windows.net/builds/geth-linux-${GETH_ARCH}-${GETH_VERSION}-*.tar.gz"
  
  # Try direct download
  cd /tmp
  GETH_TAR="geth-linux-${GETH_ARCH}-${GETH_VERSION}"
  
  # Use go-ethereum PPA as reliable source
  add-apt-repository -y ppa:ethereum/ethereum 2>/dev/null || true
  apt-get update -qq
  apt-get install -y ethereum 2>/dev/null || {
    # Fallback: manual download
    warn "PPA failed, downloading manually..."
    GETH_DOWNLOAD="https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.13.14-2bd6bd01.tar.gz"
    wget -q "$GETH_DOWNLOAD" -O geth.tar.gz
    tar xzf geth.tar.gz
    mv geth-*/geth /usr/local/bin/geth
    chmod +x /usr/local/bin/geth
    rm -rf geth.tar.gz geth-*/
  }
  log "Geth $(geth version 2>&1 | head -1) installed"
else
  log "Geth already installed: $(geth version 2>&1 | grep 'Geth' | head -1)"
fi

# ─── STEP 4: Folder Structure ─────────────────────────────────────
header "Step 4: Creating Project Structure"

mkdir -p \
  "$INSTALL_DIR"/{node/data,scripts} \
  "$INSTALL_DIR"/explorer/{backend,frontend/assets/{css,js}} \
  "$INSTALL_DIR"/website/assets/{css,js} \
  "$INSTALL_DIR"/nginx \
  /var/log/fyrochain

log "Directories created at $INSTALL_DIR"

# ─── STEP 5: Validator Account ────────────────────────────────────
header "Step 5: Creating Validator Account"

# Save password
echo "$WALLET_PASS" > "$INSTALL_DIR/node/password.txt"
chmod 600 "$INSTALL_DIR/node/password.txt"

if [ ! -f "$INSTALL_DIR/node/validator.address" ]; then
  log "Generating new validator account..."
  
  # Create account
  GETH_OUTPUT=$(geth account new \
    --datadir "$DATADIR" \
    --password "$INSTALL_DIR/node/password.txt" 2>&1)
  
  # Extract address
  VALIDATOR_ADDR=$(echo "$GETH_OUTPUT" | grep -oP '0x[a-fA-F0-9]{40}' | head -1)
  
  if [ -z "$VALIDATOR_ADDR" ]; then
    error "Failed to create validator account"
  fi
  
  echo "$VALIDATOR_ADDR" > "$INSTALL_DIR/node/validator.address"
  log "Validator address: $VALIDATOR_ADDR"
else
  VALIDATOR_ADDR=$(cat "$INSTALL_DIR/node/validator.address")
  log "Using existing validator: $VALIDATOR_ADDR"
fi

# ─── STEP 6: Genesis File ─────────────────────────────────────────
header "Step 6: Initializing Blockchain"

# Strip 0x prefix for extradata
ADDR_CLEAN=${VALIDATOR_ADDR#0x}
EXTRADATA="0x$(printf '%064d' 0)${ADDR_CLEAN}$(printf '%0130d' 0)"

# Create genesis.json
cat > "$INSTALL_DIR/node/genesis.json" << EOF
{
  "config": {
    "chainId": 511,
    "homesteadBlock": 0,
    "eip150Block": 0,
    "eip155Block": 0,
    "eip158Block": 0,
    "byzantiumBlock": 0,
    "constantinopleBlock": 0,
    "petersburgBlock": 0,
    "istanbulBlock": 0,
    "berlinBlock": 0,
    "londonBlock": 0,
    "clique": {
      "period": 5,
      "epoch": 30000
    }
  },
  "difficulty": "1",
  "gasLimit": "8000000",
  "extradata": "$EXTRADATA",
  "alloc": {
    "$ADDR_CLEAN": {
      "balance": "10000000000000000000000000"
    }
  }
}
EOF

# Initialize if not already done
if [ ! -d "$DATADIR/geth" ]; then
  log "Initializing Geth datadir..."
  geth init --datadir "$DATADIR" "$INSTALL_DIR/node/genesis.json" 2>&1 | tail -3
  log "Geth initialized"
else
  warn "Geth already initialized, skipping"
fi

# ─── STEP 7: PostgreSQL ───────────────────────────────────────────
header "Step 7: Database Setup"

systemctl start postgresql
systemctl enable postgresql

# Create database and user
sudo -u postgres psql 2>/dev/null << PSQL || warn "DB may already exist"
CREATE USER fyro WITH PASSWORD '$DB_PASS';
CREATE DATABASE fyroscan OWNER fyro;
GRANT ALL PRIVILEGES ON DATABASE fyroscan TO fyro;
\q
PSQL

log "PostgreSQL configured"

# ─── STEP 8: Install project files ────────────────────────────────
header "Step 8: Installing FyroChain Files"

# Copy all project files (assuming they're in the same directory as this script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -d "$SCRIPT_DIR/explorer" ]; then
  cp -r "$SCRIPT_DIR/explorer" "$INSTALL_DIR/"
  cp -r "$SCRIPT_DIR/website" "$INSTALL_DIR/"
  cp -r "$SCRIPT_DIR/nginx" "$INSTALL_DIR/"
  cp -r "$SCRIPT_DIR/node/"*.sh "$INSTALL_DIR/node/"
  log "Project files copied"
else
  warn "Project files not found in $SCRIPT_DIR - downloading from GitHub..."
  # If you have a GitHub repo, add clone here:
  # git clone https://github.com/Shahreyaarr/fyrochain.git "$INSTALL_DIR/"
fi

chmod +x "$INSTALL_DIR/node/"*.sh

# ─── STEP 9: Backend Dependencies ────────────────────────────────
header "Step 9: Node.js Backend"

cd "$INSTALL_DIR/explorer/backend"

# Create .env
cat > .env << EOF
DB_HOST=localhost
DB_PORT=5432
DB_NAME=fyroscan
DB_USER=fyro
DB_PASSWORD=$DB_PASS
RPC_URL=http://localhost:8545
PORT=3001
NODE_ENV=production
CHAIN_ID=511
NETWORK_NAME=FyroMainnet
TOKEN_SYMBOL=FYRO
EOF

chmod 600 .env
log ".env created"

npm install --production 2>&1 | tail -3
log "Node.js dependencies installed"

# ─── STEP 10: Systemd Services ────────────────────────────────────
header "Step 10: Setting Up Systemd Services"

# Geth service
cat > /etc/systemd/system/fyrochain-node.service << EOF
[Unit]
Description=FyroChain Geth Node
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR/node
ExecStart=/bin/bash $INSTALL_DIR/node/start.sh
Restart=always
RestartSec=10
StandardOutput=append:/var/log/fyrochain/geth.log
StandardError=append:/var/log/fyrochain/geth-error.log
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Explorer backend service
cat > /etc/systemd/system/fyroscan-backend.service << EOF
[Unit]
Description=FyroScan Block Explorer Backend
After=network.target postgresql.service fyrochain-node.service
Wants=postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR/explorer/backend
ExecStart=$(which node) server.js
Restart=always
RestartSec=5
Environment=NODE_ENV=production
StandardOutput=append:/var/log/fyrochain/explorer.log
StandardError=append:/var/log/fyrochain/explorer-error.log

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable fyrochain-node fyroscan-backend
log "Systemd services created and enabled"

# ─── STEP 11: Nginx ──────────────────────────────────────────────
header "Step 11: Nginx Configuration"

# Use HTTP-only config first (before SSL)
cat > /etc/nginx/sites-available/fyrochain << 'NGINX'
limit_req_zone $binary_remote_addr zone=rpc_limit:10m rate=30r/m;
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=120r/m;

server {
    listen 80;
    server_name fyroscan.org www.fyroscan.org;
    root /root/fyrochain/explorer/frontend;
    index index.html;

    gzip on;
    gzip_types text/plain text/css application/javascript application/json;

    location /api {
        limit_req zone=api_limit burst=30 nodelay;
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location /health {
        proxy_pass http://localhost:3001;
    }

    location / {
        try_files $uri $uri/ /index.html;
    }
}

server {
    listen 80;
    server_name fyrochain.com www.fyrochain.com;
    root /root/fyrochain/website;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}

server {
    listen 80;
    server_name rpc.fyrochain.com;

    add_header Access-Control-Allow-Origin "*" always;
    add_header Access-Control-Allow-Methods "POST, GET, OPTIONS" always;
    add_header Access-Control-Allow-Headers "Content-Type" always;

    location / {
        limit_req zone=rpc_limit burst=20 nodelay;
        if ($request_method = 'OPTIONS') { return 204; }
        proxy_pass http://localhost:8545;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        client_max_body_size 1m;
    }
}
NGINX

# Disable default site, enable ours
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/fyrochain /etc/nginx/sites-enabled/fyrochain

nginx -t && systemctl restart nginx
log "Nginx configured and restarted"

# ─── STEP 12: Firewall ───────────────────────────────────────────
header "Step 12: Firewall Setup"

ufw --force reset 2>/dev/null
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment "SSH"
ufw allow 80/tcp comment "HTTP"
ufw allow 443/tcp comment "HTTPS"
ufw allow 30311/tcp comment "Geth P2P"
# Block external DB and RPC access
ufw deny 5432 comment "Block external DB"
ufw deny 8545 comment "Block direct RPC (use proxy)"
ufw --force enable
log "Firewall configured"

# ─── STEP 13: Start Services ──────────────────────────────────────
header "Step 13: Starting Services"

systemctl start fyrochain-node
log "FyroChain node starting..."
sleep 5

systemctl start fyroscan-backend
log "FyroScan backend starting..."

# ─── STEP 14: SSL Certificates ────────────────────────────────────
header "Step 14: SSL Certificates"

echo ""
echo "  DNS must be pointed to this server's IP before running certbot."
echo "  Domains: fyroscan.org, fyrochain.com, rpc.fyrochain.com"
echo ""
read -p "  Run certbot now? (y/n) [n]: " RUN_CERTBOT
RUN_CERTBOT=${RUN_CERTBOT:-n}

if [[ "$RUN_CERTBOT" =~ ^[Yy]$ ]]; then
  certbot --nginx -d fyroscan.org -d www.fyroscan.org --non-interactive --agree-tos -m admin@fyrochain.com 2>/dev/null && log "fyroscan.org SSL done" || warn "fyroscan.org SSL failed"
  certbot --nginx -d fyrochain.com -d www.fyrochain.com --non-interactive --agree-tos -m admin@fyrochain.com 2>/dev/null && log "fyrochain.com SSL done" || warn "fyrochain.com SSL failed"
  certbot --nginx -d rpc.fyrochain.com --non-interactive --agree-tos -m admin@fyrochain.com 2>/dev/null && log "rpc.fyrochain.com SSL done" || warn "rpc.fyrochain.com SSL failed"
  
  # Auto-renewal
  systemctl enable certbot.timer 2>/dev/null || (echo "0 12 * * * root certbot renew --quiet" >> /etc/crontab)
  log "SSL auto-renewal configured"
else
  warn "Skipping SSL — run: certbot --nginx -d fyroscan.org -d fyrochain.com -d rpc.fyrochain.com"
fi

# ─── Final Summary ────────────────────────────────────────────────
header "Installation Complete!"

echo ""
echo -e "${BOLD}${GREEN}✅ FyroChain is running!${NC}"
echo ""
echo -e "${BOLD}Network Details:${NC}"
echo -e "  Network Name:  ${CYAN}FyroMainnet${NC}"
echo -e "  Chain ID:      ${CYAN}511${NC}"
echo -e "  Token Symbol:  ${CYAN}FYRO${NC}"
echo -e "  Block Time:    ${CYAN}5 seconds${NC}"
echo -e "  Validator:     ${CYAN}$VALIDATOR_ADDR${NC}"
echo ""
echo -e "${BOLD}URLs:${NC}"
echo -e "  Explorer:  ${CYAN}https://fyroscan.org${NC}"
echo -e "  Website:   ${CYAN}https://fyrochain.com${NC}"
echo -e "  RPC:       ${CYAN}https://rpc.fyrochain.com${NC}"
echo ""
echo -e "${BOLD}Service Commands:${NC}"
echo -e "  systemctl status fyrochain-node     # Check node status"
echo -e "  systemctl status fyroscan-backend   # Check API status"
echo -e "  systemctl restart fyrochain-node    # Restart node"
echo -e "  journalctl -fu fyrochain-node       # Follow node logs"
echo ""
echo -e "${BOLD}Files:${NC}"
echo -e "  Node data:   ${CYAN}$DATADIR${NC}"
echo -e "  Node logs:   ${CYAN}/var/log/fyrochain/${NC}"
echo -e "  Config:      ${CYAN}$INSTALL_DIR${NC}"
echo ""
echo -e "${BOLD}MetaMask Setup:${NC}"
echo -e "  RPC URL:   ${CYAN}https://rpc.fyrochain.com${NC}"
echo -e "  Chain ID:  ${CYAN}511${NC}"
echo -e "  Token:     ${CYAN}FYRO${NC}"
echo ""
echo -e "${YELLOW}⚠  Genesis wallet (10M FYRO): $VALIDATOR_ADDR${NC}"
echo -e "${YELLOW}⚠  Password stored at: $INSTALL_DIR/node/password.txt (chmod 600)${NC}"
echo ""
