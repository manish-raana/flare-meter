import SwiftUI

/// A menu bar app (no Dock icon, `LSUIElement`): the icon shows the fullest metric, the panel shows them all.
@main
struct FlareMeterApp: App {
    @State private var store: UsageStore

    init() {
        #if DEBUG
        MarketingRenderer.runIfRequested()
        #endif
        let store = UsageStore()
        _store = State(initialValue: store)
        // Hosting unit tests: no updater or welcome window.
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }
        _ = AppUpdater.shared
        // Runs once the app has finished launching.
        Task { @MainActor in WelcomeWindow.showIfNeeded(store: store) }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarPanel().environment(store)
        } label: {
            MenuBarLabel(store: store)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(store)
                .frame(width: 520)
                .frame(minHeight: 560)
        }
        .windowResizability(.contentSize)
    }
}
