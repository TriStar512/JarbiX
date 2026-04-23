"""
JarbiX REST API — serves the iOS companion app.
Run independently: python api.py
Or import and call run_api() in a background thread from main.py.
"""

import sqlite3
import os
import time
import threading
from datetime import datetime
from flask import Flask, jsonify, request
from config import Config
from risk import RiskManager
from signals import generate_signals

app = Flask(__name__)

# Shared state (in production, back with Redis or a DB)
_state_lock = threading.Lock()
_bot_state = {
    "running": False,
    "paper_trade": Config.PAPER_TRADE,
    "active_positions": [],
    "daily_pnl": 0.0,
}

_risk = RiskManager()


# ── helpers ───────────────────────────────────────────────────────────────────

def _db_trades(limit: int = 50):
    try:
        conn = sqlite3.connect("jarbix.db")
        conn.row_factory = sqlite3.Row
        cur = conn.cursor()
        cur.execute(
            "SELECT * FROM trades ORDER BY timestamp DESC LIMIT ?", (limit,)
        )
        rows = [dict(r) for r in cur.fetchall()]
        conn.close()
        return rows
    except Exception:
        return []


def _cors(resp):
    resp.headers["Access-Control-Allow-Origin"] = "*"
    return resp


# ── endpoints ─────────────────────────────────────────────────────────────────

@app.route("/api/status")
def get_status():
    with _state_lock:
        state = dict(_bot_state)
    return _cors(jsonify({
        "bot_running": state["running"],
        "paper_trade": state["paper_trade"],
        "portfolio_heat": round(_risk.calculate_portfolio_heat({}), 3),
        "daily_trades": _risk.daily_trade_count,
        "daily_pnl": round(state["daily_pnl"], 2),
        "active_positions": state["active_positions"],
        "max_daily_trades": Config.MAX_DAILY_TRADES,
        "loss_streak": _risk.daily_loss_streak,
        "timestamp": datetime.utcnow().isoformat() + "Z",
    }))


@app.route("/api/signals")
def get_signals():
    try:
        sigs = generate_signals()
    except Exception:
        sigs = []
    return _cors(jsonify({"signals": sigs}))


@app.route("/api/trades")
def get_trades():
    limit = request.args.get("limit", 50, type=int)
    return _cors(jsonify({"trades": _db_trades(limit)}))


@app.route("/api/metrics")
def get_metrics():
    trades = _db_trades(1000)
    total = len(trades)
    wins = sum(1 for t in trades if (t.get("pnl") or 0) > 0)
    losses = total - wins
    total_pnl = sum((t.get("pnl") or 0) for t in trades)
    win_rate = (wins / total * 100) if total > 0 else 0.0

    gross_profit = sum((t.get("pnl") or 0) for t in trades if (t.get("pnl") or 0) > 0)
    gross_loss = abs(sum((t.get("pnl") or 0) for t in trades if (t.get("pnl") or 0) < 0))
    profit_factor = (gross_profit / gross_loss) if gross_loss > 0 else 0.0

    return _cors(jsonify({
        "total_trades": total,
        "wins": wins,
        "losses": losses,
        "win_rate": round(win_rate, 1),
        "total_pnl": round(total_pnl, 2),
        "max_drawdown": 0.0,
        "sharpe_ratio": 0.0,
        "profit_factor": round(profit_factor, 2),
    }))


@app.route("/api/config", methods=["GET", "POST"])
def config_endpoint():
    if request.method == "GET":
        return _cors(jsonify({
            "paper_trade": Config.PAPER_TRADE,
            "max_loss_pct": Config.MAX_LOSS_PCT,
            "max_position_size_pct": Config.MAX_POSITION_SIZE_PCT,
            "max_concurrent_trades": Config.MAX_CONCURRENT_TRADES,
            "max_daily_trades": Config.MAX_DAILY_TRADES,
        }))
    # POST — accept but don't persist (runtime override only)
    data = request.get_json(silent=True) or {}
    if "paper_trade" in data:
        with _state_lock:
            _bot_state["paper_trade"] = bool(data["paper_trade"])
    return _cors(jsonify({"status": "updated"}))


@app.route("/api/toggle", methods=["POST"])
def toggle_bot():
    with _state_lock:
        _bot_state["running"] = not _bot_state["running"]
        running = _bot_state["running"]
    return _cors(jsonify({"bot_running": running}))


@app.route("/api/flatten", methods=["POST"])
def emergency_flatten():
    with _state_lock:
        _bot_state["active_positions"] = []
        _bot_state["running"] = False
    return _cors(jsonify({"status": "flattened", "bot_running": False}))


@app.after_request
def after_request(resp):
    resp.headers["Access-Control-Allow-Origin"] = "*"
    resp.headers["Access-Control-Allow-Headers"] = "Content-Type"
    resp.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
    return resp


def run_api(host: str = "0.0.0.0", port: int = None, debug: bool = False):
    port = port or int(os.getenv("FLASK_PORT", 5000))
    app.run(host=host, port=port, debug=debug, use_reloader=False)


if __name__ == "__main__":
    run_api()
