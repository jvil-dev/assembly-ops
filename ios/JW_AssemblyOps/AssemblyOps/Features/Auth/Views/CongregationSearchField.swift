//
//  CongregationSearchField.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/26/26.
//

// MARK: - Congregation Search Field
//
// Inline search component inspired by jw.org congregation search.
// Shows a text field with placeholder "Enter a name"; when 3+ characters
// are typed, fetches results via searchCongregations query and displays
// them in a dropdown below with the matching text highlighted in gold.
//
// Features:
//   - "Enter search text to find results." hint when field is empty
//   - Matching portion highlighted in gold
//   - X clear button when typing
//   - 300ms debounce on search
//   - Confirmed selection shows checkmark + name with clear option
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
    @FocusState private var isFocused: Bool
    @StateObject private var searcher = CongregationSearcher()
    @State private var query = ""
    @State private var showResults = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if selectedId != nil {
                confirmedRow
            } else {
                searchRow
            }

            // Underline
            Rectangle()
                .fill(isFocused || showResults
                      ? AppTheme.themeColor
                      : AppTheme.textTertiary(for: colorScheme).opacity(0.3))
                .frame(height: isFocused || showResults ? 1.5 : 1)
                .animation(AppTheme.quickAnimation, value: isFocused)

            // Hint / Results / No results
            if selectedId == nil {
                if showResults && !searcher.results.isEmpty {
                    resultsDropdown
                } else if showResults && query.count >= 3 && !searcher.isLoading && searcher.results.isEmpty {
                    Text(searcher.hasSearchError
                         ? "common.searchFailed".localized
                         : "registration.congregation.noResults".localized)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(searcher.hasSearchError
                                         ? AppTheme.StatusColors.declined
                                         : AppTheme.textTertiary(for: colorScheme))
                        .padding(.vertical, AppTheme.Spacing.m)
                        .transition(.opacity)
                } else if query.isEmpty {
                    Text("registration.congregation.searchHint".localized)
                        .font(AppTheme.Typography.caption)
                        .italic()
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        .padding(.vertical, AppTheme.Spacing.m)
                        .transition(.opacity)
                }
            }
        }
        .animation(AppTheme.quickAnimation, value: showResults)
        .animation(AppTheme.quickAnimation, value: searcher.results.count)
        .animation(AppTheme.quickAnimation, value: selectedId != nil)
    }

    // MARK: - Confirmed Selection Row

    private var confirmedRow: some View {
        HStack(spacing: AppTheme.Spacing.s) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.StatusColors.accepted)

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
        }
        .padding(.vertical, AppTheme.Spacing.s)
    }

    // MARK: - Search Input Row

    private var searchRow: some View {
        HStack(spacing: AppTheme.Spacing.s) {
            TextField("Enter a name", text: $query)
                .font(AppTheme.Typography.body)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
                .focused($isFocused)
                .onChange(of: query) { _, newValue in
                    handleQueryChange(newValue)
                }

            if searcher.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
            } else if !query.isEmpty {
                Button {
                    query = ""
                    showResults = false
                    searcher.cancel()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }
            }
        }
        .padding(.vertical, AppTheme.Spacing.s)
    }

    // MARK: - Results Dropdown

    private var resultsDropdown: some View {
        VStack(spacing: 0) {
            ForEach(searcher.results, id: \.id) { congregation in
                Button {
                    select(congregation)
                } label: {
                    HStack(spacing: AppTheme.Spacing.m) {
                        highlightedText(congregation.name, matching: query)
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
    }

    // MARK: - Highlighted Text

    /// Renders the congregation name with the matching portion highlighted in gold.
    private func highlightedText(_ text: String, matching search: String) -> Text {
        let lowered = text.lowercased()
        let searchLowered = search.lowercased().trimmingCharacters(in: .whitespaces)

        guard let range = lowered.range(of: searchLowered) else {
            return Text(text)
                .font(AppTheme.Typography.body)
                .foregroundColor(.primary)
        }

        let before = String(text[text.startIndex..<range.lowerBound])
        let match = String(text[range])
        let after = String(text[range.upperBound..<text.endIndex])

        return Text(before)
            .font(AppTheme.Typography.body)
            .foregroundColor(.primary)
        + Text(match)
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(Color(red: 0.75, green: 0.65, blue: 0.15))
        + Text(after)
            .font(AppTheme.Typography.body)
            .foregroundColor(.primary)
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
        selectedName = congregation.name
        selectedId = congregation.id
        showResults = false
        // Don't clear query here — it triggers onChange which wipes the selection.
        // The searchRow is removed from the view tree once selectedId != nil,
        // so the stale query value is harmless. It resets in clearSelection().
        isFocused = false
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

#Preview {
    CongregationSearchField(
        selectedName: .constant(""),
        selectedId: .constant(nil)
    )
    .padding()
}
