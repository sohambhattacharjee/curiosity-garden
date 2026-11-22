import Foundation
import CommonCrypto
import Security

enum ParentPIN {
    private static let service = "org.curiositygarden.parent-pin"
    private struct Credential: Codable { var salt: Data; var digest: Data; var failures: Int = 0; var lockedUntil: Date? }
    private static func query() -> [String: Any] { [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: "parent"] }
    private static func read() -> Credential? {
        var q = query(); q[kSecReturnData as String] = true
        var item: CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary, &item) == errSecSuccess, let data = item as? Data else { return nil }
        return try? JSONDecoder().decode(Credential.self, from: data)
    }
    static var exists: Bool { read() != nil }
    private static func derive(_ pin: String, salt: Data) -> Data {
        var output = [UInt8](repeating: 0, count: 32)
        let bytes = Array(pin.utf8)
        bytes.withUnsafeBytes { password in salt.withUnsafeBytes { saltBytes in
            _ = CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), password.baseAddress!.assumingMemoryBound(to: Int8.self), bytes.count, saltBytes.baseAddress!.assumingMemoryBound(to: UInt8.self), salt.count, CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256), 210_000, &output, output.count)
        } }
        return Data(output)
    }
    private static func write(_ credential: Credential) -> Bool {
        guard let data = try? JSONEncoder().encode(credential) else { return false }
        let attributes: [String: Any] = [kSecValueData as String: data, kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly]
        let updated = SecItemUpdate(query() as CFDictionary, attributes as CFDictionary)
        if updated == errSecSuccess { return true }
        guard updated == errSecItemNotFound else { return false }
        return SecItemAdd(query().merging(attributes) { _, new in new } as CFDictionary, nil) == errSecSuccess
    }
    static func create(_ pin: String) -> Bool {
        guard pin.count == 6, pin.allSatisfy({ $0.isASCII && $0.isNumber }) else { return false }
        var bytes = [UInt8](repeating: 0, count: 16)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else { return false }
        let salt = Data(bytes)
        return write(Credential(salt: salt, digest: derive(pin, salt: salt)))
    }
    static func verify(_ pin: String) -> Bool {
        guard var credential = read(), credential.lockedUntil.map({ $0 <= Date() }) ?? true else { return false }
        guard pin.count == 6, pin.allSatisfy({ $0.isASCII && $0.isNumber }), credential.salt.count == 16, credential.digest.count == 32 else { return false }
        let digest = derive(pin, salt: credential.salt)
        let matches = zip(digest, credential.digest).reduce(UInt8(0)) { $0 | ($1.0 ^ $1.1) } == 0
        if matches { credential.failures = 0; credential.lockedUntil = nil }
        else { credential.failures += 1; if credential.failures >= 5 { credential.lockedUntil = Date().addingTimeInterval(300) } }
        return write(credential) && matches
    }
}
