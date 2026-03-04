// FyroScan App.js - Core utilities, navbar, footer, search

const API_BASE = '/api';

// ─── API Fetch ────────────────────────────────────────────
async function apiFetch(endpoint) {
  try {
    const res = await fetch(API_BASE + endpoint);
    if (!res.ok) return null;
    return await res.json();
  } catch (e) {
    console.warn('[API] Fetch error:', e.message);
    return null;
  }
}

// ─── Formatting ───────────────────────────────────────────
function formatNumber(n) {
  if (n === null || n === undefined) return '—';
  return Number(n).toLocaleString('en-US');
}

function truncateHash(hash, start = 6, end = 4) {
  if (!hash) return '—';
  if (hash.length <= start + end + 3) return hash;
  return `${hash.slice(0, start)}...${hash.slice(-end)}`;
}

function formatFyro(wei, decimals = 4) {
  if (!wei || wei === '0') return '0 FYRO';
  try {
    const val = BigInt(wei);
    const eth = Number(val) / 1e18;
    return `${eth.toFixed(decimals)} FYRO`;
  } catch { return '0 FYRO'; }
}

function formatGwei(gasPrice) {
  if (!gasPrice) return '—';
  try {
    const gwei = Number(BigInt(gasPrice)) / 1e9;
    return `${gwei.toFixed(2)} Gwei`;
  } catch { return '—'; }
}

function timeAgo(timestamp) {
  if (!timestamp) return '—';
  const diff = Math.floor((Date.now() - new Date(timestamp)) / 1000);
  if (diff < 60) return `${diff} secs ago`;
  if (diff < 3600) return `${Math.floor(diff / 60)} mins ago`;
  if (diff < 86400) return `${Math.floor(diff / 3600)} hrs ago`;
  return `${Math.floor(diff / 86400)} days ago`;
}

function fullDate(timestamp) {
  if (!timestamp) return '—';
  return new Date(timestamp).toLocaleString('en-US', {
    year: 'numeric', month: 'short', day: 'numeric',
    hour: '2-digit', minute: '2-digit', second: '2-digit', timeZoneName: 'short'
  });
}

function statusBadge(status) {
  if (status === 1 || status === '1' || status === true) {
    return `<span class="badge badge-success">Success</span>`;
  }
  if (status === 0 || status === '0' || status === false) {
    return `<span class="badge badge-fail">Failed</span>`;
  }
  return `<span class="badge badge-pending">Pending</span>`;
}

function getParam(key) {
  return new URLSearchParams(window.location.search).get(key);
}

function copyToClipboard(text, btn) {
  navigator.clipboard.writeText(text).then(() => {
    const orig = btn.textContent;
    btn.textContent = 'Copied!';
    btn.style.color = '#21c87a';
    setTimeout(() => { btn.textContent = orig; btn.style.color = ''; }, 2000);
  });
}

let _refreshTimer = null;
function autoRefresh(fn, interval = 15000) {
  fn();
  _refreshTimer = setInterval(fn, interval);
}

// ─── Search ───────────────────────────────────────────────
async function doSearch(query) {
  const q = (query || '').trim();
  if (!q) return;
  const result = await apiFetch(`/search/${encodeURIComponent(q)}`);
  if (result && result.redirect) {
    window.location.href = result.redirect;
  } else {
    alert('No results found for: ' + q);
  }
}

