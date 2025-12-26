/**
 * Assignment Resolvers
 *
 * GraphQL resolvers for schedule assignment operations.
 * Handles the connection between GraphQL queries/mutations and AssignmentService.
 *
 * Authorization:
 *   - Most operations require Admin auth + event access
 *   - myAssignments requires Volunteer auth (for mobile app)
 *   - All mutations verify the admin has access to the relevant event
 *
 * Query Resolvers:
 *   - assignment, assignments: Get assignments by ID or event
 *   - volunteerAssignments, sessionAssignments, postAssignments: Filtered queries
 *   - myAssignments: Volunteer's own schedule
 *   - departmentCoverage, departmentCoverageGaps: Coverage matrix queries
 *
 * Mutation Resolvers:
 *   - createAssignment, createAssignments: Create single or bulk
 *   - updateAssignment: Change post or session
 *   - deleteAssignment: Remove assignment
 *
 * Type Resolvers:
 *   - ScheduleAssignment.isCheckedIn: Computed field (true if checkIn exists)
 *
 * Used by: ./index.ts (resolver composition)
 */
import { Context } from '../context.js';
import { AssignmentService, CoverageSlot } from '../../services/assignmentService.js';
import { requireAdmin, requireVolunteer, requireEventAccess } from '../guards/auth.js';
import { ScheduleAssignment } from '@prisma/client';
import {
  CreateAssignmentInput,
  CreateAssignmentsInput,
  UpdateAssignmentInput,
} from '../validators/assignment.js';

const assignmentResolvers = {
  Query: {
    assignment: async (_parent: unknown, { id }: { id: string }, context: Context) => {
      requireAdmin(context);

      const assignmentService = new AssignmentService(context.prisma);
      const eventId = await assignmentService.getAssignmentEventId(id);
      await requireEventAccess(context, eventId);

      return assignmentService.getAssignment(id);
    },

    assignments: async (_parent: unknown, { eventId }: { eventId: string }, context: Context) => {
      requireAdmin(context);
      await requireEventAccess(context, eventId);

      const assignmentService = new AssignmentService(context.prisma);
      return assignmentService.getEventAssignments(eventId);
    },

    volunteerAssignments: async (
      _parent: unknown,
      { volunteerId }: { volunteerId: string },
      context: Context
    ) => {
      requireAdmin(context);

      // Get volunteer's eventId for access check
      const volunteer = await context.prisma.volunteer.findUnique({
        where: { id: volunteerId },
        select: { eventId: true },
      });

      if (volunteer) {
        await requireEventAccess(context, volunteer.eventId);
      }

      const assignmentService = new AssignmentService(context.prisma);
      return assignmentService.getVolunteerAssignments(volunteerId);
    },

    sessionAssignments: async (
      _parent: unknown,
      { sessionId }: { sessionId: string },
      context: Context
    ) => {
      requireAdmin(context);

      // Get session's eventId for access check
      const session = await context.prisma.session.findUnique({
        where: { id: sessionId },
        select: { eventId: true },
      });

      if (session) {
        await requireEventAccess(context, session.eventId);
      }

      const assignmentService = new AssignmentService(context.prisma);
      return assignmentService.getSessionAssignments(sessionId);
    },

    postAssignments: async (_parent: unknown, { postId }: { postId: string }, context: Context) => {
      requireAdmin(context);

      // Get post's eventId for access check
      const post = await context.prisma.post.findUnique({
        where: { id: postId },
        include: { department: { select: { eventId: true } } },
      });

      if (post) {
        await requireEventAccess(context, post.department.eventId);
      }

      const assignmentService = new AssignmentService(context.prisma);
      return assignmentService.getPostAssignments(postId);
    },

    myAssignments: async (_parent: unknown, _args: unknown, context: Context) => {
      requireVolunteer(context);

      const assignmentService = new AssignmentService(context.prisma);
      return assignmentService.getVolunteerAssignments(context.volunteer.id);
    },

    departmentCoverage: async (
      _parent: unknown,
      { departmentId }: { departmentId: string },
      context: Context
    ): Promise<CoverageSlot[]> => {
      requireAdmin(context);

      // Get department's eventId for access check
      const department = await context.prisma.department.findUnique({
        where: { id: departmentId },
        select: { eventId: true },
      });

      if (department) {
        await requireEventAccess(context, department.eventId);
      }

      const assignmentService = new AssignmentService(context.prisma);
      return assignmentService.getDepartmentCoverage(departmentId);
    },

    departmentCoverageGaps: async (
      _parent: unknown,
      { departmentId }: { departmentId: string },
      context: Context
    ): Promise<CoverageSlot[]> => {
      requireAdmin(context);

      // Get department's eventId for access check
      const department = await context.prisma.department.findUnique({
        where: { id: departmentId },
        select: { eventId: true },
      });

      if (department) {
        await requireEventAccess(context, department.eventId);
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

      // Get volunteer's eventId for access check
      const volunteer = await context.prisma.volunteer.findUnique({
        where: { id: input.volunteerId },
        select: { eventId: true },
      });

      if (volunteer) {
        await requireEventAccess(context, volunteer.eventId);
      }

      const assignmentService = new AssignmentService(context.prisma);
      return assignmentService.createAssignment(input);
    },

    createAssignments: async (
      _parent: unknown,
      { input }: { input: CreateAssignmentsInput },
      context: Context
    ) => {
      requireAdmin(context);

      // Get first volunteer's eventId for access check
      if (input.assignments.length > 0) {
        const volunteer = await context.prisma.volunteer.findUnique({
          where: { id: input.assignments[0].volunteerId },
          select: { eventId: true },
        });

        if (volunteer) {
          await requireEventAccess(context, volunteer.eventId);
        }
      }

      const assignmentService = new AssignmentService(context.prisma);
      return assignmentService.createAssignments(input);
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
  },

  ScheduleAssignment: {
    isCheckedIn: (assignment: ScheduleAssignment & { checkIn?: { id: string } | null }) => {
      return !!assignment.checkIn;
    },
  },
};

export default assignmentResolvers;
