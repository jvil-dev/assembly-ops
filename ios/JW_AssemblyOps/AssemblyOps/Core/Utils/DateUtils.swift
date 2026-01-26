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
}
