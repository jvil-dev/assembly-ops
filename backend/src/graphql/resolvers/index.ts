/**
 * GraphQL Resolver Composition
 *
 * This file combines all resolvers into a single object for Apollo Server.
 * Resolvers are the functions that actually execute when a query/mutation is called.
 *
 * Structure:
 *   - Query: All read operations (me, events, volunteers, etc.)
 *   - Mutation: All write operations (register, login, create, update, delete)
 *   - Type Resolvers: Computed fields on types (Admin.fullName, Event.volunteerCount)
 *
 * Flow:
 *   1. Client sends a GraphQL query/mutation
 *   2. Apollo matches it to the schema (../schema/)
 *   3. The matching resolver function here gets called
 *   4. Resolver calls guards (authorization), validators (input), and services (business logic)
 *   5. Result is returned to the client
 *
 * Type resolvers (Admin, Event, Volunteer, etc.):
 *   These resolve fields that aren't directly stored in the database.
 *   Example: Admin.fullName computes firstName + lastName
 *   Example: Event.volunteerCount counts related volunteers
 *
 * Used by: ../index.ts (Apollo Server setup)
 */
import { DateTimeResolver } from 'graphql-scalars';
import { Context } from '../context.js';
import authResolvers from './auth.js';
import eventResolvers from './event.js';
import volunteerResolvers from './volunteer.js';
import postResolvers from './post.js';
import sessionResolvers from './session.js';
import assignmentResolvers from './assignment.js';
import checkInResolvers from './checkIn.js';

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
    ...postResolvers.Query,
    ...sessionResolvers.Query,
    ...assignmentResolvers.Query,
    ...checkInResolvers.Query,
  },

  Mutation: {
    ...baseResolvers.Mutation,
    ...authResolvers.Mutation,
    ...eventResolvers.Mutation,
    ...volunteerResolvers.Mutation,
    ...postResolvers.Mutation,
    ...sessionResolvers.Mutation,
    ...assignmentResolvers.Mutation,
    ...checkInResolvers.Mutation,
  },

  Admin: authResolvers.Admin,
  Event: eventResolvers.Event,
  EventTemplate: eventResolvers.EventTemplate,
  Department: eventResolvers.Department,
  Volunteer: volunteerResolvers.Volunteer,
  Post: postResolvers.Post,
  Session: sessionResolvers.Session,
  ScheduleAssignment: assignmentResolvers.ScheduleAssignment,
};

export default resolvers;
