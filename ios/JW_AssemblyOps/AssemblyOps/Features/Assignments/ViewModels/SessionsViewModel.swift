//
//  SessionsViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/14/26.
//

// MARK: - Sessions View Model
//
// Manages state and business logic for creating and managing event sessions.
// Sessions represent time blocks during which volunteers serve.
//
// Published Properties:
//   - sessions: List of sessions in current event
//   - isLoading: Loading state indicator
//   - errorMessage: Error display message
//   - showSuccess: Success state trigger
//
// Methods:
//   - createSession(eventId:name:date:startTime:endTime:): Create new session
//   - loadSessions(eventId:): Fetch sessions for event

import Foundation
import Apollo
import Combine

@MainActor
final class SessionsViewModel: ObservableObject {
    @Published var sessions: [SessionItem] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var error: String?
    @Published var didCreate = false

    // Form fields
    @Published var name: String = ""
    @Published var selectedDate: Date = Date()
    @Published var startTime: String = ""
    @Published var endTime: String = ""

    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !startTime.isEmpty &&
        !endTime.isEmpty
    }

    func createSession(eventId: String) async {
        guard isFormValid else { return }
        isSaving = true
        error = nil
        defer { isSaving = false }

        // Convert Date to ISO 8601 string for GraphQL DateTime type
        let dateFormatter = ISO8601DateFormatter()
        let dateString = dateFormatter.string(from: selectedDate)

        let input = AssemblyOpsAPI.CreateSessionInput(
            name: name,
            date: dateString,
            startTime: startTime,
            endTime: endTime
        )

        do {
            _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AssemblyOpsAPI.CreateSessionMutation.Data.CreateSession, Error>) in
                NetworkClient.shared.apollo.perform(
                    mutation: AssemblyOpsAPI.CreateSessionMutation(
                        eventId: eventId,
                        input: input
                    )
                ) { result in
                    switch result {
                    case .success(let graphQLResult):
                        if let session = graphQLResult.data?.createSession {
                            continuation.resume(returning: session)
                        } else if let errors = graphQLResult.errors, !errors.isEmpty {
                            continuation.resume(throwing: NSError(
                                domain: "SessionCreation",
                                code: -1,
                                userInfo: [NSLocalizedDescriptionKey: errors.first?.localizedDescription ?? "Unknown error"]
                            ))
                        } else {
                            continuation.resume(throwing: NSError(
                                domain: "SessionCreation",
                                code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "Failed to create session"]
                            ))
                        }
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }

            HapticManager.shared.success()
            didCreate = true

            // Reset form
            name = ""
            startTime = ""
            endTime = ""
            selectedDate = Date()

        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
        }
    }
}

struct SessionItem: Identifiable {
    let id: String
    let name: String
    let date: Date
    let startTime: String
    let endTime: String
    let createdAt: Date
}
