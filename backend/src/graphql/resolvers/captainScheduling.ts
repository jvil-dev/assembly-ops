/**
 * Captain Scheduling Resolvers
 *
 * Resolvers for captain-specific scheduling mutations.
 * All mutations require the `requireCaptain` guard and validate that
 * target posts belong to the captain's department.
 *
 * Delegates to existing ShiftService and AssignmentService for business logic.
 *
 * Mutations:
 *   - captainCreateAssignment: Assign a volunteer to a post/session/shift
 *   - captainDeleteAssignment: Remove an assignment
 *   - captainSwapVolunteer: Replace one volunteer with another on an assignment
 *   - captainCreateShift: Create a shift within a session
 *   - captainUpdateShift: Update shift details
 *   - captainDeleteShift: Delete a shift
 *
 * Used by: ./index.ts (resolver composition)
 */
import { Context } from '../context.js';
import { requireAuth, requireCaptain } from '../guards/auth.js';
import { ShiftService } from '../../services/shiftService.js';
import { SessionService } from '../../services/sessionService.js';
import { AssignmentService } from '../../services/assignmentService.js';
import { AuthorizationError, NotFoundError } from '../../utils/errors.js';
import {
  CaptainCreateAssignmentInput,
  CaptainSwapInput,
  CaptainCreateShiftInput,
  CaptainUpdateShiftInput,
  captainCreateAssignmentSchema,
  captainSwapSchema,
  captainCreateShiftSchema,
  captainUpdateShiftSchema,
} from '../validators/captainScheduling.js';

/**
 * Validate that a post belongs to the captain's department.
 */
async function validatePostInDepartment(
  context: Context,
  postId: string,
  departmentId: string
): Promise<void> {
  const post = await context.prisma.post.findUnique({
    where: { id: postId },
    select: { departmentId: true },
  });

  if (!post) {
    throw new NotFoundError('Post not found');
  }

  if (post.departmentId !== departmentId) {
    throw new AuthorizationError('Post does not belong to your department');
  }
}

const captainSchedulingResolvers = {
  Query: {
    captainSessions: async (
      _parent: unknown,
      { eventId }: { eventId: string },
      context: Context
    ) => {
      await requireCaptain(context, eventId);

      const sessionService = new SessionService(context.prisma);
      return sessionService.getEventSessions(eventId);
    },

    captainShifts: async (
      _parent: unknown,
      { sessionId, postId }: { sessionId: string; postId?: string },
      context: Context
    ) => {
      requireAuth(context);

      const sessionService = new SessionService(context.prisma);
      const eventId = await sessionService.getSessionEventId(sessionId);
      await requireCaptain(context, eventId);

      const shiftService = new ShiftService(context.prisma);
      return shiftService.getShifts(sessionId, postId ?? undefined);
    },

    captainVolunteers: async (
      _parent: unknown,
      { eventId, departmentId }: { eventId: string; departmentId: string },
      context: Context
    ) => {
      const { departmentId: captainDeptId } = await requireCaptain(context, eventId);

      if (departmentId !== captainDeptId) {
        throw new AuthorizationError('You can only view volunteers in your department');
      }

      return context.prisma.eventVolunteer.findMany({
        where: { eventId, departmentId },
        include: { user: true, department: true, role: true },
      });
    },

    captainPosts: async (
      _parent: unknown,
      { departmentId }: { departmentId: string },
      context: Context
    ) => {
      requireAuth(context);

      const department = await context.prisma.department.findUnique({
        where: { id: departmentId },
        select: { eventId: true },
      });

      if (!department) {
        throw new NotFoundError('Department not found');
      }

      await requireCaptain(context, department.eventId);

      return context.prisma.post.findMany({
        where: { departmentId },
        orderBy: { name: 'asc' },
      });
    },
  },

  Mutation: {
    captainCreateAssignment: async (
      _parent: unknown,
      { input }: { input: CaptainCreateAssignmentInput },
      context: Context
    ) => {
      const validated = captainCreateAssignmentSchema.parse(input);
      const { departmentId } = await requireCaptain(context, validated.eventId);

      // Verify the target post belongs to the captain's department
      await validatePostInDepartment(context, validated.postId, departmentId);

      const assignmentService = new AssignmentService(context.prisma);
      return assignmentService.forceAssignment({
        volunteerId: validated.eventVolunteerId,
        postId: validated.postId,
        sessionId: validated.sessionId,
        shiftId: validated.shiftId ?? null,
        isCaptain: false,
        canCount: validated.canCount ?? false,
      }, context.user!.id);
    },

    captainDeleteAssignment: async (
      _parent: unknown,
      { eventId, assignmentId }: { eventId: string; assignmentId: string },
      context: Context
    ) => {
      const { departmentId } = await requireCaptain(context, eventId);

      // Verify the assignment's post belongs to the captain's department
      const assignment = await context.prisma.scheduleAssignment.findUnique({
        where: { id: assignmentId },
        select: { post: { select: { departmentId: true } } },
      });

      if (!assignment) {
        throw new NotFoundError('Assignment not found');
      }

      if (assignment.post.departmentId !== departmentId) {
        throw new AuthorizationError('Assignment does not belong to your department');
      }

      const assignmentService = new AssignmentService(context.prisma);
      return assignmentService.deleteAssignment(assignmentId);
    },

    captainSwapVolunteer: async (
      _parent: unknown,
      { input, eventId }: { input: CaptainSwapInput; eventId: string },
      context: Context
    ) => {
      const validated = captainSwapSchema.parse(input);
      const { departmentId } = await requireCaptain(context, eventId);

      // Verify the assignment's post belongs to the captain's department
      const assignment = await context.prisma.scheduleAssignment.findUnique({
        where: { id: validated.assignmentId },
        include: { post: true },
      });

      if (!assignment) {
        throw new NotFoundError('Assignment not found');
      }

      if (assignment.post.departmentId !== departmentId) {
        throw new AuthorizationError('Assignment does not belong to your department');
      }

      // Swap: update the eventVolunteerId on the existing assignment
      return context.prisma.scheduleAssignment.update({
        where: { id: validated.assignmentId },
        data: { eventVolunteerId: validated.newEventVolunteerId },
        include: {
          post: true,
          session: true,
          shift: true,
          eventVolunteer: { include: { user: true } },
        },
      });
    },

    captainCreateShift: async (
      _parent: unknown,
      { input }: { input: CaptainCreateShiftInput },
      context: Context
    ) => {
      const validated = captainCreateShiftSchema.parse(input);
      await requireCaptain(context, validated.eventId);

      const shiftService = new ShiftService(context.prisma);
      return shiftService.createShift({
        sessionId: validated.sessionId,
        postId: validated.postId,
        startTime: validated.startTime,
        endTime: validated.endTime,
      }, context.user!.id);
    },

    captainUpdateShift: async (
      _parent: unknown,
      { id, input }: { id: string; input: CaptainUpdateShiftInput },
      context: Context
    ) => {
      const validated = captainUpdateShiftSchema.parse(input);
      await requireCaptain(context, validated.eventId);

      const shiftService = new ShiftService(context.prisma);
      return shiftService.updateShift(id, {
        startTime: validated.startTime,
        endTime: validated.endTime,
      });
    },

    captainDeleteShift: async (
      _parent: unknown,
      { id, eventId }: { id: string; eventId: string },
      context: Context
    ) => {
      await requireCaptain(context, eventId);

      const shiftService = new ShiftService(context.prisma);
      return shiftService.deleteShift(id);
    },
  },
};

export default captainSchedulingResolvers;
