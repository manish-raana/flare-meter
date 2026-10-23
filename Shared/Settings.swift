import Foundation

/// Which Cloudflare plan the limits come from.
enum Plan: String, CaseIterable, Codable, Identifiable {
    /// Workers Free: daily caps; past one, requests fail until 00:00 UTC.
    case free
    /// Workers Paid: monthly amounts included, then billed per use.
    case paid

    var id: String { rawValue }
    var label: String { self == .free ? "Workers Free (daily limits)" : "Workers Paid (monthly, billed past included)" }
}

/// A Cloudflare account FlareMeter is connected to, with the Worker and plan chosen for it. Its token is in `TokenStore`.
struct SavedAccount: Codable, Hashable, Identifiable {
    let id: String
    var name: String
    /// Empty: all Workers on the account.
    var workerScript: String = ""
    var plan: Plan = .free
}

/// Settings shared by the app and the widget: the tokens in the Keychain (`TokenStore`), the rest in the App Group's
/// defaults. The top-level fields are the account being shown; `savedAccounts` holds every connected one.
struct UsageSettings: Codable, Equatable {
    var accountID: String = ""
    var apiToken: String = ""
    /// Empty: all Workers on the account.
    var workerScript: String = ""
    var plan: Plan = .free
    var savedAccounts: [SavedAccount] = []

    /// The token isn't written to defaults.
    private enum CodingKeys: String, CodingKey { case accountID, workerScript, plan, savedAccounts }

    var isComplete: Bool { !accountID.isEmpty && !apiToken.isEmpty }

    /// The name of the account being shown (its ID until Cloudflare says otherwise).
    var accountName: String { savedAccounts.first { $0.id == accountID }?.name ?? accountID }

    /// The account's Workers & Pages page in the Cloudflare dashboard (the dashboard's home without an account).
    static func dashboardURL(accountID: String) -> URL {
        URL(string: accountID.isEmpty ? "https://dash.cloudflare.com" : "https://dash.cloudflare.com/\(accountID)/workers-and-pages")!
    }

    /// What a reading depends on (not the token).
    var cacheKey: String { "\(accountID)|\(workerScript)|\(plan.rawValue)" }

    private static let key = "settings"

    static var appGroup: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFUAppGroup") as? String) ?? ""
    }

    static var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }

    static func load() -> UsageSettings {
        var s = defaults?.data(forKey: key).flatMap { try? JSONDecoder().decode(UsageSettings.self, from: $0) } ?? UsageSettings()
        s.adoptSingleAccount()
        s.apiToken = TokenStore.read(accountID: s.accountID)
        return s
    }

    /// Saves the token first: if the Keychain refuses it, nothing changes.
    func save() throws {
        try TokenStore.write(apiToken, accountID: accountID)
        var s = self
        s.rememberCurrent()
        guard let data = try? JSONEncoder().encode(s) else { return }
        UsageSettings.defaults?.set(data, forKey: UsageSettings.key)
    }

    // MARK: Accounts

    /// Shows `id`, with the Worker and plan last chosen for it.
    mutating func select(_ id: String) {
        rememberCurrent()
        guard let account = savedAccounts.first(where: { $0.id == id }) else { return }
        accountID = account.id
        workerScript = account.workerScript
        plan = account.plan
        apiToken = TokenStore.read(accountID: account.id)
    }

    /// Adds the accounts `token` can read (or gives them this token), then shows the current account if the token
    /// covers it, otherwise the first one. Saves the tokens; call `save()` for the rest.
    mutating func connect(_ accounts: [CloudflareClient.Account], token: String) throws {
        guard let first = accounts.first else { return }
        for account in accounts { try TokenStore.write(token, accountID: account.id) }
        rememberCurrent()
        for account in accounts {
            if let i = savedAccounts.firstIndex(where: { $0.id == account.id }) {
                savedAccounts[i].name = account.name
            } else {
                savedAccounts.append(SavedAccount(id: account.id, name: account.name, plan: plan))
            }
        }
        select(accounts.contains { $0.id == accountID } ? accountID : first.id)
    }

    /// Forgets `id` and its token, and shows another connected account, if any. Saves.
    mutating func remove(_ id: String) throws {
        try TokenStore.write("", accountID: id)
        savedAccounts.removeAll { $0.id == id }
        if let next = savedAccounts.first {
            if accountID == id { select(next.id) }
        } else {
            TokenStore.removeLegacy()
            self = UsageSettings()
        }
        try save()
    }

    /// Updates the names of connected accounts from what Cloudflare lists.
    mutating func rename(from accounts: [CloudflareClient.Account]) {
        for account in accounts {
            if let i = savedAccounts.firstIndex(where: { $0.id == account.id }) { savedAccounts[i].name = account.name }
        }
    }

    /// Copies the shown account's Worker and plan into `savedAccounts`, adding it if it's new.
    private mutating func rememberCurrent() {
        guard !accountID.isEmpty else { return }
        if let i = savedAccounts.firstIndex(where: { $0.id == accountID }) {
            savedAccounts[i].workerScript = workerScript
            savedAccounts[i].plan = plan
        } else {
            savedAccounts.append(SavedAccount(id: accountID, name: accountID, workerScript: workerScript, plan: plan))
        }
    }

    /// Settings from before several accounts: the one account becomes the first saved one.
    private mutating func adoptSingleAccount() {
        if savedAccounts.isEmpty { rememberCurrent() }
    }
}

extension UsageSettings {
    /// Settings saved by older versions have no `savedAccounts`.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        accountID = try c.decodeIfPresent(String.self, forKey: .accountID) ?? ""
        workerScript = try c.decodeIfPresent(String.self, forKey: .workerScript) ?? ""
        plan = try c.decodeIfPresent(Plan.self, forKey: .plan) ?? .free
        savedAccounts = try c.decodeIfPresent([SavedAccount].self, forKey: .savedAccounts) ?? []
    }
}

/// The one reading the menu bar and widget both show. Whichever side fetches saves it here and tells the other.
enum SnapshotCache {
    private static let key = "lastSnapshot"

    /// Darwin notification posted after a save, so the menu bar app picks up a reading the widget fetched.
    static var changedNotification: String { "\(UsageSettings.appGroup).snapshotChanged" }

    static func load() -> UsageSnapshot? {
        guard let data = UsageSettings.defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(UsageSnapshot.self, from: data)
    }

    static func save(_ snapshot: UsageSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UsageSettings.defaults?.set(data, forKey: key)
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                             CFNotificationName(changedNotification as CFString), nil, nil, true)
    }
}
