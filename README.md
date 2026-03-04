# 🔥 FyroChain — Layer-1 Blockchain Ecosystem

![Chain ID](https://img.shields.io/badge/Chain_ID-511-blue)
![Token](https://img.shields.io/badge/Token-FYRO-orange)
![Supply](https://img.shields.io/badge/Max_Supply-21M-green)
![Consensus](https://img.shields.io/badge/Consensus-PoA_Clique-lightblue)
![License](https://img.shields.io/badge/License-MIT-yellow)

> Built by **Shahreyarr** & **Sadik Anwar** — MSc Cyber Security, Amity University Rajasthan, Jaipur
> Developed under [DigitalEdge Solutions](https://digitaledgesolutions.cloud)

FyroChain is a production-ready Layer-1 blockchain ecosystem including:
- **FyroScan** — Full block explorer at [fyrochain.org](https://fyrochain.org)
- **FyroChain Node** — Geth-based PoA blockchain (Chain ID: 511)
- **FyroDEX** — Decentralized Exchange at [fyrochain.org/dex](https://fyrochain.org/dex)
- **One-Command Install** — Complete automated setup

---

## 🌐 Network Details

| Property | Value |
|---|---|
| Network Name | FyroMainnet |
| Chain ID | 511 |
| Token Symbol | FYRO |
| Max Supply | 21,000,000 FYRO |
| Block Time | ~5 seconds |
| Consensus | Proof of Authority (Clique) |
| RPC URL | https://rpc.fyrochain.org |
| Explorer | https://fyrochain.org |
| DEX | https://fyrochain.org/dex |

---

## 💎 Token Contract (ERC-20)

| Field | Value |
|---|---|
| Contract Address | `0x21213B659c7440ad62E4b5E55246E4750EEa24D4` |
| WFYRO Contract | `0x8BE10A840764404C407025daB4b8c0Cfb5f950f2` |
| DEX Factory | `0x1A78fe8119ef979025989E2aDDAf47B3FA71177e` |
| DEX Router | `0x7E9f78A8326eb2839282238d25B72c35a2b3d63B` |
| Standard | ERC-20 |
| Max Supply | 21,000,000 FYRO |
| Team Allocation | 2,100,000 FYRO (10%) |
| Halving Interval | Every 210,000 blocks |
| Total Halvings | 64 |

---

## 🚀 Quick Start (Ubuntu 22.04)
```bash
# Clone project
git clone https://github.com/fyrochain/FyroBlockchain /root/fyrochain
cd /root/fyrochain

# Run one-command install
sudo bash scripts/install.sh
```

---

## 📁 Project Structure
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
├── dex/                     # FyroDEX — Decentralized Exchange
│   └── index.html
│
├── website/                 # fyrochain.org landing page
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

---

## 🔌 API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/stats` | Network statistics |
| GET | `/api/blocks?page=1` | Paginated blocks |
| GET | `/api/blocks/:id` | Block by number or hash |
| GET | `/api/transactions?page=1` | Paginated transactions |
| GET | `/api/transactions/:hash` | Transaction details |
| GET | `/api/address/:address` | Address info + transactions |
| GET | `/api/search/:query` | Smart search |

---

## 🦊 Add to MetaMask

1. Open MetaMask → Settings → Networks → **Add Network**
2. Enter details:

| Field | Value |
|---|---|
| Network Name | FyroMainnet |
| RPC URL | `https://rpc.fyrochain.org` |
| Chain ID | `511` |
| Currency Symbol | `FYRO` |
| Block Explorer | `https://fyrochain.org` |

3. Save and switch to FyroMainnet ✅

---

## ⚙️ Service Management
```bash
# Node status
pm2 status

# Restart explorer
pm2 restart fyroscan

# View logs
pm2 logs fyroscan

# Health check
bash /root/fyrochain/scripts/health-check.sh
```

---

## 🕐 Automation (Crontab)
```bash
# Edit crontab
crontab -e

# Health check every 5 minutes
*/5 * * * * /root/fyrochain/scripts/health-check.sh

# Daily backup at 2 AM
0 2 * * * /root/fyrochain/scripts/backup.sh
```

---

## 🔗 Links

| Platform | Link |
|---|---|
| 🌐 Explorer | https://fyrochain.org |
| ⚡ DEX | https://fyrochain.org/dex |
| 📄 Whitepaper | https://fyrochain.org/whitepaper.pdf |
| 💬 Telegram | https://t.me/fyrochain |
| 🐦 Twitter | https://twitter.com/fyrochain |
| 💻 GitHub | https://github.com/fyrochain |
| 🏢 Company | https://digitaledgesolutions.cloud |

---

## 👨‍💻 Developers

**Shahreyarr** & **Sadik Anwar**
MSc Cyber Security — Amity University Rajasthan, Jaipur
[DigitalEdge Solutions](https://digitaledgesolutions.cloud)

> *FyroChain — Student-built, production-ready Layer-1 blockchain.*

---

## 📜 License

MIT License © 2026 FyroChain — DigitalEdge Solutions
