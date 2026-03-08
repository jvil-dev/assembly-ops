//
//  FloorPlanView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/8/26.
//

// MARK: - Floor Plan View
//
// Pinch-to-zoom floor plan viewer for an event.
// Loads the floor plan image via FloorPlanViewModel and supports
// MagnificationGesture (zoom), DragGesture (pan while zoomed),
// and double-tap to reset. isReadOnly is accepted for future use.
//

import SwiftUI

struct FloorPlanView: View {
    let eventId: String
    let isReadOnly: Bool

    @StateObject private var viewModel = FloorPlanViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false

    // Gesture state
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    // Error alert state
    @State private var showError = false

    var body: some View {
        ZStack {
            if viewModel.isLoading {
                loadingState
            } else if let error = viewModel.error {
                errorState(message: error)
            } else if viewModel.hasFloorPlan, let imageUrl = viewModel.imageUrl {
                floorPlanImage(url: imageUrl)
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .themedBackground(scheme: colorScheme)
        .navigationTitle("floorplan.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadFloorPlan(eventId: eventId)
        }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
        .onChange(of: viewModel.error) { _, newValue in
            showError = newValue != nil
        }
        .alert("common.error".localized, isPresented: $showError) {
            Button("common.ok".localized) { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
    }

    // MARK: - Loading State

    private var loadingState: some View {
        ProgressView()
            .scaleEffect(1.2)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
    }

    // MARK: - Error State

    private func errorState(message: String) -> some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.StatusColors.warning)
            Text(message)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)
                .screenPadding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView(
            "floorplan.empty.title".localized,
            systemImage: "map",
            description: Text("floorplan.empty.desc".localized)
        )
        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
    }

    // MARK: - Floor Plan Image

    private func floorPlanImage(url: URL) -> some View {
        GeometryReader { geometry in
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: geometry.size.width, height: geometry.size.height)

                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale = min(max(scale * delta, 1.0), 5.0)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                    if scale <= 1.0 {
                                        withAnimation(AppTheme.quickAnimation) {
                                            offset = .zero
                                            lastOffset = .zero
                                        }
                                    }
                                }
                        )
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    guard scale > 1.0 else { return }
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(AppTheme.quickAnimation) {
                                scale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            }
                        }

                case .failure:
                    VStack(spacing: AppTheme.Spacing.l) {
                        Image(systemName: "photo.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        Text("floorplan.empty.title".localized)
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)

                @unknown default:
                    EmptyView()
                }
            }
        }
        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
    }
}

#Preview {
    NavigationStack {
        FloorPlanView(eventId: "preview-event-id", isReadOnly: true)
    }
}
