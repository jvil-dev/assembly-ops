/**
 * Attendance Service
 *
 * Business logic for recording audience attendance counts with section support.
 * Used for CO-24 reporting at assemblies and conventions.
 *
 * Methods:
 *   - submitAttendanceCount(userId, input): Record count for session/section
 *   - updateAttendanceCount(id, input): Update an existing count
 *   - deleteAttendanceCount(id): Remove a count record
 *   - getAttendanceCount(id): Get single count by ID
 *   - getSessionAttendanceCounts(sessionId): All counts for a session
 *   - getSessionTotalAttendance(sessionId): Sum of all section counts
 *   - getEventAttendanceSummary(eventId): Aggregated counts per session
 *   - getSessionEventId(sessionId): Get event ID for access control
 *
 * Section Support:
 *   Attendance can be recorded per section (e.g., "A1", "B2", "Floor", "Balcony").
 *   Multiple counts per session allowed if sections differ.
 *   Unique constraint: [sessionId, section] - upsert updates existing.
 *
 * Business Rules:
 *   - One count per session+section combination (upsert on conflict)
 *   - Only overseers with event access can submit/update/delete
 *   - Counts ordered by session date and time for reports
 *
 * Called by: ../graphql/resolvers/attendance.ts
 */

import { PrismaClient, AttendanceCount, EventRole } from '@prisma/client';
import { NotFoundError, ValidationError, AuthorizationError } from '../utils/errors.js';
import {
  SubmitAttendanceCountInput,
  UpdateAttendanceCountInput,
  submitAttendanceCountSchema,
  updateAttendanceCountSchema,
} from '../graphql/validators/attendance.js';

export class AttendanceService {
  constructor(private prisma: PrismaClient) {}

  /**
   * Submit attendance count for a session section
   */
  async submitAttendanceCount(
    adminId: string,
    input: SubmitAttendanceCountInput
  ): Promise<AttendanceCount> {
    const result = submitAttendanceCountSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { sessionId, section, count, notes } = result.data;

    // Verify session exists
    const session = await this.prisma.session.findUnique({
      where: { id: sessionId },
    });

    if (!session) {
      throw new NotFoundError('Session');
    }

    // Upsert attendance count (update if exists for this session/section)
    return this.prisma.attendanceCount.upsert({
      where: {
        sessionId_section: {
          sessionId,
          section: section ?? '',
        },
      },
      create: {
        sessionId,
        section,
        count,
        notes,
        submittedById: adminId,
      },
      update: {
        count,
        notes,
        submittedById: adminId,
      },
      include: {
        session: true,
        submittedBy: true,
      },
    });
  }

  /**
   * Submit attendance count as an attendant volunteer (post-scoped).
   * Requires postId and verifies volunteer has an ACCEPTED assignment on that post.
   */
  async submitVolunteerAttendanceCount(
    eventVolunteerId: string,
    input: SubmitAttendanceCountInput
  ): Promise<AttendanceCount> {
    const result = submitAttendanceCountSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { sessionId, postId, count, notes } = result.data;

    if (!postId) {
      throw new ValidationError('postId is required for volunteer count submission');
    }

    // Verify session exists
    const session = await this.prisma.session.findUnique({
      where: { id: sessionId },
    });
    if (!session) {
      throw new NotFoundError('Session');
    }

    // Verify volunteer has an ACCEPTED assignment on this post
    const assignment = await this.prisma.scheduleAssignment.findFirst({
      where: {
        eventVolunteerId,
        postId,
        status: 'ACCEPTED',
      },
    });

    if (!assignment) {
      throw new AuthorizationError('You do not have an accepted assignment on this post');
    }

    // Get post name to use as the section label
    const post = await this.prisma.post.findUnique({
      where: { id: postId },
      select: { name: true },
    });

    // Upsert using the post name as the section label
    return this.prisma.attendanceCount.upsert({
      where: {
        sessionId_section: {
          sessionId,
          section: post?.name ?? '',
        },
      },
      create: {
        sessionId,
        section: post?.name,
        postId,
        count,
        notes,
        submittedById: (await this.getSubmittingAdminId(session.eventId)),
      },
      update: {
        count,
        notes,
        postId,
      },
      include: {
        session: true,
        submittedBy: true,
      },
    });
  }

