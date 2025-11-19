import { Helmet } from 'react-helmet-async';
import CodeBlock from '../components/CodeBlock/CodeBlock';

function Features() {
  return (
    <>
      <Helmet>
        <title>Features - BetterStructureSql</title>
      </Helmet>

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
                        <li>Reads current schema (file or directory)</li>
                        <li>Stores in <code>better_structure_sql_schema_versions</code> table</li>
                        <li>Includes metadata: format, mode, DB version, file count</li>
                        <li>Creates ZIP archive for multi-file schemas</li>
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
{`ID     Format  Mode          Files   Database        Created
---------------------------------------------------------------------
5      sql     multi_file    47      PostgreSQL 15.3 2025-01-15 10:30
4      sql     single_file   1       MySQL 8.0       2025-01-14 15:20`}
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
                      <p>Restore database from a specific stored version.</p>
                      <CodeBlock language="bash">
{`# Restore from version 5
rails db:schema:restore[5]

# Or using environment variable
VERSION_ID=5 rails db:schema:restore`}
                      </CodeBlock>
                      <small className="text-muted">
                        Automatically handles single-file and multi-file (ZIP) schemas.
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
              <p>Secure the engine with authentication constraints:</p>

              <div className="accordion mb-4" id="authExamples">
                <div className="accordion-item">
                  <h2 className="accordion-header">
                    <button className="accordion-button" type="button" data-bs-toggle="collapse" data-bs-target="#deviseAuth">
                      <i className="bi bi-shield-lock me-2" />
                      Devise Authentication
                    </button>
                  </h2>
                  <div id="deviseAuth" className="accordion-collapse collapse show" data-bs-parent="#authExamples">
                    <div className="accordion-body">
                      <CodeBlock language="ruby">
{`# config/routes.rb
authenticate :user, ->(user) { user.admin? } do
  mount BetterStructureSql::Engine, at: '/admin/schema'
end`}
                      </CodeBlock>
                      <p className="mb-0 text-muted">
                        Requires authenticated admin user to access the engine.
                      </p>
                    </div>
                  </div>
                </div>

                <div className="accordion-item">
                  <h2 className="accordion-header">
                    <button className="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#customConstraint">
                      <i className="bi bi-code-square me-2" />
                      Custom Constraint Class
                    </button>
                  </h2>
                  <div id="customConstraint" className="accordion-collapse collapse" data-bs-parent="#authExamples">
                    <div className="accordion-body">
                      <CodeBlock language="ruby">
{`# lib/constraints/admin_constraint.rb
class AdminConstraint
  def matches?(request)
    user = request.env['warden']&.user
    user&.admin?
  end
end

# config/routes.rb
require 'constraints/admin_constraint'

constraints AdminConstraint.new do
  mount BetterStructureSql::Engine, at: '/schema_versions'
end`}
                      </CodeBlock>
                    </div>
                  </div>
                </div>

                <div className="accordion-item">
                  <h2 className="accordion-header">
                    <button className="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#envBased">
                      <i className="bi bi-globe me-2" />
                      Environment-Based Access
                    </button>
                  </h2>
                  <div id="envBased" className="accordion-collapse collapse" data-bs-parent="#authExamples">
                    <div className="accordion-body">
                      <CodeBlock language="ruby">
{`# config/routes.rb
if Rails.env.development?
  # No auth in development
  mount BetterStructureSql::Engine, at: '/schema_versions'
elsif Rails.env.production?
  # Require admin in production
  authenticate :user, ->(user) { user.admin? } do
    mount BetterStructureSql::Engine, at: '/schema_versions'
  end
end`}
                      </CodeBlock>
                    </div>
                  </div>
                </div>
              </div>

              <h3 className="mt-4 mb-3">Engine Features</h3>
              <div className="row">
                <div className="col-md-4 mb-3">
                  <div className="card h-100">
                    <div className="card-body text-center">
                      <i className="bi bi-list-columns display-4 text-primary" />
                      <h5 className="mt-3">Browse Versions</h5>
                      <p className="text-muted">
                        View all stored schema versions with metadata (date, size, database version, format)
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
                        Browse formatted schema with syntax highlighting and line numbers
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
                        rails db:migrate && rails db:schema:store
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
  rails db:schema:store
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
                      <p><strong>Auto-store in deployment pipeline:</strong></p>
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
      - uses: actions/checkout@v3
      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
      - name: Install dependencies
        run: bundle install
      - name: Run migrations and store schema
        run: |
          rails db:migrate RAILS_ENV=production
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
                    <li>Scalable - handles 50,000+ database objects</li>
                    <li>ZIP downloads - complete schema as single archive</li>
                  </ul>
                </div>
                <div className="col-md-6">
                  <h5>Directory Structure</h5>
                  <CodeBlock language="text">
{`db/schema/
├── _header.sql
├── _manifest.json
├── 1_extensions/
│   └── 000001.sql
├── 2_types/
├── 3_sequences/
├── 4_tables/
│   ├── 000001.sql
│   ├── 000002.sql
│   └── 000003.sql
├── 5_indexes/
├── 6_foreign_keys/
├── 7_views/
├── 8_functions/
└── 9_triggers/`}
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
                <a href="#/getting-started/installation" className="alert-link">Install BetterStructureSql</a>
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
