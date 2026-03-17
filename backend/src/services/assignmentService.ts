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
 *   - Unlimited assignment per post (no capacity limits)
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
 *   - No capacity limits — overseers can assign unlimited volunteers per post
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
  SetCanCountInput,
  CaptainCheckInInput,
  PendingAssignmentsFilter,
  CopySessionAssignmentsInput,
  createAssignmentSchema,
  createAssignmentsSchema,
  updateAssignmentSchema,
  acceptAssignmentSchema,
  declineAssignmentSchema,
  forceAssignmentSchema,
  setCaptainSchema,
  setCanCountSchema,
  captainCheckInSchema,
  copySessionAssignmentsSchema,
  CreateAssignmentInput,
  CreateAssignmentsInput,
  UpdateAssignmentInput,
} from '../graphql/validators/assignment.js';

export interface CoverageSlot {
  post: {
    id: string;
    name: string;
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
  shifts: Array<{
    id: string;
    name: string;
    startTime: Date;
    endTime: Date;
  }>;
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
    canCount: boolean;
    shiftId: string | null;
    shiftName: string | null;
  }>;
  filled: number;
}

export class AssignmentService {
  constructor(private prisma: PrismaClient) {}

  /**
   * Check if a context volunteer ID owns a given assignment.
   */
  private isAssignmentOwner(
    assignment: { eventVolunteerId: string },
    contextVolunteerId: string
  ): boolean {
    return assignment.eventVolunteerId === contextVolunteerId;
  }

  /**
   * Get the effective time range for an assignment.
   * Priority: shift time > area time > null (whole-session)
   */
  private getEffectiveTimeRange(
    shiftData: { startTime: Date; endTime: Date } | null,
    areaData: { startTime: Date | null; endTime: Date | null } | null
  ): { startTime: Date; endTime: Date } | null {
    if (shiftData) return { startTime: shiftData.startTime, endTime: shiftData.endTime };
    if (areaData?.startTime && areaData?.endTime) return { startTime: areaData.startTime, endTime: areaData.endTime };
    return null;
  }

  /**
   * Check if two time ranges overlap.
   */
  private timesOverlap(
    a: { startTime: Date; endTime: Date },
    b: { startTime: Date; endTime: Date }
  ): boolean {
    return a.startTime < b.endTime && a.endTime > b.startTime;
  }

