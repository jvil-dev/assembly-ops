/**
 * AssignmentService Unit Tests
 *
 * Tests the core scheduling business logic: createAssignment, acceptAssignment,
 * declineAssignment, forceAssignment, setCaptain, setCanCount, captainCheckIn,
 * and getDepartmentCoverage. Prisma is mocked via createPrismaMock() so no
 * database is required.
 */
import { vi, describe, it, expect, beforeEach } from 'vitest';
import { createPrismaMock } from '../unitTestHelpers.js';
import { AssignmentService } from '../../services/assignmentService.js';
import {
  NotFoundError,
  ValidationError,
  ConflictError,
  AuthorizationError,
} from '../../utils/errors.js';

// ---------------------------------------------------------------------------
// Shared mock data
// ---------------------------------------------------------------------------

const mockVolunteer = {
  id: 'vol-1',
  event: { id: 'event-1' },
  user: { firstName: 'John', lastName: 'Doe' },
};

const mockPost = {
  id: 'post-1',
  department: { eventId: 'event-1', departmentType: 'ATTENDANT' },
};

const mockSession = {
  id: 'session-1',
  eventId: 'event-1',
};

const mockShift = {
  id: 'shift-1',
  sessionId: 'session-1',
  startTime: new Date('2026-03-01T08:00:00Z'),
  endTime: new Date('2026-03-01T12:00:00Z'),
};

