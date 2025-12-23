//
//  Constants.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/21/25.
//

import Foundation

enum Constants {
    
    // MARK: - API Configuration
    enum API {
        #if DEBUG
        static let baseURL = "http://localhost:3000/api"
        #else
        static let baseURL = "https://api.assemblyops.com/api"  // Update for production
        #endif
        
        static let timeout: TimeInterval = 30.0
        
        // API Versions
        static let version = "v1"
        
        // Full base URL with version
        static var versionedBaseURL: String {
            "\(baseURL)/\(version)"
        }
    }
    
    // MARK: - Keychain Keys
    enum Keychain {
        static let serviceName = "com.jorgevilleda.JWAssemblyOps"
        
        // Overseer tokens
        static let overseerAccessToken = "overseer_access_token"
        static let overseerRefreshToken = "overseer_refresh_token"
        static let overseerId = "overseer_id"
        
        // Volunteer tokens
        static let volunteerToken = "volunteer_token"
        static let volunteerId = "volunteer_id"
        
        // Session info
        static let currentEventId = "current_event_id"
        static let userType = "user_type"  // "overseer" or "volunteer"
    }
    
    // MARK: - UserDefaults Keys
    enum UserDefaults {
        static let hasCompletedOnboarding = "has_completed_onboarding"
        static let lastSyncTimestamp = "last_sync_timestamp"
        static let preferredLanguage = "preferred_language"
    }
    
    // MARK: - App Info
    enum App {
        static let name = "JW AssemblyOps"
        static let tagline = "Volunteer Management System"
        static let supportEmail = "support@assemblyops.com"  // Update later
        static let minimumPasswordLength = 8
    }
    
    // MARK: - Sync Configuration
    enum Sync {
        static let fullSyncInterval: TimeInterval = 3600  // 1 hour
        static let deltaSyncInterval: TimeInterval = 300  // 5 minutes
        static let maxRetryAttempts = 3
        static let retryDelay: TimeInterval = 5.0
    }
    
    // MARK: - Validation
    enum Validation {
        static let maxVolunteersPerAssignment = 10
        static let maxMessageLength = 500
        static let volunteerIdLength = 8
        static let tokenLength = 16
    }
}
