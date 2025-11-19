# GitHub Pages React Documentation Site

Modern, interactive documentation site for BetterStructureSql built with React, Bootstrap Darkly theme, and deployed to GitHub Pages.

## Overview

A fully-featured React-based documentation website that showcases BetterStructureSql's capabilities with clean UI, interactive examples, and comprehensive guides. The site emphasizes the power of using SQL databases to their fullest potential with schema management features.

## Theme: "Using SQL Databases to the Fullest"

The site centers around the philosophy that modern Rails applications can leverage advanced database features (views, functions, triggers, stored procedures) across thousands of tables without sacrificing maintainability. BetterStructureSql makes this possible through:

- Clean, maintainable schema dumps
- Multi-file output for massive schemas (50,000+ objects)
- Schema versioning with production access via Engine
- Support for advanced database features (views, triggers, functions)
- Multi-database compatibility (PostgreSQL, MySQL, SQLite)

## Technology Stack

### Core Technologies
- **React** (18+) - Modern component-based UI
- **React Router** (v6) - Hash-based routing (`#/`) for GitHub Pages compatibility
- **Bootstrap 5** - UI framework with Darkly theme (Bootswatch)
- **npm** - Package management
- **Vite** - Build tool and dev server

### Development Tools
- **ESLint** - Code linting with React and Airbnb config
- **Prettier** - Code formatting
- **Jest** - Unit testing framework
- **React Testing Library** - Component testing
- **Vitest** - Fast unit test runner (Vite-native alternative to Jest)

### Deployment
- **GitHub Pages** - Static site hosting
- **GitHub Actions** - CI/CD pipeline for automatic deployment

## Site Structure

### Location
All site files stored in `./site/` directory within the project root:

```
better_structure_sql/
├── site/                           # Documentation site
│   ├── public/                     # Static assets
│   │   ├── favicon.ico
│   │   └── logo.svg
│   ├── src/
│   │   ├── components/             # React components
│   │   │   ├── Layout/
│   │   │   │   ├── Header.jsx
│   │   │   │   ├── Footer.jsx
│   │   │   │   └── Sidebar.jsx
│   │   │   ├── CodeBlock/
│   │   │   │   └── CodeBlock.jsx
│   │   │   ├── FeatureCard/
│   │   │   │   └── FeatureCard.jsx
│   │   │   └── DatabaseTabs/
│   │   │       └── DatabaseTabs.jsx
│   │   ├── pages/                  # Route pages
│   │   │   ├── Home.jsx
│   │   │   ├── GettingStarted/
│   │   │   │   ├── Installation.jsx
│   │   │   │   ├── Configuration.jsx
│   │   │   │   └── QuickStart.jsx
│   │   │   ├── Databases/
│   │   │   │   ├── PostgreSQL.jsx
│   │   │   │   ├── MySQL.jsx
│   │   │   │   └── SQLite.jsx
│   │   │   ├── Features/
│   │   │   │   ├── SchemaVersioning.jsx
│   │   │   │   ├── MultiFileOutput.jsx
│   │   │   │   ├── WebEngine.jsx
│   │   │   │   └── AdvancedFeatures.jsx
│   │   │   ├── Production/
│   │   │   │   ├── Deployment.jsx
│   │   │   │   ├── AfterMigrate.jsx
│   │   │   │   └── EngineAccess.jsx
│   │   │   ├── Examples.jsx
│   │   │   └── API.jsx
│   │   ├── App.jsx                 # Main app component
│   │   ├── main.jsx                # Entry point
│   │   └── routes.jsx              # Route configuration
│   ├── tests/
│   │   ├── components/             # Component tests
│   │   ├── pages/                  # Page tests
│   │   └── setup.js                # Test setup
│   ├── .eslintrc.json              # ESLint configuration
│   ├── .prettierrc                 # Prettier configuration
│   ├── vite.config.js              # Vite configuration
│   ├── vitest.config.js            # Test configuration
│   ├── package.json
│   └── README.md
├── .github/
│   └── workflows/
│       └── deploy-docs.yml         # GitHub Pages deployment
└── [rest of gem files]
```

