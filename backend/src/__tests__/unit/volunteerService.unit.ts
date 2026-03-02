/**
 * VolunteerService Unit Tests
 *
 * Tests business logic for volunteer management: creation, join requests,
 * approvals, denials, direct-add by userId, and placeholder user linking.
 * Prisma is mocked via createPrismaMock(). The credentials utility is
 * module-mocked so generated IDs are deterministic.
 */
import { vi, describe, it, expect, beforeEach } from 'vitest';
import { createPrismaMock } from '../unitTestHelpers.js';
import { VolunteerService } from '../../services/volunteerService.js';
import { NotFoundError, ValidationError } from '../../utils/errors.js';

// ---------------------------------------------------------------------------
// Module mocks — hoisted before dynamic imports
// ---------------------------------------------------------------------------
vi.mock('../../utils/credentials.js', () => ({
  generateUserId: vi.fn().mockReturnValue('NEWID1'),
}));

// ---------------------------------------------------------------------------
// Shared mock data factories
// Prisma mock fns accept `unknown` return values — we cast with `as any`
// to avoid satisfying the full generated Prisma type shapes in test fixtures.
// ---------------------------------------------------------------------------

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyRecord = Record<string, any>;

function makeEvent(overrides: AnyRecord = {}): AnyRecord {
  return {
    id: 'event-id-1',
    name: 'Circuit Assembly 2026',
    eventType: 'CIRCUIT_ASSEMBLY_CO',
    circuitId: 'circuit-id-1',
    isPublic: true,
    createdAt: new Date(),
    updatedAt: new Date(),
    ...overrides,
  };
}

function makeUser(overrides: AnyRecord = {}): AnyRecord {
  return {
    id: 'user-db-id',
    userId: 'USR001',
    email: 'test@example.com',
    firstName: 'John',
    lastName: 'Doe',
    congregation: 'Midtown Congregation',
    isPlaceholder: false,
    isOverseer: false,
    isAppAdmin: false,
    passwordHash: null,
    phone: null,
    appointmentStatus: 'PUBLISHER',
    congregationId: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    ...overrides,
  };
}

function makePlaceholderUser(overrides: AnyRecord = {}): AnyRecord {
  return {
    id: 'ph-id',
    userId: 'PHID01',
    email: 'PHID01@placeholder.assemblyops.io',
    firstName: 'Jane',
    lastName: 'Smith',
    congregation: 'West Congregation',
    isPlaceholder: true,
    isOverseer: false,
    isAppAdmin: false,
    passwordHash: null,
    phone: null,
    appointmentStatus: 'PUBLISHER',
    congregationId: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    eventVolunteers: [],
    ...overrides,
  };
}

function makeEventVolunteer(overrides: AnyRecord = {}): AnyRecord {
  return {
    id: 'ev-id-1',
    userId: 'user-db-id',
    eventId: 'event-id-1',
    departmentId: 'dept-id-1',
    roleId: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    user: makeUser(),
    ...overrides,
  };
}

function makeJoinRequest(overrides: AnyRecord = {}): AnyRecord {
  return {
    id: 'req-id-1',
    eventId: 'event-id-1',
    userId: 'user-db-id',
    status: 'PENDING',
    departmentType: null,
    note: null,
    resolvedAt: null,
    resolvedById: null,
    createdAt: new Date(),
    user: makeUser(),
    event: makeEvent(),
    ...overrides,
  };
}

function makeCongregation(overrides: AnyRecord = {}): AnyRecord {
  return {
    id: 'cong-id-1',
    name: 'Midtown Congregation',
    circuitId: 'circuit-id-1',
    state: 'TX',
    language: 'English',
    createdAt: new Date(),
    updatedAt: new Date(),
    ...overrides,
  };
}

