/**
 * Authorization Guards
 *
 * Guards check if the caller has permission before resolver logic runs.
 *
 *   requireUser()        — any authenticated User (volunteer or overseer)
 *   requireOverseer()    — User with isOverseer === true
 *   requireAdmin()       — alias for requireOverseer() (backward compat)
 *   requireAppAdmin()    — User with isAppAdmin === true
 *   requireAuth()        — alias for requireUser()
 *   requireEventAccess() — overseer must belong to the event (with optional role check)
 *
 * Helpers:
 *   resolveUserEventVolunteer() — look up the current user's EventVolunteer for an event
 */
import { Context } from '../context.js';
import { AuthenticationError, AuthorizationError } from '../../utils/errors.js';
import { EventRole, PrismaClient } from '@prisma/client';

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

export function requireAppAdmin(
  context: Context
): asserts context is Context & { user: NonNullable<Context['user']> } {
  if (!context.user) {
    throw new AuthenticationError('You must be logged in');
  }
  if (!context.user.isAppAdmin) {
    throw new AuthorizationError('App admin access required');
  }
}

// Backward-compat alias — existing resolvers calling requireAdmin() still work
export function requireAdmin(
  context: Context
): asserts context is Context & { user: NonNullable<Context['user']> } {
  requireOverseer(context);
}

// Alias for requireUser — all callers are Users now
export function requireAuth(context: Context): void {
  if (!context.user) {
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

/**
 * Look up the current user's EventVolunteer for a given event.
 * Used by resolvers that need the EventVolunteer ID (assignments, check-ins, etc.)
 */
export async function resolveUserEventVolunteer(
  userId: string,
  eventId: string,
  prisma: PrismaClient
): Promise<{ id: string; departmentId: string | null }> {
  const ev = await prisma.eventVolunteer.findUnique({
    where: { userId_eventId: { userId, eventId } },
    select: { id: true, departmentId: true },
  });

  if (!ev) {
    throw new AuthorizationError('You are not a volunteer for this event');
  }

  return ev;
}
