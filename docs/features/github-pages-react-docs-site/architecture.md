# Architecture: GitHub Pages React Documentation Site

Technical architecture for the BetterStructureSql documentation site built with React and modern frontend tooling.

## System Architecture

### High-Level Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        GitHub Pages                          │
│                  (Static Site Hosting)                       │
└─────────────────────────────────────────────────────────────┘
                            ▲
                            │ Deploy
                            │
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Actions CI/CD                      │
│  (Build → Test → Lint → Bundle → Deploy)                    │
└─────────────────────────────────────────────────────────────┘
                            ▲
                            │ Push to main
                            │
┌─────────────────────────────────────────────────────────────┐
│                    Development Workflow                      │
│                                                              │
│  Developer → ESLint → Tests → Git Commit → GitHub           │
└─────────────────────────────────────────────────────────────┘
```

### Component Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                         App.jsx                              │
│                    (Root Component)                          │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │            HashRouter (React Router)               │    │
│  │                                                     │    │
│  │  ┌─────────────────────────────────────────────┐  │    │
│  │  │           Layout Components                  │  │    │
│  │  │  • Header (Navigation)                       │  │    │
│  │  │  • Sidebar (Nested Navigation)               │  │    │
│  │  │  • Footer (Links, Version)                   │  │    │
│  │  └─────────────────────────────────────────────┘  │    │
│  │                                                     │    │
│  │  ┌─────────────────────────────────────────────┐  │    │
│  │  │           Route Pages                        │  │    │
│  │  │  • Home                                      │  │    │
│  │  │  • Getting Started (Install, Config)         │  │    │
│  │  │  • Database Guides (PG, MySQL, SQLite)       │  │    │
│  │  │  • Features (Versioning, Multi-file, etc)    │  │    │
│  │  │  • Production Usage                          │  │    │
│  │  │  • Examples                                  │  │    │
│  │  │  • API Reference                             │  │    │
│  │  └─────────────────────────────────────────────┘  │    │
│  │                                                     │    │
│  │  ┌─────────────────────────────────────────────┐  │    │
│  │  │        Reusable Components                   │  │    │
│  │  │  • FeatureCard                               │  │    │
│  │  │  • CodeBlock (Syntax Highlighting)           │  │    │
│  │  │  • DatabaseTabs                              │  │    │
│  │  │  • ConfigGenerator                           │  │    │
│  │  │  • SchemaVisualizer                          │  │    │
│  │  │  • ComparisonViewer                          │  │    │
│  │  └─────────────────────────────────────────────┘  │    │
│  └────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────┘
```

## Technology Stack Details

### Build System

**Vite** - Modern build tool
- **Dev Server**: Lightning-fast HMR (Hot Module Replacement)
- **Build**: Rollup-based bundling with code splitting
- **Plugins**: React Fast Refresh, JSX transform
- **CSS**: PostCSS with autoprefixer
- **Assets**: Automatic optimization and hashing

**Configuration**:
```javascript
{
  base: '/better_structure_sql/',  // GitHub Pages subpath
  plugins: [react()],
  build: {
    outDir: 'dist',
    sourcemap: true,
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom', 'react-router-dom'],
          ui: ['bootstrap']
        }
      }
    }
  }
}
```

### Routing System

**React Router v6** with Hash Mode
- **HashRouter**: `#/` prefix for GitHub Pages compatibility
- **Routes**: Declarative route configuration
- **Lazy Loading**: Code-split route components
- **Navigation**: Programmatic and declarative navigation
- **Nested Routes**: Hierarchical route structure

**Route Structure**:
```
#/                          → Home
#/install                   → Installation Guide
#/quick-start               → Quick Start
#/configuration             → Configuration
#/databases/postgresql      → PostgreSQL Guide
#/databases/mysql           → MySQL Guide
#/databases/sqlite          → SQLite Guide
#/features/schema-versioning → Schema Versioning
#/features/multi-file       → Multi-File Output
#/features/web-engine       → Web Engine
#/features/advanced         → Advanced Features
#/production/deployment     → Production Deployment
#/production/after-migrate  → Post-Migration Workflow
#/production/engine-access  → Engine Access
#/examples                  → Examples
#/api                       → API Reference
```

### State Management

**Minimal State** - Leverage React built-ins:
- **Context API**: Theme preferences, user settings
- **useState**: Local component state
- **useEffect**: Side effects and data fetching
- **useNavigate**: Programmatic navigation
- **useLocation**: Current route information

No Redux/MobX needed for documentation site.

### Styling Architecture

