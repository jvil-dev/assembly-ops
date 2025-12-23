//
//  APIClient.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/23/25.
//

import Foundation

actor APIClient {

    // MARK: - Singleton

    static let shared = APIClient()

    // MARK: - Properties

    private let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // MARK: - Init

    private init() {
        self.baseURL = Constants.API.baseURL

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Constants.API.timeout
        config.timeoutIntervalForResource = Constants.API.timeout * 2
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    // MARK: - HTTP Methods
    
    enum HTTPMethod: String {
        case GET
        case POST
        case PUT
        case PATCH
        case DELETE
    }
    
    // MARK: - Request Building
    
    private func buildRequest(
        endpoint: String,
        method: HTTPMethod,
        body: Data? = nil,
        queryItems: [URLQueryItem]? = nil,
        requiresAuth: Bool = true
    ) throws -> URLRequest {
        // Build URL
        var urlString = "\(baseURL)\(endpoint)"
        
        if let queryItems = queryItems, !queryItems.isEmpty {
            var components = URLComponents(string: urlString)
            components?.queryItems = queryItems
            urlString = components?.url?.absoluteString ?? urlString
        }
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth header if required
        if requiresAuth {
            if let token = KeychainManager.shared.overseerAccessToken {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else if let token = KeychainManager.shared.volunteerToken {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }
        
        // Add body
        if let body = body {
            request.httpBody = body
        }
        
        return request
    }
    
    // MARK: - Request Execution
    
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Encodable? = nil,
        queryItems: [URLQueryItem]? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        // Check network connectivity
        guard NetworkMonitor.shared.isConnected else {
            throw APIError.offline
        }
        
        // Encode body if present
        var bodyData: Data? = nil
        if let body = body {
            do {
                bodyData = try encoder.encode(body)
            } catch {
                throw APIError.encodingError(error)
            }
        }
        
        // Build request
        let request = try buildRequest(
            endpoint: endpoint,
            method: method,
            body: bodyData,
            queryItems: queryItems,
            requiresAuth: requiresAuth
        )
        
        // Execute request
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            if error.code == .timedOut {
                throw APIError.timeout
            } else if error.code == .notConnectedToInternet {
                throw APIError.offline
            } else {
                throw APIError.networkError(error)
            }
        } catch {
            throw APIError.networkError(error)
        }
        
        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Handle status codes
        switch httpResponse.statusCode {
        case 200...299:
            break // Success
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 409:
            let message = try? decoder.decode(APIResponse<String>.self, from: data).message
            throw APIError.conflict(message: message)
        case 422:
            let message = try? decoder.decode(APIResponse<String>.self, from: data).message
            throw APIError.validationError(message: message)
        case 500...599:
            let message = try? decoder.decode(APIResponse<String>.self, from: data).message
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
        default:
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: nil)
        }
        
        // Decode response
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    // MARK: - Convenience Methods
    
    func get<T: Decodable>(
        _ endpoint: String,
        queryItems: [URLQueryItem]? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        try await request(
            endpoint: endpoint,
            method: .GET,
            queryItems: queryItems,
            requiresAuth: requiresAuth
        )
    }
    
    func post<T: Decodable>(
        _ endpoint: String,
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        try await request(
            endpoint: endpoint,
            method: .POST,
            body: body,
            requiresAuth: requiresAuth
        )
    }
    
    func put<T: Decodable>(
        _ endpoint: String,
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        try await request(
            endpoint: endpoint,
            method: .PUT,
            body: body,
            requiresAuth: requiresAuth
        )
    }
    
    func patch<T: Decodable>(
        _ endpoint: String,
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        try await request(
            endpoint: endpoint,
            method: .PATCH,
            body: body,
            requiresAuth: requiresAuth
        )
    }
    
    func delete<T: Decodable>(
        _ endpoint: String,
        requiresAuth: Bool = true
    ) async throws -> T {
        try await request(
            endpoint: endpoint,
            method: .DELETE,
            requiresAuth: requiresAuth
        )
    }
    
    // For endpoints that return no data
    func deleteNoResponse(
        _ endpoint: String,
        requiresAuth: Bool = true
    ) async throws {
        let _: APIResponse<String> = try await request(
            endpoint: endpoint,
            method: .DELETE,
            requiresAuth: requiresAuth
        )
    }
}
