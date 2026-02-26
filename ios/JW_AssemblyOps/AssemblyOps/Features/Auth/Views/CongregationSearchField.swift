//
//  CongregationSearchField.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/26/26.
//

// MARK: - Congregation Search Field
//
// Inline search component for the registration form.
// Shows a text field; when 3+ characters are typed, fetches results via
// searchCongregations query and displays them in a list below.
// Tapping a result sets the congregation name + id and collapses the list.
//
// Usage:
//   CongregationSearchField(
//       selectedName: $viewModel.congregationName,
//       selectedId: $viewModel.congregationId
//   )

import SwiftUI
import Combine
import Apollo

struct CongregationSearchField: View {
    @Binding var selectedName: String
    @Binding var selectedId: String?

    @Environment(\.colorScheme) var colorScheme
    @StateObject private var searcher = CongregationSearcher()
    @State private var query = ""
    @State private var showResults = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Input row
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: selectedId != nil ? "checkmark.circle.fill" : "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundStyle(selectedId != nil ? AppTheme.StatusColors.accepted : AppTheme.textTertiary(for: colorScheme))
                    .animation(AppTheme.quickAnimation, value: selectedId != nil)

                if selectedId != nil {
                    // Show confirmed selection
                    Text(selectedName)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(.primary)
                    Spacer()
                    Button {
                        clearSelection()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    }
                } else {
                    TextField("Search your congregation...", text: $query)
                        .font(AppTheme.Typography.body)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                        .onChange(of: query) { _, newValue in
                            handleQueryChange(newValue)
                        }
                    if searcher.isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
            }
            .padding(.vertical, AppTheme.Spacing.s)

            // Underline
            Rectangle()
                .fill(showResults ? AppTheme.themeColor : AppTheme.textTertiary(for: colorScheme).opacity(0.3))
                .frame(height: showResults ? 1.5 : 1)
                .animation(AppTheme.quickAnimation, value: showResults)

            // Results list
            if showResults && !searcher.results.isEmpty {
                VStack(spacing: 0) {
                    ForEach(searcher.results, id: \.id) { congregation in
                        Button {
                            select(congregation)
                        } label: {
                            HStack(spacing: AppTheme.Spacing.m) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(congregation.name)
                                        .font(AppTheme.Typography.body)
                                        .foregroundStyle(.primary)
                                    Text("\(congregation.city), \(congregation.state)")
                                        .font(AppTheme.Typography.caption)
                                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                                }
                                Spacer()
                            }
                            .padding(.vertical, AppTheme.Spacing.m)
                            .padding(.horizontal, AppTheme.Spacing.s)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if congregation.id != searcher.results.last?.id {
                            Divider()
                                .padding(.leading, AppTheme.Spacing.s)
                        }
                    }
                }
                .background(AppTheme.cardBackground(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                .padding(.top, AppTheme.Spacing.xs)
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else if showResults && query.count >= 3 && !searcher.isLoading && searcher.results.isEmpty {
                Text(searcher.hasSearchError
                     ? "common.searchFailed".localized
                     : "registration.congregation.noResults".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(searcher.hasSearchError
                                     ? AppTheme.StatusColors.declined
                                     : AppTheme.textTertiary(for: colorScheme))
                    .padding(.top, AppTheme.Spacing.s)
                    .transition(.opacity)
            }
        }
        .animation(AppTheme.quickAnimation, value: showResults)
        .animation(AppTheme.quickAnimation, value: searcher.results.count)
    }

    // MARK: - Helpers

    private func handleQueryChange(_ newValue: String) {
        selectedId = nil
        selectedName = newValue
        if newValue.count >= 3 {
            showResults = true
            searcher.search(query: newValue)
        } else {
            showResults = false
            searcher.cancel()
        }
    }

    private func select(_ congregation: AssemblyOpsAPI.SearchCongregationsQuery.Data.SearchCongregation) {
        selectedName = "\(congregation.name) - \(congregation.city)"
        selectedId = congregation.id
        showResults = false
        query = ""
        HapticManager.shared.lightTap()
    }

    private func clearSelection() {
        selectedName = ""
        selectedId = nil
        query = ""
        showResults = false
        HapticManager.shared.lightTap()
    }
}

// MARK: - Congregation Searcher

@MainActor
private final class CongregationSearcher: ObservableObject {
    @Published var results: [AssemblyOpsAPI.SearchCongregationsQuery.Data.SearchCongregation] = []
    @Published var isLoading = false
    @Published var hasSearchError = false

    private var cancellable: (any Apollo.Cancellable)?
    private var debounceTask: Task<Void, Never>?

    func search(query: String) {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
            guard !Task.isCancelled else { return }
            await performSearch(query: query)
        }
    }

    func cancel() {
        debounceTask?.cancel()
        cancellable?.cancel()
        results = []
        isLoading = false
        hasSearchError = false
    }

    private func performSearch(query: String) async {
        isLoading = true
        cancellable?.cancel()

        await withCheckedContinuation { continuation in
            cancellable = NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.SearchCongregationsQuery(query: query),
                cachePolicy: .fetchIgnoringCacheData
            ) { [weak self] result in
                Task { @MainActor in
                    self?.isLoading = false
                    if case .success(let graphQLResult) = result,
                       let data = graphQLResult.data?.searchCongregations {
                        self?.results = data
                        self?.hasSearchError = false
                    } else {
                        self?.results = []
                        if case .failure = result { self?.hasSearchError = true }
                    }
                    continuation.resume()
                }
            }
        }
    }
}
