//
//  KeychainManager.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/23/25.
//

import Foundation
import Security

final class KeychainManager {
    // MARK: - Singleton
    static let shared = KeychainManager()
    private init() {}
    
    // MARK: - Service Name
    private let serviceName = Constants.Keychain.serviceName
    
    // MARK: - Save
    @discardableResult
    func save(_ data: Data, forKey key: String) -> Bool {
        // Delete existing item first
        delete(forKey: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    @discardableResult
    func save(_ string: String, forKey key: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return save(data, forKey: key)
    }
    
    // MARK: - Retrieve
    func getData(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }
    
    func getString(forKey key: String) -> String? {
        guard let data = getData (forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - Delete
    @discardableResult
    func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
            ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Clear All
    func clearAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Convinience Methods
    
    // Overseer tokens
    var overseerAccessToken: String? {
        get { getString(forKey: Constants.Keychain.overseerAccessToken) }
        set {
            if let value = newValue {
                save(value, forKey: Constants.Keychain.overseerAccessToken)
            } else {
                delete(forKey: Constants.Keychain.overseerAccessToken)
            }
        }
    }
    
    var overseerRefreshToken: String? {
        get { getString(forKey: Constants.Keychain.overseerRefreshToken) }
        set {
            if let value = newValue {
                save(value, forKey: Constants.Keychain.overseerRefreshToken)
            } else {
                delete(forKey: Constants.Keychain.overseerRefreshToken)
            }
        }
    }
    
    var overseerId: String? {
        get { getString(forKey: Constants.Keychain.overseerId) }
        set {
            if let value = newValue {
                save(value, forKey: Constants.Keychain.overseerId)
            } else {
                delete(forKey: Constants.Keychain.overseerId)
            }
        }
    }
    
    // Volunteer tokens
    var volunteerToken: String? {
        get { getString(forKey: Constants.Keychain.volunteerToken) }
        set {
            if let value = newValue {
                save(value, forKey: Constants.Keychain.volunteerToken)
            } else {
                delete(forKey: Constants.Keychain.volunteerToken)
            }
        }
    }

    var volunteerId: String? {
        get { getString(forKey: Constants.Keychain.volunteerId) }
        set {
            if let value = newValue {
                save(value, forKey: Constants.Keychain.volunteerId)
            } else {
                delete(forKey: Constants.Keychain.volunteerId)
            }
        }
    }

    // Session info
    var currentEventId: String? {
        get { getString(forKey: Constants.Keychain.currentEventId) }
        set {
            if let value = newValue {
                save(value, forKey: Constants.Keychain.currentEventId)
            } else {
                delete(forKey: Constants.Keychain.currentEventId)
            }
        }
    }

    var userType: String? {
        get { getString(forKey: Constants.Keychain.userType) }
        set {
            if let value = newValue {
                save(value, forKey: Constants.Keychain.userType)
            } else {
                delete(forKey: Constants.Keychain.userType)
            }
        }
    }

    // MARK: - Session Helpers

    var isOverseerLoggedIn: Bool {
        overseerAccessToken != nil && userType == "overseer"
    }

    var isVolunteerLoggedIn: Bool {
        volunteerToken != nil && userType == "volunteer"
    }

    var isLoggedIn: Bool {
        isOverseerLoggedIn || isVolunteerLoggedIn
    }

    func clearOverseerSession() {
        overseerAccessToken = nil
        overseerRefreshToken = nil
        overseerId = nil
        currentEventId = nil
        userType = nil
    }

    func clearVolunteerSession() {
        volunteerToken = nil
        volunteerId = nil
        currentEventId = nil
        userType = nil
    }

    func clearAllSessions() {
        clearOverseerSession()
        clearVolunteerSession()
    }
}
