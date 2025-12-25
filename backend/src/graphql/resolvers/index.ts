import { DateTimeResolver } from 'graphql-scalars';
import { Context } from '../context.js';
import authResolvers from './auth.js';

const baseResolvers = {
  DateTime: DateTimeResolver,

  Query: {
    health: async (_parent: unknown, _args: unknown, { prisma }: Context) => {
      try {
        await prisma.$queryRaw`SELECT 1`;
        return {
          status: 'healthy',
          timestamp: new Date(),
          database: 'connected',
        };
      } catch {
        return {
          status: 'unhealthy',
          timestamp: new Date(),
          database: 'disconnected',
        };
      }
    },
  },

  Mutation: {
    _empty: (): null => null,
  },
};

const resolvers = {
  DateTime: baseResolvers.DateTime,

  Query: {
    ...baseResolvers.Query,
    ...authResolvers.Query,
  },

  Mutation: {
    ...baseResolvers.Mutation,
    ...authResolvers.Mutation,
  },

  Admin: authResolvers.Admin,
};

export default resolvers;
