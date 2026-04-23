import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    """Central configuration for JarbiX — Hyperliquid perpetuals."""

    PAPER_TRADE = os.getenv("PAPER_TRADE", "true").lower() == "true"

    # Supported assets
    ASSETS = ["BTC", "ETH", "SOL", "XRP"]

    # Hyperliquid supports up to 50x on most pairs.
    # We cap conservatively; tweak per-asset via env if needed.
    BROKER_MAX_LEVERAGE = {
        "hyperliquid": float(os.getenv("MAX_LEVERAGE_HYPERLIQUID", 50.0)),
        "paper":       float(os.getenv("MAX_LEVERAGE_PAPER",       50.0)),
    }

    # Primary broker — always Hyperliquid (or paper for simulation)
    PRIMARY_BROKER = "paper" if PAPER_TRADE else "hyperliquid"

    # Risk controls (conservative defaults — do not loosen without understanding them)
    MAX_LOSS_PCT           = float(os.getenv("MAX_LOSS_PCT",            0.02))
    MAX_POSITION_SIZE_PCT  = float(os.getenv("MAX_POSITION_SIZE_PCT",   0.05))
    MAX_CONCURRENT_TRADES  = int(os.getenv("MAX_CONCURRENT_TRADES",     4))
    MAX_DAILY_TRADES       = int(os.getenv("MAX_DAILY_TRADES",          12))
    POSITION_TIMEOUT_MINUTES = int(os.getenv("POSITION_TIMEOUT_MINUTES", 30))

    # API — iOS companion app connects here
    FLASK_PORT  = int(os.getenv("FLASK_PORT",  5000))
    SECRET_KEY  = os.getenv("SECRET_KEY", "change_this_in_production")

    # Hyperliquid credentials (set in .env for live trading)
    HL_WALLET_ADDRESS  = os.getenv("HL_WALLET_ADDRESS",  "")
    HL_PRIVATE_KEY     = os.getenv("HL_PRIVATE_KEY",     "")

    # No duplicate coin exposure across positions
    ENABLE_DUPLICATE_COINS = False
