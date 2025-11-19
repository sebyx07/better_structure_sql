import * as esbuild from 'esbuild';
import { readFileSync, writeFileSync, mkdirSync } from 'fs';

const PORT = 3000;

// Ensure public/dist exists
mkdirSync('public/dist', { recursive: true });

// Copy index.html to public for dev server
const html = readFileSync('public/index.html', 'utf8');
writeFileSync('public/index-dev.html', html.replace('%PUBLIC_URL%', ''));

const ctx = await esbuild.context({
  entryPoints: ['src/main.jsx'],
  bundle: true,
  outdir: 'public/dist',
  format: 'esm',
  splitting: true,
  sourcemap: true,
  loader: {
    '.js': 'jsx',
    '.jsx': 'jsx',
    '.css': 'css',
    '.svg': 'file',
    '.png': 'file',
    '.jpg': 'file',
  },
  define: {
    'process.env.NODE_ENV': '"development"',
  },
});

await ctx.watch();

const { host, port } = await ctx.serve({
  servedir: 'public',
  port: PORT,
  fallback: 'public/index-dev.html',
});

console.log(`🚀 Dev server running at http://${host}:${port}`);
console.log('📝 Watch mode enabled - changes will rebuild automatically');
