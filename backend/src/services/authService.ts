/**
 * Auth Service
 *
 * Business logic for admin authentication. Handles registration, login, logout,
 * and token refresh operations.
 *
 * Methods:
 *   - registerAdmin(input): Create new admin account, returns admin + tokens
 *   - loginAdmin(input): Authenticate with email/password, returns admin + tokens
 *   - refreshToken(token): Exchange refresh token for new access token
 *   - logout(token): Invalidate a specific refresh token
 *   - logoutAll(userId, userType): Invalidate ALL refresh tokens for a user
 *
 * Flow:
 *   1. Resolver receives GraphQL request
 *   2. Resolver calls AuthService method
 *   3. AuthService validates input with Zod schemas
 *   4. AuthService performs database operations
 *   5. AuthService calls TokenService for token management
 *   6. Result returned to resolver → client
 *
 * Security:
 *   - Passwords hashed with bcrypt before storage
 *   - Refresh tokens stored in database for validation/revocation
 *   - Generic error messages for auth failures (prevent user enumeration)
 *
 * Dependencies:
 *   - TokenService: Manages refresh token storage/validation
 *   - utils/password.ts: Password hashing and verification
 *   - utils/jwt.ts: Token generation
 *   - validators/auth.ts: Input validation schemas
 *
 * Called by: ../graphql/resolvers/auth.ts
 */
import { PrismaClient } from '@prisma/client';
import { hashPassword, verifyPassword } from '../utils/password.js';
import { generateTokens, TokenPair } from '../utils/jwt.js';
import { TokenService } from './tokenService.js';
import { AuthenticationError, ConflictError, ValidationError } from '../utils/errors.js';
import {
  registerAdminSchema,
  loginAdminSchema,
  RegisterAdminInput,
  LoginAdminInput,
} from '../graphql/validators/auth.js';
import { verifyToken } from '../utils/credentials.js';

export class AuthService {
  private tokenService: TokenService;

  constructor(private prisma: PrismaClient) {
    this.tokenService = new TokenService(prisma);
  }

  async registerAdmin(input: RegisterAdminInput): Promise<{
    admin: { id: string; email: string; firstName: string; lastName: string };
    tokens: TokenPair;
  }> {
    // Validate input
    const result = registerAdminSchema.safeParse(input);
    if (!result.success) {
      const firstError = result.error.issues[0];
      throw new ValidationError(firstError.message);
    }
    const validated = result.data;

    // Check if email already exists
    const existingAdmin = await this.prisma.admin.findUnique({
      where: { email: validated.email },
    });

    if (existingAdmin) {
      throw new ConflictError('An account with this email already exists');
    }

    // Hash password
    const passwordHash = await hashPassword(validated.password);

    // Create admin
    const admin = await this.prisma.admin.create({
      data: {
        email: validated.email,
        passwordHash,
        firstName: validated.firstName,
        lastName: validated.lastName,
      },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
      },
    });

    // Generate tokens
    const tokens = generateTokens({
      sub: admin.id,
      type: 'admin',
      email: admin.email,
    });

    // Store refresh token
    await this.tokenService.createRefreshToken(tokens.refreshToken, admin.id, 'admin');

