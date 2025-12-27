//
//  AssignmentDetailView.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//


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
