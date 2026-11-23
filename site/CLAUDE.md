# sebyx07/better_structure_sql — site

> Workspace brain — established by the developerz.ai maintainer agent for the maintainers of this repository from this workspace, then owned by
> its maintainers. Correct it in place; setup never overwrites a brain that exists.

Docs site (Node, Astro). Built to GitHub Pages on release and when site/** or version.rb changes on main.

The gate is the repo root’s: `bin/check` (see the root `CLAUDE.md`).

## Structure

**src/pages/** — Markdown pages (`.md` -> HTML). **public/** — assets. Generated **dist/** is not committed. `package.json` pins Node 24 (site/.nvmrc).

## Conventions

npm ci, npm run lint, npm test. Linter is ESLint. Tests are unit only. Build is `npm run build`. Docs reference code paths and config options; never hardcode version matrices (link to ci.yml).
