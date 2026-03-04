# 🔷 FyroChain — Complete Layer-1 Blockchain Ecosystem

[![Chain ID](https://img.shields.io/badge/Chain%20ID-511-00d4ff)](https://fyroscan.org)
[![Token](https://img.shields.io/badge/Token-FYRO-00d4ff)](https://fyroscan.org)
[![Consensus](https://img.shields.io/badge/Consensus-PoA%20(Clique)-00d4ff)](https://fyrochain.com)

## Overview

FyroChain is a production-ready Layer-1 blockchain ecosystem including:

- **FyroScan** — Full block explorer (fyroscan.org clone)
- **FyroChain Node** — Geth-based PoA blockchain (Chain ID: 511)
- **Landing Page** — fyrochain.com website
- **One-Command Install** — Complete automated setup

## Network Details

| Property | Value |
|----------|-------|
| Network Name | FyroMainnet |
| Chain ID | 511 |
| Token Symbol | FYRO |
| Max Supply | 10,000,000 FYRO |
| Block Time | 5 seconds |
| Consensus | Proof of Authority (Clique) |
| RPC URL | https://rpc.fyrochain.com |
| Explorer | https://fyroscan.org |

## Quick Start (Ubuntu 20.04/22.04)

```bash
# Clone or upload project
git clone https://github.com/Shahreyaarr/fyrochain /root/fyrochain-src
cd /root/fyrochain-src

# Run one-command install
sudo bash scripts/install.sh
```

## Project Structure

```
fyrochain/
├── node/                    # Geth blockchain node
│   ├── genesis.json         # Chain configuration
│   ├── start.sh             # Start node
│   ├── stop.sh              # Stop node
│   └── monitor.sh           # Auto-restart monitor
│
├── explorer/
│   ├── backend/             # Node.js + Express API
│   │   ├── server.js        # Main API server
│   │   ├── db.js            # PostgreSQL connection
│   │   ├── sync.js          # Blockchain sync engine
│   │   └── package.json
│   │
│   └── frontend/            # FyroScan HTML/CSS/JS
│       ├── index.html       # Homepage (stats + tables)
│       ├── block.html       # Block detail page
│       ├── tx.html          # Transaction detail page
│       ├── address.html     # Address detail page
│       ├── blocks.html      # All blocks (paginated)
│       ├── txs.html         # All transactions (paginated)
│       └── assets/
│           ├── css/style.css  # Complete stylesheet
│           └── js/app.js      # Frontend logic
│
├── website/                 # fyrochain.com landing page
│   └── index.html
│
├── nginx/
│   └── fyrochain.conf       # Nginx server configuration
│
└── scripts/
    ├── install.sh           # One-command full setup
    ├── health-check.sh      # Automated health monitoring
    └── backup.sh            # Database + keystore backup
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/stats` | Network statistics |
| GET | `/api/blocks?page=1` | Paginated blocks |
| GET | `/api/blocks/:id` | Block by number or hash |
| GET | `/api/transactions?page=1` | Paginated transactions |
| GET | `/api/transactions/:hash` | Transaction details |
| GET | `/api/address/:address` | Address info + transactions |
| GET | `/api/search/:query` | Smart search |

## MetaMask Configuration

To add FyroChain to MetaMask:

1. Open MetaMask → Settings → Networks → Add Network
2. Enter:
   - **Network Name:** FyroMainnet
   - **RPC URL:** https://rpc.fyrochain.com
   - **Chain ID:** 511
   - **Currency Symbol:** FYRO
   - **Block Explorer:** https://fyroscan.org
3. Save and switch to FyroMainnet

## Service Management

```bash
# Node status
systemctl status fyrochain-node

# Explorer backend
systemctl status fyroscan-backend

# Restart services
systemctl restart fyrochain-node
systemctl restart fyroscan-backend

# View logs
journalctl -fu fyrochain-node
journalctl -fu fyroscan-backend
tail -f /var/log/fyrochain/geth.log
```

## Automation

```bash
# Add to crontab
crontab -e

# Health check every 5 minutes
*/5 * * * * /root/fyrochain/scripts/health-check.sh

# Daily backup at 2 AM
0 2 * * * /root/fyrochain/scripts/backup.sh
```

## Social Links

- **GitHub:** https://github.com/Shahreyaarr
- **Instagram:** https://instagram.com/shahreyarr._
- **Twitter:** https://twitter.com/fyrochain
- **Discord:** https://discord.gg/fyrochain

## License

© 2024 FyroChain. All rights reserved.
