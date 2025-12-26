/**
 * GraphQL Server Setup
 *
 * This is the main entry point for the GraphQL API. It creates and configures
 * the Apollo Server instance that handles all GraphQL requests.
 *
 * Flow:
 *   1. Request hits /graphql endpoint
 *   2. Express middleware parses JSON body
 *   3. createContext() extracts auth info from JWT (see ./context.ts)
 *   4. Apollo Server matches the query/mutation to a resolver (see ./resolvers/)
 *   5. Resolver executes and returns data
 *
 * Key integrations:
 *   - typeDefs (./schema/): Defines the GraphQL schema (what queries/mutations exist)
 *   - resolvers (./resolvers/): Implements the logic for each query/mutation
 *   - createContext (./context.ts): Creates the context object with auth + prisma
 *
 * Called by: server.ts during app startup
 */
import { ApolloServer } from '@apollo/server';
import { expressMiddleware } from '@as-integrations/express5';
import { ApolloServerPluginDrainHttpServer } from '@apollo/server/plugin/drainHttpServer';
import express from 'express';
import http from 'http';
import cors from 'cors';
import typeDefs from './schema/index.js';
import resolvers from './resolvers/index.js';
import { createContext, Context } from './context.js';

export async function createApolloServer(app: express.Application) {
  const httpServer = http.createServer(app);

  const server = new ApolloServer<Context>({
    typeDefs,
    resolvers,
    plugins: [ApolloServerPluginDrainHttpServer({ httpServer })],
    introspection: process.env.NODE_ENV !== 'production',
  });

  await server.start();

  app.use(
    '/graphql',
    cors<cors.CorsRequest>(),
    express.json(),
    expressMiddleware(server, {
      context: createContext,
    })
  );

  return httpServer;
}
