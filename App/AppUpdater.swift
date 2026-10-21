import AppKit
import Sparkle

/// Sparkle updates from the website's appcast (`SUFeedURL`), signed with the key in `SUPublicEDKey`.
@MainActor
final class AppUpdater {
    static let shared = AppUpdater()

    private let controller: SPUStandardUpdaterController?

    private init() {
        // Without a feed and key (a local build), Sparkle would only complain at launch.
        let configured = ["SUFeedURL", "SUPublicEDKey"].allSatisfy {
            !((Bundle.main.object(forInfoDictionaryKey: $0) as? String) ?? "").isEmpty
        }
        controller = configured ? SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil) : nil
    }

    var isAvailable: Bool { controller != nil }

    var automaticallyChecks: Bool {
        get { controller?.updater.automaticallyChecksForUpdates ?? false }
        set { controller?.updater.automaticallyChecksForUpdates = newValue }
    }

    func checkForUpdates() {
        // A menu bar app isn't frontmost; bring it forward so Sparkle's window shows.
        NSApp.activate()
        controller?.checkForUpdates(nil)
    }
}
