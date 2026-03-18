/**
 * AttendantService Unit Tests
 *
 * Tests the updateMeeting business logic: validation, not-found errors,
 * partial updates, and atomic attendee replacement via transaction.
 * Prisma is mocked via createPrismaMock() so no database is required.
 */
import { vi, describe, it, expect, beforeEach } from 'vitest';
import { createPrismaMock } from '../unitTestHelpers.js';
import { AttendantService } from '../../services/attendantService.js';
import { NotFoundError, ValidationError } from '../../utils/errors.js';

// ---------------------------------------------------------------------------
// Shared mock data
// ---------------------------------------------------------------------------

function makeMeeting(overrides: Record<string, unknown> = {}) {
  return {
    id: 'meeting-1',
    eventId: 'event-1',
    sessionId: 'session-1',
    meetingDate: new Date('2026-03-20T07:00:00Z'),
    notes: 'Initial briefing',
    createdById: 'user-1',
    createdAt: new Date(),
    updatedAt: new Date(),
    session: { id: 'session-1', name: 'Saturday AM' },
    createdBy: { id: 'user-1', firstName: 'John', lastName: 'Doe' },
    attendees: [
      {
        id: 'ma-1',
        eventVolunteerId: 'ev-1',
        eventVolunteer: { id: 'ev-1', user: { firstName: 'Jane', lastName: 'Smith' } },
      },
    ],
    ...overrides,
  };
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe('AttendantService', () => {
  let prisma: ReturnType<typeof createPrismaMock>;
  let service: AttendantService;

  beforeEach(() => {
    vi.clearAllMocks();
    prisma = createPrismaMock();
    service = new AttendantService(prisma);
  });

  describe('updateMeeting', () => {
    it('throws ValidationError when id is empty', async () => {
      await expect(service.updateMeeting({ id: '' })).rejects.toThrow(ValidationError);
    });

    it('throws ValidationError when attendeeIds is an empty array', async () => {
      await expect(
        service.updateMeeting({ id: 'meeting-1', attendeeIds: [] })
      ).rejects.toThrow(ValidationError);
    });

    it('throws ValidationError when notes exceeds 2000 chars', async () => {
      await expect(
        service.updateMeeting({ id: 'meeting-1', notes: 'x'.repeat(2001) })
      ).rejects.toThrow(ValidationError);
    });

    it('throws NotFoundError when meeting does not exist', async () => {
      vi.mocked(prisma.attendantMeeting.findUnique).mockResolvedValue(null);

      await expect(
        service.updateMeeting({ id: 'nonexistent', notes: 'Updated' })
      ).rejects.toThrow(NotFoundError);
    });

    it('updates notes only (no transaction needed)', async () => {
      const existing = makeMeeting();
      vi.mocked(prisma.attendantMeeting.findUnique).mockResolvedValue(existing as never);
      vi.mocked(prisma.attendantMeeting.update).mockResolvedValue(
        makeMeeting({ notes: 'Updated notes' }) as never
      );

      const result = await service.updateMeeting({ id: 'meeting-1', notes: 'Updated notes' });

      expect(prisma.attendantMeeting.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'meeting-1' },
          data: { notes: 'Updated notes' },
        })
      );
      expect(prisma.$transaction).not.toHaveBeenCalled();
      expect(result).toBeDefined();
    });

    it('updates meetingDate only', async () => {
      const existing = makeMeeting();
      vi.mocked(prisma.attendantMeeting.findUnique).mockResolvedValue(existing as never);
      vi.mocked(prisma.attendantMeeting.update).mockResolvedValue(
        makeMeeting({ meetingDate: new Date('2026-03-21T08:00:00Z') }) as never
      );

      await service.updateMeeting({ id: 'meeting-1', meetingDate: '2026-03-21T08:00:00Z' });

      expect(prisma.attendantMeeting.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: { meetingDate: new Date('2026-03-21T08:00:00Z') },
        })
      );
    });

    it('clears notes when null is passed', async () => {
      const existing = makeMeeting();
      vi.mocked(prisma.attendantMeeting.findUnique).mockResolvedValue(existing as never);
      vi.mocked(prisma.attendantMeeting.update).mockResolvedValue(
        makeMeeting({ notes: null }) as never
      );

      await service.updateMeeting({ id: 'meeting-1', notes: null });

      expect(prisma.attendantMeeting.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: { notes: null },
        })
      );
    });

    it('replaces attendees atomically via transaction', async () => {
      const existing = makeMeeting();
      vi.mocked(prisma.attendantMeeting.findUnique).mockResolvedValue(existing as never);

      // $transaction passes mock itself as tx
      vi.mocked(prisma.meetingAttendance.deleteMany).mockResolvedValue({ count: 1 } as never);
      vi.mocked(prisma.attendantMeeting.update).mockResolvedValue(
        makeMeeting({
          attendees: [
            { id: 'ma-2', eventVolunteerId: 'ev-2' },
            { id: 'ma-3', eventVolunteerId: 'ev-3' },
          ],
        }) as never
      );

      await service.updateMeeting({
        id: 'meeting-1',
        attendeeIds: ['ev-2', 'ev-3'],
      });

      expect(prisma.$transaction).toHaveBeenCalled();
      expect(prisma.meetingAttendance.deleteMany).toHaveBeenCalledWith({
        where: { meetingId: 'meeting-1' },
      });
      expect(prisma.attendantMeeting.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            attendees: {
              create: [
                { eventVolunteerId: 'ev-2' },
                { eventVolunteerId: 'ev-3' },
              ],
            },
          }),
        })
      );
    });

    it('updates name only', async () => {
      const existing = makeMeeting();
      vi.mocked(prisma.attendantMeeting.findUnique).mockResolvedValue(existing as never);
      vi.mocked(prisma.attendantMeeting.update).mockResolvedValue(
        makeMeeting({ name: 'Parking Lot Briefing' }) as never
      );

      await service.updateMeeting({ id: 'meeting-1', name: 'Parking Lot Briefing' });

      expect(prisma.attendantMeeting.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: { name: 'Parking Lot Briefing' },
        })
      );
      expect(prisma.$transaction).not.toHaveBeenCalled();
    });

    it('clears name when null is passed', async () => {
      const existing = makeMeeting({ name: 'Old Name' });
      vi.mocked(prisma.attendantMeeting.findUnique).mockResolvedValue(existing as never);
      vi.mocked(prisma.attendantMeeting.update).mockResolvedValue(
        makeMeeting({ name: null }) as never
      );

      await service.updateMeeting({ id: 'meeting-1', name: null });

      expect(prisma.attendantMeeting.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: { name: null },
        })
      );
    });

    it('throws ValidationError when name exceeds 100 chars', async () => {
      await expect(
        service.updateMeeting({ id: 'meeting-1', name: 'x'.repeat(101) })
      ).rejects.toThrow(ValidationError);
    });

    it('updates date, notes, and attendees together', async () => {
      const existing = makeMeeting();
      vi.mocked(prisma.attendantMeeting.findUnique).mockResolvedValue(existing as never);
      vi.mocked(prisma.meetingAttendance.deleteMany).mockResolvedValue({ count: 1 } as never);
      vi.mocked(prisma.attendantMeeting.update).mockResolvedValue(makeMeeting() as never);

      await service.updateMeeting({
        id: 'meeting-1',
        meetingDate: '2026-03-21T08:00:00Z',
        notes: 'New notes',
        attendeeIds: ['ev-1'],
      });

      expect(prisma.$transaction).toHaveBeenCalled();
      expect(prisma.attendantMeeting.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            meetingDate: new Date('2026-03-21T08:00:00Z'),
            notes: 'New notes',
            attendees: { create: [{ eventVolunteerId: 'ev-1' }] },
          }),
        })
      );
    });
  });

  describe('createMeeting', () => {
    it('creates a meeting with name', async () => {
      vi.mocked(prisma.attendantMeeting.create).mockResolvedValue(
        makeMeeting({ name: 'Safety Walkthrough' }) as never
      );

      const result = await service.createMeeting('user-1', {
        eventId: 'event-1',
        sessionId: 'session-1',
        name: 'Safety Walkthrough',
        meetingDate: '2026-03-20T07:00:00Z',
        attendeeIds: ['ev-1'],
      });

      expect(prisma.attendantMeeting.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            name: 'Safety Walkthrough',
            eventId: 'event-1',
            sessionId: 'session-1',
          }),
        })
      );
      expect(result).toBeDefined();
    });

    it('creates a meeting without name', async () => {
      vi.mocked(prisma.attendantMeeting.create).mockResolvedValue(makeMeeting() as never);

      await service.createMeeting('user-1', {
        eventId: 'event-1',
        sessionId: 'session-1',
        meetingDate: '2026-03-20T07:00:00Z',
        attendeeIds: ['ev-1'],
      });

      expect(prisma.attendantMeeting.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            name: undefined,
            eventId: 'event-1',
          }),
        })
      );
    });
  });

  describe('getMeetingEventId', () => {
    it('returns the event ID for an existing meeting', async () => {
      vi.mocked(prisma.attendantMeeting.findUnique).mockResolvedValue({
        eventId: 'event-1',
      } as never);

      const eventId = await service.getMeetingEventId('meeting-1');
      expect(eventId).toBe('event-1');
    });

    it('throws NotFoundError when meeting does not exist', async () => {
      vi.mocked(prisma.attendantMeeting.findUnique).mockResolvedValue(null);

      await expect(service.getMeetingEventId('nonexistent')).rejects.toThrow(NotFoundError);
    });
  });

  describe('deleteMeeting', () => {
    it('deletes an existing meeting', async () => {
      vi.mocked(prisma.attendantMeeting.findUnique).mockResolvedValue(makeMeeting() as never);
      vi.mocked(prisma.attendantMeeting.delete).mockResolvedValue(makeMeeting() as never);

      const result = await service.deleteMeeting('meeting-1');
      expect(result).toBe(true);
      expect(prisma.attendantMeeting.delete).toHaveBeenCalledWith({
        where: { id: 'meeting-1' },
      });
    });

    it('throws NotFoundError when meeting does not exist', async () => {
      vi.mocked(prisma.attendantMeeting.findUnique).mockResolvedValue(null);

      await expect(service.deleteMeeting('nonexistent')).rejects.toThrow(NotFoundError);
    });
  });
});
