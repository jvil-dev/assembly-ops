/**
 * AttendanceService Unit Tests
 *
 * Tests the canCount enforcement in submitVolunteerAttendanceCount.
 * Verifies that only designated counters (canCount=true) can submit
 * attendance counts through the volunteer pathway.
 */
import { vi, describe, it, expect, beforeEach } from 'vitest';
import { createPrismaMock } from '../unitTestHelpers.js';
import { AttendanceService } from '../../services/attendanceService.js';
import { AuthorizationError, NotFoundError, ValidationError } from '../../utils/errors.js';

describe('AttendanceService', () => {
  let prisma: ReturnType<typeof createPrismaMock>;
  let service: AttendanceService;

  const mockSession = {
    id: 'session-1',
    eventId: 'event-1',
  };

  const mockPost = {
    id: 'post-1',
    name: 'Door A',
  };

  beforeEach(() => {
    vi.clearAllMocks();
    prisma = createPrismaMock();
    service = new AttendanceService(prisma);
  });

  describe('submitVolunteerAttendanceCount — canCount enforcement', () => {
    it('rejects submission when assignment has canCount=false', async () => {
      const assignment = {
        id: 'assign-1',
        eventVolunteerId: 'vol-1',
        postId: 'post-1',
        status: 'ACCEPTED',
        canCount: false,
      };

      vi.mocked(prisma.session.findUnique).mockResolvedValue(mockSession as never);
      vi.mocked(prisma.scheduleAssignment.findFirst).mockResolvedValue(assignment as never);

      await expect(
        service.submitVolunteerAttendanceCount('vol-1', {
          sessionId: 'session-1',
          section: null,
          postId: 'post-1',
          count: 100,
          notes: null,
        })
      ).rejects.toThrow(AuthorizationError);

      await expect(
        service.submitVolunteerAttendanceCount('vol-1', {
          sessionId: 'session-1',
          section: null,
          postId: 'post-1',
          count: 100,
          notes: null,
        })
      ).rejects.toThrow('not designated as a counter');
    });

    it('rejects submission when volunteer has no accepted assignment', async () => {
      vi.mocked(prisma.session.findUnique).mockResolvedValue(mockSession as never);
      vi.mocked(prisma.scheduleAssignment.findFirst).mockResolvedValue(null);

      await expect(
        service.submitVolunteerAttendanceCount('vol-1', {
          sessionId: 'session-1',
          section: null,
          postId: 'post-1',
          count: 100,
          notes: null,
        })
      ).rejects.toThrow(AuthorizationError);

      await expect(
        service.submitVolunteerAttendanceCount('vol-1', {
          sessionId: 'session-1',
          section: null,
          postId: 'post-1',
          count: 100,
          notes: null,
        })
      ).rejects.toThrow('do not have an accepted assignment');
    });

    it('allows submission when assignment has canCount=true', async () => {
      const assignment = {
        id: 'assign-1',
        eventVolunteerId: 'vol-1',
        postId: 'post-1',
        status: 'ACCEPTED',
        canCount: true,
      };

      const attendanceCount = {
        id: 'count-1',
        sessionId: 'session-1',
        postId: 'post-1',
        count: 100,
        section: 'Door A',
        notes: null,
        submittedById: 'admin-1',
      };

      vi.mocked(prisma.session.findUnique).mockResolvedValue(mockSession as never);
      vi.mocked(prisma.scheduleAssignment.findFirst).mockResolvedValue(assignment as never);
      vi.mocked(prisma.post.findUnique).mockResolvedValue(mockPost as never);
      vi.mocked(prisma.eventAdmin.findFirst).mockResolvedValue({ userId: 'admin-1' } as never);
      vi.mocked(prisma.attendanceCount.upsert).mockResolvedValue(attendanceCount as never);

      const result = await service.submitVolunteerAttendanceCount('vol-1', {
        sessionId: 'session-1',
        section: null,
        postId: 'post-1',
        count: 100,
        notes: null,
      });

      expect(result.count).toBe(100);
      expect(prisma.attendanceCount.upsert).toHaveBeenCalledOnce();
    });

    it('rejects submission when postId is missing', async () => {
      await expect(
        service.submitVolunteerAttendanceCount('vol-1', {
          sessionId: 'session-1',
          section: null,
          count: 100,
          notes: null,
        })
      ).rejects.toThrow(ValidationError);
    });

    it('rejects submission when session does not exist', async () => {
      vi.mocked(prisma.session.findUnique).mockResolvedValue(null);

      await expect(
        service.submitVolunteerAttendanceCount('vol-1', {
          sessionId: 'session-missing',
          section: null,
          postId: 'post-1',
          count: 100,
          notes: null,
        })
      ).rejects.toThrow(NotFoundError);
    });
  });
});