**Bootstrap 5 with Darkly Theme**
- **Framework**: Bootstrap 5.3+
- **Theme**: Bootswatch Darkly
- **Customization**: CSS variables override
- **Components**: Bootstrap components (Cards, Nav, Buttons)
- **Icons**: Bootstrap Icons via CDN
- **Responsive**: Mobile-first grid system

**Custom CSS Organization**:
```
src/
├── styles/
│   ├── main.css          # Global styles
│   ├── variables.css     # CSS custom properties
│   ├── utilities.css     # Utility classes
│   └── components/       # Component-specific styles
│       ├── header.css
│       ├── sidebar.css
│       └── code-block.css
```

### Component Design Patterns

#### 1. Layout Components
**Responsibility**: Page structure and navigation
- `Header.jsx`: Top navigation with logo, menu
- `Sidebar.jsx`: Contextual navigation for docs sections
- `Footer.jsx`: Links, copyright, version info

#### 2. Content Components
**Responsibility**: Display documentation content
- `FeatureCard.jsx`: Feature highlight cards
- `CodeBlock.jsx`: Syntax-highlighted code
- `DatabaseTabs.jsx`: Database-specific examples in tabs
- `ComparisonViewer.jsx`: Side-by-side schema comparison

#### 3. Interactive Components
**Responsibility**: User interaction and tools
- `ConfigGenerator.jsx`: Configuration builder form
- `SchemaVisualizer.jsx`: Multi-file schema tree view
- `FeatureMatrix.jsx`: Database compatibility table
- `SearchBar.jsx`: Full-text documentation search

#### 4. Utility Components
**Responsibility**: Reusable utilities
- `ErrorBoundary.jsx`: Error handling
- `ScrollToTop.jsx`: Reset scroll on navigation
- `LazyLoad.jsx`: Lazy loading wrapper

## Code Organization

### Directory Structure

```
site/
├── public/
│   ├── favicon.ico
│   ├── logo.svg
│   ├── images/
│   │   ├── hero-bg.jpg
│   │   └── screenshots/
│   └── data/              # Static JSON data
│       ├── examples.json
│       └── features.json
├── src/
│   ├── components/
│   │   ├── Layout/
│   │   │   ├── Header.jsx
│   │   │   ├── Sidebar.jsx
│   │   │   ├── Footer.jsx
│   │   │   └── Layout.jsx
│   │   ├── CodeBlock/
│   │   │   ├── CodeBlock.jsx
│   │   │   ├── CodeBlock.test.jsx
│   │   │   └── CodeBlock.module.css
│   │   ├── FeatureCard/
│   │   │   ├── FeatureCard.jsx
│   │   │   └── FeatureCard.test.jsx
│   │   ├── DatabaseTabs/
│   │   │   ├── DatabaseTabs.jsx
│   │   │   └── DatabaseTabs.test.jsx
│   │   ├── ConfigGenerator/
│   │   │   ├── ConfigGenerator.jsx
│   │   │   └── ConfigGenerator.test.jsx
│   │   └── SchemaVisualizer/
│   │       ├── SchemaVisualizer.jsx
│   │       └── SchemaVisualizer.test.jsx
│   ├── pages/
│   │   ├── Home.jsx
│   │   ├── GettingStarted/
│   │   │   ├── Installation.jsx
│   │   │   ├── Configuration.jsx
│   │   │   └── QuickStart.jsx
│   │   ├── Databases/
│   │   │   ├── PostgreSQL.jsx
│   │   │   ├── MySQL.jsx
│   │   │   └── SQLite.jsx
│   │   ├── Features/
│   │   │   ├── SchemaVersioning.jsx
│   │   │   ├── MultiFileOutput.jsx
│   │   │   ├── WebEngine.jsx
│   │   │   └── AdvancedFeatures.jsx
│   │   ├── Production/
│   │   │   ├── Deployment.jsx
│   │   │   ├── AfterMigrate.jsx
│   │   │   └── EngineAccess.jsx
│   │   ├── Examples.jsx
│   │   └── API.jsx
│   ├── hooks/
│   │   ├── useTheme.js
│   │   ├── useSearch.js
│   │   └── useCodeCopy.js
│   ├── utils/
│   │   ├── codeFormatter.js
│   │   ├── syntaxHighlighter.js
│   │   └── analytics.js
│   ├── styles/
│   │   ├── main.css
│   │   ├── variables.css
│   │   └── components/
│   ├── App.jsx
│   ├── main.jsx
│   └── routes.jsx
├── tests/
│   ├── components/
│   ├── pages/
│   ├── utils/
│   └── setup.js
├── .eslintrc.json
├── .prettierrc
├── vite.config.js
├── vitest.config.js
├── package.json
└── README.md
```

