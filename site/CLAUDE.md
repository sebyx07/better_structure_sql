# site/ (docs site)

The user-facing docs site: a React single-page app bundled with esbuild (`scripts/build.js`,
`scripts/dev.js`), deployed to GitHub Pages at https://sebyx07.github.io/better_structure_sql/.

## Run it

- Node version from `.nvmrc`. `npm ci && npm run lint && npm test && npm run build`; `npm run dev` for a local server.
- Lint is ESLint (`eslint.config.js`), tests are Vitest with Testing Library (`tests/`), output is `dist/` (gitignored).
- `bin/check` does **not** cover the site. `.github/workflows/deploy-docs.yml` runs lint, test and build on
  pull requests touching `site/**` or `lib/better_structure_sql/version.rb`, and deploys on `main`.

## Rules

- Pages are JSX under `src/pages/`, shared pieces under `src/components/`. The gem version shown is
  `src/version.js`, filled at build time from `lib/better_structure_sql/version.rb` (`scripts/gemVersion.js`); never hardcode it.
- A change to options, tasks or output updates the matching page here alongside `README.md`, `docs/` and `llms.txt`.
- Never restate the tested Ruby, Rails or database versions; link to `.github/workflows/ci.yml`.
