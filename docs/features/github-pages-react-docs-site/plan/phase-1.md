# Phase 1: Project Foundation and Core Setup

## Objective

Establish the React project foundation with build tooling, routing, styling framework, and essential development tools (ESLint, testing). Create basic site structure and deploy pipeline.

## Deliverables

### 1. Project Initialization

**Create site directory structure**:
```
site/
├── public/
├── src/
│   ├── components/
│   ├── pages/
│   ├── styles/
│   ├── App.jsx
│   └── main.jsx
├── tests/
├── package.json
├── vite.config.js
└── README.md
```

**Initialize npm project**:
- Create `package.json` with dependencies
- Install React, React DOM, React Router
- Install Vite and build plugins
- Install Bootstrap and Bootswatch Darkly
- Install testing tools (Vitest, React Testing Library)
- Install ESLint and Prettier
- Configure scripts (dev, build, test, lint)

### 2. Vite Configuration

**Configure `vite.config.js`**:
- Set base path for GitHub Pages (`/better_structure_sql/`)
- Configure React plugin
- Set up build output directory (`dist/`)
- Enable source maps for debugging
- Configure test environment with Vitest
- Set up CSS processing

**Configuration example**:
```javascript
export default defineConfig({
  plugins: [react()],
  base: '/better_structure_sql/',
  build: {
    outDir: 'dist',
    sourcemap: true,
  },
  test: {
    globals: true,
    environment: 'happy-dom',
    setupFiles: './tests/setup.js',
  },
});
```

### 3. React Router Setup

**Install and configure HashRouter**:
- Install `react-router-dom` (v6)
- Create `src/routes.jsx` with route definitions
- Configure HashRouter in `src/main.jsx`
- Create placeholder pages for main routes:
  - Home (`/`)
  - Installation (`/install`)
  - Configuration (`/configuration`)
  - Examples (`/examples`)

**Route structure**:
```javascript
<Routes>
  <Route path="/" element={<Home />} />
  <Route path="/install" element={<Installation />} />
  <Route path="/configuration" element={<Configuration />} />
  <Route path="/examples" element={<Examples />} />
</Routes>
```

### 4. Bootstrap Darkly Theme Integration

**Install and configure Bootstrap**:
- Install `bootstrap` and `bootswatch` via npm
- Import Darkly theme in `src/main.jsx`:
  ```javascript
  import 'bootswatch/dist/darkly/bootstrap.min.css';
  ```
- Install `bootstrap-icons` for icon support
- Create custom CSS variables override file
- Set up global styles in `src/styles/main.css`

**Verify theming**:
- Test dark theme applies correctly
- Verify Bootstrap components render properly
- Check responsive behavior (mobile, tablet, desktop)

### 5. ESLint and Prettier Configuration

**Configure ESLint** (`.eslintrc.json`):
- Extend `eslint:recommended`, `plugin:react/recommended`, `airbnb`
- Configure React settings (JSX runtime, prop-types)
- Set up parser options (ES2021, JSX)
- Add custom rules for project conventions
- Integrate with Prettier (eslint-config-prettier)

**Configure Prettier** (`.prettierrc`):
```json
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 100
}
```

**Add npm scripts**:
```json
{
  "scripts": {
    "lint": "eslint src --ext .js,.jsx",
    "lint:fix": "eslint src --ext .js,.jsx --fix",
    "format": "prettier --write \"src/**/*.{js,jsx,json,css,md}\""
  }
}
```

### 6. Testing Setup

**Configure Vitest**:
- Create `vitest.config.js` with test settings
- Set up `tests/setup.js` for global test configuration
- Install testing utilities:
  - `@testing-library/react`
  - `@testing-library/jest-dom`
  - `@testing-library/user-event`
  - `happy-dom` (lightweight DOM)

**Create sample tests**:
- Component test: `tests/components/App.test.jsx`
- Page test: `tests/pages/Home.test.jsx`
- Test script in package.json: `"test": "vitest"`

**Example test**:
```javascript
import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import App from '../src/App';

describe('App', () => {
  it('renders without crashing', () => {
    render(<App />);
    expect(screen.getByRole('main')).toBeInTheDocument();
  });
});
```

### 7. Layout Components

**Create base layout structure**:

