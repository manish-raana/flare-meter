import SwiftUI

/// Connect with one pasted token: the account is found from it. Shared by Settings (also to add another account) and
/// the welcome window; saves the settings when the token works.
struct ConnectSection: View {
    @Environment(UsageStore.self) private var store
    var title = "Connect Cloudflare"
    /// After saving, with the accounts the token can read.
    var onConnect: ([CloudflareClient.Account]) async -> Void = { _ in }

    @State private var tokenDraft = ""
    @State private var connecting = false
    @State private var connectError: String?
    /// The token works but can't list accounts (a user token): ask for the account ID.
    @State private var needsAccountID = false
    @State private var accountIDDraft = ""

    /// Cloudflare's account token page with Account Analytics: Read already chosen
    /// (https://developers.cloudflare.com/fundamentals/api/how-to/account-owned-token-template/).
    /// An account token lists its account, so the app finds it; a user token with this permission alone can't.
    private static let createTokenURL = URL(string: "https://dash.cloudflare.com/?to=/:account/api-tokens&permissionGroupKeys=%5B%7B%22key%22%3A%22account_analytics%22%2C%22type%22%3A%22read%22%7D%5D&name=FlareMeter")!

    var body: some View {
        Section {
            LabeledContent {
                Button("Create Token…") { NSWorkspace.shared.open(Self.createTokenURL) }
            } label: {
                StepLabel(1, "Create a read-only token",
                          "Opens Cloudflare with Account Analytics · Read selected. Pick your account, click Continue to summary → Create Token, then Copy.")
            }
            LabeledContent {
                PasteButton(payloadType: String.self) { strings in
                    Task { @MainActor in
                        tokenDraft = strings.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        await connect()
                    }
                }
                .disabled(connecting)
            } label: {
                StepLabel(2, "Paste it here", "The account and your Workers are found from the token.")
            }
            HStack {
                SecureField("Token", text: $tokenDraft, prompt: Text("Or paste the token into this field"))
                    .labelsHidden()
                    .onSubmit { Task { await connect() } }
                if connecting {
                    ProgressView().controlSize(.small)
                } else {
                    Button("Connect") { Task { await connect() } }
                        .disabled(tokenDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            if needsAccountID {
                VStack(alignment: .leading, spacing: 6) {
                    Text("This token can't list its accounts (it's a user token). Paste your Account ID, or any dashboard URL that contains it.")
                        .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    HStack {
                        TextField("Account ID", text: $accountIDDraft, prompt: Text("32 hex characters"))
                            .labelsHidden()
                            .onSubmit { Task { await connect() } }
                        Link("Find it", destination: URL(string: "https://dash.cloudflare.com/?to=/:account/workers-and-pages")!)
                    }
                }
            }
            if let connectError {
                Label(connectError, systemImage: "exclamationmark.triangle.fill").font(.caption).foregroundStyle(.red)
            }
        } header: {
            Text(title)
        } footer: {
            Text(TokenStore.usesKeychain
                 ? "The token can only read analytics. It's kept in your Keychain and sent only to Cloudflare."
                 : "The token can only read analytics. It stays on this Mac and is sent only to Cloudflare.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func connect() async {
        let token = tokenDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty, !connecting else { return }
        connecting = true
        defer { connecting = false }
        connectError = nil
        do {
            let client = CloudflareClient(settings: UsageSettings(apiToken: token))
            var found = try await client.accounts()
            if found.isEmpty {
                // A user token with only Account Analytics can't list accounts: use the ID the person gives,
                // checked by reading analytics with it.
                needsAccountID = true
                guard let id = Self.accountID(in: accountIDDraft) else {
                    if !accountIDDraft.isEmpty { connectError = "That doesn't contain a 32-character account ID." }
                    return
                }
                _ = try await CloudflareClient(settings: UsageSettings(accountID: id, apiToken: token)).workerNames()
                found = [CloudflareClient.Account(id: id, name: id)]
            }
            var s = UsageSettings.load()
            try s.connect(found, token: token)
            try s.save()
            store.settingsChanged()
            tokenDraft = ""
            accountIDDraft = ""
            needsAccountID = false
            await onConnect(found)
        } catch {
            connectError = "Couldn't connect: \(error.localizedDescription)"
        }
    }

    /// The first 32-hex-character run in an ID or a dashboard URL.
    private static func accountID(in text: String) -> String? {
        guard let r = text.range(of: "[0-9a-fA-F]{32}", options: .regularExpression) else { return nil }
        return String(text[r]).lowercased()
    }
}

/// A numbered step: an orange badge, a title and a detail line.
struct StepLabel: View {
    let n: Int
    let title: String
    let detail: String

    init(_ n: Int, _ title: String, _ detail: String) {
        self.n = n
        self.title = title
        self.detail = detail
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(n)")
                .font(.caption.weight(.bold)).foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(.orange.gradient))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(detail).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
