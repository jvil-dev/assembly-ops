//
//  FloorPlanService.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/4/26.
//

// MARK: - Floor Plan Service
//
// Manages floor plan upload and retrieval for an event.
// Overseers upload via S3 presigned URL; all event members view via presigned GET URL.
//
// Methods:
//   - fetchViewUrl(eventId:): Returns presigned GET URL for viewing, or nil if none uploaded
//   - uploadFloorPlan(eventId:imageData:): Full upload flow — presigned PUT URL → S3 PUT → confirm
//   - deleteFloorPlan(eventId:): Deletes the floor plan for an event
//
// Dependencies:
//   - NetworkClient: Apollo client for GraphQL
//   - URLSession: Direct HTTP PUT to S3 presigned URL (no Apollo)

import Foundation
import Apollo

// MARK: - FloorPlanError

enum FloorPlanError: LocalizedError {
    case networkError(String)
    case serverError(String)
    case uploadFailed(Int)
    case missingUploadUrl

    var errorDescription: String? {
        switch self {
        case .networkError(let message): return "Network error: \(message)"
        case .serverError(let message): return message
        case .uploadFailed(let statusCode): return "S3 upload failed with status \(statusCode)"
        case .missingUploadUrl: return "Did not receive a presigned upload URL from the server"
        }
    }
}

// MARK: - FloorPlanService

/// Manages floor plan upload and retrieval for an event.
/// Overseers upload via S3 presigned URL; all event members view via presigned GET URL.
/// Called by: FloorPlanViewModel
final class FloorPlanService {
    static let shared = FloorPlanService()
    private init() {}

    // MARK: - Fetch View URL

    /// Returns a presigned S3 GET URL for viewing the floor plan, or nil if none uploaded.
    func fetchViewUrl(eventId: String) async throws -> String? {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.FloorPlanUrlQuery(eventId: eventId),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: FloorPlanError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        // floorPlanUrl is String? (nullable) — nil means no floor plan uploaded
                        continuation.resume(returning: graphQLResult.data?.floorPlanUrl)
                    }
                case .failure(let error):
                    continuation.resume(throwing: FloorPlanError.networkError(error.localizedDescription))
                }
            }
        }
    }

    // MARK: - Upload Floor Plan

    /// Full upload flow:
    /// 1. Get presigned PUT URL from backend
    /// 2. HTTP PUT image data to S3 URL
    /// 3. Confirm upload to backend (writes key to DB)
    func uploadFloorPlan(eventId: String, imageData: Data) async throws {
        // Step 1: Get presigned PUT URL
        let uploadUrl: String = try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.GetFloorPlanUploadUrlMutation(eventId: eventId)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let urlString = graphQLResult.data?.getFloorPlanUploadUrl {
                        continuation.resume(returning: urlString)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: FloorPlanError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: FloorPlanError.missingUploadUrl)
                    }
                case .failure(let error):
                    continuation.resume(throwing: FloorPlanError.networkError(error.localizedDescription))
                }
            }
        }

        // Step 2: PUT imageData directly to the presigned S3 URL
        guard let s3Url = URL(string: uploadUrl) else {
            throw FloorPlanError.missingUploadUrl
        }
        var request = URLRequest(url: s3Url)
        request.httpMethod = "PUT"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        let (_, response) = try await URLSession.shared.upload(for: request, from: imageData)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw FloorPlanError.uploadFailed(statusCode)
        }

        // Step 3: Confirm upload so backend writes the S3 key to DB
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.ConfirmFloorPlanUploadMutation(eventId: eventId)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: FloorPlanError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(returning: ())
                    }
                case .failure(let error):
                    continuation.resume(throwing: FloorPlanError.networkError(error.localizedDescription))
                }
            }
        }
    }

    // MARK: - Delete Floor Plan

    func deleteFloorPlan(eventId: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.DeleteFloorPlanMutation(eventId: eventId)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: FloorPlanError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(returning: ())
                    }
                case .failure(let error):
                    continuation.resume(throwing: FloorPlanError.networkError(error.localizedDescription))
                }
            }
        }
    }
}
