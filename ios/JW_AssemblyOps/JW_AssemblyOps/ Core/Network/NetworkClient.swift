//
//  NetworkClient.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/26/25.
//

// MARK: - Network Client
//
// Singleton Apollo GraphQL client for all API communication.
// Configures endpoint URL based on build environment (DEBUG vs Release).
//
// Properties:
//   - apollo: The ApolloClient instance for executing queries/mutations
//   - baseURL: API endpoint (local dev server in DEBUG, production in Release)
//
// Methods:
//   - resetClient(): Recreate Apollo client with fresh auth headers (call after login/logout)
//
// Configuration:
//   - DEBUG: http://localhost:4000/graphql (local dev server)
//   - Release: https://api.assemblyops.io/graphql (production)
//
// Auth:
//   - Reads access token from KeychainManager
//   - Attaches "Authorization: Bearer <token>" header to all requests
//
// Dependencies:
//   - KeychainManager: Retrieves stored access token
//   - Apollo: GraphQL client library
//
// Used by: LoginViewModel, AssignmentsViewModel, AppState (all API calls)

import Foundation
import Apollo

/// Main GraphQL client for API communication
final class NetworkClient {
    static let shared = NetworkClient()

    private(set) var apollo: ApolloClient

    // Configure for your environment
    #if DEBUG
    private let baseURL = URL(string: "http://192.168.1.2:4000/graphql")!
    #else
    private let baseURL = URL(string: "https://api.assemblyops.io/graphql")!
    #endif

    private init() {
        apollo = NetworkClient.createClient(url: baseURL)
    }

    /// Recreate client (useful after login/logout)
    func resetClient() {
        apollo = NetworkClient.createClient(url: baseURL)
    }

    private static func createClient(url: URL) -> ApolloClient {
        let store = ApolloStore()
        let provider = DefaultInterceptorProvider(store: store)
        let transport = RequestChainNetworkTransport(
            interceptorProvider: provider,
            endpointURL: url,
            additionalHeaders: authHeaders()
        )
        return ApolloClient(networkTransport: transport, store: store)
    }

    private static func authHeaders() -> [String: String] {
        if let token = KeychainManager.shared.accessToken {
            return ["Authorization": "Bearer \(token)"]
        }
        return [:]
    }
}