  /**
   * Create a single assignment
   */
  async createAssignment(input: CreateAssignmentInput): Promise<{ assignment: ScheduleAssignment; warning: string | null }> {
    const result = createAssignmentSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { volunteerId, postId, sessionId, shiftId, canCount, force } = result.data;

    const [volunteer, post, session] = await Promise.all([
      this.prisma.eventVolunteer.findUnique({
        where: { id: volunteerId },
        include: { user: { select: { firstName: true, lastName: true } }, event: true },
      }),
      this.prisma.post.findUnique({
        where: { id: postId },
        include: {
          department: { select: { eventId: true } },
          area: { select: { startTime: true, endTime: true } },
        },
      }),
      this.prisma.session.findUnique({
        where: { id: sessionId },
        select: { id: true, eventId: true, startTime: true, endTime: true },
      }),
    ]);

    if (!volunteer) throw new NotFoundError('Volunteer');
    if (!post) throw new NotFoundError('Post');
    if (!session) throw new NotFoundError('Session');

    // Verify all belong to same event
    const eventId = volunteer.event.id;
    if (post.department.eventId !== eventId || session.eventId !== eventId) {
      throw new ValidationError('Volunteer, post, and session must belong to the same event');
    }

    // Determine effective time range for the new assignment
    let newShiftData: { startTime: Date; endTime: Date } | null = null;
    if (shiftId) {
      const shift = await this.prisma.shift.findUnique({
        where: { id: shiftId },
        select: { sessionId: true, startTime: true, endTime: true },
      });
      if (!shift) throw new NotFoundError('Shift');
      if (shift.sessionId !== sessionId) {
        throw new ValidationError('Shift does not belong to the specified session');
      }
      newShiftData = { startTime: shift.startTime, endTime: shift.endTime };
    }

    const newTimeRange = this.getEffectiveTimeRange(newShiftData, post.area);
    let warning: string | null = null;
    const volunteerName = `${volunteer.user.firstName} ${volunteer.user.lastName}`;

    // Fetch all existing assignments for this volunteer in this session
    const existingAssignments = await this.prisma.scheduleAssignment.findMany({
      where: {
        eventVolunteerId: volunteerId,
        sessionId,
      },
      include: {
        shift: true,
        post: {
          include: {
            area: { select: { startTime: true, endTime: true } },
          },
        },
      },
    });

    for (const existing of existingAssignments) {
      const existingTimeRange = this.getEffectiveTimeRange(
        existing.shift ? { startTime: existing.shift.startTime, endTime: existing.shift.endTime } : null,
        existing.post.area
      );

      // Case 1: Both whole-session → hard conflict (unchanged behavior)
      if (!newTimeRange && !existingTimeRange) {
        throw new ConflictError(
          `${volunteerName} is already assigned to another post for this session`
        );
      }

      // Case 2: Both timed → standard overlap check → hard conflict
      if (newTimeRange && existingTimeRange) {
        if (this.timesOverlap(newTimeRange, existingTimeRange)) {
          throw new ConflictError(
            `${volunteerName} has an overlapping assignment in this session`
          );
        }
        continue;
      }

      // Case 3: One timed, one whole-session → soft conflict with warning
      // The timed range always overlaps a whole-session by definition,
      // so we issue a warning (not a hard block) suggesting the overseer
      // create a shift for the whole-session assignment.
      if (!force) {
        const wholeSessionPostName = newTimeRange ? existing.post.name : post.name;
        throw new ConflictError(
          `${volunteerName} has a whole-session assignment at "${wholeSessionPostName}". ` +
          `Consider creating a shift for that assignment to avoid overlap. ` +
          `Use force to proceed anyway.`
        );
      }
      // force=true: set warning and continue
      const wholeSessionPostName = newTimeRange ? existing.post.name : post.name;
      warning = `${volunteerName} also has a whole-session assignment at "${wholeSessionPostName}". Consider creating a shift for that assignment to avoid overlap.`;
    }

    const assignment = await this.prisma.scheduleAssignment.create({
      data: {
        eventVolunteerId: volunteerId,
        postId,
        sessionId,
        shiftId: shiftId || undefined,
        canCount: canCount ?? false,
      },
      include: {
        eventVolunteer: { include: { user: true } },
        post: { include: { department: true } },
        session: true,
        shift: true,
        checkIn: true,
      },
    });

    return { assignment, warning };
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
        const { assignment } = await this.createAssignment(assignmentInput);
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
        eventVolunteer: { select: { eventId: true } },
      },
    });

    if (!assignment) {
      throw new NotFoundError('Assignment');
    }

    // Get eventId from eventVolunteer
    const eventId = assignment.eventVolunteer?.eventId;
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
          eventVolunteerId: assignment.eventVolunteerId,
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
        ...(validated.canCount !== undefined && { canCount: validated.canCount }),
      },
      include: {
        eventVolunteer: { include: { user: true } },
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
        eventVolunteer: { include: { user: true } },
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
        eventVolunteer: { include: { user: true } },
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
    return this.prisma.scheduleAssignment.findMany({
      where: {
        eventVolunteerId: contextVolunteerId,
        ...(status && { status: status as 'PENDING' | 'ACCEPTED' | 'DECLINED' | 'AUTO_DECLINED' }),
      },
      include: {
        eventVolunteer: { include: { user: true } },
        post: { include: { department: { include: { event: true } }, area: true } },
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
        eventVolunteer: { include: { user: true } },
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
        eventVolunteer: { include: { user: true } },
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

    // Get all ACCEPTED + PENDING assignments for these posts (include shift data)
    const postIds = posts.map((p) => p.id);
    const sessionIds = sessions.map((s) => s.id);

    const assignments = await this.prisma.scheduleAssignment.findMany({
      where: {
        postId: { in: postIds },
        status: { in: ['ACCEPTED', 'PENDING'] },
      },
      include: {
        eventVolunteer: {
          include: { user: { select: { firstName: true, lastName: true } } },
        },
        checkIn: {
          select: { id: true, checkInTime: true },
        },
        shift: {
          select: { id: true, name: true, startTime: true, endTime: true },
        },
      },
    });

    // Fetch all shifts for these posts+sessions in one query
    const shifts = await this.prisma.shift.findMany({
      where: { sessionId: { in: sessionIds }, postId: { in: postIds } },
      orderBy: { startTime: 'asc' },
    });

    // Build per-slot shift lookup: "postId-sessionId" -> Shift[]
    const shiftsBySlot = new Map<string, typeof shifts>();
    for (const shift of shifts) {
      const key = `${shift.postId}-${shift.sessionId}`;
      const arr = shiftsBySlot.get(key) || [];
      arr.push(shift);
      shiftsBySlot.set(key, arr);
    }

    // Build the coverage matrix
    const coverageSlots: CoverageSlot[] = [];

    for (const post of posts) {
      for (const session of sessions) {
        const slotAssignments = assignments.filter(
          (a) =>
            a.postId === post.id &&
            a.sessionId === session.id &&
            a.eventVolunteer?.user
        );

        const acceptedCount = slotAssignments.filter(
          (a) => a.status === 'ACCEPTED'
        ).length;

        const slotShifts = shiftsBySlot.get(`${post.id}-${session.id}`) || [];

        coverageSlots.push({
          post: {
            id: post.id,
            name: post.name,
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
          shifts: slotShifts.map((s) => ({
            id: s.id,
            name: s.name,
            startTime: s.startTime,
            endTime: s.endTime,
          })),
          assignments: slotAssignments.map((a) => ({
            id: a.id,
            volunteer: a.eventVolunteer?.user
              ? {
                  id: a.eventVolunteer.id,
                  firstName: a.eventVolunteer.user.firstName,
                  lastName: a.eventVolunteer.user.lastName,
                }
              : null,
            checkIn: a.checkIn,
            status: a.status,
            forceAssigned: a.forceAssigned,
            canCount: a.canCount,
            shiftId: a.shift?.id ?? null,
            shiftName: a.shift?.name ?? null,
          })),
          filled: acceptedCount,
        });
      }
    }

    return coverageSlots;
  }

  /**
   * Get coverage gaps (slots with no assignments) for a department
   */
  async getDepartmentCoverageGaps(departmentId: string): Promise<CoverageSlot[]> {
    const coverage = await this.getDepartmentCoverage(departmentId);
    return coverage.filter((slot) => slot.filled === 0);
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
    const isOwner = this.isAssignmentOwner(assignment, contextVolunteerId);
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
        eventVolunteer: { include: { user: true } },
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
    const isOwner = this.isAssignmentOwner(assignment, contextVolunteerId);
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
        eventVolunteer: { include: { user: true } },
        post: { include: { department: true } },
        session: true,
      },
    });
  }

  /**
   * Force-assign a volunteer (overseer action) - bypasses acceptance workflow
   */
  async forceAssignment(input: ForceAssignmentInput, createdByUserId?: string): Promise<ScheduleAssignment> {
    const result = forceAssignmentSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { volunteerId, postId, sessionId, shiftId, isCaptain, canCount } = result.data;

    // Verify eventVolunteer exists
    const eventVolunteer = await this.prisma.eventVolunteer.findUnique({
      where: { id: volunteerId },
    });
    if (!eventVolunteer) {
      throw new NotFoundError('Volunteer');
    }

    // Verify post exists
    const post = await this.prisma.post.findUnique({
      where: { id: postId },
      include: { department: { select: { departmentType: true } } },
    });
    if (!post) {
      throw new NotFoundError('Post');
    }

    // Captain designation is only supported for the Attendant department
    if (isCaptain && post.department.departmentType !== 'ATTENDANT') {
      throw new ValidationError('Captain designation is only available for the Attendant department');
    }

    // Verify session exists
    const session = await this.prisma.session.findUnique({
      where: { id: sessionId },
    });
    if (!session) {
      throw new NotFoundError('Session');
    }

    // If shiftId provided, validate it belongs to the session
    if (shiftId) {
      const shift = await this.prisma.shift.findUnique({
        where: { id: shiftId },
        select: { sessionId: true },
      });
      if (!shift) throw new NotFoundError('Shift');
      if (shift.sessionId !== sessionId) {
        throw new ValidationError('Shift does not belong to the specified session');
      }
    }

    // Check if assignment already exists for this volunteer/session/shift combo
    const existing = await this.prisma.scheduleAssignment.findFirst({
      where: {
        eventVolunteerId: volunteerId,
        sessionId,
        shiftId: shiftId || null,
      },
    });

    if (existing) {
      return this.prisma.scheduleAssignment.update({
        where: { id: existing.id },
        data: {
          postId,
          status: 'ACCEPTED',
          forceAssigned: true,
          isCaptain: isCaptain ?? existing.isCaptain,
          canCount: canCount ?? existing.canCount,
          respondedAt: new Date(),
        },
        include: {
          eventVolunteer: { include: { user: true } },
          post: { include: { department: true } },
          session: true,
          shift: true,
        },
      });
    }

    // Create new force-assigned assignment
    return this.prisma.scheduleAssignment.create({
      data: {
        eventVolunteerId: volunteerId,
        postId,
        sessionId,
        shiftId: shiftId || undefined,
        status: 'ACCEPTED',
        forceAssigned: true,
        isCaptain: isCaptain ?? false,
        canCount: canCount ?? false,
        respondedAt: new Date(),
        ...(createdByUserId ? { createdByUserId } : {}),
      },
      include: {
        eventVolunteer: { include: { user: true } },
        post: { include: { department: true } },
        session: true,
        shift: true,
        createdBy: true,
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
      include: { post: { include: { department: { select: { departmentType: true } } } } },
    });

    if (!assignment) {
      throw new NotFoundError('Assignment');
    }

    // Captain designation is only supported for the Attendant department
    if (result.data.isCaptain && assignment.post.department.departmentType !== 'ATTENDANT') {
      throw new ValidationError('Captain designation is only available for the Attendant department');
    }

    return this.prisma.scheduleAssignment.update({
      where: { id: assignment.id },
      data: { isCaptain: result.data.isCaptain },
      include: {
        eventVolunteer: { include: { user: true } },
        post: { include: { department: true } },
        session: true,
      },
    });
  }

  /**
   * Set canCount status on an assignment (overseer or captain action)
   */
  async setCanCount(input: SetCanCountInput): Promise<ScheduleAssignment> {
    const result = setCanCountSchema.safeParse(input);
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
      data: { canCount: result.data.canCount },
      include: {
        eventVolunteer: { include: { user: true } },
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
        eventVolunteerId: captainVolunteerId,
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
          ? `Checked in by captain. ${result.data.notes}`
          : 'Checked in by captain',
        status: 'CHECKED_IN',
      },
    });

    // Return updated assignment with check-in
    return this.prisma.scheduleAssignment.findUniqueOrThrow({
      where: { id: targetAssignment.id },
      include: {
        eventVolunteer: { include: { user: true } },
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
        eventVolunteerId: captainVolunteerId,
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
        eventVolunteerId: { not: captainVolunteerId },
      },
      include: {
        eventVolunteer: { include: { user: true } },
        checkIn: true,
      },
      orderBy: { eventVolunteer: { user: { lastName: 'asc' } } },
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
        eventVolunteer: { include: { user: true } },
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
        eventVolunteer: { include: { user: true } },
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

    let totalCount = 0;

    // Auto-decline ScheduleAssignments past their deadline
    const pastDeadline = await this.prisma.scheduleAssignment.findMany({
      where: {
        status: 'PENDING',
        acceptedDeadline: { lt: now },
      },
    });

    if (pastDeadline.length > 0) {
      const result = await this.prisma.scheduleAssignment.updateMany({
        where: {
          id: { in: pastDeadline.map((a) => a.id) },
        },
        data: {
          status: 'AUTO_DECLINED',
          respondedAt: now,
        },
      });
      totalCount += result.count;
    }

    // Auto-decline AreaCaptain assignments past their deadline
    const pastDeadlineCaptains = await this.prisma.areaCaptain.findMany({
      where: {
        status: 'PENDING',
        acceptedDeadline: { lt: now },
      },
    });

    if (pastDeadlineCaptains.length > 0) {
      const captainResult = await this.prisma.areaCaptain.updateMany({
        where: {
          id: { in: pastDeadlineCaptains.map((a) => a.id) },
        },
        data: {
          status: 'AUTO_DECLINED',
          respondedAt: now,
        },
      });
      totalCount += captainResult.count;
    }

    return totalCount;
  }

  /**
   * Copy assignments from one session to another for specific areas/posts.
   * Skips volunteers who already have assignments in the target session.
   */
  async copySessionAssignments(
    input: CopySessionAssignmentsInput,
    createdByUserId: string
  ): Promise<{
    copiedCount: number;
    skippedCount: number;
    skippedVolunteers: Array<{ volunteerName: string; postName: string; reason: string }>;
    copiedAreaCaptains: number;
    copiedVolunteerUserIds: string[];
  }> {
    const result = copySessionAssignmentsSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const {
      sourceSessionId,
      targetSessionId,
      departmentId,
      areaIds,
      postIds,
      copyIsCaptain,
      copyCanCount,
      copyAreaCaptains,
      forceAssign,
    } = result.data;

    // Verify entities exist and belong to same event
    const [sourceSession, targetSession, department] = await Promise.all([
      this.prisma.session.findUnique({ where: { id: sourceSessionId }, select: { id: true, eventId: true } }),
      this.prisma.session.findUnique({ where: { id: targetSessionId }, select: { id: true, eventId: true } }),
      this.prisma.department.findUnique({ where: { id: departmentId }, select: { id: true, eventId: true } }),
    ]);

    if (!sourceSession) throw new NotFoundError('Source session');
    if (!targetSession) throw new NotFoundError('Target session');
    if (!department) throw new NotFoundError('Department');

    if (sourceSession.eventId !== targetSession.eventId) {
      throw new ValidationError('Source and target sessions must belong to the same event');
    }
    if (department.eventId !== sourceSession.eventId) {
      throw new ValidationError('Department must belong to the same event as sessions');
    }

    // Resolve which posts to copy
    let resolvedPostIds: string[];

    if (postIds) {
      // Verify posts belong to this department
      const posts = await this.prisma.post.findMany({
        where: { id: { in: postIds }, departmentId },
        select: { id: true },
      });
      resolvedPostIds = posts.map(p => p.id);
    } else if (areaIds) {
      const posts = await this.prisma.post.findMany({
        where: { areaId: { in: areaIds }, departmentId },
        select: { id: true },
      });
      resolvedPostIds = posts.map(p => p.id);
    } else {
      const posts = await this.prisma.post.findMany({
        where: { departmentId },
        select: { id: true },
      });
      resolvedPostIds = posts.map(p => p.id);
    }

    if (resolvedPostIds.length === 0) {
      return { copiedCount: 0, skippedCount: 0, skippedVolunteers: [], copiedAreaCaptains: 0, copiedVolunteerUserIds: [] };
    }

    // Fetch source assignments (ACCEPTED + PENDING only)
    const sourceAssignments = await this.prisma.scheduleAssignment.findMany({
      where: {
        sessionId: sourceSessionId,
        postId: { in: resolvedPostIds },
        status: { in: ['ACCEPTED', 'PENDING'] },
      },
      include: {
        eventVolunteer: { include: { user: { select: { firstName: true, lastName: true } } } },
        post: { select: { name: true } },
      },
    });

    if (sourceAssignments.length === 0) {
      return { copiedCount: 0, skippedCount: 0, skippedVolunteers: [], copiedAreaCaptains: 0, copiedVolunteerUserIds: [] };
    }

    // Check for conflicts: volunteers who already have assignments in the target session
    // Only check within the same department's posts to avoid blocking cross-department assignments
    const sourceVolunteerIds = [...new Set(sourceAssignments.map(a => a.eventVolunteerId))];
    const existingTargetAssignments = await this.prisma.scheduleAssignment.findMany({
      where: {
        sessionId: targetSessionId,
        eventVolunteerId: { in: sourceVolunteerIds },
        post: { departmentId },
      },
      select: { eventVolunteerId: true },
    });

    const conflictVolunteerIds = new Set(existingTargetAssignments.map(a => a.eventVolunteerId));

    const skippedVolunteers: Array<{ volunteerName: string; postName: string; reason: string }> = [];
    const skippedVolunteerIds = new Set<string>();
    const toCreate: Array<{
      eventVolunteerId: string;
      postId: string;
      sessionId: string;
      status: 'PENDING' | 'ACCEPTED';
      forceAssigned: boolean;
      isCaptain: boolean;
      canCount: boolean;
      createdByUserId: string;
    }> = [];
    const copiedVolunteerUserIds: string[] = [];

    for (const assignment of sourceAssignments) {
      const volunteerName = assignment.eventVolunteer?.user
        ? `${assignment.eventVolunteer.user.firstName} ${assignment.eventVolunteer.user.lastName}`
        : 'Unknown';
      const postName = assignment.post?.name ?? 'Unknown';

      if (!forceAssign && conflictVolunteerIds.has(assignment.eventVolunteerId)) {
        // Deduplicate skip entries per volunteer
        if (!skippedVolunteerIds.has(assignment.eventVolunteerId)) {
          skippedVolunteerIds.add(assignment.eventVolunteerId);
          skippedVolunteers.push({
            volunteerName,
            postName,
            reason: 'Already assigned in target session',
          });
        }
        continue;
      }

      toCreate.push({
        eventVolunteerId: assignment.eventVolunteerId,
        postId: assignment.postId,
        sessionId: targetSessionId,
        status: forceAssign ? 'ACCEPTED' : 'PENDING',
        forceAssigned: forceAssign,
        isCaptain: copyIsCaptain ? assignment.isCaptain : false,
        canCount: copyCanCount ? assignment.canCount : false,
        createdByUserId,
      });
    }

    // Bulk create
    let copiedCount = 0;
    if (toCreate.length > 0) {
      const created = await this.prisma.scheduleAssignment.createMany({
        data: toCreate,
        skipDuplicates: true,
      });
      copiedCount = created.count;

      // Collect volunteer user IDs for notifications
      const volunteerIds = [...new Set(toCreate.map(a => a.eventVolunteerId))];
      const volunteers = await this.prisma.eventVolunteer.findMany({
        where: { id: { in: volunteerIds } },
        select: { user: { select: { id: true } } },
      });
      copiedVolunteerUserIds.push(...volunteers.map(v => v.user.id));
    }

    // Copy area captains if requested
    let copiedAreaCaptains = 0;
    if (copyAreaCaptains) {
      // Resolve which areas are in scope
      let resolvedAreaIds: string[];
      if (areaIds) {
        resolvedAreaIds = areaIds;
      } else if (postIds) {
        // Get areas from the selected posts
        const postsWithAreas = await this.prisma.post.findMany({
          where: { id: { in: postIds }, areaId: { not: null } },
          select: { areaId: true },
        });
        resolvedAreaIds = [...new Set(postsWithAreas.map(p => p.areaId!))];
      } else {
        // All areas in department
        const areas = await this.prisma.area.findMany({
          where: { departmentId },
          select: { id: true },
        });
        resolvedAreaIds = areas.map(a => a.id);
      }

      if (resolvedAreaIds.length > 0) {
        // Fetch source area captains
        const sourceCaptains = await this.prisma.areaCaptain.findMany({
          where: {
            areaId: { in: resolvedAreaIds },
            sessionId: sourceSessionId,
          },
        });

        // Check which already exist in target
        const existingTargetCaptains = await this.prisma.areaCaptain.findMany({
          where: {
            areaId: { in: resolvedAreaIds },
            sessionId: targetSessionId,
          },
          select: { areaId: true },
        });
        const existingCaptainAreaIds = new Set(existingTargetCaptains.map(c => c.areaId));

        const captainsToCreate = sourceCaptains
          .filter(c => !existingCaptainAreaIds.has(c.areaId))
          .map(c => ({
            areaId: c.areaId,
            sessionId: targetSessionId,
            eventVolunteerId: c.eventVolunteerId,
            status: forceAssign ? 'ACCEPTED' as const : 'PENDING' as const,
            forceAssigned: forceAssign,
          }));

        if (captainsToCreate.length > 0) {
          const created = await this.prisma.areaCaptain.createMany({
            data: captainsToCreate,
            skipDuplicates: true,
          });
          copiedAreaCaptains = created.count;
        }
      }
    }

    return {
      copiedCount,
      skippedCount: skippedVolunteers.length,
      skippedVolunteers,
      copiedAreaCaptains,
      copiedVolunteerUserIds,
    };
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
        eventVolunteer: { include: { user: true } },
        post: { include: { department: true } },
        session: true,
      },
    });
  }
}
