import * as esbuild from 'esbuild';
import { htmlPlugin } from '@craftamap/esbuild-plugin-html';
import { copyFileSync, readFileSync, rmSync, writeFileSync } from 'fs';
import { sharedOptions, STATIC_FILES } from './esbuild.shared.js';

const OUT_DIR = 'dist';

rmSync(OUT_DIR, { recursive: true, force: true });

try {
  await esbuild.build({
    ...sharedOptions,
    minify: true,
    target: ['es2020'],
    outdir: OUT_DIR,
    publicPath: '/better_structure_sql',
    metafile: true,
    plugins: [
      htmlPlugin({
        files: [
          {
            entryPoints: ['src/main.jsx'],
            filename: 'index.html',
            htmlTemplate: readFileSync('public/index.template.html', 'utf8'),
            scriptLoading: 'module',
          },
        ],
      }),
    ],
    define: { ...sharedOptions.define, 'process.env.NODE_ENV': '"production"' },
    logLevel: 'info',
  });

  STATIC_FILES.forEach((file) => copyFileSync(`public/${file}`, `${OUT_DIR}/${file}`));
  // GitHub Pages must not run the output through Jekyll
  writeFileSync(`${OUT_DIR}/.nojekyll`, '');

  console.log('Build completed successfully');
} catch (error) {
  console.error('Build failed:', error.message);
  process.exit(1);
}
