//
//  AssignmentCardView.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//

// MARK: - Assignment Card View
//
// Compact card displaying assignment summary in the schedule list.
// Used as the row view in AssignmentsListView.
//
// Components:
//   - Time column: Start and end times
//   - Color bar: Green if checked in, blue otherwise
//   - Details: Post name, department, optional location
//   - Status indicator: Checkmark if checked in, chevron otherwise
//
// Behavior:
//   - Tappable (wrapped in NavigationLink by parent)
//   - Visual distinction between checked-in and pending assignments
//
// Preview Data:
//   - Assignment.preview: Sample unchecked assignment
//   - Assignment.previewCheckedIn: Sample checked-in assignment
//
// Dependencies:
//   - Assignment: Data model
//
// Used by: AssignmentsListView.swift

import SwiftUI

struct AssignmentCardView: View {
    let assignment: Assignment
    
    var body: some View {
        HStack(spacing: 12) {
            // Time column
            VStack(alignment: .center, spacing: 2) {
                Text(assignment.startTime, style: .time)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(assignment.endTime, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 60)
            
            // Divider
            Rectangle()
                .fill(assignment.isCheckedIn ? Color.green : Color.blue)
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: 2))
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(assignment.postName)
                    .font(.headline)
                
                Text(assignment.departmentName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if let location = assignment.postLocation {
                    HStack(spacing: 4) {
                        Image(systemName: "location")
                            .font(.caption)
                        Text(location)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Status indicator
            if assignment.isCheckedIn {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title2)
            } else {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    VStack(spacing: 12) {
        AssignmentCardView(assignment: .preview)
        AssignmentCardView(assignment: .previewCheckedIn)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

// MARK: - Preview Data
extension Assignment {
    static var preview: Assignment {
        Assignment(
            id: "1",
            postName: "East Lobby",
            postLocation: "Building A, Floor 1",
            departmentName: "Attendant",
            sessionName: "Saturday Morning",
            date: Date(),
            startTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!,
            endTime: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!,
            isCheckedIn: false,
            checkInTime: nil
        )
    }
    
    static var previewCheckedIn: Assignment {
        Assignment(
            id: "2",
            postName: "Auditorium",
            postLocation: "Main Hall",
            departmentName: "Attendant",
            sessionName: "Saturday Afternoon",
            date: Date(),
            startTime: Calendar.current.date(bySettingHour: 13, minute: 30, second: 0, of: Date())!,
            endTime: Calendar.current.date(bySettingHour: 16, minute: 30, second: 0, of: Date())!,
            isCheckedIn: true,
            checkInTime: Date()
        )
    }
}