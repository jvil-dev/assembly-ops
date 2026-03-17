/**
 * DeleteAccount Resolver Unit Tests
 *
 * Tests the deleteAccount mutation resolver in isolation using mocked Prisma.
 * Covers: password-based users, OAuth-only users, missing password, wrong password,
 * and unauthenticated access.
 */
import { vi, describe, it, expect, beforeEach } from 'vitest';
import { createPrismaMock, buildContext } from '../unitTestHelpers.js';
import { AuthenticationError, ValidationError } from '../../utils/errors.js';

// Mock verifyPassword before importing the resolver
vi.mock('../../utils/password.js', () => ({
  hashPassword: vi.fn(),
  verifyPassword: vi.fn(),
}));

import { verifyPassword } from '../../utils/password.js';
import authResolvers from '../../graphql/resolvers/auth.js';

const deleteAccount = authResolvers.Mutation.deleteAccount;

describe('deleteAccount resolver', () => {
  let prisma: ReturnType<typeof createPrismaMock>;

  beforeEach(() => {
    vi.clearAllMocks();
    prisma = createPrismaMock();
  });

  it('throws when user is not authenticated', async () => {
    const context = buildContext({ user: null, prisma });

    await expect(
      deleteAccount({}, { password: 'pass' }, context)
    ).rejects.toThrow();
  });

  it('throws AuthenticationError when user not found in DB', async () => {
    const context = buildContext({ prisma });
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    vi.mocked(prisma.user.findUnique).mockResolvedValue(null as any);

    await expect(
      deleteAccount({}, { password: 'pass' }, context)
    ).rejects.toThrow(AuthenticationError);
  });

  it('throws ValidationError when password user provides no password', async () => {
    const context = buildContext({ prisma });
    vi.mocked(prisma.user.findUnique).mockResolvedValue({
      id: 'user-db-id',
      passwordHash: 'hashed-pw',
    } as never);

    await expect(
      deleteAccount({}, { password: null }, context)
    ).rejects.toThrow(ValidationError);
  });

  it('throws ValidationError when password is incorrect', async () => {
    const context = buildContext({ prisma });
    vi.mocked(prisma.user.findUnique).mockResolvedValue({
      id: 'user-db-id',
      passwordHash: 'hashed-pw',
    } as never);
    vi.mocked(verifyPassword).mockResolvedValue(false);

    await expect(
      deleteAccount({}, { password: 'wrong-pass' }, context)
    ).rejects.toThrow(ValidationError);

    expect(verifyPassword).toHaveBeenCalledWith('wrong-pass', 'hashed-pw');
  });

  it('deletes user and returns true when password is correct', async () => {
    const context = buildContext({ prisma });
    vi.mocked(prisma.user.findUnique).mockResolvedValue({
      id: 'user-db-id',
      passwordHash: 'hashed-pw',
    } as never);
    vi.mocked(verifyPassword).mockResolvedValue(true);
    vi.mocked(prisma.user.delete).mockResolvedValue({} as never);

    const result = await deleteAccount({}, { password: 'correct-pass' }, context);

    expect(result).toBe(true);
    expect(verifyPassword).toHaveBeenCalledWith('correct-pass', 'hashed-pw');
    expect(prisma.user.delete).toHaveBeenCalledWith({
      where: { id: 'user-db-id' },
    });
  });

  it('deletes OAuth-only user without password verification', async () => {
    const context = buildContext({ prisma });
    vi.mocked(prisma.user.findUnique).mockResolvedValue({
      id: 'user-db-id',
      passwordHash: null,
    } as never);
    vi.mocked(prisma.user.delete).mockResolvedValue({} as never);

    const result = await deleteAccount({}, { password: null }, context);

    expect(result).toBe(true);
    expect(verifyPassword).not.toHaveBeenCalled();
    expect(prisma.user.delete).toHaveBeenCalledWith({
      where: { id: 'user-db-id' },
    });
  });
});
