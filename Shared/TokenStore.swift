import Foundation
import Security

/// The API token. With `CFU_KEYCHAIN = YES` (paid team builds), a data protection Keychain item in a shared access
/// group, so the app and the widget can both read it and nothing else can. Otherwise (free Personal Team builds, which
/// can't keep that entitlement), the App Group's defaults, private to the app and widget.
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

    private static let defaultsKey = "apiToken"

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.manishrana.FlareMeter.apiToken",
            kSecAttrAccount as String: "cloudflare",
            kSecAttrAccessGroup as String: accessGroup,
            kSecUseDataProtectionKeychain as String: true,
        ]
    }

    static func read() -> String {
        guard usesKeychain else { return UsageSettings.defaults?.string(forKey: defaultsKey) ?? "" }
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess, let data = item as? Data else { return "" }
        return String(decoding: data, as: UTF8.self)
    }

    /// Saves the token; an empty one removes it.
    static func write(_ token: String) throws {
        guard usesKeychain else {
            UsageSettings.defaults?.set(token.isEmpty ? nil : token, forKey: defaultsKey)
            return
        }
        SecItemDelete(baseQuery as CFDictionary)
        guard !token.isEmpty else { return }
        var query = baseQuery
        query[kSecValueData as String] = Data(token.utf8)
        // The widget refreshes in the background, so it must read the token while the Mac is locked.
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw StoreError.keychain(status) }
    }
}
