//
//  SecureStorage.swift
//  Pastor
//
//  Created by Victor Dombrovskiy on 27.10.2025.
//

import Foundation
import CryptoKit
import Security

final class SecureStorage {
    
    private let fileName: String
    private let keychainKey: String
    
    init(fileName: String, keychainKey: String) {
        self.fileName = fileName
        self.keychainKey = keychainKey
        
        prettyPrintStorageSize()
    }

    func prettyPrintStorageSize() {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB] // choose which units to show
        formatter.countStyle = .file
        if let encryptedData = try? Data(contentsOf: fileURL()) {
            let sizeString = formatter.string(fromByteCount: Int64(encryptedData.count))
            print("Storage size pretty printed: \(sizeString)")
        }
    }
    
    // MARK: - Encryption Key Management
    
    private func getOrCreateKey() throws -> SymmetricKey {
        if let existingData = loadFromKeychain(key: keychainKey),
           let key = try? SymmetricKey(data: existingData) {
            return key
        }
        
        // Create new random key
        let newKey = SymmetricKey(size: .bits256)
        let data = newKey.withUnsafeBytes { Data($0) }
        saveToKeychain(data: data, key: keychainKey)
        return newKey
    }
    
    // MARK: - Public API
    
    func saveStrings(_ strings: [String]) throws {
        let key = try getOrCreateKey()
        
        // Convert to JSON
        let jsonData = try JSONEncoder().encode(strings)
        
        // Encrypt
        let sealedBox = try AES.GCM.seal(jsonData, using: key)
        let combined = sealedBox.combined! // nonce + ciphertext + tag
        
        // Save to file
        try combined.write(to: fileURL(), options: .atomic)
    }
    
    func loadStrings() throws -> [String] {
        let key = try getOrCreateKey()
        let encryptedData = try Data(contentsOf: fileURL())
        
        // Decrypt
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decrypted = try AES.GCM.open(sealedBox, using: key)
        let decoded = try JSONDecoder().decode([String].self, from: decrypted)
        
        return decoded
    }
    
    func deleteAll() {
        try? FileManager.default.removeItem(at: fileURL())
        _ = deleteFromKeychain(key: keychainKey)
    }
    
    // MARK: - Helpers
    
    private func fileURL() -> URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(fileName)
    }
    
    // MARK: - Keychain I/O
    
    private func saveToKeychain(data: Data, key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func loadFromKeychain(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else { return nil }
        return item as? Data
    }
    
    private func deleteFromKeychain(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }
}
