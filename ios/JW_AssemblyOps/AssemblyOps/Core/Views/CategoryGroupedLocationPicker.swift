//
//  CategoryGroupedLocationPicker.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/23/26.
//

import SwiftUI

struct CategoryGroupedLocationPicker: View {
    let posts: [AttendantPostItem]
    @Binding var selectedPostId: String?
    @Binding var useCustomLocation: Bool
    @Binding var customLocation: String

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        if posts.isEmpty {
            customLocationField
        } else {
            VStack(spacing: AppTheme.Spacing.s) {
                groupedPostRows
                otherLocationButton
                if useCustomLocation {
                    customLocationField
                }
            }
        }
    }

    // MARK: - Grouped Posts

    @ViewBuilder
    private var groupedPostRows: some View {
        let grouped = Dictionary(grouping: posts) { post in
            AttendantMainCategory.mainCategory(from: post.category ?? "")
        }

        // Render I → E → S sections
        ForEach(AttendantMainCategory.allCases) { category in
            if let categoryPosts = grouped[category], !categoryPosts.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(category.rawValue)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        .padding(.leading, AppTheme.Spacing.xs)
                        .padding(.top, AppTheme.Spacing.xs)

                    ForEach(categoryPosts) { post in
                        postRow(post)
                    }
                }
            }
        }

        // Ungrouped posts (nil category)
        if let ungrouped = grouped[nil], !ungrouped.isEmpty {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("attendant.location.category.other".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    .padding(.leading, AppTheme.Spacing.xs)
                    .padding(.top, AppTheme.Spacing.xs)

                ForEach(ungrouped) { post in
                    postRow(post)
                }
            }
        }
    }

    // MARK: - Post Row

    private func postRow(_ post: AttendantPostItem) -> some View {
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

    // MARK: - Other Location

    private var otherLocationButton: some View {
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
    }

    // MARK: - Custom Location Field

    private var customLocationField: some View {
        TextField("attendant.incidents.location.custom".localized, text: $customLocation)
            .font(AppTheme.Typography.body)
            .padding(AppTheme.Spacing.m)
            .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
    }
}
