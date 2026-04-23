import SwiftUI

// MARK: - Settings

struct SettingsView: View {
    @EnvironmentObject var vm: BotViewModel

    @State private var serverURL: String = UserDefaults.standard.string(forKey: "serverURL") ?? "http://localhost:5000"
    @State private var refreshInterval: Double = 5
    @State private var savedFeedback = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Server
                Section {
                    HStack {
                        Image(systemName: "network")
                            .foregroundStyle(.blue)
                            .frame(width: 28)
                        TextField("http://192.168.x.x:5000", text: $serverURL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                    }
                } header: {
                    Text("Bot Server URL")
                } footer: {
                    Text("Enter the IP of the machine running api.py. Make sure you're on the same Wi-Fi network.")
                }

                // MARK: Refresh
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .foregroundStyle(.green).frame(width: 28)
                            Text("Every \(Int(refreshInterval))s")
                        }
                        Slider(value: $refreshInterval, in: 3...60, step: 1)
                            .tint(.green)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Auto-Refresh Interval")
                }

                // MARK: Save
                Section {
                    Button(action: save) {
                        HStack {
                            Image(systemName: savedFeedback ? "checkmark.circle.fill" : "square.and.arrow.down")
                                .foregroundStyle(savedFeedback ? .green : .blue)
                            Text(savedFeedback ? "Saved!" : "Save Settings")
                                .foregroundStyle(savedFeedback ? .green : .blue)
                                .fontWeight(.semibold)
                        }
                    }
                }

                // MARK: Bot config (read-only)
                if let cfg = vm.config {
                    Section {
                        LabeledContent("Mode", value: cfg.paperTrade ? "Paper Trading" : "Live Trading")
                        LabeledContent("Max Loss / Trade", value: String(format: "%.0f%%", cfg.maxLossPct * 100))
                        LabeledContent("Max Position Size", value: String(format: "%.0f%%", cfg.maxPositionSizePct * 100))
                        LabeledContent("Max Concurrent", value: "\(cfg.maxConcurrentTrades) trades")
                        LabeledContent("Max Daily Trades", value: "\(cfg.maxDailyTrades)")
                    } header: {
                        Text("Bot Risk Config (server-side)")
                    } footer: {
                        Text("Edit these values in the server's .env file.")
                    }
                }

                // MARK: About
                Section("About") {
                    LabeledContent("App Version",  value: "1.0.0")
                    LabeledContent("iOS Target",   value: "18.3+")
                    LabeledContent("Broker",       value: "Hyperliquid")
                    LabeledContent("Bot",          value: "JarbiX v1.0")
                }
            }
            .navigationTitle("Settings")
            .task { await vm.fetchConfig() }
        }
    }

    private func save() {
        vm.updateServerURL(serverURL, refreshInterval: refreshInterval)
        savedFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { savedFeedback = false }
    }
}
