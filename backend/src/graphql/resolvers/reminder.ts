/**
 * Reminder Confirmation Resolvers
 *
 * GraphQL resolvers for mandatory shift/session reminder confirmations.
 *
 * Queries:
 *   - myReminderConfirmations(eventId): Volunteer's own confirmations
 *   - shiftReminderStatus(shiftId): Per-shift compliance view (overseer)
 *
 * Mutations:
 *   - confirmShiftReminder(shiftId): Volunteer confirms shift reminder
 *   - confirmSessionReminder(sessionId): Fallback for non-shift departments
 *
 * Authorization:
 *   Volunteer mutations: requireAuth + attendant department check
 *   Overseer queries: requireAdmin + event access
 *
 * Used by: ./index.ts (resolver composition)
 */
import { Context } from '../context.js';
import { ReminderService } from '../../services/reminderService.js';
import { requireAuth, requireEventAccess, tryRequireAdmin, tryRequireDeptAccessByEvent } from '../guards/auth.js';
import { AuthorizationError } from '../../utils/errors.js';
import { confirmShiftReminderSchema, confirmSessionReminderSchema } from '../validators/reminder.js';

/**
 * Resolve the eventVolunteerId for the current user in the event that owns a shift.
 * Path: shiftId → session → eventId → EventVolunteer
 */
async function resolveVolunteerFromShift(
  context: Context,
  shiftId: string
): Promise<{ eventVolunteerId: string; eventId: string }> {
  if (!context.user) throw new AuthorizationError('You must be logged in');

  const shift = await context.prisma.shift.findUnique({
    where: { id: shiftId },
    include: { session: true },
  });
  if (!shift) throw new Error('Shift not found');

  const eventId = shift.session.eventId;
  const eventVolunteer = await context.prisma.eventVolunteer.findUnique({
    where: { userId_eventId: { userId: context.user.id, eventId } },
    include: { department: true },
  });

  if (!eventVolunteer || eventVolunteer.department?.departmentType !== 'ATTENDANT') {
    throw new AuthorizationError('Only attendant volunteers can confirm reminders');
  }

  return { eventVolunteerId: eventVolunteer.id, eventId };
}

/**
 * Resolve the eventVolunteerId for the current user in the event that owns a session.
 * Path: sessionId → eventId → EventVolunteer
 */
async function resolveVolunteerFromSession(
  context: Context,
  sessionId: string
): Promise<{ eventVolunteerId: string; eventId: string }> {
  if (!context.user) throw new AuthorizationError('You must be logged in');

  const session = await context.prisma.session.findUnique({
    where: { id: sessionId },
  });
  if (!session) throw new Error('Session not found');

  const eventId = session.eventId;
  const eventVolunteer = await context.prisma.eventVolunteer.findUnique({
    where: { userId_eventId: { userId: context.user.id, eventId } },
    include: { department: true },
  });

  if (!eventVolunteer || eventVolunteer.department?.departmentType !== 'ATTENDANT') {
    throw new AuthorizationError('Only attendant volunteers can confirm reminders');
  }

  return { eventVolunteerId: eventVolunteer.id, eventId };
}

const reminderResolvers = {
  Query: {
    myReminderConfirmations: async (
      _parent: unknown,
      { eventId }: { eventId: string },
      context: Context
    ) => {
      requireAuth(context);

      // Look up the user's EventVolunteer for this event
      const eventVolunteer = await context.prisma.eventVolunteer.findUnique({
        where: { userId_eventId: { userId: context.user!.id, eventId } },
      });
      if (!eventVolunteer) {
        throw new AuthorizationError('You are not a volunteer for this event');
      }

      const reminderService = new ReminderService(context.prisma);
      return reminderService.getMyConfirmations(eventVolunteer.id);
    },

    shiftReminderStatus: async (
      _parent: unknown,
      { shiftId }: { shiftId: string },
      context: Context
    ) => {
      requireAuth(context);

      // Verify event access via shift → session → event
      const shift = await context.prisma.shift.findUnique({
        where: { id: shiftId },
        include: { session: true },
      });
      if (!shift) throw new Error('Shift not found');

      if (tryRequireAdmin(context)) {
        await requireEventAccess(context, shift.session.eventId);
      } else {
        const access = await tryRequireDeptAccessByEvent(context, shift.session.eventId);
        if (!access) throw new AuthorizationError('Department access required');
      }

      const reminderService = new ReminderService(context.prisma);
      return reminderService.getShiftReminderStatus(shiftId);
    },
  },

  Mutation: {
    confirmShiftReminder: async (
      _parent: unknown,
      { shiftId }: { shiftId: string },
      context: Context
    ) => {
      requireAuth(context);
      confirmShiftReminderSchema.parse({ shiftId });

      const { eventVolunteerId } = await resolveVolunteerFromShift(context, shiftId);

      const reminderService = new ReminderService(context.prisma);
      return reminderService.confirmShiftReminder(eventVolunteerId, shiftId);
    },

    confirmSessionReminder: async (
      _parent: unknown,
      { sessionId }: { sessionId: string },
      context: Context
    ) => {
      requireAuth(context);
      confirmSessionReminderSchema.parse({ sessionId });

      const { eventVolunteerId } = await resolveVolunteerFromSession(context, sessionId);

      const reminderService = new ReminderService(context.prisma);
      return reminderService.confirmSessionReminder(eventVolunteerId, sessionId);
    },
  },
};

export default reminderResolvers;
