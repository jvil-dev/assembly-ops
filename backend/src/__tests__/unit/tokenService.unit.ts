/**
 * TokenService Unit Tests
 *
 * Tests the full refresh token lifecycle: creation, validation, rotation,
 * revocation, and cleanup. Prisma is mocked via createPrismaMock(). The
 * jwt module is module-mocked so no real JWT signing occurs.
 */
import { vi, describe, it, expect, beforeEach } from 'vitest';
import { createPrismaMock } from '../unitTestHelpers.js';
import { TokenService } from '../../services/tokenService.js';

// ---------------------------------------------------------------------------
// Module mock — must be hoisted before the dynamic import of jwt below
// ---------------------------------------------------------------------------
vi.mock('../../utils/jwt.js', () => ({
  generateTokens: vi.fn().mockReturnValue({
    accessToken: 'mock-access',
    refreshToken: 'mock-refresh',
    expiresIn: 900,
  }),
  verifyRefreshToken: vi.fn(),
}));

import { generateTokens, verifyRefreshToken } from '../../utils/jwt.js';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Build a stored RefreshToken record (not revoked, not expired). */
function makeStoredToken(overrides: Partial<{
  id: string;
  token: string;
  userId: string;
  revoked: boolean;
  expiresAt: Date;
  createdAt: Date;
}> = {}) {
  const future = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days out
  return {
    id: 'token-id-1',
    token: 'hashed-token-value',
    userId: 'user-abc',
    revoked: false,
    expiresAt: future,
    createdAt: new Date(),
    ...overrides,
  };
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe('TokenService', () => {
  let prisma: ReturnType<typeof createPrismaMock>;
  let service: TokenService;

  beforeEach(() => {
    vi.clearAllMocks();
    prisma = createPrismaMock();
    service = new TokenService(prisma);
  });

  // -------------------------------------------------------------------------
  // createRefreshToken
  // -------------------------------------------------------------------------

  describe('createRefreshToken', () => {
    it('calls prisma.refreshToken.create with hashed token and userId', async () => {
      vi.mocked(prisma.refreshToken.create).mockResolvedValue(makeStoredToken());

      await service.createRefreshToken('raw-token', 'user-abc');

      expect(prisma.refreshToken.create).toHaveBeenCalledOnce();
      const { data } = vi.mocked(prisma.refreshToken.create).mock.calls[0][0] as {
        data: { token: string; userId: string; expiresAt: Date };
      };
      // Token must be SHA-256 hashed (64 hex chars), not the raw value
      expect(data.token).toMatch(/^[a-f0-9]{64}$/);
      expect(data.token).not.toBe('raw-token');
      expect(data.userId).toBe('user-abc');
    });

    it('stores an expiry ~7 days in the future', async () => {
      vi.mocked(prisma.refreshToken.create).mockResolvedValue(makeStoredToken());

      const before = new Date();
      await service.createRefreshToken('raw-token', 'user-abc');
      const after = new Date();

      const { data } = vi.mocked(prisma.refreshToken.create).mock.calls[0][0] as {
        data: { expiresAt: Date };
      };
      const sixDaysMs = 6 * 24 * 60 * 60 * 1000;
      const eightDaysMs = 8 * 24 * 60 * 60 * 1000;
      expect(data.expiresAt.getTime()).toBeGreaterThan(before.getTime() + sixDaysMs);
      expect(data.expiresAt.getTime()).toBeLessThan(after.getTime() + eightDaysMs);
    });

    it('hashes the same raw token consistently', async () => {
      vi.mocked(prisma.refreshToken.create).mockResolvedValue(makeStoredToken());

      await service.createRefreshToken('my-token', 'user-abc');
      const call1 = (vi.mocked(prisma.refreshToken.create).mock.calls[0][0] as { data: { token: string } }).data.token;

      vi.clearAllMocks();
      vi.mocked(prisma.refreshToken.create).mockResolvedValue(makeStoredToken());

      await service.createRefreshToken('my-token', 'user-abc');
      const call2 = (vi.mocked(prisma.refreshToken.create).mock.calls[0][0] as { data: { token: string } }).data.token;

      expect(call1).toBe(call2);
    });
  });

  // -------------------------------------------------------------------------
  // revokeRefreshToken
  // -------------------------------------------------------------------------

  describe('revokeRefreshToken', () => {
    it('calls updateMany with the hashed token and sets revoked=true', async () => {
      vi.mocked(prisma.refreshToken.updateMany).mockResolvedValue({ count: 1 });

      await service.revokeRefreshToken('raw-token');

      expect(prisma.refreshToken.updateMany).toHaveBeenCalledOnce();
      const args = vi.mocked(prisma.refreshToken.updateMany).mock.calls[0][0] as {
        where: { token: string };
        data: { revoked: boolean };
      };
      expect(args.where.token).toMatch(/^[a-f0-9]{64}$/);
      expect(args.data.revoked).toBe(true);
    });
  });

  // -------------------------------------------------------------------------
  // revokeAllUserTokens
  // -------------------------------------------------------------------------

  describe('revokeAllUserTokens', () => {
    it('calls updateMany filtering by userId and revoked=false', async () => {
      vi.mocked(prisma.refreshToken.updateMany).mockResolvedValue({ count: 3 });

      await service.revokeAllUserTokens('user-abc');

      expect(prisma.refreshToken.updateMany).toHaveBeenCalledOnce();
      const args = vi.mocked(prisma.refreshToken.updateMany).mock.calls[0][0] as {
        where: { userId: string; revoked: boolean };
        data: { revoked: boolean };
      };
      expect(args.where.userId).toBe('user-abc');
      expect(args.where.revoked).toBe(false);
      expect(args.data.revoked).toBe(true);
    });
  });

  // -------------------------------------------------------------------------
  // deleteAllUserTokens
  // -------------------------------------------------------------------------

  describe('deleteAllUserTokens', () => {
    it('calls deleteMany filtering only by userId', async () => {
      vi.mocked(prisma.refreshToken.deleteMany).mockResolvedValue({ count: 2 });

      await service.deleteAllUserTokens('user-abc');

      expect(prisma.refreshToken.deleteMany).toHaveBeenCalledOnce();
      const args = vi.mocked(prisma.refreshToken.deleteMany).mock.calls[0][0] as {
        where: { userId: string };
      };
      expect(args.where.userId).toBe('user-abc');
    });
  });

  // -------------------------------------------------------------------------
  // rotateRefreshToken
  // -------------------------------------------------------------------------

  describe('rotateRefreshToken', () => {
    it('returns null when the token is not found in the DB', async () => {
      vi.mocked(prisma.refreshToken.findUnique).mockResolvedValue(null);

      const result = await service.rotateRefreshToken('old-token', 'user-abc');

      expect(result).toBeNull();
      expect(prisma.refreshToken.deleteMany).not.toHaveBeenCalled();
      expect(generateTokens).not.toHaveBeenCalled();
    });

    it('returns null and revokes all tokens when the token is already revoked (reuse detection)', async () => {
      vi.mocked(prisma.refreshToken.findUnique).mockResolvedValue(
        makeStoredToken({ revoked: true })
      );
      vi.mocked(prisma.refreshToken.updateMany).mockResolvedValue({ count: 1 });

      const result = await service.rotateRefreshToken('old-token', 'user-abc');

      expect(result).toBeNull();
      // revokeAllUserTokens must be called to limit damage from token theft
      expect(prisma.refreshToken.updateMany).toHaveBeenCalledOnce();
      const args = vi.mocked(prisma.refreshToken.updateMany).mock.calls[0][0] as {
        where: { userId: string; revoked: boolean };
      };
      expect(args.where.userId).toBe('user-abc');
      expect(args.where.revoked).toBe(false);
      expect(generateTokens).not.toHaveBeenCalled();
    });

    it('returns null when the token is expired (past expiresAt)', async () => {
      const expired = new Date(Date.now() - 1000); // 1 second in the past
      vi.mocked(prisma.refreshToken.findUnique).mockResolvedValue(
        makeStoredToken({ expiresAt: expired })
      );

      const result = await service.rotateRefreshToken('old-token', 'user-abc');

      expect(result).toBeNull();
      expect(generateTokens).not.toHaveBeenCalled();
    });

    it('happy path: deletes all old tokens, generates a new pair, stores it, and returns it', async () => {
      vi.mocked(prisma.refreshToken.findUnique).mockResolvedValue(makeStoredToken());
      vi.mocked(prisma.refreshToken.deleteMany).mockResolvedValue({ count: 1 });
      vi.mocked(prisma.refreshToken.create).mockResolvedValue(makeStoredToken());

      const result = await service.rotateRefreshToken(
        'old-token',
        'user-abc',
        'test@example.com',
        true,
        false
      );

      expect(result).toEqual({
        accessToken: 'mock-access',
        refreshToken: 'mock-refresh',
        expiresIn: 900,
      });

      // Old tokens must be wiped first
      expect(prisma.refreshToken.deleteMany).toHaveBeenCalledOnce();
      const deleteArgs = vi.mocked(prisma.refreshToken.deleteMany).mock.calls[0][0] as {
        where: { userId: string };
      };
      expect(deleteArgs.where.userId).toBe('user-abc');

      // generateTokens called with correct payload
      expect(generateTokens).toHaveBeenCalledOnce();
      expect(generateTokens).toHaveBeenCalledWith({
        sub: 'user-abc',
        type: 'user',
        email: 'test@example.com',
        isOverseer: true,
        isAppAdmin: false,
      });

      // New refresh token stored in DB
      expect(prisma.refreshToken.create).toHaveBeenCalledOnce();
      const createArgs = vi.mocked(prisma.refreshToken.create).mock.calls[0][0] as {
        data: { token: string; userId: string; expiresAt: Date };
      };
      expect(createArgs.data.userId).toBe('user-abc');
      // The stored token must be the hash of 'mock-refresh', not the raw value
      expect(createArgs.data.token).toMatch(/^[a-f0-9]{64}$/);
      expect(createArgs.data.token).not.toBe('mock-refresh');
    });

    it('happy path: works without optional email/isOverseer/isAppAdmin args', async () => {
      vi.mocked(prisma.refreshToken.findUnique).mockResolvedValue(makeStoredToken());
      vi.mocked(prisma.refreshToken.deleteMany).mockResolvedValue({ count: 1 });
      vi.mocked(prisma.refreshToken.create).mockResolvedValue(makeStoredToken());

      const result = await service.rotateRefreshToken('old-token', 'user-abc');

      expect(result).not.toBeNull();
      expect(generateTokens).toHaveBeenCalledWith({
        sub: 'user-abc',
        type: 'user',
        email: undefined,
        isOverseer: undefined,
        isAppAdmin: undefined,
      });
    });
  });

  // -------------------------------------------------------------------------
  // validateRefreshToken
  // -------------------------------------------------------------------------

  describe('validateRefreshToken', () => {
    it('returns null when verifyRefreshToken throws (invalid/expired JWT)', async () => {
      vi.mocked(verifyRefreshToken).mockImplementation(() => {
        throw new Error('invalid signature');
      });

      const result = await service.validateRefreshToken('bad-token');

      expect(result).toBeNull();
      expect(prisma.refreshToken.findUnique).not.toHaveBeenCalled();
    });

    it('returns null when no DB record is found for the token hash', async () => {
      vi.mocked(verifyRefreshToken).mockReturnValue({ sub: 'user-abc', type: 'user' });
      vi.mocked(prisma.refreshToken.findUnique).mockResolvedValue(null);

      const result = await service.validateRefreshToken('valid-jwt');

      expect(result).toBeNull();
    });

    it('returns null when the stored token is revoked', async () => {
      vi.mocked(verifyRefreshToken).mockReturnValue({ sub: 'user-abc', type: 'user' });
      vi.mocked(prisma.refreshToken.findUnique).mockResolvedValue(
        makeStoredToken({ revoked: true })
      );

      const result = await service.validateRefreshToken('valid-jwt');

      expect(result).toBeNull();
    });

    it('returns null when the stored token is expired', async () => {
      vi.mocked(verifyRefreshToken).mockReturnValue({ sub: 'user-abc', type: 'user' });
      const expired = new Date(Date.now() - 1000);
      vi.mocked(prisma.refreshToken.findUnique).mockResolvedValue(
        makeStoredToken({ expiresAt: expired })
      );

      const result = await service.validateRefreshToken('valid-jwt');

      expect(result).toBeNull();
    });

    it('happy path: returns { userId, userType: "user" } for a valid, active token', async () => {
      vi.mocked(verifyRefreshToken).mockReturnValue({ sub: 'user-abc', type: 'user' });
      vi.mocked(prisma.refreshToken.findUnique).mockResolvedValue(makeStoredToken());

      const result = await service.validateRefreshToken('valid-jwt');

      expect(result).toEqual({ userId: 'user-abc', userType: 'user' });
    });

    it('looks up the DB record using the hash of the raw token, not the raw value', async () => {
      vi.mocked(verifyRefreshToken).mockReturnValue({ sub: 'user-abc', type: 'user' });
      vi.mocked(prisma.refreshToken.findUnique).mockResolvedValue(makeStoredToken());

      await service.validateRefreshToken('raw-token-value');

      const args = vi.mocked(prisma.refreshToken.findUnique).mock.calls[0][0] as {
        where: { token: string };
      };
      expect(args.where.token).toMatch(/^[a-f0-9]{64}$/);
      expect(args.where.token).not.toBe('raw-token-value');
    });
  });

  // -------------------------------------------------------------------------
  // cleanupExpiredTokens
  // -------------------------------------------------------------------------

  describe('cleanupExpiredTokens', () => {
    it('deletes records that are expired OR revoked and returns the deleted count', async () => {
      vi.mocked(prisma.refreshToken.deleteMany).mockResolvedValue({ count: 5 });

      const count = await service.cleanupExpiredTokens();

      expect(count).toBe(5);
      expect(prisma.refreshToken.deleteMany).toHaveBeenCalledOnce();
      const args = vi.mocked(prisma.refreshToken.deleteMany).mock.calls[0][0] as {
        where: { OR: unknown[] };
      };
      expect(args.where.OR).toHaveLength(2);
    });

    it('returns 0 when there is nothing to clean up', async () => {
      vi.mocked(prisma.refreshToken.deleteMany).mockResolvedValue({ count: 0 });

      const count = await service.cleanupExpiredTokens();

      expect(count).toBe(0);
    });
  });
});
