import { PrismaClient } from '@prisma/client';
import { generateTokens, verifyRefreshToken, TokenPair } from '../utils/jwt.js';

const REFRESH_TOKEN_EXPIRY_DAYS = 7;

export class TokenService {
  constructor(private prisma: PrismaClient) {}

  async createRefreshToken(
    token: string,
    userId: string,
    userType: 'admin' | 'volunteer'
  ): Promise<void> {
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + REFRESH_TOKEN_EXPIRY_DAYS);

    await this.prisma.refreshToken.create({
      data: {
        token,
        expiresAt,
        adminId: userType === 'admin' ? userId : null,
        volunteerId: userType === 'volunteer' ? userId : null,
      },
    });
  }

  async revokeRefreshToken(token: string): Promise<void> {
    await this.prisma.refreshToken.updateMany({
      where: { token },
      data: { revoked: true },
    });
  }

  async revokeAllUserTokens(userId: string, userType: 'admin' | 'volunteer'): Promise<void> {
    const where =
      userType === 'admin'
        ? { adminId: userId, revoked: false }
        : { volunteerId: userId, revoked: false };

    await this.prisma.refreshToken.updateMany({
      where,
      data: { revoked: true },
    });
  }

  async rotateRefreshToken(
    oldToken: string,
    userId: string,
    userType: 'admin' | 'volunteer',
    email?: string
  ): Promise<TokenPair | null> {
    const storedToken = await this.prisma.refreshToken.findUnique({
      where: { token: oldToken },
    });

    if (!storedToken) {
      return null;
    }

    if (storedToken.revoked) {
      // Token reuse detected - revoke all user tokens
      await this.revokeAllUserTokens(userId, userType);
      return null;
    }

    if (storedToken.expiresAt < new Date()) {
      return null;
    }

    // Revoke old token
    await this.revokeRefreshToken(oldToken);

    // Generate new tokens
    const tokens = generateTokens({
      sub: userId,
      type: userType,
      email,
    });

    // Store new refresh token
    await this.createRefreshToken(tokens.refreshToken, userId, userType);

    return tokens;
  }

  async validateRefreshToken(token: string): Promise<{
    userId: string;
    userType: 'admin' | 'volunteer';
  } | null> {
    try {
      const payload = verifyRefreshToken(token);

      const storedToken = await this.prisma.refreshToken.findUnique({
        where: { token },
      });

      if (!storedToken || storedToken.revoked || storedToken.expiresAt < new Date()) {
        return null;
      }

      return {
        userId: payload.sub,
        userType: payload.type,
      };
    } catch {
      return null;
    }
  }

  async cleanupExpiredTokens(): Promise<number> {
    const result = await this.prisma.refreshToken.deleteMany({
      where: {
        OR: [{ expiresAt: { lt: new Date() } }, { revoked: true }],
      },
    });
    return result.count;
  }
}
