/**
 * Token Service
 *
 * Manages refresh token lifecycle: creation, validation, rotation, and revocation.
 * Refresh tokens are stored in the database to enable server-side invalidation.
 *
 * Token Rotation:
 *   Each time a refresh token is used, it's revoked and a new one is issued.
 *   If a revoked token is used again (token reuse), ALL user tokens are revoked.
 *   This detects token theft and limits damage.
 *
 * Token Lifetime:
 *   - Access token: 15 minutes (stored only on client)
 *   - Refresh token: 7 days (stored in database)
 *
 * Called by: AuthService
 */
import crypto from 'crypto';
import { PrismaClient } from '@prisma/client';
import { generateTokens, verifyRefreshToken, TokenPair } from '../utils/jwt.js';

const REFRESH_TOKEN_EXPIRY_DAYS = 7;

export class TokenService {
  constructor(private prisma: PrismaClient) {}

  private hashToken(token: string): string {
    return crypto.createHash('sha256').update(token).digest('hex');
  }

  async createRefreshToken(token: string, userId: string): Promise<void> {
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + REFRESH_TOKEN_EXPIRY_DAYS);

    await this.prisma.refreshToken.create({
      data: {
        token: this.hashToken(token),
        expiresAt,
        userId,
      },
    });
  }

  async revokeRefreshToken(token: string): Promise<void> {
    await this.prisma.refreshToken.updateMany({
      where: { token: this.hashToken(token) },
      data: { revoked: true },
    });
  }

  async revokeAllUserTokens(userId: string): Promise<void> {
    await this.prisma.refreshToken.updateMany({
      where: { userId, revoked: false },
      data: { revoked: true },
    });
  }

  async deleteAllUserTokens(userId: string): Promise<void> {
    await this.prisma.refreshToken.deleteMany({ where: { userId } });
  }

  async rotateRefreshToken(
    oldToken: string,
    userId: string,
    email?: string,
    isOverseer?: boolean,
    isAppAdmin?: boolean
  ): Promise<TokenPair | null> {
    const storedToken = await this.prisma.refreshToken.findUnique({
      where: { token: this.hashToken(oldToken) },
    });

    if (!storedToken) return null;

    if (storedToken.revoked) {
      await this.revokeAllUserTokens(userId);
      return null;
    }

    if (storedToken.expiresAt < new Date()) return null;

    await this.deleteAllUserTokens(userId);

    const tokens = generateTokens({ sub: userId, type: 'user', email, isOverseer, isAppAdmin });
    await this.createRefreshToken(tokens.refreshToken, userId);

    return tokens;
  }

  async validateRefreshToken(token: string): Promise<{
    userId: string;
    userType: 'user';
  } | null> {
    try {
      const payload = verifyRefreshToken(token);

      const storedToken = await this.prisma.refreshToken.findUnique({
        where: { token: this.hashToken(token) },
      });

      if (!storedToken || storedToken.revoked || storedToken.expiresAt < new Date()) {
        return null;
      }

      return { userId: payload.sub, userType: payload.type };
    } catch {
      return null;
    }
  }

  async cleanupExpiredTokens(): Promise<number> {
    const result = await this.prisma.refreshToken.deleteMany({
      where: { OR: [{ expiresAt: { lt: new Date() } }, { revoked: true }] },
    });
    return result.count;
  }
}
