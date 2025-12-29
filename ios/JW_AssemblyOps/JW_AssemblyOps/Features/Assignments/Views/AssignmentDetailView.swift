//
//  AssignmentDetailView.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//

// MARK: - Assignment Detail View
//
// Full-screen view showing complete details for a single assignment.
// Displays post info, time, location, and check-in status.
//
// Components:
//   - Header card: Post name and session
//   - Detail sections: Time, date, department, location
//   - Check-in status: Shows checked-in state with timestamp
//   - Check-in button: Placeholder for future check-in functionality
//
// Behavior:
//   - Read-only display of assignment details
//   - Check-in button shown only for today's unchecked assignments
//   - Check-in functionality to be implemented in Sprint 3.3
//
// Dependencies:
//   - Assignment: Data model passed from list view
//
// Used by: AssignmentsListView.swift (via NavigationLink)

import SwiftUI

struct AssignmentDetailView: View {
    let assignment: Assignment
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header card
                headerCard
                
                // Details sections
                VStack(spacing: 16) {
                    detailSection(
                        title: "Time",
                        icon: "clock",
                        content: assignment.timeRangeFormatted
                    )
                    
                    detailSection(
                        title: "Date",
                        icon: "calendar",
                        content: assignment.date.formatted(date: .complete, time: .omitted)
                    )
                    
                    detailSection(
                        title: "Department",
                        icon: "person.2",
                        content: assignment.departmentName
                    )
                    
                    if let location = assignment.postLocation {
                        detailSection(
                            title: "Location",
                            icon: "location",
                            content: location
                        )
                    }
                }
                
                // Check-in status
                checkInStatusCard
                
                // Check-in button (placeholder for Sprint 3.3)
                if !assignment.isCheckedIn && assignment.isToday {
                    checkInButton
                }
                
                Spacer()
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Assignment")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Subviews
    
    private var headerCard: some View {
        VStack(spacing: 8) {
            Text(assignment.postName)
                .font(.title)
                .fontWeight(.bold)
            
            Text(assignment.sessionName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func detailSection(title: String, icon: String, content: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(content)
                    .font(.body)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var checkInStatusCard: some View {
        HStack(spacing: 12) {
            Image(systemName: assignment.isCheckedIn ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(assignment.isCheckedIn ? .green : .secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(assignment.isCheckedIn ? "Checked In" : "Not Checked In")
                    .font(.headline)
                
                if let checkInTime = assignment.checkInTime {
                    Text("at \(checkInTime.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var checkInButton: some View {
        Button {
            // TODO: Implement in Sprint 3.3
        } label: {
            Label("Check In", systemImage: "checkmark.circle")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
        }
        .buttonStyle(.borderedProminent)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        AssignmentDetailView(assignment: .preview)
    }
}

#Preview("Checked In") {
    NavigationStack {
        AssignmentDetailView(assignment: .previewCheckedIn)
    }
}
