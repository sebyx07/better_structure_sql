# Phase 3: API Reference, Polish, and Optimization

## Objective

Complete the documentation site with API reference, enhance UX with search functionality, optimize performance with esbuild bundling, ensure accessibility compliance, and finalize deployment to GitHub Pages.

## Deliverables

### 1. API Reference Page

**API Documentation** (`src/pages/API.jsx`):

Comprehensive API reference organized by category:

#### Configuration API

```ruby
# All configuration options with types and defaults
BetterStructureSql.configure do |config|
  # Output Configuration
  config.output_path = 'db/structure.sql'        # String, default: 'db/structure.sql'
  config.max_lines_per_file = 500                # Integer, default: 500 (multi-file mode)
  config.overflow_threshold = 1.1                # Float, default: 1.1 (10% overflow)
  config.generate_manifest = true                # Boolean, default: true

  # Feature Toggles
  config.include_extensions = true               # Boolean, default: true
  config.include_functions = true                # Boolean, default: true
  config.include_triggers = true                 # Boolean, default: true
  config.include_views = true                    # Boolean, default: true
  config.include_materialized_views = true       # Boolean, default: true
  config.include_domains = true                  # Boolean, default: true
  config.include_sequences = true                # Boolean, default: true
  config.include_custom_types = true             # Boolean, default: true

  # Schema Versioning
  config.enable_schema_versions = false          # Boolean, default: false
  config.schema_versions_limit = 10              # Integer, default: 10 (0 = unlimited)

  # Database-Specific
  config.search_path = '"$user", public'         # String (PostgreSQL)
  config.adapter = nil                           # Symbol: :postgresql, :mysql, :sqlite (auto-detect if nil)

  # Rails Integration
  config.replace_default_dump = false            # Boolean, default: false
end
```

#### Rake Tasks API

```bash
# Dump schema to structure.sql (or configured output path)
rake db:schema:dump_better

# Load schema from structure.sql (or configured output path)
rake db:schema:load_better

# Store current schema as version in database
rake db:schema:store

# List all stored schema versions
rake db:schema:versions

# Cleanup old versions (keep last N per retention limit)
rake db:schema:cleanup

# Restore schema from specific version
rake db:schema:restore[VERSION_ID]
```

#### Programmatic API

```ruby
# Dump schema programmatically
dumper = BetterStructureSql::Dumper.new
dumper.dump  # Writes to configured output_path

# Store schema version
BetterStructureSql::SchemaVersions.store

# Retrieve schema versions
versions = BetterStructureSql::SchemaVersion.all.order(created_at: :desc)
latest = BetterStructureSql::SchemaVersion.latest

# Load specific version
version = BetterStructureSql::SchemaVersion.find(id)
loader = BetterStructureSql::SchemaLoader.new
loader.load_from_version(version)

# Adapter API (advanced usage)
adapter = BetterStructureSql::Adapters::Registry.adapter_for_connection(
  ActiveRecord::Base.connection
)
tables = adapter.fetch_tables
indexes = adapter.fetch_indexes
supports_views = adapter.supports_materialized_views?
```

#### Engine Routes API

```ruby
# Mount engine in routes.rb
mount BetterStructureSql::Engine => '/schema_versions'

# Available routes (automatically generated)
# GET /schema_versions              - List all versions
# GET /schema_versions/:id          - Show specific version
# GET /schema_versions/:id/raw      - Download raw text
# GET /schema_versions/:id/download - Download ZIP (multi-file)
```

#### ActiveRecord Model API

```ruby
# SchemaVersion model
class BetterStructureSql::SchemaVersion < ActiveRecord::Base
  # Attributes
  # - id: integer (primary key)
  # - content: text (single-file schemas)
  # - zip_archive: binary (multi-file schemas)
  # - pg_version: string (e.g., "PostgreSQL 15.3")
  # - format_type: string ('sql' or 'rb')
  # - output_mode: string ('single_file' or 'multi_file')
  # - file_count: integer (number of files in multi-file schema)
  # - created_at: datetime

  # Scopes
  scope :latest, -> { order(created_at: :desc).first }
  scope :sql_format, -> { where(format_type: 'sql') }
  scope :multi_file, -> { where(output_mode: 'multi_file') }

  # Instance methods
  def multi_file?
    output_mode == 'multi_file'
  end

  def file_list
    # Returns array of file paths for multi-file schemas
  end

  def extract_to(directory)
    # Extracts ZIP archive to directory
  end
end
```

### 2. Search Functionality

**Search Component** (`src/components/Search/Search.jsx`):

