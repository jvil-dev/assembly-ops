/**
 * Volunteer Resolvers
 *
 * Handles EventVolunteer management: create, update, delete, credentials.
 * All volunteers are now Users with per-event EventVolunteer records.
 *
 * Queries:
 *   - volunteer: Get a single EventVolunteer by ID
 *   - volunteers: Get all EventVolunteers for an event (optionally filtered by department)
 *   - myVolunteerProfile: Get the logged-in volunteer's own EventVolunteer record
 *   - volunteerToken: Get decrypted token for an EventVolunteer
 *   - roles: Get all roles for an event
 *
 * Mutations:
 *   - createVolunteer: Add one EventVolunteer, returns login credentials
 *   - createVolunteers: Bulk add, returns all credentials
 *   - updateVolunteer: Update EventVolunteer details (includes department removal cleanup)
 *   - regenerateVolunteerCredentials: Generate new login credentials
 *   - requestToJoinEvent: Volunteer requests to join an event
 *   - cancelJoinRequest: Cancel a pending join request
 *   - approveJoinRequest: Overseer approves a join request
 *   - denyJoinRequest: Overseer denies a join request
 *
 * Additional Queries:
 *   - myJoinRequests: Get the current user's join requests
 *   - eventJoinRequests: Get all join requests for an event (overseer)
 *
 * Authorization:
 *   - Most operations require overseer + event access
 *   - myVolunteerProfile requires volunteer login
 *
 * Dependencies:
 *   - VolunteerService (../../services/volunteerService.ts): Business logic
 *   - Guards (../guards/auth.ts): requireAdmin, requireVolunteer, requireEventAccess
 *
 * Schema: ../schema/volunteer.ts
 */
import { Context } from '../context.js';
import { VolunteerService, CreatedVolunteer } from '../../services/volunteerService.js';
import { NotificationService } from '../../services/notificationService.js';
import { requireAdmin, requireOverseer, requireUser, requireAuth, requireEventAccess, tryRequireAdmin, tryRequireDeptAccessByEvent } from '../guards/auth.js';
import { AuthorizationError } from '../../utils/errors.js';
import {
  CreateVolunteerInput,
  CreateVolunteersInput,
  updateMyProfileSchema,
  UpdateMyProfileInput,
} from '../validators/volunteer.js';

