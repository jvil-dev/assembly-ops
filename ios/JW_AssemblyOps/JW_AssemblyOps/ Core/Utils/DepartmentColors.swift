//
//  DepartmentColors.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 1/2/26.
//

// MARK: - Department Colors
//
// Utility for mapping department types to their lanyard colors.
// Colors are defined in Assets.xcassets as "Department: [Name]" color sets.
//
// Methods:
//   - color(for:): Get SwiftUI Color for a department type string
//   - backgroundColor(for:): Get lighter variant (15% opacity) for backgrounds
//   - colorName(for:): Get human-readable color name for accessibility
//
// Usage:
//   DepartmentColor.color(for: "ATTENDANT")  // Returns Color("Department: Attendant")
//
// Used by: AssignmentCardView, AssignmentDetailView, ProfileView, Volunteer

import SwiftUI

enum DepartmentColor {
    
    static func color(for departmentType: String) -> Color {
        switch departmentType {
        case "PARKING":
            return Color("Department: Parking")
        case "ATTENDANT":
            return Color("Department: Attendant")
        case "AUDIO/VIDEO", "AV", "AUDIO_VIDEO":
            return Color("Department: Audio-Video")
        case "CLEANING":
            return Color("Department: Cleaning")
        case "COMMITTEE":
            return Color("Department: Committee")
        case "FIRST_AID", "FIRSTAID":
            return Color("Department: First Aid")
            
        // Assigned colors
        case "BAPTISM":
            return Color("Department: Baptism")
        case "INFORMATION", "INFORMATION_VOLUNTEER_SERVICE":
            return Color("Department: Information")
        case "ACCOUNTS":
            return Color("Department: Accounts")
        case "INSTALLATION":
            return Color("Department: Installation")
        case "LOST_FOUND", "LOST_AND_FOUND":
            return Color("Department: LostFound")
        case "ROOMING":
            return Color("Department: Rooming")
        case "TRUCKING", "TRUCKING_EQUIPMENT":
            return Color("Department: Trucking")
            
        default:
            return Color("Department: Default")
        }
    }
    
    /// Get lighter variant for backgrounds
    static func backgroundColor(for departmentType: String) -> Color {
        color(for: departmentType).opacity(0.15)
    }
    
    /// Get color name for accessibility
    static func colorName(for departmentType: String) -> String {
        switch departmentType.uppercased() {
        case "PARKING": return "Yellow"
        case "ATTENDANT": return "Orange"
        case "AUDIO_VIDEO", "AV", "AUDIO/VIDEO": return "Green"
        case "CLEANING": return "Teal"
        case "COMMITTEE": return "White"
        case "FIRST_AID", "FIRSTAID": return "Red"
        case "BAPTISM": return "Light Blue"
        case "INFORMATION", "INFORMATION_VOLUNTEER_SERVICE": return "Brown"
        case "ACCOUNTS": return "Forest Green"
        case "INSTALLATION": return "Slate"
        case "LOST_FOUND", "LOST_AND_FOUND", "LOST_FOUND_CHECKROOM": return "Purple"
        case "ROOMING": return "Indigo"
        case "TRUCKING", "TRUCKING_EQUIPMENT": return "Charcoal"
        default: return "Gray"
        }
    }
}