  /**
   * Get the event overseer admin ID for volunteer-submitted counts.
   * AttendanceCount.submittedById is a required FK to Admin, so we use the event overseer.
   */
  private async getSubmittingAdminId(eventId: string): Promise<string> {
    const eventAdmin = await this.prisma.eventAdmin.findFirst({
      where: { eventId, role: EventRole.APP_ADMIN },
      select: { userId: true },
    });

    if (!eventAdmin) {
      throw new NotFoundError('Event overseer');
    }

    return eventAdmin.userId;
  }

  /**
   * Update an attendance count
   */
  async updateAttendanceCount(
    id: string,
    input: UpdateAttendanceCountInput
  ): Promise<AttendanceCount> {
    const result = updateAttendanceCountSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const existing = await this.prisma.attendanceCount.findUnique({
      where: { id },
    });

    if (!existing) {
      throw new NotFoundError('Attendance count');
    }

    return this.prisma.attendanceCount.update({
      where: { id },
      data: {
        count: result.data.count ?? existing.count,
        notes: result.data.notes,
      },
      include: {
        session: true,
        submittedBy: true,
      },
    });
  }

  /**
   * Get a single attendance count by ID
   */
  async getAttendanceCount(id: string): Promise<AttendanceCount | null> {
    return this.prisma.attendanceCount.findUnique({
      where: { id },
      include: {
        session: true,
        submittedBy: true,
      },
    });
  }

  /**
   * Get attendance count for a session
   */
  async getSessionAttendanceCounts(sessionId: string): Promise<AttendanceCount[]> {
    return this.prisma.attendanceCount.findMany({
      where: { sessionId },
      include: {
        submittedBy: true,
      },
      orderBy: { section: 'asc' },
    });
  }

  /**
   * Get total attendance count for a session (sum of all sections)
   */
  async getSessionTotalAttendance(sessionId: string): Promise<number> {
    const counts = await this.prisma.attendanceCount.aggregate({
      where: { sessionId },
      _sum: { count: true },
    });

    return counts._sum.count ?? 0;
  }

  /**
   * Get attendance count for an event (all sessions)
   */
  async getEventAttendanceCounts(eventId: string): Promise<AttendanceCount[]> {
    return this.prisma.attendanceCount.findMany({
      where: {
        session: { eventId },
      },
      include: {
        session: true,
        submittedBy: true,
      },
      orderBy: [
        { session: { date: 'asc' } },
        { session: { startTime: 'asc' } },
        { section: 'asc' },
      ],
    });
  }

  /**
   * Get attendance summary for an event
   */
  async getEventAttendanceSummary(eventId: string) {
    const sessions = await this.prisma.session.findMany({
      where: { eventId },
      include: {
        attendanceCounts: true,
      },
      orderBy: [{ date: 'asc' }, { startTime: 'asc' }],
    });

    return sessions.map((session) => {
      const counts = session.attendanceCounts;
      const total = counts.reduce((sum, c) => sum + c.count, 0);

      return {
        session,
        totalCount: total,
        sectionCounts: counts,
      };
    });
  }

  /**
   * Delete an attendance count
   */
  async deleteAttendanceCount(id: string): Promise<boolean> {
    const existing = await this.prisma.attendanceCount.findUnique({
      where: { id },
    });

    if (!existing) {
      throw new NotFoundError('Attendance count');
    }

    await this.prisma.attendanceCount.delete({
      where: { id },
    });

    return true;
  }

  /**
   * Get session's event ID for access control
   */
  async getSessionEventId(sessionId: string): Promise<string> {
    const session = await this.prisma.session.findUnique({
      where: { id: sessionId },
      select: { eventId: true },
    });

    if (!session) {
      throw new NotFoundError('Session');
    }

    return session.eventId;
  }

  /**
   * Get attendance count's event ID for access control
   */
  async getAttendanceCountEventId(id: string): Promise<string> {
    const count = await this.prisma.attendanceCount.findUnique({
      where: { id },
      include: { session: { select: { eventId: true } } },
    });

    if (!count) {
      throw new NotFoundError('Attendance count');
    }

    return count.session.eventId;
  }
}
