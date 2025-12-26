/**
 * Assignment Service
 *
 * Business logic for schedule assignments - the core of volunteer scheduling.
 * An assignment links a Volunteer to a Post for a specific Session.
 *
 * Key Features:
 *   - CRUD operations for assignments (single and bulk)
 *   - Conflict detection: One volunteer per session
 *   - Capacity enforcement: Posts have max volunteer limits
 *   - Coverage matrix: Posts × Sessions grid showing filled/unfilled slots
 *
 * Coverage Matrix:
 *   Used by department overseers to visualize scheduling gaps.
 *   Returns a flat array of CoverageSlots, each representing one post-session cell.
 *   Example: 3 posts × 4 sessions = 12 CoverageSlot objects
 *
 * Business Rules:
 *   - Volunteer, Post, and Session must belong to the same Event
 *   - A volunteer can only have ONE assignment per session (no double-booking)
 *   - A post cannot exceed its capacity for any session
 *
 * Used by: ../graphql/resolvers/assignment.ts
 */
import { PrismaClient, ScheduleAssignment } from '@prisma/client';
import { NotFoundError, ValidationError, ConflictError } from '../utils/errors.js';
import {
  createAssignmentSchema,
  createAssignmentsSchema,
  updateAssignmentSchema,
  CreateAssignmentInput,
  CreateAssignmentsInput,
  UpdateAssignmentInput,
} from '../graphql/validators/assignment.js';

export interface CoverageSlot {
  post: {
    id: string;
    name: string;
    capacity: number;
  };
  session: {
    id: string;
    name: string;
    date: Date;
    startTime: Date;
    endTime: Date;
  };
  assignments: Array<{
    id: string;
    volunteer: {
      id: string;
      firstName: string;
      lastName: string;
    };
    checkIn: {
      id: string;
      checkInTime: Date;
    } | null;
  }>;
  filled: number;
  capacity: number;
  isFilled: boolean;
}

export class AssignmentService {
  constructor(private prisma: PrismaClient) {}

  /**
   * Create a single assignment
   */
  async createAssignment(input: CreateAssignmentInput): Promise<ScheduleAssignment> {
    const result = createAssignmentSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { volunteerId, postId, sessionId } = result.data;

    const [volunteer, post, session] = await Promise.all([
      this.prisma.volunteer.findUnique({
        where: { id: volunteerId },
        select: { id: true, eventId: true, firstName: true, lastName: true },
      }),
      this.prisma.post.findUnique({
        where: { id: postId },
        include: { department: { select: { eventId: true } } },
      }),
      this.prisma.session.findUnique({
        where: { id: sessionId },
        select: { id: true, eventId: true },
      }),
    ]);

    if (!volunteer) throw new NotFoundError('Volunteer');
    if (!post) throw new NotFoundError('Post');
    if (!session) throw new NotFoundError('Session');

    // Verify all belong to same event
    const eventId = volunteer.eventId;
    if (post.department.eventId !== eventId || session.eventId !== eventId) {
      throw new ValidationError('Volunteer, post, and session must belong to the same event');
    }

    // Check if volunteer already has an assignment for this session
    const existingAssignment = await this.prisma.scheduleAssignment.findUnique({
      where: {
        volunteerId_sessionId: {
          volunteerId,
          sessionId,
        },
      },
    });

    if (existingAssignment) {
      throw new ConflictError(
        `${volunteer.firstName} ${volunteer.lastName} is already assigned to another post for this session`
      );
    }

    // Check if post has reached capacity for this session
    const postAssignmentCount = await this.prisma.scheduleAssignment.count({
      where: {
        postId,
        sessionId,
      },
    });

    if (postAssignmentCount >= post.capacity) {
      throw new ConflictError(
        `${post.name} has reached its capacity of ${post.capacity} for this session`
      );
    }

    return this.prisma.scheduleAssignment.create({
      data: {
        volunteerId,
        postId,
        sessionId,
      },
      include: {
        volunteer: true,
        post: { include: { department: true } },
        session: true,
        checkIn: true,
      },
    });
  }

