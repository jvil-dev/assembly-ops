//
//  CopyAssignmentsSheet.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/16/26.
//

// MARK: - Copy Assignments Sheet
//
// Multi-step sheet for copying assignments from one session to another.
// Steps: Select Target → Select Areas → Options → Results
//
// Presented from SessionDetailView toolbar menu (attendant dept only).
//
// Used by: SessionDetailView (via SessionSheetsModifier)

import SwiftUI

struct CopyAssignmentsSheet: View {
    @StateObject private var viewModel: CopyAssignmentsViewModel
    @ObservedObject var coverageVM: CoverageMatrixViewModel
    @ObservedObject var areaVM: AreaManagementViewModel
    let departmentId: String
    let deptColor: Color

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var step: CopyStep = .selectTarget
    @State private var showSkipped = false

    enum CopyStep {
        case selectTarget
        case selectAreas
        case options
        case result
    }

    init(
        sourceSession: EventSessionItem,
        coverageVM: CoverageMatrixViewModel,
        areaVM: AreaManagementViewModel,
        departmentId: String,
        deptColor: Color
    ) {
        _viewModel = StateObject(wrappedValue: CopyAssignmentsViewModel(sourceSession: sourceSession))
        self.coverageVM = coverageVM
        self.areaVM = areaVM
        self.departmentId = departmentId
        self.deptColor = deptColor
    }

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .selectTarget:
                    targetSessionStep
                case .selectAreas:
                    selectAreasStep
                case .options:
                    optionsStep
                case .result:
                    resultStep
                }
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(step == .result ? "copy.done".localized : "Cancel") {
                        dismiss()
                    }
                }
                if step != .result {
                    ToolbarItem(placement: .confirmationAction) {
                        nextButton
                    }
                }
            }
            .onAppear {
                viewModel.loadSessions(from: coverageVM)
                viewModel.loadAreas(from: areaVM)
            }
        }
    }

    private var navigationTitle: String {
        switch step {
        case .selectTarget: return "copy.selectTarget".localized
        case .selectAreas: return "copy.selectAreas".localized
        case .options: return "copy.options".localized
        case .result: return "copy.title".localized
        }
    }

    @ViewBuilder
    private var nextButton: some View {
        switch step {
        case .selectTarget:
            Button("Next") {
                withAnimation { step = .selectAreas }
            }
            .disabled(viewModel.targetSession == nil)
        case .selectAreas:
            Button("Next") {
                withAnimation { step = .options }
            }
            .disabled(viewModel.selectedAreaIds.isEmpty)
        case .options, .result:
            EmptyView()
        }
    }

    // MARK: - Step 1: Select Target Session

    private var targetSessionStep: some View {
        List {
            Section {
                Text(String(format: NSLocalizedString("copy.sourceLabel", comment: ""), viewModel.sourceSession.name))
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            Section(header: Text("copy.targetHeader".localized).textCase(nil)) {
                if viewModel.availableSessions.isEmpty {
                    Text("copy.noSessions".localized)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                } else {
                    ForEach(viewModel.availableSessions) { session in
                        Button {
                            viewModel.targetSession = session
                            HapticManager.shared.lightTap()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(session.name)
                                        .font(AppTheme.Typography.bodyMedium)
                                        .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                                    Text(DateUtils.formatSessionDateFull(session.date))
                                        .font(AppTheme.Typography.caption)
                                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                                }
                                Spacer()
                                if viewModel.targetSession?.id == session.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(deptColor)
                                }
                            }
                        }
                        .listRowBackground(AppTheme.cardBackground(for: colorScheme))
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    // MARK: - Step 2: Select Areas

    private var selectAreasStep: some View {
        List {
            Section {
                Toggle(isOn: Binding(
                    get: { viewModel.selectAll },
                    set: { _ in viewModel.toggleSelectAll() }
                )) {
                    Label("copy.selectAll".localized, systemImage: "checkmark.circle")
                        .font(AppTheme.Typography.bodyMedium)
                }
                .tint(deptColor)
                .listRowBackground(AppTheme.cardBackground(for: colorScheme))
            }

            Section(header:
                HStack {
                    Text("copy.areasHeader".localized).textCase(nil)
                    Spacer()
                    let count = viewModel.sourceAssignmentCount(from: coverageVM)
                    Text("\(count) " + "copy.assignments".localized)
                        .font(AppTheme.Typography.captionSmall)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }
            ) {
                if viewModel.areas.isEmpty {
                    Text("copy.noAreas".localized)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                } else {
                    ForEach(viewModel.areas) { area in
                        areaRow(area)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    private func areaRow(_ area: AreaItem) -> some View {
        let isSelected = viewModel.selectedAreaIds.contains(area.id)
        let postCount = area.posts.count
        let assignmentCount = coverageVM.slots
            .filter { $0.sessionId == viewModel.sourceSession.id }
            .filter { slot in area.posts.contains { $0.id == slot.postId } }
            .reduce(0) { $0 + $1.assignments.count }

        return Button {
            viewModel.toggleArea(area.id)
            HapticManager.shared.lightTap()
        } label: {
            HStack(spacing: AppTheme.Spacing.m) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? deptColor : AppTheme.textTertiary(for: colorScheme))
                    .font(.system(size: 20))

                VStack(alignment: .leading, spacing: 2) {
                    Text(area.name)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundStyle(AppTheme.textPrimary(for: colorScheme))

                    HStack(spacing: AppTheme.Spacing.s) {
                        Label("\(postCount)", systemImage: "mappin")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

                        Label("\(assignmentCount)", systemImage: "person.2")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    }
                }

                Spacer()

                if let category = area.category {
                    Text(category)
                        .font(AppTheme.Typography.captionSmall)
                        .foregroundStyle(deptColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(deptColor.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
        .listRowBackground(AppTheme.cardBackground(for: colorScheme))
    }

    // MARK: - Step 3: Options

    private var optionsStep: some View {
        List {
            // Summary
            Section {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                    Label(viewModel.sourceSession.name + " → " + (viewModel.targetSession?.name ?? ""),
                          systemImage: "doc.on.doc")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundStyle(AppTheme.textPrimary(for: colorScheme))

                    let count = viewModel.sourceAssignmentCount(from: coverageVM)
                    Text(String(format: NSLocalizedString("copy.summaryCount", comment: ""), count, viewModel.selectedAreaIds.count))
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
                .listRowBackground(AppTheme.cardBackground(for: colorScheme))
            }

            // Toggles
            Section(header: Text("copy.options".localized).textCase(nil)) {
                Toggle(isOn: $viewModel.forceAssign) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("copy.forceAssign".localized)
                            .font(AppTheme.Typography.body)
                        Text("copy.forceAssignWarning".localized)
                            .font(AppTheme.Typography.captionSmall)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    }
                }
                .tint(deptColor)
                .listRowBackground(AppTheme.cardBackground(for: colorScheme))

                Toggle("copy.countFlag".localized, isOn: $viewModel.copyCanCount)
                    .font(AppTheme.Typography.body)
                    .tint(deptColor)
                    .listRowBackground(AppTheme.cardBackground(for: colorScheme))

                Toggle("copy.captainFlag".localized, isOn: $viewModel.copyIsCaptain)
                    .font(AppTheme.Typography.body)
                    .tint(deptColor)
                    .listRowBackground(AppTheme.cardBackground(for: colorScheme))

                Toggle("copy.areaCaptains".localized, isOn: $viewModel.copyAreaCaptains)
                    .font(AppTheme.Typography.body)
                    .tint(deptColor)
                    .listRowBackground(AppTheme.cardBackground(for: colorScheme))
            }

            // Execute button
            Section {
                Button {
                    Task {
                        await viewModel.executeCopy(departmentId: departmentId)
                        if viewModel.result != nil {
                            withAnimation { step = .result }
                        }
                    }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            let count = viewModel.sourceAssignmentCount(from: coverageVM)
                            Text(String(format: NSLocalizedString("copy.execute", comment: ""), count))
                                .font(AppTheme.Typography.headline)
                        }
                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .frame(height: AppTheme.ButtonHeight.large)
                    .background(viewModel.canExecute ? deptColor : deptColor.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
                }
                .disabled(!viewModel.canExecute)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(
                    top: AppTheme.Spacing.l,
                    leading: AppTheme.Spacing.screenEdge,
                    bottom: AppTheme.Spacing.l,
                    trailing: AppTheme.Spacing.screenEdge
                ))
            }

            // Error
            if let error = viewModel.error {
                Section {
                    Text(error)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.StatusColors.declined)
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    // MARK: - Step 4: Results

    private var resultStep: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Success card
                if let result = viewModel.result {
                    VStack(spacing: AppTheme.Spacing.l) {
                        Image(systemName: result.copiedCount > 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(result.copiedCount > 0 ? deptColor : AppTheme.StatusColors.warning)

                        Text(String(format: NSLocalizedString("copy.result.copied", comment: ""), result.copiedCount))
                            .font(AppTheme.Typography.title)
                            .foregroundStyle(AppTheme.textPrimary(for: colorScheme))

                        if result.copiedAreaCaptains > 0 {
                            Text(String(format: NSLocalizedString("copy.result.areaCaptains", comment: ""), result.copiedAreaCaptains))
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        }

                        if result.hasSkipped {
                            Text(String(format: NSLocalizedString("copy.result.skipped", comment: ""), result.skippedCount))
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(AppTheme.StatusColors.warning)
                        }
                    }
                    .cardPadding()
                    .frame(maxWidth: .infinity)
                    .themedCard(scheme: colorScheme)

                    // Skipped details
                    if result.hasSkipped {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                            Button {
                                withAnimation(AppTheme.quickAnimation) {
                                    showSkipped.toggle()
                                }
                            } label: {
                                HStack {
                                    Text("copy.result.skippedDetails".localized)
                                        .font(AppTheme.Typography.captionBold)
                                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                                        .rotationEffect(.degrees(showSkipped ? 90 : 0))
                                }
                            }

                            if showSkipped {
                                ForEach(result.skippedVolunteers) { volunteer in
                                    HStack(spacing: AppTheme.Spacing.s) {
                                        Image(systemName: "person.crop.circle.badge.xmark")
                                            .font(.system(size: 14))
                                            .foregroundStyle(AppTheme.StatusColors.warning)

                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(volunteer.volunteerName)
                                                .font(AppTheme.Typography.captionBold)
                                                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                                            Text(volunteer.postName + " — " + volunteer.reason)
                                                .font(AppTheme.Typography.captionSmall)
                                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                                        }
                                    }
                                }
                            }
                        }
                        .cardPadding()
                        .themedCard(scheme: colorScheme)
                    }
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.xl)
        }
    }
}
