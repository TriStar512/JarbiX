import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    """Central configuration for JarbiX - 100% Texas/US CFTC compliant"""

    COMPLIANT_MODE = os.getenv("COMPLIANT_MODE", "true").lower() == "true"
    PAPER_TRADE = os.getenv("PAPER_TRADE", "true").lower() == "true"

    # Supported assets - only these four
    ASSETS = ["BTC", "ETH", "SOL", "XRP"]

    # Legal max leverage per compliant broker (never exceeded)
    BROKER_MAX_LEVERAGE = {
        "coinbase_derivatives": float(os.getenv("MAX_LEVERAGE_COINBASE", 10.0)),
        "bitnomial": float(os.getenv("MAX_LEVERAGE_BITNOMIAL", 6.0)),
        "kraken_us": float(os.getenv("MAX_LEVERAGE_KRAKEN_US", 10.0)),
        "cme_futures": float(os.getenv("MAX_LEVERAGE_CME", 15.0)),
        "paper": 25.0   # Simulation only - for testing higher leverage logic safely
    }

    # Risk settings (conservative and non-negotiable)
    MAX_LOSS_PCT = float(os.getenv("MAX_LOSS_PCT", 0.02))
    MAX_POSITION_SIZE_PCT = float(os.getenv("MAX_POSITION_SIZE_PCT", 0.05))
    MAX_CONCURRENT_TRADES = int(os.getenv("MAX_CONCURRENT_TRADES", 4))
    POSITION_TIMEOUT_MINUTES = int(os.getenv("POSITION_TIMEOUT_MINUTES", 30))

    # Web / Dashboard
    FLASK_PORT = int(os.getenv("FLASK_PORT", 5000))
    SECRET_KEY = os.getenv("SECRET_KEY", "change_this_to_a_strong_random_string")

    # Best trade routing - no duplicate coins
    ENABLE_DUPLICATE_COINS = False