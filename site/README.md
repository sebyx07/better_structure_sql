# BetterStructureSql Documentation Site

React-based documentation site with Bootstrap Darkly theme, deployed to GitHub Pages.

## Features

- **React 19** with React Router 7 HashRouter for GitHub Pages compatibility
- **Bootstrap Darkly** theme from Bootswatch
- **esbuild** for fast builds and small bundles
- **ESLint 9** (flat config) with React, hooks and jsx-a11y rules
- **Vitest** and React Testing Library for testing
- **GitHub Actions** for automatic deployment

## Local Development

Requires Node.js 22 or newer (`.nvmrc` pins the version CI uses).

```bash
# Install dependencies
npm ci

# Start dev server (http://localhost:3000)
npm run dev

# Run tests
npm test

# Run linter
npm run lint

# Format code
npm run format

# Build for production
npm run build
```

## Project Structure

```
site/
├── public/              # Static assets
├── src/
│   ├── components/      # React components
│   │   ├── CodeBlock/   # Syntax-highlighted code with copy button
│   │   ├── Layout/      # Header, Footer, Layout
│   │   └── Seo/         # Page title and meta description
│   ├── pages/           # Route pages
│   ├── styles/          # CSS files
│   ├── App.jsx          # Main app component
│   └── main.jsx         # Entry point
├── tests/               # Test files
├── scripts/             # esbuild build and dev scripts
└── package.json
```

## Build Configuration

- **esbuild** handles bundling and transpilation
- **Hash routing** (`#/`) for GitHub Pages compatibility
- **Code splitting** for optimal loading
- **Bootstrap Darkly** theme included

## Deployment

`.github/workflows/deploy-docs.yml` lints, tests and builds the site on every pull request that touches `site/`. On pushes to `main` it also deploys `dist/` with the official GitHub Pages actions (`upload-pages-artifact` + `deploy-pages`). The repository's Pages source must be set to **GitHub Actions** (Settings → Pages); the `gh-pages` branch is no longer used.

The gem version shown on the site is read from `lib/better_structure_sql/version.rb` at build time, so a release redeploys the site with the new version.

## Adding Content

1. Create new page components in `src/pages/`
2. Add routes in `src/App.jsx`
3. Update navigation in `src/components/Layout/Header.jsx`
4. Follow SOLID principles (keep files under 300 lines)

## Code Quality

- ESLint with React, hooks and accessibility rules
- Prettier for consistent formatting
- Accessibility (WCAG 2.1 AA) compliance
- Vitest for unit and integration testing

## Theme

Using **Bootswatch Darkly** theme with Bootstrap 5:
- Dark background (#222)
- Primary blue (#375a7f)
- Clean, modern aesthetic
- Fully responsive

## Performance

- Bundle size: ~205KB gzipped (JS + CSS)
- First Contentful Paint: < 1.5s
- Lighthouse score target: 90+