Simple client-side search using static index:
- Search across all page content
- Keyboard shortcut (Ctrl+K or Cmd+K)
- Instant results as you type
- Navigate to results with arrow keys
- Minimal UI (modal overlay)

Implementation:
```javascript
// Pre-build search index from all content
const searchIndex = [
  {
    title: 'Schema Versioning',
    path: '/features/schema-versioning',
    content: 'Store schema snapshots...',
    keywords: ['versioning', 'history', 'audit']
  },
  // ...
];

// Simple fuzzy matching
function search(query) {
  const lowerQuery = query.toLowerCase();
  return searchIndex.filter(item =>
    item.title.toLowerCase().includes(lowerQuery) ||
    item.content.toLowerCase().includes(lowerQuery) ||
    item.keywords.some(kw => kw.includes(lowerQuery))
  );
}
```

### 3. Build Optimization with esbuild

**Replace Vite with esbuild** for faster builds and smaller files:

**Build script** (`scripts/build.js`):

```javascript
const esbuild = require('esbuild');
const { htmlPlugin } = require('@craftamap/esbuild-plugin-html');

esbuild.build({
  entryPoints: ['src/main.jsx'],
  bundle: true,
  minify: true,
  splitting: true,
  format: 'esm',
  target: ['es2020'],
  outdir: 'dist',
  publicPath: '/better_structure_sql',
  loader: {
    '.js': 'jsx',
    '.jsx': 'jsx',
    '.css': 'css',
    '.svg': 'file',
    '.png': 'file',
    '.jpg': 'file',
  },
  plugins: [
    htmlPlugin({
      files: [
        {
          entryPoints: ['src/main.jsx'],
          filename: 'index.html',
          htmlTemplate: 'public/index.html',
        },
      ],
    }),
  ],
  define: {
    'process.env.NODE_ENV': '"production"',
  },
}).catch(() => process.exit(1));
```

**Dev server** (`scripts/dev.js`):

```javascript
const esbuild = require('esbuild');
const { createServer } = require('http');
const { spawn } = require('child_process');

// esbuild serve with live reload
esbuild.serve(
  {
    servedir: 'public',
    port: 3000,
  },
  {
    entryPoints: ['src/main.jsx'],
    bundle: true,
    outdir: 'public/dist',
    loader: { '.js': 'jsx', '.jsx': 'jsx' },
  }
).then(server => {
  console.log(`Dev server running at http://localhost:3000`);
});
```

**Package.json scripts**:
```json
{
  "scripts": {
    "dev": "node scripts/dev.js",
    "build": "node scripts/build.js",
    "test": "vitest",
    "lint": "eslint src --ext .js,.jsx",
    "format": "prettier --write \"src/**/*.{js,jsx,json,css}\""
  }
}
```

Benefits of esbuild:
- 10-100x faster than Webpack/Vite
- Simpler configuration (single build.js file)
- Smaller bundle sizes
- Native ESM support
- Works great with React

### 4. Code Quality and SOLID Principles

**File Size Guidelines**:
- Components: Max 200 lines
- Pages: Max 300 lines
- Utilities: Max 150 lines
- Extract large components into smaller pieces

**SOLID in React**:

**Single Responsibility**:
```javascript
// ❌ Bad: Component does too much
function UserProfile() {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  // ... fetch logic
  // ... render logic
  // ... error handling
}

// ✅ Good: Separate concerns
function UserProfile() {
  const { user, loading, error } = useUser();
  if (loading) return <LoadingSpinner />;
  if (error) return <ErrorMessage error={error} />;
  return <UserProfileView user={user} />;
}
```

**Open/Closed Principle**:
```javascript
// ✅ Extensible via props, not modification
function CodeBlock({ language, code, showLineNumbers = false, theme = 'darkly' }) {
  return (
    <SyntaxHighlighter
      language={language}
      style={theme === 'darkly' ? darkly : light}
      showLineNumbers={showLineNumbers}
    >
      {code}
    </SyntaxHighlighter>
  );
}
```

**Dependency Inversion**:
```javascript
// ✅ Depend on abstractions (props/context), not concrete implementations
function FeatureList({ features, FeatureComponent = FeatureCard }) {
  return features.map(feature => (
    <FeatureComponent key={feature.id} {...feature} />
  ));
}
```

**Component Organization**:
```
src/components/CodeBlock/
├── CodeBlock.jsx          # Main component (50 lines)
├── CopyButton.jsx         # Copy functionality (30 lines)
├── LineNumbers.jsx        # Line number display (40 lines)
├── CodeBlock.test.jsx     # Tests
└── index.js               # Exports
```

### 5. Accessibility Enhancements

**WCAG 2.1 Level AA Compliance**:

**Semantic HTML**:
```jsx
// ✅ Use proper heading hierarchy
<article>
  <h1>Schema Versioning</h1>
  <section>
    <h2>Configuration</h2>
    <p>...</p>
  </section>
  <section>
    <h2>Usage</h2>
    <p>...</p>
  </section>
