import { Context } from '../context.js';
import { OAuthService } from '../../services/oauthService.js';

export const oauthResolvers = {
  Mutation: {
    loginWithGoogle: async (
      _: unknown,
      { input }: { input: { idToken: string } },
      context: Context
    ) => {
      const service = new OAuthService(context.prisma);
      const result = await service.loginWithGoogle(input.idToken);
      return {
        admin: result.admin || null,
        accessToken: result.tokens?.accessToken || null,
        refreshToken: result.tokens?.refreshToken || null,
        expiresIn: result.tokens?.expiresIn || null,
        isNewUser: result.isNewUser,
        pendingOAuthToken: result.pendingOAuthToken || null,
        email: result.email,
        firstName: result.firstName || null,
        lastName: result.lastName || null,
      };
    },

    loginWithApple: async (
      _: unknown,
      {
        input,
      }: {
        input: {
          identityToken: string;
          firstName?: string;
          lastName?: string;
        };
      },
      context: Context
    ) => {
      const service = new OAuthService(context.prisma);
      const result = await service.loginWithApple(
        input.identityToken,
        input.firstName,
        input.lastName
      );
      return {
        admin: result.admin || null,
        accessToken: result.tokens?.accessToken || null,
        refreshToken: result.tokens?.refreshToken || null,
        expiresIn: result.tokens?.expiresIn || null,
        isNewUser: result.isNewUser,
        pendingOAuthToken: result.pendingOAuthToken || null,
        email: result.email,
        firstName: result.firstName || null,
        lastName: result.lastName || null,
      };
    },

    completeOAuthRegistration: async (
      _: unknown,
      {
        input,
      }: {
        input: {
          pendingOAuthToken: string;
          firstName: string;
          lastName: string;
          phone?: string;
          congregation: string;
        };
      },
      context: Context
    ) => {
      const service = new OAuthService(context.prisma);
      const result = await service.completeOAuthRegistration(input);
      return {
        admin: result.admin,
        accessToken: result.tokens.accessToken,
        refreshToken: result.tokens.refreshToken,
        expiresIn: result.tokens.expiresIn,
      };
    },
  },
};
