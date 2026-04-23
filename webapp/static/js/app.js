/* ── JarbiX PWA — single-file app ───────────────────────────── */
'use strict';

// ── Config ───────────────────────────────────────────────────────
const cfg = {
  get url()      { return localStorage.getItem('serverURL') || ''; },
  set url(v)     { localStorage.setItem('serverURL', v); },
  get interval() { return parseInt(localStorage.getItem('refreshInterval') || '5', 10); },
  set interval(v) { localStorage.setItem('refreshInterval', String(v)); },
};

// ── API ──────────────────────────────────────────────────────────
const api = {
  async _fetch(path, opts = {}) {
    const base = cfg.url || window.location.origin;
    const res = await fetch(base + path, {
      ...opts,
      headers: { 'Content-Type': 'application/json', ...(opts.headers || {}) },
      signal: AbortSignal.timeout(8000),
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return res.json();
  },
  status:  ()         => api._fetch('/api/status'),
  signals: ()         => api._fetch('/api/signals'),
  trades:  (n = 50)   => api._fetch(`/api/trades?limit=${n}`),
  metrics: ()         => api._fetch('/api/metrics'),
  config:  ()         => api._fetch('/api/config'),
  toggle:  ()         => api._fetch('/api/toggle',  { method: 'POST' }),
  flatten: ()         => api._fetch('/api/flatten', { method: 'POST' }),
  saveConfig: (body)  => api._fetch('/api/config',  { method: 'POST', body: JSON.stringify(body) }),
};

// ── State ────────────────────────────────────────────────────────
let state = {
  status: null, signals: [], trades: [], metrics: null, config: null,
  connected: false, activeView: 'dashboard',
};
let refreshTimer = null;

// ── Helpers ──────────────────────────────────────────────────────
const $ = id => document.getElementById(id);
const fmt = {
  pnl:  v => `${v >= 0 ? '+' : ''}$${Math.abs(v).toFixed(2)}`,
  pct:  v => `${(v * 100).toFixed(0)}%`,
  lev:  v => `${v.toFixed(1)}x`,
  num:  v => v.toFixed(2),
  pnlColor: v => v >= 0 ? 'green' : 'red',
};
function heatColor(h) {
  if (h < 0.3) return 'var(--green)';
  if (h < 0.6) return 'var(--yellow)';
  if (h < 0.8) return 'var(--orange)';
  return 'var(--red)';
}
function relTime(date) {
  const s = Math.floor((Date.now() - date) / 1000);
  if (s < 5)  return 'just now';
  if (s < 60) return `${s}s ago`;
  return `${Math.floor(s / 60)}m ago`;
}
function dirBadge(dir) {
  const cls = dir === 'long' ? 'badge-green' : 'badge-red';
  return `<span class="badge ${cls}">${dir.toUpperCase()}</span>`;
}

// ── Tab navigation ───────────────────────────────────────────────
document.querySelectorAll('.tab').forEach(btn => {
  btn.addEventListener('click', () => {
    const view = btn.dataset.view;
    document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
    document.querySelectorAll('.view').forEach(v => v.classList.remove('active'));
    btn.classList.add('active');
    document.getElementById(`view-${view}`).classList.add('active');
    state.activeView = view;
    if (view === 'metrics')  renderMetrics();
    if (view === 'settings') renderSettings();
  });
});

// ── Render functions ─────────────────────────────────────────────

function renderDashboard() {
  const s = state.status;
  const running = s?.bot_running ?? false;

  $('status-dot').className   = `status-dot ${running ? 'running' : 'stopped'}`;
  $('status-label').className = `status-label ${running ? 'running' : 'stopped'}`;
  $('status-label').textContent = running ? 'BOT ACTIVE' : 'BOT STOPPED';

  if (s?.paper_trade) $('paper-badge').classList.remove('hidden');
  else                $('paper-badge').classList.add('hidden');

  if (!s) return;

  // Mini cards
  const pnl = s.daily_pnl ?? 0;
  const heat = s.portfolio_heat ?? 0;
  const streak = s.loss_streak ?? 0;

  $('dash-pnl').textContent   = fmt.pnl(pnl);
  $('dash-pnl').className     = `mini-value ${fmt.pnlColor(pnl)}`;
  $('dash-heat').textContent  = fmt.pct(heat);
  $('dash-heat').className    = `mini-value`;
  $('dash-heat').style.color  = heatColor(heat);
  $('dash-trades').textContent = `${s.daily_trades} / ${s.max_daily_trades}`;
  $('dash-trades').className  = `mini-value ${s.daily_trades >= s.max_daily_trades ? 'red' : ''}`;
  $('dash-streak').textContent = streak;
  $('dash-streak').className  = `mini-value ${streak >= 3 ? 'red' : streak >= 1 ? 'orange' : ''}`;

  // Heat bar
  $('heat-pct').textContent = fmt.pct(heat);
  $('heat-pct').style.color = heatColor(heat);
  const fill = $('heat-fill');
  fill.style.width      = `${Math.min(heat * 100, 100)}%`;
  fill.style.background = heatColor(heat);

  // Positions
  const positions = s.active_positions ?? [];
  if (positions.length === 0) {
    $('positions-list').innerHTML = '<div class="empty-state">No active positions</div>';
  } else {
    $('positions-list').innerHTML = positions.map(p => `
      <div class="position-row">
        <div class="pos-left">
          <div class="pos-asset">${p.asset} ${dirBadge(p.direction)}</div>
          <div class="pos-broker">${(p.broker || '').replace(/_/g, ' ')}</div>
        </div>
        <div class="pos-right">
          <div class="pos-lev">${fmt.lev(p.leverage ?? 1)}</div>
          <div class="pos-pnl ${fmt.pnlColor(p.current_pnl ?? 0)}">${fmt.pnl(p.current_pnl ?? 0)}</div>
        </div>
      </div>`).join('');
  }

  // Controls mirror
  $('ctrl-status').textContent  = running ? 'Running' : 'Stopped';
  $('ctrl-status').className    = `ctrl-status ${running ? 'running' : 'stopped'}`;
  $('ctrl-icon').textContent    = running ? '▶' : '⏹';
  $('btn-toggle').textContent   = running ? 'Stop Bot' : 'Start Bot';
  $('btn-toggle').className     = `btn ${running ? 'btn-stop' : 'btn-start'}`;

  renderSession(s);
}

function renderSession(s) {
  if (!s) return;
  $('session-info').innerHTML = `
    <div class="session-row"><span>Mode</span><span style="color:${s.paper_trade ? 'var(--blue)' : 'var(--orange)'}">
      ${s.paper_trade ? 'Paper Trading' : 'Live Trading'}</span></div>
    <div class="session-row"><span>Broker</span><span>Hyperliquid</span></div>
    <div class="session-row"><span>Active Positions</span><span>${(s.active_positions || []).length}</span></div>
    <div class="session-row"><span>Trades Today</span>
      <span style="color:${s.daily_trades >= s.max_daily_trades ? 'var(--red)' : 'inherit'}">
        ${s.daily_trades} / ${s.max_daily_trades}</span></div>
    <div class="session-row"><span>Loss Streak</span>
      <span style="color:${s.loss_streak >= 3 ? 'var(--red)' : s.loss_streak >= 1 ? 'var(--orange)' : 'inherit'}">
        ${s.loss_streak}</span></div>`;
}

function renderSignals() {
  const assetColors = { BTC: 'var(--orange)', ETH: 'var(--blue)', SOL: 'var(--green)', XRP: 'var(--yellow)' };
  const barColor = { signal_strength: 'var(--green)', sentiment: 'var(--blue)', atr: 'var(--orange)' };

  if (!state.signals.length) {
    $('signals-list').innerHTML = '<div class="empty-state mt-40">Waiting for signals…</div>';
    return;
  }

  $('signals-list').innerHTML = state.signals.map(sig => {
    const color = assetColors[sig.asset] || 'var(--muted)';
    const atrNorm = Math.min((sig.atr_ratio || 0) / 2, 1);
    const score = ((sig.signal_strength * 0.5 + sig.sentiment * 0.3 + atrNorm * 0.2) * 100).toFixed(0);
    const broker = (sig.broker_candidates?.[0] || '').replace(/_/g, ' ');
    return `
      <div class="signal-card" style="border-color:${color}33">
        <div class="sig-header">
          <div>
            <div class="sig-asset">${sig.asset}</div>
            <div class="sig-broker">${broker}</div>
          </div>
          <div>${dirBadge(sig.direction)}</div>
        </div>
        <div class="sig-divider"></div>
        <div class="sig-bar-wrap">
          ${sigBar('Signal Strength', sig.signal_strength, barColor.signal_strength)}
          ${sigBar('Sentiment',       sig.sentiment,       barColor.sentiment)}
          ${sigBar('Volatility (ATR)', atrNorm,            barColor.atr)}
        </div>
        <div class="sig-score"><span>Overall score</span><span>${score} / 100</span></div>
      </div>`;
  }).join('');
}

function sigBar(label, value, color) {
  const pct = Math.round(Math.min(Math.max(value, 0), 1) * 100);
  return `
    <div class="sig-bar">
      <div class="sig-bar-header"><span>${label}</span><span>${pct}%</span></div>
      <div class="bar-track"><div class="bar-fill" style="width:${pct}%;background:${color}"></div></div>
    </div>`;
}

function renderMetrics() {
  const m = state.metrics;
  if (!m) return;

  // Donut
  const wr = m.win_rate ?? 0;
  const circ = 2 * Math.PI * 30; // r=30
  const arc = (wr / 100) * circ;
  $('donut-arc').setAttribute('stroke-dasharray', `${arc.toFixed(1)} ${(circ - arc).toFixed(1)}`);
  const donutColor = wr < 40 ? 'var(--red)' : wr < 55 ? 'var(--orange)' : 'var(--green)';
  $('donut-arc').style.stroke = donutColor;
  $('win-rate-pct').textContent = `${wr.toFixed(0)}%`;
  $('win-rate-pct').style.color = donutColor;
  $('wins-count').textContent   = `Wins: ${m.wins}`;
  $('losses-count').textContent = `Losses: ${m.losses}`;
  $('total-count').textContent  = `Total: ${m.total_trades}`;

  // P&L
  const pnl = m.total_pnl ?? 0;
  $('total-pnl').textContent = fmt.pnl(pnl);
  $('total-pnl').className   = `pnl-value ${fmt.pnlColor(pnl)}`;

  // Stats
  $('sharpe').textContent        = fmt.num(m.sharpe_ratio ?? 0);
  $('profit-factor').textContent = fmt.num(m.profit_factor ?? 0);
  $('max-dd').textContent        = `${((m.max_drawdown || 0) * 100).toFixed(1)}%`;
  $('metrics-total').textContent = m.total_trades;

  // Trade history
  if (!state.trades.length) {
    $('trade-history').innerHTML = '<div class="empty-state">No trades yet</div>';
    return;
  }
  $('trade-history').innerHTML = state.trades.slice(0, 30).map(t => {
    const pnl = t.pnl ?? null;
    return `
      <div class="trade-row">
        <div class="trade-left">
          <div class="trade-asset">${t.asset} ${dirBadge(t.direction)}</div>
          <div class="trade-broker">${(t.broker || '').replace(/_/g, ' ')}</div>
        </div>
        <div class="trade-right">
          <div class="trade-pnl ${pnl !== null ? fmt.pnlColor(pnl) : ''}">${pnl !== null ? fmt.pnl(pnl) : '—'}</div>
          <div class="trade-lev">${fmt.lev(t.leverage ?? 1)}</div>
        </div>
      </div>`;
  }).join('');
}

function renderSettings() {
  $('setting-url').value      = cfg.url;
  $('setting-interval').value = cfg.interval;
  $('interval-label').textContent = `${cfg.interval}s`;

  if (state.config) {
    const c = state.config;
    $('bot-config-list').innerHTML = `
      <div class="config-row"><span>Mode</span><span style="color:${c.paper_trade ? 'var(--blue)' : 'var(--orange)'}">${c.paper_trade ? 'Paper Trading' : 'Live Trading'}</span></div>
      <div class="config-row"><span>Max Loss / Trade</span><span>${(c.max_loss_pct * 100).toFixed(0)}%</span></div>
      <div class="config-row"><span>Max Position Size</span><span>${(c.max_position_size_pct * 100).toFixed(0)}%</span></div>
      <div class="config-row"><span>Max Concurrent</span><span>${c.max_concurrent_trades} trades</span></div>
      <div class="config-row"><span>Max Daily Trades</span><span>${c.max_daily_trades}</span></div>`;
  }
}

// ── Controls wiring ──────────────────────────────────────────────

$('btn-toggle').addEventListener('click', async () => {
  const running = state.status?.bot_running;
  const msg = running ? 'Stop the trading bot?' : 'Start the trading bot?';
  if (!confirm(msg)) return;
  try {
    const res = await api.toggle();
    if (state.status) state.status.bot_running = res.bot_running;
    renderDashboard();
    clearError('ctrl-error');
  } catch (e) { showError('ctrl-error', e.message); }
});

$('btn-flatten').addEventListener('click', async () => {
  if (!confirm('EMERGENCY FLATTEN: close all positions and stop the bot immediately?')) return;
  try {
    await api.flatten();
    await refreshAll();
    clearError('ctrl-error');
    alert('All positions flattened. Bot stopped.');
  } catch (e) { showError('ctrl-error', e.message); }
});

// ── Settings wiring ──────────────────────────────────────────────

$('setting-interval').addEventListener('input', () => {
  $('interval-label').textContent = `${$('setting-interval').value}s`;
});

$('btn-save').addEventListener('click', () => {
  cfg.url      = $('setting-url').value.trim().replace(/\/$/, '');
  cfg.interval = parseInt($('setting-interval').value, 10);
  $('btn-save').textContent = '✓ Saved';
  restartRefresh();
  setTimeout(() => { $('btn-save').textContent = 'Save Settings'; }, 2000);
});

// ── Error helpers ────────────────────────────────────────────────

function showError(id, msg) { const el = $(id); if (el) { el.textContent = msg; el.classList.remove('hidden'); } }
function clearError(id)     { const el = $(id); if (el) el.classList.add('hidden'); }

// ── Connection indicator ─────────────────────────────────────────

function setConnected(ok) {
  state.connected = ok;
  $('conn-dot').className = `conn-dot ${ok ? 'online' : 'offline'}`;
}

// ── Refresh cycle ────────────────────────────────────────────────

let _lastRefresh = null;

async function refreshLive() {
  try {
    const [status, signals] = await Promise.all([api.status(), api.signals()]);
    state.status  = status;
    state.signals = signals.signals || [];
    setConnected(true);
    clearError('dash-error');
    clearError('ctrl-error');
  } catch (e) {
    setConnected(false);
    showError('dash-error', `Cannot reach server: ${e.message}`);
  }
  _lastRefresh = new Date();
  $('last-updated').textContent = relTime(_lastRefresh);
  renderDashboard();
  renderSignals();
}

async function refreshAll() {
  await refreshLive();
  try { const r = await api.trades(100); state.trades = r.trades || []; } catch {}
  try { state.metrics = await api.metrics(); } catch {}
  try { state.config  = await api.config();  } catch {}
  renderMetrics();
  renderSettings();
}

function restartRefresh() {
  clearInterval(refreshTimer);
  refreshAll();
  refreshTimer = setInterval(refreshLive, cfg.interval * 1000);
}

// ── Last-updated ticker ──────────────────────────────────────────

setInterval(() => {
  if (_lastRefresh) $('last-updated').textContent = relTime(_lastRefresh);
}, 5000);

// ── Service worker ───────────────────────────────────────────────

if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/static/sw.js').catch(() => {});
}

// ── Boot ─────────────────────────────────────────────────────────

restartRefresh();