</article>
```

**Keyboard Navigation**:
```jsx
// ✅ Keyboard-accessible tabs
function DatabaseTabs({ tabs, activeTab, onChange }) {
  return (
    <div role="tablist">
      {tabs.map((tab, index) => (
        <button
          key={tab.id}
          role="tab"
          aria-selected={activeTab === tab.id}
          tabIndex={activeTab === tab.id ? 0 : -1}
          onClick={() => onChange(tab.id)}
          onKeyDown={(e) => {
            if (e.key === 'ArrowRight') onChange(tabs[index + 1]?.id);
            if (e.key === 'ArrowLeft') onChange(tabs[index - 1]?.id);
          }}
        >
          {tab.label}
        </button>
      ))}
    </div>
  );
}
```

**ARIA Labels**:
```jsx
// ✅ Screen reader support
<nav aria-label="Main navigation">
  <ul>
    <li><Link to="/">Home</Link></li>
    <li><Link to="/docs">Documentation</Link></li>
  </ul>
</nav>

<button aria-label="Copy code to clipboard">
  <CopyIcon />
</button>
```

**Focus Management**:
```jsx
// ✅ Focus visible on keyboard navigation
.btn:focus-visible {
  outline: 2px solid #375a7f;
  outline-offset: 2px;
}
```

**Color Contrast**:
- Darkly theme already meets 4.5:1 ratio
- Verify custom colors with contrast checker
- Test with browser DevTools accessibility panel

### 6. Performance Optimization

**Code Splitting**:
```javascript
// Lazy load route components
import { lazy, Suspense } from 'react';

const Home = lazy(() => import('./pages/Home'));
const PostgreSQL = lazy(() => import('./pages/Databases/PostgreSQL'));

function App() {
  return (
    <Suspense fallback={<LoadingSpinner />}>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/databases/postgresql" element={<PostgreSQL />} />
      </Routes>
    </Suspense>
  );
}
```

**Image Optimization**:
```bash
# Compress images before adding to public/
npm install -g sharp-cli
sharp -i screenshot.png -o screenshot-optimized.png --webp
```

**Bundle Analysis**:
```javascript
// Add to esbuild config
const { metafile } = await esbuild.build({
  // ... config
  metafile: true,
});

// Analyze bundle
console.log(await esbuild.analyzeMetafile(metafile));
```

**Performance Budget**:
- Total bundle: < 300KB gzipped
- Main JS: < 150KB
- Vendor JS: < 100KB
- CSS: < 50KB
- First Load: < 2 seconds

### 7. SEO Enhancements

**Meta Tags Component** (`src/components/SEO/SEO.jsx`):

```jsx
import { Helmet } from 'react-helmet-async';

function SEO({
  title,
  description,
  path,
  image = '/logo-social.png',
  type = 'website'
}) {
  const siteUrl = 'https://YOUR_USERNAME.github.io/better_structure_sql';
  const fullUrl = `${siteUrl}${path}`;

  return (
    <Helmet>
      {/* Basic */}
      <title>{title} | BetterStructureSql</title>
      <meta name="description" content={description} />
      <link rel="canonical" href={fullUrl} />

      {/* Open Graph */}
      <meta property="og:title" content={title} />
      <meta property="og:description" content={description} />
      <meta property="og:url" content={fullUrl} />
      <meta property="og:type" content={type} />
      <meta property="og:image" content={`${siteUrl}${image}`} />

      {/* Twitter Card */}
      <meta name="twitter:card" content="summary_large_image" />
      <meta name="twitter:title" content={title} />
      <meta name="twitter:description" content={description} />
      <meta name="twitter:image" content={`${siteUrl}${image}`} />
    </Helmet>
  );
}
```

**Sitemap Generation** (`scripts/generate-sitemap.js`):

```javascript
const fs = require('fs');

const routes = [
  '/',
  '/install',
  '/configuration',
  '/databases/postgresql',
  '/databases/mysql',
  '/databases/sqlite',
  '/features/schema-versioning',
  '/features/multi-file',
  '/production/deployment',
  '/examples',
  '/api',
];

