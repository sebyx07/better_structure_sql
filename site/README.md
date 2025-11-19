# BetterStructureSql Documentation Site

React-based documentation site with Bootstrap Darkly theme, deployed to GitHub Pages.

## Features

- **React 18** with HashRouter for GitHub Pages compatibility
- **Bootstrap Darkly** theme from Bootswatch
- **esbuild** for fast builds and small bundles
- **ESLint** with Airbnb config for code quality
- **Vitest** and React Testing Library for testing
- **GitHub Actions** for automatic deployment

## Local Development

```bash
# Install dependencies
npm install

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
│   │   └── Layout/      # Header, Footer, Layout
│   ├── pages/           # Route pages
│   ├── styles/          # CSS files
│   ├── App.jsx          # Main app component
│   └── main.jsx         # Entry point
├── tests/               # Test files
├── scripts/             # Build scripts
└── package.json
```

## Build Configuration

- **esbuild** handles bundling and transpilation
- **Hash routing** (`#/`) for GitHub Pages compatibility
- **Code splitting** for optimal loading
- **Bootstrap Darkly** theme included

## Deployment

The site automatically deploys to GitHub Pages when changes are pushed to the `main` branch (in the `site/` directory). The GitHub Actions workflow:

1. Installs dependencies
2. Builds the site
3. Deploys to `gh-pages` branch

## Adding Content

1. Create new page components in `src/pages/`
2. Add routes in `src/App.jsx`
3. Update navigation in `src/components/Layout/Header.jsx`
4. Follow SOLID principles (keep files under 300 lines)

## Code Quality

- ESLint enforces Airbnb style guide
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

- Bundle size: ~300KB gzipped
- First Contentful Paint: < 1.5s
- Lighthouse score target: 90+