  /**
   * Create multiple assignments
   */
  async createAssignments(input: CreateAssignmentsInput): Promise<ScheduleAssignment[]> {
    const result = createAssignmentsSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { assignments } = result.data;
    const createdAssignments: ScheduleAssignment[] = [];

    for (const assignmentInput of assignments) {
      try {
        const assignment = await this.createAssignment(assignmentInput);
        createdAssignments.push(assignment);
      } catch (error) {
        // If any assignment fails, continue but log the error
        console.error('Failed to create assignment:', error);
        throw error; // Re-throw to fail the entire batch
      }
    }

    return createdAssignments;
  }

  /**
   * Update an assignment (change post or session)
   */
  async updateAssignment(
    assignmentId: string,
    input: UpdateAssignmentInput
  ): Promise<ScheduleAssignment> {
    const result = updateAssignmentSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const validated = result.data;

    const assignment = await this.prisma.scheduleAssignment.findUnique({
      where: { id: assignmentId },
      include: {
        volunteer: { select: { eventId: true } },
      },
    });

    if (!assignment) {
      throw new NotFoundError('Assignment');
    }

    const eventId = assignment.volunteer.eventId;

    // If changing post, verify it's in the same event
    if (validated.postId) {
      const post = await this.prisma.post.findUnique({
        where: { id: validated.postId },
        include: { department: { select: { eventId: true } } },
      });

      if (!post) throw new NotFoundError('Post');
      if (post.department.eventId !== eventId) {
        throw new ValidationError('Post must belong to the same event');
      }
    }

    // If changing session, verify it's in the same event and no conflict
    if (validated.sessionId) {
      const session = await this.prisma.session.findUnique({
        where: { id: validated.sessionId },
        select: { eventId: true },
      });

      if (!session) throw new NotFoundError('Session');
      if (session.eventId !== eventId) {
        throw new ValidationError('Session must belong to the same event');
      }

      // Check for conflicts (excluding current assignment)
      const existingAssignment = await this.prisma.scheduleAssignment.findFirst({
        where: {
          volunteerId: assignment.volunteerId,
          sessionId: validated.sessionId,
          id: { not: assignmentId },
        },
      });

      if (existingAssignment) {
        throw new ConflictError('Volunteer already has an assignment for this session');
      }
    }

    return this.prisma.scheduleAssignment.update({
      where: { id: assignmentId },
      data: {
        postId: validated.postId,
        sessionId: validated.sessionId,
      },
      include: {
        volunteer: true,
        post: { include: { department: true } },
        session: true,
        checkIn: true,
      },
    });
  }

  /**
   * Delete an assignment
   */
  async deleteAssignment(assignmentId: string): Promise<boolean> {
    const assignment = await this.prisma.scheduleAssignment.findUnique({
      where: { id: assignmentId },
    });

    if (!assignment) {
      throw new NotFoundError('Assignment');
    }

    await this.prisma.scheduleAssignment.delete({
      where: { id: assignmentId },
    });

    return true;
  }

  /**
   * Get a single assignment
   */
  async getAssignment(assignmentId: string) {
    return this.prisma.scheduleAssignment.findUnique({
      where: { id: assignmentId },
      include: {
        volunteer: true,
        post: { include: { department: true } },
        session: true,
        checkIn: true,
      },
    });
  }

  /**
   * Get all assignments for an event
   */
  async getEventAssignments(eventId: string) {
    return this.prisma.scheduleAssignment.findMany({
      where: {
        session: { eventId },
      },
      include: {
        volunteer: true,
        post: { include: { department: true } },
        session: true,
        checkIn: true,
      },
      orderBy: [
        { session: { date: 'asc' } },
        { session: { startTime: 'asc' } },
        { post: { name: 'asc' } },
      ],
    });
  }