### Page Navigation

**Home** (`#/`)
- Hero section with tagline: "Use SQL Databases to the Fullest"
- Feature highlights with cards
- Quick start snippet
- Database support badges (PostgreSQL, MySQL, SQLite)
- Live demo links

**Getting Started**
- `#/install` - Installation guide with database-specific instructions
- `#/quick-start` - 5-minute quick start
- `#/configuration` - Configuration options and examples

**Database Guides**
- `#/databases/postgresql` - PostgreSQL-specific features (extensions, materialized views, custom types)
- `#/databases/mysql` - MySQL features (stored procedures, triggers, character sets)
- `#/databases/sqlite` - SQLite features (pragmas, inline FKs, type affinities)

**Features**
- `#/features/schema-versioning` - Version storage, retention, web UI access
- `#/features/multi-file-output` - Massive schema support, directory organization
- `#/features/web-engine` - Mountable Rails Engine for production schema access
- `#/features/advanced` - Views, triggers, functions, partitioning

**Production Usage**
- `#/production/deployment` - Production deployment strategies
- `#/production/after-migrate` - Automatic schema storage after migrations
- `#/production/engine-access` - Developer access to production schemas without direct DB access

**Examples** (`#/examples`)
- Real-world schema examples
- Before/After comparisons (pg_dump vs BetterStructureSql)
- Multi-file schema visualization
- Interactive schema explorer

**API Reference** (`#/api`)
- Configuration API
- Rake tasks
- Programmatic usage
- Custom generators

## Key Features to Highlight

### 1. Schema Versioning in Production

**Problem**: Developers need to see the current production schema without direct database access.

**Solution**: After each migration in production, automatically store the schema version:

```ruby
# config/initializers/better_structure_sql.rb
config.enable_schema_versions = true
config.schema_versions_limit = 10
```

```ruby
# After deploy and migrate
rake db:migrate
rake db:schema:store  # Stores version with timestamp
```

Developers access via mounted Engine:
```ruby
# config/routes.rb
authenticate :admin_user do
  mount BetterStructureSql::Engine => '/schema_versions'
end
```

### 2. Thousands of Tables Support

**Problem**: Large schemas (e.g., multi-tenant apps with 50,000+ tables) produce massive structure.sql files that are slow to load and difficult to diff.

**Solution**: Multi-file output with intelligent chunking:

```ruby
config.output_path = 'db/schema'
config.max_lines_per_file = 500
```

Result: 50,000 tables split across organized directories, git diffs show only changed files.

### 3. Advanced Database Features Made Easy

**Problem**: Using views, triggers, functions means maintaining custom schema dumps.

**Solution**: BetterStructureSql introspects and generates:
- Views and materialized views
- PL/pgSQL functions
- Triggers (BEFORE, AFTER, INSTEAD OF)
- Stored procedures (MySQL)
- Custom types and enums
- Extensions

All deterministically dumped and version-controlled.

### 4. Multi-Database Development

**Problem**: Different databases require different dump tools (pg_dump, mysqldump, sqlite3).

**Solution**: Single gem with adapter pattern:
- Auto-detects database type
- Database-specific SQL generation
- Graceful feature degradation
- Unified configuration API

## Bootstrap Darkly Theme

### Theme Implementation

Use Bootswatch Darkly theme via CDN or npm package:

```html
<!-- CDN approach -->
<link rel="stylesheet"
      href="https://cdn.jsdelivr.net/npm/bootswatch@5.3.2/dist/darkly/bootstrap.min.css">
```

```bash
# npm approach (preferred)
npm install bootswatch
```

```javascript
// Import in main.jsx or App.jsx
import 'bootswatch/dist/darkly/bootstrap.min.css';
```

