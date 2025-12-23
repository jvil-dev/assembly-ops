//
//  OfflineAction.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/22/25.
//

import Foundation
import SwiftData

@Model
final class OfflineAction {
    // MARK: - Properties
    
    @Attribute(.unique) var id: String
    var actionType: OfflineActionType
    var status: OfflineActionStatus
    var payload: Data  // JSON encoded action data
    var endpoint: String
    var httpMethod: String  // GET, POST, PUT, DELETE
    
    // Retry tracking
    var retryCount: Int
    var maxRetries: Int
    var lastError: String?
    
    // Timestamps
    var createdAt: Date
    var updatedAt: Date
    var syncedAt: Date?
    
    // MARK: - Initializer
    
    init(
        id: String = UUID().uuidString,
        actionType: OfflineActionType,
        status: OfflineActionStatus = .pending,
        payload: Data,
        endpoint: String,
        httpMethod: String = "POST",
        retryCount: Int = 0,
        maxRetries: Int = 3,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.actionType = actionType
        self.status = status
        self.payload = payload
        self.endpoint = endpoint
        self.httpMethod = httpMethod
        self.retryCount = retryCount
        self.maxRetries = maxRetries
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Computed Properties
    
    var canRetry: Bool {
        status == .failed && retryCount < maxRetries
    }
    
    var isPending: Bool {
        status == .pending
    }
    
    // MARK: - Methods
    
    func markSyncing() {
        status = .syncing
        updatedAt = Date()
    }
    
    func markCompleted() {
        status = .completed
        syncedAt = Date()
        updatedAt = Date()
    }
    
    func markFailed(error: String) {
        status = .failed
        lastError = error
        retryCount += 1
        updatedAt = Date()
    }
    
    func resetForRetry() {
        status = .pending
        updatedAt = Date()
    }
}
