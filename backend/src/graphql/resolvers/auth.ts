/**
 * Auth Resolvers
 *
 * Handles unified user authentication: register, login, logout, token refresh.
 * All users (overseers and volunteers) share the same auth flow.
 *
 * Queries:
 *   - me: Returns the currently logged-in user, or null if not authenticated
 *
 * Mutations:
 *   - registerUser: Creates a new user account, returns tokens
 *   - loginUser: Authenticates with email/password, returns tokens
 *   - refreshToken: Exchanges refresh token for new access token
 *   - logoutUser: Invalidates a specific refresh token
 *   - logoutAllSessions: Invalidates ALL refresh tokens for this user
 *   - updateUserProfile: Update profile fields
 *   - setOverseerMode: Toggle isOverseer flag
 *
 * Type Resolvers (User):
 *   - fullName: Computed field (firstName + lastName)
 *   - eventRoles: Fetches all EventAdmin records for this user
 *
 * Schema: ../schema/auth.ts
 */
import { Context } from '../context.js';
import { AuthService } from '../../services/authService.js';
import { AuthenticationError } from '../../utils/errors.js';
import { requireUser } from '../guards/auth.js';
import { User, EventAdmin } from '@prisma/client';
import {
  RegisterUserInput,
  LoginUserInput,
} from '../validators/auth.js';

export interface UpdateUserProfileInput {
  firstName?: string | null;
  lastName?: string | null;
  phone?: string | null;
  congregation?: string | null;
  congregationId?: string | null;
}

const authResolvers = {
  Query: {
    me: async (
      _parent: unknown,
      _args: unknown,
      context: Context
    ): Promise<User | null> => {
      if (!context.user) {
        return null;
      }

      return context.prisma.user.findUnique({
        where: { id: context.user.id },
      });
    },
  },

  Mutation: {
    registerUser: async (
      _parent: unknown,
      { input }: { input: RegisterUserInput },
      context: Context
    ) => {
      const authService = new AuthService(context.prisma);
      const result = await authService.registerUser(input);

      return {
        user: result.user,
        accessToken: result.tokens.accessToken,
        refreshToken: result.tokens.refreshToken,
        expiresIn: result.tokens.expiresIn,
      };
    },

    loginUser: async (
      _parent: unknown,
      { input }: { input: LoginUserInput },
      context: Context
    ) => {
      const authService = new AuthService(context.prisma);
      const result = await authService.loginUser(input);

      return {
        user: result.user,
        accessToken: result.tokens.accessToken,
        refreshToken: result.tokens.refreshToken,
        expiresIn: result.tokens.expiresIn,
      };
    },

    refreshToken: async (
      _parent: unknown,
      { input }: { input: { refreshToken: string } },
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

    logoutUser: async (
      _parent: unknown,
      { refreshToken }: { refreshToken: string },
      context: Context
    ) => {
      requireUser(context);
      const authService = new AuthService(context.prisma);
      await authService.logout(refreshToken);

      return { success: true };
    },

    logoutAllSessions: async (
      _parent: unknown,
      _args: unknown,
      context: Context
    ) => {
      requireUser(context);

      await context.prisma.refreshToken.updateMany({
        where: { userId: context.user!.id },
        data: { revoked: true },
      });

      return { success: true };
    },

    updateUserProfile: async (
      _parent: unknown,
      { input }: { input: UpdateUserProfileInput },
      context: Context
    ) => {
      requireUser(context);
      const authService = new AuthService(context.prisma);
      return authService.updateProfile(context.user!.id, input);
    },

    setOverseerMode: async (
      _parent: unknown,
      { isOverseer }: { isOverseer: boolean },
      context: Context
    ) => {
      requireUser(context);
      const authService = new AuthService(context.prisma);
      return authService.setOverseerMode(context.user!.id, isOverseer);
    },
  },

  User: {
    fullName: (user: User): string => {
      return `${user.firstName} ${user.lastName}`;
    },

    eventRoles: async (
      user: User,
      _args: unknown,
      context: Context
    ): Promise<EventAdmin[]> => {
      return context.prisma.eventAdmin.findMany({
        where: { userId: user.id },
      });
    },

    congregationRef: async (user: User, _args: unknown, context: Context) => {
      if (!(user as User & { congregationId?: string | null }).congregationId) return null;
      return context.prisma.congregation.findUnique({
        where: { id: (user as User & { congregationId: string }).congregationId },
      });
    },
  },
};

export default authResolvers;
