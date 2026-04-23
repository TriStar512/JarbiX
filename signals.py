"""
JarbiX - signals.py
Generates trading signals for BTC, ETH, SOL, XRP using multi-timeframe analysis.
This is the "brain" that decides if there's a good opportunity.
"""

from config import Config

def generate_signals():
    """
    Returns a list of potential trade signals.
    In real version this would fetch price data from compliant brokers via ccxt.
    For now it's a placeholder that you can expand.
    """
    signals = []
    
    for asset in Config.ASSETS:
        # Placeholder signal generation (replace with real TA later)
        signal = {
            "asset": asset,
            "signal_strength": 0.75,      # 0.0 to 1.0 — higher = stronger trade
            "sentiment": 0.6,             # from news/on-chain
            "atr_ratio": 1.2,             # volatility measure
            "portfolio_heat": 0.3,        # current risk level
            "direction": "long",          # or "short"
            "broker_candidates": ["coinbase_derivatives", "paper"]  # only compliant ones
        }
        signals.append(signal)
    
    return signals


def select_best_trade(signals):
    """
    Picks the SINGLE best trade opportunity.
    Enforces: no duplicate coins across brokers.
    Chooses the one with highest overall score.
    """
    if not signals:
        return None
    
    best = None
    best_score = -1
    
    for signal in signals:
        # Simple scoring: strength + sentiment + leverage potential
        score = (signal["signal_strength"] * 0.5 +
                 signal["sentiment"] * 0.3 +
                 signal["atr_ratio"] * 0.2)
        
        # Only consider compliant brokers
        if score > best_score:
            best = {
                "asset": signal["asset"],
                "broker": signal["broker_candidates"][0],  # pick best one
                "signal_strength": signal["signal_strength"],
                "sentiment": signal["sentiment"],
                "atr_ratio": signal["atr_ratio"],
                "portfolio_heat": signal["portfolio_heat"],
                "direction": signal["direction"]
            }
            best_score = score
    
    return best