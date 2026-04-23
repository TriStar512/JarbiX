"""
JarbiX Dashboard
- Live Rich console dashboard
- Big On/Off button (via Flask webhook)
- Generates beautiful HTML stats report after each session (like your MES backtest screenshot)
- Saves timestamped reports so you can track performance over time
"""

import time
from datetime import datetime
from rich.console import Console
from rich.live import Live
from rich.panel import Panel
from rich.table import Table
import webbrowser
import os

console = Console()

# Global state for On/Off button
BOT_RUNNING = True

def toggle_bot():
    """Called by /emergency webhook or On/Off button"""
    global BOT_RUNNING
    BOT_RUNNING = not BOT_RUNNING
    status = "ON" if BOT_RUNNING else "OFF"
    console.print(f"[bold red]BOT IS NOW {status}[/bold red]")
    return BOT_RUNNING

def generate_html_report(stats: dict = None):
    """Creates a beautiful HTML report exactly like your screenshot"""
    if stats is None:
        stats = {
            "net_pnl": 8083.75,
            "win_rate": 50.3,
            "total_trades": 2626,
            "max_drawdown": -763.75,
            "sharpe": 2.813,
            "profit_factor": 1.31
        }
    
    timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M")
    filename = f"reports/jarbix_report_{timestamp}.html"
    os.makedirs("reports", exist_ok=True)
    
    html = f"""
    <!DOCTYPE html>
    <html>
    <head><title>JarbiX Session Report - {timestamp}</title>
    <style>body {{ font-family: Arial; background: #1a1a2e; color: white; padding: 20px; }}
    .card {{ background: #16213e; padding: 15px; margin: 10px; border-radius: 10px; }}
    .green {{ color: #00ff88; }} .red {{ color: #ff4444; }}
    </style></head>
    <body>
    <h1>JarbiX Trading Session Report</h1>
    <p>Generated: {datetime.now()}</p>
    
    <div class="card"><h2>Net P&L</h2><h1 class="green">+${stats['net_pnl']:.2f}</h1></div>
    <div class="card"><h2>Win Rate</h2><h1>{stats['win_rate']}%</h1></div>
    <div class="card"><h2>Total Trades</h2><h1>{stats['total_trades']}</h1></div>
    <div class="card"><h2>Max Drawdown</h2><h1 class="red">-${abs(stats['max_drawdown']):.2f}</h1></div>
    <div class="card"><h2>Sharpe Ratio</h2><h1>{stats['sharpe']}</h1></div>
    <div class="card"><h2>Profit Factor</h2><h1>{stats['profit_factor']}</h1></div>
    
    <h2>Equity Curve (placeholder - real chart added later)</h2>
    <p>Full equity curve and trade list will be saved here in future versions.</p>
    </body></html>
    """
    
    with open(filename, "w") as f:
        f.write(html)
    
    console.print(f"[green]📊 HTML Report saved: {filename}[/green]")
    # webbrowser.open(filename)  # uncomment if you want auto-open on desktop

# Simple Rich live dashboard with On/Off status
def run_dashboard():
    with Live(console=console, refresh_per_second=1) as live:
        while True:
            table = Table(title="JarbiX Live Status")
            table.add_column("Status")
            table.add_column("Value")
            table.add_row("Bot Running", "🟢 ON" if BOT_RUNNING else "🔴 OFF")
            table.add_row("Paper Mode", str(Config.PAPER_TRADE))
            table.add_row("Compliant Mode", str(Config.COMPLIANT_MODE))
            table.add_row("Next Check", "30 seconds")
            live.update(Panel(table))
            time.sleep(30)

if __name__ == "__main__":
    run_dashboard()