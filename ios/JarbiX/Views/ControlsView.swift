import SwiftUI

// MARK: - Controls

struct ControlsView: View {
    @EnvironmentObject var vm: BotViewModel
    @State private var showToggleAlert = false
    @State private var showFlattenAlert = false

    private var running: Bool { vm.status?.botRunning == true }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    BotToggleCard(running: running, onTap: { showToggleAlert = true })
                    FlattenCard(onTap: { showFlattenAlert = true })
                    if let s = vm.status { SessionInfoCard(status: s) }
                    if let err = vm.errorMessage { ErrorBanner(message: err) }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Controls")
            // Toggle confirmation
            .alert(running ? "Stop Bot" : "Start Bot", isPresented: $showToggleAlert) {
                Button("Cancel", role: .cancel) {}
                Button(running ? "Stop" : "Start", role: running ? .destructive : .none) {
                    Task { await vm.toggleBot() }
                }
            } message: {
                Text(running
                    ? "The bot will stop placing new trades."
                    : "The bot will resume placing trades.")
            }
            // Flatten confirmation
            .alert("Emergency Flatten", isPresented: $showFlattenAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Flatten All Positions", role: .destructive) {
                    Task { await vm.emergencyFlatten() }
                }
            } message: {
                Text("This closes ALL open positions immediately and stops the bot. This cannot be undone.")
            }
        }
    }
}

// MARK: - Bot Toggle Card

struct BotToggleCard: View {
    let running: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Trading Bot")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(running ? "Running" : "Stopped")
                        .font(.title2).fontWeight(.bold)
                        .foregroundStyle(running ? .green : .red)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill((running ? Color.green : Color.red).opacity(0.12))
                        .frame(width: 56, height: 56)
                    Image(systemName: running ? "play.circle.fill" : "stop.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(running ? .green : .red)
                }
            }

            Button(action: onTap) {
                Label(running ? "Stop Bot" : "Start Bot",
                      systemImage: running ? "stop.fill" : "play.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(running ? Color.red : Color.green)
                    .foregroundStyle(.white)
                    .fontWeight(.semibold)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Emergency Flatten Card

struct FlattenCard: View {
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Emergency Controls", systemImage: "exclamationmark.triangle.fill")
                .fontWeight(.semibold)
                .foregroundStyle(.red)

            Text("Immediately closes all Hyperliquid positions and halts the bot.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button(action: onTap) {
                Label("EMERGENCY FLATTEN", systemImage: "xmark.octagon.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundStyle(.white)
                    .fontWeight(.bold)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.red.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Session Info Card

struct SessionInfoCard: View {
    let status: BotStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Session Info").font(.caption).foregroundStyle(.secondary)

            InfoRow(label: "Mode",
                    value: status.paperTrade ? "Paper Trading" : "Live Trading",
                    valueColor: status.paperTrade ? .blue : .orange)
            Divider()
            InfoRow(label: "Broker", value: "Hyperliquid")
            Divider()
            InfoRow(label: "Active Positions", value: "\(status.activePositions.count)")
            Divider()
            InfoRow(label: "Trades Today",
                    value: "\(status.dailyTrades) / \(status.maxDailyTrades)",
                    valueColor: status.dailyTrades >= status.maxDailyTrades ? .red : .primary)
            Divider()
            InfoRow(label: "Loss Streak",
                    value: "\(status.lossStreak)",
                    valueColor: status.lossStreak >= 3 ? .red : status.lossStreak >= 1 ? .orange : .primary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.semibold).foregroundStyle(valueColor)
        }
        .font(.subheadline)
    }
}
