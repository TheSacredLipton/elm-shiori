import { defineConfig, devices } from '@playwright/test';

const examples = ['01-hello', '02-css', '03-elm-ui', '04-elm-css', '05-tailwind'];

const projects = examples.map((name, index) => {
  const port = 3001 + index;
  return {
    name,
    use: {
      ...devices['Desktop Chrome'],
      baseURL: `http://localhost:${port}`
    }
  };
});

const webServers = examples.map((name, index) => {
  const port = 3001 + index;
  return {
    command: `node ../../bin/shiori.js serve --port ${port}`,
    cwd: `./examples/${name}`,
    url: `http://localhost:${port}`,
    reuseExistingServer: !process.env.CI,
    timeout: 30000
  };
});

export default defineConfig({
  testDir: './tests',
  testMatch: 'vrt.spec.js',
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 1,
  reporter: 'list',
  projects,
  webServer: webServers
});
