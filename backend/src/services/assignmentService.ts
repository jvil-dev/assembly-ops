/**
 * Assignment Service
 *
 * Business logic for schedule assignments - the core of volunteer scheduling.
 * An assignment links a Volunteer to a Post for a specific Session.
 *
 * Key Features:
 *   - CRUD operations for assignments (single and bulk)
 *   - Assignment acceptance workflow (PENDING → ACCEPTED/DECLINED)
 *   - Captain role with group check-in capabilities
 *   - Force-assign for critical posts (bypasses acceptance)
 *   - Conflict detection: One volunteer per session
 *   - Capacity enforcement: Posts have max volunteer limits
 *   - Coverage matrix: Posts × Sessions grid (ACCEPTED assignments only)
 *
 * Assignment Status Flow:
 *   createAssignment → PENDING → acceptAssignment → ACCEPTED
 *                            ↓
 *                    declineAssignment → DECLINED
 *                            ↓
 *              (auto after deadline) → AUTO_DECLINED
 *
 *   forceAssignment → ACCEPTED (bypasses acceptance, sets forceAssigned=true)
 *
 * Captain Role:
 *   - setCaptain: Designate an assignment as captain
 *   - getCaptainGroup: Get volunteers at same post/session
 *   - captainCheckIn: Captain can check in group members
 *
 * Coverage Matrix:
 *   Used by department overseers to visualize scheduling gaps.
 *   Includes ACCEPTED + PENDING assignments. Only ACCEPTED count as "filled" slots.
 *   Returns a flat array of CoverageSlots, each representing one post-session cell.
 *
 * Business Rules:
 *   - Volunteer, Post, and Session must belong to the same Event
 *   - A volunteer can only have ONE assignment per session (no double-booking)
 *   - A post cannot exceed its capacity for any session
 *   - Only ACCEPTED assignments count toward coverage
 *
 * Used by: ../graphql/resolvers/assignment.ts
 */
import { Prisma, PrismaClient, ScheduleAssignment } from '@prisma/client';
import {
  NotFoundError,
  ValidationError,
  ConflictError,
  AuthorizationError,
} from '../utils/errors.js';
import {
  AcceptAssignmentInput,
  DeclineAssignmentInput,
  ForceAssignmentInput,
  SetCaptainInput,
  CaptainCheckInInput,
  PendingAssignmentsFilter,
  createAssignmentSchema,
  createAssignmentsSchema,
  updateAssignmentSchema,
  CreateAssignmentInput,
  CreateAssignmentsInput,
  UpdateAssignmentInput,
  acceptAssignmentSchema,
  declineAssignmentSchema,
  forceAssignmentSchema,
  setCaptainSchema,
  captainCheckInSchema,
} from '../graphql/validators/assignment.js';

export interface CoverageSlot {
  post: {
    id: string;
    name: string;
    capacity: number;
    category: string | null;
    location: string | null;
    sortOrder: number;
    areaId: string | null;
    areaName: string | null;
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
    } | null;
    checkIn: {
      id: string;
      checkInTime: Date;
    } | null;
    status: string;
    forceAssigned: boolean;
  }>;
  filled: number;
  capacity: number;
  isFilled: boolean;
}

export class AssignmentService {
  constructor(private prisma: PrismaClient) {}

  /**
   * Check if a context volunteer ID (old Volunteer.id or new EventVolunteer.id)
   * owns a given assignment. Bridges both models via the shared login ID.
   */
  private async isAssignmentOwner(
    assignment: { volunteerId: string | null; eventVolunteerId: string | null },
    contextVolunteerId: string
  ): Promise<boolean> {
    // Direct match on either FK
    if (assignment.volunteerId === contextVolunteerId || assignment.eventVolunteerId === contextVolunteerId) {
      return true;
    }

    // Bridge: if caller is an EventVolunteer, check if old volunteerId matches
    const eventVolunteer = await this.prisma.eventVolunteer.findUnique({
      where: { id: contextVolunteerId },
      select: { volunteerId: true },
    });
    if (eventVolunteer) {
      const oldVolunteer = await this.prisma.volunteer.findUnique({
        where: { volunteerId: eventVolunteer.volunteerId },
        select: { id: true },
      });
      if (oldVolunteer && assignment.volunteerId === oldVolunteer.id) {
        return true;
      }
    }

    return false;
  }

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
        select: { id: true, volunteerId: true, eventId: true, firstName: true, lastName: true },
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

    // Bridge: find the corresponding EventVolunteer via shared login ID
    const eventVolunteer = await this.prisma.eventVolunteer.findUnique({
      where: { volunteerId: volunteer.volunteerId },
      select: { id: true },
    });

