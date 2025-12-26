/**
 * Auth Resolvers
 *
 * Handles admin authentication: register, login, logout, token refresh.
 *
 * Queries:
 *   - me: Returns the currently logged-in admin, or null if not authenticated
 *
 * Mutations:
 *   - registerAdmin: Creates a new admin account, returns tokens
 *   - loginAdmin: Authenticates with email/password, returns tokens
 *   - refreshToken: Exchanges refresh token for new access token
 *   - logoutAdmin: Invalidates a specific refresh token
 *   - logoutAllSessions: Invalidates ALL refresh tokens for this admin
 *
 * Type Resolvers (Admin):
 *   - fullName: Computed field (firstName + lastName)
 *   - eventRoles: Fetches all EventAdmin records for this admin
 *
 * Dependencies:
 *   - AuthService (../../services/authService.ts): Business logic for auth
 *   - Guards (../guards/auth.ts): Authorization checks
 *
 * Schema: ../schema/auth.ts
 */
import { Context } from '../context.js';
import { AuthService } from '../../services/authService.js';
import { AuthenticationError } from '../../utils/errors.js';
import { requireAdmin } from '../guards/auth.js';
import { Admin, EventAdmin } from '@prisma/client';

export interface RegisterInput {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  phone?: string | null;
  congregation: string;
}

export interface LoginInput {
  email: string;
  password: string;
}

export interface RefreshInput {
  refreshToken: string;
}

const authResolvers = {
  Query: {
    me: async (
      _parent: unknown,
      _args: unknown,
      context: Context
    ): Promise<Admin | null> => {
      if (!context.admin) {
        return null;
      }

      return context.prisma.admin.findUnique({
        where: { id: context.admin.id },
      });
    },
  },

  Mutation: {
    registerAdmin: async (
      _parent: unknown,
      { input }: { input: RegisterInput },
      context: Context
    ) => {
      const authService = new AuthService(context.prisma);
      const result = await authService.registerAdmin({
        ...input,
        phone: input.phone ?? null,
      });

      return {
        admin: result.admin,
        accessToken: result.tokens.accessToken,
        refreshToken: result.tokens.refreshToken,
        expiresIn: result.tokens.expiresIn,
      };
    },

    loginAdmin: async (
      _parent: unknown,
      { input }: { input: LoginInput },
      context: Context
    ) => {
      const authService = new AuthService(context.prisma);
      const result = await authService.loginAdmin(input);

      return {
        admin: result.admin,
        accessToken: result.tokens.accessToken,
        refreshToken: result.tokens.refreshToken,
        expiresIn: result.tokens.expiresIn,
      };
    },

    refreshToken: async (
      _parent: unknown,
      { input }: { input: RefreshInput },
      context: Context
    ) => {
      const authService = new AuthService(context.prisma);
      const tokens = await authService.refreshToken(input.refreshToken);

      if (!tokens) {
        throw new AuthenticationError('Invalid or expired refresh token');
      }

      return {
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        expiresIn: tokens.expiresIn,
      };
    },

    logoutAdmin: async (
      _parent: unknown,
      { refreshToken }: { refreshToken: string },
      context: Context
    ) => {
      const authService = new AuthService(context.prisma);
      await authService.logout(refreshToken);

      return { success: true };
    },

    logoutAllSessions: async (
      _parent: unknown,
      _args: unknown,
      context: Context
    ) => {
      requireAdmin(context);

      const authService = new AuthService(context.prisma);
      await authService.logoutAll(context.admin.id, 'admin');

      return { success: true };
    },
  },

  Admin: {
    fullName: (admin: Admin): string => {
      return `${admin.firstName} ${admin.lastName}`;
    },

    eventRoles: async (
      admin: Admin,
      _args: unknown,
      context: Context
    ): Promise<EventAdmin[]> => {
      return context.prisma.eventAdmin.findMany({
        where: { adminId: admin.id },
      });
    },
  },
};

export default authResolvers;
