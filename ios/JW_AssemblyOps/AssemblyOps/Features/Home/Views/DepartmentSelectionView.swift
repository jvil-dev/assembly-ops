//
//  DepartmentSelectionView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/26/26.
//

// MARK: - Department Selection View
//
// Grid of 12 departments for an event. Shows which are available vs already claimed.
// Tap an available department → confirm → purchaseDepartment mutation.
// Success → navigates to AccessCodeDisplayView.
//

import SwiftUI

struct DepartmentSelectionView: View {
    let event: DiscoverableEvent
    @StateObject private var viewModel = DepartmentBrowseViewModel()
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.popToRoot) var popToRoot
    @State private var hasAppeared = false
    @State private var selectedType: DepartmentTypeInfo?
    @State private var showConfirm = false
    @State private var showError = false

    // All 14 department types
    private let departmentTypes: [DepartmentTypeInfo] = [
        .init(type: "ACCOUNTS", name: "Accounts", icon: "dollarsign.circle"),
        .init(type: "ATTENDANT", name: "Attendant", icon: "person.badge.shield.checkmark"),
        .init(type: "AUDIO", name: "Audio", icon: "speaker.wave.3"),
        .init(type: "VIDEO", name: "Video", icon: "video"),
        .init(type: "STAGE", name: "Stage", icon: "light.overhead.left"),
        .init(type: "BAPTISM", name: "Baptism", icon: "drop.circle"),
        .init(type: "CLEANING", name: "Cleaning", icon: "sparkles"),
        .init(type: "FIRST_AID", name: "First Aid", icon: "cross.case"),
        .init(type: "INFORMATION_VOLUNTEER_SERVICE", name: "Information", icon: "info.circle"),
        .init(type: "INSTALLATION", name: "Installation", icon: "wrench.and.screwdriver"),
        .init(type: "LOST_FOUND_CHECKROOM", name: "Lost & Found", icon: "magnifyingglass.circle"),
        .init(type: "PARKING", name: "Parking", icon: "car.circle"),
        .init(type: "ROOMING", name: "Rooming", icon: "bed.double"),
        .init(type: "TRUCKING_EQUIPMENT", name: "Trucking", icon: "truck.box"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Event header
                eventHeader
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                // Department grid
                Text("departmentSelection.chooseTitle".localized)
                    .font(AppTheme.Typography.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                LazyVGrid(columns: [.init(.flexible()), .init(.flexible()), .init(.flexible())], spacing: AppTheme.Spacing.m) {
                    ForEach(Array(departmentTypes.enumerated()), id: \.element.type) { index, dept in
                        departmentCell(dept)
                            .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.03 + 0.1)
                    }
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle(event.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $viewModel.purchasedDepartment) { result in
            NavigationStack {
                AccessCodeDisplayView(
                    departmentName: result.name,
                    accessCode: result.accessCode,
                    eventName: event.name,
                    onDone: {
                        viewModel.purchasedDepartment = nil
                        popToRoot()
                    }
                )
            }
        }
        .confirmationDialog(
            "departmentSelection.confirm.title".localized,
            isPresented: $showConfirm,
            titleVisibility: .visible
        ) {
            Button("departmentSelection.confirm.purchase".localized) {
                if let dept = selectedType {
                    viewModel.purchaseDepartment(eventId: event.id, departmentType: dept.type)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let dept = selectedType {
                Text(String(format: "departmentSelection.confirm.message".localized, dept.name, event.name))
            }
        }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) { hasAppeared = true }
        }
        .onChange(of: viewModel.errorMessage) { _, error in
            showError = error != nil
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .overlay {
            if viewModel.isPurchasing {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView("departmentSelection.purchasing".localized)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
            }
        }
    }

    // MARK: - Event Header

    private var eventHeader: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            Text(event.displayEventType.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(AppTheme.themeColor)

            Text(event.name)
                .font(AppTheme.Typography.title)
                .foregroundStyle(.primary)

            HStack(spacing: AppTheme.Spacing.m) {
                Label(event.venue, systemImage: "mappin")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Department Cell

    private func departmentCell(_ dept: DepartmentTypeInfo) -> some View {
        let color = DepartmentColor.color(for: dept.type)

        return Button {
            HapticManager.shared.lightTap()
            selectedType = dept
            showConfirm = true
        } label: {
            VStack(spacing: AppTheme.Spacing.s) {
                ZStack {
                    Circle()
                        .fill(color.opacity(colorScheme == .dark ? 0.2 : 0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: dept.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(color)
                }

                Text(dept.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.m)
            .background(AppTheme.cardBackground(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Department Type Info

struct DepartmentTypeInfo: Hashable {
    let type: String
    let name: String
    let icon: String
}

#Preview {
    NavigationStack {
        DepartmentSelectionView(
            event: DiscoverableEvent(
                id: "e1", name: "2026 Circuit Assembly",
                eventType: "CIRCUIT_ASSEMBLY",
                circuit: "CA-5", state: "CA",
                venue: "Assembly Hall", address: "123 Main St",
                startDate: "2026-03-15", endDate: "2026-03-16",
                theme: nil, isPublic: true, volunteerCount: 30
            )
        )
    }
    .environmentObject(AppState.shared)
}
