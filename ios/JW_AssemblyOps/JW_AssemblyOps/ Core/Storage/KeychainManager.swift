//
//  KeychainManager.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/26/25.
//


import Foundation
import Security

/// Secure storage for authentication tokens using iOS Keychain
final class KeychainManager {
    static let shared = KeychainManager()
    
    private let service = "com.assemblyops.auth"
    
    private enum Keys {
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
        static let expiresAt = "expiresAt"
        static let volunteerId = "volunteerId"
    }
    
    private init() {}
    
    // MARK: - Token Storage
    
    var accessToken: String? {
        get { getString(for: Keys.accessToken) }
        set { setString(newValue, for: Keys.accessToken) }
    }
    
    var refreshToken: String? {
        get { getString(for: Keys.refreshToken) }
        set { setString(newValue, for: Keys.refreshToken) }
    }
    
    var tokenExpiresAt: Date? {
        get {
            guard let interval = getDouble(for: Keys.expiresAt) else { return nil }
            return Date(timeIntervalSince1970: interval)
        }
        set {
            setDouble(newValue?.timeIntervalSince1970, for: Keys.expiresAt)
        }
    }
    
    var volunteerId: String? {
        get { getString(for: Keys.volunteerId) }
        set { setString(newValue, for: Keys.volunteerId) }
    }
    
    // MARK: - Convenience
    
    var isLoggedIn: Bool {
        accessToken != nil && refreshToken != nil
    }
    
    var isTokenExpired: Bool {
        guard let expiresAt = tokenExpiresAt else { return true }
        // Consider expired if less than 60 seconds remaining
        return expiresAt.timeIntervalSinceNow < 60
    }
    
    func saveTokens(accessToken: String, refreshToken: String, expiresIn: Int) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenExpiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))
    }
    
    func clearAll() {
        accessToken = nil
        refreshToken = nil
        tokenExpiresAt = nil
        volunteerId = nil
    }
    
    // MARK: - Private Helpers
    
    private func getString(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    private func setString(_ value: String?, for key: String) {
        // Delete existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Add new item if value exists
        guard let value = value, let data = value.data(using: .utf8) else { return }
        
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        SecItemAdd(addQuery as CFDictionary, nil)
    }
    
    private func getDouble(for key: String) -> Double? {
        guard let string = getString(for: key) else { return nil }
        return Double(string)
    }
    
    private func setDouble(_ value: Double?, for key: String) {
        guard let value = value else {
            setString(nil, for: key)
            return
        }
        setString(String(value), for: key)
    }
}