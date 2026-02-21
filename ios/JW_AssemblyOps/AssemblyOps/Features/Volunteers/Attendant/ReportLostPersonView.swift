//
//  ReportLostPersonView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/16/26.
//

// MARK: - Report Lost Person View
//
// Form for attendant volunteers to report a lost person.
// Grouped into themed cards: person details, last seen, contact info.
//

import SwiftUI

struct ReportLostPersonView: View {
    var posts: [AttendantPostItem] = []
    @StateObject private var viewModel = AttendantVolunteerViewModel()
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var hasAppeared = false

    // Form state
    @State private var personName = ""
    @State private var ageText = ""
    @State private var description = ""
    @State private var selectedPostId: String?
    @State private var customLocation = ""
    @State private var useCustomLocation = false
    @State private var lastSeenTime = Date()
    @State private var includeLastSeenTime = false
    @State private var contactName = ""
    @State private var contactPhone = ""
    @State private var didReport = false
    @State private var showError = false

    /// Resolved location string for the API
    private var resolvedLocation: String? {
        if useCustomLocation {
            let trimmed = customLocation.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        } else if let postId = selectedPostId, let post = posts.first(where: { $0.id == postId }) {
            return [post.name, post.location].compactMap { $0 }.joined(separator: " — ")
        }
        return nil
    }

    var isFormValid: Bool {
        !personName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !contactName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    personDetailsCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    lastSeenCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                    contactInfoCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.10)
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("attendant.lostPerson.create".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save".localized) {
                        Task {
                            guard let eventId = appState.currentVolunteer?.eventId else { return }
                            let ageValue: Int? = Int(ageText)
                            let loc = resolvedLocation
                            let time: String? = includeLastSeenTime ? ISO8601DateFormatter().string(from: lastSeenTime) : nil
                            let phone = contactPhone.isEmpty ? nil : contactPhone
                            await viewModel.reportLostPerson(
                                eventId: eventId, personName: personName, age: ageValue,
                                description: description, lastSeenLocation: loc,
                                lastSeenTime: time, contactName: contactName,
                                contactPhone: phone, sessionId: nil
                            )
                            didReport = true
                        }
                    }
                    .disabled(!isFormValid || viewModel.isSaving)
                }
            }
            .alert("attendant.lostPerson.report.success".localized, isPresented: $didReport) {
                Button("common.ok".localized) {
                    HapticManager.shared.success()
                    dismiss()
                }
            }
            .onChange(of: viewModel.error) { _, newValue in showError = newValue != nil }
            .alert("common.error".localized, isPresented: $showError) {
                Button("common.ok".localized) { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
        }
    }

    // MARK: - Person Details Card

    private var personDetailsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            SectionHeaderLabel(icon: "person.fill", title: "attendant.lostPerson.section.personDetails".localized)

            VStack(spacing: AppTheme.Spacing.m) {
                themedTextField("attendant.lostPerson.personName".localized, text: $personName, required: true)

                themedTextField("attendant.lostPerson.age".localized, text: $ageText, keyboardType: .numberPad)

                // Description (required)
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    HStack(spacing: 2) {
                        Text("attendant.lostPerson.description".localized)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        Text("*")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(.red)
                    }

                    ZStack(alignment: .topLeading) {
                        if description.isEmpty {
                            Text("attendant.lostPerson.description.placeholder".localized)
                                .font(AppTheme.Typography.body)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                                .padding(.horizontal, AppTheme.Spacing.xs)
                                .padding(.vertical, AppTheme.Spacing.s)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $description)
                            .scrollContentBackground(.hidden)
                            .font(AppTheme.Typography.body)
                            .frame(minHeight: 80)
                    }
                    .padding(AppTheme.Spacing.s)
                    .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Last Seen Card

    private var lastSeenCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            SectionHeaderLabel(icon: "mappin.and.ellipse", title: "attendant.lostPerson.section.lastSeen".localized)

            VStack(spacing: AppTheme.Spacing.m) {
                locationPicker

                Divider()

                // Last seen time
                VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                    Toggle("attendant.lostPerson.includeTime".localized, isOn: $includeLastSeenTime)
                        .font(AppTheme.Typography.subheadline)
                        .tint(AppTheme.themeColor)

                    if includeLastSeenTime {
                        DatePicker("", selection: $lastSeenTime, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .labelsHidden()
                    }
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Contact Info Card

    private var contactInfoCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            SectionHeaderLabel(icon: "phone.fill", title: "attendant.lostPerson.section.contactInfo".localized)

            VStack(spacing: AppTheme.Spacing.m) {
                themedTextField("attendant.lostPerson.contactName".localized, text: $contactName, required: true)

                themedTextField("attendant.lostPerson.contactPhone".localized, text: $contactPhone, keyboardType: .phonePad)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Location Picker

    @ViewBuilder
    private var locationPicker: some View {
        if posts.isEmpty {
            TextField("attendant.incidents.location.custom".localized, text: $customLocation)
                .font(AppTheme.Typography.body)
                .padding(AppTheme.Spacing.m)
                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
        } else {
            VStack(spacing: AppTheme.Spacing.s) {
                ForEach(posts) { post in
                    Button {
                        selectedPostId = selectedPostId == post.id ? nil : post.id
                        useCustomLocation = false
                        HapticManager.shared.lightTap()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(post.name)
                                    .font(AppTheme.Typography.subheadline)
                                    .foregroundStyle(.primary)
                                if let location = post.location {
                                    Text(location)
                                        .font(AppTheme.Typography.caption)
                                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                                }
                            }
                            Spacer()
                            if selectedPostId == post.id && !useCustomLocation {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.themeColor)
                            }
                        }
                        .padding(AppTheme.Spacing.m)
                        .background(
                            selectedPostId == post.id && !useCustomLocation
                                ? AppTheme.themeColor.opacity(0.1)
                                : AppTheme.cardBackgroundSecondary(for: colorScheme)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    useCustomLocation = true
                    selectedPostId = nil
                    HapticManager.shared.lightTap()
                } label: {
                    HStack {
                        Text("attendant.incidents.location.other".localized)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                        if useCustomLocation {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppTheme.themeColor)
                        }
                    }
                    .padding(AppTheme.Spacing.m)
                    .background(
                        useCustomLocation
                            ? AppTheme.themeColor.opacity(0.1)
                            : AppTheme.cardBackgroundSecondary(for: colorScheme)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                }
                .buttonStyle(.plain)

                if useCustomLocation {
                    TextField("attendant.incidents.location.custom".localized, text: $customLocation)
                        .font(AppTheme.Typography.body)
                        .padding(AppTheme.Spacing.m)
                        .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                }
            }
        }
    }

    // MARK: - Helper Views

    private func themedTextField(
        _ label: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        required: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack(spacing: 2) {
                Text(label)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                if required {
                    Text("*")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.red)
                }
            }
            TextField("", text: text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.words)
                .padding(AppTheme.Spacing.m)
                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
        }
    }
}

#Preview {
    ReportLostPersonView()
        .environmentObject(AppState.shared)
}
