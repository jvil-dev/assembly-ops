//
//  CheckInButton.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 1/2/26.
//

// MARK: - Check-In Button
//
// Reusable button component for check-in/check-out actions.
// Displays different states based on assignment's check-in status.
//
// States:
//   - canCheckIn: Green "Check In" button (pending + today)
//   - canCheckOut: Blue "Check Out" button (checked in)
//   - isCheckedOut: "Checked Out" label (completed)
//   - noShow: "Marked No Show" label (admin marked)
//   - else: EmptyView (not today or already handled)
//
// Properties:
//   - assignment: The assignment to check in/out
//   - onCheckIn: Async closure called when check-in tapped
//   - onCheckOut: Async closure called when check-out tapped
//
// Behavior:
//   - Shows loading spinner during async operations
//   - Disables button while loading to prevent double-taps
//
// Used by: AssignmentDetailView

import SwiftUI

struct CheckInButton: View {
    let assignment: Assignment
    let onCheckIn: () async -> Void
    let onCheckOut: () async -> Void
    
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if assignment.canCheckIn {
                checkInButton
            } else if assignment.canCheckOut {
                checkOutButton
            } else if assignment.isCheckedOut {
                checkedOutView
            } else if assignment.checkInStatus == .noShow {
                noShowView
            } else {
                // Not today or already handled
                EmptyView()
            }
        }
    }
    
    private var checkInButton: some View {
        Button {
            Task {
                isLoading = true
                await onCheckIn()
                isLoading = false
            }
        } label: {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.circle")
                    Text("Check In")
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
        .disabled(isLoading)
    }
    
    private var checkOutButton: some View {
        Button {
            Task {
                isLoading = true
                await onCheckOut()
                isLoading = false
            }
        } label: {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.right.circle")
                    Text("Check Out")
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .buttonStyle(.borderedProminent)
        .tint(.blue)
        .disabled(isLoading)
    }
    
    private var checkedOutView: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.blue)
            Text("Checked Out")
                .foregroundStyle(.secondary)
        }
        .font(.headline)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var noShowView: some View {
        HStack {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
            Text("Marked No Show")
                .foregroundStyle(.secondary)
        }
        .font(.headline)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview("Can Check In") {
    CheckInButton(
        assignment: .preview,
        onCheckIn: {},
        onCheckOut: {}
    )
    .padding()
}

#Preview("Can Check Out") {
    CheckInButton(
        assignment: .previewCheckedIn,
        onCheckIn: {},
        onCheckOut: {}
    )
    .padding()
}