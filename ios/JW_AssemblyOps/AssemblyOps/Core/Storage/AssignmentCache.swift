//
//  AssignmentCache.swift
//  AssemblyOps
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
    let postId: String
    let postCategory: String?
    let areaId: String?
    let areaName: String?
    let departmentName: String
    let departmentType: String
    let eventId: String
    let sessionName: String
    let sessionId: String
    let date: Date
    let startTime: Date
    let endTime: Date

    // Shift times (for Attendant assignments with post-specific shifts)
    let shiftId: String?
    let shiftName: String?
    let shiftStartTime: Date?
    let shiftEndTime: Date?

    // Department session times (overseer-configured per-dept times)
    let deptSessionStartTime: Date?
    let deptSessionEndTime: Date?

    // Assignment status (acceptance workflow)
    let status: String
    let isCaptain: Bool
    let canCount: Bool
    let respondedAt: Date?
    let declineReason: String?
    let acceptDeadline: Date?
    let forceAssigned: Bool

    // Check-in status (attendance tracking)
    let checkInStatus: String
    let checkInTime: Date?
    let checkOutTime: Date?

    init(from assignment: Assignment) {
        self.id = assignment.id
        self.postName = assignment.postName
        self.postLocation = assignment.postLocation
        self.postId = assignment.postId
        self.postCategory = assignment.postCategory
        self.areaId = assignment.areaId
        self.areaName = assignment.areaName
        self.departmentName = assignment.departmentName
        self.departmentType = assignment.departmentType
        self.eventId = assignment.eventId
        self.sessionName = assignment.sessionName
        self.sessionId = assignment.sessionId
        self.date = assignment.date
        self.startTime = assignment.startTime
        self.endTime = assignment.endTime
        self.shiftId = assignment.shiftId
        self.shiftName = assignment.shiftName
        self.shiftStartTime = assignment.shiftStartTime
        self.shiftEndTime = assignment.shiftEndTime
        self.deptSessionStartTime = assignment.deptSessionStartTime
        self.deptSessionEndTime = assignment.deptSessionEndTime
        self.status = assignment.status.rawValue
        self.isCaptain = assignment.isCaptain
        self.canCount = assignment.canCount
        self.respondedAt = assignment.respondedAt
        self.declineReason = assignment.declineReason
        self.acceptDeadline = assignment.acceptDeadline
        self.forceAssigned = assignment.forceAssigned
        self.checkInStatus = assignment.checkInStatus.rawValue
        self.checkInTime = assignment.checkInTime
        self.checkOutTime = assignment.checkOutTime
    }

    func toAssignment() -> Assignment {
        Assignment(
            id: id,
            postName: postName,
            postLocation: postLocation,
            postId: postId,
            postCategory: postCategory,
            areaId: areaId,
            areaName: areaName,
            departmentName: departmentName,
            departmentType: departmentType,
            eventId: eventId,
            sessionName: sessionName,
            sessionId: sessionId,
            date: date,
            startTime: startTime,
            endTime: endTime,
            shiftId: shiftId,
            shiftName: shiftName,
            shiftStartTime: shiftStartTime,
            shiftEndTime: shiftEndTime,
            deptSessionStartTime: deptSessionStartTime,
            deptSessionEndTime: deptSessionEndTime,
            status: AssignmentStatus(rawValue: status) ?? .pending,
            isCaptain: isCaptain,
            canCount: canCount,
            respondedAt: respondedAt,
            declineReason: declineReason,
            acceptDeadline: acceptDeadline,
            forceAssigned: forceAssigned,
            checkInStatus: CheckInStatus(rawValue: checkInStatus) ?? .pending,
            checkInTime: checkInTime,
            checkOutTime: checkOutTime
        )
    }
}
