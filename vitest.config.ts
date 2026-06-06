import { defineConfig } from 'vitest/config';
import path from 'node:path';

export default defineConfig({
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'src'),
    },
  },
  test: {
    environment: 'node',
    include: ['tests/unit/**/*.test.ts', 'tests/functional/**/*.test.ts', 'tests/integration/**/*.test.ts'],
    globals: false,
    testTimeout: 15_000,
  },
});