const volunteerResolvers = {
  // Type resolver: maps EventVolunteer (Prisma) → Volunteer (GraphQL)
  // EventVolunteer stores user data via .user relation; GraphQL Volunteer type expects flat fields.
  Volunteer: {
    userId: (parent: Record<string, unknown>) =>
      (parent as { user?: { userId?: string } }).user?.userId ?? '',
    firstName: (parent: Record<string, unknown>) =>
      (parent as { user?: { firstName?: string } }).user?.firstName ?? parent.firstName,
    lastName: (parent: Record<string, unknown>) =>
      (parent as { user?: { lastName?: string } }).user?.lastName ?? parent.lastName,
    fullName: (parent: Record<string, unknown>) => {
      const user = (parent as { user?: { firstName?: string; lastName?: string } }).user;
      if (user) return `${user.firstName} ${user.lastName}`;
      return (parent as { fullName?: string }).fullName ?? '';
    },
    email: (parent: Record<string, unknown>) =>
      (parent as { user?: { email?: string } }).user?.email ?? parent.email,
    phone: (parent: Record<string, unknown>) =>
      (parent as { user?: { phone?: string } }).user?.phone ?? parent.phone,
    congregation: (parent: Record<string, unknown>) =>
      (parent as { user?: { congregation?: string } }).user?.congregation ?? parent.congregation ?? '',
    appointmentStatus: (parent: Record<string, unknown>) =>
      (parent as { user?: { appointmentStatus?: string } }).user?.appointmentStatus ?? parent.appointmentStatus,
    notes: (parent: Record<string, unknown>) =>
      (parent as { user?: { notes?: string } }).user?.notes ?? parent.notes,
    isPlaceholder: (parent: Record<string, unknown>) =>
      (parent as { user?: { isPlaceholder?: boolean } }).user?.isPlaceholder ?? false,
  },

  Query: {
    volunteer: async (_parent: unknown, { id }: { id: string }, context: Context) => {
      requireAdmin(context);
      const volunteerService = new VolunteerService(context.prisma);
      const volunteer = await volunteerService.getVolunteer(id);
      if (volunteer) {
        await requireEventAccess(context, volunteer.eventId);
      }
      return volunteer;
    },

    volunteers: async (
      _parent: unknown,
      { eventId, departmentId }: { eventId: string; departmentId?: string },
      context: Context
    ) => {
      requireAuth(context);
      if (tryRequireAdmin(context)) {
        await requireEventAccess(context, eventId);
      } else {
        // Non-overseer: must be dept assistant overseer OR accepted area captain
        const deptAccess = await tryRequireDeptAccessByEvent(context, eventId);
        if (!deptAccess) {
          // Check if user is a captain in the requested department
          // (via AreaCaptain record OR ScheduleAssignment.isCaptain)
          const ev = await context.prisma.eventVolunteer.findFirst({
            where: {
              userId: context.user!.id,
              event: { departments: { some: { id: departmentId } } },
            },
            select: { id: true },
          });
          if (!ev) throw new AuthorizationError('Not authorized');
          const [areaCaptain, captainAssignment] = await Promise.all([
            context.prisma.areaCaptain.findFirst({
              where: {
                eventVolunteerId: ev.id,
                area: { departmentId },
                status: 'ACCEPTED',
              },
            }),
            context.prisma.scheduleAssignment.findFirst({
              where: {
                eventVolunteerId: ev.id,
                isCaptain: true,
                post: { departmentId },
              },
            }),
          ]);
          if (!areaCaptain && !captainAssignment) throw new AuthorizationError('Not authorized');
        }
      }
      const volunteerService = new VolunteerService(context.prisma);
      return volunteerService.getEventVolunteers(eventId, departmentId);
    },

    myVolunteerProfile: async (_parent: unknown, _args: unknown, context: Context) => {
      requireUser(context);

      const eventVolunteer = await context.prisma.eventVolunteer.findFirst({
        where: { userId: context.user!.id },
        orderBy: { createdAt: 'desc' },
        include: {
          user: true,
          event: true,
          department: true,
          role: true,
        },
      });

      if (!eventVolunteer) return null;

      const user = eventVolunteer.user;
      return {
        id: eventVolunteer.id,
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        phone: user.phone,
        congregation: user.congregation || '',
        appointmentStatus: user.appointmentStatus,
        eventId: eventVolunteer.eventId,
        event: eventVolunteer.event,
        department: eventVolunteer.department,
        departmentId: eventVolunteer.departmentId,
        role: eventVolunteer.role,
        roleId: eventVolunteer.roleId,
        assignments: [],
        createdAt: eventVolunteer.createdAt,
      };
    },

    roles: async (_parent: unknown, { eventId }: { eventId: string }, context: Context) => {
      requireAdmin(context);
      await requireEventAccess(context, eventId);
      return context.prisma.role.findMany({
        where: { eventId },
        orderBy: { sortOrder: 'asc' },
      });
    },

    // ── Join Request Queries ──────────────────────────────────────────────

    myJoinRequests: async (_parent: unknown, _args: unknown, context: Context) => {
      requireUser(context);
      const volunteerService = new VolunteerService(context.prisma);
      return volunteerService.getMyJoinRequests(context.user!.id);
    },

    eventJoinRequests: async (
      _parent: unknown,
      { eventId, status }: { eventId: string; status?: string },
      context: Context
    ) => {
      requireOverseer(context);
      await requireEventAccess(context, eventId);
      const volunteerService = new VolunteerService(context.prisma);
      return volunteerService.getEventJoinRequests(eventId, status);
    },
  },

  Mutation: {
    createVolunteer: async (
      _parent: unknown,
      { eventId, input }: { eventId: string; input: CreateVolunteerInput },
      context: Context
    ): Promise<CreatedVolunteer> => {
      requireAdmin(context);
      await requireEventAccess(context, eventId);

      // Get admin's department in this event
      const eventAdmin = await context.prisma.eventAdmin.findUnique({
        where: {
          userId_eventId: {
            userId: context.user!.id,
            eventId,
          },
        },
      });

      const volunteerService = new VolunteerService(context.prisma);
      return volunteerService.createVolunteer(
        eventId,
        input,
        eventAdmin?.departmentId || undefined
      );
    },

    createVolunteers: async (
      _parent: unknown,
      { input }: { input: CreateVolunteersInput },
      context: Context
    ): Promise<CreatedVolunteer[]> => {
      requireAdmin(context);
      await requireEventAccess(context, input.eventId);

      // Get admin's department in this event
      const eventAdmin = await context.prisma.eventAdmin.findUnique({
        where: {
          userId_eventId: {
            userId: context.user!.id,
            eventId: input.eventId,
          },
        },
      });

      const volunteerService = new VolunteerService(context.prisma);
      return volunteerService.createVolunteers(input, eventAdmin?.departmentId || undefined);
    },

    updateVolunteer: async (
      _parent: unknown,
      { id, input }: { id: string; input: Partial<CreateVolunteerInput> },
      context: Context
    ) => {
      requireAdmin(context);

      // Get EventVolunteer to check event access
      const eventVolunteer = await context.prisma.eventVolunteer.findUnique({
        where: { id },
        select: { eventId: true },
      });

      if (eventVolunteer) {
        await requireEventAccess(context, eventVolunteer.eventId);
      }

      const volunteerService = new VolunteerService(context.prisma);
      return volunteerService.updateVolunteer(id, input);
    },

    updateMyProfile: async (
      _parent: unknown,
      { input }: { input: UpdateMyProfileInput },
      context: Context
    ) => {
      requireUser(context);

      const validated = updateMyProfileSchema.parse(input);

      const eventVolunteer = await context.prisma.eventVolunteer.findFirst({
        where: { userId: context.user!.id },
        orderBy: { createdAt: 'desc' },
        include: {
          user: true,
          event: true,
          department: true,
          role: true,
        },
      });

      if (!eventVolunteer) {
        throw new Error('Volunteer not found');
      }

      const updatedUser = await context.prisma.user.update({
        where: { id: eventVolunteer.userId },
        data: {
          ...(validated.phone != null && { phone: validated.phone }),
          ...(validated.email != null && { email: validated.email }),
        },
      });

      return {
        id: eventVolunteer.id,
        firstName: updatedUser.firstName,
        lastName: updatedUser.lastName,
        email: updatedUser.email,
        phone: updatedUser.phone,
        congregation: updatedUser.congregation || '',
        appointmentStatus: updatedUser.appointmentStatus,
        eventId: eventVolunteer.eventId,
        event: eventVolunteer.event,
        department: eventVolunteer.department,
        departmentId: eventVolunteer.departmentId,
        role: eventVolunteer.role,
        roleId: eventVolunteer.roleId,
        assignments: [],
        createdAt: eventVolunteer.createdAt,
      };
    },

    // ── Join Request Mutations ──────────────────────────────────────────────

    requestToJoinEvent: async (
      _parent: unknown,
      { eventId, departmentType, note }: { eventId: string; departmentType?: string; note?: string },
      context: Context
    ) => {
      requireUser(context);
      const volunteerService = new VolunteerService(context.prisma);
      const request = await volunteerService.requestToJoinEvent(eventId, context.user!.id, departmentType, note);

      // Notify all event overseers
      const eventAdmins = await context.prisma.eventAdmin.findMany({
        where: { eventId },
        select: { userId: true },
      });
      if (eventAdmins.length > 0) {
        const overseerUserIds = eventAdmins.map((a) => a.userId);
        const notificationService = new NotificationService(context.prisma);
        notificationService.sendToUsers(overseerUserIds, eventId, {
          title: 'New Join Request',
          body: `${request.user.firstName} ${request.user.lastName} wants to join ${request.event.name}`,
          data: { type: 'JOIN_REQUEST_SUBMITTED', eventId, requestId: request.id },
        }).catch(() => {});
      }

      return request;
    },

    cancelJoinRequest: async (
      _parent: unknown,
      { requestId }: { requestId: string },
      context: Context
    ) => {
      requireUser(context);
      const volunteerService = new VolunteerService(context.prisma);
      await volunteerService.cancelJoinRequest(requestId, context.user!.id);
      return true;
    },

    approveJoinRequest: async (
      _parent: unknown,
      { requestId }: { requestId: string },
      context: Context
    ) => {
      requireOverseer(context);
      const volunteerService = new VolunteerService(context.prisma);
      const approved = await volunteerService.approveJoinRequest(requestId, context.user!.id);

      // Notify the requesting volunteer
      const approvedRequest = await context.prisma.eventJoinRequest.findUnique({
        where: { id: requestId },
        include: { event: { select: { name: true } } },
      });
      if (approvedRequest) {
        const notificationService = new NotificationService(context.prisma);
        notificationService.sendToUser(approvedRequest.userId, approvedRequest.eventId, {
          title: 'Join Request Approved',
          body: `You've been accepted to ${approvedRequest.event.name}`,
          data: { type: 'JOIN_REQUEST_APPROVED', eventId: approvedRequest.eventId, requestId },
        }).catch(() => {});
      }

      return approved;
    },

    denyJoinRequest: async (
      _parent: unknown,
      { requestId, reason }: { requestId: string; reason?: string },
      context: Context
    ) => {
      requireOverseer(context);
      const volunteerService = new VolunteerService(context.prisma);
      const denied = await volunteerService.denyJoinRequest(requestId, context.user!.id, reason);

      // Notify the requesting volunteer
      const notificationService = new NotificationService(context.prisma);
      notificationService.sendToUser(denied.userId, denied.eventId, {
        title: 'Join Request Denied',
        body: `Your request to join ${denied.event.name} was not approved`,
        data: { type: 'JOIN_REQUEST_DENIED', eventId: denied.eventId, requestId },
      }).catch(() => {});

      return denied;
    },

    linkPlaceholderUser: async (
      _parent: unknown,
      { placeholderUserId, realUserId }: { placeholderUserId: string; realUserId: string },
      context: Context
    ) => {
      requireAdmin(context);
      const volunteerService = new VolunteerService(context.prisma);
      return volunteerService.linkPlaceholderUser(placeholderUserId, realUserId);
    },
  },

};

export default volunteerResolvers;
