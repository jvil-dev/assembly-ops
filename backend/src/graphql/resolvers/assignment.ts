/**
 * Assignment Resolvers
 *
 * GraphQL resolvers for schedule assignment operations.
 * Handles the connection between GraphQL queries/mutations and AssignmentService.
 *
 * Authorization:
 *   - Most operations require Overseer auth + event access
 *   - myAssignments, acceptAssignment, declineAssignment require Volunteer auth
 *   - Captain check-in requires volunteer to be a captain
 *
 * Query Resolvers:
 *   - assignment, assignments: Get assignments by ID or event
 *   - volunteerAssignments, sessionAssignments, postAssignments: Filtered queries
 *   - myAssignments: Volunteer's own schedule (with optional status filter)
 *   - pendingAssignments, declinedAssignments: Overseer queries for assignment status
 *   - captainGroup: Get volunteers at same post/session as captain
 *   - departmentCoverage, departmentCoverageGaps: Coverage matrix (ACCEPTED only)
 *
 * Mutation Resolvers:
 *   - createAssignment: Create single (PENDING status)
 *   - createAssignments: Bulk create
 *   - acceptAssignment, declineAssignment: Volunteer response to assignment
 *   - forceAssignment: Overseer bypasses acceptance (auto-ACCEPTED)
 *   - setCaptain: Designate assignment as captain
 *   - captainCheckIn: Captain checks in group member
 *   - updateAssignment, deleteAssignment: Modify or remove
 *
 * Type Resolvers:
 *   - ScheduleAssignment.isCheckedIn: Computed field (true if checkIn exists)
 *
 * Used by: ./index.ts (resolver composition)
 */
import { ScheduleAssignment } from '@prisma/client';
import { GraphQLError } from 'graphql';
import { Context } from '../context.js';
import { AssignmentService } from '../../services/assignmentService.js';
import { requireAdmin, requireVolunteer, requireEventAccess } from '../guards/auth.js';
import {
  CreateAssignmentInput,
  UpdateAssignmentInput,
  AcceptAssignmentInput,
  DeclineAssignmentInput,
  ForceAssignmentInput,
  SetCaptainInput,
  CaptainCheckInInput,
  PendingAssignmentsFilter,
} from '../validators/assignment.js';

