//
//  DateUtils.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/13/26.
//

// MARK: - Date Utils
//
// Shared date formatting utilities for consistent parsing across the app.
//
// Properties:
//   - isoFormatter: ISO8601 formatter for GraphQL DateTime fields
//
// Used by: CheckInService, ProfileViewModel, Message

import Foundation

enum DateUtils {
    /// Shared ISO8601 formatter for parsing GraphQL DateTime strings
    /// Format: 2026-01-13T10:15:30.123Z
    static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    /// Parse an ISO8601 date string into a Date object
    /// - Parameter dateString: ISO8601 formatted date string
    /// - Returns: Date object if parsing succeeds, nil otherwise
    static func parseISO8601(_ dateString: String) -> Date? {
        return isoFormatter.date(from: dateString)
    }

    /// Format a date as a relative time string (e.g., "2h ago", "3d ago")
    static func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
