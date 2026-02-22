//
//  AttendantPostCategory.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/21/26.
//

// MARK: - Attendant Post Category
//
// Hardcoded category structure for the Attendant department.
// Posts universally follow Interior (I), Exterior (E), and Seating (S).
// Subcategories (e.g. "Exterior - Doors") are optional free-text suffixes
// stored as plain strings in the Post.category field.
//
// Usage:
//   AttendantMainCategory.storageString(main: .exterior, sub: "Doors") → "Exterior - Doors"
//   AttendantMainCategory.sortIndex(for: "Exterior - Doors")           → 1

import Foundation

enum AttendantMainCategory: String, CaseIterable, Identifiable {
    case interior = "Interior"
    case exterior = "Exterior"
    case seating  = "Seating"

    var id: String { rawValue }

    var code: String {
        switch self {
        case .interior: return "I"
        case .exterior: return "E"
        case .seating:  return "S"
        }
    }

    /// Common subcategory chips shown for Exterior. Other mains have none.
    var commonSubcategories: [String] {
        switch self {
        case .exterior: return ["Doors", "Parking", "Ramp"]
        default: return []
        }
    }

    /// Returns the string to store in Post.category.
    /// If sub is nil or empty, returns just the main category name.
    static func storageString(main: AttendantMainCategory, sub: String?) -> String {
        if let sub = sub, !sub.trimmingCharacters(in: .whitespaces).isEmpty {
            return "\(main.rawValue) - \(sub.trimmingCharacters(in: .whitespaces))"
        }
        return main.rawValue
    }

    /// Returns the display prefix badge string for a stored category value.
    /// e.g. "Exterior - Doors" → "E · Exterior - Doors"
    static func displayString(for category: String) -> String {
        if let match = AttendantMainCategory.allCases.first(where: {
            category == $0.rawValue || category.hasPrefix("\($0.rawValue) -")
        }) {
            return "\(match.code) · \(category)"
        }
        return category
    }

    /// Sort index for ordering I → E → S → unknown in SessionDetailView.
    static func sortIndex(for category: String) -> Int {
        for (index, main) in AttendantMainCategory.allCases.enumerated() {
            if category == main.rawValue || category.hasPrefix("\(main.rawValue) -") {
                return index
            }
        }
        return AttendantMainCategory.allCases.count
    }
}
