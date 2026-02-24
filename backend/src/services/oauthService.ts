import { PrismaClient, AuthProvider } from '@prisma/client';
import { TokenService } from './tokenService.js';
import { generateTokens } from '../utils/jwt.js';
import { AuthenticationError } from '../utils/errors.js';
import { verifyGoogleToken, verifyAppleToken } from '../utils/oauthVerifiers.js';
import { generatePendingOAuthToken, verifyPendingOAuthToken } from '../utils/pendingOAuth.js';
import { encryptField } from '../utils/encryption.js';

export class OAuthService {
  private tokenService: TokenService;

  constructor(private prisma: PrismaClient) {
    this.tokenService = new TokenService(prisma);
  }

  async loginWithGoogle(idToken: string) {
    const userInfo = await verifyGoogleToken(idToken);
    return this.handleOAuthLogin(AuthProvider.GOOGLE, userInfo);
  }

  async loginWithApple(identityToken: string, firstName?: string, lastName?: string) {
    const userInfo = await verifyAppleToken(identityToken);
    if (firstName) userInfo.firstName = firstName;
    if (lastName) userInfo.lastName = lastName;
    return this.handleOAuthLogin(AuthProvider.APPLE, userInfo);
  }

  private async handleOAuthLogin(
    provider: AuthProvider,
    userInfo: { providerId: string; email: string; firstName?: string; lastName?: string }
  ) {
    const connection = await this.prisma.oAuthConnection.findUnique({
      where: {
        provider_providerId: {
          provider,
          providerId: userInfo.providerId,
        },
      },
      include: { admin: true },
    });

    if (connection) {
      // Existing user
      const tokens = await this.issueTokens(connection.admin);
      return { admin: connection.admin, tokens, isNewUser: false, email: userInfo.email };
    }

    // Check if email matches existing admin
    const existingAdmin = await this.prisma.admin.findUnique({ where: { email: userInfo.email } });

    if (existingAdmin) {
      // Autolink OAuth to existing account
      await this.prisma.oAuthConnection.create({
        data: {
          provider,
          providerId: userInfo.providerId,
          encryptedEmail: encryptField(userInfo.email),
          adminId: existingAdmin.id,
        },
      });
      const tokens = await this.issueTokens(existingAdmin);
      return { admin: existingAdmin, tokens, isNewUser: false, email: userInfo.email };
    }

    // New user - return pending token
    const pendingOAuthToken = generatePendingOAuthToken({
      provider,
      providerId: userInfo.providerId,
      email: userInfo.email,
    });
    return {
      isNewUser: true,
      pendingOAuthToken,
      email: userInfo.email,
      firstName: userInfo.firstName,
      lastName: userInfo.lastName,
    };
  }

  async completeOAuthRegistration(input: {
    pendingOAuthToken: string;
    firstName: string;
    lastName: string;
  }) {
    const pending = verifyPendingOAuthToken(input.pendingOAuthToken);
    if (!pending) throw new AuthenticationError('Invalid or expired registration token');

    const admin = await this.prisma.$transaction(async (tx) => {
      const newAdmin = await tx.admin.create({
        data: {
          email: pending.email,
          passwordHash: null,
          firstName: input.firstName,
          lastName: input.lastName,
        },
      });
      await tx.oAuthConnection.create({
        data: {
          provider: pending.provider,
          providerId: pending.providerId,
          encryptedEmail: encryptField(pending.email),
          adminId: newAdmin.id,
        },
      });
      return newAdmin;
    });

    const tokens = await this.issueTokens(admin);
    return { admin, tokens };
  }

  private async issueTokens(admin: { id: string; email: string }) {
    await this.tokenService.deleteAllUserTokens(admin.id, 'admin');
    const tokens = generateTokens({ sub: admin.id, type: 'admin', email: admin.email });
    await this.tokenService.createRefreshToken(tokens.refreshToken, admin.id, 'admin');
    return tokens;
  }
}
