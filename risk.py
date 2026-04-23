from config import Config
import time

class RiskManager:
    def __init__(self):
        self.daily_trade_count = 0
        self.last_trade_time = 0
        self.daily_loss_streak = 0
        self.session_start = time.time()
    
    def check_risk(self, position_size_pct: float, portfolio_heat: float, current_loss_pct: float = 0.0) -> bool:
        """Core risk checks to prevent blow-up"""
        if position_size_pct > Config.MAX_POSITION_SIZE_PCT:
            return False
        if current_loss_pct > Config.MAX_LOSS_PCT:
            return False
        if portfolio_heat > 0.8:
            return False
        if self.daily_trade_count >= Config.MAX_DAILY_TRADES:
            return False
        if time.time() - self.last_trade_time < 300 and self.daily_loss_streak > 0:  # 5-min cool-off after loss
            return False
        return True
    
    def calculate_portfolio_heat(self, positions) -> float:
        """Simple but effective heat calculation"""
        total_exposure = sum(p.get("notional", 0) for p in positions.values())
        return min(total_exposure / 100_000, 1.0)   # adjust denominator based on your account size later
    
    def record_trade(self, pnl: float):
        """Track daily stats to prevent overtrading"""
        self.daily_trade_count += 1
        self.last_trade_time = time.time()
        if pnl < 0:
            self.daily_loss_streak += 1
        else:
            self.daily_loss_streak = 0