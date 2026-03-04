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

    /// Format a Date as a smart message timestamp:
    /// - Today → "2:45 PM" (device locale short time)
    /// - Yesterday → "Yesterday"
    /// - Older → "3/1/26" (device locale short date)
    static func formattedMessageDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.timeStyle = .short
            formatter.dateStyle = .none
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .short
            formatter.timeStyle = .none
        }
        return formatter.string(from: date)
    }

    // MARK: - UTC Calendar & Formatters (for event dates stored as UTC midnight)

    /// Calendar fixed to UTC — use for date-status comparisons on events whose
    /// dates are stored as UTC midnight (e.g. 2026-03-22T00:00:00.000Z).
    static let utcCalendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    private static let eventDateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        fmt.timeZone = TimeZone(identifier: "UTC")
        return fmt
    }()

    private static let eventYearFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy"
        fmt.timeZone = TimeZone(identifier: "UTC")
        return fmt
    }()

    static let eventFullDateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d, yyyy"
        fmt.timeZone = TimeZone(identifier: "UTC")
        return fmt
    }()

    /// Format a start/end Date pair: "Mar 22 – Mar 22, 2026"
    static func formatEventDateRange(from start: Date, to end: Date) -> String {
        let startStr = eventDateFormatter.string(from: start)
        let endStr = eventDateFormatter.string(from: end)
        let year = eventYearFormatter.string(from: start)
        return "\(startStr) – \(endStr), \(year)"
    }

    /// Format start/end ISO 8601 strings: "Mar 22 – Mar 22, 2026"
    static func formatEventDateRange(from startISO: String, to endISO: String) -> String {
        guard let start = parseISO8601(startISO),
              let end = parseISO8601(endISO) else {
            return "\(startISO) – \(endISO)"
        }
        return formatEventDateRange(from: start, to: end)
    }

    /// Format a start/end Date pair with full dates: "Mar 22, 2026 – Mar 22, 2026"
    static func formatEventFullDateRange(from start: Date, to end: Date) -> String {
        let startStr = eventFullDateFormatter.string(from: start)
        let endStr = eventFullDateFormatter.string(from: end)
        return "\(startStr) – \(endStr)"
    }

    /// Format start/end ISO 8601 strings with full dates: "Mar 22, 2026 – Mar 22, 2026"
    static func formatEventFullDateRange(from startISO: String, to endISO: String) -> String {
        guard let start = parseISO8601(startISO),
              let end = parseISO8601(endISO) else {
            return "\(startISO) – \(endISO)"
        }
        return formatEventFullDateRange(from: start, to: end)
    }

    // MARK: - Session Date Formatters (UTC-aware)
    //
    // Session dates are stored as PostgreSQL DATE (no time) and arrive as
    // UTC midnight (e.g. 2026-03-22T00:00:00.000Z).  Using the device
    // calendar would shift them back one day for timezones west of UTC.

    private static let sessionDateFullFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateStyle = .full       // "Sunday, March 22, 2026"
        fmt.timeStyle = .none
        fmt.timeZone = TimeZone(identifier: "UTC")
        return fmt
    }()

    private static let sessionDateAbbreviatedFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium     // "Mar 22, 2026"
        fmt.timeStyle = .none
        fmt.timeZone = TimeZone(identifier: "UTC")
        return fmt
    }()

    /// Full session date: "Sunday, March 22, 2026"
    static func formatSessionDateFull(_ date: Date) -> String {
        sessionDateFullFormatter.string(from: date)
    }

    /// Abbreviated session date: "Mar 22, 2026"
    static func formatSessionDateAbbreviated(_ date: Date) -> String {
        sessionDateAbbreviatedFormatter.string(from: date)
    }

    /// Whether a UTC-midnight session date falls on today (UTC-aware).
    static func isSessionDateToday(_ date: Date) -> Bool {
        utcCalendar.isDateInToday(date)
    }

    /// Whether a UTC-midnight session date falls on tomorrow (UTC-aware).
    static func isSessionDateTomorrow(_ date: Date) -> Bool {
        utcCalendar.isDateInTomorrow(date)
    }

    /// Start-of-day in UTC for a session date.
    static func sessionStartOfDay(for date: Date) -> Date {
        utcCalendar.startOfDay(for: date)
    }

    /// Format elapsed time between two dates (e.g., "14m", "1h 23m", "2d 4h")
    /// Used for lost person alerts to show urgency of open cases.
    static func elapsedString(from start: Date, to end: Date = Date()) -> String {
        let seconds = Int(end.timeIntervalSince(start))
        let minutes = seconds / 60
        let hours = minutes / 60
        let days = hours / 24
        if days > 0 { return "\(days)d \(hours % 24)h" }
        if hours > 0 { return "\(hours)h \(minutes % 60)m" }
        return "\(max(1, minutes))m"
    }
}
