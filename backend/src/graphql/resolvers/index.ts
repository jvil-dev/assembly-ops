import { DateTimeResolver } from 'graphql-scalars';
import { Context } from '../context.js';

const resolvers = {
  DateTime: DateTimeResolver,

  Query: {
    health: async (_: unknown, __: unknown, { prisma }: Context) => {
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
    _empty: () => null,
  },
};

export default resolvers;