### Color Palette
- Primary: `#375a7f` (blue)
- Secondary: `#444` (dark gray)
- Success: `#00bc8c` (teal)
- Danger: `#e74c3c` (red)
- Warning: `#f39c12` (orange)
- Info: `#3498db` (light blue)
- Background: `#222` (dark)
- Surface: `#303030` (lighter dark)
- Text: `#fff` (white)

### Typography
- Headings: Clear hierarchy with proper spacing
- Code blocks: Syntax highlighting with Prism.js or react-syntax-highlighter
- Monospace font for code: `'Source Code Pro', Monaco, Consolas, monospace`

## React Router Hash Mode

### Why Hash Mode?

GitHub Pages doesn't support client-side routing with clean URLs. Hash mode (`#/path`) works perfectly:

```javascript
// src/main.jsx
import { HashRouter } from 'react-router-dom';

root.render(
  <HashRouter>
    <App />
  </HashRouter>
);
```

### Route Configuration

```javascript
// src/routes.jsx
import { Routes, Route } from 'react-router-dom';

export default function AppRoutes() {
  return (
    <Routes>
      <Route path="/" element={<Home />} />
      <Route path="/install" element={<Installation />} />
      <Route path="/databases/postgresql" element={<PostgreSQL />} />
      <Route path="/features/schema-versioning" element={<SchemaVersioning />} />
      {/* ... */}
    </Routes>
  );
}
```

## ESLint Configuration

### Rules and Plugins

```json
{
  "extends": [
    "eslint:recommended",
    "plugin:react/recommended",
    "plugin:react-hooks/recommended",
    "airbnb",
    "prettier"
  ],
  "plugins": ["react", "react-hooks", "jsx-a11y"],
  "env": {
    "browser": true,
    "es2021": true,
    "node": true
  },
  "parserOptions": {
    "ecmaVersion": "latest",
    "sourceType": "module",
    "ecmaFeatures": {
      "jsx": true
    }
  },
  "rules": {
    "react/react-in-jsx-scope": "off",
    "react/prop-types": "warn",
    "no-console": "warn"
  }
}
```

### Pre-commit Hook

```json
// package.json
{
  "scripts": {
    "lint": "eslint src --ext .js,.jsx",
    "lint:fix": "eslint src --ext .js,.jsx --fix",
    "format": "prettier --write \"src/**/*.{js,jsx,json,css,md}\""
  },
  "husky": {
    "hooks": {
      "pre-commit": "npm run lint"
    }
  }
}
```

## Testing Strategy

### Unit Tests (Vitest + React Testing Library)

```javascript
// tests/components/FeatureCard.test.jsx
import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import FeatureCard from '../../src/components/FeatureCard/FeatureCard';

describe('FeatureCard', () => {
  it('renders title and description', () => {
    render(
      <FeatureCard
        title="Schema Versioning"
        description="Store and retrieve schema versions"
      />
    );

    expect(screen.getByText('Schema Versioning')).toBeInTheDocument();
    expect(screen.getByText(/Store and retrieve/)).toBeInTheDocument();
  });
});
```

### Integration Tests

```javascript
// tests/pages/Home.test.jsx
import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import Home from '../../src/pages/Home';

describe('Home Page', () => {
  it('displays hero section with tagline', () => {
    render(
      <MemoryRouter>
        <Home />
      </MemoryRouter>
    );

    expect(screen.getByText(/Use SQL Databases to the Fullest/i)).toBeInTheDocument();
  });
});
```

### Coverage Requirements
- Minimum 80% code coverage
- All components must have tests
- Critical user flows fully tested

## Deployment

### GitHub Actions Workflow

```yaml
# .github/workflows/deploy-docs.yml
name: Deploy Documentation

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: site/package-lock.json

      - name: Install dependencies
        working-directory: ./site
        run: npm ci

      - name: Lint
        working-directory: ./site
        run: npm run lint

      - name: Test
        working-directory: ./site
        run: npm test -- --coverage

      - name: Build
        working-directory: ./site
        run: npm run build
        env:
          NODE_ENV: production

      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./site/dist
```

### Vite Build Configuration

