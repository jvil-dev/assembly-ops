import { DateTimeResolver } from 'graphql-scalars';
import { Context } from '../context.js';
import authResolvers from './auth.js';
import eventResolvers from './event.js';
import volunteerResolvers from './volunteer.js';

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
    ...eventResolvers.Query,
    ...volunteerResolvers.Query,
  },

  Mutation: {
    ...baseResolvers.Mutation,
    ...authResolvers.Mutation,
    ...eventResolvers.Mutation,
    ...volunteerResolvers.Mutation,
  },

  Admin: authResolvers.Admin,
  Event: eventResolvers.Event,
  EventTemplate: eventResolvers.EventTemplate,
  Department: eventResolvers.Department,
  Volunteer: volunteerResolvers.Volunteer,
};

export default resolvers;
