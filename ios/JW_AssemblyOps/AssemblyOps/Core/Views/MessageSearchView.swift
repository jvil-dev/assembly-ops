//
//  MessageSearchView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/23/26.
//

// MARK: - Message Search View
//
// Search overlay with real-time results for messages.
//
// Features:
//   - Search bar with debounced input
//   - Results list with message previews
//   - Empty and loading states
//
// Used by: MessagesView, OverseerMessagesView

import SwiftUI
import Combine

struct MessageSearchView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var hasAppeared = false

    @State private var query = ""
    @State private var results: [Message] = []
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var searchTask: Task<Void, Never>?

    let eventId: String

    var body: some View {
        NavigationStack {
            contentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .themedBackground(scheme: colorScheme)
                .navigationTitle("messages.search.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "messages.search.placeholder".localized)
            .onChange(of: query) { _, newValue in
                searchTask?.cancel()
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmed.count >= 2 else {
                    results = []
                    hasSearched = false
                    return
                }

#Preview {
    MessageSearchView(eventId: "event-1")
}
                searchTask = Task {
                    try? await Task.sleep(nanoseconds: 400_000_000) // 400ms debounce
                    guard !Task.isCancelled else { return }
                    await performSearch(trimmed)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("general.cancel".localized) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if !hasSearched && results.isEmpty {
            searchPrompt
        } else if isSearching {
            LoadingView(message: "messages.search.searching".localized)
        } else if results.isEmpty {
            noResults
        } else {
            resultsList
        }
    }

    // MARK: - Search Prompt

    private var searchPrompt: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

            Text("messages.search.prompt".localized)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(AppTheme.Spacing.screenEdge)
        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
    }

    // MARK: - No Results

    private var noResults: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

            Text("messages.search.noResults".localized)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.primary)

            Text("messages.search.noResults.subtitle".localized)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

            Spacer()
        }
        .padding(AppTheme.Spacing.screenEdge)
    }

    // MARK: - Results List

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.m) {
                ForEach(Array(results.enumerated()), id: \.element.id) { index, message in
                    MessageRowView(message: message)
                        .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.02)
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.s)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
    }

    // MARK: - Search Logic

    @MainActor
    private func performSearch(_ query: String) async {
        isSearching = true
        defer {
            isSearching = false
            hasSearched = true
        }

        do {
            results = try await MessagesService.shared.searchMessages(
                eventId: eventId,
                query: query
            )
        } catch {
            results = []
        }
    }
}
