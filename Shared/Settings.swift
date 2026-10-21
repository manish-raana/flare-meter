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

/// Settings shared by the app and the widget: the token in the Keychain (`TokenStore`), the rest in the App Group's
/// defaults.
struct UsageSettings: Codable, Equatable {
    var accountID: String = ""
    var apiToken: String = ""
    /// Empty: all Workers on the account.
    var workerScript: String = ""
    var plan: Plan = .free

    /// The token isn't written to defaults.
    private enum CodingKeys: String, CodingKey { case accountID, workerScript, plan }

    var isComplete: Bool { !accountID.isEmpty && !apiToken.isEmpty }

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
        s.apiToken = TokenStore.read()
        return s
    }

    /// Saves the token first: if the Keychain refuses it, nothing changes.
    func save() throws {
        try TokenStore.write(apiToken)
        guard let data = try? JSONEncoder().encode(self) else { return }
        UsageSettings.defaults?.set(data, forKey: UsageSettings.key)
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
