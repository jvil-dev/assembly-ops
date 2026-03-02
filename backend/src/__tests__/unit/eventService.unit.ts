/**
 * EventService Unit Tests
 *
 * Tests business logic for department purchasing, volunteer joining, privacy
 * settings, and hierarchy role management. Prisma is mocked via createPrismaMock()
 * so no real database calls are made. The time utility is module-mocked so
 * session creation does not depend on wall-clock date math.
 */
import { vi, describe, it, expect, beforeEach } from 'vitest';
import { createPrismaMock } from '../unitTestHelpers.js';
import { EventService } from '../../services/eventService.js';
import {
  NotFoundError,
  ConflictError,
  ValidationError,
  AuthorizationError,
} from '../../utils/errors.js';

// ---------------------------------------------------------------------------
// Module mock — hoisted so the import of eventService picks up the stub
// ---------------------------------------------------------------------------
vi.mock('../../utils/time.js', () => ({
  timeStringToDate: vi.fn((time: string) => new Date(`2026-01-01T${time}:00`)),
}));

// ---------------------------------------------------------------------------
// Shared mock data
// ---------------------------------------------------------------------------

const mockEvent = {
  id: 'event-1',
  startDate: new Date('2026-06-01'),
  endDate: new Date('2026-06-03'),
  circuitId: 'circuit-1',
};

const mockDepartment = {
  id: 'dept-1',
  eventId: 'event-1',
  departmentType: 'AUDIO',
  accessCode: 'AUD-7X9K',
  name: 'Audio',
  isPublic: true,
  overseer: {
    userId: 'user-1',
    user: { firstName: 'John', lastName: 'Doe' },
  },
};

const mockEventAdmin = {
  id: 'ea-1',
  userId: 'user-1',
  eventId: 'event-1',
  role: 'DEPARTMENT_OVERSEER',
  departmentId: null,
};

