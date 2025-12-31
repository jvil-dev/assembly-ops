/**
 * Attendance Service
 *
 * Business logic for recording audience attendance counts (CO-24 reporting).
 *
 * Methods:
 *   - recordAttendance(adminId, input): Record attendance count for a session
 *   - updateAttendance(attendanceId, input): Update an existing attendance record
 *   - getAttendance(sessionId): Get attendance count for a session
 *   - getEventAttendance(eventId): Get all attendance counts for an event
 *   - deleteAttendance(attendanceId): Delete an attendance record
 *   - getSessionEventId(sessionId): Get event ID for access control
 *
 * Business Rules:
 *   - Only one attendance count per session (use update for corrections)
 *   - Only EVENT_OVERSEER can record/update/delete attendance
 *   - Ordered by session date and time for event-wide queries
 *
 * Called by: ../graphql/resolvers/checkIn.ts
 */
import { PrismaClient, AttendanceCount } from '@prisma/client';
import { NotFoundError, ValidationError, ConflictError } from '../utils/errors.js';
import {
  recordAttendanceSchema,
  updateAttendanceSchema,
  RecordAttendanceInput,
  UpdateAttendanceInput,
} from '../graphql/validators/checkIn.js';

export class AttendanceService {
  constructor(private prisma: PrismaClient) {}

  /**
   * Record attendance count for a session
   */
  async recordAttendance(adminId: string, input: RecordAttendanceInput): Promise<AttendanceCount> {
    const result = recordAttendanceSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const { sessionId, count, notes } = result.data;

    // Verify session exists
    const session = await this.prisma.session.findUnique({
      where: { id: sessionId },
    });
    if (!session) {
      throw new NotFoundError('Session');
    }

    // Check if attendance already recorded
    const existing = await this.prisma.attendanceCount.findUnique({
      where: { sessionId },
    });

    if (existing) {
      throw new ConflictError('Attendance already recorded for this session. Use update instead');
    }

    return this.prisma.attendanceCount.create({
      data: {
        count,
        notes,
        sessionId,
        submittedById: adminId,
      },
      include: {
        session: true,
        submittedBy: true,
      },
    });
  }

  /**
   * Update attendance count for a session
   */
  async updateAttendance(
    attendanceId: string,
    input: UpdateAttendanceInput
  ): Promise<AttendanceCount> {
    const result = updateAttendanceSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const validated = result.data;

    const attendance = await this.prisma.attendanceCount.findUnique({
      where: { id: attendanceId },
    });

    if (!attendance) {
      throw new NotFoundError('Attendance record');
    }

    return this.prisma.attendanceCount.update({
      where: { id: attendanceId },
      data: {
        count: validated.count,
        notes: validated.notes,
      },
      include: {
        session: true,
        submittedBy: true,
      },
    });
  }

  /**
   * Get attendance count for a session
   */
  async getAttendance(sessionId: string) {
    return this.prisma.attendanceCount.findUnique({
      where: { sessionId },
      include: {
        session: true,
        submittedBy: true,
      },
    });
  }

  /**
   * Get all attendance counts for an event
   */
  async getEventAttendance(eventId: string) {
    return this.prisma.attendanceCount.findMany({
      where: {
        session: { eventId },
      },
      include: {
        session: true,
        submittedBy: true,
      },
      orderBy: [{ session: { date: 'asc' } }, { session: { startTime: 'asc' } }],
    });
  }

  /**
   * Delete attendance record
   */
  async deleteAttendance(attendanceId: string): Promise<boolean> {
    const attendance = await this.prisma.attendanceCount.findUnique({
      where: { id: attendanceId },
    });

    if (!attendance) {
      throw new NotFoundError('Attendance record');
    }

    await this.prisma.attendanceCount.delete({
      where: { id: attendanceId },
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
}
