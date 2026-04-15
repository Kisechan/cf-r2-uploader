import Foundation
import Security

public struct KeychainStore: Sendable {
    public let serviceName: String

    public init(serviceName: String = "kisechan.CFR2Uploader.credentials") {
        self.serviceName = serviceName
    }

    public func save(credentials: R2Credentials, forProfile profile: String) throws {
        let data = try JSONEncoder().encode(credentials)
        let query = baseQuery(profile: profile)

        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrLabel as String] = "CFR2Uploader \(profile)"

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw UploaderError.underlying("Keychain 保存失败：\(status)")
        }
    }

    public func loadCredentials(forProfile profile: String) throws -> R2Credentials {
        var query = baseQuery(profile: profile)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status != errSecItemNotFound else {
            throw UploaderError.credentialsNotFound(profile: profile)
        }

        guard status == errSecSuccess, let data = item as? Data else {
            throw UploaderError.underlying("Keychain 读取失败：\(status)")
        }

        return try JSONDecoder().decode(R2Credentials.self, from: data)
    }

    public func deleteCredentials(forProfile profile: String) throws {
        let status = SecItemDelete(baseQuery(profile: profile) as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw UploaderError.underlying("Keychain 删除失败：\(status)")
        }
    }

    private func baseQuery(profile: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: profile,
        ]
    }
}