const mockEventVolunteer = {
  id: 'ev-1',
  userId: 'user-2',
  eventId: 'event-1',
  departmentId: 'dept-1',
};

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe('EventService', () => {
  let prisma: ReturnType<typeof createPrismaMock>;
  let service: EventService;

  beforeEach(() => {
    vi.clearAllMocks();
    prisma = createPrismaMock();
    service = new EventService(prisma);
  });

  // =========================================================================
  // purchaseDepartment
  // =========================================================================

  describe('purchaseDepartment', () => {
    it('throws ValidationError when eventId is missing', async () => {
      await expect(
        service.purchaseDepartment({ eventId: '', departmentType: 'AUDIO' as never }, 'user-1')
      ).rejects.toThrow(ValidationError);
    });

    it('throws ValidationError when departmentType is invalid', async () => {
      await expect(
        service.purchaseDepartment(
          { eventId: 'event-1', departmentType: 'INVALID_TYPE' as never },
          'user-1'
        )
      ).rejects.toThrow(ValidationError);
    });

    it('throws NotFoundError when event does not exist', async () => {
      vi.mocked(prisma.event.findUnique).mockResolvedValue(null);

      await expect(
        service.purchaseDepartment({ eventId: 'event-1', departmentType: 'AUDIO' }, 'user-1')
      ).rejects.toThrow(NotFoundError);
    });

    it('throws ConflictError with overseer name when department type is already claimed', async () => {
      vi.mocked(prisma.event.findUnique).mockResolvedValue(mockEvent as never);
      vi.mocked(prisma.department.findUnique).mockResolvedValueOnce(mockDepartment as never);

      await expect(
        service.purchaseDepartment({ eventId: 'event-1', departmentType: 'AUDIO' }, 'user-2')
      ).rejects.toThrow(new ConflictError('Audio is already claimed by John Doe'));
    });

    it('throws ConflictError when caller already has a department (eventAdmin.departmentId set)', async () => {
      vi.mocked(prisma.event.findUnique).mockResolvedValue(mockEvent as never);
      // No existing department for this type
      vi.mocked(prisma.department.findUnique).mockResolvedValueOnce(null);
      // EventAdmin already has a department
      vi.mocked(prisma.eventAdmin.findUnique).mockResolvedValue({
        ...mockEventAdmin,
        departmentId: 'dept-existing',
      } as never);

      await expect(
        service.purchaseDepartment({ eventId: 'event-1', departmentType: 'AUDIO' }, 'user-1')
      ).rejects.toThrow(ConflictError);
    });

    it('happy path (new EventAdmin): creates EventAdmin, Department with access code, and links them', async () => {
      vi.mocked(prisma.event.findUnique).mockResolvedValue(mockEvent as never);
      vi.mocked(prisma.department.findUnique)
        // First call: existing dept check → not found
        .mockResolvedValueOnce(null)
        // generateUniqueAccessCode check → not taken
        .mockResolvedValueOnce(null)
        // Final findUnique for returned department
        .mockResolvedValueOnce(mockDepartment as never);
      vi.mocked(prisma.eventAdmin.findUnique).mockResolvedValue(null);
      vi.mocked(prisma.eventAdmin.create).mockResolvedValue(mockEventAdmin as never);
      vi.mocked(prisma.department.create).mockResolvedValue(mockDepartment as never);
      vi.mocked(prisma.eventAdmin.update).mockResolvedValue({
        ...mockEventAdmin,
        departmentId: 'dept-1',
      } as never);
      vi.mocked(prisma.post.createMany).mockResolvedValue({ count: 2 });
      vi.mocked(prisma.session.count).mockResolvedValue(1); // skip session creation
      vi.mocked(prisma.session.create).mockResolvedValue({} as never);

      await service.purchaseDepartment({ eventId: 'event-1', departmentType: 'AUDIO' }, 'user-1');

      // EventAdmin created (user had none)
      expect(prisma.eventAdmin.create).toHaveBeenCalledOnce();
      const createAdminArgs = vi.mocked(prisma.eventAdmin.create).mock.calls[0][0] as {
        data: { userId: string; eventId: string; role: string };
      };
      expect(createAdminArgs.data.userId).toBe('user-1');
      expect(createAdminArgs.data.eventId).toBe('event-1');

      // Department created
      expect(prisma.department.create).toHaveBeenCalledOnce();
      const createDeptArgs = vi.mocked(prisma.department.create).mock.calls[0][0] as {
        data: { name: string; departmentType: string; eventId: string; accessCode: string };
      };
      expect(createDeptArgs.data.name).toBe('Audio');
      expect(createDeptArgs.data.departmentType).toBe('AUDIO');
      expect(createDeptArgs.data.eventId).toBe('event-1');
      // Access code must start with AUD- prefix
      expect(createDeptArgs.data.accessCode).toMatch(/^AUD-/);

      // EventAdmin linked to department
      expect(prisma.eventAdmin.update).toHaveBeenCalledOnce();
      const updateAdminArgs = vi.mocked(prisma.eventAdmin.update).mock.calls[0][0] as {
        where: { id: string };
        data: { departmentId: string };
      };
      expect(updateAdminArgs.data.departmentId).toBe('dept-1');
    });

    it('happy path (existing EventAdmin without dept): skips EventAdmin creation', async () => {
      vi.mocked(prisma.event.findUnique).mockResolvedValue(mockEvent as never);
      vi.mocked(prisma.department.findUnique)
        .mockResolvedValueOnce(null)   // existing dept check
        .mockResolvedValueOnce(null)   // access code uniqueness check
        .mockResolvedValueOnce(mockDepartment as never); // final return
      // EventAdmin exists but has no department yet
      vi.mocked(prisma.eventAdmin.findUnique).mockResolvedValue(mockEventAdmin as never);
      vi.mocked(prisma.department.create).mockResolvedValue(mockDepartment as never);
      vi.mocked(prisma.eventAdmin.update).mockResolvedValue({
        ...mockEventAdmin,
        departmentId: 'dept-1',
      } as never);
      vi.mocked(prisma.post.createMany).mockResolvedValue({ count: 2 });
      vi.mocked(prisma.session.count).mockResolvedValue(1);

      await service.purchaseDepartment({ eventId: 'event-1', departmentType: 'AUDIO' }, 'user-1');

      // EventAdmin.create must NOT be called — existing record reused
      expect(prisma.eventAdmin.create).not.toHaveBeenCalled();
      // Department is still created
      expect(prisma.department.create).toHaveBeenCalledOnce();
    });

    it('auto-seeds default posts for AUDIO department (2 posts)', async () => {
      vi.mocked(prisma.event.findUnique).mockResolvedValue(mockEvent as never);
      vi.mocked(prisma.department.findUnique)
        .mockResolvedValueOnce(null)
        .mockResolvedValueOnce(null)
        .mockResolvedValueOnce(mockDepartment as never);
      vi.mocked(prisma.eventAdmin.findUnique).mockResolvedValue(null);
      vi.mocked(prisma.eventAdmin.create).mockResolvedValue(mockEventAdmin as never);
      vi.mocked(prisma.department.create).mockResolvedValue(mockDepartment as never);
      vi.mocked(prisma.eventAdmin.update).mockResolvedValue({
        ...mockEventAdmin,
        departmentId: 'dept-1',
      } as never);
      vi.mocked(prisma.session.count).mockResolvedValue(1);
      vi.mocked(prisma.post.createMany).mockResolvedValue({ count: 2 });

      await service.purchaseDepartment({ eventId: 'event-1', departmentType: 'AUDIO' }, 'user-1');

      expect(prisma.post.createMany).toHaveBeenCalledOnce();
      const postArgs = vi.mocked(prisma.post.createMany).mock.calls[0][0] as {
        data: Array<{ name: string; departmentId: string }>;
      };
      expect(postArgs.data).toHaveLength(2);
      expect(postArgs.data[0].name).toBe('Mixer Operator');
      expect(postArgs.data[1].name).toBe('Mixer Operator Assistant');
      expect(postArgs.data[0].departmentId).toBe('dept-1');
    });

    it('does not seed posts for ACCOUNTS department (no defaults defined)', async () => {
      const accountsDept = { ...mockDepartment, id: 'dept-2', departmentType: 'ACCOUNTS', name: 'Accounts', accessCode: 'ACC-1234' };

      vi.mocked(prisma.event.findUnique).mockResolvedValue(mockEvent as never);
      vi.mocked(prisma.department.findUnique)
        .mockResolvedValueOnce(null)
        .mockResolvedValueOnce(null)
        .mockResolvedValueOnce(accountsDept as never);
      vi.mocked(prisma.eventAdmin.findUnique).mockResolvedValue(null);
      vi.mocked(prisma.eventAdmin.create).mockResolvedValue(mockEventAdmin as never);
      vi.mocked(prisma.department.create).mockResolvedValue(accountsDept as never);
      vi.mocked(prisma.eventAdmin.update).mockResolvedValue({
        ...mockEventAdmin,
        departmentId: 'dept-2',
      } as never);
      vi.mocked(prisma.session.count).mockResolvedValue(1);

      await service.purchaseDepartment(
        { eventId: 'event-1', departmentType: 'ACCOUNTS' },
        'user-1'
      );

      expect(prisma.post.createMany).not.toHaveBeenCalled();
    });

    it('auto-creates sessions when sessionCount=0 (2 sessions × dayCount days)', async () => {
      // Event spans 3 days (June 1–3 inclusive) → 3 × 2 = 6 session.create calls
      vi.mocked(prisma.event.findUnique).mockResolvedValue(mockEvent as never);
      vi.mocked(prisma.department.findUnique)
        .mockResolvedValueOnce(null)
        .mockResolvedValueOnce(null)
        .mockResolvedValueOnce(mockDepartment as never);
      vi.mocked(prisma.eventAdmin.findUnique).mockResolvedValue(null);
      vi.mocked(prisma.eventAdmin.create).mockResolvedValue(mockEventAdmin as never);
      vi.mocked(prisma.department.create).mockResolvedValue(mockDepartment as never);
      vi.mocked(prisma.eventAdmin.update).mockResolvedValue({
        ...mockEventAdmin,
        departmentId: 'dept-1',
      } as never);
      vi.mocked(prisma.post.createMany).mockResolvedValue({ count: 2 });
      // sessionCount = 0 triggers auto-creation
      vi.mocked(prisma.session.count).mockResolvedValue(0);
      vi.mocked(prisma.session.create).mockResolvedValue({} as never);
      vi.mocked(prisma.role.create).mockResolvedValue({} as never);

      await service.purchaseDepartment({ eventId: 'event-1', departmentType: 'AUDIO' }, 'user-1');

      // 3 days × 2 sessions each = 6 creates
      expect(prisma.session.create).toHaveBeenCalledTimes(6);

      // Verify Morning/Afternoon naming for day 1
      const firstCall = vi.mocked(prisma.session.create).mock.calls[0][0] as {
        data: { name: string; eventId: string };
      };
      const secondCall = vi.mocked(prisma.session.create).mock.calls[1][0] as {
        data: { name: string };
      };
      expect(firstCall.data.name).toBe('Morning');
      expect(secondCall.data.name).toBe('Afternoon');
      expect(firstCall.data.eventId).toBe('event-1');
    });

    it('skips session creation when sessions already exist (count > 0)', async () => {
      vi.mocked(prisma.event.findUnique).mockResolvedValue(mockEvent as never);
      vi.mocked(prisma.department.findUnique)
        .mockResolvedValueOnce(null)
        .mockResolvedValueOnce(null)
        .mockResolvedValueOnce(mockDepartment as never);
      vi.mocked(prisma.eventAdmin.findUnique).mockResolvedValue(null);
      vi.mocked(prisma.eventAdmin.create).mockResolvedValue(mockEventAdmin as never);
      vi.mocked(prisma.department.create).mockResolvedValue(mockDepartment as never);
      vi.mocked(prisma.eventAdmin.update).mockResolvedValue({
        ...mockEventAdmin,
        departmentId: 'dept-1',
      } as never);
      vi.mocked(prisma.post.createMany).mockResolvedValue({ count: 2 });
      // Sessions already exist
      vi.mocked(prisma.session.count).mockResolvedValue(4);

      await service.purchaseDepartment({ eventId: 'event-1', departmentType: 'AUDIO' }, 'user-1');

      expect(prisma.session.create).not.toHaveBeenCalled();
    });

    it('seeds 4 default roles when this is the first department (sessionCount=0)', async () => {
      vi.mocked(prisma.event.findUnique).mockResolvedValue(mockEvent as never);
      vi.mocked(prisma.department.findUnique)
        .mockResolvedValueOnce(null)
        .mockResolvedValueOnce(null)
        .mockResolvedValueOnce(mockDepartment as never);
      vi.mocked(prisma.eventAdmin.findUnique).mockResolvedValue(null);
      vi.mocked(prisma.eventAdmin.create).mockResolvedValue(mockEventAdmin as never);
      vi.mocked(prisma.department.create).mockResolvedValue(mockDepartment as never);
      vi.mocked(prisma.eventAdmin.update).mockResolvedValue({
        ...mockEventAdmin,
        departmentId: 'dept-1',
      } as never);
      vi.mocked(prisma.post.createMany).mockResolvedValue({ count: 2 });
      vi.mocked(prisma.session.count).mockResolvedValue(0);
      vi.mocked(prisma.session.create).mockResolvedValue({} as never);
      vi.mocked(prisma.role.create).mockResolvedValue({} as never);

      await service.purchaseDepartment({ eventId: 'event-1', departmentType: 'AUDIO' }, 'user-1');

      expect(prisma.role.create).toHaveBeenCalledTimes(4);

      const roleNames = vi.mocked(prisma.role.create).mock.calls.map(
        (call) => (call[0] as { data: { name: string } }).data.name
      );
      expect(roleNames).toContain('Volunteer');
      expect(roleNames).toContain('Captain');
      expect(roleNames).toContain('Keyman');
      expect(roleNames).toContain('Assistant Overseer');
    });
  });

  // =========================================================================
  // joinDepartmentByAccessCode
  // =========================================================================

  describe('joinDepartmentByAccessCode', () => {
    it('throws NotFoundError when no department matches the access code', async () => {
      vi.mocked(prisma.department.findFirst).mockResolvedValue(null);

      await expect(
        service.joinDepartmentByAccessCode({ accessCode: 'BAD-CODE' }, 'user-2')
      ).rejects.toThrow(NotFoundError);
    });

    it('throws ConflictError when the user is already a volunteer for the event', async () => {
      vi.mocked(prisma.department.findFirst).mockResolvedValue({
        ...mockDepartment,
        event: mockEvent,
      } as never);
      vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue(mockEventVolunteer as never);

      await expect(
        service.joinDepartmentByAccessCode({ accessCode: 'AUD-7X9K' }, 'user-2')
      ).rejects.toThrow(ConflictError);
    });

    it('happy path: creates EventVolunteer with correct userId, eventId, and departmentId', async () => {
      vi.mocked(prisma.department.findFirst).mockResolvedValue({
        ...mockDepartment,
        event: mockEvent,
      } as never);
      vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue(null);
      vi.mocked(prisma.eventVolunteer.create).mockResolvedValue({
        ...mockEventVolunteer,
        user: { id: 'user-2', firstName: 'Jane', lastName: 'Smith' },
        event: mockEvent,
      } as never);

      const result = await service.joinDepartmentByAccessCode(
        { accessCode: 'AUD-7X9K' },
        'user-2'
      );

      expect(prisma.eventVolunteer.create).toHaveBeenCalledOnce();
      const createArgs = vi.mocked(prisma.eventVolunteer.create).mock.calls[0][0] as {
        data: { userId: string; eventId: string; departmentId: string };
      };
      expect(createArgs.data.userId).toBe('user-2');
      expect(createArgs.data.eventId).toBe('event-1');
      expect(createArgs.data.departmentId).toBe('dept-1');
      expect(result).toBeDefined();
    });
  });

  // =========================================================================
  // setDepartmentPrivacy
  // =========================================================================

  describe('setDepartmentPrivacy', () => {
    it('throws NotFoundError when department does not exist', async () => {
      vi.mocked(prisma.department.findUnique).mockResolvedValue(null);

      await expect(
        service.setDepartmentPrivacy('dept-1', false, 'user-1')
      ).rejects.toThrow(NotFoundError);
    });

    it('throws AuthorizationError when caller is not the department overseer', async () => {
      vi.mocked(prisma.department.findUnique).mockResolvedValue({
        ...mockDepartment,
        overseer: { userId: 'user-1' },
      } as never);

      // caller is 'user-99', not 'user-1'
      await expect(
        service.setDepartmentPrivacy('dept-1', false, 'user-99')
      ).rejects.toThrow(AuthorizationError);
    });

    it('happy path: calls department.update with correct isPublic value', async () => {
      vi.mocked(prisma.department.findUnique).mockResolvedValue({
        ...mockDepartment,
        overseer: { userId: 'user-1' },
      } as never);
      vi.mocked(prisma.department.update).mockResolvedValue({
        ...mockDepartment,
        isPublic: false,
      } as never);

      await service.setDepartmentPrivacy('dept-1', false, 'user-1');

      expect(prisma.department.update).toHaveBeenCalledOnce();
      const updateArgs = vi.mocked(prisma.department.update).mock.calls[0][0] as {
        where: { id: string };
        data: { isPublic: boolean };
      };
      expect(updateArgs.where.id).toBe('dept-1');
      expect(updateArgs.data.isPublic).toBe(false);
    });
  });

  // =========================================================================
  // assignHierarchyRole
  // =========================================================================

  describe('assignHierarchyRole', () => {
    const validInput = {
      departmentId: 'dept-1',
      eventVolunteerId: 'ev-1',
      hierarchyRole: 'ASSISTANT_OVERSEER' as const,
    };

    it('throws NotFoundError when department does not exist', async () => {
      vi.mocked(prisma.department.findUnique).mockResolvedValue(null);

      await expect(
        service.assignHierarchyRole(validInput, 'user-1')
      ).rejects.toThrow(NotFoundError);
    });

    it('throws AuthorizationError when caller is not the department overseer', async () => {
      vi.mocked(prisma.department.findUnique).mockResolvedValue({
        ...mockDepartment,
        overseer: { userId: 'user-1' },
      } as never);

      await expect(
        service.assignHierarchyRole(validInput, 'user-99')
      ).rejects.toThrow(AuthorizationError);
    });

    it('throws ValidationError when volunteer is not a member of this department', async () => {
      vi.mocked(prisma.department.findUnique).mockResolvedValue({
        ...mockDepartment,
        overseer: { userId: 'user-1' },
        eventId: 'event-1',
      } as never);
      // Direct lookup by eventVolunteerId returns a volunteer from a different department
      vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue({
        ...mockEventVolunteer,
        departmentId: 'dept-other',
      } as never);

      await expect(
        service.assignHierarchyRole(validInput, 'user-1')
      ).rejects.toThrow(ValidationError);
    });

    it('happy path: upserts DepartmentHierarchy with correct fields', async () => {
      vi.mocked(prisma.department.findUnique).mockResolvedValue({
        ...mockDepartment,
        overseer: { userId: 'user-1' },
        eventId: 'event-1',
      } as never);
      vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue(mockEventVolunteer as never);
      vi.mocked(prisma.departmentHierarchy.upsert).mockResolvedValue({
        id: 'dh-1',
        departmentId: 'dept-1',
        eventVolunteerId: 'ev-1',
        hierarchyRole: 'ASSISTANT_OVERSEER',
        eventVolunteer: { ...mockEventVolunteer, user: {} },
        department: mockDepartment,
      } as never);

      const result = await service.assignHierarchyRole(validInput, 'user-1');

      expect(prisma.departmentHierarchy.upsert).toHaveBeenCalledOnce();
      const upsertArgs = vi.mocked(prisma.departmentHierarchy.upsert).mock.calls[0][0] as {
        where: {
          departmentId_hierarchyRole_eventVolunteerId: {
            departmentId: string;
            hierarchyRole: string;
            eventVolunteerId: string;
          };
        };
        create: { departmentId: string; eventVolunteerId: string; hierarchyRole: string };
      };
      expect(upsertArgs.where.departmentId_hierarchyRole_eventVolunteerId.departmentId).toBe('dept-1');
      expect(upsertArgs.where.departmentId_hierarchyRole_eventVolunteerId.hierarchyRole).toBe('ASSISTANT_OVERSEER');
      expect(upsertArgs.where.departmentId_hierarchyRole_eventVolunteerId.eventVolunteerId).toBe('ev-1');
      expect(upsertArgs.create.departmentId).toBe('dept-1');
      expect(upsertArgs.create.eventVolunteerId).toBe('ev-1');
      expect(upsertArgs.create.hierarchyRole).toBe('ASSISTANT_OVERSEER');
      expect(result).toBeDefined();
    });
  });

  // =========================================================================
  // removeHierarchyRole
  // =========================================================================

  describe('removeHierarchyRole', () => {
    it('throws NotFoundError when department does not exist', async () => {
      vi.mocked(prisma.department.findUnique).mockResolvedValue(null);

      await expect(
        service.removeHierarchyRole('dept-1', 'ev-1', 'user-1')
      ).rejects.toThrow(NotFoundError);
    });

    it('throws AuthorizationError when caller is not the department overseer', async () => {
      vi.mocked(prisma.department.findUnique).mockResolvedValue({
        ...mockDepartment,
        overseer: { userId: 'user-1' },
        eventId: 'event-1',
      } as never);

      await expect(
        service.removeHierarchyRole('dept-1', 'ev-1', 'user-99')
      ).rejects.toThrow(AuthorizationError);
    });
  });
});
