/**
 * Auth Guards Unit Tests
 *
 * Tests all 11 exported guard functions from graphql/guards/auth.ts.
 * Prisma is mocked via createPrismaMock(). No database or JWT signing occurs.
 *
 * Sync guards tested:
 *   requireUser, requireOverseer, requireAdmin, requireAuth,
 *   requireAppAdmin, tryRequireAdmin
 *
 * Async guards tested (prisma mock required):
 *   requireEventAccess, resolveUserEventVolunteer, requireCaptain,
 *   requireDeptAccess, tryRequireDeptAccessByEvent, requireAreaOverseer
 */
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { buildContext, createPrismaMock } from '../unitTestHelpers.js';
import {
  requireUser,
  requireOverseer,
  requireAdmin,
  requireAuth,
  requireAppAdmin,
  tryRequireAdmin,
  requireEventAccess,
  resolveUserEventVolunteer,
  requireCaptain,
  requireDeptAccess,
  tryRequireDeptAccessByEvent,
  requireAreaOverseer,
} from '../../graphql/guards/auth.js';
import { AuthenticationError, AuthorizationError } from '../../utils/errors.js';

// ---------------------------------------------------------------------------
// Sync Guards
// ---------------------------------------------------------------------------

describe('requireUser', () => {
  it('throws AuthenticationError when no user in context', () => {
    const ctx = buildContext({ user: null });
    expect(() => requireUser(ctx)).toThrow(AuthenticationError);
  });

  it('does not throw when user is present', () => {
    const ctx = buildContext();
    expect(() => requireUser(ctx)).not.toThrow();
  });
});

describe('requireOverseer', () => {
  it('throws AuthenticationError when no user in context', () => {
    const ctx = buildContext({ user: null });
    expect(() => requireOverseer(ctx)).toThrow(AuthenticationError);
  });

  it('throws AuthorizationError when user is not an overseer', () => {
    const ctx = buildContext({ user: { isOverseer: false } });
    expect(() => requireOverseer(ctx)).toThrow(AuthorizationError);
  });

  it('does not throw when user is an overseer', () => {
    const ctx = buildContext({ user: { isOverseer: true } });
    expect(() => requireOverseer(ctx)).not.toThrow();
  });
});

describe('requireAdmin', () => {
  it('throws AuthenticationError when no user in context (alias for requireOverseer)', () => {
    const ctx = buildContext({ user: null });
    expect(() => requireAdmin(ctx)).toThrow(AuthenticationError);
  });

  it('throws AuthorizationError when user is not an overseer', () => {
    const ctx = buildContext({ user: { isOverseer: false } });
    expect(() => requireAdmin(ctx)).toThrow(AuthorizationError);
  });

  it('does not throw when user is an overseer', () => {
    const ctx = buildContext({ user: { isOverseer: true } });
    expect(() => requireAdmin(ctx)).not.toThrow();
  });
});

describe('requireAuth', () => {
  it('throws AuthenticationError when no user in context', () => {
    const ctx = buildContext({ user: null });
    expect(() => requireAuth(ctx)).toThrow(AuthenticationError);
  });

  it('does not throw when user is present (volunteer)', () => {
    const ctx = buildContext({ user: { isOverseer: false } });
    expect(() => requireAuth(ctx)).not.toThrow();
  });

  it('does not throw when user is present (overseer)', () => {
    const ctx = buildContext({ user: { isOverseer: true } });
    expect(() => requireAuth(ctx)).not.toThrow();
  });
});

describe('requireAppAdmin', () => {
  it('throws AuthenticationError when no user in context', () => {
    const ctx = buildContext({ user: null });
    expect(() => requireAppAdmin(ctx)).toThrow(AuthenticationError);
  });

  it('throws AuthorizationError when user is not an app admin', () => {
    const ctx = buildContext({ user: { isAppAdmin: false } });
    expect(() => requireAppAdmin(ctx)).toThrow(AuthorizationError);
  });

  it('does not throw when user is an app admin', () => {
    const ctx = buildContext({ user: { isAppAdmin: true } });
    expect(() => requireAppAdmin(ctx)).not.toThrow();
  });
});

