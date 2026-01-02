//
//  AssignmentDetailView.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//

// MARK: - Assignment Detail View
//
// Full-screen view showing complete details for a single assignment.
// Displays post info, time, location, and check-in/out functionality.
//
// Components:
//   - Header card: Post name and session
//   - Detail sections: Time, date, department, location
//   - Check-in status card: Shows current status with timestamps
//   - CheckInButton: Check-in/out actions for today's assignments
//
// Behavior:
//   - Check-in button shown for today's pending assignments
//   - Check-out button shown after checking in
//   - Haptic feedback on success/error
//   - Error alerts for failed operations
//   - Local state updates after successful check-in/out
//
// Dependencies:
//   - Assignment: Data model (mutable via @State)
//   - CheckInButton: Reusable check-in/out button component
//   - CheckInService: API calls for check-in operations
//   - HapticManager: Haptic feedback
//
// Used by: AssignmentsListView.swift (via NavigationLink)

import SwiftUI

struct AssignmentDetailView: View {
    @State var assignment: Assignment
    
    @State private var showingError = false
    @State private var errorMessage = ""
    
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
                
                // Check-in/out button
                CheckInButton(assignment: assignment, onCheckIn: performCheckIn, onCheckOut: performCheckOut)
                    .padding(.top, 8)
                Spacer()
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Assignment")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Actions
    
    private func performCheckIn() async {
        do {
            let result = try await CheckInService.shared.checkIn(assignmentId: assignment.id)
            
            // Update local state
            await MainActor.run {
                assignment = Assignment(id: assignment.id, postName: assignment.postName, postLocation: assignment.postName, departmentName: assignment.departmentName, sessionName: assignment.sessionName, date: assignment.date, startTime: assignment.startTime, endTime: assignment.endTime, checkInStatus: result.status, checkInTime: result.checkInTime, checkOutTime: nil)
                
                // Haptic feedback
                HapticManager.shared.success()
            }
        } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    HapticManager.shared.error()
                }
            }
        }
    
    private func performCheckOut() async {
        do {
            let result = try await CheckInService.shared.checkOut(assignmentId: assignment.id)
            
            // Update local state
            await MainActor.run {
                assignment = Assignment(id: assignment.id, postName: assignment.postName, postLocation: assignment.postLocation, departmentName: assignment.departmentName, sessionName: assignment.sessionName, date: assignment.date, startTime: assignment.startTime, endTime: assignment.endTime, checkInStatus: result.status, checkInTime: result.checkInTime, checkOutTime: result.checkOutTime)
                
                // Haptic feedback
                HapticManager.shared.success()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
                HapticManager.shared.error()
            }
        }
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
            Image(systemName: statusIcon)
                .font(.title2)
                .foregroundStyle(statusIconColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(assignment.statusText.isEmpty ? "Pending" : assignment.statusText)
                    .font(.headline)
                
                if let checkInTime = assignment.checkInTime {
                    Text("Checked in at \(checkInTime.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if let checkOutTime = assignment.checkOutTime {
                    Text("Checked out at \(checkOutTime.formatted(date: .omitted, time: .shortened))")
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
    
    private var statusIcon: String {
        switch assignment.checkInStatus {
        case .checkedIn: return "checkmark.circle.fill"
        case .checkedOut: return "arrow.right.circle.fill"
        case .noShow: return "xmark.circle.fill"
        case .pending: return "circle"
        }
    }
    
    private var statusIconColor: Color {
        switch assignment.checkInStatus {
        case .checkedIn: return .green
        case .checkedOut: return .blue
        case .noShow: return .red
        case .pending: return .secondary
        }
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