const assignmentResolvers = {
  Query: {
    assignment: async (_parent: unknown, { id }: { id: string }, context: Context) => {
      requireAdmin(context);
      const assignmentService = new AssignmentService(context.prisma);
      return assignmentService.getAssignments(id);
    },

    assignments: async (
      _parent: unknown,
      {
        eventId,
        departmentId,
        sessionId,
        volunteerId,
      }: {
        eventId?: string;
        departmentId?: string;
        sessionId?: string;
        volunteerId?: string;
      },
      context: Context
    ) => {
      requireAdmin(context);
      if (eventId) {
        await requireEventAccess(context, eventId);
      }
      const assignmentService = new AssignmentService(context.prisma);

      // Use the appropriate service method based on filter provided
      if (volunteerId) {
        return assignmentService.getVolunteerAssignments(volunteerId);
      }
      if (sessionId) {
        return assignmentService.getSessionAssignments(sessionId);
      }
      if (eventId) {
        return assignmentService.getEventAssignments(eventId);
      }
      // If only departmentId, get all posts in department and their assignments
      if (departmentId) {
        const posts = await context.prisma.post.findMany({
          where: { departmentId },
          select: { id: true },
        });
        return context.prisma.scheduleAssignment.findMany({
          where: { postId: { in: posts.map((p) => p.id) } },
          include: {
            eventVolunteer: true,
            post: { include: { department: true } },
            session: true,
            checkIn: true,
          },
        });
      }
      return [];
    },

    volunteerAssignments: async (
      _parent: unknown,
      { volunteerId }: { volunteerId: string },
      context: Context
    ) => {
      requireAdmin(context);
      const assignmentService = new AssignmentService(context.prisma);
      return assignmentService.getVolunteerAssignments(volunteerId);
    },

    myAssignments: async (_parent: unknown, { status }: { status?: string }, context: Context) => {
      requireVolunteer(context);
      const assignmentService = new AssignmentService(context.prisma);
      return assignmentService.getVolunteerAssignments(context.volunteer.id, status);
    },

    pendingAssignments: async (
      _parent: unknown,
      { filter }: { filter?: PendingAssignmentsFilter },
      context: Context
    ) => {
      requireAdmin(context);
      if (filter?.eventId) {
        await requireEventAccess(context, filter.eventId);
      }
      const assignmentService = new AssignmentService(context.prisma);
      return assignmentService.getPendingAssignments(filter ?? {});
    },

    declinedAssignments: async (
      _parent: unknown,
      { eventId, departmentId }: { eventId?: string; departmentId?: string },
      context: Context
    ) => {
      requireAdmin(context);
      if (eventId) {
        await requireEventAccess(context, eventId);
      }
      const assignmentService = new AssignmentService(context.prisma);
      return assignmentService.getDeclinedAssignments(eventId, departmentId);
    },

    captainGroup: async (
      _parent: unknown,
      { postId, sessionId }: { postId: string; sessionId: string },
      context: Context
    ) => {
      requireVolunteer(context);
      const assignmentService = new AssignmentService(context.prisma);

      // Get captain assignment
      const captainAssignment = await context.prisma.scheduleAssignment.findFirst({
        where: {
          eventVolunteerId: context.volunteer.id,
          postId,
          sessionId,
          isCaptain: true,
        },
        include: {
          eventVolunteer: { include: { user: true } },
          post: { include: { department: true } },
          session: true,
          checkIn: true,
        },
      });

      if (!captainAssignment) {
        return null;
      }

      const members = await assignmentService.getCaptainGroup(
        context.volunteer.id,
        postId,
        sessionId
      );

      return {
        captain: captainAssignment,
        members,
      };
    },

    departmentCoverage: async (
      _parent: unknown,
      { departmentId }: { departmentId: string },
      context: Context
    ) => {
      requireAdmin(context);
      const dept = await context.prisma.department.findUnique({
        where: { id: departmentId },
        select: { eventId: true },
      });
      if (dept) {
        await requireEventAccess(context, dept.eventId);
      }
      const assignmentService = new AssignmentService(context.prisma);
      return assignmentService.getDepartmentCoverage(departmentId);
    },

    departmentCoverageGaps: async (
      _parent: unknown,
      { departmentId }: { departmentId: string },
      context: Context
    ) => {
      requireAdmin(context);
      const dept = await context.prisma.department.findUnique({
        where: { id: departmentId },
        select: { eventId: true },
      });
      if (dept) {
        await requireEventAccess(context, dept.eventId);
      }
      const assignmentService = new AssignmentService(context.prisma);
      return assignmentService.getDepartmentCoverageGaps(departmentId);
    },
  },

  Mutation: {
    createAssignment: async (
      _parent: unknown,
      { input }: { input: CreateAssignmentInput },
      context: Context
    ) => {
      requireAdmin(context);
      const assignmentService = new AssignmentService(context.prisma);

      // Get event ID for access check
      const session = await context.prisma.session.findUnique({
        where: { id: input.sessionId },
        select: { eventId: true },
      });
      if (session) {
        await requireEventAccess(context, session.eventId);
      }

      return assignmentService.createAssignment(input);
    },

    updateAssignment: async (
      _parent: unknown,
      { id, input }: { id: string; input: UpdateAssignmentInput },
      context: Context
    ) => {
      requireAdmin(context);
      const assignmentService = new AssignmentService(context.prisma);
      const eventId = await assignmentService.getAssignmentEventId(id);
      await requireEventAccess(context, eventId);

      return assignmentService.updateAssignment(id, input);
    },

    deleteAssignment: async (_parent: unknown, { id }: { id: string }, context: Context) => {
      requireAdmin(context);
      const assignmentService = new AssignmentService(context.prisma);
      const eventId = await assignmentService.getAssignmentEventId(id);
      await requireEventAccess(context, eventId);

      return assignmentService.deleteAssignment(id);
    },

    bulkCreateAssignments: async (
      _parent: unknown,
      { inputs }: { inputs: CreateAssignmentInput[] },
      context: Context
    ) => {
      requireAdmin(context);
      const assignmentService = new AssignmentService(context.prisma);

      if (inputs.length === 0) {
        return [];
      }

      // Collect all unique session IDs and validate they exist and belong to the same event
      const sessionIds = [...new Set(inputs.map((i) => i.sessionId))];
      const sessions = await context.prisma.session.findMany({
        where: { id: { in: sessionIds } },
        select: { id: true, eventId: true },
      });

      if (sessions.length !== sessionIds.length) {
        throw new GraphQLError('One or more session IDs are invalid', {
          extensions: { code: 'BAD_USER_INPUT' },
        });
      }

      const eventIds = [...new Set(sessions.map((s) => s.eventId))];
      if (eventIds.length > 1) {
        throw new GraphQLError('All assignments must belong to the same event', {
          extensions: { code: 'BAD_USER_INPUT' },
        });
      }

      await requireEventAccess(context, eventIds[0]);

      return assignmentService.createAssignments({ assignments: inputs });
    },

    // Volunteer actions
    acceptAssignment: async (
      _parent: unknown,
      { input }: { input: AcceptAssignmentInput },
      context: Context
    ) => {
      requireVolunteer(context);
      const assignmentService = new AssignmentService(context.prisma);
      return assignmentService.acceptAssignment(context.volunteer.id, input);
    },

    declineAssignment: async (
      _parent: unknown,
      { input }: { input: DeclineAssignmentInput },
      context: Context
    ) => {
      requireVolunteer(context);
      const assignmentService = new AssignmentService(context.prisma);
      return assignmentService.declineAssignment(context.volunteer.id, input);
    },

    // Overseer actions
    forceAssignment: async (
      _parent: unknown,
      { input }: { input: ForceAssignmentInput },
      context: Context
    ) => {
      requireAdmin(context);

      // Get event ID for access check
      const session = await context.prisma.session.findUnique({
        where: { id: input.sessionId },
        select: { eventId: true },
      });
      if (session) {
        await requireEventAccess(context, session.eventId);
      }

      const assignmentService = new AssignmentService(context.prisma);
      return assignmentService.forceAssignment(input);
    },

    setCaptain: async (
      _parent: unknown,
      { input }: { input: SetCaptainInput },
      context: Context
    ) => {
      requireAdmin(context);
      const assignmentService = new AssignmentService(context.prisma);
      const eventId = await assignmentService.getAssignmentEventId(input.assignmentId);
      await requireEventAccess(context, eventId);

      return assignmentService.setCaptain(input);
    },

    setAcceptDeadline: async (
      _parent: unknown,
      { assignmentId, deadline }: { assignmentId: string; deadline: Date },
      context: Context
    ) => {
      requireAdmin(context);
      const assignmentService = new AssignmentService(context.prisma);
      const eventId = await assignmentService.getAssignmentEventId(assignmentId);
      await requireEventAccess(context, eventId);

      return assignmentService.setAcceptDeadline(assignmentId, deadline);
    },

    // Captain actions
    captainCheckIn: async (
      _parent: unknown,
      { input }: { input: CaptainCheckInInput },
      context: Context
    ) => {
      requireVolunteer(context);
      const assignmentService = new AssignmentService(context.prisma);
      return assignmentService.captainCheckIn(context.volunteer.id, input);
    },
  },

  ScheduleAssignment: {
    // Map eventVolunteer → volunteer for backward-compatible GraphQL Volunteer type
    volunteer: async (
      parent: ScheduleAssignment & { eventVolunteer?: unknown },
      _args: unknown,
      context: Context
    ) => {
      if (parent.eventVolunteer) return parent.eventVolunteer;
      if (!parent.eventVolunteerId) return null;
      return context.prisma.eventVolunteer.findUnique({
        where: { id: parent.eventVolunteerId },
        include: { user: true },
      });
    },

    eventVolunteer: async (
      parent: ScheduleAssignment & { eventVolunteer?: unknown },
      _args: unknown,
      context: Context
    ) => {
      if (parent.eventVolunteer) return parent.eventVolunteer;
      if (!parent.eventVolunteerId) return null;
      return context.prisma.eventVolunteer.findUnique({
        where: { id: parent.eventVolunteerId },
        include: { user: true },
      });
    },

    post: async (
      parent: ScheduleAssignment & { post?: unknown },
      _args: unknown,
      context: Context
    ) => {
      if (parent.post) return parent.post;
      return context.prisma.post.findUnique({
        where: { id: parent.postId },
        include: { department: true },
      });
    },

    session: async (
      parent: ScheduleAssignment & { session?: unknown },
      _args: unknown,
      context: Context
    ) => {
      if (parent.session) return parent.session;
      return context.prisma.session.findUnique({
        where: { id: parent.sessionId },
      });
    },

    checkIn: async (
      parent: ScheduleAssignment & { checkIn?: unknown },
      _args: unknown,
      context: Context
    ) => {
      if (parent.checkIn !== undefined) return parent.checkIn;
      return context.prisma.checkIn.findUnique({
        where: { assignmentId: parent.id },
      });
    },

    isCheckedIn: async (
      parent: ScheduleAssignment & { checkIn?: { id: string } | null },
      _args: unknown,
      context: Context
    ) => {
      if (parent.checkIn !== undefined) return parent.checkIn !== null;
      const checkIn = await context.prisma.checkIn.findUnique({
        where: { assignmentId: parent.id },
        select: { id: true },
      });
      return checkIn !== null;
    },
  },
};

export default assignmentResolvers;
