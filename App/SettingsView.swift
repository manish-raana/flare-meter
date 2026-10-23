import ServiceManagement
import SwiftUI

/// Connect with one pasted token: the account and Workers are found from it, and every change saves at once.
struct SettingsView: View {
    private static let sourceURL = URL(string: "https://github.com/manish-raana/flare-meter")!
    private static let sponsorURL = URL(string: "https://github.com/sponsors/manish-raana")!

    @Environment(UsageStore.self) private var store
    @State private var settings = UsageSettings.load()
    @State private var workers: [String] = []
    @State private var customWorker = ""
    @State private var showAdvanced = false
    @State private var addingAccount = false
    @State private var message: String?
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var autoUpdate = AppUpdater.shared.automaticallyChecks
    @AppStorage("menuBarShowsPercent") private var menuBarShowsPercent = true

    var body: some View {
        Form {
            if settings.isComplete {
                connectedSection
            } else {
                ConnectSection { _ in
                    settings = UsageSettings.load()
                    await loadWorkers()
                }
            }

            AlertsSection(plan: settings.plan)

            Section("General") {
                Toggle("Show percentage in the menu bar", isOn: $menuBarShowsPercent)
                Toggle("Launch at login", isOn: Binding(get: { launchAtLogin }, set: setLaunchAtLogin))
                if AppUpdater.shared.isAvailable {
                    HStack {
                        Toggle("Check for updates automatically", isOn: Binding(get: { autoUpdate }, set: { on in
                            AppUpdater.shared.automaticallyChecks = on
                            autoUpdate = on
                        }))
                        Spacer()
                        Button("Check Now") { AppUpdater.shared.checkForUpdates() }
                    }
                }
                if let message { Text(message).font(.caption).foregroundStyle(.red) }
            }

            if settings.isComplete {
                Section {
                    DisclosureGroup("Advanced", isExpanded: $showAdvanced) { advanced }
                }
            }

            Section {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("FlareMeter is free and open source")
                        Text("If it saves you a surprise bill, you can sponsor its development.").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button { NSWorkspace.shared.open(Self.sourceURL) } label: { Text("Source") }
                    Button { NSWorkspace.shared.open(Self.sponsorURL) } label: { Label("Sponsor", systemImage: "heart") }
                }
            }
        }
        .formStyle(.grouped)
        .padding(.vertical, 8)
        .task { await loadDetails() }
        .onChange(of: settings.accountID) { Task { await loadWorkers() } }
        // Switched from the menu bar panel.
        .onChange(of: store.settings) { settings = store.settings }
    }

    // MARK: Connected

    @ViewBuilder
    private var connectedSection: some View {
        Section {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill").font(.title2).foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Connected")
                    Text(settings.accountName).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button("Add Account…") { addingAccount.toggle() }
                Button(settings.savedAccounts.count > 1 ? "Remove" : "Disconnect") { remove() }
                    .help("Forget this account and its token")
            }
            if settings.savedAccounts.count > 1 {
                Picker("Account", selection: Binding(get: { settings.accountID }, set: switchAccount)) {
                    ForEach(settings.savedAccounts) { Text($0.name).tag($0.id) }
                }
            }
            Picker("Worker", selection: binding(\.workerScript)) {
                Text("All Workers").tag("")
                if !workerOptions.isEmpty { Divider() }
                ForEach(workerOptions, id: \.self) { Text($0).tag($0) }
            }
            Picker("Plan", selection: binding(\.plan)) {
                ForEach(Plan.allCases) { Text($0.label).tag($0) }
            }
        } header: {
            Text("Cloudflare")
        } footer: {
            Text("Free plan limits are account-wide, so All Workers matches what Cloudflare enforces. Each account keeps its own Worker and plan. Limits and prices as of \(Metrics.pricingAsOf).")
                .font(.caption).foregroundStyle(.secondary)
        }
        if addingAccount {
            ConnectSection(title: "Add an account") { _ in
                settings = UsageSettings.load()
                addingAccount = false
                await loadWorkers()
            }
        }
    }

    /// Discovered Workers, plus the saved one if it had no recent traffic (so the picker can show it).
    private var workerOptions: [String] {
        let saved = settings.workerScript
        return saved.isEmpty || workers.contains(saved) ? workers : workers + [saved]
    }

    private func binding<T>(_ key: WritableKeyPath<UsageSettings, T>) -> Binding<T> {
        Binding(get: { settings[keyPath: key] }, set: { value in
            var s = settings
            s[keyPath: key] = value
            apply(s)
        })
    }

    private func switchAccount(_ id: String) {
        var s = settings
        s.select(id)
        apply(s)
    }

    /// Forgets the shown account; another connected one, if any, takes its place.
    private func remove() {
        var s = settings
        do {
            try s.remove(s.accountID)
        } catch {
            message = error.localizedDescription
            return
        }
        settings = s
        workers = []
        store.settingsChanged()
    }

    /// Saves, and tells the menu bar and widget.
    private func apply(_ s: UsageSettings) {
        do {
            try s.save()
        } catch {
            message = error.localizedDescription
            return
        }
        settings = s
        store.settingsChanged()
    }

    /// Account names from Cloudflare, and any other accounts the token can read (connected before FlareMeter kept
    /// several).
    private func loadDetails() async {
        guard settings.isComplete else { return }
        let found = (try? await CloudflareClient(settings: settings).accounts()) ?? []
        let known = Set(settings.savedAccounts.map { "\($0.id)|\($0.name)" })
        if found.contains(where: { !known.contains("\($0.id)|\($0.name)") }) {
            var s = settings
            do {
                try s.connect(found, token: settings.apiToken)
            } catch {
                message = error.localizedDescription
                return
            }
            apply(s)
        }
        await loadWorkers()
    }

    private func loadWorkers() async {
        guard settings.isComplete else { return }
        workers = (try? await CloudflareClient(settings: settings).workerNames()) ?? []
    }

    // MARK: Advanced

    @ViewBuilder
    private var advanced: some View {
        LabeledContent("Account ID") {
            Text(settings.accountID).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
        }
        HStack {
            TextField("Other Worker name", text: $customWorker, prompt: Text("A Worker without recent traffic"))
                .onSubmit(useCustomWorker)
            Button("Use", action: useCustomWorker).disabled(customWorker.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        Link("Open the Cloudflare dashboard", destination: URL(string: "https://dash.cloudflare.com/\(settings.accountID)")!)
    }

    private func useCustomWorker() {
        let name = customWorker.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        var s = settings
        s.workerScript = name
        apply(s)
        customWorker = ""
    }

    private func setLaunchAtLogin(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            message = error.localizedDescription
        }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }
}

