import Foundation

// MARK: - Bot Status

struct BotStatus: Codable {
    let botRunning: Bool
    let paperTrade: Bool
    let portfolioHeat: Double
    let dailyTrades: Int
    let dailyPnl: Double
    let activePositions: [Position]
    let maxDailyTrades: Int
    let lossStreak: Int
    let timestamp: String

    enum CodingKeys: String, CodingKey {
        case botRunning = "bot_running"
        case paperTrade = "paper_trade"
        case portfolioHeat = "portfolio_heat"
        case dailyTrades = "daily_trades"
        case dailyPnl = "daily_pnl"
        case activePositions = "active_positions"
        case maxDailyTrades = "max_daily_trades"
        case lossStreak = "loss_streak"
        case timestamp
    }
}

// MARK: - Position

struct Position: Codable, Identifiable {
    var id: String { "\(asset)-\(broker)-\(entryPrice)" }
    let asset: String
    let broker: String
    let direction: String
    let leverage: Double
    let entryPrice: Double
    let currentPnl: Double

    enum CodingKeys: String, CodingKey {
        case asset, broker, direction, leverage
        case entryPrice = "entry_price"
        case currentPnl = "current_pnl"
    }
}

// MARK: - Signal

struct Signal: Codable, Identifiable {
    var id: String { asset }
    let asset: String
    let signalStrength: Double
    let sentiment: Double
    let atrRatio: Double
    let portfolioHeat: Double
    let direction: String
    let brokerCandidates: [String]

    enum CodingKeys: String, CodingKey {
        case asset, direction, sentiment
        case signalStrength = "signal_strength"
        case atrRatio = "atr_ratio"
        case portfolioHeat = "portfolio_heat"
        case brokerCandidates = "broker_candidates"
    }
}

// MARK: - Trade

struct Trade: Codable, Identifiable {
    let id: Int?
    let asset: String
    let broker: String
    let direction: String
    let signalStrength: Double
    let leverage: Double
    let pnl: Double?
    let timestamp: String

    enum CodingKeys: String, CodingKey {
        case id, asset, broker, direction, leverage, pnl, timestamp
        case signalStrength = "signal_strength"
    }
}

// MARK: - Metrics

struct Metrics: Codable {
    let totalTrades: Int
    let wins: Int
    let losses: Int
    let winRate: Double
    let totalPnl: Double
    let maxDrawdown: Double
    let sharpeRatio: Double
    let profitFactor: Double

    enum CodingKeys: String, CodingKey {
        case wins, losses
        case totalTrades = "total_trades"
        case winRate = "win_rate"
        case totalPnl = "total_pnl"
        case maxDrawdown = "max_drawdown"
        case sharpeRatio = "sharpe_ratio"
        case profitFactor = "profit_factor"
    }
}

// MARK: - Bot Config

struct BotConfig: Codable {
    var paperTrade: Bool
    var maxLossPct: Double
    var maxPositionSizePct: Double
    var maxConcurrentTrades: Int
    var maxDailyTrades: Int

    enum CodingKeys: String, CodingKey {
        case paperTrade = "paper_trade"
        case maxLossPct = "max_loss_pct"
        case maxPositionSizePct = "max_position_size_pct"
        case maxConcurrentTrades = "max_concurrent_trades"
        case maxDailyTrades = "max_daily_trades"
    }
}

// MARK: - API Response Wrappers

struct SignalsResponse: Codable { let signals: [Signal] }
struct TradesResponse: Codable  { let trades: [Trade] }
struct ToggleResponse: Codable  { let botRunning: Bool; enum CodingKeys: String, CodingKey { case botRunning = "bot_running" } }
struct FlattenResponse: Codable { let status: String; let botRunning: Bool; enum CodingKeys: String, CodingKey { case status; case botRunning = "bot_running" } }
struct GenericResponse: Codable { let status: String? }
