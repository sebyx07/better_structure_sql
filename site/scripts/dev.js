import * as esbuild from 'esbuild';
import { readFileSync, writeFileSync, mkdirSync } from 'fs';

const PORT = 3000;

// Ensure public/dist exists
mkdirSync('public/dist', { recursive: true });

// Read template and inject script tags for dev
const html = readFileSync('public/index.template.html', 'utf8');
const htmlWithScripts = html
  .replace('%PUBLIC_URL%', '')
  .replace(
    '</head>',
    '  <link rel="stylesheet" href="/dist/main.css">\n  </head>'
  )
  .replace(
    '</body>',
    '  <script type="module" src="/dist/main.js"></script>\n  </body>'
  );

// Write as index.html so localhost:3000 works
writeFileSync('public/index.html', htmlWithScripts);

const ctx = await esbuild.context({
  entryPoints: ['src/main.jsx'],
  bundle: true,
  outdir: 'public/dist',
  format: 'esm',
  splitting: true,
  sourcemap: true,
  jsx: 'automatic',
  loader: {
    '.js': 'jsx',
    '.jsx': 'jsx',
    '.css': 'css',
    '.svg': 'file',
    '.png': 'file',
    '.jpg': 'file',
    '.ico': 'file',
    '.woff': 'file',
    '.woff2': 'file',
    '.ttf': 'file',
    '.eot': 'file',
  },
  define: {
    'process.env.NODE_ENV': '"development"',
  },
});

await ctx.watch();

const { host, port } = await ctx.serve({
  servedir: 'public',
  port: PORT,
});

console.log(`🚀 Dev server running at http://${host}:${port}`);
console.log('📝 Watch mode enabled - changes will rebuild automatically');
