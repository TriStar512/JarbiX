"""
JarbiX - Main Entry Point
Texas/US CFTC-compliant leveraged crypto trading bot.
Only trades on legal platforms and uses strong risk controls to prevent blow-ups.
"""

import time
from config import Config
from risk import RiskManager
from leverage import calculate_leverage
import dashboard  # We'll create this next

def main():
    print("🚀 Starting JarbiX - Texas Compliant Trading Bot")
    print(f"Paper Mode: {Config.PAPER_TRADE}")
    print(f"Compliant Mode: {Config.COMPLIANT_MODE}")
    
    risk_manager = RiskManager()
    
    # Main trading loop (runs 24/7)
    while True:
        try:
            # Step 1: Generate signals for all assets
            signals = generate_signals()   # We'll implement this in signals.py later
            
            # Step 2: Risk check before doing anything
            if not risk_manager.check_risk(0.0, 0.0):  # placeholder for now
                print("⚠️  Risk limits hit - skipping cycle")
                time.sleep(60)
                continue
            
            # Step 3: Find the BEST trade opportunity (no duplicate coins)
            best_trade = select_best_trade(signals)
            
            if best_trade:
                # Calculate safe leverage (up to 100% of legal max on that broker)
                lev = calculate_leverage(
                    best_trade["signal_strength"],
                    best_trade["sentiment"],
                    best_trade["atr_ratio"],
                    best_trade["portfolio_heat"],
                    best_trade["broker"]
                )
                
                print(f"✅ Best opportunity: {best_trade['asset']} on {best_trade['broker']} @ {lev}x leverage")
                
                # Execute trade (paper or live)
                execute_trade(best_trade, lev, risk_manager)
            
            # Step 4: Generate HTML stats report every hour (like your screenshot)
            if int(time.time()) % 3600 == 0:
                dashboard.generate_html_report()
            
            time.sleep(30)  # Check every 30 seconds
            
        except Exception as e:
            print(f"Error in main loop: {e}")
            time.sleep(60)  # Wait before retrying

# Placeholder functions - we'll fill these in next batches
def generate_signals():
    return []  # Will return list of potential trades

def select_best_trade(signals):
    return None  # Will pick the best one later

def execute_trade(trade, leverage, risk_manager):
    print(f"Executing paper trade for {trade['asset']} at {leverage}x")
    # risk_manager.record_trade(pnl)  # call this after trade closes

if __name__ == "__main__":
    main()