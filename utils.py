"""
JarbiX - utils.py
Helper functions used across the bot.
"""

import time
from datetime import datetime
from config import Config

def log_trade(asset: str, broker: str, leverage: float, pnl: float = 0.0):
    """Simple logging for every trade attempt"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    status = "PAPER" if Config.PAPER_TRADE else "LIVE"
    print(f"[{timestamp}] {status} | {asset} on {broker} @ {leverage}x | PnL: ${pnl:.2f}")


def get_current_time():
    """Returns current timestamp for reports"""
    return datetime.now()


def clamp(value: float, min_val: float, max_val: float) -> float:
    """Keep a number between min and max (used in leverage and risk)"""
    return max(min_val, min(value, max_val))