**Header component** (`src/components/Layout/Header.jsx`):
- Bootstrap navbar with brand logo
- Navigation links (Home, Docs, Features, Examples, API)
- Responsive hamburger menu for mobile
- Active route highlighting

**Footer component** (`src/components/Layout/Footer.jsx`):
- Links to GitHub repository
- License information
- Current gem version
- Social links (optional)

**Layout wrapper** (`src/components/Layout/Layout.jsx`):
- Combines Header, main content area, Footer
- Applies consistent spacing and styling
- ScrollToTop utility on route change

### 8. Home Page Foundation

**Create Home page** (`src/pages/Home.jsx`):
- Hero section with tagline: "Use SQL Databases to the Fullest"
- Brief description of BetterStructureSql
- Key feature highlights (4-6 cards)
- Call-to-action buttons (Get Started, View on GitHub)
- Database badges (PostgreSQL, MySQL, SQLite)

**Feature cards**:
- Clean Diffs
- Multi-Database Support
- Schema Versioning
- Multi-File Output
- No External Tools
- Rails Integration

### 9. GitHub Actions Deployment

**Create workflow** (`.github/workflows/deploy-docs.yml`):
- Trigger on push to main branch
- Install Node.js with npm caching
- Run `npm ci` for clean install
- Run linter (`npm run lint`)
- Run tests (`npm test`)
- Build site (`npm run build`)
- Deploy to GitHub Pages (gh-pages branch)

**Workflow example**:
```yaml
name: Deploy Docs

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: site/package-lock.json
      - run: npm ci
        working-directory: ./site
      - run: npm run lint
        working-directory: ./site
      - run: npm test
        working-directory: ./site
      - run: npm run build
        working-directory: ./site
      - uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./site/dist
```

### 10. Documentation

**Create site README** (`site/README.md`):
- Project description
- Local development setup
- Available scripts
- Build and deployment process
- Contributing guidelines

**Update root README**:
- Add link to documentation site
- Mention GitHub Pages hosting

## Testing Requirements

### Unit Tests
- App component renders correctly
- Header navigation works
- Footer displays version
- Layout wrapper applies structure
- Home page renders hero section

### Integration Tests
- Router navigation between pages
- Bootstrap components render with Darkly theme
- Responsive layout on mobile/tablet/desktop

### Build Tests
- Vite build completes without errors
- Output directory contains index.html
- Assets are properly hashed and copied
- Source maps generated

### Linting Tests
- ESLint passes with no errors
- Prettier formatting consistent
- No accessibility violations (jsx-a11y)

## Success Criteria

- [x] Site runs locally with `npm run dev`
- [x] Hash routing works (URLs like `#/install`)
- [x] Bootstrap Darkly theme applies correctly
- [x] All ESLint rules pass
- [x] All tests pass with >80% coverage
- [x] Vite build produces optimized bundle
- [x] GitHub Actions deploys to GitHub Pages successfully
- [x] Site accessible at `https://<username>.github.io/better_structure_sql/`
- [x] Mobile responsive layout works
- [x] Navigation between pages functions correctly

## Dependencies

**Production**:
- react: ^18.2.0
- react-dom: ^18.2.0
- react-router-dom: ^6.20.0
- bootstrap: ^5.3.2
- bootswatch: ^5.3.2
- bootstrap-icons: ^1.11.0

**Development**:
- vite: ^5.0.0
- @vitejs/plugin-react: ^4.2.0
- eslint: ^8.54.0
- eslint-plugin-react: ^7.33.0
- eslint-plugin-react-hooks: ^4.6.0
- eslint-plugin-jsx-a11y: ^6.8.0
- eslint-config-airbnb: ^19.0.0
- eslint-config-prettier: ^9.0.0
- prettier: ^3.1.0
- vitest: ^1.0.0
- @testing-library/react: ^14.0.0
- @testing-library/jest-dom: ^6.1.0
- @testing-library/user-event: ^14.5.0
- happy-dom: ^12.10.0

## Phase Dependencies

None - This is the foundation phase.

## Estimated Effort

**Development**: 2-3 days
- Project setup and configuration: 4 hours
- Layout components and routing: 4 hours
- Testing setup and initial tests: 3 hours
- GitHub Actions configuration: 2 hours
- Documentation and polish: 2 hours

**Total**: ~15 hours
