/**
 * Unit Test Helpers
 *
 * Shared utilities for unit tests that mock Prisma and build auth contexts.
 * Used by all *.unit.ts files in __tests__/unit/.
 */
import { vi } from 'vitest';
import type { PrismaClient } from '@prisma/client';
import type { Context, UserContext } from '../graphql/context.js';

/**
 * Creates a deeply-mocked PrismaClient where every model method is a vi.fn().
 * Each test sets up return values via mockResolvedValue / mockRejectedValue.
 *
 * $transaction is wired to pass the mock itself as `tx`, so nested
 * calls inside transactions (tx.user.create, etc.) hit the same spies.
 */
export function createPrismaMock() {
  const makeModel = () => ({
    findUnique: vi.fn(),
    findFirst: vi.fn(),
    findMany: vi.fn(),
    create: vi.fn(),
    createMany: vi.fn(),
    update: vi.fn(),
    updateMany: vi.fn(),
    upsert: vi.fn(),
    delete: vi.fn(),
    deleteMany: vi.fn(),
    count: vi.fn(),
    findUniqueOrThrow: vi.fn(),
    groupBy: vi.fn(),
  });

  const mock: Record<string, unknown> = {
    user: makeModel(),
    refreshToken: makeModel(),
    oAuthConnection: makeModel(),
    congregation: makeModel(),
    circuit: makeModel(),
    event: makeModel(),
    eventAdmin: makeModel(),
    eventVolunteer: makeModel(),
    eventJoinRequest: makeModel(),
    department: makeModel(),
    departmentHierarchy: makeModel(),
    role: makeModel(),
    scheduleAssignment: makeModel(),
    shift: makeModel(),
    post: makeModel(),
    area: makeModel(),
    areaCaptain: makeModel(),
    session: makeModel(),
    checkIn: makeModel(),
    message: makeModel(),
    conversation: makeModel(),
    conversationParticipant: makeModel(),
    attendanceCount: makeModel(),
    facilityLocation: makeModel(),
    postSessionStatus: makeModel(),
    walkThroughCompletion: makeModel(),
    reminderConfirmation: makeModel(),
    lanyardCheckout: makeModel(),
    safetyIncident: makeModel(),
    lostPersonAlert: makeModel(),
    attendantMeeting: makeModel(),
    meetingAttendance: makeModel(),
    aVEquipmentItem: makeModel(),
    aVEquipmentCheckout: makeModel(),
    aVDamageReport: makeModel(),
    aVHazardAssessment: makeModel(),
    aVSafetyBriefing: makeModel(),
    aVSafetyBriefingAttendee: makeModel(),
    eventNote: makeModel(),
  };

  // $transaction: call callback with mock itself as tx, or Promise.all for array mode
  mock.$transaction = vi.fn(async (fnOrArray: unknown) => {
    if (typeof fnOrArray === 'function') {
      return (fnOrArray as (tx: unknown) => Promise<unknown>)(mock);
    }
    return Promise.all(fnOrArray as Promise<unknown>[]);
  });

  return mock as unknown as PrismaClient;
}

/**
 * Build a minimal Context object for guard tests.
 * Pass { user: null } for unauthenticated scenarios.
 */
export function buildContext(overrides?: {
  user?: Partial<UserContext> | null;
  prisma?: PrismaClient;
}): Context {
  const prisma = overrides?.prisma ?? createPrismaMock();

  return {
    prisma,
    req: {} as Context['req'],
    res: {} as Context['res'],
    user:
      overrides?.user === null
        ? undefined
        : {
            id: 'user-db-id',
            userId: 'ABC123',
            email: 'test@example.com',
            isOverseer: false,
            isAppAdmin: false,
            ...(overrides?.user ?? {}),
          },
  };
}
