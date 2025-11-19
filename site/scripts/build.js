import * as esbuild from 'esbuild';
import { htmlPlugin } from '@craftamap/esbuild-plugin-html';
import { readFileSync } from 'fs';

const isProduction = process.env.NODE_ENV === 'production';

esbuild
  .build({
    entryPoints: ['src/main.jsx'],
    bundle: true,
    minify: isProduction,
    splitting: true,
    format: 'esm',
    target: ['es2020'],
    outdir: 'dist',
    publicPath: '/better_structure_sql',
    metafile: true,
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
    plugins: [
      htmlPlugin({
        files: [
          {
            entryPoints: ['src/main.jsx'],
            filename: 'index.html',
            htmlTemplate: readFileSync('public/index.html', 'utf8'),
          },
        ],
      }),
    ],
    define: {
      'process.env.NODE_ENV': JSON.stringify(
        process.env.NODE_ENV || 'production'
      ),
    },
    logLevel: 'info',
  })
  .then(() => {
    console.log('✅ Build completed successfully!');
  })
  .catch(() => {
    console.error('❌ Build failed');
    process.exit(1);
  });
