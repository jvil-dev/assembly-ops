//
//  JoinEventView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/31/26.
//

// MARK: - Join Event View
//
// Allows Department Overseers to join an event using a join code.
// After joining, optionally claim a department.
//
// Flow:
//   1. Enter join code -> tap Join
//   2. On success: shows event info + available departments
//   3. Select department -> claim it
//   4. Proceed to dashboard
//

import SwiftUI

struct JoinEventView: View {
    @ObservedObject var viewModel: EventSetupViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                if viewModel.joinedEvent != nil {
                    // Post-join: show event info + department claiming
                    joinedContent
                } else {
                    // Pre-join: code entry
                    joinCodeContent
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle("Join Event")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Join Code Content

    private var joinCodeContent: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            // Icon
            VStack(spacing: AppTheme.Spacing.m) {
                Image(systemName: "person.badge.key.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AppTheme.StatusColors.info)

                Text("Enter Join Code")
                    .font(AppTheme.Typography.title)
                    .fontWeight(.bold)

                Text("Get this code from the Event Overseer to join their event.")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
            }
            .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
            .padding(.vertical, AppTheme.Spacing.l)

            // Code input
            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                HStack(spacing: 8) {
                    Image(systemName: "key.fill")
                        .foregroundStyle(AppTheme.themeColor)
                    Text("Join Code")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }

                TextField("", text: $viewModel.joinCode)
                    .font(.system(.title3, design: .monospaced))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding(AppTheme.Spacing.l)
                    .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                    .multilineTextAlignment(.center)
            }
            .cardPadding()
            .themedCard(scheme: colorScheme)
            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

            // Error message
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            // Join button
            Button {
                viewModel.joinEvent()
            } label: {
                HStack(spacing: AppTheme.Spacing.s) {
                    if viewModel.isJoining {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Join Event")
                            .font(AppTheme.Typography.headline)
                        Image(systemName: "arrow.right")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.l)
                .background(!viewModel.joinCode.trimmingCharacters(in: .whitespaces).isEmpty
                    ? AppTheme.themeColor
                    : AppTheme.themeColor.opacity(0.4))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
            }
            .disabled(viewModel.joinCode.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isJoining)
            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)
        }
    }

    // MARK: - Joined Content

    private var joinedContent: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            // Success header
            VStack(spacing: AppTheme.Spacing.m) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AppTheme.StatusColors.accepted)

                Text("Event Joined!")
                    .font(AppTheme.Typography.title)
                    .fontWeight(.bold)
            }
            .padding(.vertical, AppTheme.Spacing.l)

            // Event info card
            if let event = viewModel.joinedEvent {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.circle.fill")
                            .foregroundStyle(AppTheme.themeColor)
                        Text("Event Details")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    }

                    Text(event.eventName)
                        .font(AppTheme.Typography.headline)
                        .fontWeight(.semibold)

                    Label(event.venue, systemImage: "mappin")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                    HStack {
                        Text("Role")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        Spacer()
                        Text(formatRole(event.role))
                            .font(AppTheme.Typography.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(AppTheme.themeColor)
                            .padding(.horizontal, AppTheme.Spacing.s)
                            .padding(.vertical, 4)
                            .background(AppTheme.themeColor.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                .cardPadding()
                .themedCard(scheme: colorScheme)
            }

            // Department claiming section
            if !viewModel.availableDepartments.isEmpty {
                departmentClaimSection
            }

            // Skip / Go to dashboard
            Button {
                viewModel.completeSetup()
            } label: {
                Text(viewModel.availableDepartments.isEmpty ? "Go to Dashboard" : "Skip for Now")
                    .font(AppTheme.Typography.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.l)
                    .background(viewModel.availableDepartments.isEmpty
                        ? AppTheme.themeColor
                        : AppTheme.cardBackgroundSecondary(for: colorScheme))
                    .foregroundStyle(viewModel.availableDepartments.isEmpty
                        ? .white
                        : AppTheme.textSecondary(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
            }
        }
    }

    // MARK: - Department Claim Section

    private var departmentClaimSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: 8) {
                Image(systemName: "square.grid.2x2.fill")
                    .foregroundStyle(AppTheme.themeColor)
                Text("Claim Your Department")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            Text("Select the department you'll be overseeing:")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

            if viewModel.isLoadingDepartments {
                ProgressView()
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.m) {
                    ForEach(viewModel.availableDepartments, id: \.self) { deptType in
                        departmentButton(deptType)
                    }
                }
            }

            // Error
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.red)
            }

            // Claim button
            if let selected = viewModel.selectedDepartmentType,
               let eventId = viewModel.joinedEvent?.eventId {
                Button {
                    viewModel.claimDepartment(eventId: eventId, departmentType: selected)
                } label: {
                    HStack(spacing: AppTheme.Spacing.s) {
                        if viewModel.isClaiming {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Claim \(formatDepartment(selected))")
                                .font(AppTheme.Typography.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.l)
                    .background(AppTheme.themeColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
                }
                .disabled(viewModel.isClaiming)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Department Button

    private func departmentButton(_ deptType: String) -> some View {
        Button {
            viewModel.selectedDepartmentType = deptType
            HapticManager.shared.lightTap()
        } label: {
            VStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: departmentIcon(deptType))
                    .font(.title3)
                    .foregroundStyle(viewModel.selectedDepartmentType == deptType
                        ? AppTheme.themeColor
                        : AppTheme.textSecondary(for: colorScheme))

                Text(formatDepartment(deptType))
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(viewModel.selectedDepartmentType == deptType
                        ? (colorScheme == .dark ? .white : .primary)
                        : AppTheme.textSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(AppTheme.Spacing.m)
            .background(viewModel.selectedDepartmentType == deptType
                ? AppTheme.themeColor.opacity(0.1)
                : AppTheme.cardBackgroundSecondary(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .stroke(viewModel.selectedDepartmentType == deptType
                        ? AppTheme.themeColor
                        : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func formatRole(_ role: String) -> String {
        switch role {
        case "APP_ADMIN": return "App Administrator"
        case "EVENT_OVERSEER": return "App Administrator"  // Legacy fallback
        case "DEPARTMENT_OVERSEER": return "Department Overseer"
        default: return role
        }
    }

    private func formatDepartment(_ type: String) -> String {
        switch type {
        case "ACCOUNTS": return "Accounts"
        case "ATTENDANT": return "Attendant"
        case "AUDIO_VIDEO": return "Audio/Video"
        case "BAPTISM": return "Baptism"
        case "CLEANING": return "Cleaning"
        case "FIRST_AID": return "First Aid"
        case "INFORMATION_VOLUNTEER_SERVICE": return "Information"
        case "INSTALLATION": return "Installation"
        case "LOST_FOUND_CHECKROOM": return "Lost & Found"
        case "PARKING": return "Parking"
        case "ROOMING": return "Rooming"
        case "TRUCKING_EQUIPMENT": return "Trucking"
        default: return type
        }
    }

    private func departmentIcon(_ type: String) -> String {
        switch type {
        case "ACCOUNTS": return "dollarsign.circle"
        case "ATTENDANT": return "person.2"
        case "AUDIO_VIDEO": return "speaker.wave.2"
        case "BAPTISM": return "drop"
        case "CLEANING": return "sparkles"
        case "FIRST_AID": return "cross.case"
        case "INFORMATION_VOLUNTEER_SERVICE": return "info.circle"
        case "INSTALLATION": return "hammer"
        case "LOST_FOUND_CHECKROOM": return "questionmark.folder"
        case "PARKING": return "car"
        case "ROOMING": return "bed.double"
        case "TRUCKING_EQUIPMENT": return "truck.box"
        default: return "square.grid.2x2"
        }
    }
}

// MARK: - Previews

#Preview("Join Code Entry") {
    NavigationStack {
        JoinEventView(viewModel: EventSetupViewModel())
    }
}

#Preview("Event Joined") {
    NavigationStack {
        JoinEventView(viewModel: {
            let vm = EventSetupViewModel()
            vm.joinedEvent = JoinedEventInfo(
                eventAdminId: "ea-1",
                role: "DEPARTMENT_OVERSEER",
                eventId: "evt-1",
                eventName: "Circuit Assembly with CO Visit",
                venue: "Assembly Hall of Jehovah's Witnesses"
            )
            vm.availableDepartments = ["ATTENDANT", "PARKING", "CLEANING", "FIRST_AID", "AUDIO_VIDEO", "ACCOUNTS"]
            return vm
        }())
    }
}

#Preview("Dark") {
    NavigationStack {
        JoinEventView(viewModel: {
            let vm = EventSetupViewModel()
            vm.joinCode = "XYZ789"
            return vm
        }())
    }
    .preferredColorScheme(.dark)
}
