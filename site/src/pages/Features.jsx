import { Link } from 'react-router-dom';
import Seo from '../components/Seo/Seo';
import CodeBlock from '../components/CodeBlock/CodeBlock';

function Features() {
  return (
    <>
      <Seo
        title="Features"
        description="BetterStructureSql rake tasks, schema versioning web UI, automatic schema storage and multi-file schema output."
      />

      <div className="container py-5">
        <div className="row">
          <div className="col-lg-10 offset-lg-1">
            <h1 className="mb-4">
              <i className="bi bi-stars me-2" />
              Features
            </h1>
            <p className="lead">
              Powerful features for managing database schemas across PostgreSQL, MySQL, and SQLite
            </p>

            {/* Rake Tasks */}
            <section className="mb-5">
              <h2 className="mb-3">
                <i className="bi bi-terminal me-2" />
                Rake Tasks
              </h2>
              <p>BetterStructureSql provides a comprehensive set of Rake tasks for schema management:</p>

              <div className="row">
                <div className="col-md-6 mb-3">
                  <div className="card h-100">
                    <div className="card-header">
                      <h5 className="mb-0">
                        <i className="bi bi-download me-2" />
                        db:schema:dump_better
                      </h5>
                    </div>
                    <div className="card-body">
                      <p>Explicitly dump schema using BetterStructureSql to <code>db/structure.sql</code> or <code>db/schema</code> directory.</p>
                      <CodeBlock language="bash">
                        rails db:schema:dump_better
                      </CodeBlock>
                      <small className="text-muted">
                        Use this for explicit dumps. Enable <code>replace_default_dump</code> to use <code>db:schema:dump</code> instead.
                      </small>
                    </div>
                  </div>
                </div>

                <div className="col-md-6 mb-3">
                  <div className="card h-100">
                    <div className="card-header">
                      <h5 className="mb-0">
                        <i className="bi bi-upload me-2" />
                        db:schema:load_better
                      </h5>
                    </div>
                    <div className="card-body">
                      <p>Load schema from file or directory. Automatically detects single-file vs multi-file mode.</p>
                      <CodeBlock language="bash">
                        rails db:schema:load_better
                      </CodeBlock>
                      <small className="text-muted">
                        Supports both <code>db/structure.sql</code> (single file) and <code>db/schema/</code> (directory with manifest).
                      </small>
                    </div>
                  </div>
                </div>

                <div className="col-md-6 mb-3">
                  <div className="card h-100 border-primary">
                    <div className="card-header bg-primary text-white">
                      <h5 className="mb-0">
                        <i className="bi bi-floppy me-2" />
                        db:schema:store
                      </h5>
                    </div>
                    <div className="card-body">
                      <p><strong>Store current schema as a version in the database.</strong></p>
                      <CodeBlock language="bash">
                        rails db:schema:store
                      </CodeBlock>
                      <p className="mb-2">This command:</p>
                      <ul className="small">
                        <li>Reads the dumped schema at <code>output_path</code> (it does not dump)</li>
                        <li>Skips storage when the content hash matches the latest version</li>
                        <li>Stores in <code>better_structure_sql_schema_versions</code> table</li>
                        <li>Includes metadata: format, mode, DB version, file count</li>
                        <li>Creates a ZIP archive for multi-file schemas; the directory on disk is left untouched</li>
                        <li>Manages retention (keeps last N versions)</li>
                      </ul>
                    </div>
                  </div>
                </div>

                <div className="col-md-6 mb-3">
                  <div className="card h-100">
                    <div className="card-header">
                      <h5 className="mb-0">
                        <i className="bi bi-list-ul me-2" />
                        db:schema:versions
                      </h5>
                    </div>
                    <div className="card-body">
                      <p>List all stored schema versions with metadata.</p>
                      <CodeBlock language="bash">
                        rails db:schema:versions
                      </CodeBlock>
                      <p className="mb-1">Example output:</p>
                      <CodeBlock language="text">
{`Schema Versions (2 total)

ID   | Format | Mode        | Files | PostgreSQL | Hash     | Created             | Size
-----------------------------------------------------------------------------------------
5    | sql    | multi_file  | 47    | 15.3       | 9f2c41ab | 2025-01-15 10:30:12 | 182.40 KB
4    | sql    | single_file | -     | 15.3       | 03be77d1 | 2025-01-14 15:20:44 | 175.12 KB`}
                      </CodeBlock>
                    </div>
                  </div>
                </div>

                <div className="col-md-6 mb-3">
                  <div className="card h-100">
                    <div className="card-header">
                      <h5 className="mb-0">
                        <i className="bi bi-arrow-counterclockwise me-2" />
                        db:schema:restore[VERSION_ID]
                      </h5>
                    </div>
                    <div className="card-body">
                      <p>
                        Replace the database schema with a stored version. The database is purged
                        first: every table and all data are dropped, the stored versions included.
                      </p>
                      <CodeBlock language="bash">
{`# Restore from version 5
CONFIRM=1 rails db:schema:restore[5]

# Or using environment variable
CONFIRM=1 VERSION_ID=5 rails db:schema:restore`}
                      </CodeBlock>
                      <small className="text-muted">
                        Needs <code>CONFIRM=1</code> and refuses protected environments such as
                        production. Handles single-file and multi-file (ZIP) schemas.
                      </small>
                    </div>
                  </div>
                </div>

                <div className="col-md-6 mb-3">
                  <div className="card h-100">
                    <div className="card-header">
                      <h5 className="mb-0">
                        <i className="bi bi-trash me-2" />
                        db:schema:cleanup
                      </h5>
                    </div>
                    <div className="card-body">
                      <p>Remove old schema versions based on retention limit.</p>
                      <CodeBlock language="bash">
                        rails db:schema:cleanup
                      </CodeBlock>
                      <small className="text-muted">
                        Respects <code>schema_versions_limit</code> config. Set to 0 for unlimited retention.
                        Retention is also applied automatically each time a version is stored.
                      </small>
                    </div>
                  </div>
                </div>
              </div>
            </section>

            {/* Web UI Engine */}
            <section className="mb-5">
              <h2 className="mb-3">
                <i className="bi bi-window me-2" />
                Web UI Engine
              </h2>
              <p>
                BetterStructureSql includes a mountable Rails Engine that provides a web interface
                for browsing and downloading stored schema versions.
              </p>

              <h3 className="mt-4 mb-3">Mounting the Engine</h3>
              <p>Add to your <code>config/routes.rb</code>:</p>

              <div className="card mb-3">
                <div className="card-header">
                  <strong>Basic Mount (Development)</strong>
                </div>
                <div className="card-body">
                  <CodeBlock language="ruby">
{`# config/routes.rb
Rails.application.routes.draw do
  mount BetterStructureSql::Engine, at: '/schema_versions'
end`}
                  </CodeBlock>
                  <p className="mb-0 mt-2">
                    <i className="bi bi-link-45deg me-1" />
                    Access at: <code>http://localhost:3000/schema_versions</code>
                  </p>
                </div>
              </div>

              <h3 className="mt-4 mb-3">Authentication (Production)</h3>
              <div className="alert alert-warning">
                <i className="bi bi-shield-lock me-2" />
                The UI shows your whole schema, so it <strong>fails closed</strong>: outside
                development and test every request gets <code>403 Forbidden</code> until you declare
                how access is controlled, using one of the options below.
              </div>

              <div className="card mb-3">
                <div className="card-header">
                  <strong>Option 1: Check access in the engine</strong>
                </div>
                <div className="card-body">
                  <CodeBlock language="ruby" filename="config/initializers/better_structure_sql.rb">
{`BetterStructureSql::Engine.authenticate_with do |controller|
  controller.request.env['warden']&.user&.admin?
end`}
                  </CodeBlock>
                  <p className="mb-0">
                    The block receives the controller. A falsy result answers <code>403 Forbidden</code>.
                  </p>
                </div>
              </div>

              <div className="card mb-3">
                <div className="card-header">
                  <strong>Option 2: Restrict the routes (Devise shown)</strong>
                </div>
                <div className="card-body">
                  <CodeBlock language="ruby">
{`# config/routes.rb
authenticate :user, ->(user) { user.admin? } do
  mount BetterStructureSql::Engine, at: '/schema_versions'
end

# config/initializers/better_structure_sql.rb
# Tell the engine the routes already restrict access
BetterStructureSql::Engine.authentication_handled_by_routes!`}
                  </CodeBlock>
                  <p className="mb-0">
                    Any route constraint works the same way, for example a class with a{' '}
                    <code>matches?(request)</code> method passed to <code>constraints</code>.
                  </p>
                </div>
              </div>

              <h3 className="mt-4 mb-3">Engine Routes</h3>
              <p>Relative to the mount point:</p>
              <div className="table-responsive">
                <table className="table table-sm">
                  <thead>
                    <tr>
                      <th scope="col">Route</th>
                      <th scope="col">Purpose</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td><code>GET /</code>, <code>GET /schema_versions</code></td>
                      <td>Paginated list of stored versions</td>
                    </tr>
                    <tr>
                      <td><code>GET /schema_versions/:id</code></td>
                      <td>Version details and inline schema</td>
                    </tr>
                    <tr>
                      <td><code>GET /schema_versions/:id/raw</code></td>
                      <td>Schema as plain text</td>
                    </tr>
                    <tr>
                      <td><code>GET /schema_versions/:id/download</code></td>
                      <td>File download (ZIP archive for multi-file versions)</td>
                    </tr>
                  </tbody>
                </table>
              </div>

              <h3 className="mt-4 mb-3">Engine Features</h3>
              <div className="row">
                <div className="col-md-4 mb-3">
                  <div className="card h-100">
                    <div className="card-body text-center">
                      <i className="bi bi-list-columns display-4 text-primary" />
                      <h5 className="mt-3">Browse Versions</h5>
                      <p className="text-muted">
                        Paginated list of stored schema versions with metadata (date, size, database version, format)
                      </p>
                    </div>
                  </div>
                </div>

                <div className="col-md-4 mb-3">
                  <div className="card h-100">
                    <div className="card-body text-center">
                      <i className="bi bi-code-slash display-4 text-success" />
                      <h5 className="mt-3">View Schema</h5>
                      <p className="text-muted">
                        Read the stored schema inline (very large schemas are offered as downloads) and copy it to the clipboard
                      </p>
                    </div>
                  </div>
                </div>

                <div className="col-md-4 mb-3">
                  <div className="card h-100">
                    <div className="card-body text-center">
                      <i className="bi bi-download display-4 text-info" />
                      <h5 className="mt-3">Download</h5>
                      <p className="text-muted">
                        Download raw SQL/Ruby files or ZIP archives for multi-file schemas
                      </p>
                    </div>
                  </div>
                </div>
              </div>

              <div className="alert alert-info mt-3">
                <i className="bi bi-people me-2" />
                <strong>Developer Onboarding:</strong> New team members can access the latest
                schema without database credentials or running migrations.
              </div>
            </section>

            {/* Automatic Workflows */}
            <section className="mb-5">
              <h2 className="mb-3">
                <i className="bi bi-arrow-repeat me-2" />
                Automatic Schema Storage Workflows
              </h2>
              <p>Automate schema version storage after migrations:</p>

              <div className="row">
                <div className="col-md-6 mb-3">
                  <div className="card h-100">
                    <div className="card-header bg-success text-white">
                      <h5 className="mb-0">
                        <i className="bi bi-terminal me-2" />
                        Option 1: Manual Chain
                      </h5>
                    </div>
                    <div className="card-body">
                      <p><strong>Run after each migration:</strong></p>
                      <CodeBlock language="bash">
                        rails db:migrate && rails db:schema:dump_better && rails db:schema:store
                      </CodeBlock>
                      <p className="mb-0 text-muted">
                        Simple and explicit. Recommended for development.
                      </p>
                    </div>
                  </div>
                </div>

                <div className="col-md-6 mb-3">
                  <div className="card h-100">
                    <div className="card-header bg-primary text-white">
                      <h5 className="mb-0">
                        <i className="bi bi-git me-2" />
                        Option 2: Git Hook
                      </h5>
                    </div>
                    <div className="card-body">
                      <p><strong>Auto-store on git pull/merge:</strong></p>
                      <CodeBlock language="bash">
{`# .git/hooks/post-merge
#!/bin/bash
if git diff HEAD@{1} --name-only | grep -q "db/migrate"; then
  echo "Migrations detected, storing schema..."
  rails db:migrate && rails db:schema:dump_better && rails db:schema:store
fi

chmod +x .git/hooks/post-merge`}
                      </CodeBlock>
                    </div>
                  </div>
                </div>

                <div className="col-md-12 mb-3">
                  <div className="card">
                    <div className="card-header bg-warning text-dark">
                      <h5 className="mb-0">
                        <i className="bi bi-gear me-2" />
                        Option 3: CI/CD Pipeline
                      </h5>
                    </div>
                    <div className="card-body">
                      <p><strong>Auto-store in deployment pipeline (dump first; store reads the dumped schema):</strong></p>
                      <CodeBlock language="yaml">
{`# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
      - name: Install dependencies
        run: bundle install
      - name: Run migrations and store schema
        run: |
          rails db:migrate RAILS_ENV=production
          rails db:schema:dump_better RAILS_ENV=production
          rails db:schema:store RAILS_ENV=production`}
                      </CodeBlock>
                      <p className="mb-0 text-muted">
                        Recommended for production. Ensures schema is always versioned.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </section>

            {/* Multi-File Schema */}
            <section className="mb-5">
              <h2 className="mb-3">
                <i className="bi bi-folder2-open me-2" />
                Multi-File Schema Output
              </h2>
              <p>
                For large schemas (100+ tables), use directory-based output for better organization,
                git diffs, and AI/LLM-friendly navigation.
              </p>

              <div className="card mb-3">
                <div className="card-header">
                  <strong>Enable Multi-File Mode</strong>
                </div>
                <div className="card-body">
                  <CodeBlock language="ruby">
{`# config/initializers/better_structure_sql.rb
BetterStructureSql.configure do |config|
  # Use directory instead of single file
  config.output_path = 'db/schema'

  # Optional: Customize chunking
  config.max_lines_per_file = 500        # ~500 lines per file
  config.overflow_threshold = 1.1        # Allow 10% overflow
  config.generate_manifest = true        # Create _manifest.json
end`}
                  </CodeBlock>
                </div>
              </div>

              <div className="row">
                <div className="col-md-6">
                  <h5>Benefits</h5>
                  <ul>
                    <li>Memory efficient - incremental file writing</li>
                    <li>Git friendly - only changed files in diffs</li>
                    <li>Easy navigation - organized by object type</li>
                    <li>AI-friendly - 500-line chunks fit in LLM context windows</li>
                    <li>Scalable - built for schemas with thousands of objects</li>
                    <li>ZIP downloads - complete schema as single archive</li>
                  </ul>
                </div>
                <div className="col-md-6">
                  <h5>Directory Structure</h5>
                  <CodeBlock language="text">
{`db/schema/
├── _header.sql
├── _manifest.json
├── 01_extensions/
│   └── 000001.sql
├── 02_types/
├── 03_functions/
├── 04_sequences/
├── 05_tables/
│   ├── 000001.sql
│   ├── 000002.sql
│   └── 000003.sql
├── 06_indexes/
├── 07_foreign_keys/
├── 08_views/
├── 09_triggers/
├── 10_comments/
└── 20_migrations/`}
                  </CodeBlock>
                </div>
              </div>
            </section>

            {/* Next Steps */}
            <div className="alert alert-primary">
              <h4 className="alert-heading">
                <i className="bi bi-rocket me-2" />
                Get Started
              </h4>
              <hr />
              <p className="mb-0">
                Ready to use these features?{' '}
                <Link to="/install" className="alert-link">Install BetterStructureSql</Link>
                {' '}and configure it for your project.
              </p>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}

export default Features;