// ─── Navbar ───────────────────────────────────────────────
function renderNavbar(activePage) {
  const navEl = document.getElementById('navbar');
  if (!navEl) return;

  navEl.innerHTML = `
    <nav class="navbar">
      <div class="navbar-inner">
        <a href="index.html" class="logo">
         <img src="https://fyroscan.org/logo192.png" alt="FyroScan" class="logo-img" style="width:48px;height:48px;object-fit:contain;" onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">
         <span class="logo-fallback" style="display:none;"></span>
          <span></span>
        </a>

        <ul class="nav-links">
          <li><a href="index.html" class="${activePage === 'home' ? 'active' : ''}">Home</a></li>
          <li class="nav-dropdown">
            <a href="blocks.html" class="${activePage === 'blocks' ? 'active' : ''}">Blockchain ▾</a>
            <ul class="dropdown-menu">
              <li><a href="blocks.html">View Blocks</a></li>
              <li><a href="txs.html">View Transactions</a></li>
            </ul>
          </li>
          <li><a href="txs.html" class="${activePage === 'txs' ? 'active' : ''}">Transactions</a></li>
          <li><a href="#" class="">Resources</a></li>
          <li><a href="#" class="">Developers</a></li>
        </ul>

        <div class="nav-search-wrapper" id="navSearchWrapper">
          <input type="text" class="nav-search-input" id="navSearchInput" placeholder="Search by Address / Txn Hash / Block">
          <button class="nav-search-btn" id="navSearchBtn">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg>
          </button>
        </div>

        <a href="#" class="btn-signin">Sign In</a>
        <button class="mobile-menu-btn" id="mobileMenuBtn">☰</button>
      </div>
    </nav>
    <div class="mobile-nav" id="mobileNav">
      <a href="index.html">Home</a>
      <a href="blocks.html">Blockchain</a>
      <a href="txs.html">Transactions</a>
      <a href="#">Resources</a>
    </div>
  `;

  // Search handlers
  const input = document.getElementById('navSearchInput');
  const btn = document.getElementById('navSearchBtn');
  if (btn) btn.onclick = () => doSearch(input.value);
  if (input) input.addEventListener('keydown', e => { if (e.key === 'Enter') doSearch(input.value); });

  // Mobile menu
  const mobileBtn = document.getElementById('mobileMenuBtn');
  const mobileNav = document.getElementById('mobileNav');
  if (mobileBtn) mobileBtn.onclick = () => mobileNav.classList.toggle('open');
}

