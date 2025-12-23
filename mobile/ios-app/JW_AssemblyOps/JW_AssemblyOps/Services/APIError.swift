//
//  APIError.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/23/25.
//

import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidRequest
    case invalidResponse
    case networkError(Error)
    case decodingError(Error)
    case encodingError(Error)
    case serverError(statusCode: Int, message: String?)
    case unauthorized
    case forbidden
    case notFound
    case conflict(message: String?)
    case validationError(message: String?)
    case noData
    case offline
    case timeout
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidRequest:
            return "Invalid request"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .serverError(let statusCode, let message):
            return message ?? "Server error (code: \(statusCode))"
        case .unauthorized:
            return "Session expired. Please sign in again."
        case .forbidden:
            return "You don't have permission to perform this action"
        case .notFound:
            return "Resource not found"
        case .conflict(let message):
            return message ?? "A conflict occurred"
        case .validationError(let message):
            return message ?? "Validation error"
        case .noData:
            return "No data received"
        case .offline:
            return "You appear to be offline. Please check your connection."
        case .timeout:
            return "Request timed out. Please try again."
        case .unknown:
            return "An unexpected error occurred"
        }
    }
    
    var isAuthError: Bool {
        switch self {
        case .unauthorized, .forbidden:
            return true
        default:
            return false
        }
    }
    
    var isNetworkError: Bool {
        switch self {
        case .networkError, .offline, .timeout:
            return true
        default:
            return false
        }
    }
}

