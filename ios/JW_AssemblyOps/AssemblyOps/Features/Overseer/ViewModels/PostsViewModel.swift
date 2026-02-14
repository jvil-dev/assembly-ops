//
//  PostsViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/14/26.
//

// MARK: - Posts View Model
//
// Manages state and business logic for creating and managing posts.
// Posts represent specific locations or positions within a department.
//
// Published Properties:
//   - posts: List of posts in current department
//   - isLoading: Loading state indicator
//   - errorMessage: Error display message
//   - showSuccess: Success state trigger
//
// Methods:
//   - createPost(departmentId:name:description:): Create new post
//   - loadPosts(departmentId:): Fetch posts for department

import Foundation
import Apollo
import Combine

@MainActor
final class PostsViewModel: ObservableObject {
    @Published var posts: [PostItem] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var error: String?
    @Published var didCreate = false

    // Form fields
    @Published var name: String = ""
    @Published var description: String = ""
    @Published var location: String = ""
    @Published var capacityText: String = "1"

    var capacity: Int { Int(capacityText) ?? 1 }

    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        capacity > 0
    }

    func createPost(departmentId: String) async {
        guard isFormValid else { return }
        isSaving = true
        error = nil
        defer { isSaving = false }

        let input = AssemblyOpsAPI.CreatePostInput(
            name: name,
            description: description.isEmpty ? .none : .some(description),
            location: location.isEmpty ? .none : .some(location),
            capacity: .some(capacity)
        )

        do {
            _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AssemblyOpsAPI.CreatePostMutation.Data.CreatePost, Error>) in
                NetworkClient.shared.apollo.perform(
                    mutation: AssemblyOpsAPI.CreatePostMutation(
                        departmentId: departmentId,
                        input: input
                    )
                ) { result in
                    switch result {
                    case .success(let graphQLResult):
                        if let post = graphQLResult.data?.createPost {
                            continuation.resume(returning: post)
                        } else if let errors = graphQLResult.errors, !errors.isEmpty {
                            continuation.resume(throwing: NSError(
                                domain: "PostCreation",
                                code: -1,
                                userInfo: [NSLocalizedDescriptionKey: errors.first?.localizedDescription ?? "Unknown error"]
                            ))
                        } else {
                            continuation.resume(throwing: NSError(
                                domain: "PostCreation",
                                code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "Failed to create post"]
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
            description = ""
            location = ""
            capacityText = "1"

        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
        }
    }
}

struct PostItem: Identifiable {
    let id: String
    let name: String
    let description: String?
    let location: String?
    let capacity: Int
    let createdAt: Date
}
