from config import Config

def calculate_leverage(signal_strength: float, sentiment: float, atr_ratio: float, portfolio_heat: float, broker: str) -> float:
    """
    Scales leverage up to 100% of the platform's LEGAL max ONLY when the signal is strong.
    Never exceeds platform limits or risk rules.
    """
    max_lev = Config.BROKER_MAX_LEVERAGE.get(broker, 5.0)
    
    base = 2.0
    proposed = base * (1 + sentiment * 0.5) * min(atr_ratio, 1.5) * max(0.5, 1 - portfolio_heat)
    proposed *= (0.5 + 0.5 * signal_strength)   # stronger signal = higher leverage
    
    final_lev = max(1.0, min(proposed, max_lev))
    
    # Extra safety — never go high if heat is rising
    if portfolio_heat > 0.6:
        final_lev = min(final_lev, 3.0)
    
    return round(final_lev, 2)