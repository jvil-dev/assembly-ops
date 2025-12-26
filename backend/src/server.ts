import app from './app.js';
import { createApolloServer } from './graphql/index.js';

const PORT = process.env.PORT || 4000;

async function start() {
  const httpServer = await createApolloServer(app);

  httpServer.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
    console.log(`Health check: http://localhost:${PORT}/health`);
    console.log(`GraphQL: http://localhost:${PORT}/graphql`);
  });
}

start().catch(console.error);

export default app;
