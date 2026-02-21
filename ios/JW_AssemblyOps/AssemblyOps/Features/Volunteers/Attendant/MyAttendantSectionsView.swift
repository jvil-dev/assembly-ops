//
//  MyAttendantSectionsView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/16/26.
//

// MARK: - My Attendant Posts View
//
// Volunteer-facing list of accepted post assignments for attendant department.
// Posts are sourced from ScheduleAssignments (ACCEPTED status).
// Tap post navigates to SubmitSectionCountView for count submission.
// Toolbar buttons for Report Incident and Report Lost Person.
//

import SwiftUI

struct MyAttendantSectionsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var showReportIncident = false
    @State private var showReportLostPerson = false
    @State private var posts: [AttendantPostItem] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    if isLoading && posts.isEmpty {
                        LoadingView(message: "attendant.posts.title".localized)
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
                    } else if posts.isEmpty {
                        emptyState
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
                    } else {
                        ForEach(Array(posts.enumerated()), id: \.element.id) { index, post in
                            NavigationLink(destination: SubmitSectionCountView(post: post)) {
                                postRow(post)
                            }
                            .buttonStyle(.plain)
                            .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.05)
                        }
                    }
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("attendant.posts.title".localized)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(destination: MyAttendantMeetingsView()) {
                        Image(systemName: "person.3.sequence")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showReportIncident = true
                        } label: {
                            Label("attendant.incidents.report".localized, systemImage: "exclamationmark.triangle")
                        }

                        Button {
                            showReportLostPerson = true
                        } label: {
                            Label("attendant.lostPerson.create".localized, systemImage: "person.crop.circle.badge.questionmark")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showReportIncident) {
                ReportSafetyIncidentView(posts: posts)
            }
            .sheet(isPresented: $showReportLostPerson) {
                ReportLostPersonView(posts: posts)
            }
            .refreshable {
                await loadPosts()
            }
            .task {
                await loadPosts()
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
        }
    }

    // MARK: - Post Row

    private func postRow(_ post: AttendantPostItem) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.name)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(.primary)

                    if let location = post.location {
                        Text(location)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                            .lineLimit(2)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Image(systemName: "map")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            Text("attendant.volunteer.noPosts".localized)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xxl)
    }

    // MARK: - Data Loading

    private func loadPosts() async {
        isLoading = true
        defer { isLoading = false }
        if let assignments = try? await AssignmentsService.shared.fetchAssignments() {
            let unique = Dictionary(
                assignments
                    .filter { $0.status == .accepted && $0.departmentType == "ATTENDANT" }
                    .map { ($0.postId, AttendantPostItem(id: $0.postId, name: $0.postName, location: $0.postLocation, category: "", sortOrder: 0)) },
                uniquingKeysWith: { first, _ in first }
            )
            posts = Array(unique.values).sorted { $0.name < $1.name }
        }
    }
}

#Preview {
    MyAttendantSectionsView()
        .environmentObject(AppState.shared)
}
