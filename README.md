# JarbiX

**Texas/US CFTC-Compliant Leveraged Crypto Trading Bot**

"trade insane or remain the train" — now 100% legal for Texas residents.

### Features
- Only CFTC-regulated platforms: Coinbase Derivatives, Bitnomial, Kraken Derivatives US, CME futures
- Dynamic leverage: uses up to **100% of each platform's legal max** when signals justify it
- Best-trade routing — assigns each asset (BTC, ETH, SOL, XRP) to **only one broker** at a time
- Multi-timeframe signals, news sentiment, on-chain filters
- Strong risk management (max ~2% loss per trade, position sizing, heat discount, emergency flatten)
- Rich live dashboard, Flask webhooks, SQLite logging
- Paper trading is the safe default

### Quick Start (Paper Mode First!)
1. Click "Add file" → "Create new file" → name it `.env.example` and add the config (I'll give it next)
2. `pip install -r requirements.txt` when you can run it locally
3. Always start with `PAPER_TRADE=true`

**Warning**: Trading involves substantial risk of loss. This is **not** financial or legal advice. Start in paper mode only. Texas residents must follow CFTC rules.
