import SwiftUI

// MARK: - Signals

struct SignalsView: View {
    @EnvironmentObject var vm: BotViewModel

    private let assetColor: [String: Color] = [
        "BTC": .orange, "ETH": .blue, "SOL": .purple, "XRP": .cyan
    ]
    private let assetIcon: [String: String] = [
        "BTC": "bitcoinsign.circle.fill",
        "ETH": "e.circle.fill",
        "SOL": "s.circle.fill",
        "XRP": "x.circle.fill"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    if vm.signals.isEmpty {
                        EmptyCard(icon: "waveform.path.ecg", text: "Waiting for signals…")
                            .padding(.top, 40)
                    } else {
                        ForEach(vm.signals) { sig in
                            SignalCard(signal: sig,
                                       color: assetColor[sig.asset] ?? .gray,
                                       icon: assetIcon[sig.asset] ?? "questionmark.circle.fill")
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Signals")
            .refreshable { await vm.refreshLive() }
        }
    }
}

// MARK: - Signal Card

struct SignalCard: View {
    let signal: Signal
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(signal.asset)
                        .font(.title3).fontWeight(.bold)
                    Text(signal.brokerCandidates.first.map { formatted($0) } ?? "—")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                DirectionPill(direction: signal.direction)
            }

            Divider()

            SignalBar(label: "Signal Strength", value: signal.signalStrength, color: color)
            SignalBar(label: "Sentiment",        value: signal.sentiment,      color: .teal)
            SignalBar(label: "Volatility (ATR)", value: min(signal.atrRatio / 2.0, 1.0), color: .orange)

            // Score summary
            HStack {
                Text("Overall score")
                    .font(.caption2).foregroundStyle(.secondary)
                Spacer()
                let score = signal.signalStrength * 0.5 + signal.sentiment * 0.3 + min(signal.atrRatio / 2, 1) * 0.2
                Text(String(format: "%.0f / 100", score * 100))
                    .font(.caption).fontWeight(.semibold)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.25), lineWidth: 1))
    }

    private func formatted(_ broker: String) -> String {
        broker.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

// MARK: - Signal Bar

struct SignalBar: View {
    let label: String
    let value: Double
    let color: Color

    private var clamped: Double { min(max(value, 0), 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.0f%%", clamped * 100))
                    .font(.caption).fontWeight(.semibold)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.tertiarySystemGroupedBackground)).frame(height: 7)
                    Capsule().fill(color).frame(width: geo.size.width * clamped, height: 7)
                        .animation(.spring(duration: 0.4), value: clamped)
                }
            }
            .frame(height: 7)
        }
    }
}
