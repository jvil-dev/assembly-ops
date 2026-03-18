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
 *   requireAreaOverseer() — volunteer must have AREA_OVERSEER role for the post's area
 *   requireAreaCaptainAccess() — volunteer must be an accepted area captain for the post's area
 *
 * Helpers:
 *   tryRequireAdmin()           — non-throwing admin check (returns boolean)
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

/**
 * Require that the current user is a captain for the given event.
 * A captain is any volunteer with isCaptain=true on any ScheduleAssignment.
 * Overseers with event access bypass the captain check.
 */
export async function requireCaptain(
  context: Context,
  eventId: string
): Promise<{ eventVolunteerId: string; departmentId: string }> {
  requireAuth(context);

  // Overseers with event access bypass the captain check
  if (context.user!.isOverseer) {
    const eventAdmin = await context.prisma.eventAdmin.findUnique({
      where: { userId_eventId: { userId: context.user!.id, eventId } },
    });

    if (eventAdmin) {
      const ev = await context.prisma.eventVolunteer.findUnique({
        where: { userId_eventId: { userId: context.user!.id, eventId } },
      });

      return {
        eventVolunteerId: ev?.id ?? eventAdmin.userId,
        departmentId: eventAdmin.departmentId!,
      };
    }
  }

  const eventVolunteer = await context.prisma.eventVolunteer.findUnique({
    where: { userId_eventId: { userId: context.user!.id, eventId } },
  });

  if (!eventVolunteer || !eventVolunteer.departmentId) {
    throw new AuthorizationError('Not a department volunteer for this event');
  }

  // Check ScheduleAssignment.isCaptain OR accepted AreaCaptain assignment
  const [captainAssignment, areaCaptain] = await Promise.all([
    context.prisma.scheduleAssignment.findFirst({
      where: {
        eventVolunteerId: eventVolunteer.id,
        isCaptain: true,
      },
    }),
    context.prisma.areaCaptain.findFirst({
      where: {
        eventVolunteerId: eventVolunteer.id,
        status: 'ACCEPTED',
      },
    }),
  ]);

  if (!captainAssignment && !areaCaptain) {
    throw new AuthorizationError('Captain access required');
  }

  return {
    eventVolunteerId: eventVolunteer.id,
    departmentId: eventVolunteer.departmentId,
  };
}

/**
 * Require that the current user has department-level management access.
 * Returns true if:
 *   1. User is the department's EventAdmin (DEPARTMENT_OVERSEER), OR
 *   2. User has ASSISTANT_OVERSEER role in DepartmentHierarchy for that department
 *
 * Returns the eventId, userId, and whether they are the primary overseer.
 */
export async function requireDeptAccess(
  context: Context,
  departmentId: string
): Promise<{ eventId: string; userId: string; isOverseer: boolean }> {
  requireUser(context);

  const department = await context.prisma.department.findUnique({
    where: { id: departmentId },
    select: { eventId: true, overseer: { select: { userId: true } } },
  });

  if (!department) {
    throw new AuthorizationError('Department not found');
  }

  // Path 1: Department Overseer (via EventAdmin)
  if (department.overseer?.userId === context.user!.id) {
    return { eventId: department.eventId, userId: context.user!.id, isOverseer: true };
  }

  // Path 2: Assistant Overseer (via DepartmentHierarchy)
  const ev = await context.prisma.eventVolunteer.findUnique({
    where: { userId_eventId: { userId: context.user!.id, eventId: department.eventId } },
    select: { id: true },
  });

  if (ev) {
    const hierarchy = await context.prisma.departmentHierarchy.findFirst({
      where: {
        departmentId,
        eventVolunteerId: ev.id,
        hierarchyRole: 'ASSISTANT_OVERSEER',
      },
    });

    if (hierarchy) {
      return { eventId: department.eventId, userId: context.user!.id, isOverseer: false };
    }
  }

  throw new AuthorizationError('Department overseer or assistant overseer access required');
}

/**
 * Check if the current user has department-level access for an event.
 * Resolves the user's department from their EventVolunteer record, then
 * checks DepartmentHierarchy for ASSISTANT_OVERSEER.
 *
 * Returns null if the user is not an assistant overseer for any department in this event.
 * Used as a fallback after requireAdmin + requireEventAccess fails.
 */
export async function tryRequireDeptAccessByEvent(
  context: Context,
  eventId: string
): Promise<{ departmentId: string; userId: string } | null> {
  if (!context.user) return null;

  const ev = await context.prisma.eventVolunteer.findUnique({
    where: { userId_eventId: { userId: context.user.id, eventId } },
    select: { id: true, departmentId: true },
  });

  if (!ev?.departmentId) return null;

  const hierarchy = await context.prisma.departmentHierarchy.findFirst({
    where: {
      departmentId: ev.departmentId,
      eventVolunteerId: ev.id,
      hierarchyRole: 'ASSISTANT_OVERSEER',
    },
  });

  if (!hierarchy) return null;

  return { departmentId: ev.departmentId, userId: context.user.id };
}

/**
 * Non-throwing admin check — returns true if the user is an overseer, false otherwise.
 * Used for dual-auth patterns where either admin OR area overseer can proceed.
 */
export function tryRequireAdmin(context: Context): boolean {
  return !!(context.user && context.user.isOverseer);
}

/**
 * Require that the current user is an AREA_OVERSEER for the area containing the given post.
 * Used for delegated scheduling — crew/zone overseers schedule within their area only.
 */
export async function requireAreaOverseer(
  context: Context,
  postId: string
): Promise<{ eventVolunteerId: string; areaId: string }> {
  requireAuth(context);

  const post = await context.prisma.post.findUnique({
    where: { id: postId },
    select: { areaId: true },
  });
  if (!post?.areaId) {
    throw new AuthorizationError('Post is not assigned to an area');
  }

  const ev = await context.prisma.eventVolunteer.findFirst({
    where: { userId: context.user!.id },
    select: { id: true },
  });
  if (!ev) {
    throw new AuthorizationError('Not a volunteer');
  }

  const hierarchy = await context.prisma.departmentHierarchy.findFirst({
    where: {
      eventVolunteerId: ev.id,
      hierarchyRole: 'AREA_OVERSEER',
      areaId: post.areaId,
    },
  });
  if (!hierarchy) {
    throw new AuthorizationError('Not an area overseer for this crew');
  }

  return { eventVolunteerId: ev.id, areaId: post.areaId };
}

/**
 * Require that the current user is an accepted area captain for the area containing the given post.
 * Used as a fallback after requireAreaOverseer fails — allows captains to manage assignments/shifts
 * within their assigned areas.
 */
export async function requireAreaCaptainAccess(
  context: Context,
  postId: string
): Promise<void> {
  const post = await context.prisma.post.findUnique({
    where: { id: postId },
    select: { areaId: true, departmentId: true },
  });
  if (!post?.areaId) throw new AuthorizationError('Not authorized');

  const ev = await context.prisma.eventVolunteer.findFirst({
    where: {
      userId: context.user!.id,
      event: { departments: { some: { id: post.departmentId } } },
    },
    select: { id: true },
  });
  if (!ev) throw new AuthorizationError('Not authorized');

  const captainAccess = await context.prisma.areaCaptain.findFirst({
    where: { eventVolunteerId: ev.id, areaId: post.areaId, status: 'ACCEPTED' },
  });
  if (!captainAccess) throw new AuthorizationError('Not authorized');
}