/// Early-warning notifications (`UsageAlerts`).
private struct AlertsSection: View {
    let plan: Plan
    @AppStorage(AlertSettings.enabledKey) private var enabled = AlertSettings.enabledDefault
    @AppStorage(AlertSettings.thresholdKey) private var threshold = AlertSettings.thresholdDefault
    @AppStorage(AlertSettings.spikesKey) private var spikes = AlertSettings.spikesDefault
    @AppStorage(AlertSettings.budgetKey) private var budget = AlertSettings.budgetDefault
    @State private var denied = false

    var body: some View {
        Section {
            Toggle("Early-warning notifications", isOn: $enabled)
            if enabled {
                Picker("Warn at", selection: $threshold) {
                    ForEach(AlertSettings.thresholds, id: \.self) { Text("\(Format.percent($0)) of a limit").tag($0) }
                }
                if plan == .paid {
                    Picker("Warn when estimated charges pass", selection: $budget) {
                        Text("Never").tag(0.0)
                        ForEach(AlertSettings.budgets, id: \.self) { Text($0.formatted(.currency(code: "USD").precision(.fractionLength(0)))).tag($0) }
                    }
                }
                Toggle(isOn: $spikes) {
                    Text("Unusual spikes")
                    Text("A metric running at 10× its usual rate for half an hour, like a runaway Durable Object alarm loop.")
                }
                if denied {
                    HStack {
                        Label("Notifications are off for FlareMeter in System Settings.", systemImage: "bell.slash").foregroundStyle(.orange)
                        Spacer()
                        Button("Open") { NSWorkspace.shared.open(Self.notificationSettingsURL) }
                    }
                }
                HStack {
                    Spacer()
                    Button("Send Test Notification") { UsageAlerts.shared.sendTest() }
                }
            }
        } header: {
            Text("Alerts")
        } footer: {
            Text("Checked every 15 minutes while FlareMeter is running, so keep Launch at login on. Click a notification to open the Cloudflare dashboard.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .task(id: enabled) {
            if enabled { UsageAlerts.shared.requestPermission() }
            denied = await UsageAlerts.shared.authorizationStatus() == .denied
        }
    }

    private static let notificationSettingsURL =
        URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=\(Bundle.main.bundleIdentifier ?? "")")!
}