    return { admin, tokens };
  }

  async loginAdmin(input: LoginAdminInput): Promise<{
    admin: { id: string; email: string; firstName: string; lastName: string };
    tokens: TokenPair;
  }> {
    // Validate input
    const result = loginAdminSchema.safeParse(input);
    if (!result.success) {
      const firstError = result.error.issues[0];
      throw new ValidationError(firstError.message);
    }
    const validated = result.data;

    // Find admin
    const admin = await this.prisma.admin.findUnique({
      where: { email: validated.email },
    });

    if (!admin) {
      throw new AuthenticationError('Invalid email or password');
    }

    // Verify password (passwordHash can be null for OAuth-only accounts)
    if (!admin.passwordHash) {
      throw new AuthenticationError('Invalid email or password');
    }
    const isValid = await verifyPassword(validated.password, admin.passwordHash);
    if (!isValid) {
      throw new AuthenticationError('Invalid email or password');
    }

    // Delete any existing tokens for this admin (prevents collision on quick re-login)
    await this.tokenService.deleteAllUserTokens(admin.id, 'admin');

    // Generate tokens
    const tokens = generateTokens({
      sub: admin.id,
      type: 'admin',
      email: admin.email,
    });

    // Store refresh token
    await this.tokenService.createRefreshToken(tokens.refreshToken, admin.id, 'admin');

    return {
      admin: {
        id: admin.id,
        email: admin.email,
        firstName: admin.firstName,
        lastName: admin.lastName,
      },
      tokens,
    };
  }

  async refreshToken(refreshToken: string): Promise<TokenPair | null> {
    const validation = await this.tokenService.validateRefreshToken(refreshToken);
    if (!validation) {
      return null;
    }

    let email: string | undefined;
    if (validation.userType === 'admin') {
      const admin = await this.prisma.admin.findUnique({
        where: { id: validation.userId },
        select: { email: true },
      });
      email = admin?.email;
    }

    return this.tokenService.rotateRefreshToken(
      refreshToken,
      validation.userId,
      validation.userType,
      email
    );
  }

  async logout(refreshToken: string): Promise<boolean> {
    await this.tokenService.revokeRefreshToken(refreshToken);
    return true;
  }

  async logoutAll(userId: string, userType: 'admin' | 'volunteer' | 'eventVolunteer'): Promise<boolean> {
    await this.tokenService.revokeAllUserTokens(userId, userType);
    return true;
  }

  /**
   * Update an admin's profile (patch-style: only provided fields are updated)
   */
  async updateProfile(
    adminId: string,
    input: {
      firstName?: string | null;
      lastName?: string | null;
      phone?: string | null;
      congregationId?: string | null;
    }
  ) {
    const data: Record<string, unknown> = {};

    if (input.firstName !== undefined && input.firstName !== null) {
      data.firstName = input.firstName;
    }
    if (input.lastName !== undefined && input.lastName !== null) {
      data.lastName = input.lastName;
    }
    if (input.phone !== undefined) {
      data.phone = input.phone;
    }
    if (input.congregationId !== undefined && input.congregationId !== null) {
      // Look up congregation to also update the backward-compat string field
      const congregation = await this.prisma.congregation.findUnique({
        where: { id: input.congregationId },
        select: { name: true, city: true },
      });
      if (!congregation) {
        throw new ValidationError('Congregation not found');
      }
      data.congregationId = input.congregationId;
      data.congregation = `${congregation.name} - ${congregation.city}`;
    }

    return this.prisma.admin.update({
      where: { id: adminId },
      data,
    });
  }

  /**
   * Login an EventVolunteer using their volunteer ID (CA-XXXXXX or RC-XXXXXX) and token
   */
  async loginEventVolunteer(volunteerId: string, token: string): Promise<{
    eventVolunteer: {
      id: string;
      volunteerId: string;
      volunteerProfile: {
        id: string;
        firstName: string;
        lastName: string;
      };
      event: {
        id: string;
        template: {
          name: string;
        };
      };
      department: { id: string; name: string } | null;
    };
    tokens: TokenPair;
  }> {
    // Find event volunteer by ID
    const eventVolunteer = await this.prisma.eventVolunteer.findUnique({
      where: { volunteerId },
      include: {
        volunteerProfile: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
          },
        },
        event: {
          include: {
            template: {
              select: { name: true },
            },
          },
        },
        department: {
          select: { id: true, name: true },
        },
      },
    });

    if (!eventVolunteer) {
      throw new AuthenticationError('Invalid volunteer ID or token');
    }

    // Verify token against hash
    const isValid = await verifyToken(token, eventVolunteer.tokenHash);

    if (!isValid) {
      throw new AuthenticationError('Invalid volunteer ID or token');
    }

    // Delete any existing tokens for this event volunteer
    await this.tokenService.deleteAllUserTokens(eventVolunteer.id, 'eventVolunteer');

    // Generate JWT tokens
    const tokens = generateTokens({
      sub: eventVolunteer.id,
      type: 'eventVolunteer',
    });

    // Store refresh token
    await this.tokenService.createRefreshToken(tokens.refreshToken, eventVolunteer.id, 'eventVolunteer');

    return {
      eventVolunteer: {
        id: eventVolunteer.id,
        volunteerId: eventVolunteer.volunteerId,
        volunteerProfile: eventVolunteer.volunteerProfile,
        event: eventVolunteer.event,
        department: eventVolunteer.department,
      },
      tokens,
    };
  }
}
