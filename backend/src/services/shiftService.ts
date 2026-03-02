/**
 * Shift Service
 *
 * Business logic for sub-session shift management.
 * Shifts subdivide sessions into custom time blocks. Shift times are free-form
 * (not constrained to session program times) since departments like Attendant
 * and Parking start duty before the program begins.
 *
 * Methods:
 *   - createShift(input): Create a shift within a session
 *   - updateShift(id, input): Update shift times
 *   - deleteShift(id): Delete a shift (cascades assignments)
 *   - getShifts(sessionId): Get all shifts for a session
 *   - getShiftSessionId(id): Get parent sessionId for access control
 *
 * Validation:
 *   - endTime must be after startTime
 *   - No overlapping shifts within the same session
 *
 * Called by: ../graphql/resolvers/shift.ts
 */
import { PrismaClient, Shift } from '@prisma/client';
import { ValidationError, NotFoundError } from '../utils/errors.js';
import { timeStringToDate } from '../utils/time.js';
import {
  createShiftSchema,
  updateShiftSchema,
  CreateShiftInput,
  UpdateShiftInput,
} from '../graphql/validators/shift.js';

/** Auto-generate a shift name from its time range (e.g., "07:45 – 08:45") */
function generateShiftName(startTime: string, endTime: string): string {
  return `${startTime} – ${endTime}`;
}

export class ShiftService {
  constructor(private prisma: PrismaClient) {}

  async createShift(input: CreateShiftInput, createdByUserId?: string): Promise<Shift> {
    const result = createShiftSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }
    const { sessionId, postId, startTime, endTime } = result.data;

    // Validate session exists
    const session = await this.prisma.session.findUnique({
      where: { id: sessionId },
    });
    if (!session) {
      throw new NotFoundError('Session not found');
    }

    // Validate post exists
    const post = await this.prisma.post.findUnique({
      where: { id: postId },
    });
    if (!post) {
      throw new NotFoundError('Post not found');
    }

    // Validate endTime > startTime
    const start = timeStringToDate(startTime);
    const end = timeStringToDate(endTime);
    if (end <= start) {
      throw new ValidationError('End time must be after start time');
    }

    // Check for overlapping shifts on the same post in the same session
    await this.checkOverlap(sessionId, postId, start, end);

    // Auto-generate name from time range
    const name = generateShiftName(startTime, endTime);

    return this.prisma.shift.create({
      data: {
        sessionId,
        postId,
        name,
        startTime: start,
        endTime: end,
        ...(createdByUserId ? { createdByUserId } : {}),
      },
      include: { session: true, post: true, createdBy: true },
    });
  }

  async updateShift(id: string, input: UpdateShiftInput): Promise<Shift> {
    const result = updateShiftSchema.safeParse(input);
    if (!result.success) {
      throw new ValidationError(result.error.issues[0].message);
    }

    const existing = await this.prisma.shift.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError('Shift not found');
    }

    const startTime = result.data.startTime
      ? timeStringToDate(result.data.startTime)
      : existing.startTime;
    const endTime = result.data.endTime
      ? timeStringToDate(result.data.endTime)
      : existing.endTime;

    if (endTime <= startTime) {
      throw new ValidationError('End time must be after start time');
    }

    // Check overlap excluding self (scoped to same post + session)
    await this.checkOverlap(existing.sessionId, existing.postId, startTime, endTime, id);

    // Re-generate name from the (potentially updated) time range
    const startStr = result.data.startTime ?? this.formatTime(existing.startTime);
    const endStr = result.data.endTime ?? this.formatTime(existing.endTime);
    const name = generateShiftName(startStr, endStr);

    return this.prisma.shift.update({
      where: { id },
      data: {
        name,
        startTime: result.data.startTime ? startTime : undefined,
        endTime: result.data.endTime ? endTime : undefined,
      },
      include: { session: true, post: true },
    });
  }

  async deleteShift(id: string): Promise<boolean> {
    const shift = await this.prisma.shift.findUnique({ where: { id } });
    if (!shift) {
      throw new NotFoundError('Shift not found');
    }
    await this.prisma.shift.delete({ where: { id } });
    return true;
  }

  async getShifts(sessionId: string, postId?: string): Promise<Shift[]> {
    return this.prisma.shift.findMany({
      where: { sessionId, ...(postId ? { postId } : {}) },
      include: { session: true, post: true, createdBy: true },
      orderBy: { startTime: 'asc' },
    });
  }

  async getShiftSessionId(id: string): Promise<string> {
    const shift = await this.prisma.shift.findUnique({
      where: { id },
      select: { sessionId: true },
    });
    if (!shift) {
      throw new NotFoundError('Shift not found');
    }
    return shift.sessionId;
  }

  /** Format a Date (time-only) back to HH:MM string */
  private formatTime(date: Date): string {
    const hours = date.getUTCHours().toString().padStart(2, '0');
    const minutes = date.getUTCMinutes().toString().padStart(2, '0');
    return `${hours}:${minutes}`;
  }

  /**
   * Check that a new/updated shift does not overlap with existing shifts
   * in the same post + session. Excludes the shift with `excludeId` (for updates).
   */
  private async checkOverlap(
    sessionId: string,
    postId: string,
    startTime: Date,
    endTime: Date,
    excludeId?: string
  ): Promise<void> {
    const existingShifts = await this.prisma.shift.findMany({
      where: {
        sessionId,
        postId,
        ...(excludeId ? { id: { not: excludeId } } : {}),
      },
    });

    for (const shift of existingShifts) {
      // Overlap: new start < existing end AND new end > existing start
      if (startTime < shift.endTime && endTime > shift.startTime) {
        throw new ValidationError(
          `Shift overlaps with existing shift "${shift.name}" (${shift.startTime.toISOString()} - ${shift.endTime.toISOString()})`
        );
      }
    }
  }
}
