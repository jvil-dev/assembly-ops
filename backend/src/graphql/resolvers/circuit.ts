/**
 * Circuit Resolvers
 *
 * Handles circuit queries for the event catalog and congregation organization.
 *
 * Queries:
 *   - circuits: Get all circuits (optionally filtered by region/language)
 *   - circuit: Get a single circuit by ID
 *   - circuitByCode: Get a circuit by its code (e.g., "MA-6-A-S")
 *
 * Type Resolvers:
 *   - Circuit.congregations: Get all congregations in this circuit
 *   - Circuit.eventTemplates: Get all event templates for this circuit
 *
 * Schema: ../schema/circuit.ts
 */
import { Context } from '../context.js';
import { Circuit } from '@prisma/client';
import { requireAuth } from '../guards/auth.js';

const circuitResolvers = {
  Query: {
    circuits: async (
      _parent: unknown,
      args: { region?: string; language?: string },
      context: Context
    ): Promise<Circuit[]> => {
      requireAuth(context);
      return context.prisma.circuit.findMany({
        where: {
          ...(args.region && { region: args.region }),
          ...(args.language && { language: args.language }),
        },
        orderBy: { code: 'asc' },
      });
    },

    circuit: async (
      _parent: unknown,
      { id }: { id: string },
      context: Context
    ): Promise<Circuit | null> => {
      requireAuth(context);
      return context.prisma.circuit.findUnique({
        where: { id },
      });
    },

    circuitByCode: async (
      _parent: unknown,
      { code }: { code: string },
      context: Context
    ): Promise<Circuit | null> => {
      requireAuth(context);
      return context.prisma.circuit.findUnique({
        where: { code },
      });
    },
  },

  Circuit: {
    congregations: async (circuit: Circuit, _args: unknown, context: Context) => {
      return context.prisma.congregation.findMany({
        where: { circuitId: circuit.id },
        orderBy: { name: 'asc' },
      });
    },

    events: async (circuit: Circuit, _args: unknown, context: Context) => {
      return context.prisma.event.findMany({
        where: { circuitId: circuit.id },
        orderBy: { startDate: 'desc' },
      });
    },
  },
};

export default circuitResolvers;
