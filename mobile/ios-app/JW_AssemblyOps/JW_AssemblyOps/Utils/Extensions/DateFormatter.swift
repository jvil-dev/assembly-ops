//
//  DateFormatter.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/23/25.
//

import Foundation

extension DateFormatter {
    
    /// ISO8601 formatter for API communication
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    /// ISO8601 formatter without milliseconds
    static let iso8601Short: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    /// Date only formatter for API (yyyy-MM-dd)
    static let apiDateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    /// Time only formatter for API (HH:mm:ss)
    static let apiTimeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

// MARK: - Date Extensions

extension Date {
    
    /// Convert to ISO8601 string for API
    var iso8601String: String {
        DateFormatter.iso8601.string(from: self)
    }
    
    /// Convert to date-only string for API (yyyy-MM-dd)
    var apiDateString: String {
        DateFormatter.apiDateOnly.string(from: self)
    }
    
    /// Convert to time-only string for API (HH:mm:ss)
    var apiTimeString: String {
        DateFormatter.apiTimeOnly.string(from: self)
    }
}

// MARK: - String Extensions

extension String {
    
    /// Parse ISO8601 string to Date
    var iso8601Date: Date? {
        DateFormatter.iso8601.date(from: self) ??
        DateFormatter.iso8601Short.date(from: self)
    }
    
    /// Parse API date-only string (yyyy-MM-dd) to Date
    var apiDate: Date? {
        DateFormatter.apiDateOnly.date(from: self)
    }
    
    /// Parse API time-only string (HH:mm:ss) to Date
    var apiTime: Date? {
        DateFormatter.apiTimeOnly.date(from: self)
    }
}
