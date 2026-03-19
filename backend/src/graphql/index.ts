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
 * WebSocket subscriptions:
 *   - graphql-ws protocol over ws:// (or wss:// in production)
 *   - Auth via connectionParams.authToken (JWT)
 *   - Shares the same executable schema as HTTP
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
import { makeExecutableSchema } from '@graphql-tools/schema';
import { WebSocketServer } from 'ws';
import { useServer } from 'graphql-ws/use/ws';
import depthLimit from 'graphql-depth-limit';
import express from 'express';
import http from 'http';
import typeDefs from './schema/index.js';
import resolvers from './resolvers/index.js';
import { createContext, createSubscriptionContext, Context } from './context.js';

export async function createApolloServer(app: express.Application) {
  const httpServer = http.createServer(app);

  // Build executable schema shared by both HTTP and WebSocket transports
  const schema = makeExecutableSchema({ typeDefs, resolvers });

  // WebSocket server for subscriptions
  const wsServer = new WebSocketServer({
    server: httpServer,
    path: '/graphql',
  });

  const serverCleanup = useServer(
    {
      schema,
      context: async (ctx) => {
        return createSubscriptionContext(
          (ctx.connectionParams as Record<string, unknown>) ?? {}
        );
      },
    },
    wsServer
  );

  const server = new ApolloServer<Context>({
    schema,
    validationRules: [depthLimit(10)],
    plugins: [
      ApolloServerPluginDrainHttpServer({ httpServer }),
      // Graceful shutdown for WebSocket server
      {
        async serverWillStart() {
          return {
            async drainServer() {
              await serverCleanup.dispose();
            },
          };
        },
      },
    ],
    introspection: process.env.NODE_ENV !== 'production',
  });

  await server.start();

  app.use(
    '/graphql',
    express.json(),
    expressMiddleware(server, {
      context: createContext,
    })
  );

  return httpServer;
}
