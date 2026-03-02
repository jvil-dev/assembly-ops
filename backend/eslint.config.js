/**
 * ESLint Configuration (Flat Config Format)
 *
 * Linting rules for TypeScript code quality and consistency.
 * Uses the new ESLint flat config format (eslint.config.js).
 *
 * Base Configs:
 *   - @eslint/js recommended: Standard JavaScript rules
 *   - typescript-eslint recommended: TypeScript-specific rules
 *
 * Custom Rules:
 *   - no-unused-vars: Error, but ignore variables starting with "_"
 *     (useful for unused function parameters like _req, _parent)
 *   - explicit-function-return-type: Off (TypeScript infers return types)
 *   - no-explicit-any: Warn only (sometimes any is necessary)
 *
 * Ignored Paths:
 *   - dist/: Compiled JavaScript output
 *   - node_modules/: Dependencies
 *   - jest.config.js: Jest config (not TypeScript)
 *
 * Run: npm run lint (check) or npm run lint:fix (auto-fix)
 */
import eslint from "@eslint/js";
import tseslint from "typescript-eslint";

export default tseslint.config(
  eslint.configs.recommended,
  ...tseslint.configs.recommended,
  {
    rules: {
      "@typescript-eslint/no-unused-vars": [
        "error",
        { argsIgnorePattern: "^_" },
      ],
      "@typescript-eslint/explicit-function-return-type": "off",
      "@typescript-eslint/no-explicit-any": "warn",
    },
  },
  {
    ignores: ["dist/**", "node_modules/**", "jest.config.js"],
  }
);
