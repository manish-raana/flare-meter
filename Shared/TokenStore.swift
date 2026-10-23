import Foundation
import Security

/// The API tokens, one per connected account. With `CFU_KEYCHAIN = YES` (paid team builds), data protection Keychain
/// items in a shared access group, so the app and the widget can both read them and nothing else can. Otherwise (free
/// Personal Team builds, which can't keep that entitlement), the App Group's defaults, private to the app and widget.
enum TokenStore {
    enum StoreError: LocalizedError {
        case keychain(OSStatus)

        var errorDescription: String? {
            guard case .keychain(let status) = self else { return nil }
            let text = SecCopyErrorMessageString(status, nil) as String? ?? "error \(status)"
            return "Couldn't save the token in the Keychain: \(text)"
        }
    }

    /// Empty when this build keeps the token in the App Group instead.
    static var accessGroup: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFUKeychainGroup") as? String) ?? ""
    }

    static var usesKeychain: Bool { !accessGroup.isEmpty }

    /// Before accounts had their own tokens there was one, under this name. It's still read for accounts without
    /// their own, so an update keeps working, and removed with the last account.
    private static let legacyName = "cloudflare"

    /// Each account's token is kept under its own name.
    private static func name(_ accountID: String) -> String { "\(legacyName):\(accountID)" }

    private static func defaultsKey(_ name: String) -> String { name == legacyName ? "apiToken" : "apiToken.\(name)" }

    private static func baseQuery(_ name: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.manishrana.FlareMeter.apiToken",
            kSecAttrAccount as String: name,
            kSecAttrAccessGroup as String: accessGroup,
            kSecUseDataProtectionKeychain as String: true,
        ]
    }

    /// The token for `accountID`, or the one from before per-account tokens; empty when there's neither.
    static func read(accountID: String) -> String {
        let own = accountID.isEmpty ? "" : read(name: name(accountID))
        return own.isEmpty ? read(name: legacyName) : own
    }

    /// Saves `accountID`'s token; an empty one removes it.
    static func write(_ token: String, accountID: String) throws {
        try write(token, name: name(accountID))
    }

    /// Removes the token from before per-account tokens.
    static func removeLegacy() {
        try? write("", name: legacyName)
    }

    private static func read(name: String) -> String {
        guard usesKeychain else { return UsageSettings.defaults?.string(forKey: defaultsKey(name)) ?? "" }
        var query = baseQuery(name)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess, let data = item as? Data else { return "" }
        return String(decoding: data, as: UTF8.self)
    }

    private static func write(_ token: String, name: String) throws {
        guard usesKeychain else {
            UsageSettings.defaults?.set(token.isEmpty ? nil : token, forKey: defaultsKey(name))
            return
        }
        SecItemDelete(baseQuery(name) as CFDictionary)
        guard !token.isEmpty else { return }
        var query = baseQuery(name)
        query[kSecValueData as String] = Data(token.utf8)
        // The widget refreshes in the background, so it must read the token while the Mac is locked.
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw StoreError.keychain(status) }
    }
}
