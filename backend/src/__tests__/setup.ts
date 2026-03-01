import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { ApolloServer } from '@apollo/server';
import { expressMiddleware } from '@as-integrations/express5';
import typeDefs from '../graphql/schema/index.js';
import resolvers from '../graphql/resolvers/index.js';
import { createContext, Context } from '../graphql/context.js';
import { cleanupTestData } from './testHelpers.js';

let app: express.Application;
let server: ApolloServer<Context>;

export async function createTestApp() {
  if (app) return app;

  app = express();
  app.use(helmet({ contentSecurityPolicy: false }));
  app.use(cors());
  app.use(express.json());

  // Health check endpoint for tests
  app.get('/health', async (_req, res) => {
    try {
      const prisma = (await import('../config/database.js')).default;
      await prisma.$queryRaw`SELECT 1`;
      res.status(200).json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        services: { database: 'connected' },
      });
    } catch {
      res.status(503).json({
        status: 'unhealthy',
        timestamp: new Date().toISOString(),
        services: { database: 'disconnected' },
      });
    }
  });

  server = new ApolloServer<Context>({
    typeDefs,
    resolvers,
  });

  await server.start();

  app.use(
    '/graphql',
    cors(),
    express.json(),
    expressMiddleware(server, { context: createContext })
  );

  return app;
}

export async function closeTestApp() {
  await cleanupTestData();
  if (server) await server.stop();
}
