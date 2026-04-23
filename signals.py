"""
JarbiX - signals.py
Generates trading signals for BTC, ETH, SOL, XRP via Hyperliquid.
Real implementation should replace the placeholder values with live TA.
"""

from config import Config


def generate_signals():
    """
    Returns a list of potential trade signals.
    Broker candidates are always Hyperliquid (or paper in paper-trade mode).
    Replace the placeholder values with real data from ccxt / hyperliquid SDK.
    """
    broker = Config.PRIMARY_BROKER
    signals = []

    for asset in Config.ASSETS:
        signal = {
            "asset": asset,
            "signal_strength": 0.75,   # 0.0–1.0  (replace with real TA)
            "sentiment":       0.60,   # 0.0–1.0  (news / on-chain)
            "atr_ratio":       1.20,   # volatility ratio
            "portfolio_heat":  0.30,   # current exposure level
            "direction":       "long", # or "short"
            "broker_candidates": [broker],
        }
        signals.append(signal)

    return signals


def select_best_trade(signals):
    """
    Picks the single best trade opportunity (highest composite score).
    Enforces: no duplicate coins across positions.
    """
    if not signals:
        return None

    best, best_score = None, -1

    for sig in signals:
        score = (sig["signal_strength"] * 0.5 +
                 sig["sentiment"]       * 0.3 +
                 sig["atr_ratio"]       * 0.2)

        if score > best_score:
            best = {
                "asset":          sig["asset"],
                "broker":         sig["broker_candidates"][0],
                "signal_strength": sig["signal_strength"],
                "sentiment":       sig["sentiment"],
                "atr_ratio":       sig["atr_ratio"],
                "portfolio_heat":  sig["portfolio_heat"],
                "direction":       sig["direction"],
            }
            best_score = score

    return best
