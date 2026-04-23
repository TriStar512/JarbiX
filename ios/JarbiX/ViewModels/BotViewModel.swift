import Foundation
import Combine

@MainActor
final class BotViewModel: ObservableObject {

    // MARK: Published state

    @Published var status: BotStatus?
    @Published var signals: [Signal] = []
    @Published var trades: [Trade] = []
    @Published var metrics: Metrics?
    @Published var config: BotConfig?

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdated = Date()
    @Published var isConnected = false

    // MARK: Private

    private let api = APIService.shared
    private var refreshTimer: Timer?
    private(set) var refreshInterval: TimeInterval = 5

    // MARK: Init

    init() {
        startAutoRefresh(interval: refreshInterval)
    }

    deinit {
        refreshTimer?.invalidate()
    }

    // MARK: Refresh control

    func startAutoRefresh(interval: TimeInterval = 5) {
        refreshInterval = interval
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { await self?.refreshLive() }
        }
        Task { await refreshLive() }
    }

    func refreshLive() async {
        await fetchStatus()
        await fetchSignals()
    }

    func fetchAll() async {
        isLoading = true
        defer { isLoading = false }
        await fetchStatus()
        await fetchSignals()
        await fetchTrades()
        await fetchMetrics()
        await fetchConfig()
        lastUpdated = Date()
    }

    // MARK: Individual fetches

    func fetchStatus() async {
        do {
            status = try await api.getStatus()
            isConnected = true
            errorMessage = nil
        } catch {
            isConnected = false
            errorMessage = error.localizedDescription
        }
        lastUpdated = Date()
    }

    func fetchSignals() async {
        do { signals = try await api.getSignals().signals } catch {}
    }

    func fetchTrades() async {
        do { trades = try await api.getTrades(limit: 100).trades } catch {}
    }

    func fetchMetrics() async {
        do { metrics = try await api.getMetrics() } catch {}
    }

    func fetchConfig() async {
        do { config = try await api.getConfig() } catch {}
    }

    // MARK: Actions

    func toggleBot() async {
        do {
            let resp = try await api.toggleBot()
            if var s = status {
                // Patch locally while we wait for next poll
                status = BotStatus(
                    botRunning: resp.botRunning, paperTrade: s.paperTrade,
                    portfolioHeat: s.portfolioHeat, dailyTrades: s.dailyTrades,
                    dailyPnl: s.dailyPnl, activePositions: s.activePositions,
                    maxDailyTrades: s.maxDailyTrades, lossStreak: s.lossStreak,
                    timestamp: s.timestamp
                )
                _ = s // suppress warning
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func emergencyFlatten() async {
        do {
            _ = try await api.emergencyFlatten()
            await fetchStatus()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveConfig(_ cfg: BotConfig) async {
        do {
            try await api.updateConfig(cfg)
            config = cfg
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateServerURL(_ url: String, refreshInterval interval: TimeInterval) {
        api.updateBaseURL(url)
        startAutoRefresh(interval: interval)
    }
}
