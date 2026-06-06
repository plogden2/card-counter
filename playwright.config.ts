import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: 'tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'list',
  use: {
    baseURL: 'http://localhost:5173',
    trace: 'on-first-retry',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
  webServer: {
    command:
      process.platform === 'win32'
        ? '"C:\\Program Files\\cursor\\resources\\app\\resources\\helpers\\node.exe" node_modules/vite/bin/vite.js'
        : 'node node_modules/vite/bin/vite.js',
    url: 'http://localhost:5173',
    reuseExistingServer: !process.env.CI,
  },
});