// ─── Footer ───────────────────────────────────────────────
function renderFooter() {
  const el = document.getElementById('footer');
  if (!el) return;
  el.innerHTML = `
    <div style="background:#f8fafc;border-top:1px solid #e2e8f0;padding:12px 40px;display:flex;align-items:center;justify-content:space-between;">
      <div style="display:flex;gap:10px;">
        <a href="#" style="width:32px;height:32px;border:1px solid #e2e8f0;border-radius:6px;display:flex;align-items:center;justify-content:center;color:#64748b;font-size:13px;background:#fff;text-decoration:none;">𝕏</a>
        <a href="#" style="width:32px;height:32px;border:1px solid #e2e8f0;border-radius:6px;display:flex;align-items:center;justify-content:center;color:#64748b;font-size:13px;background:#fff;text-decoration:none;">⬡</a>
        <a href="#" style="width:32px;height:32px;border:1px solid #e2e8f0;border-radius:6px;display:flex;align-items:center;justify-content:center;color:#64748b;font-size:13px;background:#fff;text-decoration:none;">f</a>
        <a href="#" style="width:32px;height:32px;border:1px solid #e2e8f0;border-radius:6px;display:flex;align-items:center;justify-content:center;color:#64748b;font-size:13px;background:#fff;text-decoration:none;">r</a>
      </div>
      <a href="#" onclick="window.scrollTo({top:0,behavior:'smooth'});return false;" style="font-size:13px;color:#64748b;text-decoration:none;">⬆ Back to Top</a>
    </div>

    <footer style="background:#fff;border-top:1px solid #e2e8f0;padding:48px 40px 24px;">
      <div style="max-width:1280px;margin:0 auto;">

        <div style="display:grid;grid-template-columns:1.4fr 1fr 1fr 1fr;gap:48px;padding-bottom:40px;border-bottom:1px solid #e2e8f0;">

          <!-- Brand col -->
          <div>
            <div style="display:flex;align-items:center;gap:10px;margin-bottom:14px;">
              <img src="https://fyroscan.org/logo192.png" style="width:30px;height:30px;border-radius:6px;" onerror="this.style.display='none'">
              <span style="font-size:15px;font-weight:700;color:#0f172a;">Powered by <span style="color:#2563eb;">FyroChain</span></span>
            </div>
            <p style="font-size:13px;color:#64748b;line-height:1.8;margin-bottom:20px;">FyroScan is a Block Explorer and Analytics Platform for FyroChain, a decentralized smart contracts platform.</p>
            <div style="width:100%;height:90px;background:url('https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Blue_world_map.svg/600px-Blue_world_map.svg.png') no-repeat center/contain;opacity:0.12;"></div>
          </div>

          <!-- Company col -->
          <div>
            <div style="font-size:12px;font-weight:700;color:#0f172a;margin-bottom:18px;text-transform:uppercase;letter-spacing:0.6px;">Company</div>
            <div style="display:flex;flex-direction:column;gap:11px;">
              <a href="#" style="font-size:13px;color:#64748b;text-decoration:none;">About Us</a>
              <a href="#" style="font-size:13px;color:#64748b;text-decoration:none;">Brand Assets</a>
              <a href="#" style="font-size:13px;color:#64748b;text-decoration:none;">Contact Us</a>
              <a href="#" style="font-size:13px;color:#64748b;text-decoration:none;display:flex;align-items:center;gap:8px;">Careers <span style="background:#2563eb;color:#fff;font-size:10px;padding:2px 8px;border-radius:20px;font-weight:600;">We're Hiring!</span></a>
              <a href="#" style="font-size:13px;color:#64748b;text-decoration:none;">Terms & Privacy</a>
              <a href="#" style="font-size:13px;color:#64748b;text-decoration:none;">Bug Bounty</a>
            </div>
          </div>

          <!-- Community col -->
          <div>
            <div style="font-size:12px;font-weight:700;color:#0f172a;margin-bottom:18px;text-transform:uppercase;letter-spacing:0.6px;">Community</div>
            <div style="display:flex;flex-direction:column;gap:11px;">
              <a href="#" style="font-size:13px;color:#64748b;text-decoration:none;">API Documentation</a>
              <a href="#" style="font-size:13px;color:#64748b;text-decoration:none;">Knowledge Base</a>
              <a href="#" style="font-size:13px;color:#64748b;text-decoration:none;">Network Status</a>
              <a href="#" style="font-size:13px;color:#64748b;text-decoration:none;">Newsletters</a>
            </div>
          </div>

          <!-- Products col -->
          <div>
            <div style="font-size:12px;font-weight:700;color:#0f172a;margin-bottom:18px;text-transform:uppercase;letter-spacing:0.6px;">Products & Services</div>
            <div style="display:flex;flex-direction:column;gap:11px;">
              <a href="#" style="font-size:13px;color:#64748b;text-decoration:none;">Advertise</a>
              <a href="#" style="font-size:13px;color:#64748b;text-decoration:none;">Explorer as a Service (EaaS)</a>
              <a href="#" style="font-size:13px;color:#64748b;text-decoration:none;">API Plans</a>
              <a href="#" style="font-size:13px;color:#64748b;text-decoration:none;">Priority Support</a>
              <a href="#" style="font-size:13px;color:#64748b;text-decoration:none;">FyroScan ↗</a>
              <a href="#" style="font-size:13px;color:#64748b;text-decoration:none;">FyroScan Chat ↗</a>
            </div>
          </div>

        </div>

        <!-- Bottom bar -->
        <div style="display:flex;align-items:center;justify-content:space-between;padding-top:20px;flex-wrap:wrap;gap:12px;">
          <p style="font-size:12.5px;color:#94a3b8;">FyroScan © ${new Date().getFullYear()} (D1)</p>
          <p style="font-size:12.5px;color:#94a3b8;">
            Donations: <a href="#" style="color:#2563eb;font-family:monospace;font-size:12px;">0xE2c9754f1BFae4bb8BcC096e4A88efd0fDBf201b</a> ❤️
          </p>
        </div>

      </div>
    </footer>
  `;
}

// ─── Init Page ────────────────────────────────────────────
function initPage(activePage) {
  renderNavbar(activePage);
  renderFooter();
}