describe('tryRequireAdmin', () => {
  it('returns false when no user in context', () => {
    const ctx = buildContext({ user: null });
    expect(tryRequireAdmin(ctx)).toBe(false);
  });

  it('returns false when user is not an overseer', () => {
    const ctx = buildContext({ user: { isOverseer: false } });
    expect(tryRequireAdmin(ctx)).toBe(false);
  });

  it('returns true when user is an overseer', () => {
    const ctx = buildContext({ user: { isOverseer: true } });
    expect(tryRequireAdmin(ctx)).toBe(true);
  });
});

// ---------------------------------------------------------------------------
// Async Guards
// ---------------------------------------------------------------------------

describe('requireEventAccess', () => {
  let prisma: ReturnType<typeof createPrismaMock>;

  beforeEach(() => {
    vi.clearAllMocks();
    prisma = createPrismaMock();
  });

  it('throws AuthenticationError when no user in context', async () => {
    const ctx = buildContext({ user: null, prisma });
    await expect(requireEventAccess(ctx, 'event-1')).rejects.toThrow(AuthenticationError);
  });

  it('throws AuthorizationError when eventAdmin record is not found', async () => {
    vi.mocked(prisma.eventAdmin.findUnique).mockResolvedValue(null);
    const ctx = buildContext({ prisma });
    await expect(requireEventAccess(ctx, 'event-1')).rejects.toThrow(AuthorizationError);
  });

  it('throws AuthorizationError when role is not in allowedRoles', async () => {
    vi.mocked(prisma.eventAdmin.findUnique).mockResolvedValue({
      id: 'ea-1',
      userId: 'user-db-id',
      eventId: 'event-1',
      role: 'DEPARTMENT_OVERSEER',
      departmentId: 'dept-1',
      createdAt: new Date(),
      updatedAt: new Date(),
    } as never);
    const ctx = buildContext({ prisma });
    // allowedRoles is empty — no role matches
    await expect(requireEventAccess(ctx, 'event-1', [])).rejects.toThrow(AuthorizationError);
  });

  it('does not throw when eventAdmin is found with no role restriction', async () => {
    vi.mocked(prisma.eventAdmin.findUnique).mockResolvedValue({
      id: 'ea-1',
      userId: 'user-db-id',
      eventId: 'event-1',
      role: 'DEPARTMENT_OVERSEER',
      departmentId: 'dept-1',
      createdAt: new Date(),
      updatedAt: new Date(),
    } as never);
    const ctx = buildContext({ prisma });
    await expect(requireEventAccess(ctx, 'event-1')).resolves.toBeUndefined();
  });

  it('does not throw when eventAdmin role matches an allowedRole', async () => {
    vi.mocked(prisma.eventAdmin.findUnique).mockResolvedValue({
      id: 'ea-1',
      userId: 'user-db-id',
      eventId: 'event-1',
      role: 'DEPARTMENT_OVERSEER',
      departmentId: 'dept-1',
      createdAt: new Date(),
      updatedAt: new Date(),
    } as never);
    const ctx = buildContext({ prisma });
    await expect(
      requireEventAccess(ctx, 'event-1', ['DEPARTMENT_OVERSEER' as never])
    ).resolves.toBeUndefined();
  });
});

// ---------------------------------------------------------------------------

