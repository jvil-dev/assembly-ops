//
//  NetworkClient.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/26/25.
//

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
