//
//  NetworkClient.swift
//  AssemblyOps
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
//   - Release: https://api.assemblyops.org/graphql (production)
//
// Auth:
//   - AuthTokenInterceptor dynamically adds Bearer token to every request
//   - Automatically refreshes expired access tokens before sending requests
//   - Posts Notification.Name.authSessionExpired when refresh token is also expired
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

    #if DEBUG
    static let graphQLURL = URL(string: "http://192.168.1.5:4000/graphql")!
    #else
    static let graphQLURL = URL(string: "https://api.assemblyops.org/graphql")!
    #endif

    private init() {
        apollo = NetworkClient.createClient()
    }

    /// Recreate client (useful after login/logout to clear Apollo cache)
    func resetClient() {
        apollo = NetworkClient.createClient()
    }

    private static func createClient() -> ApolloClient {
        let store = ApolloStore()
        let provider = AuthInterceptorProvider(store: store)
        let transport = RequestChainNetworkTransport(
            interceptorProvider: provider,
            endpointURL: graphQLURL
        )
        return ApolloClient(networkTransport: transport, store: store)
    }
}

// MARK: - Auth Interceptor Provider

/// Custom interceptor provider that injects AuthTokenInterceptor before network fetch.
/// Uses composition (not subclassing) to avoid @MainActor isolation conflicts.
private struct AuthInterceptorProvider: InterceptorProvider {
    private let base: DefaultInterceptorProvider

    init(store: ApolloStore) {
        self.base = DefaultInterceptorProvider(store: store)
    }

    func interceptors<Operation: GraphQLOperation>(
        for operation: Operation
    ) -> [any ApolloInterceptor] {
        var interceptors = base.interceptors(for: operation)
        // Insert auth interceptor before NetworkFetchInterceptor
        if let networkIndex = interceptors.firstIndex(where: { $0 is NetworkFetchInterceptor }) {
            interceptors.insert(AuthTokenInterceptor(), at: networkIndex)
        } else {
            interceptors.insert(AuthTokenInterceptor(), at: 0)
        }
        // Insert rate limit interceptor after NetworkFetchInterceptor to inspect HTTP responses
        if let networkIndex = interceptors.firstIndex(where: { $0 is NetworkFetchInterceptor }) {
            interceptors.insert(RateLimitInterceptor(), at: networkIndex + 1)
        }
        return interceptors
    }

    func additionalErrorInterceptor<Operation: GraphQLOperation>(
        for operation: Operation
    ) -> (any ApolloErrorInterceptor)? {
        base.additionalErrorInterceptor(for: operation)
    }
}

// MARK: - Auth Token Interceptor

/// Adds a fresh Bearer token to every request, refreshing the access token if expired.
private final class AuthTokenInterceptor: ApolloInterceptor {
    let id = "AuthTokenInterceptor"

    /// Serialises concurrent refresh attempts so only one refresh runs at a time.
    private static let refreshLock = NSLock()
    private static var isRefreshing = false
    private static var pendingCompletions: [(Bool) -> Void] = []

    func interceptAsync<Operation: GraphQLOperation>(
        chain: any RequestChain,
        request: HTTPRequest<Operation>,
        response: HTTPResponse<Operation>?,
        completion: @escaping (Result<GraphQLResult<Operation.Data>, any Error>) -> Void
    ) {
        // No tokens at all (not logged in) — proceed without auth header
        guard KeychainManager.shared.accessToken != nil else {
            chain.proceedAsync(request: request, response: response, interceptor: self, completion: completion)
            return
        }

        // If token is still valid, attach it and proceed immediately
        if !KeychainManager.shared.isTokenExpired,
           let token = KeychainManager.shared.accessToken {
            request.addHeader(name: "Authorization", value: "Bearer \(token)")
            chain.proceedAsync(request: request, response: response, interceptor: self, completion: completion)
            return
        }

        // Token exists but is expired — refresh before proceeding
        Self.enqueueRefresh { success in
            if success, let token = KeychainManager.shared.accessToken {
                request.addHeader(name: "Authorization", value: "Bearer \(token)")
                chain.proceedAsync(request: request, response: response, interceptor: self, completion: completion)
            } else {
                // Refresh failed — notify app to log out
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .authSessionExpired, object: nil)
                }
                chain.handleErrorAsync(
                    AuthError.tokenRefreshFailed,
                    request: request,
                    response: response,
                    completion: completion
                )
            }
        }
    }

    // MARK: - Token Refresh (via URLSession, bypasses Apollo)

    private static func enqueueRefresh(completion: @escaping (Bool) -> Void) {
        refreshLock.lock()
        pendingCompletions.append(completion)

        guard !isRefreshing else {
            refreshLock.unlock()
            return
        }
        isRefreshing = true
        refreshLock.unlock()

        performTokenRefresh { success in
            refreshLock.lock()
            let completions = pendingCompletions
            pendingCompletions = []
            isRefreshing = false
            refreshLock.unlock()

            for cb in completions { cb(success) }
        }
    }

    private static func performTokenRefresh(completion: @escaping (Bool) -> Void) {
        guard let refreshToken = KeychainManager.shared.refreshToken else {
            completion(false)
            return
        }

        let body: [String: Any] = [
            "query": "mutation RefreshToken($input: RefreshTokenInput!) { refreshToken(input: $input) { accessToken refreshToken expiresIn } }",
            "variables": ["input": ["refreshToken": refreshToken]]
        ]

        var request = URLRequest(url: NetworkClient.graphQLURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard error == nil,
                  let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let dataField = json["data"] as? [String: Any],
                  let tokenPayload = dataField["refreshToken"] as? [String: Any],
                  let newAccess = tokenPayload["accessToken"] as? String,
                  let newRefresh = tokenPayload["refreshToken"] as? String,
                  let expiresIn = tokenPayload["expiresIn"] as? Int
            else {
                #if DEBUG
                print("[AuthInterceptor] Token refresh failed")
                #endif
                completion(false)
                return
            }

            KeychainManager.shared.saveTokens(
                accessToken: newAccess,
                refreshToken: newRefresh,
                expiresIn: expiresIn
            )
            #if DEBUG
            print("[AuthInterceptor] Token refreshed successfully")
            #endif
            completion(true)
        }.resume()
    }
}

// MARK: - Auth Error

private enum AuthError: LocalizedError {
    case tokenRefreshFailed

    var errorDescription: String? {
        "Session expired. Please log in again."
    }
}

// MARK: - Notification

extension Notification.Name {
    static let authSessionExpired = Notification.Name("authSessionExpired")
}

// MARK: - Apollo Async Extension
extension ApolloClient {
    /// Async/await wrapper for GraphQL queries
    func fetch<Query: GraphQLQuery>(
        query: Query,
        cachePolicy: CachePolicy = .default
    ) async throws -> GraphQLResult<Query.Data> {
        try await withCheckedThrowingContinuation { continuation in
            self.fetch(query: query, cachePolicy: cachePolicy) { result in
                switch result {
                case .success(let graphQLResult):
                    continuation.resume(returning: graphQLResult)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Async/await wrapper for GraphQL mutations
    func perform<Mutation: GraphQLMutation>(
        mutation: Mutation
    ) async throws -> GraphQLResult<Mutation.Data> {
        try await withCheckedThrowingContinuation { continuation in
            self.perform(mutation: mutation) { result in
                switch result {
                case .success(let graphQLResult):
                    continuation.resume(returning: graphQLResult)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