function makeCircuit(overrides: AnyRecord = {}): AnyRecord {
  return {
    id: 'circuit-id-1',
    code: 'UNKNOWN',
    region: 'Unknown',
    language: 'English',
    createdAt: new Date(),
    updatedAt: new Date(),
    ...overrides,
  };
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe('VolunteerService', () => {
  let prisma: ReturnType<typeof createPrismaMock>;
  let service: VolunteerService;

  beforeEach(() => {
    vi.clearAllMocks();
    prisma = createPrismaMock();
    service = new VolunteerService(prisma);
  });

  // =========================================================================
  // createVolunteer
  // =========================================================================

  describe('createVolunteer', () => {
    const validInput = {
      firstName: 'John',
      lastName: 'Doe',
      congregation: 'Midtown Congregation',
      email: null,
      phone: null,
      notes: null,
    };

    it('throws ValidationError when firstName is empty', async () => {
      await expect(
        service.createVolunteer('event-id-1', {
          ...validInput,
          firstName: '',
        })
      ).rejects.toThrow(ValidationError);
    });

    it('throws ValidationError when congregation is empty', async () => {
      await expect(
        service.createVolunteer('event-id-1', {
          ...validInput,
          congregation: '',
        })
      ).rejects.toThrow(ValidationError);
    });

    it('throws NotFoundError when event does not exist', async () => {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.event.findUnique).mockResolvedValue(null as any);

      await expect(
        service.createVolunteer('nonexistent-event', validInput)
      ).rejects.toThrow(NotFoundError);

      expect(prisma.event.findUnique).toHaveBeenCalledWith({ where: { id: 'nonexistent-event' } });
    });

    it('happy path with email: finds existing user and creates EventVolunteer without creating a new User', async () => {
      const existingUser = makeUser({ email: 'existing@test.com' });
      const ev = makeEventVolunteer({ user: existingUser });

      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.event.findUnique).mockResolvedValue(makeEvent() as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.congregation.findFirst).mockResolvedValue(makeCongregation() as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.user.findUnique).mockResolvedValue(existingUser as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.eventVolunteer.create).mockResolvedValue(ev as any);

      const result = await service.createVolunteer('event-id-1', {
        ...validInput,
        email: 'existing@test.com',
      });

      expect(prisma.user.create).not.toHaveBeenCalled();
      expect(prisma.eventVolunteer.create).toHaveBeenCalledOnce();
      expect(result).toEqual({
        id: ev.id,
        firstName: existingUser.firstName,
        lastName: existingUser.lastName,
        congregation: existingUser.congregation,
      });
    });

    it('happy path without email: creates placeholder User with isPlaceholder=true', async () => {
      const placeholderUser = makeUser({
        id: 'new-user-id',
        userId: 'NEWID1',
        email: 'NEWID1@placeholder.assemblyops.io',
        isPlaceholder: true,
        congregation: 'Midtown Congregation',
      });
      const ev = makeEventVolunteer({ userId: 'new-user-id', user: placeholderUser });

      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.event.findUnique).mockResolvedValue(makeEvent() as any);
      // No existing congregation — triggers circuit upsert + congregation create
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.congregation.findFirst).mockResolvedValue(null as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.circuit.upsert).mockResolvedValue(makeCircuit() as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.congregation.create).mockResolvedValue(makeCongregation() as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.user.create).mockResolvedValue(placeholderUser as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.eventVolunteer.create).mockResolvedValue(ev as any);

      const result = await service.createVolunteer('event-id-1', validInput);

      expect(prisma.user.create).toHaveBeenCalledOnce();
      const createArgs = vi.mocked(prisma.user.create).mock.calls[0][0] as {
        data: { isPlaceholder: boolean; email: string; userId: string };
      };
      expect(createArgs.data.isPlaceholder).toBe(true);
      expect(createArgs.data.email).toMatch(/@placeholder\.assemblyops\.io$/);
      expect(createArgs.data.userId).toBe('NEWID1');

      expect(result.id).toBe(ev.id);
      expect(result.firstName).toBe(placeholderUser.firstName);
    });
  });

  // =========================================================================
  // requestToJoinEvent
  // =========================================================================

  describe('requestToJoinEvent', () => {
    it('throws NotFoundError when event does not exist', async () => {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.event.findUnique).mockResolvedValue(null as any);

      await expect(
        service.requestToJoinEvent('bad-event', 'user-db-id')
      ).rejects.toThrow(NotFoundError);
    });

    it('throws ValidationError for REGIONAL_CONVENTION events (invite-only)', async () => {
      vi.mocked(prisma.event.findUnique).mockResolvedValue(
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        makeEvent({ eventType: 'REGIONAL_CONVENTION' }) as any
      );

      await expect(
        service.requestToJoinEvent('event-id-1', 'user-db-id')
      ).rejects.toThrow(ValidationError);
    });

    it('throws ValidationError for SPECIAL_CONVENTION events (invite-only)', async () => {
      vi.mocked(prisma.event.findUnique).mockResolvedValue(
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        makeEvent({ eventType: 'SPECIAL_CONVENTION' }) as any
      );

      await expect(
        service.requestToJoinEvent('event-id-1', 'user-db-id')
      ).rejects.toThrow(ValidationError);
    });

    it('throws ValidationError when user is already a volunteer for the event', async () => {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.event.findUnique).mockResolvedValue(makeEvent() as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue(makeEventVolunteer() as any);

      await expect(
        service.requestToJoinEvent('event-id-1', 'user-db-id')
      ).rejects.toThrow(ValidationError);
    });

    it('throws ValidationError when a PENDING join request already exists', async () => {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.event.findUnique).mockResolvedValue(makeEvent() as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue(null as any);
      vi.mocked(prisma.eventJoinRequest.findUnique).mockResolvedValue(
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        makeJoinRequest({ status: 'PENDING' }) as any
      );

      await expect(
        service.requestToJoinEvent('event-id-1', 'user-db-id')
      ).rejects.toThrow(ValidationError);
    });

    it('re-submits when previous request was DENIED: updates existing request back to PENDING', async () => {
      const deniedRequest = makeJoinRequest({ status: 'DENIED', id: 'denied-req-id' });
      const updatedRequest = makeJoinRequest({ status: 'PENDING', id: 'denied-req-id' });

      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.event.findUnique).mockResolvedValue(makeEvent() as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue(null as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.eventJoinRequest.findUnique).mockResolvedValue(deniedRequest as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.eventJoinRequest.update).mockResolvedValue(updatedRequest as any);

      const result = await service.requestToJoinEvent('event-id-1', 'user-db-id');

      expect(prisma.eventJoinRequest.update).toHaveBeenCalledOnce();
      const updateArgs = vi.mocked(prisma.eventJoinRequest.update).mock.calls[0][0] as {
        where: { id: string };
        data: { status: string; resolvedAt: null; resolvedById: null };
      };
      expect(updateArgs.where.id).toBe('denied-req-id');
      expect(updateArgs.data.status).toBe('PENDING');
      expect(updateArgs.data.resolvedAt).toBeNull();
      expect(updateArgs.data.resolvedById).toBeNull();

      expect(prisma.eventJoinRequest.create).not.toHaveBeenCalled();
      expect(result).toEqual(updatedRequest);
    });

    it('happy path: creates a new EventJoinRequest when no prior request exists', async () => {
      const newRequest = makeJoinRequest({ departmentType: 'ATTENDANT', note: 'Experienced volunteer' });

      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.event.findUnique).mockResolvedValue(makeEvent() as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue(null as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.eventJoinRequest.findUnique).mockResolvedValue(null as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.eventJoinRequest.create).mockResolvedValue(newRequest as any);

      const result = await service.requestToJoinEvent(
        'event-id-1',
        'user-db-id',
        'ATTENDANT',
        'Experienced volunteer'
      );

      expect(prisma.eventJoinRequest.create).toHaveBeenCalledOnce();
      const createArgs = vi.mocked(prisma.eventJoinRequest.create).mock.calls[0][0] as {
        data: { eventId: string; userId: string; departmentType: string; note: string };
      };
      expect(createArgs.data.eventId).toBe('event-id-1');
      expect(createArgs.data.userId).toBe('user-db-id');
      expect(createArgs.data.departmentType).toBe('ATTENDANT');
      expect(createArgs.data.note).toBe('Experienced volunteer');
      expect(result).toEqual(newRequest);
    });
  });

  // =========================================================================
  // approveJoinRequest
  // =========================================================================

  describe('approveJoinRequest', () => {
    it('throws NotFoundError when join request does not exist', async () => {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.eventJoinRequest.findUnique).mockResolvedValue(null as any);

      await expect(
        service.approveJoinRequest('nonexistent-req', 'admin-id')
      ).rejects.toThrow(NotFoundError);
    });

    it('throws ValidationError when join request is not PENDING', async () => {
      vi.mocked(prisma.eventJoinRequest.findUnique).mockResolvedValue(
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        makeJoinRequest({ status: 'APPROVED' }) as any
      );

      await expect(
        service.approveJoinRequest('req-id-1', 'admin-id')
      ).rejects.toThrow(ValidationError);
    });

    it('happy path: marks request APPROVED and creates EventVolunteer in a transaction', async () => {
      const pendingRequest = makeJoinRequest({ status: 'PENDING' });
      const approvedRequest = makeJoinRequest({ status: 'APPROVED' });
      const createdEv = makeEventVolunteer();

      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.eventJoinRequest.findUnique).mockResolvedValue(pendingRequest as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.eventJoinRequest.update).mockResolvedValue(approvedRequest as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.eventVolunteer.create).mockResolvedValue(createdEv as any);

      const result = await service.approveJoinRequest('req-id-1', 'admin-id');

      expect(prisma.$transaction).toHaveBeenCalledOnce();

      expect(prisma.eventJoinRequest.update).toHaveBeenCalledOnce();
      const updateArgs = vi.mocked(prisma.eventJoinRequest.update).mock.calls[0][0] as {
        where: { id: string };
        data: { status: string; resolvedById: string; resolvedAt: Date };
      };
      expect(updateArgs.where.id).toBe('req-id-1');
      expect(updateArgs.data.status).toBe('APPROVED');
      expect(updateArgs.data.resolvedById).toBe('admin-id');
      expect(updateArgs.data.resolvedAt).toBeInstanceOf(Date);

      expect(prisma.eventVolunteer.create).toHaveBeenCalledOnce();
      const evCreateArgs = vi.mocked(prisma.eventVolunteer.create).mock.calls[0][0] as {
        data: { userId: string; eventId: string };
      };
      expect(evCreateArgs.data.userId).toBe(pendingRequest.userId);
      expect(evCreateArgs.data.eventId).toBe(pendingRequest.eventId);

      expect(result).toEqual(createdEv);
    });
  });

  // =========================================================================
  // denyJoinRequest
  // =========================================================================

  describe('denyJoinRequest', () => {
    it('throws NotFoundError when join request does not exist', async () => {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.eventJoinRequest.findUnique).mockResolvedValue(null as any);

      await expect(
        service.denyJoinRequest('nonexistent-req', 'admin-id')
      ).rejects.toThrow(NotFoundError);
    });

    it('throws ValidationError when join request is not PENDING', async () => {
      vi.mocked(prisma.eventJoinRequest.findUnique).mockResolvedValue(
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        makeJoinRequest({ status: 'DENIED' }) as any
      );

      await expect(
        service.denyJoinRequest('req-id-1', 'admin-id')
      ).rejects.toThrow(ValidationError);
    });

    it('happy path: marks request DENIED with resolvedAt timestamp and optional denial reason', async () => {
      const pendingRequest = makeJoinRequest({ status: 'PENDING', note: 'original note' });
      const deniedRequest = makeJoinRequest({
        status: 'DENIED',
        note: 'Not enough capacity',
        resolvedAt: new Date(),
      });

      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.eventJoinRequest.findUnique).mockResolvedValue(pendingRequest as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.eventJoinRequest.update).mockResolvedValue(deniedRequest as any);

      const result = await service.denyJoinRequest('req-id-1', 'admin-id', 'Not enough capacity');

      expect(prisma.eventJoinRequest.update).toHaveBeenCalledOnce();
      const updateArgs = vi.mocked(prisma.eventJoinRequest.update).mock.calls[0][0] as {
        where: { id: string };
        data: { status: string; resolvedAt: Date; resolvedById: string; note: string };
      };
      expect(updateArgs.where.id).toBe('req-id-1');
      expect(updateArgs.data.status).toBe('DENIED');
      expect(updateArgs.data.resolvedAt).toBeInstanceOf(Date);
      expect(updateArgs.data.resolvedById).toBe('admin-id');
      expect(updateArgs.data.note).toBe('Not enough capacity');
      expect(result).toEqual(deniedRequest);
    });
  });

  // =========================================================================
  // addVolunteerByUserId
  // =========================================================================

  describe('addVolunteerByUserId', () => {
    it('throws NotFoundError when no user exists with the given userId shortcode', async () => {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.user.findUnique).mockResolvedValue(null as any);

      await expect(
        service.addVolunteerByUserId('event-id-1', 'BADID1', 'admin-id')
      ).rejects.toThrow(NotFoundError);

      expect(prisma.user.findUnique).toHaveBeenCalledWith({ where: { userId: 'BADID1' } });
    });

    it('throws ValidationError when user is already a volunteer for the event', async () => {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.user.findUnique).mockResolvedValue(makeUser() as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue(makeEventVolunteer() as any);

      await expect(
        service.addVolunteerByUserId('event-id-1', 'USR001', 'admin-id')
      ).rejects.toThrow(ValidationError);
    });

    it('happy path: creates EventVolunteer linked to the found user', async () => {
      const foundUser = makeUser({ id: 'user-db-id', userId: 'USR001' });
      const ev = makeEventVolunteer({ departmentId: 'dept-id-2' });

      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.user.findUnique).mockResolvedValue(foundUser as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue(null as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.eventVolunteer.create).mockResolvedValue(ev as any);

      const result = await service.addVolunteerByUserId('event-id-1', 'USR001', 'admin-id', 'dept-id-2');

      expect(prisma.eventVolunteer.create).toHaveBeenCalledOnce();
      const createArgs = vi.mocked(prisma.eventVolunteer.create).mock.calls[0][0] as {
        data: { userId: string; eventId: string; departmentId: string | undefined };
      };
      expect(createArgs.data.userId).toBe(foundUser.id);
      expect(createArgs.data.eventId).toBe('event-id-1');
      expect(createArgs.data.departmentId).toBe('dept-id-2');
      expect(result).toEqual(ev);
    });
  });

  // =========================================================================
  // linkPlaceholderUser
  // =========================================================================

  describe('linkPlaceholderUser', () => {
    it('throws NotFoundError when placeholder userId shortcode does not match any user', async () => {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.user.findUnique).mockResolvedValueOnce(null as any);

      await expect(
        service.linkPlaceholderUser('BADPLA', 'REAL01')
      ).rejects.toThrow(NotFoundError);
    });

    it('throws ValidationError when the found user is not a placeholder', async () => {
      const realUser = makeUser({ userId: 'NOTPH1', isPlaceholder: false });
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.user.findUnique).mockResolvedValueOnce({ ...realUser, eventVolunteers: [] } as any);

      await expect(
        service.linkPlaceholderUser('NOTPH1', 'REAL01')
      ).rejects.toThrow(ValidationError);
    });

    it('throws NotFoundError when real user userId shortcode does not match any user', async () => {
      const placeholder = makePlaceholderUser({ eventVolunteers: [] });

      vi.mocked(prisma.user.findUnique)
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        .mockResolvedValueOnce(placeholder as any)   // placeholder lookup
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        .mockResolvedValueOnce(null as any);          // real user lookup

      await expect(
        service.linkPlaceholderUser('PHID01', 'BADREA')
      ).rejects.toThrow(NotFoundError);
    });

    it('throws ValidationError when real user is itself a placeholder', async () => {
      const placeholder = makePlaceholderUser({ eventVolunteers: [] });
      const anotherPlaceholder = makePlaceholderUser({
        id: 'another-ph-id',
        userId: 'ANOTH1',
        isPlaceholder: true,
        eventVolunteers: [],
      });

      vi.mocked(prisma.user.findUnique)
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        .mockResolvedValueOnce(placeholder as any)
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        .mockResolvedValueOnce(anotherPlaceholder as any);

      await expect(
        service.linkPlaceholderUser('PHID01', 'ANOTH1')
      ).rejects.toThrow(ValidationError);
    });

    it('simple re-parent path: re-points placeholder EV to real user when no event collision exists', async () => {
      const phEv = makeEventVolunteer({ id: 'ph-ev-id', userId: 'ph-id', eventId: 'event-id-1' });
      const placeholder = makePlaceholderUser({ eventVolunteers: [phEv] });
      const realUser = makeUser({
        id: 'real-id',
        userId: 'REAL01',
        isPlaceholder: false,
        eventVolunteers: [], // No existing EV for event-id-1 — simple re-parent path
      });

      vi.mocked(prisma.user.findUnique)
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        .mockResolvedValueOnce(placeholder as any)
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        .mockResolvedValueOnce(realUser as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.eventVolunteer.update).mockResolvedValue({ ...phEv, userId: 'real-id' } as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.user.delete).mockResolvedValue(placeholder as any);

      const result = await service.linkPlaceholderUser('PHID01', 'REAL01');

      expect(prisma.$transaction).toHaveBeenCalledOnce();

      // EV must be re-pointed to real user
      expect(prisma.eventVolunteer.update).toHaveBeenCalledOnce();
      const evUpdateArgs = vi.mocked(prisma.eventVolunteer.update).mock.calls[0][0] as {
        where: { id: string };
        data: { userId: string };
      };
      expect(evUpdateArgs.where.id).toBe('ph-ev-id');
      expect(evUpdateArgs.data.userId).toBe('real-id');

      // Placeholder user must be deleted
      expect(prisma.user.delete).toHaveBeenCalledOnce();
      const deleteArgs = vi.mocked(prisma.user.delete).mock.calls[0][0] as {
        where: { id: string };
      };
      expect(deleteArgs.where.id).toBe('ph-id');

      expect(result).toEqual({
        success: true,
        mergedCount: 1,
        message: expect.stringContaining('1'),
      });
    });

    it('conflict merge path: deletes conflicting ScheduleAssignments then re-parents the rest to real EV', async () => {
      const phEv = makeEventVolunteer({ id: 'ph-ev-id', userId: 'ph-id', eventId: 'event-id-1' });
      const realEv = makeEventVolunteer({ id: 'real-ev-id', userId: 'real-id', eventId: 'event-id-1' });

      const placeholder = makePlaceholderUser({ eventVolunteers: [phEv] });
      const realUser = makeUser({
        id: 'real-id',
        userId: 'REAL01',
        isPlaceholder: false,
        eventVolunteers: [realEv], // Collision: same event
      });

      vi.mocked(prisma.user.findUnique)
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        .mockResolvedValueOnce(placeholder as any)
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        .mockResolvedValueOnce(realUser as any);

      // Real user has assignment on session-1/shift-1; placeholder has the same key (conflict)
      const realAssignments = [{ sessionId: 'session-1', shiftId: 'shift-1' }];
      const phAssignmentsConflict = [{ id: 'ph-assign-1', sessionId: 'session-1', shiftId: 'shift-1' }];

      vi.mocked(prisma.scheduleAssignment.findMany)
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        .mockResolvedValueOnce(realAssignments as any)
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        .mockResolvedValueOnce(phAssignmentsConflict as any);

      // All other constrained tables: no conflicts
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.departmentHierarchy.findMany).mockResolvedValue([] as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.reminderConfirmation.findMany).mockResolvedValue([] as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.lanyardCheckout.findMany).mockResolvedValue([] as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.meetingAttendance.findMany).mockResolvedValue([] as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.aVSafetyBriefingAttendee.findMany).mockResolvedValue([] as any);

      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.scheduleAssignment.deleteMany).mockResolvedValue({ count: 1 } as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.scheduleAssignment.updateMany).mockResolvedValue({ count: 0 } as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.departmentHierarchy.updateMany).mockResolvedValue({ count: 0 } as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.reminderConfirmation.updateMany).mockResolvedValue({ count: 0 } as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.lanyardCheckout.updateMany).mockResolvedValue({ count: 0 } as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.meetingAttendance.updateMany).mockResolvedValue({ count: 0 } as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.aVSafetyBriefingAttendee.updateMany).mockResolvedValue({ count: 0 } as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.areaCaptain.updateMany).mockResolvedValue({ count: 0 } as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.walkThroughCompletion.updateMany).mockResolvedValue({ count: 0 } as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.postSessionStatus.updateMany).mockResolvedValue({ count: 0 } as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.aVEquipmentCheckout.updateMany).mockResolvedValue({ count: 0 } as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.aVDamageReport.updateMany).mockResolvedValue({ count: 0 } as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.checkIn.updateMany).mockResolvedValue({ count: 0 } as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.message.updateMany).mockResolvedValue({ count: 0 } as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.lostPersonAlert.updateMany).mockResolvedValue({ count: 0 } as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.safetyIncident.updateMany).mockResolvedValue({ count: 0 } as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.eventVolunteer.delete).mockResolvedValue(phEv as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.user.delete).mockResolvedValue(placeholder as any);

      const result = await service.linkPlaceholderUser('PHID01', 'REAL01');

      // Conflicting assignment must be deleted first
      expect(prisma.scheduleAssignment.deleteMany).toHaveBeenCalledOnce();
      const deleteAssignArgs = vi.mocked(prisma.scheduleAssignment.deleteMany).mock.calls[0][0] as {
        where: { id: { in: string[] } };
      };
      expect(deleteAssignArgs.where.id.in).toContain('ph-assign-1');

      // Remaining assignments re-parented to real EV
      expect(prisma.scheduleAssignment.updateMany).toHaveBeenCalledOnce();
      const updateAssignArgs = vi.mocked(prisma.scheduleAssignment.updateMany).mock.calls[0][0] as {
        where: { eventVolunteerId: string };
        data: { eventVolunteerId: string };
      };
      expect(updateAssignArgs.where.eventVolunteerId).toBe('ph-ev-id');
      expect(updateAssignArgs.data.eventVolunteerId).toBe('real-ev-id');

      // Simple updateMany tables all called for the placeholder EV
      expect(prisma.areaCaptain.updateMany).toHaveBeenCalledOnce();
      expect(prisma.walkThroughCompletion.updateMany).toHaveBeenCalledOnce();
      expect(prisma.postSessionStatus.updateMany).toHaveBeenCalledOnce();
      expect(prisma.aVEquipmentCheckout.updateMany).toHaveBeenCalledOnce();
      expect(prisma.aVDamageReport.updateMany).toHaveBeenCalledOnce();
      expect(prisma.checkIn.updateMany).toHaveBeenCalledOnce();
      // message.updateMany called twice: senderVolId + eventVolunteerId
      expect(prisma.message.updateMany).toHaveBeenCalledTimes(2);
      expect(prisma.lostPersonAlert.updateMany).toHaveBeenCalledOnce();
      expect(prisma.safetyIncident.updateMany).toHaveBeenCalledOnce();

      // Placeholder EV deleted, then placeholder User deleted
      expect(prisma.eventVolunteer.delete).toHaveBeenCalledOnce();
      const deleteEvArgs = vi.mocked(prisma.eventVolunteer.delete).mock.calls[0][0] as {
        where: { id: string };
      };
      expect(deleteEvArgs.where.id).toBe('ph-ev-id');

      expect(prisma.user.delete).toHaveBeenCalledOnce();
      const deleteUserArgs = vi.mocked(prisma.user.delete).mock.calls[0][0] as {
        where: { id: string };
      };
      expect(deleteUserArgs.where.id).toBe('ph-id');

      expect(result).toEqual({
        success: true,
        mergedCount: 1,
        message: expect.stringContaining('1'),
      });
    });

    it('conflict merge path: skips deleteMany when no conflicts exist for constrained tables', async () => {
      const phEv = makeEventVolunteer({ id: 'ph-ev-id', userId: 'ph-id', eventId: 'event-id-1' });
      const realEv = makeEventVolunteer({ id: 'real-ev-id', userId: 'real-id', eventId: 'event-id-1' });

      const placeholder = makePlaceholderUser({ eventVolunteers: [phEv] });
      const realUser = makeUser({
        id: 'real-id',
        userId: 'REAL01',
        isPlaceholder: false,
        eventVolunteers: [realEv],
      });

      vi.mocked(prisma.user.findUnique)
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        .mockResolvedValueOnce(placeholder as any)
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        .mockResolvedValueOnce(realUser as any);

      // Real user has assignment on session-1/shift-1; placeholder on session-2/shift-2 — no conflict
      const realAssignments = [{ sessionId: 'session-1', shiftId: 'shift-1' }];
      const phAssignmentsNoConflict = [{ id: 'ph-assign-2', sessionId: 'session-2', shiftId: 'shift-2' }];

      vi.mocked(prisma.scheduleAssignment.findMany)
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        .mockResolvedValueOnce(realAssignments as any)
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        .mockResolvedValueOnce(phAssignmentsNoConflict as any);

      // All other constrained tables: no entries
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.departmentHierarchy.findMany).mockResolvedValue([] as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.reminderConfirmation.findMany).mockResolvedValue([] as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.lanyardCheckout.findMany).mockResolvedValue([] as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.meetingAttendance.findMany).mockResolvedValue([] as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.aVSafetyBriefingAttendee.findMany).mockResolvedValue([] as any);

      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.scheduleAssignment.updateMany).mockResolvedValue({ count: 1 } as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.departmentHierarchy.updateMany).mockResolvedValue({ count: 0 } as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.reminderConfirmation.updateMany).mockResolvedValue({ count: 0 } as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.lanyardCheckout.updateMany).mockResolvedValue({ count: 0 } as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.meetingAttendance.updateMany).mockResolvedValue({ count: 0 } as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.aVSafetyBriefingAttendee.updateMany).mockResolvedValue({ count: 0 } as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.areaCaptain.updateMany).mockResolvedValue({ count: 0 } as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.walkThroughCompletion.updateMany).mockResolvedValue({ count: 0 } as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.postSessionStatus.updateMany).mockResolvedValue({ count: 0 } as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.aVEquipmentCheckout.updateMany).mockResolvedValue({ count: 0 } as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.aVDamageReport.updateMany).mockResolvedValue({ count: 0 } as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.checkIn.updateMany).mockResolvedValue({ count: 0 } as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.message.updateMany).mockResolvedValue({ count: 0 } as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.lostPersonAlert.updateMany).mockResolvedValue({ count: 0 } as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.safetyIncident.updateMany).mockResolvedValue({ count: 0 } as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.eventVolunteer.delete).mockResolvedValue(phEv as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.user.delete).mockResolvedValue(placeholder as any);

      await service.linkPlaceholderUser('PHID01', 'REAL01');

      // deleteMany must NOT be called since there are no conflicting IDs
      expect(prisma.scheduleAssignment.deleteMany).not.toHaveBeenCalled();
      // updateMany IS called to re-parent the non-conflicting assignment
      expect(prisma.scheduleAssignment.updateMany).toHaveBeenCalledOnce();
    });

    it('returns mergedCount=0 and success=true when placeholder has no event volunteers', async () => {
      const placeholder = makePlaceholderUser({ eventVolunteers: [] });
      const realUser = makeUser({
        id: 'real-id',
        userId: 'REAL01',
        isPlaceholder: false,
        eventVolunteers: [],
      });

      vi.mocked(prisma.user.findUnique)
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        .mockResolvedValueOnce(placeholder as any)
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        .mockResolvedValueOnce(realUser as any);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      vi.mocked(prisma.user.delete).mockResolvedValue(placeholder as any);

      const result = await service.linkPlaceholderUser('PHID01', 'REAL01');

      // No EVs to process — no re-parent or conflict-merge calls
      expect(prisma.eventVolunteer.update).not.toHaveBeenCalled();
      expect(prisma.eventVolunteer.delete).not.toHaveBeenCalled();

      // Placeholder user still gets cleaned up
      expect(prisma.user.delete).toHaveBeenCalledOnce();

      expect(result).toEqual({
        success: true,
        mergedCount: 0,
        message: expect.stringContaining('0'),
      });
    });
  });
});
