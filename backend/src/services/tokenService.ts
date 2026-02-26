/**
 * Token Service
 *
 * Manages refresh token lifecycle: creation, validation, rotation, and revocation.
 * Refresh tokens are stored in the database to enable server-side invalidation.
 *
 * Token Types:
 *   - 'user': All registered users (volunteers and overseers) — stored via userId FK
 *   - 'eventVolunteer': Printed-card event-day credentials — stored via eventVolunteerId FK
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

  async createRefreshToken(
    token: string,
    userId: string,
    userType: 'user' | 'eventVolunteer'
  ): Promise<void> {
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + REFRESH_TOKEN_EXPIRY_DAYS);

    await this.prisma.refreshToken.create({
      data: {
        token: this.hashToken(token),
        expiresAt,
        userId: userType === 'user' ? userId : null,
        eventVolunteerId: userType === 'eventVolunteer' ? userId : null,
      },
    });
  }

  async revokeRefreshToken(token: string): Promise<void> {
    await this.prisma.refreshToken.updateMany({
      where: { token: this.hashToken(token) },
      data: { revoked: true },
    });
  }

  async revokeAllUserTokens(userId: string, userType: 'user' | 'eventVolunteer'): Promise<void> {
    const where =
      userType === 'user'
        ? { userId, revoked: false }
        : { eventVolunteerId: userId, revoked: false };

    await this.prisma.refreshToken.updateMany({ where, data: { revoked: true } });
  }

  async deleteAllUserTokens(userId: string, userType: 'user' | 'eventVolunteer'): Promise<void> {
    const where =
      userType === 'user' ? { userId } : { eventVolunteerId: userId };

    await this.prisma.refreshToken.deleteMany({ where });
  }

  async rotateRefreshToken(
    oldToken: string,
    userId: string,
    userType: 'user' | 'eventVolunteer',
    email?: string,
    isOverseer?: boolean
  ): Promise<TokenPair | null> {
    const storedToken = await this.prisma.refreshToken.findUnique({
      where: { token: this.hashToken(oldToken) },
    });

    if (!storedToken) return null;

    if (storedToken.revoked) {
      await this.revokeAllUserTokens(userId, userType);
      return null;
    }

    if (storedToken.expiresAt < new Date()) return null;

    await this.deleteAllUserTokens(userId, userType);

    const tokens = generateTokens({ sub: userId, type: userType, email, isOverseer });
    await this.createRefreshToken(tokens.refreshToken, userId, userType);

    return tokens;
  }

  async validateRefreshToken(token: string): Promise<{
    userId: string;
    userType: 'user' | 'eventVolunteer';
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
