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
//   - Color bar: Varies by status (green=checked in, blue=checked out, red=no show, gray/orange=pending)
//   - Details: Post name, department, optional location
//   - Status indicator: Badge/icon based on check-in status
//
// Status States:
//   - pending: Chevron (orange if today, gray otherwise)
//   - checkedIn: Green "In" badge
//   - checkedOut: Blue "Out" badge
//   - noShow: Red X icon
//
// Behavior:
//   - Tappable (wrapped in NavigationLink by parent)
//   - Visual distinction between all status states
//
// Preview Data:
//   - Assignment.preview: Pending assignment (today)
//   - Assignment.previewCheckedIn: Checked-in assignment
//   - Assignment.previewCheckedOut: Checked-out assignment
//   - Assignment.previewNoShow: No-show assignment
//
// Dependencies:
//   - Assignment: Data model with CheckInStatus
//
// Used by: AssignmentsListView.swift

import SwiftUI

struct AssignmentCardView: View {
    let assignment: Assignment
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator bar
            Rectangle()
                .fill(statusColor)
                .frame(width: 4)
                .clipShape(RoundedRectangle(cornerRadius: 2))
            
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
            
            // Status badge
            statusBadge
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var statusBadge: some View {
        switch assignment.checkInStatus {
        case .checkedIn:
            Label("In", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green)
                .clipShape(Capsule())
            
        case .checkedOut:
            Label("Out", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue)
                .clipShape(Capsule())
            
        case .noShow:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
                .font(.title2)
            
        case .pending:
            if assignment.isToday {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            } else {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
        }
    }
    
    private var statusColor: Color {
        switch assignment.checkInStatus {
        case .checkedIn: return .green
        case .checkedOut: return .blue
        case .noShow: return .red
        case .pending: return assignment.isToday ? .orange : .gray
        }
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
