import SwiftUI
class KeychainHelper {
    static let standard = KeychainHelper()
    private let service = "com.musictransfer.spotify.tokens" // Use a unique service name
    
    func save<T: Codable>(_ item: T, for key: String) {
        do {
            let data = try JSONEncoder().encode(item)
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key,
                kSecValueData as String: data
            ]
            
            SecItemDelete(query as CFDictionary) // Delete any existing item
            let status = SecItemAdd(query as CFDictionary, nil)
            guard status == errSecSuccess else {
                print("🚨 Keychain save error: \(status)")
                return
            }
        } catch {
            print("🚨 Keychain encoding error: \(error)")
        }
    }
    
    func load<T: Codable>(for key: String) -> T? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            guard let data = dataTypeRef as? Data else { return nil }
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                print("🚨 Keychain decoding error: \(error)")
                return nil
            }
        }
        return nil
    }
    
    func delete(for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