function makeAssignment(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 'assign-1',
    eventVolunteerId: 'vol-1',
    postId: 'post-1',
    sessionId: 'session-1',
    shiftId: null,
    status: 'PENDING',
    forceAssigned: false,
    isCaptain: false,
    respondedAt: null,
    declineReason: null,
    acceptedDeadline: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    post: {
      ...mockPost,
      department: { departmentType: 'ATTENDANT' },
    },
    session: mockSession,
    checkIn: null,
    shift: null,
    ...overrides,
  };
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe('AssignmentService', () => {
  let prisma: ReturnType<typeof createPrismaMock>;
  let service: AssignmentService;

  beforeEach(() => {
    vi.clearAllMocks();
    prisma = createPrismaMock();
    service = new AssignmentService(prisma);
  });

  // =========================================================================
  // createAssignment
  // =========================================================================

  describe('createAssignment', () => {
    it('throws ValidationError when volunteerId is missing', async () => {
      await expect(
        service.createAssignment({ volunteerId: '', postId: 'post-1', sessionId: 'session-1', shiftId: null, canCount: false })
      ).rejects.toThrow(ValidationError);
    });

    it('throws NotFoundError when volunteer does not exist', async () => {
      vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue(null);
      vi.mocked(prisma.post.findUnique).mockResolvedValue(mockPost as never);
      vi.mocked(prisma.session.findUnique).mockResolvedValue(mockSession as never);

      await expect(
        service.createAssignment({ volunteerId: 'vol-1', postId: 'post-1', sessionId: 'session-1', shiftId: null, canCount: false })
      ).rejects.toThrow(NotFoundError);

      await expect(
        service.createAssignment({ volunteerId: 'vol-1', postId: 'post-1', sessionId: 'session-1', shiftId: null, canCount: false })
      ).rejects.toThrow('Volunteer not found');
    });

    it('throws NotFoundError when post does not exist', async () => {
      vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue(mockVolunteer as never);
      vi.mocked(prisma.post.findUnique).mockResolvedValue(null);
      vi.mocked(prisma.session.findUnique).mockResolvedValue(mockSession as never);

      await expect(
        service.createAssignment({ volunteerId: 'vol-1', postId: 'post-1', sessionId: 'session-1', shiftId: null, canCount: false })
      ).rejects.toThrow(NotFoundError);

      await expect(
        service.createAssignment({ volunteerId: 'vol-1', postId: 'post-1', sessionId: 'session-1', shiftId: null, canCount: false })
      ).rejects.toThrow('Post not found');
    });

    it('throws NotFoundError when session does not exist', async () => {
      vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue(mockVolunteer as never);
      vi.mocked(prisma.post.findUnique).mockResolvedValue(mockPost as never);
      vi.mocked(prisma.session.findUnique).mockResolvedValue(null);

      await expect(
        service.createAssignment({ volunteerId: 'vol-1', postId: 'post-1', sessionId: 'session-1', shiftId: null, canCount: false })
      ).rejects.toThrow(NotFoundError);

      await expect(
        service.createAssignment({ volunteerId: 'vol-1', postId: 'post-1', sessionId: 'session-1', shiftId: null, canCount: false })
      ).rejects.toThrow('Session not found');
    });

    it('throws ValidationError when post belongs to a different event', async () => {
      const crossEventPost = {
        id: 'post-2',
        department: { eventId: 'event-999' }, // different event
      };
      vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue(mockVolunteer as never);
      vi.mocked(prisma.post.findUnique).mockResolvedValue(crossEventPost as never);
      vi.mocked(prisma.session.findUnique).mockResolvedValue(mockSession as never);

      await expect(
        service.createAssignment({ volunteerId: 'vol-1', postId: 'post-2', sessionId: 'session-1', shiftId: null, canCount: false })
      ).rejects.toThrow(ValidationError);
    });

    it('throws ValidationError when session belongs to a different event', async () => {
      const crossEventSession = { id: 'session-2', eventId: 'event-999' };
      vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue(mockVolunteer as never);
      vi.mocked(prisma.post.findUnique).mockResolvedValue(mockPost as never);
      vi.mocked(prisma.session.findUnique).mockResolvedValue(crossEventSession as never);

      await expect(
        service.createAssignment({ volunteerId: 'vol-1', postId: 'post-1', sessionId: 'session-2', shiftId: null, canCount: false })
      ).rejects.toThrow(ValidationError);
    });

    it('throws NotFoundError when shiftId is provided but shift does not exist', async () => {
      vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue(mockVolunteer as never);
      vi.mocked(prisma.post.findUnique).mockResolvedValue(mockPost as never);
      vi.mocked(prisma.session.findUnique).mockResolvedValue(mockSession as never);
      vi.mocked(prisma.shift.findUnique).mockResolvedValue(null);

      await expect(
        service.createAssignment({ volunteerId: 'vol-1', postId: 'post-1', sessionId: 'session-1', shiftId: 'shift-bad', canCount: false })
      ).rejects.toThrow(NotFoundError);

      await expect(
        service.createAssignment({ volunteerId: 'vol-1', postId: 'post-1', sessionId: 'session-1', shiftId: 'shift-bad', canCount: false })
      ).rejects.toThrow('Shift not found');
    });

    it('throws ValidationError when shift does not belong to the specified session', async () => {
      const wrongSessionShift = { ...mockShift, sessionId: 'session-other' };
      vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue(mockVolunteer as never);
      vi.mocked(prisma.post.findUnique).mockResolvedValue(mockPost as never);
      vi.mocked(prisma.session.findUnique).mockResolvedValue(mockSession as never);
      vi.mocked(prisma.shift.findUnique).mockResolvedValue(wrongSessionShift as never);

      await expect(
        service.createAssignment({ volunteerId: 'vol-1', postId: 'post-1', sessionId: 'session-1', shiftId: 'shift-1', canCount: false })
      ).rejects.toThrow(ValidationError);

      await expect(
        service.createAssignment({ volunteerId: 'vol-1', postId: 'post-1', sessionId: 'session-1', shiftId: 'shift-1', canCount: false })
      ).rejects.toThrow('Shift does not belong to the specified session');
    });

    it('throws ConflictError when an overlapping shift assignment exists for the volunteer', async () => {
      // New shift: 10:00 – 14:00; existing shift: 08:00 – 12:00 → overlap
      const newShift = {
        id: 'shift-new',
        sessionId: 'session-1',
        startTime: new Date('2026-03-01T10:00:00Z'),
        endTime: new Date('2026-03-01T14:00:00Z'),
      };
      const existingShiftAssignment = {
        id: 'assign-existing',
        shiftId: 'shift-existing',
        shift: {
          id: 'shift-existing',
          startTime: new Date('2026-03-01T08:00:00Z'),
          endTime: new Date('2026-03-01T12:00:00Z'),
        },
      };

      vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue(mockVolunteer as never);
      vi.mocked(prisma.post.findUnique).mockResolvedValue(mockPost as never);
      vi.mocked(prisma.session.findUnique).mockResolvedValue(mockSession as never);
      vi.mocked(prisma.shift.findUnique).mockResolvedValue(newShift as never);
      vi.mocked(prisma.scheduleAssignment.findMany).mockResolvedValue([existingShiftAssignment] as never);

      await expect(
        service.createAssignment({ volunteerId: 'vol-1', postId: 'post-1', sessionId: 'session-1', shiftId: 'shift-new', canCount: false })
      ).rejects.toThrow(ConflictError);
    });

    it('creates assignment when shift provided with no overlap', async () => {
      // New shift: 13:00 – 17:00; existing shift: 08:00 – 12:00 → no overlap
      const newShift = {
        id: 'shift-new',
        sessionId: 'session-1',
        startTime: new Date('2026-03-01T13:00:00Z'),
        endTime: new Date('2026-03-01T17:00:00Z'),
      };
      const existingShiftAssignment = {
        id: 'assign-existing',
        shiftId: 'shift-existing',
        shift: {
          id: 'shift-existing',
          startTime: new Date('2026-03-01T08:00:00Z'),
          endTime: new Date('2026-03-01T12:00:00Z'),
        },
      };
      const createdAssignment = makeAssignment({ shiftId: 'shift-new' });

      vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue(mockVolunteer as never);
      vi.mocked(prisma.post.findUnique).mockResolvedValue(mockPost as never);
      vi.mocked(prisma.session.findUnique).mockResolvedValue(mockSession as never);
      vi.mocked(prisma.shift.findUnique).mockResolvedValue(newShift as never);
      vi.mocked(prisma.scheduleAssignment.findMany).mockResolvedValue([existingShiftAssignment] as never);
      vi.mocked(prisma.scheduleAssignment.create).mockResolvedValue(createdAssignment as never);

      const result = await service.createAssignment({
        volunteerId: 'vol-1',
        postId: 'post-1',
        sessionId: 'session-1',
        shiftId: 'shift-new',
        canCount: false,
      });

      expect(result).toEqual(createdAssignment);
      expect(prisma.scheduleAssignment.create).toHaveBeenCalledOnce();
    });

    it('throws ConflictError when volunteer already has a null-shift assignment for the same session', async () => {
      const existingNullShiftAssignment = makeAssignment({ shiftId: null });

      vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue(mockVolunteer as never);
      vi.mocked(prisma.post.findUnique).mockResolvedValue(mockPost as never);
      vi.mocked(prisma.session.findUnique).mockResolvedValue(mockSession as never);
      vi.mocked(prisma.scheduleAssignment.findFirst).mockResolvedValue(existingNullShiftAssignment as never);

      await expect(
        service.createAssignment({ volunteerId: 'vol-1', postId: 'post-1', sessionId: 'session-1', shiftId: null, canCount: false })
      ).rejects.toThrow(ConflictError);

      await expect(
        service.createAssignment({ volunteerId: 'vol-1', postId: 'post-1', sessionId: 'session-1', shiftId: null, canCount: false })
      ).rejects.toThrow('already assigned');
    });

    it('creates assignment when no null-shift conflict exists (legacy path)', async () => {
      const createdAssignment = makeAssignment();

      vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue(mockVolunteer as never);
      vi.mocked(prisma.post.findUnique).mockResolvedValue(mockPost as never);
      vi.mocked(prisma.session.findUnique).mockResolvedValue(mockSession as never);
      vi.mocked(prisma.scheduleAssignment.findFirst).mockResolvedValue(null);
      vi.mocked(prisma.scheduleAssignment.create).mockResolvedValue(createdAssignment as never);

      const result = await service.createAssignment({
        volunteerId: 'vol-1',
        postId: 'post-1',
        sessionId: 'session-1',
        shiftId: null,
        canCount: false,
      });

      expect(result).toEqual(createdAssignment);
      expect(prisma.scheduleAssignment.create).toHaveBeenCalledOnce();
    });
  });

  // =========================================================================
  // acceptAssignment
  // =========================================================================

  describe('acceptAssignment', () => {
    it('throws NotFoundError when assignment does not exist', async () => {
      vi.mocked(prisma.scheduleAssignment.findUnique).mockResolvedValue(null);

      await expect(
        service.acceptAssignment('vol-1', { assignmentId: 'assign-missing' })
      ).rejects.toThrow(NotFoundError);

      await expect(
        service.acceptAssignment('vol-1', { assignmentId: 'assign-missing' })
      ).rejects.toThrow('Assignment not found');
    });

    it('throws AuthorizationError when the assignment belongs to a different volunteer', async () => {
      const otherVolunteersAssignment = makeAssignment({ eventVolunteerId: 'vol-other' });
      vi.mocked(prisma.scheduleAssignment.findUnique).mockResolvedValue(otherVolunteersAssignment as never);

      await expect(
        service.acceptAssignment('vol-1', { assignmentId: 'assign-1' })
      ).rejects.toThrow(AuthorizationError);
    });

    it('throws ValidationError when assignment status is not PENDING', async () => {
      const acceptedAssignment = makeAssignment({ status: 'ACCEPTED' });
      vi.mocked(prisma.scheduleAssignment.findUnique).mockResolvedValue(acceptedAssignment as never);

      await expect(
        service.acceptAssignment('vol-1', { assignmentId: 'assign-1' })
      ).rejects.toThrow(ValidationError);
    });

    it('happy path: updates status to ACCEPTED and sets respondedAt', async () => {
      const pendingAssignment = makeAssignment({ status: 'PENDING' });
      const acceptedAssignment = makeAssignment({ status: 'ACCEPTED', respondedAt: new Date() });

      vi.mocked(prisma.scheduleAssignment.findUnique).mockResolvedValue(pendingAssignment as never);
      vi.mocked(prisma.scheduleAssignment.update).mockResolvedValue(acceptedAssignment as never);

      const result = await service.acceptAssignment('vol-1', { assignmentId: 'assign-1' });

      expect(result.status).toBe('ACCEPTED');
      expect(prisma.scheduleAssignment.update).toHaveBeenCalledOnce();

      const updateArgs = vi.mocked(prisma.scheduleAssignment.update).mock.calls[0][0] as {
        data: { status: string; respondedAt: Date };
      };
      expect(updateArgs.data.status).toBe('ACCEPTED');
      expect(updateArgs.data.respondedAt).toBeInstanceOf(Date);
    });
  });

  // =========================================================================
  // declineAssignment
  // =========================================================================

  describe('declineAssignment', () => {
    it('throws AuthorizationError when assignment belongs to a different volunteer', async () => {
      const otherVolunteersAssignment = makeAssignment({ eventVolunteerId: 'vol-other' });
      vi.mocked(prisma.scheduleAssignment.findUnique).mockResolvedValue(otherVolunteersAssignment as never);

      await expect(
        service.declineAssignment('vol-1', { assignmentId: 'assign-1', reason: null })
      ).rejects.toThrow(AuthorizationError);
    });

    it('throws ValidationError when assignment status is not PENDING', async () => {
      const declinedAssignment = makeAssignment({ status: 'DECLINED' });
      vi.mocked(prisma.scheduleAssignment.findUnique).mockResolvedValue(declinedAssignment as never);

      await expect(
        service.declineAssignment('vol-1', { assignmentId: 'assign-1', reason: null })
      ).rejects.toThrow(ValidationError);
    });

    it('throws ValidationError when assignment is force-assigned', async () => {
      const forceAssigned = makeAssignment({ status: 'PENDING', forceAssigned: true });
      vi.mocked(prisma.scheduleAssignment.findUnique).mockResolvedValue(forceAssigned as never);

      await expect(
        service.declineAssignment('vol-1', { assignmentId: 'assign-1', reason: null })
      ).rejects.toThrow(ValidationError);

      await expect(
        service.declineAssignment('vol-1', { assignmentId: 'assign-1', reason: null })
      ).rejects.toThrow('Cannot decline a force-assigned assignment');
    });

    it('happy path: updates status to DECLINED and sets respondedAt', async () => {
      const pendingAssignment = makeAssignment({ status: 'PENDING', forceAssigned: false });
      const declinedAssignment = makeAssignment({
        status: 'DECLINED',
        respondedAt: new Date(),
        declineReason: 'Conflict',
      });

      vi.mocked(prisma.scheduleAssignment.findUnique).mockResolvedValue(pendingAssignment as never);
      vi.mocked(prisma.scheduleAssignment.update).mockResolvedValue(declinedAssignment as never);

      const result = await service.declineAssignment('vol-1', {
        assignmentId: 'assign-1',
        reason: 'Conflict',
      });

      expect(result.status).toBe('DECLINED');
      expect(prisma.scheduleAssignment.update).toHaveBeenCalledOnce();

      const updateArgs = vi.mocked(prisma.scheduleAssignment.update).mock.calls[0][0] as {
        data: { status: string; respondedAt: Date; declineReason: string | null };
      };
      expect(updateArgs.data.status).toBe('DECLINED');
      expect(updateArgs.data.respondedAt).toBeInstanceOf(Date);
    });
  });

  // =========================================================================
  // forceAssignment
  // =========================================================================

  describe('forceAssignment', () => {
    it('throws NotFoundError when volunteer does not exist', async () => {
      vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue(null);

      await expect(
        service.forceAssignment({ volunteerId: 'vol-missing', postId: 'post-1', sessionId: 'session-1', shiftId: null, isCaptain: false, canCount: false })
      ).rejects.toThrow(NotFoundError);

      await expect(
        service.forceAssignment({ volunteerId: 'vol-missing', postId: 'post-1', sessionId: 'session-1', shiftId: null, isCaptain: false, canCount: false })
      ).rejects.toThrow('Volunteer not found');
    });

    it('throws NotFoundError when post does not exist', async () => {
      vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue(mockVolunteer as never);
      vi.mocked(prisma.post.findUnique).mockResolvedValue(null);

      await expect(
        service.forceAssignment({ volunteerId: 'vol-1', postId: 'post-missing', sessionId: 'session-1', shiftId: null, isCaptain: false, canCount: false })
      ).rejects.toThrow(NotFoundError);

      await expect(
        service.forceAssignment({ volunteerId: 'vol-1', postId: 'post-missing', sessionId: 'session-1', shiftId: null, isCaptain: false, canCount: false })
      ).rejects.toThrow('Post not found');
    });

    it('throws NotFoundError when session does not exist', async () => {
      vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue(mockVolunteer as never);
      vi.mocked(prisma.post.findUnique).mockResolvedValue(mockPost as never);
      vi.mocked(prisma.session.findUnique).mockResolvedValue(null);

      await expect(
        service.forceAssignment({ volunteerId: 'vol-1', postId: 'post-1', sessionId: 'session-missing', shiftId: null, isCaptain: false, canCount: false })
      ).rejects.toThrow(NotFoundError);

      await expect(
        service.forceAssignment({ volunteerId: 'vol-1', postId: 'post-1', sessionId: 'session-missing', shiftId: null, isCaptain: false, canCount: false })
      ).rejects.toThrow('Session not found');
    });

    it('throws ValidationError when isCaptain=true but department is not ATTENDANT', async () => {
      const nonAttendantPost = {
        id: 'post-audio',
        department: { eventId: 'event-1', departmentType: 'AUDIO' },
      };
      vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue(mockVolunteer as never);
      vi.mocked(prisma.post.findUnique).mockResolvedValue(nonAttendantPost as never);

      await expect(
        service.forceAssignment({
          volunteerId: 'vol-1',
          postId: 'post-audio',
          sessionId: 'session-1',
          shiftId: null,
          isCaptain: true,
          canCount: false,
        })
      ).rejects.toThrow(ValidationError);

      await expect(
        service.forceAssignment({
          volunteerId: 'vol-1',
          postId: 'post-audio',
          sessionId: 'session-1',
          shiftId: null,
          isCaptain: true,
          canCount: false,
        })
      ).rejects.toThrow('Captain designation is only available for the Attendant department');
    });

    it('updates existing assignment to ACCEPTED with forceAssigned=true when one already exists', async () => {
      const existingAssignment = makeAssignment({ status: 'PENDING' });
      const updatedAssignment = makeAssignment({ status: 'ACCEPTED', forceAssigned: true });

      vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue(mockVolunteer as never);
      vi.mocked(prisma.post.findUnique).mockResolvedValue(mockPost as never);
      vi.mocked(prisma.session.findUnique).mockResolvedValue(mockSession as never);
      vi.mocked(prisma.scheduleAssignment.findFirst).mockResolvedValue(existingAssignment as never);
      vi.mocked(prisma.scheduleAssignment.update).mockResolvedValue(updatedAssignment as never);

      const result = await service.forceAssignment({
        volunteerId: 'vol-1',
        postId: 'post-1',
        sessionId: 'session-1',
        shiftId: null,
        isCaptain: false,
        canCount: false,
      });

      expect(result.status).toBe('ACCEPTED');
      expect(result.forceAssigned).toBe(true);
      expect(prisma.scheduleAssignment.update).toHaveBeenCalledOnce();
      expect(prisma.scheduleAssignment.create).not.toHaveBeenCalled();

      const updateArgs = vi.mocked(prisma.scheduleAssignment.update).mock.calls[0][0] as {
        data: { status: string; forceAssigned: boolean };
      };
      expect(updateArgs.data.status).toBe('ACCEPTED');
      expect(updateArgs.data.forceAssigned).toBe(true);
    });

    it('creates new assignment with ACCEPTED + forceAssigned=true when none exists', async () => {
      const newAssignment = makeAssignment({ status: 'ACCEPTED', forceAssigned: true });

      vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue(mockVolunteer as never);
      vi.mocked(prisma.post.findUnique).mockResolvedValue(mockPost as never);
      vi.mocked(prisma.session.findUnique).mockResolvedValue(mockSession as never);
      vi.mocked(prisma.scheduleAssignment.findFirst).mockResolvedValue(null);
      vi.mocked(prisma.scheduleAssignment.create).mockResolvedValue(newAssignment as never);

      const result = await service.forceAssignment({
        volunteerId: 'vol-1',
        postId: 'post-1',
        sessionId: 'session-1',
        shiftId: null,
        isCaptain: false,
        canCount: false,
      });

      expect(result.status).toBe('ACCEPTED');
      expect(result.forceAssigned).toBe(true);
      expect(prisma.scheduleAssignment.create).toHaveBeenCalledOnce();
      expect(prisma.scheduleAssignment.update).not.toHaveBeenCalled();

      const createArgs = vi.mocked(prisma.scheduleAssignment.create).mock.calls[0][0] as {
        data: { status: string; forceAssigned: boolean };
      };
      expect(createArgs.data.status).toBe('ACCEPTED');
      expect(createArgs.data.forceAssigned).toBe(true);
    });

    it('threads canCount=true through forceAssignment when creating new assignment', async () => {
      const newAssignment = makeAssignment({ status: 'ACCEPTED', forceAssigned: true, canCount: true });

      vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue(mockVolunteer as never);
      vi.mocked(prisma.post.findUnique).mockResolvedValue(mockPost as never);
      vi.mocked(prisma.session.findUnique).mockResolvedValue(mockSession as never);
      vi.mocked(prisma.scheduleAssignment.findFirst).mockResolvedValue(null);
      vi.mocked(prisma.scheduleAssignment.create).mockResolvedValue(newAssignment as never);

      const result = await service.forceAssignment({
        volunteerId: 'vol-1',
        postId: 'post-1',
        sessionId: 'session-1',
        shiftId: null,
        isCaptain: false,
        canCount: true,
      });

      expect(result.canCount).toBe(true);

      const createArgs = vi.mocked(prisma.scheduleAssignment.create).mock.calls[0][0] as {
        data: { canCount: boolean };
      };
      expect(createArgs.data.canCount).toBe(true);
    });

    it('threads canCount=true through forceAssignment when updating existing assignment', async () => {
      const existingAssignment = makeAssignment({ status: 'PENDING', canCount: false });
      const updatedAssignment = makeAssignment({ status: 'ACCEPTED', forceAssigned: true, canCount: true });

      vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue(mockVolunteer as never);
      vi.mocked(prisma.post.findUnique).mockResolvedValue(mockPost as never);
      vi.mocked(prisma.session.findUnique).mockResolvedValue(mockSession as never);
      vi.mocked(prisma.scheduleAssignment.findFirst).mockResolvedValue(existingAssignment as never);
      vi.mocked(prisma.scheduleAssignment.update).mockResolvedValue(updatedAssignment as never);

      const result = await service.forceAssignment({
        volunteerId: 'vol-1',
        postId: 'post-1',
        sessionId: 'session-1',
        shiftId: null,
        isCaptain: false,
        canCount: true,
      });

      expect(result.canCount).toBe(true);

      const updateArgs = vi.mocked(prisma.scheduleAssignment.update).mock.calls[0][0] as {
        data: { canCount: boolean };
      };
      expect(updateArgs.data.canCount).toBe(true);
    });
  });

  // =========================================================================
  // setCaptain
  // =========================================================================

  describe('setCaptain', () => {
    it('throws NotFoundError when assignment does not exist', async () => {
      vi.mocked(prisma.scheduleAssignment.findUnique).mockResolvedValue(null);

      await expect(
        service.setCaptain({ assignmentId: 'assign-missing', isCaptain: true })
      ).rejects.toThrow(NotFoundError);

      await expect(
        service.setCaptain({ assignmentId: 'assign-missing', isCaptain: true })
      ).rejects.toThrow('Assignment not found');
    });

    it('throws ValidationError when isCaptain=true but department is not ATTENDANT', async () => {
      const nonAttendantAssignment = makeAssignment({
        post: {
          ...mockPost,
          department: { departmentType: 'VIDEO' },
        },
      });
      vi.mocked(prisma.scheduleAssignment.findUnique).mockResolvedValue(nonAttendantAssignment as never);

      await expect(
        service.setCaptain({ assignmentId: 'assign-1', isCaptain: true })
      ).rejects.toThrow(ValidationError);

      await expect(
        service.setCaptain({ assignmentId: 'assign-1', isCaptain: true })
      ).rejects.toThrow('Captain designation is only available for the Attendant department');
    });

    it('happy path: updates isCaptain on assignment in ATTENDANT department', async () => {
      const attendantAssignment = makeAssignment({
        post: {
          ...mockPost,
          department: { departmentType: 'ATTENDANT' },
        },
      });
      const updatedAssignment = makeAssignment({ isCaptain: true });

      vi.mocked(prisma.scheduleAssignment.findUnique).mockResolvedValue(attendantAssignment as never);
      vi.mocked(prisma.scheduleAssignment.update).mockResolvedValue(updatedAssignment as never);

      const result = await service.setCaptain({ assignmentId: 'assign-1', isCaptain: true });

      expect(result.isCaptain).toBe(true);
      expect(prisma.scheduleAssignment.update).toHaveBeenCalledOnce();

      const updateArgs = vi.mocked(prisma.scheduleAssignment.update).mock.calls[0][0] as {
        data: { isCaptain: boolean };
      };
      expect(updateArgs.data.isCaptain).toBe(true);
    });
  });

  // =========================================================================
  // setCanCount
  // =========================================================================

  describe('setCanCount', () => {
    it('throws NotFoundError when assignment does not exist', async () => {
      vi.mocked(prisma.scheduleAssignment.findUnique).mockResolvedValue(null);

      await expect(
        service.setCanCount({ assignmentId: 'assign-missing', canCount: true })
      ).rejects.toThrow(NotFoundError);

      await expect(
        service.setCanCount({ assignmentId: 'assign-missing', canCount: true })
      ).rejects.toThrow('Assignment not found');
    });

    it('throws ValidationError when assignmentId is empty', async () => {
      await expect(
        service.setCanCount({ assignmentId: '', canCount: true })
      ).rejects.toThrow(ValidationError);
    });

    it('happy path: updates canCount to true on assignment', async () => {
      const assignment = makeAssignment({ canCount: false });
      const updatedAssignment = makeAssignment({ canCount: true });

      vi.mocked(prisma.scheduleAssignment.findUnique).mockResolvedValue(assignment as never);
      vi.mocked(prisma.scheduleAssignment.update).mockResolvedValue(updatedAssignment as never);

      const result = await service.setCanCount({ assignmentId: 'assign-1', canCount: true });

      expect(result.canCount).toBe(true);
      expect(prisma.scheduleAssignment.update).toHaveBeenCalledOnce();

      const updateArgs = vi.mocked(prisma.scheduleAssignment.update).mock.calls[0][0] as {
        data: { canCount: boolean };
      };
      expect(updateArgs.data.canCount).toBe(true);
    });

    it('happy path: updates canCount to false on assignment', async () => {
      const assignment = makeAssignment({ canCount: true });
      const updatedAssignment = makeAssignment({ canCount: false });

      vi.mocked(prisma.scheduleAssignment.findUnique).mockResolvedValue(assignment as never);
      vi.mocked(prisma.scheduleAssignment.update).mockResolvedValue(updatedAssignment as never);

      const result = await service.setCanCount({ assignmentId: 'assign-1', canCount: false });

      expect(result.canCount).toBe(false);
      expect(prisma.scheduleAssignment.update).toHaveBeenCalledOnce();
    });
  });

  // =========================================================================
  // captainCheckIn
  // =========================================================================

  describe('captainCheckIn', () => {
    it('throws NotFoundError when the target assignment does not exist', async () => {
      vi.mocked(prisma.scheduleAssignment.findUnique).mockResolvedValue(null);

      await expect(
        service.captainCheckIn('captain-vol-1', { assignmentId: 'assign-missing', notes: null })
      ).rejects.toThrow(NotFoundError);

      await expect(
        service.captainCheckIn('captain-vol-1', { assignmentId: 'assign-missing', notes: null })
      ).rejects.toThrow('Assignment not found');
    });

    it('throws ValidationError when the target volunteer is already checked in', async () => {
      const alreadyCheckedIn = makeAssignment({
        checkIn: { id: 'checkin-1', checkInTime: new Date() },
      });
      vi.mocked(prisma.scheduleAssignment.findUnique).mockResolvedValue(alreadyCheckedIn as never);

      await expect(
        service.captainCheckIn('captain-vol-1', { assignmentId: 'assign-1', notes: null })
      ).rejects.toThrow(ValidationError);

      await expect(
        service.captainCheckIn('captain-vol-1', { assignmentId: 'assign-1', notes: null })
      ).rejects.toThrow('already checked in');
    });

    it('throws AuthorizationError when caller has no captain assignment for the same post/session', async () => {
      const targetAssignment = makeAssignment({ checkIn: null });
      vi.mocked(prisma.scheduleAssignment.findUnique).mockResolvedValue(targetAssignment as never);
      vi.mocked(prisma.scheduleAssignment.findFirst).mockResolvedValue(null); // no captain assignment

      await expect(
        service.captainCheckIn('non-captain-vol', { assignmentId: 'assign-1', notes: null })
      ).rejects.toThrow(AuthorizationError);

      await expect(
        service.captainCheckIn('non-captain-vol', { assignmentId: 'assign-1', notes: null })
      ).rejects.toThrow('must be a captain');
    });

    it('happy path: creates CheckIn record and returns updated assignment', async () => {
      const targetAssignment = makeAssignment({ checkIn: null });
      const captainAssignment = makeAssignment({
        id: 'captain-assign-1',
        eventVolunteerId: 'captain-vol-1',
        isCaptain: true,
      });
      const updatedAssignment = makeAssignment({
        checkIn: { id: 'checkin-new', checkInTime: new Date() },
      });

      vi.mocked(prisma.scheduleAssignment.findUnique).mockResolvedValue(targetAssignment as never);
      vi.mocked(prisma.scheduleAssignment.findFirst).mockResolvedValue(captainAssignment as never);
      vi.mocked(prisma.checkIn.create).mockResolvedValue({ id: 'checkin-new' } as never);
      vi.mocked(prisma.scheduleAssignment.findUniqueOrThrow).mockResolvedValue(updatedAssignment as never);

      const result = await service.captainCheckIn('captain-vol-1', { assignmentId: 'assign-1', notes: null });

      expect(prisma.checkIn.create).toHaveBeenCalledOnce();

      const checkInArgs = vi.mocked(prisma.checkIn.create).mock.calls[0][0] as {
        data: { assignmentId: string; status: string; notes: string };
      };
      expect(checkInArgs.data.assignmentId).toBe('assign-1');
      expect(checkInArgs.data.status).toBe('CHECKED_IN');
      expect(checkInArgs.data.notes).toContain('Checked in by captain');

      expect(prisma.scheduleAssignment.findUniqueOrThrow).toHaveBeenCalledOnce();
      expect(result).toEqual(updatedAssignment);
    });
  });

  // =========================================================================
  // getDepartmentCoverage
  // =========================================================================

  describe('getDepartmentCoverage', () => {
    it('returns empty array when department has no posts', async () => {
      vi.mocked(prisma.post.findMany).mockResolvedValue([] as never);

      const result = await service.getDepartmentCoverage('dept-1');

      expect(result).toEqual([]);
      expect(prisma.department.findUnique).not.toHaveBeenCalled();
      expect(prisma.session.findMany).not.toHaveBeenCalled();
    });

    it('returns empty array when there are no sessions for the event', async () => {
      const posts = [
        {
          id: 'post-1',
          name: 'Door A',
          category: null,
          location: null,
          sortOrder: 1,
          departmentId: 'dept-1',
          area: null,
        },
      ];
      const department = { eventId: 'event-1' };

      vi.mocked(prisma.post.findMany).mockResolvedValue(posts as never);
      vi.mocked(prisma.department.findUnique).mockResolvedValue(department as never);
      vi.mocked(prisma.session.findMany).mockResolvedValue([] as never);

      const result = await service.getDepartmentCoverage('dept-1');

      expect(result).toEqual([]);
      expect(prisma.scheduleAssignment.findMany).not.toHaveBeenCalled();
    });

    it('happy path: builds correct coverage matrix with filled count from ACCEPTED assignments only', async () => {
      const posts = [
        {
          id: 'post-1',
          name: 'Door A',
          category: null,
          location: null,
          sortOrder: 1,
          departmentId: 'dept-1',
          area: null,
        },
      ];
      const department = { eventId: 'event-1' };
      const sessions = [
        {
          id: 'session-1',
          name: 'Morning',
          date: new Date('2026-03-01'),
          startTime: new Date('2026-03-01T08:00:00Z'),
          endTime: new Date('2026-03-01T12:00:00Z'),
          eventId: 'event-1',
        },
      ];
      // One ACCEPTED + one PENDING for the same slot — filled should be 1
      const assignments = [
        {
          id: 'assign-accepted',
          postId: 'post-1',
          sessionId: 'session-1',
          status: 'ACCEPTED',
          forceAssigned: false,
          shift: null,
          eventVolunteer: {
            id: 'vol-1',
            user: { firstName: 'John', lastName: 'Doe' },
          },
          checkIn: null,
        },
        {
          id: 'assign-pending',
          postId: 'post-1',
          sessionId: 'session-1',
          status: 'PENDING',
          forceAssigned: false,
          shift: null,
          eventVolunteer: {
            id: 'vol-2',
            user: { firstName: 'Jane', lastName: 'Smith' },
          },
          checkIn: null,
        },
      ];

      vi.mocked(prisma.post.findMany).mockResolvedValue(posts as never);
      vi.mocked(prisma.department.findUnique).mockResolvedValue(department as never);
      vi.mocked(prisma.session.findMany).mockResolvedValue(sessions as never);
      vi.mocked(prisma.scheduleAssignment.findMany).mockResolvedValue(assignments as never);
      vi.mocked(prisma.shift.findMany).mockResolvedValue([] as never);

      const result = await service.getDepartmentCoverage('dept-1');

      expect(result).toHaveLength(1); // 1 post × 1 session
      const slot = result[0];
      expect(slot.post.id).toBe('post-1');
      expect(slot.session.id).toBe('session-1');
      // filled = ACCEPTED only
      expect(slot.filled).toBe(1);
      // Both ACCEPTED + PENDING assignments should appear in the list
      expect(slot.assignments).toHaveLength(2);
    });
  });
});
