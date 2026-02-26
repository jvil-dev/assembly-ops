/**
 * Authorization Guards
 *
 * Guards check if the caller has permission before resolver logic runs.
 *
 *   requireUser()        — any authenticated User (volunteer or overseer)
 *   requireOverseer()    — User with isOverseer === true
 *   requireAdmin()       — alias for requireOverseer() (backward compat)
 *   requireVolunteer()   — EventVolunteer printed-card session
 *   requireAuth()        — any authenticated caller (user or eventVolunteer)
 *   requireEventAccess() — overseer must belong to the event (with optional role check)
 *
 * Usage:
 *   myResolver: async (_, args, context) => {
 *     requireOverseer(context);
 *     // ...
 *   }
 */
import { Context } from '../context.js';
import { AuthenticationError, AuthorizationError } from '../../utils/errors.js';
import { EventRole } from '@prisma/client';

export function requireUser(
  context: Context
): asserts context is Context & { user: NonNullable<Context['user']> } {
  if (!context.user) {
    throw new AuthenticationError('You must be logged in');
  }
}

export function requireOverseer(
  context: Context
): asserts context is Context & { user: NonNullable<Context['user']> } {
  if (!context.user) {
    throw new AuthenticationError('You must be logged in');
  }
  if (!context.user.isOverseer) {
    throw new AuthorizationError('Overseer access required');
  }
}

// Backward-compat alias — existing resolvers calling requireAdmin() still work
export function requireAdmin(
  context: Context
): asserts context is Context & { user: NonNullable<Context['user']> } {
  requireOverseer(context);
}

export function requireVolunteer(
  context: Context
): asserts context is Context & { volunteer: NonNullable<Context['volunteer']> } {
  if (!context.volunteer) {
    throw new AuthenticationError('You must be logged in as an event volunteer');
  }
}

export function requireAuth(context: Context): void {
  if (!context.user && !context.volunteer) {
    throw new AuthenticationError('You must be logged in');
  }
}

export async function requireEventAccess(
  context: Context,
  eventId: string,
  allowedRoles?: EventRole[]
): Promise<void> {
  if (!context.user) {
    throw new AuthenticationError('You must be logged in');
  }

  const eventAdmin = await context.prisma.eventAdmin.findUnique({
    where: { userId_eventId: { userId: context.user.id, eventId } },
  });

  if (!eventAdmin) {
    throw new AuthorizationError('You do not have access to this event');
  }

  if (allowedRoles && !allowedRoles.includes(eventAdmin.role)) {
    throw new AuthorizationError('You do not have permission for this action');
  }
}
