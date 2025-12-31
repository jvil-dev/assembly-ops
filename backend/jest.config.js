/**
 * Jest Configuration
 *
 * Test runner configuration for integration tests.
 * Uses ts-jest for TypeScript support with ESM modules.
 *
 * Key Settings:
 *   - preset: ts-jest ESM preset (for ES modules support)
 *   - testEnvironment: node (not browser)
 *   - testTimeout: 10 seconds (database operations can be slow)
 *
 * ESM Support:
 *   - extensionsToTreatAsEsm: Treat .ts files as ES modules
 *   - moduleNameMapper: Map .js imports to actual files (TypeScript quirk)
 *   - useESM: true in ts-jest transform
 *
 * Test Discovery:
 *   - testMatch: Files in __tests__/ ending with .test.ts
 *   - setupFilesAfterEnv: Runs setup.ts before each test file
 *
 * Coverage:
 *   - collectCoverageFrom: All .ts files in src/ (excluding .d.ts)
 *   - coverageDirectory: ./coverage
 *
 * Run: npm test (all tests) or npm run test:watch (watch mode)
 */

/** @type {import('ts-jest').JestConfigWithTsJest} */
export default {
  preset: 'ts-jest/presets/default-esm',
  testEnvironment: 'node',
  extensionsToTreatAsEsm: ['.ts'],
  moduleNameMapper: {
    '^(\\.{1,2}/.*)\\.js$': '$1',
  },
  transform: {
    '^.+\\.tsx?$': [
      'ts-jest',
      {
        useESM: true,
      },
    ],
  },
  testMatch: ['<rootDir>/src/__tests__/**/*.test.ts', '<rootDir>/src/__tests__/**/*.integration.ts'],
  testPathIgnorePatterns: ['/node_modules/', '/node_modules.nosync/'],
  modulePathIgnorePatterns: ['<rootDir>/node_modules.nosync/'],
  collectCoverageFrom: ['src/**/*.ts', '!src/**/*.d.ts'],
  coverageDirectory: 'coverage',
  verbose: true,
  testTimeout: 10000,
  setupFilesAfterEnv: ['<rootDir>/src/__tests__/setup.ts'],
};