describe('resolveUserEventVolunteer', () => {
  let prisma: ReturnType<typeof createPrismaMock>;

  beforeEach(() => {
    vi.clearAllMocks();
    prisma = createPrismaMock();
  });

  it('throws AuthorizationError when no eventVolunteer record found', async () => {
    vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue(null);
    await expect(
      resolveUserEventVolunteer('user-db-id', 'event-1', prisma)
    ).rejects.toThrow(AuthorizationError);
  });

  it('returns { id, departmentId } when eventVolunteer is found', async () => {
    vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue({
      id: 'ev-1',
      departmentId: 'dept-1',
    } as never);
    const result = await resolveUserEventVolunteer('user-db-id', 'event-1', prisma);
    expect(result).toEqual({ id: 'ev-1', departmentId: 'dept-1' });
  });
});

// ---------------------------------------------------------------------------

describe('requireCaptain', () => {
  let prisma: ReturnType<typeof createPrismaMock>;

  beforeEach(() => {
    vi.clearAllMocks();
    prisma = createPrismaMock();
  });

  it('throws AuthenticationError when no user in context', async () => {
    const ctx = buildContext({ user: null, prisma });
    await expect(requireCaptain(ctx, 'event-1')).rejects.toThrow(AuthenticationError);
  });

  it('returns eventAdmin data immediately when overseer has event access (bypass)', async () => {
    vi.mocked(prisma.eventAdmin.findUnique).mockResolvedValue({
      id: 'ea-1',
      userId: 'user-db-id',
      eventId: 'event-1',
      role: 'DEPARTMENT_OVERSEER',
      departmentId: 'dept-1',
      createdAt: new Date(),
      updatedAt: new Date(),
    } as never);
    // eventVolunteer lookup inside the overseer bypass branch
    vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue({
      id: 'ev-1',
      userId: 'user-db-id',
      eventId: 'event-1',
      departmentId: 'dept-1',
    } as never);

    const ctx = buildContext({ user: { isOverseer: true }, prisma });
    const result = await requireCaptain(ctx, 'event-1');
    // Bypass: should return data without checking scheduleAssignment or areaCaptain
    expect(result).toMatchObject({ departmentId: 'dept-1' });
    expect(prisma.scheduleAssignment.findFirst).not.toHaveBeenCalled();
    expect(prisma.areaCaptain.findFirst).not.toHaveBeenCalled();
  });

  it('throws AuthorizationError when volunteer has no eventVolunteer (or no departmentId)', async () => {
    vi.mocked(prisma.eventAdmin.findUnique).mockResolvedValue(null);
    vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue(null);
    const ctx = buildContext({ user: { isOverseer: false }, prisma });
    await expect(requireCaptain(ctx, 'event-1')).rejects.toThrow(AuthorizationError);
  });

  it('throws AuthorizationError when volunteer has no captain assignment and no areaCaptain', async () => {
    // Non-overseer path — no eventAdmin lookup result needed
    vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue({
      id: 'ev-1',
      userId: 'user-db-id',
      eventId: 'event-1',
      departmentId: 'dept-1',
    } as never);
    vi.mocked(prisma.scheduleAssignment.findFirst).mockResolvedValue(null);
    vi.mocked(prisma.areaCaptain.findFirst).mockResolvedValue(null);

    const ctx = buildContext({ user: { isOverseer: false }, prisma });
    await expect(requireCaptain(ctx, 'event-1')).rejects.toThrow(AuthorizationError);
  });

  it('returns volunteer data when volunteer has a captain scheduleAssignment', async () => {
    vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue({
      id: 'ev-1',
      userId: 'user-db-id',
      eventId: 'event-1',
      departmentId: 'dept-1',
    } as never);
    vi.mocked(prisma.scheduleAssignment.findFirst).mockResolvedValue({
      id: 'sa-1',
      isCaptain: true,
    } as never);
    vi.mocked(prisma.areaCaptain.findFirst).mockResolvedValue(null);

    const ctx = buildContext({ user: { isOverseer: false }, prisma });
    const result = await requireCaptain(ctx, 'event-1');
    expect(result).toEqual({ eventVolunteerId: 'ev-1', departmentId: 'dept-1' });
  });

  it('returns volunteer data when volunteer has an accepted areaCaptain assignment', async () => {
    vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue({
      id: 'ev-1',
      userId: 'user-db-id',
      eventId: 'event-1',
      departmentId: 'dept-1',
    } as never);
    vi.mocked(prisma.scheduleAssignment.findFirst).mockResolvedValue(null);
    vi.mocked(prisma.areaCaptain.findFirst).mockResolvedValue({
      id: 'ac-1',
      eventVolunteerId: 'ev-1',
      status: 'ACCEPTED',
    } as never);

    const ctx = buildContext({ user: { isOverseer: false }, prisma });
    const result = await requireCaptain(ctx, 'event-1');
    expect(result).toEqual({ eventVolunteerId: 'ev-1', departmentId: 'dept-1' });
  });
});

