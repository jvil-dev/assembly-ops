//
//  RateLimitInterceptor.swift
//  AssemblyOps
//  Created by Jorge Villeda on 3/6/26.
//
//  Apollo interceptor that detects HTTP 429 responses and surfaces them
//  as RateLimitError with the server's Retry-After interval.
//

import Foundation
import Apollo

enum RateLimitError: LocalizedError {
    case rateLimited(retryAfter: TimeInterval)

    var errorDescription: String? {
        switch self {
        case .rateLimited:
            return NSLocalizedString("rate_limit_error", comment: "")
        }
    }
}

extension Error {
    var isRateLimited: Bool {
        self is RateLimitError
    }

    var retryAfterInterval: TimeInterval? {
        guard let rateLimitError = self as? RateLimitError,
              case let .rateLimited(interval) = rateLimitError else {
            return nil
        }
        return interval
    }
}

final class RateLimitInterceptor: ApolloInterceptor {
    let id = "RateLimitInterceptor"

    func interceptAsync<Operation: GraphQLOperation>(
        chain: any RequestChain,
        request: HTTPRequest<Operation>,
        response: HTTPResponse<Operation>?,
        completion: @escaping (Result<GraphQLResult<Operation.Data>, any Error>) -> Void
    ) {
        guard let httpResponse = response?.httpResponse else {
            chain.proceedAsync(request: request, response: response, interceptor: self, completion: completion)
            return
        }

        if httpResponse.statusCode == 429 {
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap(TimeInterval.init) ?? 60

            chain.handleErrorAsync(
                RateLimitError.rateLimited(retryAfter: retryAfter),
                request: request,
                response: response,
                completion: completion
            )
            return
        }

        chain.proceedAsync(request: request, response: response, interceptor: self, completion: completion)
    }
}
