/**
 * Reminder Confirmation Service
 *
 * Business logic for mandatory shift/session reminder confirmations.
 * Handles upserts (idempotent confirmations) and compliance queries.
 *
 * Methods:
 *   - confirmShiftReminder(eventVolunteerId, shiftId): Upsert shift confirmation
 *   - confirmSessionReminder(eventVolunteerId, sessionId): Upsert session confirmation
 *   - getMyConfirmations(eventVolunteerId): All confirmations for a volunteer
 *   - getShiftReminderStatus(shiftId): Per-shift compliance summary
 *
 * Used by: ../graphql/resolvers/reminder.ts
 */
import { PrismaClient } from '@prisma/client';

export class ReminderService {
  constructor(private prisma: PrismaClient) {}

  async confirmShiftReminder(eventVolunteerId: string, shiftId: string) {
    // Verify the shift exists
    const shift = await this.prisma.shift.findUnique({
      where: { id: shiftId },
    });
    if (!shift) throw new Error('Shift not found');

    // Upsert — idempotent confirmation
    return this.prisma.reminderConfirmation.upsert({
      where: {
        eventVolunteerId_shiftId: { eventVolunteerId, shiftId },
      },
      update: {}, // Already confirmed — no-op
      create: {
        eventVolunteerId,
        shiftId,
      },
    });
  }

  async confirmSessionReminder(eventVolunteerId: string, sessionId: string) {
    // Verify the session exists
    const session = await this.prisma.session.findUnique({
      where: { id: sessionId },
    });
    if (!session) throw new Error('Session not found');

    // Upsert — idempotent confirmation
    return this.prisma.reminderConfirmation.upsert({
      where: {
        eventVolunteerId_sessionId: { eventVolunteerId, sessionId },
      },
      update: {},
      create: {
        eventVolunteerId,
        sessionId,
      },
    });
  }

  async getMyConfirmations(eventVolunteerId: string) {
    return this.prisma.reminderConfirmation.findMany({
      where: { eventVolunteerId },
      orderBy: { confirmedAt: 'desc' },
    });
  }

  async getShiftReminderStatus(shiftId: string) {
    const shift = await this.prisma.shift.findUnique({
      where: { id: shiftId },
    });
    if (!shift) throw new Error('Shift not found');

    // Get all assignments for this shift
    const assignments = await this.prisma.scheduleAssignment.findMany({
      where: { shiftId },
      include: {
        eventVolunteer: {
          include: { user: true },
        },
      },
    });

    // Get confirmations for this shift
    const confirmations = await this.prisma.reminderConfirmation.findMany({
      where: { shiftId },
    });
    const confirmedSet = new Map(
      confirmations.map((c) => [c.eventVolunteerId, c.confirmedAt])
    );

    const volunteerStatuses = assignments.map((a) => ({
      eventVolunteerId: a.eventVolunteerId,
      firstName: a.eventVolunteer.user.firstName,
      lastName: a.eventVolunteer.user.lastName,
      confirmed: confirmedSet.has(a.eventVolunteerId),
      confirmedAt: confirmedSet.get(a.eventVolunteerId) ?? null,
    }));

    return {
      shiftId,
      shiftName: shift.name,
      totalAssigned: assignments.length,
      totalConfirmed: confirmedSet.size,
      confirmations: volunteerStatuses,
    };
  }
}
