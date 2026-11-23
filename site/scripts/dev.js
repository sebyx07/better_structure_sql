import * as esbuild from 'esbuild';
import { readFileSync, writeFileSync, mkdirSync } from 'fs';
import { sharedOptions } from './esbuild.shared.js';

const PORT = 3000;

// Ensure public/dist exists
mkdirSync('public/dist', { recursive: true });

// The template links assets under the GitHub Pages base path; the dev server serves from /
const html = readFileSync('public/index.template.html', 'utf8')
  .replaceAll('/better_structure_sql/', '/')
  .replace('</head>', '  <link rel="stylesheet" href="/dist/main.css">\n  </head>')
  .replace('</body>', '  <script type="module" src="/dist/main.js"></script>\n  </body>');

// Write as index.html so localhost:3000 works
writeFileSync('public/index.html', html);

const ctx = await esbuild.context({
  ...sharedOptions,
  outdir: 'public/dist',
  sourcemap: true,
  define: { ...sharedOptions.define, 'process.env.NODE_ENV': '"development"' },
});

await ctx.watch();

const { hosts, port } = await ctx.serve({ servedir: 'public', port: PORT });

console.log(`Dev server running at http://${hosts[0]}:${port}`);
console.log('Watch mode enabled - changes will rebuild automatically');