const sitemap = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${routes.map(route => `  <url>
    <loc>https://YOUR_USERNAME.github.io/better_structure_sql/#${route}</loc>
    <changefreq>weekly</changefreq>
    <priority>0.8</priority>
  </url>`).join('\n')}
</urlset>`;

fs.writeFileSync('public/sitemap.xml', sitemap);
```

### 8. GitHub Pages Deployment Configuration

**GitHub Pages Setup**:

1. **Enable GitHub Pages** in repository settings:
   - Source: gh-pages branch
   - Directory: / (root)

2. **GitHub Actions Workflow** (`.github/workflows/deploy-docs.yml`):

```yaml
name: Deploy Documentation Site

on:
  push:
    branches: [main]
    paths:
      - 'site/**'
      - '.github/workflows/deploy-docs.yml'
  workflow_dispatch:

permissions:
  contents: write

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    defaults:
      run:
        working-directory: ./site

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: site/package-lock.json

      - name: Install dependencies
        run: npm ci

      - name: Lint code
        run: npm run lint

      - name: Run tests
        run: npm test -- --run --coverage

      - name: Build site
        run: npm run build
        env:
          NODE_ENV: production

      - name: Generate sitemap
        run: node scripts/generate-sitemap.js

      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./site/dist
          publish_branch: gh-pages
          cname: # Optional: custom domain
```

**Custom Domain** (optional):

Create `public/CNAME` file:
```
docs.betterstructuresql.com
```

Configure DNS:
```
CNAME   docs   YOUR_USERNAME.github.io
```

### 9. Final Polish

**Loading States**:
```jsx
// Skeleton screens for better perceived performance
function PageSkeleton() {
  return (
    <div className="skeleton">
      <div className="skeleton-header" />
      <div className="skeleton-content" />
    </div>
  );
}
```

**Error Boundaries**:
```jsx
// Graceful error handling
class ErrorBoundary extends React.Component {
  state = { hasError: false };

  static getDerivedStateFromError(error) {
    return { hasError: true };
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="error-page">
          <h1>Oops! Something went wrong.</h1>
          <p>Try refreshing the page or return to <Link to="/">home</Link>.</p>
        </div>
      );
    }
    return this.props.children;
  }
}
```

**Smooth Scroll**:
```javascript
// Scroll to top on route change
function ScrollToTop() {
  const { pathname } = useLocation();

  useEffect(() => {
    window.scrollTo(0, 0);
  }, [pathname]);

  return null;
}
```

**Copy Feedback**:
```jsx
// Visual feedback when copying code
function CopyButton({ code }) {
  const [copied, setCopied] = useState(false);

  const handleCopy = () => {
    navigator.clipboard.writeText(code);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <button onClick={handleCopy} className="copy-btn">
      {copied ? 'Copied!' : 'Copy'}
    </button>
  );
}
```

## Testing Requirements

### Unit Tests
- API page renders all sections
- Search component filters results correctly
- SEO component generates correct meta tags
- Error boundary catches errors

### Performance Tests
- Lighthouse CI score > 90
- Bundle size < 300KB gzipped
- First Contentful Paint < 1.5s
- Time to Interactive < 3.5s

### Accessibility Tests
- All pages pass axe-core audit
- Keyboard navigation works throughout site
- ARIA labels present where needed
- Color contrast meets WCAG AA

### SEO Tests
- Meta tags present on all pages
- Sitemap includes all routes
- Canonical URLs set correctly
- Open Graph tags valid

## Success Criteria

- [x] API reference page complete and accurate
- [x] Search functionality works smoothly
- [x] esbuild bundling optimized for performance
- [x] All components follow SOLID principles
- [x] Files kept small and focused (< 300 lines)
- [x] WCAG 2.1 AA compliance achieved
- [x] Lighthouse score > 90 for all pages
- [x] Bundle size under 300KB
- [x] GitHub Pages deployment automated
- [x] SEO optimized with meta tags and sitemap
- [x] All tests pass with >85% coverage
- [x] Site live and accessible at GitHub Pages URL

## Phase Dependencies

Depends on Phase 2 (content pages, database guides, examples).

## Estimated Effort

**Development**: 3-4 days
- API reference page: 4 hours
- Search functionality: 4 hours
- esbuild migration: 3 hours
- Code refactoring for SOLID: 4 hours
- Accessibility enhancements: 4 hours
- Performance optimization: 3 hours
- SEO implementation: 3 hours
- GitHub Pages deployment: 2 hours
- Testing and polish: 5 hours

**Total**: ~32 hours
