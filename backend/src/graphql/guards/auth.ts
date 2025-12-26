/**
 * Authorization Guards
 *
 * Guards are functions that check if a user has permission to perform an action.
 * They're called at the start of resolvers to protect sensitive operations.
 *
 * Available guards:
 *   - requireAdmin(): User must be logged in as an admin (overseer)
 *   - requireVolunteer(): User must be logged in as a volunteer
 *   - requireAuth(): User must be logged in as either admin or volunteer
 *   - requireEventAccess(): Admin must have access to a specific event
 *
 * How to use in a resolver:
 *   ```
 *   myResolver: async (_, args, context) => {
 *     requireAdmin(context);  // Throws if not admin
 *     // ... rest of resolver logic
 *   }
 *   ```
 *
 * Authentication vs Authorization:
 *   - Authentication: "Who are you?" (handled by context.ts via JWT)
 *   - Authorization: "Are you allowed to do this?" (handled by these guards)
 *
 * Used by: ./resolvers/* to protect queries and mutations
 */
import { Context } from '../context.js';
import { AuthenticationError, AuthorizationError } from '../../utils/errors.js';
import { EventRole } from '@prisma/client';

export function requireAdmin(
  context: Context
): asserts context is Context & { admin: NonNullable<Context['admin']> } {
  if (!context.admin) {
    throw new AuthenticationError('You must be logged in as an admin');
  }
}

export function requireVolunteer(
  context: Context
): asserts context is Context & { volunteer: NonNullable<Context['volunteer']> } {
  if (!context.volunteer) {
    throw new AuthenticationError('You must be logged in as a volunteer');
  }
}

export function requireAuth(context: Context): void {
  if (!context.admin && !context.volunteer) {
    throw new AuthenticationError('You must be logged in');
  }
}

export async function requireEventAccess(
  context: Context,
  eventId: string,
  allowedRoles?: EventRole[]
): Promise<void> {
  if (!context.admin) {
    throw new AuthenticationError('You must be logged in as an admin');
  }

  const eventAdmin = await context.prisma.eventAdmin.findUnique({
    where: {
      adminId_eventId: {
        adminId: context.admin.id,
        eventId,
      },
    },
  });

  if (!eventAdmin) {
    throw new AuthorizationError('You do not have access to this event');
  }

  if (allowedRoles && !allowedRoles.includes(eventAdmin.role)) {
    throw new AuthorizationError('You do not have permission for this action');
  }
}
