import AppKit
import ServiceManagement
import SwiftUI

/// The first-launch guide: connect, then where to find FlareMeter. A menu bar app shows no window of its own, so
/// without this a new user only has a small icon to discover.
@MainActor
enum WelcomeWindow {
    private static let seenKey = "welcomeSeen"
    private static var window: NSWindow?
    private static var closeObserver: NSObjectProtocol?

    /// At launch: once while Cloudflare still needs connecting (an existing user updating never sees it).
    static func showIfNeeded(store: UsageStore) {
        #if DEBUG
        // `FlareMeter --welcome`: show it regardless (testing).
        if CommandLine.arguments.contains("--welcome") { return show(store: store) }
        #endif
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: seenKey) else { return }
        guard !store.settings.isComplete else {
            defaults.set(true, forKey: seenKey)
            return
        }
        show(store: store)
    }

    static func show(store: UsageStore) {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return
        }
        let w = NSWindow(contentRect: .zero, styleMask: [.titled, .closable, .fullSizeContentView], backing: .buffered, defer: false)
        w.titleVisibility = .hidden
        w.titlebarAppearsTransparent = true
        w.isReleasedWhenClosed = false
        w.contentView = NSHostingView(rootView: WelcomeView(close: { w.close() }).environment(store))
        w.center()
        // Closing it any way counts as seen: the menu bar panel still guides whatever is left.
        closeObserver = NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: w, queue: .main) { _ in
            MainActor.assumeIsolated {
                UserDefaults.standard.set(true, forKey: seenKey)
                if let closeObserver { NotificationCenter.default.removeObserver(closeObserver) }
                closeObserver = nil
                window = nil
            }
        }
        window = w
        w.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }
}

private struct WelcomeView: View {
    let close: () -> Void
    @Environment(UsageStore.self) private var store
    @State private var step: Step
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @AppStorage(AlertSettings.enabledKey) private var alertsEnabled = AlertSettings.enabledDefault

    enum Step: Int, CaseIterable { case connect, done }

    init(close: @escaping () -> Void) {
        self.close = close
        // Start at the first thing left to do.
        _step = State(initialValue: UsageSettings.load().isComplete ? .done : .connect)
    }

    private var steps: [Step] { Step.allCases }

    var body: some View {
        VStack(spacing: 0) {
            header.padding(.top, 28).padding(.horizontal, 24)
            Group {
                switch step {
                case .connect: Form { ConnectSection() }.formStyle(.grouped)
                case .done: done
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            Divider()
            footer.padding(16)
        }
        .frame(width: 520, height: 560)
    }

    // MARK: Sections

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "cloud.fill")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(.orange.gradient, in: RoundedRectangle(cornerRadius: 12))
            Text(title).font(.title2.weight(.semibold))
            Text(subtitle)
                .font(.callout).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            if steps.count > 1 {
                HStack(spacing: 6) {
                    ForEach(steps, id: \.self) { s in
                        Capsule()
                            .fill(s.rawValue <= step.rawValue ? AnyShapeStyle(.orange) : AnyShapeStyle(.quaternary))
                            .frame(width: 28, height: 4)
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    private var title: String {
        switch step {
        case .connect: "Welcome to FlareMeter"
        case .done: "You're all set"
        }
    }

    private var subtitle: String {
        switch step {
        case .connect: "Your Workers usage against your plan's limits, in the menu bar and on your desktop. Connect Cloudflare with a read-only token: it takes about a minute."
        case .done: "FlareMeter refreshes every 15 minutes on its own, and warns you before a limit or a bill catches you out."
        }
    }

    private var done: some View {
        Form {
            Section {
                tip("menubar.arrow.up.rectangle", "Find it in the menu bar",
                    "Click the cloud near the clock to see every metric. It shows the fullest one's percentage.")
                tip("square.grid.2x2", "Add the desktop widget",
                    "Right-click the desktop → Edit Widgets…, then search for FlareMeter. Small, medium and large sizes.")
                tip("gearshape", "Change things later",
                    "The panel's settings button picks a single Worker, your plan, and more.")
            }
            Section {
                Toggle(isOn: $alertsEnabled) {
                    Text("Early-warning notifications")
                    Text("When a metric nears its limit, or suddenly runs far faster than usual.")
                }
                Toggle(isOn: Binding(get: { launchAtLogin }, set: setLaunchAtLogin)) {
                    Text("Launch at login")
                    Text("Alerts need FlareMeter running.")
                }
            }
        }
        .formStyle(.grouped)
        .onChange(of: alertsEnabled) { if alertsEnabled { UsageAlerts.shared.requestPermission() } }
    }

    private func tip(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol).font(.title3).foregroundStyle(.orange).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(detail).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 2)
    }

    private var footer: some View {
        HStack {
            if let previous {
                Button("Back") { step = previous }
            }
            Spacer()
            if step == .done {
                Button("Done", action: close).keyboardShortcut(.defaultAction)
            } else {
                // Skippable: the menu bar panel and Settings cover anything left.
                if !stepComplete { Button("Later", action: close) }
                Button("Continue") { if let next { step = next } }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!stepComplete)
            }
        }
        .controlSize(.large)
    }

    // MARK: Navigation

    private var stepComplete: Bool {
        switch step {
        case .connect: store.settings.isComplete
        case .done: true
        }
    }

    private var previous: Step? {
        steps.firstIndex(of: step).flatMap { $0 > 0 ? steps[$0 - 1] : nil }
    }

    private var next: Step? {
        steps.firstIndex(of: step).flatMap { $0 + 1 < steps.count ? steps[$0 + 1] : nil }
    }

    private func setLaunchAtLogin(_ on: Bool) {
        if on { try? SMAppService.mainApp.register() } else { try? SMAppService.mainApp.unregister() }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }
}
