//
//  AssignmentCache.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 1/15/26.
//

// MARK: - Assignment Cache
//
// Persists volunteer assignments to UserDefaults for offline access.
// Uses Codable wrapper to serialize Assignment objects to JSON.
//
// Methods:
//   - save(_:): Encode and store assignments with timestamp
//   - load(): Decode and return cached assignments (nil if empty)
//   - clear(): Remove cached data
//
// Properties:
//   - cacheTimestamp: When cache was last updated
//   - isStale: True if cache is older than 1 hour
//
// Implementation:
//   - Uses CachedAssignment private struct for Codable conformance
//   - Stores data under "cached_assignments" key
//
// Dependencies:
//   - Assignment model, CheckInStatus enum
//
// Used by: AssignmentsViewModel

import Foundation

/// Caches assignments locally for offline access
final class AssignmentCache {
    static let shared = AssignmentCache()
    
    private let cacheKey = "cached_assignments"
    private let cacheTimestampKey = "cached_assignments_timestamp"
    
    private init() {}
    
    /// Save assignments to cache
    func save(_ assignments: [Assignment]) {
        do {
            let data = try JSONEncoder().encode(assignments.map { CachedAssignment(from: $0) })
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date(), forKey: cacheTimestampKey)
        } catch {
            print("Failed to cache assignments: \(error)")
        }
    }
    
    /// Load assignments from cache
    func load() -> [Assignment]? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else {
            return nil
        }
        
        do {
            let cached = try JSONDecoder().decode([CachedAssignment].self, from: data)
            return cached.map { $0.toAssignment() }
        } catch {
            print("Failed to load cached assignments: \(error)")
            return nil
        }
    }
    
    /// Get cache timestamp
    var cacheTimestamp: Date? {
        UserDefaults.standard.object(forKey: cacheTimestampKey) as? Date
    }
    
    /// Check if cache is stale (older than 1 hour)
    var isStale: Bool {
        guard let timestamp = cacheTimestamp else { return true }
        return Date().timeIntervalSince(timestamp) > 3600
    }
    
    /// Clear cache
    func clear() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: cacheTimestampKey)
    }
}

/// Codable wrapper for Assignment
private struct CachedAssignment: Codable {
    let id: String
    let postName: String
    let postLocation: String?
    let departmentName: String
    let departmentType: String
    let sessionName: String
    let date: Date
    let startTime: Date
    let endTime: Date
    let checkInStatus: String
    let checkInTime: Date?
    let checkOutTime: Date?
    
    init(from assignment: Assignment) {
        self.id = assignment.id
        self.postName = assignment.postName
        self.postLocation = assignment.postLocation
        self.departmentName = assignment.departmentName
        self.departmentType = assignment.departmentType
        self.sessionName = assignment.sessionName
        self.date = assignment.date
        self.startTime = assignment.startTime
        self.endTime = assignment.endTime
        self.checkInStatus = assignment.checkInStatus.rawValue
        self.checkInTime = assignment.checkInTime
        self.checkOutTime = assignment.checkOutTime
    }
    
    func toAssignment() -> Assignment {
        Assignment(
            id: id,
            postName: postName,
            postLocation: postLocation,
            departmentName: departmentName,
            departmentType: departmentType,
            sessionName: sessionName,
            date: date,
            startTime: startTime,
            endTime: endTime,
            checkInStatus: CheckInStatus(rawValue: checkInStatus) ?? .pending,
            checkInTime: checkInTime,
            checkOutTime: checkOutTime
        )
    }
}
