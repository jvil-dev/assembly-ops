//
//  CaptainGroupView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/26/26.
//

// MARK: - Captain Group View
//
// Displays group members for a captain at a specific post/session.
// Allows captain to check in group members who don't have phones.
//
// Parameters:
//   - postId: The post ID for this captain assignment
//   - sessionId: The session ID for this captain assignment
//   - onCheckIn: Callback when a member is checked in
//
// Features:
//   - Lists all group members (excludes captain)
//   - Shows check-in status for each member
//   - Check-in button for members who haven't checked in
//   - Loading and error states
//
// Components:
//   - GroupMemberRow: Individual row with name, congregation, and check-in action
//
// Dependencies:
//   - CaptainGroupViewModel: Manages data fetching and check-in
//   - GroupMember: Model for group member data
//
// Used by: AssignmentDetailView (for captain assignments)

import SwiftUI

struct CaptainGroupView: View {
    let postId: String
    let sessionId: String
    let onCheckIn: () -> Void

    @StateObject private var viewModel = CaptainGroupViewModel()
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if viewModel.members.isEmpty {
                Text("No group members assigned")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            } else {
                ForEach(viewModel.members) { member in
                    GroupMemberRow(
                        member: member,
                        onCheckIn: {
                            Task {
                                await viewModel.checkInMember(assignmentId: member.assignmentId)
                                onCheckIn()
                            }
                        }
                    )
                }
            }
        }
        .task {
            await viewModel.loadGroup(postId: postId, sessionId: sessionId)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

// MARK: - Group Member Row

private struct GroupMemberRow: View {
    let member: GroupMember
    let onCheckIn: () -> Void

    @State private var isCheckingIn = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(member.fullName)
                    .font(AppTheme.Typography.subheadline)
                    .fontWeight(.medium)

                Text(member.congregation)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }

            Spacer()

            if member.isCheckedIn {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    if let time = member.checkInTime {
                        Text(time, style: .time)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                }
            } else if member.canCheckIn {
                Button(action: {
                    isCheckingIn = true
                    onCheckIn()
                }) {
                    if isCheckingIn {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Check In")
                            .font(AppTheme.Typography.captionBold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppTheme.themeColor)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                }
                .disabled(isCheckingIn)
            } else {
                Text(member.assignmentStatus.displayName)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    CaptainGroupView(
        postId: "post-1",
        sessionId: "session-1",
        onCheckIn: {}
    )
    .padding()
}