## Data Flow

### Static Data Loading

```
JSON Files → Import in Components → Render
```

Example:
```javascript
// public/data/features.json
{
  "features": [
    {
      "id": "schema-versioning",
      "title": "Schema Versioning",
      "description": "Store and retrieve schema snapshots",
      "icon": "archive"
    }
  ]
}

// src/pages/Home.jsx
import features from '../data/features.json';

function Home() {
  return (
    <>
      {features.map(feature => (
        <FeatureCard key={feature.id} {...feature} />
      ))}
    </>
  );
}
```

### Component Communication

- **Props**: Parent to child data flow
- **Context**: Cross-cutting concerns (theme, user prefs)
- **Custom Hooks**: Shared stateful logic
- **Events**: Child to parent communication

## Testing Architecture

### Test Types

**1. Unit Tests** - Individual component logic
```javascript
// tests/components/FeatureCard.test.jsx
import { render, screen } from '@testing-library/react';
import FeatureCard from '../../src/components/FeatureCard/FeatureCard';

test('renders feature card with title', () => {
  render(<FeatureCard title="Test" description="Desc" />);
  expect(screen.getByText('Test')).toBeInTheDocument();
});
```

**2. Integration Tests** - Page-level behavior
```javascript
// tests/pages/Home.test.jsx
import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import Home from '../../src/pages/Home';

test('home page renders hero section', () => {
  render(
    <MemoryRouter>
      <Home />
    </MemoryRouter>
  );
  expect(screen.getByRole('heading', { level: 1 })).toBeInTheDocument();
});
```

**3. Snapshot Tests** - UI regression prevention
```javascript
test('feature card matches snapshot', () => {
  const { container } = render(<FeatureCard title="Test" />);
  expect(container).toMatchSnapshot();
});
```

### Test Coverage Requirements

- **Components**: 90%+ coverage
- **Pages**: 80%+ coverage
- **Utils**: 95%+ coverage
- **Overall**: 85%+ coverage

### Testing Tools

- **Vitest**: Test runner (Vite-native, fast)
- **React Testing Library**: Component testing
- **@testing-library/jest-dom**: Custom matchers
- **@testing-library/user-event**: User interaction simulation
- **happy-dom**: Lightweight DOM implementation

## Build and Deployment Pipeline

### Local Development

```bash
# Install dependencies
npm install

# Start dev server with HMR
npm run dev

# Run linter
npm run lint

# Run tests with watch mode
npm test

# Check test coverage
npm run test:coverage

# Format code
npm run format
```

### CI/CD Pipeline (GitHub Actions)

```
┌──────────────────┐
│  Push to main    │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Checkout code   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Setup Node.js   │
│  (cache npm)     │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  npm ci          │
│  (clean install) │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  npm run lint    │
│  (ESLint check)  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  npm test        │
│  (run all tests) │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  npm run build   │
│  (Vite bundle)   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Deploy to       │
│  GitHub Pages    │
└──────────────────┘
```

### Build Optimization

**Code Splitting**:
- Route-based: Each page loaded on-demand
- Vendor splitting: React libs separate bundle
- Dynamic imports: Heavy components lazy-loaded

**Asset Optimization**:
- Image compression and WebP conversion
- CSS minification and purging
- JS minification with Terser
- Gzip/Brotli compression

**Performance**:
- Tree shaking for unused code removal
- Bundle size analysis with `rollup-plugin-visualizer`
- Lighthouse CI for performance monitoring

## Accessibility

### Standards Compliance

**WCAG 2.1 Level AA**:
- Semantic HTML5 elements
- ARIA labels where needed
- Keyboard navigation support
- Focus management
- Color contrast ratios (4.5:1 minimum)
- Alt text for images
- Skip to content link

### Testing

- **axe-core**: Automated accessibility testing
- **eslint-plugin-jsx-a11y**: JSX accessibility linting
- **Manual testing**: Screen reader testing (NVDA, VoiceOver)

## SEO Optimization

### Meta Tags

