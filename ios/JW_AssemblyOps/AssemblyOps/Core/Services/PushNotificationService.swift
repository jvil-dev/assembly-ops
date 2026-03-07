//
//  PushNotificationService.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/7/26.
//

// MARK: - Push Notification Service
//
// GraphQL client for device token registration.
// Follows existing service pattern (singleton, NOT @MainActor, withCheckedThrowingContinuation).
//
// Methods:
//   - registerDeviceToken(token:platform:): Register FCM token with backend
//   - unregisterDeviceToken(token:): Remove FCM token from backend
//
// Dependencies:
//   - NetworkClient: Apollo GraphQL client
//
// Used by: PushNotificationManager

import Foundation
import Apollo

final class PushNotificationService {
    static let shared = PushNotificationService()
    private init() {}

    func registerDeviceToken(token: String, platform: String = "ios") async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.RegisterDeviceTokenMutation(
                    token: token,
                    platform: .some(platform)
                )
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: NetworkError.graphQL(errors.first?.message ?? "Failed to register token"))
                        return
                    }
                    continuation.resume(returning: graphQLResult.data?.registerDeviceToken ?? false)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func unregisterDeviceToken(token: String) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.UnregisterDeviceTokenMutation(token: token)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: NetworkError.graphQL(errors.first?.message ?? "Failed to unregister token"))
                        return
                    }
                    continuation.resume(returning: graphQLResult.data?.unregisterDeviceToken ?? false)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
