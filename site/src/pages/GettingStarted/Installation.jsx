import { Helmet } from 'react-helmet-async';
import { Link } from 'react-router-dom';
import CodeBlock from '../../components/CodeBlock/CodeBlock';

function Installation() {
  return (
    <>
      <Helmet>
        <title>Installation - BetterStructureSql</title>
      </Helmet>

      <div className="container py-5">
        <div className="row">
          <div className="col-lg-10 offset-lg-1">
            <h1 className="mb-4">
              <i className="bi bi-download me-2" />
              Installation
            </h1>
            <p className="lead">Get started with BetterStructureSql in minutes.</p>

            <div className="alert alert-info">
              <i className="bi bi-info-circle me-2" />
              BetterStructureSql requires <strong>Rails 7.0+</strong> and <strong>Ruby 2.7+</strong>
            </div>

            <section className="mb-5">
              <h2 className="mb-3">Step 1: Add to Gemfile</h2>
              <p>Add BetterStructureSql and your database adapter to your Gemfile:</p>

              <CodeBlock language="ruby" filename="Gemfile">
                {`# Database schema management
gem 'better_structure_sql'

# Choose your database adapter:
gem 'pg', '>= 1.0'         # For PostgreSQL 12+
# gem 'mysql2', '>= 0.5'   # For MySQL 8.0+
# gem 'sqlite3', '>= 1.4'  # For SQLite 3.35+`}
              </CodeBlock>
            </section>

            <section className="mb-5">
              <h2 className="mb-3">Step 2: Install Dependencies</h2>
              <CodeBlock language="bash">
                bundle install
              </CodeBlock>
            </section>

            <section className="mb-5">
              <h2 className="mb-3">Step 3: Run the Generator</h2>
              <p>This creates the initializer and migration for schema versioning:</p>
              <CodeBlock language="bash">
                rails generate better_structure_sql:install
              </CodeBlock>

              <p className="mt-3">This will create:</p>
              <ul>
                <li><code>config/initializers/better_structure_sql.rb</code> - Configuration file</li>
                <li><code>db/migrate/xxx_create_better_structure_sql_schema_versions.rb</code> - Migration for version storage</li>
              </ul>
            </section>

            <section className="mb-5">
              <h2 className="mb-3">Step 4: Run the Migration</h2>
              <CodeBlock language="bash">
                rails db:migrate
              </CodeBlock>
            </section>

            <section className="mb-5">
              <h2 className="mb-3">Step 5: Verify Installation</h2>
              <p>Generate your first schema dump:</p>
              <CodeBlock language="bash">
                rails db:schema:dump_better
              </CodeBlock>

              <p className="mt-3">
                You should now see a clean <code>db/structure.sql</code> file without pg_dump noise!
              </p>

              <div className="alert alert-info mt-3">
                <i className="bi bi-magic me-2" />
                <strong>Automatic Setup:</strong> With <code>replace_default_dump = true</code>, BetterStructureSql automatically configures Rails to use SQL schema format. No need to manually set <code>config.active_record.schema_format</code> in <code>application.rb</code>!
              </div>
            </section>

            <div className="alert alert-success">
              <h5 className="alert-heading">
                <i className="bi bi-check-circle me-2" />
                Installation Complete!
              </h5>
              <p className="mb-0">
                Next: <Link to="/quick-start" className="alert-link">Follow the Quick Start guide</Link> to
                configure BetterStructureSql for your needs.
              </p>
            </div>

            <section className="mb-5">
              <h2 className="mb-3">Database-Specific Setup</h2>
              <div className="row">
                <div className="col-md-4">
                  <div className="card h-100">
                    <div className="card-body">
                      <h5 className="card-title">
                        <i className="bi bi-database-fill text-primary me-2" />
                        PostgreSQL
                      </h5>
                      <p className="card-text small">
                        Full feature support including extensions, functions, triggers, and materialized views.
                      </p>
                      <Link to="/databases/postgresql" className="btn btn-sm btn-primary">
                        PostgreSQL Guide →
                      </Link>
                    </div>
                  </div>
                </div>
                <div className="col-md-4">
                  <div className="card h-100">
                    <div className="card-body">
                      <h5 className="card-title">
                        <i className="bi bi-database text-warning me-2" />
                        MySQL
                      </h5>
                      <p className="card-text small">
                        Stored procedures, triggers, and views support.
                      </p>
                      <Link to="/databases/mysql" className="btn btn-sm btn-warning">
                        MySQL Guide →
                      </Link>
                    </div>
                  </div>
                </div>
                <div className="col-md-4">
                  <div className="card h-100">
                    <div className="card-body">
                      <h5 className="card-title">
                        <i className="bi bi-database-dash text-info me-2" />
                        SQLite
                      </h5>
                      <p className="card-text small">
                        Lightweight schemas with triggers and CHECK constraints.
                      </p>
                      <Link to="/databases/sqlite" className="btn btn-sm btn-info">
                        SQLite Guide →
                      </Link>
                    </div>
                  </div>
                </div>
              </div>
            </section>
          </div>
        </div>
      </div>
    </>
  );
}

export default Installation;