```javascript
// site/vite.config.js
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  base: '/better_structure_sql/', // GitHub repo name
  build: {
    outDir: 'dist',
    sourcemap: true,
  },
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: './tests/setup.js',
  },
});
```

## Interactive Features

### 1. Live Schema Comparison
Side-by-side viewer showing pg_dump output vs BetterStructureSql output for same schema.

### 2. Database Feature Matrix
Interactive table showing feature support across PostgreSQL, MySQL, SQLite with tooltips.

### 3. Configuration Generator
Form-based configuration builder that generates initializer code.

### 4. Multi-File Schema Visualizer
Tree view showing directory structure for large schemas with expandable folders.

### 5. Code Playground
Editable configuration snippets with instant preview of output structure.

## Content Sections

### Why This Matters

Emphasize how BetterStructureSql enables modern Rails development:

1. **Embrace Database Features** - Use views, triggers, functions without fear
2. **Scale Confidently** - Handle 50,000+ tables (multi-tenant, time-series partitioning)
3. **Production Transparency** - Developers see current schema without DB access
4. **Version Control Friendly** - Clean diffs show actual schema changes
5. **Multi-Database Freedom** - Switch between PostgreSQL, MySQL, SQLite effortlessly

### Production Workflow

```
1. Developer writes migration
2. Deploy to production
3. Run: rake db:migrate
4. Auto-run: rake db:schema:store (via initializer hook)
5. Schema version stored in database with ZIP archive
6. Developers access via /schema_versions (authenticated)
7. Download, compare, or view formatted schema
8. No direct database access needed
```

### Schema Versioning Benefits

- **Onboarding** - New developers get latest schema instantly
- **Debugging** - Compare production vs local schema
- **Compliance** - Audit trail of schema changes with timestamps
- **Rollback** - Restore previous schema if needed
- **Documentation** - Schema evolution history

## Success Metrics

### Performance Targets
- Page load: < 2 seconds
- Lighthouse score: > 90
- Mobile responsive: All pages
- Accessibility: WCAG 2.1 AA compliant

### Content Targets
- 15+ comprehensive pages
- 50+ code examples
- Interactive demos for major features
- Video walkthroughs (optional)

### SEO Optimization
- Meta descriptions for all pages
- OpenGraph tags for social sharing
- Sitemap generation
- robots.txt configuration

## Future Enhancements

1. **Search functionality** - Full-text search across documentation
2. **Dark/Light toggle** - User preference with Darkly as default
3. **Version switcher** - Documentation for different gem versions
4. **API explorer** - Interactive API documentation
5. **Video tutorials** - Embedded walkthrough videos
6. **Community examples** - User-submitted schema patterns

## Use Cases Highlighted

### 1. Multi-Tenant SaaS with 10,000 Tables
Show how multi-file output makes this manageable with clean git diffs.

### 2. Time-Series Database with Partitioning
Demonstrate partition table support and trigger generation.

### 3. Microservices with Shared Views
Highlight view and materialized view support for data aggregation.

### 4. Legacy Database Migration
Show MySQL to PostgreSQL migration using adapter feature detection.

### 5. Regulatory Compliance
Schema versioning for audit trail and compliance requirements.

## Keywords

GitHub Pages, React documentation site, React Router hash routing, Bootstrap Darkly theme, Bootswatch, npm package management, Vite build tool, ESLint configuration, React Testing Library, Vitest testing, static site deployment, GitHub Actions CI/CD, schema versioning production workflow, automatic schema storage, post-migration hooks, Rails Engine web UI, developer schema access, production database transparency, multi-file schema output, massive schema support, thousands of tables, 50000+ database objects, advanced database features, views triggers functions, stored procedures, materialized views, multi-tenant architecture, time-series partitioning, database-agnostic development, PostgreSQL MySQL SQLite support, clean git diffs, version control friendly schemas, interactive documentation, code playground, configuration generator, feature comparison matrix, syntax highlighting, responsive design, accessibility WCAG, SEO optimization, single-page application SPA, component-based architecture, modern documentation experience