// ---------------------------------------------------------------------------

describe('requireDeptAccess', () => {
  let prisma: ReturnType<typeof createPrismaMock>;

  beforeEach(() => {
    vi.clearAllMocks();
    prisma = createPrismaMock();
  });

  it('throws AuthorizationError when department is not found', async () => {
    vi.mocked(prisma.department.findUnique).mockResolvedValue(null);
    const ctx = buildContext({ prisma });
    await expect(requireDeptAccess(ctx, 'dept-1')).rejects.toThrow(AuthorizationError);
  });

  it('returns { eventId, userId, isOverseer: true } via primary overseer path (userId match)', async () => {
    vi.mocked(prisma.department.findUnique).mockResolvedValue({
      eventId: 'event-1',
      overseer: { userId: 'user-db-id' },
    } as never);

    const ctx = buildContext({ prisma });
    const result = await requireDeptAccess(ctx, 'dept-1');
    expect(result).toEqual({ eventId: 'event-1', userId: 'user-db-id', isOverseer: true });
    // Should short-circuit without checking hierarchy
    expect(prisma.departmentHierarchy.findFirst).not.toHaveBeenCalled();
  });

  it('returns { eventId, userId, isOverseer: false } via assistant overseer path (hierarchy found)', async () => {
    vi.mocked(prisma.department.findUnique).mockResolvedValue({
      eventId: 'event-1',
      overseer: { userId: 'some-other-user-id' },
    } as never);
    vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue({
      id: 'ev-1',
    } as never);
    vi.mocked(prisma.departmentHierarchy.findFirst).mockResolvedValue({
      id: 'dh-1',
      hierarchyRole: 'ASSISTANT_OVERSEER',
    } as never);

    const ctx = buildContext({ prisma });
    const result = await requireDeptAccess(ctx, 'dept-1');
    expect(result).toEqual({ eventId: 'event-1', userId: 'user-db-id', isOverseer: false });
  });

  it('throws AuthorizationError when neither primary overseer nor assistant overseer match', async () => {
    vi.mocked(prisma.department.findUnique).mockResolvedValue({
      eventId: 'event-1',
      overseer: { userId: 'some-other-user-id' },
    } as never);
    vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue({
      id: 'ev-1',
    } as never);
    vi.mocked(prisma.departmentHierarchy.findFirst).mockResolvedValue(null);

    const ctx = buildContext({ prisma });
    await expect(requireDeptAccess(ctx, 'dept-1')).rejects.toThrow(AuthorizationError);
  });
});

// ---------------------------------------------------------------------------

