import SwiftUI

// MARK: - Metrics

struct MetricsView: View {
    @EnvironmentObject var vm: BotViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    if let m = vm.metrics {
                        WinRateCard(metrics: m)
                        TotalPnLCard(pnl: m.totalPnl)

                        HStack(spacing: 14) {
                            StatCard(title: "Sharpe",        value: String(format: "%.2f", m.sharpeRatio),            icon: "chart.bar.fill")
                            StatCard(title: "Profit Factor", value: String(format: "%.2f", m.profitFactor),            icon: "multiply.circle.fill")
                        }
                        HStack(spacing: 14) {
                            StatCard(title: "Max Drawdown",  value: String(format: "%.1f%%", m.maxDrawdown * 100),     icon: "arrow.down.right.circle.fill", valueColor: .red)
                            StatCard(title: "Total Trades",  value: "\(m.totalTrades)",                                icon: "arrow.left.arrow.right.circle.fill")
                        }
                    } else {
                        ProgressView("Loading metrics…").padding(40)
                    }

                    if !vm.trades.isEmpty {
                        TradeHistoryCard(trades: vm.trades)
                    }

                    if let err = vm.errorMessage {
                        ErrorBanner(message: err)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Metrics")
            .refreshable {
                await vm.fetchMetrics()
                await vm.fetchTrades()
            }
            .task {
                await vm.fetchMetrics()
                await vm.fetchTrades()
            }
        }
    }
}

// MARK: - Win Rate Card

struct WinRateCard: View {
    let metrics: Metrics

    private var color: Color {
        switch metrics.winRate {
        case ..<40: return .red
        case 40..<55: return .orange
        default: return .green
        }
    }

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color(.tertiarySystemGroupedBackground), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: metrics.winRate / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 0.6), value: metrics.winRate)
                VStack(spacing: 2) {
                    Text(String(format: "%.0f%%", metrics.winRate))
                        .font(.title3).fontWeight(.bold)
                    Text("Win Rate").font(.caption2).foregroundStyle(.secondary)
                }
            }
            .frame(width: 96, height: 96)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Circle().fill(.green).frame(width: 8, height: 8)
                    Text("Wins: \(metrics.wins)").font(.subheadline)
                }
                HStack(spacing: 8) {
                    Circle().fill(.red).frame(width: 8, height: 8)
                    Text("Losses: \(metrics.losses)").font(.subheadline)
                }
                HStack(spacing: 8) {
                    Circle().fill(Color.secondary).frame(width: 8, height: 8)
                    Text("Total: \(metrics.totalTrades)").font(.subheadline).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Total P&L Card

struct TotalPnLCard: View {
    let pnl: Double
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Total P&L", systemImage: "dollarsign.circle.fill")
                .font(.caption).foregroundStyle(.secondary)
            Text(String(format: "%@$%.2f", pnl < 0 ? "-" : "+", abs(pnl)))
                .font(.largeTitle).fontWeight(.bold)
                .foregroundStyle(pnl >= 0 ? .green : .red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var valueColor: Color = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon).font(.caption).foregroundStyle(.secondary)
            Text(value)
                .font(.title3).fontWeight(.bold)
                .foregroundStyle(valueColor)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Trade History

struct TradeHistoryCard: View {
    let trades: [Trade]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Trades").font(.caption).foregroundStyle(.secondary)
            ForEach(trades.prefix(30)) { trade in
                TradeRow(trade: trade)
                if trade.id != trades.prefix(30).last?.id { Divider() }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct TradeRow: View {
    let trade: Trade

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(trade.asset).fontWeight(.semibold)
                    DirectionPill(direction: trade.direction)
                }
                Text(trade.broker.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                if let pnl = trade.pnl {
                    Text(String(format: "%@$%.2f", pnl < 0 ? "-" : "+", abs(pnl)))
                        .fontWeight(.semibold)
                        .foregroundStyle(pnl >= 0 ? .green : .red)
                } else {
                    Text("—").foregroundStyle(.secondary)
                }
                Text(String(format: "%.1fx", trade.leverage))
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
