//
//  VideoEquipmentDetailView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Video Equipment Detail View
//
// Shows full detail for a single video equipment item.
// Displays info, current checkout, checkout history, and damage reports.
// Supports checkout/return and reporting damage.

import SwiftUI

struct VideoEquipmentDetailView: View {
    let equipmentId: String

    @ObservedObject private var sessionState = EventSessionState.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var hasAppeared = false
    @State private var isLoading = true
    @State private var itemData: AssemblyOpsAPI.AVEquipmentItemQuery.Data.AvEquipmentItem?
    @State private var showCheckoutSheet = false
    @State private var showReportDamage = false
    @State private var error: String?
    @State private var showError = false

    private let accentColor = DepartmentColor.color(for: "VIDEO")

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .themedBackground(scheme: colorScheme)
            } else if let item = itemData {
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.xl) {
                        infoCard(item)
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                        actionsCard(item)
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                        if !item.checkoutHistory.isEmpty {
                            checkoutHistoryCard(item.checkoutHistory)
                                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.10)
                        }

                        if !item.damageReports.isEmpty {
                            damageReportsCard(item.damageReports)
                                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)
                        }
                    }
                    .screenPadding()
                    .padding(.top, AppTheme.Spacing.l)
                    .padding(.bottom, AppTheme.Spacing.xxl)
                }
                .themedBackground(scheme: colorScheme)
            } else {
                ContentUnavailableView("av.equipment.notFound".localized, systemImage: "video.slash")
                    .themedBackground(scheme: colorScheme)
            }
        }
        .navigationTitle("av.equipment.detail".localized)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCheckoutSheet) {
            CheckoutEquipmentSheet(equipmentId: equipmentId, equipmentName: itemData?.name ?? "") {
                await loadItem()
            }
        }
        .sheet(isPresented: $showReportDamage) {
            ReportVideoDamageView(equipmentId: equipmentId, equipmentName: itemData?.name ?? "")
        }
        .onChange(of: error) { _, err in
            showError = err != nil
        }
        .alert("common.error".localized, isPresented: $showError) {
            Button("common.ok".localized) { error = nil }
        } message: {
            Text(error ?? "")
        }
        .task { await loadItem() }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
    }

    private func loadItem() async {
        isLoading = true
        do {
            itemData = try await AudioVideoService.shared.fetchEquipmentItem(id: equipmentId)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Info Card

    private func infoCard(_ item: AssemblyOpsAPI.AVEquipmentItemQuery.Data.AvEquipmentItem) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "info.circle")
                    .foregroundStyle(accentColor)
                Text("av.equipment.info".localized.uppercased())
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            Text(item.name)
                .font(AppTheme.Typography.title)
                .foregroundStyle(.primary)

            LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], alignment: .leading, spacing: AppTheme.Spacing.m) {
                detailField("av.equipment.category".localized, value: item.category.rawValue)
                detailField("av.equipment.condition".localized, value: item.condition.rawValue)
                if let model = item.model {
                    detailField("av.equipment.model".localized, value: model)
                }
                if let serial = item.serialNumber {
                    detailField("av.equipment.serial".localized, value: serial)
                }
                if let location = item.location {
                    detailField("av.equipment.location".localized, value: location)
                }
                if let area = item.area {
                    detailField("av.equipment.area".localized, value: area.name)
                }
            }

            if let notes = item.notes, !notes.isEmpty {
                Text(notes)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Actions Card

    private func actionsCard(_ item: AssemblyOpsAPI.AVEquipmentItemQuery.Data.AvEquipmentItem) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(accentColor)
                Text("av.equipment.actions".localized.uppercased())
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            if item.currentCheckout != nil {
                Button {
                    Task {
                        if let checkoutId = item.currentCheckout?.id {
                            do {
                                try await AudioVideoService.shared.returnEquipment(checkoutId: checkoutId)
                                HapticManager.shared.success()
                                await loadItem()
                            } catch {
                                self.error = error.localizedDescription
                                HapticManager.shared.error()
                            }
                        }
                    }
                } label: {
                    actionRow(icon: "arrow.uturn.backward", title: "av.equipment.return".localized, color: .green)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    showCheckoutSheet = true
                    HapticManager.shared.lightTap()
                } label: {
                    actionRow(icon: "arrow.right.circle", title: "av.equipment.checkout".localized, color: accentColor)
                }
                .buttonStyle(.plain)
            }

            Button {
                showReportDamage = true
                HapticManager.shared.lightTap()
            } label: {
                actionRow(icon: "exclamationmark.triangle", title: "av.equipment.reportDamage".localized, color: .orange)
            }
            .buttonStyle(.plain)
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Checkout History

    private func checkoutHistoryCard(_ history: [AssemblyOpsAPI.AVEquipmentItemQuery.Data.AvEquipmentItem.CheckoutHistory]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(accentColor)
                Text("av.equipment.checkoutHistory".localized.uppercased())
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            ForEach(history, id: \.id) { entry in
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        let user = entry.checkedOutBy.user
                        Text("\(user.firstName) \(user.lastName)")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(.primary)
                        Text(DateUtils.parseISO8601(entry.checkedOutAt)?.formatted(date: .abbreviated, time: .shortened) ?? "")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    }
                    Spacer()
                    if entry.checkedInAt != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Text("av.equipment.active".localized)
                            .font(AppTheme.Typography.captionSmall).fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.StatusColors.pendingBackground)
                            .foregroundStyle(AppTheme.StatusColors.pending)
                            .clipShape(Capsule())
                    }
                }
                .padding(.vertical, AppTheme.Spacing.xs)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Damage Reports

    private func damageReportsCard(_ reports: [AssemblyOpsAPI.AVEquipmentItemQuery.Data.AvEquipmentItem.DamageReport]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                Text("av.equipment.damageHistory".localized.uppercased())
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            ForEach(reports, id: \.id) { report in
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    HStack {
                        Text(report.description)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                        Spacer()
                        if let sev = AudioDamageSeverityItem(rawValue: report.severity.rawValue) {
                            Text(sev.displayName)
                                .font(AppTheme.Typography.captionSmall).fontWeight(.medium)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(sev.color.opacity(0.12))
                                .foregroundStyle(sev.color)
                                .clipShape(Capsule())
                        }
                    }
                    HStack {
                        Text(DateUtils.parseISO8601(report.createdAt)?.formatted(date: .abbreviated, time: .omitted) ?? "")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        if report.resolved {
                            Text("av.damage.resolved".localized)
                                .font(AppTheme.Typography.captionSmall).fontWeight(.medium)
                                .foregroundStyle(.green)
                        }
                    }
                }
                .padding(.vertical, AppTheme.Spacing.xs)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Helpers

    private func detailField(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(AppTheme.Typography.captionSmall)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            Text(value)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(.primary)
        }
    }

    private func actionRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: AppTheme.Spacing.m) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(title)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
        }
        .padding(AppTheme.Spacing.m)
        .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
    }
}

#Preview {
    NavigationStack {
        VideoEquipmentDetailView(equipmentId: "preview-id")
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        VideoEquipmentDetailView(equipmentId: "preview-id")
    }
    .preferredColorScheme(.dark)
}
