import SwiftUI

// MARK: - Dashboard

struct DashboardView: View {
    @EnvironmentObject var vm: BotViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    StatusCard(status: vm.status, connected: vm.isConnected)

                    if let s = vm.status {
                        HStack(spacing: 14) {
                            MiniCard(title: "Daily P&L",
                                     value: String(format: "%@$%.2f", s.dailyPnl < 0 ? "-" : "+", abs(s.dailyPnl)),
                                     valueColor: s.dailyPnl >= 0 ? .green : .red,
                                     icon: "chart.line.uptrend.xyaxis")
                            MiniCard(title: "Portfolio Heat",
                                     value: String(format: "%.0f%%", s.portfolioHeat * 100),
                                     valueColor: heatColor(s.portfolioHeat),
                                     icon: "flame.fill")
                        }

                        HStack(spacing: 14) {
                            MiniCard(title: "Trades Today",
                                     value: "\(s.dailyTrades) / \(s.maxDailyTrades)",
                                     valueColor: s.dailyTrades >= s.maxDailyTrades ? .red : .primary,
                                     icon: "arrow.left.arrow.right")
                            MiniCard(title: "Loss Streak",
                                     value: "\(s.lossStreak)",
                                     valueColor: s.lossStreak >= 3 ? .red : s.lossStreak >= 1 ? .orange : .primary,
                                     icon: "minus.circle.fill")
                        }

                        HeatBar(heat: s.portfolioHeat)

                        if s.activePositions.isEmpty {
                            EmptyCard(icon: "tray", text: "No active positions")
                        } else {
                            PositionsCard(positions: s.activePositions)
                        }
                    } else if vm.isLoading {
                        ProgressView("Connecting…").padding(40)
                    }

                    if let err = vm.errorMessage {
                        ErrorBanner(message: err)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("JarbiX")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text(relativeTime)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .refreshable { await vm.fetchAll() }
        }
    }

    var relativeTime: String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: vm.lastUpdated, relativeTo: Date())
    }
}

// MARK: - Status Card

struct StatusCard: View {
    let status: BotStatus?
    let connected: Bool

    private var running: Bool { status?.botRunning == true }
    private var paper: Bool   { status?.paperTrade == true }

    var body: some View {
        HStack(spacing: 14) {
            // Pulsing dot
            ZStack {
                Circle()
                    .fill(running ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .frame(width: 48, height: 48)
                Circle()
                    .fill(running ? Color.green : Color.red)
                    .frame(width: 14, height: 14)
                    .shadow(color: running ? .green : .red, radius: running ? 6 : 0)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(running ? "BOT ACTIVE" : "BOT STOPPED")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(running ? .green : .red)
                Text("JarbiX · Hyperliquid")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if paper {
                    Label("PAPER", systemImage: "doc.plaintext.fill")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.15))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                }
                Circle()
                    .fill(connected ? Color.green : Color.red)
                    .frame(width: 7, height: 7)
                    .overlay(Text(connected ? "online" : "offline").font(.caption2).foregroundStyle(.secondary).offset(x: 12))
                    .padding(.trailing, 40)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Mini Metric Card

struct MiniCard: View {
    let title: String
    let value: String
    let valueColor: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(valueColor)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Heat Bar

struct HeatBar: View {
    let heat: Double

    private var color: Color { heatColor(heat) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Portfolio Heat", systemImage: "flame.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.0f%%", heat * 100))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.tertiarySystemGroupedBackground)).frame(height: 10)
                    Capsule().fill(color).frame(width: geo.size.width * min(heat, 1), height: 10)
                        .animation(.spring(duration: 0.4), value: heat)
                }
            }
            .frame(height: 10)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Positions Card

struct PositionsCard: View {
    let positions: [Position]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Active Positions")
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(positions) { pos in
                PositionRow(position: pos)
                if pos.id != positions.last?.id { Divider() }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct PositionRow: View {
    let position: Position

    private var isLong: Bool { position.direction == "long" }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(position.asset).fontWeight(.semibold)
                    DirectionPill(direction: position.direction)
                }
                Text(position.broker).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(String(format: "%.1fx", position.leverage)).fontWeight(.semibold)
                Text(String(format: "%@$%.2f", position.currentPnl < 0 ? "-" : "+", abs(position.currentPnl)))
                    .font(.caption)
                    .foregroundStyle(position.currentPnl >= 0 ? .green : .red)
            }
        }
    }
}

// MARK: - Shared helpers

func heatColor(_ heat: Double) -> Color {
    switch heat {
    case ..<0.3:  return .green
    case 0.3..<0.6: return .yellow
    case 0.6..<0.8: return .orange
    default:      return .red
    }
}

struct DirectionPill: View {
    let direction: String
    var body: some View {
        Text(direction.uppercased())
            .font(.caption2).fontWeight(.bold)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background((direction == "long" ? Color.green : Color.red).opacity(0.15))
            .foregroundStyle(direction == "long" ? .green : .red)
            .clipShape(Capsule())
    }
}

struct EmptyCard: View {
    let icon: String
    let text: String
    var body: some View {
        Label(text, systemImage: icon)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ErrorBanner: View {
    let message: String
    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.caption)
            .foregroundStyle(.orange)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
