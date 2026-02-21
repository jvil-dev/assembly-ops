/**
 * Attendant Resolvers
 *
 * GraphQL resolvers for attendant department features: safety incidents,
 * lost person alerts, and meetings.
 *
 * Authorization:
 *   - Meeting management: Admin auth + event access
 *   - Safety incidents/lost persons: Volunteer (report) or Admin (resolve)
 *
 * Query Resolvers:
 *   - safetyIncidents(eventId, resolved?): Safety incidents for an event
 *   - lostPersonAlerts(eventId, resolved?): Lost person alerts for an event
 *   - attendantMeetings(eventId): Meetings for an event
 *   - myAttendantMeetings(eventId): Volunteer's meetings
 *
 * Mutation Resolvers:
 *   - reportSafetyIncident: Volunteer reports incident
 *   - resolveSafetyIncident: Admin resolves incident
 *   - createLostPersonAlert: Volunteer reports lost person
 *   - resolveLostPersonAlert: Admin resolves alert
 *   - createAttendantMeeting: Create a meeting
 *   - updateAttendantMeetingNotes: Update meeting notes
 *   - deleteAttendantMeeting: Remove a meeting
 *
 * Used by: ./index.ts (resolver composition)
 */
import { Context } from '../context.js';
import { AttendantService } from '../../services/attendantService.js';
import { requireAdmin, requireVolunteer, requireEventAccess } from '../guards/auth.js';
import {
  ReportSafetyIncidentInput,
  CreateLostPersonAlertInput,
  CreateAttendantMeetingInput,
} from '../validators/attendant.js';
import { AuthorizationError } from '../../utils/errors.js';

/**
 * Helper: resolve the EventVolunteer record for the authenticated volunteer.
 *
 * Supports two auth paths:
 *   1. New auth (eventVolunteer token): context.volunteer.id IS the EventVolunteer.id
 *   2. Old auth (volunteer token): context.volunteer.id is legacy Volunteer.id —
 *      bridge to EventVolunteer via shared `volunteerId` field
 */
async function resolveAttendantVolunteer(
  context: Context,
  eventId: string
): Promise<{ volunteerId: string; eventVolunteerId: string }> {
  // Try as EventVolunteer first (new auth — context.volunteer.id = EventVolunteer.id)
  let eventVolunteer = await context.prisma.eventVolunteer.findUnique({
    where: { id: context.volunteer!.id },
    include: { department: true },
  });

  if (!eventVolunteer) {
    // Fallback: old Volunteer auth — bridge via shared volunteerId
    const volunteer = await context.prisma.volunteer.findUnique({
      where: { id: context.volunteer!.id },
      include: { department: true },
    });

    if (!volunteer || volunteer.department?.departmentType !== 'ATTENDANT') {
      throw new AuthorizationError('Only attendant volunteers can access this feature');
    }

    eventVolunteer = await context.prisma.eventVolunteer.findFirst({
      where: { volunteerId: volunteer.volunteerId, eventId },
      include: { department: true },
    });

    if (!eventVolunteer) {
      throw new AuthorizationError('Volunteer not found for this event');
    }
  }

  if (eventVolunteer.department?.departmentType !== 'ATTENDANT') {
    throw new AuthorizationError('Only attendant volunteers can access this feature');
  }

  return { volunteerId: eventVolunteer.volunteerId, eventVolunteerId: eventVolunteer.id };
}

const attendantResolvers = {
  Query: {
    safetyIncidents: async (
      _parent: unknown,
      { eventId, resolved }: { eventId: string; resolved?: boolean },
      context: Context
    ) => {
      requireAdmin(context);
      await requireEventAccess(context, eventId);

      const attendantService = new AttendantService(context.prisma);
      return attendantService.getSafetyIncidents(eventId, resolved);
    },

    lostPersonAlerts: async (
      _parent: unknown,
      { eventId, resolved }: { eventId: string; resolved?: boolean },
      context: Context
    ) => {
      requireAdmin(context);
      await requireEventAccess(context, eventId);

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
      requireVolunteer(context);

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
      requireVolunteer(context);

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

      return attendantService.resolveSafetyIncident(id, context.admin.id, resolutionNotes);
    },

    createLostPersonAlert: async (
      _parent: unknown,
      { input }: { input: CreateLostPersonAlertInput },
      context: Context
    ) => {
      requireVolunteer(context);

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

      return attendantService.resolveLostPersonAlert(id, context.admin.id, resolutionNotes);
    },

    createAttendantMeeting: async (
      _parent: unknown,
      { input }: { input: CreateAttendantMeetingInput },
      context: Context
    ) => {
      requireAdmin(context);
      await requireEventAccess(context, input.eventId);

      const attendantService = new AttendantService(context.prisma);
      return attendantService.createMeeting(context.admin.id, input);
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
};

export default attendantResolvers;
