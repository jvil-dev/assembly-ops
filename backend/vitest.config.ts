import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    include: ['src/__tests__/**/*.test.ts', 'src/__tests__/**/*.integration.ts'],
    testTimeout: 10000,
    pool: 'forks',
    fileParallelism: false,
  },
});