    return this.prisma.scheduleAssignment.create({
      data: {
        volunteerId,
        eventVolunteerId: eventVolunteer?.id,
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
        eventVolunteer: { select: { eventId: true } },
      },
    });

    if (!assignment) {
      throw new NotFoundError('Assignment');
    }

    // Get eventId from either volunteer or eventVolunteer
    const eventId = assignment.volunteer?.eventId ?? assignment.eventVolunteer?.eventId;
    if (!eventId) {
      throw new ValidationError('Assignment has no associated volunteer');
    }

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
  async getAssignments(assignmentId: string) {
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
   * Get assignments for a specific volunteer.
   * Handles both old Volunteer.id and new EventVolunteer.id by bridging
   * via the shared volunteerId (login ID like "CA-XXXXX").
   */
  async getVolunteerAssignments(contextVolunteerId: string, status?: string) {
    // Build OR condition to match by old volunteerId OR new eventVolunteerId
    const volunteerConditions: { volunteerId?: string; eventVolunteerId?: string }[] = [
      { volunteerId: contextVolunteerId },
      { eventVolunteerId: contextVolunteerId },
    ];

    // Also bridge: if caller is an EventVolunteer, find the old Volunteer record
    const eventVolunteer = await this.prisma.eventVolunteer.findUnique({
      where: { id: contextVolunteerId },
      select: { volunteerId: true },
    });
    if (eventVolunteer) {
      // Find old Volunteer by the shared login ID
      const oldVolunteer = await this.prisma.volunteer.findUnique({
        where: { volunteerId: eventVolunteer.volunteerId },
        select: { id: true },
      });
      if (oldVolunteer) {
        volunteerConditions.push({ volunteerId: oldVolunteer.id });
      }
    }

    return this.prisma.scheduleAssignment.findMany({
      where: {
        OR: volunteerConditions,
        ...(status && { status: status as 'PENDING' | 'ACCEPTED' | 'DECLINED' | 'AUTO_DECLINED' }),
      },
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
    // Get all posts in the department (include area for grouping)
    const posts = await this.prisma.post.findMany({
      where: { departmentId },
      orderBy: [{ category: 'asc' }, { sortOrder: 'asc' }, { name: 'asc' }],
      include: { area: { select: { id: true, name: true } } },
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

    // Get all ACCEPTED + PENDING assignments for these posts
    const assignments = await this.prisma.scheduleAssignment.findMany({
      where: {
        postId: { in: posts.map((p) => p.id) },
        status: { in: ['ACCEPTED', 'PENDING'] },
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

        const acceptedCount = slotAssignments.filter(
          (a) => a.status === 'ACCEPTED'
        ).length;

        coverageSlots.push({
          post: {
            id: post.id,
            name: post.name,
            capacity: post.capacity,
            category: post.category,
            location: post.location,
            sortOrder: post.sortOrder,
            areaId: post.area?.id ?? null,
            areaName: post.area?.name ?? null,
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
            status: a.status,
            forceAssigned: a.forceAssigned,
          })),
          filled: acceptedCount,
          capacity: post.capacity,
          isFilled: acceptedCount >= post.capacity,
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

  /**
   * Accept an assignment (volunteer action)
   */
  async acceptAssignment(
    contextVolunteerId: string,
    input: AcceptAssignmentInput
  ): Promise<ScheduleAssignment> {
    const result = acceptAssignmentSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const assignment = await this.prisma.scheduleAssignment.findUnique({
      where: { id: result.data.assignmentId },
    });

    if (!assignment) {
      throw new NotFoundError('Assignment');
    }

    // Check ownership: context ID could be old Volunteer.id or new EventVolunteer.id
    const isOwner = await this.isAssignmentOwner(assignment, contextVolunteerId);
    if (!isOwner) {
      throw new AuthorizationError('This assignment does not belong to you');
    }

    if (assignment.status !== 'PENDING') {
      throw new ValidationError(`Assignment already ${assignment.status.toLowerCase()}`);
    }

    return this.prisma.scheduleAssignment.update({
      where: { id: assignment.id },
      data: {
        status: 'ACCEPTED',
        respondedAt: new Date(),
      },
      include: {
        volunteer: true,
        post: { include: { department: true } },
        session: true,
      },
    });
  }

  /**
   * Decline an assignment (volunteer action)
   */
  async declineAssignment(
    contextVolunteerId: string,
    input: DeclineAssignmentInput
  ): Promise<ScheduleAssignment> {
    const result = declineAssignmentSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const assignment = await this.prisma.scheduleAssignment.findUnique({
      where: { id: result.data.assignmentId },
    });

    if (!assignment) {
      throw new NotFoundError('Assignment');
    }

    // Check ownership: context ID could be old Volunteer.id or new EventVolunteer.id
    const isOwner = await this.isAssignmentOwner(assignment, contextVolunteerId);
    if (!isOwner) {
      throw new AuthorizationError('This assignment does not belong to you');
    }

    if (assignment.status !== 'PENDING') {
      throw new ValidationError(`Assignment is already ${assignment.status.toLowerCase()}`);
    }

    if (assignment.forceAssigned) {
      throw new ValidationError('Cannot decline a force-assigned assignment');
    }

    return this.prisma.scheduleAssignment.update({
      where: { id: assignment.id },
      data: {
        status: 'DECLINED',
        respondedAt: new Date(),
        declineReason: result.data.reason,
      },
      include: {
        volunteer: true,
        post: { include: { department: true } },
        session: true,
      },
    });
  }

  /**
   * Force-assign a volunteer (overseer action) - bypasses acceptance workflow
   */
  async forceAssignment(input: ForceAssignmentInput): Promise<ScheduleAssignment> {
    const result = forceAssignmentSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { volunteerId, postId, sessionId, isCaptain } = result.data;

    // Verify volunteer exists
    const volunteer = await this.prisma.volunteer.findUnique({
      where: { id: volunteerId },
      select: { id: true, volunteerId: true },
    });
    if (!volunteer) {
      throw new NotFoundError('Volunteer');
    }

    // Verify post exists
    const post = await this.prisma.post.findUnique({
      where: { id: postId },
    });
    if (!post) {
      throw new NotFoundError('Post');
    }

    // Verify session exists
    const session = await this.prisma.session.findUnique({
      where: { id: sessionId },
    });
    if (!session) {
      throw new NotFoundError('Session');
    }

    // Bridge: find the corresponding EventVolunteer via shared login ID
    const eventVolunteer = await this.prisma.eventVolunteer.findUnique({
      where: { volunteerId: volunteer.volunteerId },
      select: { id: true },
    });

    // Check if assignment already exists
    const existing = await this.prisma.scheduleAssignment.findUnique({
      where: {
        volunteerId_sessionId: { volunteerId, sessionId },
      },
    });

    if (existing) {
      // Update existing assignment to force-accepted, also link eventVolunteerId if missing
      return this.prisma.scheduleAssignment.update({
        where: { id: existing.id },
        data: {
          postId,
          status: 'ACCEPTED',
          forceAssigned: true,
          isCaptain: isCaptain ?? existing.isCaptain,
          respondedAt: new Date(),
          ...(eventVolunteer && !existing.eventVolunteerId && { eventVolunteerId: eventVolunteer.id }),
        },
        include: {
          volunteer: true,
          post: { include: { department: true } },
          session: true,
        },
      });
    }

    // Create new force-assigned assignment
    return this.prisma.scheduleAssignment.create({
      data: {
        volunteerId,
        eventVolunteerId: eventVolunteer?.id,
        postId,
        sessionId,
        status: 'ACCEPTED',
        forceAssigned: true,
        isCaptain: isCaptain ?? false,
        respondedAt: new Date(),
      },
      include: {
        volunteer: true,
        post: { include: { department: true } },
        session: true,
      },
    });
  }

  /**
   * Set captain status on an assignment (overseer action)
   */
  async setCaptain(input: SetCaptainInput): Promise<ScheduleAssignment> {
    const result = setCaptainSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const assignment = await this.prisma.scheduleAssignment.findUnique({
      where: { id: result.data.assignmentId },
    });

    if (!assignment) {
      throw new NotFoundError('Assignment');
    }

    return this.prisma.scheduleAssignment.update({
      where: { id: assignment.id },
      data: { isCaptain: result.data.isCaptain },
      include: {
        volunteer: true,
        post: { include: { department: true } },
        session: true,
      },
    });
  }

  /**
   * Captain check-in for a group member
   */
  async captainCheckIn(
    captainVolunteerId: string,
    input: CaptainCheckInInput
  ): Promise<ScheduleAssignment> {
    const result = captainCheckInSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    // Get the target assignment
    const targetAssignment = await this.prisma.scheduleAssignment.findUnique({
      where: { id: result.data.assignmentId },
      include: {
        post: true,
        session: true,
        checkIn: true,
      },
    });

    if (!targetAssignment) {
      throw new NotFoundError('Assignment');
    }

    // Check if already checked in
    if (targetAssignment.checkIn) {
      throw new ValidationError('Volunteer is already checked in');
    }

    // Verify captain has captain assignment for the same post and session
    const captainAssignment = await this.prisma.scheduleAssignment.findFirst({
      where: {
        volunteerId: captainVolunteerId,
        postId: targetAssignment.postId,
        sessionId: targetAssignment.sessionId,
        isCaptain: true,
      },
    });

    if (!captainAssignment) {
      throw new AuthorizationError(
        'You must be a captain for this post and session to check in group members'
      );
    }

    // Create check-in for the target volunteer
    await this.prisma.checkIn.create({
      data: {
        assignmentId: targetAssignment.id,
        notes: result.data.notes
          ? `Checked in by captain.${result.data.notes}`
          : 'Checked in by captain',
        status: 'CHECKED_IN',
      },
    });

    // Return updated assignment with check-in
    return this.prisma.scheduleAssignment.findUniqueOrThrow({
      where: { id: targetAssignment.id },
      include: {
        volunteer: true,
        post: { include: { department: true } },
        session: true,
        checkIn: true,
      },
    });
  }

  /**
   * Get group members for a captain (same post/session assignments)
   */
  async getCaptainGroup(
    captainVolunteerId: string,
    postId: string,
    sessionId: string
  ): Promise<ScheduleAssignment[]> {
    // Verify captain status
    const captainAssignment = await this.prisma.scheduleAssignment.findFirst({
      where: {
        volunteerId: captainVolunteerId,
        postId,
        sessionId,
        isCaptain: true,
      },
    });

    if (!captainAssignment) {
      throw new AuthorizationError('You are not a captain for this post and session');
    }

    // Get all assignments for this post/session (excluding captain)
    return this.prisma.scheduleAssignment.findMany({
      where: {
        postId,
        sessionId,
        volunteerId: { not: captainVolunteerId },
      },
      include: {
        volunteer: true,
        checkIn: true,
      },
      orderBy: { volunteer: { lastName: 'asc' } },
    });
  }

  /**
   * Get pending assignments for an event or department
   */
  async getPendingAssignments(filter: PendingAssignmentsFilter): Promise<ScheduleAssignment[]> {
    const where: Prisma.ScheduleAssignmentWhereInput = {};

    if (filter.status) {
      where.status = filter.status;
    } else {
      where.status = 'PENDING';
    }

    if (filter.departmentId) {
      where.post = { departmentId: filter.departmentId };
    } else if (filter.eventId) {
      where.session = { eventId: filter.eventId };
    }

    return this.prisma.scheduleAssignment.findMany({
      where,
      include: {
        volunteer: true,
        post: { include: { department: true } },
        session: true,
      },
      orderBy: [{ session: { date: 'asc' } }, { session: { startTime: 'asc' } }],
    });
  }

  /**
   * Get declined assignments for an event or department
   */
  async getDeclinedAssignments(
    eventId?: string,
    departmentId?: string
  ): Promise<ScheduleAssignment[]> {
    const where: Prisma.ScheduleAssignmentWhereInput = { status: 'DECLINED' };

    if (departmentId) {
      where.post = { departmentId };
    } else if (eventId) {
      where.session = { eventId };
    }

    return this.prisma.scheduleAssignment.findMany({
      where,
      include: {
        volunteer: true,
        post: { include: { department: true } },
        session: true,
      },
      orderBy: { respondedAt: 'desc' },
    });
  }

  /**
   * Auto-decline assignments past deadline
   */
  async autoDeclinePastDeadline(): Promise<number> {
    const now = new Date();

    // Get assignments past their deadline
    const pastDeadline = await this.prisma.scheduleAssignment.findMany({
      where: {
        status: 'PENDING',
        acceptedDeadline: { lt: now },
      },
    });

    if (pastDeadline.length === 0) {
      return 0;
    }

    // Update all to AUTO_DECLINED
    const result = await this.prisma.scheduleAssignment.updateMany({
      where: {
        id: { in: pastDeadline.map((a) => a.id) },
      },
      data: {
        status: 'AUTO_DECLINED',
        respondedAt: now,
      },
    });

    return result.count;
  }

  /**
   * Set accept deadline for an assignment
   */
  async setAcceptDeadline(assignmentId: string, deadline: Date): Promise<ScheduleAssignment> {
    const assignment = await this.prisma.scheduleAssignment.findUnique({
      where: { id: assignmentId },
    });

    if (!assignment) {
      throw new NotFoundError('Assignment');
    }

    return this.prisma.scheduleAssignment.update({
      where: { id: assignmentId },
      data: { acceptedDeadline: deadline },
      include: {
        volunteer: true,
        post: { include: { department: true } },
        session: true,
      },
    });
  }
}
