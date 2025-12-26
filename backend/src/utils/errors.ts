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
