import { defineConfig } from 'vitest/config';
import { readGemVersion } from './scripts/gemVersion.js';

export default defineConfig({
  define: { __GEM_VERSION__: JSON.stringify(readGemVersion()) },
  test: {
    globals: true,
    environment: 'happy-dom',
    setupFiles: './tests/setup.js',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: ['node_modules/', 'tests/', 'scripts/', 'dist/'],
    },
  },
});
