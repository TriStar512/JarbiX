import SwiftUI

struct ContentView: View {
    @StateObject private var vm = BotViewModel()

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "gauge.with.dots.needle.67percent") }

            SignalsView()
                .tabItem { Label("Signals", systemImage: "waveform.path.ecg") }

            MetricsView()
                .tabItem { Label("Metrics", systemImage: "chart.bar.fill") }

            ControlsView()
                .tabItem { Label("Controls", systemImage: "slider.horizontal.3") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .tint(.green)
        .environmentObject(vm)
    }
}
