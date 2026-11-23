import { readGemVersion } from './gemVersion.js';

// esbuild options shared by the production build and the dev server
export const sharedOptions = {
  entryPoints: ['src/main.jsx'],
  bundle: true,
  format: 'esm',
  splitting: true,
  jsx: 'automatic',
  define: { __GEM_VERSION__: JSON.stringify(readGemVersion()) },
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
};

// Files in public/ that are published as-is next to index.html
export const STATIC_FILES = [
  'favicon.ico',
  'favicon-192.png',
  'favicon-512.png',
  'apple-touch-icon.png',
  'manifest.json',
  'robots.txt',
  'sitemap.xml',
];
