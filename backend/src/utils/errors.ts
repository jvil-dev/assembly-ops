/**
 * Custom GraphQL Errors
 *
 * Standardized error classes for consistent API error responses.
 * Each error extends GraphQLError with a specific error code.
 *
 * Error Classes:
 *   - AuthenticationError: User not logged in (401)
 *     Code: UNAUTHENTICATED
 *     Example: "You must be logged in as an admin"
 *
 *   - AuthorizationError: User lacks permission (403)
 *     Code: FORBIDDEN
 *     Example: "You do not have access to this event"
 *
 *   - NotFoundError: Resource doesn't exist (404)
 *     Code: NOT_FOUND
 *     Example: "Event not found"
 *
 *   - ValidationError: Invalid input data (400)
 *     Code: BAD_USER_INPUT
 *     Example: "Password must be at least 8 characters"
 *
 *   - ConflictError: Resource already exists (409)
 *     Code: CONFLICT
 *     Example: "An account with this email already exists"
 *
 * Usage:
 *   throw new AuthenticationError('Custom message');
 *   throw new NotFoundError('Event');  // → "Event not found"
 *
 * Used by: Services and guards throughout the app
 */
import { GraphQLError } from 'graphql';

export class AuthenticationError extends GraphQLError {
  constructor(message = 'Not authenticated') {
    super(message, { extensions: { code: 'UNAUTHENTICATED' } });
  }
}

export class AuthorizationError extends GraphQLError {
  constructor(message = 'Not authorized') {
    super(message, { extensions: { code: 'FORBIDDEN' } });
  }
}

export class NotFoundError extends GraphQLError {
  constructor(resource: string) {
    super(`${resource} not found`, { extensions: { code: 'NOT_FOUND' } });
  }
}

export class ValidationError extends GraphQLError {
  constructor(message: string) {
    super(message, { extensions: { code: 'BAD_USER_INPUT' } });
  }
}

export class ConflictError extends GraphQLError {
  constructor(message: string) {
    super(message, { extensions: { code: 'CONFLICT' } });
  }
}