  /**
   * Get assignments for a specific volunteer
   */
  async getVolunteerAssignments(volunteerId: string) {
    return this.prisma.scheduleAssignment.findMany({
      where: { volunteerId },
      include: {
        post: { include: { department: true } },
        session: true,
        checkIn: true,
      },
      orderBy: [{ session: { date: 'asc' } }, { session: { startTime: 'asc' } }],
    });
  }

  /**
   * Get assignments for a specific session
   */
  async getSessionAssignments(sessionId: string) {
    return this.prisma.scheduleAssignment.findMany({
      where: { sessionId },
      include: {
        volunteer: true,
        post: { include: { department: true } },
        checkIn: true,
      },
      orderBy: { post: { name: 'asc' } },
    });
  }

  /**
   * Get assignments for a specific post
   */
  async getPostAssignments(postId: string) {
    return this.prisma.scheduleAssignment.findMany({
      where: { postId },
      include: {
        volunteer: true,
        session: true,
        checkIn: true,
      },
      orderBy: [{ session: { date: 'asc' } }, { session: { startTime: 'asc' } }],
    });
  }

  /**
   * Get coverage matrix for a department
   * Returns a grid of posts × sessions showing filled/unfilled slots
   */
  async getDepartmentCoverage(departmentId: string): Promise<CoverageSlot[]> {
    // Get all posts in the department
    const posts = await this.prisma.post.findMany({
      where: { departmentId },
      orderBy: { name: 'asc' },
    });

    if (posts.length === 0) {
      return [];
    }

    // Get the event ID from the department
    const department = await this.prisma.department.findUnique({
      where: { id: departmentId },
      select: { eventId: true },
    });

    if (!department) {
      throw new NotFoundError('Department');
    }

    // Get all sessions for the event
    const sessions = await this.prisma.session.findMany({
      where: { eventId: department.eventId },
      orderBy: [{ date: 'asc' }, { startTime: 'asc' }],
    });

    if (sessions.length === 0) {
      return [];
    }

    // Get all assignments for these posts
    const assignments = await this.prisma.scheduleAssignment.findMany({
      where: {
        postId: { in: posts.map((p) => p.id) },
      },
      include: {
        volunteer: {
          select: { id: true, firstName: true, lastName: true },
        },
        checkIn: {
          select: { id: true, checkInTime: true },
        },
      },
    });

    // Build the coverage matrix
    const coverageSlots: CoverageSlot[] = [];

    for (const post of posts) {
      for (const session of sessions) {
        const slotAssignments = assignments.filter(
          (a) => a.postId === post.id && a.sessionId === session.id
        );

        coverageSlots.push({
          post: {
            id: post.id,
            name: post.name,
            capacity: post.capacity,
          },
          session: {
            id: session.id,
            name: session.name,
            date: session.date,
            startTime: session.startTime,
            endTime: session.endTime,
          },
          assignments: slotAssignments.map((a) => ({
            id: a.id,
            volunteer: a.volunteer,
            checkIn: a.checkIn,
          })),
          filled: slotAssignments.length,
          capacity: post.capacity,
          isFilled: slotAssignments.length >= post.capacity,
        });
      }
    }

    return coverageSlots;
  }

  /**
   * Get coverage gaps (unfilled slots) for a department
   */
  async getDepartmentCoverageGaps(departmentId: string): Promise<CoverageSlot[]> {
    const coverage = await this.getDepartmentCoverage(departmentId);
    return coverage.filter((slot) => !slot.isFilled);
  }

  /**
   * Get assignment's event ID for access control
   */
  async getAssignmentEventId(assignmentId: string): Promise<string> {
    const assignment = await this.prisma.scheduleAssignment.findUnique({
      where: { id: assignmentId },
      include: {
        session: { select: { eventId: true } },
      },
    });

    if (!assignment) {
      throw new NotFoundError('Assignment');
    }

    return assignment.session.eventId;
  }
}