describe('tryRequireDeptAccessByEvent', () => {
  let prisma: ReturnType<typeof createPrismaMock>;

  beforeEach(() => {
    vi.clearAllMocks();
    prisma = createPrismaMock();
  });

  it('returns null when no user in context', async () => {
    const ctx = buildContext({ user: null, prisma });
    const result = await tryRequireDeptAccessByEvent(ctx, 'event-1');
    expect(result).toBeNull();
    expect(prisma.eventVolunteer.findUnique).not.toHaveBeenCalled();
  });

  it('returns null when no eventVolunteer found (or no departmentId)', async () => {
    vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue(null);
    const ctx = buildContext({ prisma });
    const result = await tryRequireDeptAccessByEvent(ctx, 'event-1');
    expect(result).toBeNull();
  });

  it('returns null when no ASSISTANT_OVERSEER hierarchy entry found', async () => {
    vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue({
      id: 'ev-1',
      departmentId: 'dept-1',
    } as never);
    vi.mocked(prisma.departmentHierarchy.findFirst).mockResolvedValue(null);
    const ctx = buildContext({ prisma });
    const result = await tryRequireDeptAccessByEvent(ctx, 'event-1');
    expect(result).toBeNull();
  });

  it('returns { departmentId, userId } when hierarchy entry is found', async () => {
    vi.mocked(prisma.eventVolunteer.findUnique).mockResolvedValue({
      id: 'ev-1',
      departmentId: 'dept-1',
    } as never);
    vi.mocked(prisma.departmentHierarchy.findFirst).mockResolvedValue({
      id: 'dh-1',
      hierarchyRole: 'ASSISTANT_OVERSEER',
    } as never);
    const ctx = buildContext({ prisma });
    const result = await tryRequireDeptAccessByEvent(ctx, 'event-1');
    expect(result).toEqual({ departmentId: 'dept-1', userId: 'user-db-id' });
  });
});

// ---------------------------------------------------------------------------

describe('requireAreaOverseer', () => {
  let prisma: ReturnType<typeof createPrismaMock>;

  beforeEach(() => {
    vi.clearAllMocks();
    prisma = createPrismaMock();
  });

  it('throws AuthorizationError when post has no areaId', async () => {
    vi.mocked(prisma.post.findUnique).mockResolvedValue({
      id: 'post-1',
      areaId: null,
    } as never);
    const ctx = buildContext({ prisma });
    await expect(requireAreaOverseer(ctx, 'post-1')).rejects.toThrow(AuthorizationError);
  });

  it('throws AuthorizationError when no eventVolunteer found for the user', async () => {
    vi.mocked(prisma.post.findUnique).mockResolvedValue({
      id: 'post-1',
      areaId: 'area-1',
    } as never);
    vi.mocked(prisma.eventVolunteer.findFirst).mockResolvedValue(null);
    const ctx = buildContext({ prisma });
    await expect(requireAreaOverseer(ctx, 'post-1')).rejects.toThrow(AuthorizationError);
  });

  it('throws AuthorizationError when no AREA_OVERSEER hierarchy entry found', async () => {
    vi.mocked(prisma.post.findUnique).mockResolvedValue({
      id: 'post-1',
      areaId: 'area-1',
    } as never);
    vi.mocked(prisma.eventVolunteer.findFirst).mockResolvedValue({
      id: 'ev-1',
    } as never);
    vi.mocked(prisma.departmentHierarchy.findFirst).mockResolvedValue(null);
    const ctx = buildContext({ prisma });
    await expect(requireAreaOverseer(ctx, 'post-1')).rejects.toThrow(AuthorizationError);
  });

  it('returns { eventVolunteerId, areaId } when AREA_OVERSEER hierarchy entry is found', async () => {
    vi.mocked(prisma.post.findUnique).mockResolvedValue({
      id: 'post-1',
      areaId: 'area-1',
    } as never);
    vi.mocked(prisma.eventVolunteer.findFirst).mockResolvedValue({
      id: 'ev-1',
    } as never);
    vi.mocked(prisma.departmentHierarchy.findFirst).mockResolvedValue({
      id: 'dh-1',
      hierarchyRole: 'AREA_OVERSEER',
      areaId: 'area-1',
    } as never);
    const ctx = buildContext({ prisma });
    const result = await requireAreaOverseer(ctx, 'post-1');
    expect(result).toEqual({ eventVolunteerId: 'ev-1', areaId: 'area-1' });
  });
});
