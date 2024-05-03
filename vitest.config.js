import { defineConfig } from 'vitest/config'; // or `import { defineConfig } from 'vite';`
import { doctest } from 'vite-plugin-doctest';
export default defineConfig({
  plugins: [
    doctest({
      /* options */
    })
  ],
  test: {
    includeSource: ['./bin/utils.js']
  }
});