```javascript
// src/components/SEO.jsx
import { Helmet } from 'react-helmet-async';

function SEO({ title, description, path }) {
  return (
    <Helmet>
      <title>{title} | BetterStructureSql</title>
      <meta name="description" content={description} />
      <meta property="og:title" content={title} />
      <meta property="og:description" content={description} />
      <meta property="og:url" content={`https://example.com${path}`} />
      <meta property="og:type" content="website" />
      <link rel="canonical" href={`https://example.com${path}`} />
    </Helmet>
  );
}
```

### Sitemap Generation

Static sitemap.xml generated during build process listing all routes.

### Analytics Integration

Google Analytics 4 or Plausible for privacy-friendly analytics.

## Error Handling

### Error Boundaries

```javascript
// src/components/ErrorBoundary.jsx
class ErrorBoundary extends React.Component {
  state = { hasError: false, error: null };

  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  componentDidCatch(error, errorInfo) {
    console.error('Error caught:', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return <ErrorPage error={this.state.error} />;
    }
    return this.props.children;
  }
}
```

### 404 Handling

Custom 404 page for invalid routes with navigation back to home.

## Performance Targets

### Lighthouse Scores
- **Performance**: 95+
- **Accessibility**: 100
- **Best Practices**: 95+
- **SEO**: 100

### Load Times
- **First Contentful Paint**: < 1.5s
- **Time to Interactive**: < 3.5s
- **Total Page Size**: < 500KB (gzipped)
- **Bundle Size**: < 300KB JS (main + vendor)

## Dependencies

### Core
- `react` (^18.2.0)
- `react-dom` (^18.2.0)
- `react-router-dom` (^6.20.0)

### UI
- `bootstrap` (^5.3.2)
- `bootswatch` (^5.3.2)
- `react-bootstrap` (^2.9.0) - Optional wrapper components
- `bootstrap-icons` (^1.11.0)

### Code Display
- `react-syntax-highlighter` (^15.5.0)
- `prismjs` (^1.29.0)

### Build Tools
- `vite` (^5.0.0)
- `@vitejs/plugin-react` (^4.2.0)

### Testing
- `vitest` (^1.0.0)
- `@testing-library/react` (^14.0.0)
- `@testing-library/jest-dom` (^6.1.0)
- `@testing-library/user-event` (^14.5.0)
- `happy-dom` (^12.10.0)

### Linting/Formatting
- `eslint` (^8.54.0)
- `eslint-plugin-react` (^7.33.0)
- `eslint-plugin-react-hooks` (^4.6.0)
- `eslint-plugin-jsx-a11y` (^6.8.0)
- `eslint-config-airbnb` (^19.0.0)
- `prettier` (^3.1.0)

### Utilities
- `react-helmet-async` (^2.0.0) - SEO meta tags
- `copy-to-clipboard` (^3.3.0) - Code copy functionality

## Security Considerations

### Content Security Policy

```html
<meta http-equiv="Content-Security-Policy"
      content="default-src 'self';
               script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net;
               style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net;
               img-src 'self' data: https:;">
```

### Dependency Auditing

```bash
npm audit
npm audit fix
```

Run regularly via GitHub Actions.

### HTTPS Enforcement

GitHub Pages automatically serves via HTTPS.

## Maintenance and Updates

### Version Management
- Semantic versioning for site releases
- CHANGELOG.md for site changes
- Git tags for site versions

### Dependency Updates
- Dependabot for automated dependency PRs
- Monthly dependency review
- Major version upgrades planned and tested

### Content Updates
- Documentation synced with gem releases
- API reference auto-generated from gem code
- Example code validated against gem functionality

## Keywords

React architecture, component hierarchy, Vite build system, React Router hash mode, HashRouter configuration, Bootstrap Darkly integration, Bootswatch theming, ESLint Airbnb config, React Testing Library, Vitest test runner, component testing strategy, test coverage requirements, GitHub Actions deployment pipeline, static site generation, code splitting optimization, lazy loading routes, bundle size optimization, CSS-in-JS alternatives, CSS modules, accessibility WCAG compliance, SEO meta tags, OpenGraph social sharing, sitemap generation, error boundary pattern, 404 handling, performance budgets, Lighthouse metrics, dependency management, security CSP, dependency auditing, responsive design mobile-first, Bootstrap grid system, utility classes, custom CSS variables, theme customization, syntax highlighting Prism, code block components, interactive demos, configuration generator UI, schema visualizer component, database tabs component, feature card design pattern, layout components, reusable UI patterns, hooks architecture, custom React hooks, state management Context API, data flow unidirectional, static JSON data, props drilling alternatives, component composition, render props, higher-order components, testing snapshots, integration testing, unit testing best practices, mock service worker, CI/CD automation, deployment workflow, build optimization, asset optimization, image compression, WebP format, gzip compression, tree shaking, dead code elimination, vendor chunking, route-based splitting
