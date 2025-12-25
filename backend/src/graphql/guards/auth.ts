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
