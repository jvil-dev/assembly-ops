/**
 * Attendant Resolvers
 *
 * GraphQL resolvers for attendant department features: safety incidents,
 * lost person alerts, and meetings.
 *
 * Authorization:
 *   - Meeting management: Overseer auth + event access
 *   - Safety incidents/lost persons: Volunteer (report) or Overseer (resolve)
 *
 * Query Resolvers:
 *   - safetyIncidents(eventId, resolved?): Safety incidents for an event
 *   - lostPersonAlerts(eventId, resolved?): Lost person alerts for an event
 *   - attendantMeetings(eventId): Meetings for an event
 *   - myAttendantMeetings(eventId): Volunteer's meetings
 *
 * Mutation Resolvers:
 *   - reportSafetyIncident: Volunteer reports incident
 *   - resolveSafetyIncident: Overseer resolves incident
 *   - createLostPersonAlert: Volunteer reports lost person
 *   - resolveLostPersonAlert: Overseer resolves alert
 *   - createAttendantMeeting: Create a meeting
 *   - updateAttendantMeetingNotes: Update meeting notes
 *   - deleteAttendantMeeting: Remove a meeting
 *
 * Used by: ./index.ts (resolver composition)
 */
import { Context } from '../context.js';
import { AttendantService } from '../../services/attendantService.js';
import { requireAdmin, requireAuth, requireEventAccess } from '../guards/auth.js';
import { decryptField } from '../../utils/encryption.js';
import {
  ReportSafetyIncidentInput,
  CreateLostPersonAlertInput,
  CreateAttendantMeetingInput,
} from '../validators/attendant.js';
import { AuthorizationError } from '../../utils/errors.js';

/**
 * Helper: resolve the EventVolunteer record for the authenticated user.
 *
 * Looks up the user's EventVolunteer for the given event and verifies
 * they belong to the ATTENDANT department.
 */
async function resolveAttendantVolunteer(
  context: Context,
  eventId: string
): Promise<{ eventVolunteerId: string }> {
  if (!context.user) throw new AuthorizationError('You must be logged in');
  const eventVolunteer = await context.prisma.eventVolunteer.findUnique({
    where: { userId_eventId: { userId: context.user.id, eventId } },
    include: { department: true },
  });

  if (!eventVolunteer || eventVolunteer.department?.departmentType !== 'ATTENDANT') {
    throw new AuthorizationError('Only attendant volunteers can access this feature');
  }

  return { eventVolunteerId: eventVolunteer.id };
}

const attendantResolvers = {
  Query: {
    safetyIncidents: async (
      _parent: unknown,
      { eventId, resolved }: { eventId: string; resolved?: boolean },
      context: Context
    ) => {
      requireAuth(context);
      const eventAdmin = await context.prisma.eventAdmin.findUnique({
        where: { userId_eventId: { userId: context.user!.id, eventId } },
      });
      if (!eventAdmin) {
        await resolveAttendantVolunteer(context, eventId);
      }

      const attendantService = new AttendantService(context.prisma);
      return attendantService.getSafetyIncidents(eventId, resolved);
    },

    lostPersonAlerts: async (
      _parent: unknown,
      { eventId, resolved }: { eventId: string; resolved?: boolean },
      context: Context
    ) => {
      requireAuth(context);
      const eventAdmin = await context.prisma.eventAdmin.findUnique({
        where: { userId_eventId: { userId: context.user!.id, eventId } },
      });
      if (!eventAdmin) {
        await resolveAttendantVolunteer(context, eventId);
      }

      const attendantService = new AttendantService(context.prisma);
      return attendantService.getLostPersonAlerts(eventId, resolved);
    },

    attendantMeetings: async (
      _parent: unknown,
      { eventId }: { eventId: string },
      context: Context
    ) => {
      requireAdmin(context);
      await requireEventAccess(context, eventId);

      const attendantService = new AttendantService(context.prisma);
      return attendantService.getMeetings(eventId);
    },

    myAttendantMeetings: async (
      _parent: unknown,
      { eventId }: { eventId: string },
      context: Context
    ) => {
      requireAuth(context);

      const { eventVolunteerId } = await resolveAttendantVolunteer(context, eventId);

      const attendantService = new AttendantService(context.prisma);
      return attendantService.getMyMeetings(eventVolunteerId);
    },
  },

  Mutation: {
    reportSafetyIncident: async (
      _parent: unknown,
      { input }: { input: ReportSafetyIncidentInput },
      context: Context
    ) => {
      requireAuth(context);

      const { eventVolunteerId } = await resolveAttendantVolunteer(context, input.eventId);

      const attendantService = new AttendantService(context.prisma);
      return attendantService.reportSafetyIncident(eventVolunteerId, input);
    },

    resolveSafetyIncident: async (
      _parent: unknown,
      { id, resolutionNotes }: { id: string; resolutionNotes?: string },
      context: Context
    ) => {
      requireAdmin(context);

      const attendantService = new AttendantService(context.prisma);
      const eventId = await attendantService.getIncidentEventId(id);
      await requireEventAccess(context, eventId);

      return attendantService.resolveSafetyIncident(id, context.user!.id, resolutionNotes);
    },

    createLostPersonAlert: async (
      _parent: unknown,
      { input }: { input: CreateLostPersonAlertInput },
      context: Context
    ) => {
      requireAuth(context);

      const { eventVolunteerId } = await resolveAttendantVolunteer(context, input.eventId);

      const attendantService = new AttendantService(context.prisma);
      return attendantService.createLostPersonAlert(eventVolunteerId, input);
    },

    resolveLostPersonAlert: async (
      _parent: unknown,
      { id, resolutionNotes }: { id: string; resolutionNotes: string },
      context: Context
    ) => {
      requireAdmin(context);

      const attendantService = new AttendantService(context.prisma);
      const eventId = await attendantService.getAlertEventId(id);
      await requireEventAccess(context, eventId);

      return attendantService.resolveLostPersonAlert(id, context.user!.id, resolutionNotes);
    },

    createAttendantMeeting: async (
      _parent: unknown,
      { input }: { input: CreateAttendantMeetingInput },
      context: Context
    ) => {
      requireAdmin(context);
      await requireEventAccess(context, input.eventId);

      const attendantService = new AttendantService(context.prisma);
      return attendantService.createMeeting(context.user!.id, input);
    },

    updateAttendantMeetingNotes: async (
      _parent: unknown,
      { id, notes }: { id: string; notes: string },
      context: Context
    ) => {
      requireAdmin(context);

      const attendantService = new AttendantService(context.prisma);
      const eventId = await attendantService.getMeetingEventId(id);
      await requireEventAccess(context, eventId);

      return attendantService.updateMeetingNotes(id, notes);
    },

    deleteAttendantMeeting: async (
      _parent: unknown,
      { id }: { id: string },
      context: Context
    ) => {
      requireAdmin(context);

      const attendantService = new AttendantService(context.prisma);
      const eventId = await attendantService.getMeetingEventId(id);
      await requireEventAccess(context, eventId);

      return attendantService.deleteMeeting(id);
    },
  },

  // Type resolvers: decrypt PII fields for GraphQL responses
  LostPersonAlert: {
    personName: (parent: Record<string, unknown>) => {
      return decryptField(parent.encryptedPersonName as string);
    },
    contactName: (parent: Record<string, unknown>) => {
      return decryptField(parent.encryptedContactName as string);
    },
    contactPhone: (parent: Record<string, unknown>) => {
      const encrypted = parent.encryptedContactPhone as string | null;
      return encrypted ? decryptField(encrypted) : null;
    },
  },
};

export default attendantResolvers;
