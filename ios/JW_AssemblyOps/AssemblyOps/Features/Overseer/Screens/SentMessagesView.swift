//
//  SentMessagesView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/8/26.
//

import SwiftUI

struct SentMessagesView: View {
    @StateObject private var viewModel = SentMessagesViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var showError = false

    var body: some View {
        Group {
            if viewModel.isLoading && !viewModel.hasLoaded {
                LoadingView(message: "Loading messages...")
            } else if viewModel.isEmpty {
                emptyState
            } else {
                messagesList
            }
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle("Sent Messages")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            if !viewModel.hasLoaded {
                await viewModel.fetchMessages()
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                HapticManager.shared.lightTap()
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                Text(error)
            }
        }
        .onChange(of: viewModel.error) { _, newValue in
            showError = newValue != nil
        }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Spacer()

            Image(systemName: "envelope")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

            Text("No Messages Sent")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.primary)

            Text("Messages you send will appear here")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(AppTheme.Spacing.screenEdge)
        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
    }

    // MARK: - Messages List

    private var messagesList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.m) {
                ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                    SentMessageRow(message: message, colorScheme: colorScheme)
                        .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.03)
                }
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.s)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        SentMessagesView()
    }
}
