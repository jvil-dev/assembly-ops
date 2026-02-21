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

    // Single create form fields
    @Published var name: String = ""
    @Published var description: String = ""
    @Published var location: String = ""
    @Published var capacityText: String = "1"
    @Published var category: String = ""

    // Bulk create form fields
    @Published var bulkPrefix: String = ""
    @Published var bulkStartNumber: String = "1"
    @Published var bulkCount: String = "10"

    var capacity: Int { Int(capacityText) ?? 1 }

    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        capacity > 0
    }

    var isBulkFormValid: Bool {
        !bulkPrefix.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        capacity > 0 &&
        (Int(bulkCount) ?? 0) >= 1 &&
        (Int(bulkCount) ?? 0) <= 50 &&
        (Int(bulkStartNumber) ?? 0) >= 0
    }

    var bulkPreviewNames: [String] {
        let prefix = bulkPrefix.trimmingCharacters(in: .whitespacesAndNewlines)
        let start = Int(bulkStartNumber) ?? 1
        let count = min(Int(bulkCount) ?? 0, 50)
        guard count > 0 else { return [] }
        return (start..<(start + count)).map { "\(prefix)\($0)" }
    }

    func createPost(departmentId: String) async {
        guard isFormValid else { return }
        isSaving = true
        error = nil
        defer { isSaving = false }

        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        let input = AssemblyOpsAPI.CreatePostInput(
            name: name,
            description: description.isEmpty ? .none : .some(description),
            location: location.isEmpty ? .none : .some(location),
            capacity: .some(capacity),
            category: trimmedCategory.isEmpty ? .none : .some(trimmedCategory)
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
            category = ""

        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
        }
    }

    func createBulkPosts(departmentId: String) async {
        guard isBulkFormValid else { return }
        isSaving = true
        error = nil
        defer { isSaving = false }

        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        let start = Int(bulkStartNumber) ?? 1
        let count = Int(bulkCount) ?? 0
        let prefix = bulkPrefix.trimmingCharacters(in: .whitespacesAndNewlines)

        let posts = (start..<(start + count)).map { number in
            AssemblyOpsAPI.CreatePostInput(
                name: "\(prefix)\(number)",
                capacity: .some(capacity),
                category: trimmedCategory.isEmpty ? .none : .some(trimmedCategory),
                sortOrder: .some(number)
            )
        }

        let input = AssemblyOpsAPI.CreatePostsInput(
            departmentId: departmentId,
            posts: posts
        )

        do {
            _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[AssemblyOpsAPI.CreatePostsMutation.Data.CreatePost], Error>) in
                NetworkClient.shared.apollo.perform(
                    mutation: AssemblyOpsAPI.CreatePostsMutation(input: input)
                ) { result in
                    switch result {
                    case .success(let graphQLResult):
                        if let created = graphQLResult.data?.createPosts {
                            continuation.resume(returning: created)
                        } else if let errors = graphQLResult.errors, !errors.isEmpty {
                            continuation.resume(throwing: NSError(
                                domain: "BulkPostCreation",
                                code: -1,
                                userInfo: [NSLocalizedDescriptionKey: errors.first?.localizedDescription ?? "Unknown error"]
                            ))
                        } else {
                            continuation.resume(throwing: NSError(
                                domain: "BulkPostCreation",
                                code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "Failed to create posts"]
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
            bulkPrefix = ""
            bulkStartNumber = "1"
            bulkCount = "10"
            capacityText = "1"
            category = ""

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
    let category: String?
    let sortOrder: Int
    let createdAt: Date
}
