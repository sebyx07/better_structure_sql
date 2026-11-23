import { Link } from 'react-router-dom';
import Seo from '../components/Seo/Seo';
import GEM_VERSION from '../version';

function Home() {
  return (
    <>
      <Seo />

      {/* Hero Section */}
      <section className="hero text-center">
        <div className="container">
          <h1 className="display-4 fw-bold">Use SQL Databases to the Fullest</h1>
          <p className="lead mb-4">
            Clean, maintainable schema dumps for Rails with support for thousands of tables, triggers,
            views, and functions.
          </p>
          <div className="d-flex gap-3 justify-content-center flex-wrap">
            <Link to="/install" className="btn btn-primary btn-lg">
              <i className="bi bi-download me-2" />
              Get Started
            </Link>
            <a
              href="https://github.com/sebyx07/better_structure_sql"
              className="btn btn-outline-light btn-lg"
              target="_blank"
              rel="noopener noreferrer"
            >
              <i className="bi bi-github me-2" />
              View on GitHub
            </a>
          </div>

          {/* Database Badges */}
          <div className="mt-5 d-flex gap-3 justify-content-center flex-wrap">
            <Link to="/databases/postgresql" className="badge bg-success fs-6 text-decoration-none">
              <i className="bi bi-check-circle me-1" />
              PostgreSQL
            </Link>
            <Link to="/databases/mysql" className="badge bg-success fs-6 text-decoration-none">
              <i className="bi bi-check-circle me-1" />
              MySQL / MariaDB
            </Link>
            <Link to="/databases/sqlite" className="badge bg-success fs-6 text-decoration-none">
              <i className="bi bi-check-circle me-1" />
              SQLite
            </Link>
          </div>
        </div>
      </section>

      {/* Why Section */}
      <section className="py-5 bg-dark">
        <div className="container">
          <div className="row">
            <div className="col-lg-8 mx-auto text-center">
              <h2 className="mb-4">Why BetterStructureSql?</h2>
              <p className="lead mb-4">
                Rails&apos; default schema dump tools create noisy files with version-specific comments
                and inconsistent formatting that pollute git diffs. BetterStructureSql uses pure Ruby
                introspection to generate clean, deterministic output.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-5">
        <div className="container">
          <h2 className="text-center mb-5">Core Features</h2>
          <div className="row g-4">
            <div className="col-md-4">
              <div className="card h-100 feature-card">
                <div className="card-body">
                  <div className="mb-3">
                    <i className="bi bi-git text-success fs-1" />
                  </div>
                  <h3 className="card-title h5">Clean Git Diffs</h3>
                  <p className="card-text">
                    Only actual schema changes show up in version control. No noise from
                    version-specific comments or metadata.
                  </p>
                </div>
              </div>
            </div>

            <div className="col-md-4">
              <div className="card h-100 feature-card">
                <div className="card-body">
                  <div className="mb-3">
                    <i className="bi bi-database text-primary fs-1" />
                  </div>
                  <h3 className="card-title h5">Multi-Database Support</h3>
                  <p className="card-text">
                    PostgreSQL is the primary target. MySQL, MariaDB and SQLite dumps are
                    round-trip tested in CI, with automatic adapter detection.
                  </p>
                </div>
              </div>
            </div>

            <div className="col-md-4">
              <div className="card h-100 feature-card">
                <div className="card-body">
                  <div className="mb-3">
                    <i className="bi bi-archive text-warning fs-1" />
                  </div>
                  <h3 className="card-title h5">Schema Versioning</h3>
                  <p className="card-text">
                    Store schema versions in your database with automatic retention management.
                    Perfect for production transparency.
                  </p>
                </div>
              </div>
            </div>

            <div className="col-md-4">
              <div className="card h-100 feature-card">
                <div className="card-body">
                  <div className="mb-3">
                    <i className="bi bi-folder text-info fs-1" />
                  </div>
                  <h3 className="card-title h5">Multi-File Output</h3>
                  <p className="card-text">
                    Split massive schemas into organized, numbered directories. AI-friendly
                    500-line chunks instead of 10,000+ line files.
                  </p>
                </div>
              </div>
            </div>

            <div className="col-md-4">
              <div className="card h-100 feature-card">
                <div className="card-body">
                  <div className="mb-3">
                    <i className="bi bi-code-slash text-danger fs-1" />
                  </div>
                  <h3 className="card-title h5">Advanced Features</h3>
                  <p className="card-text">
                    Triggers, views and functions, plus PostgreSQL extensions, custom types,
                    domains, sequences, materialized views, partitioned tables and table
                    inheritance.
                  </p>
                </div>
              </div>
            </div>

            <div className="col-md-4">
              <div className="card h-100 feature-card">
                <div className="card-body">
                  <div className="mb-3">
                    <i className="bi bi-lightning-charge text-success fs-1" />
                  </div>
                  <h3 className="card-title h5">No External Tools</h3>
                  <p className="card-text">
                    Pure Ruby implementation. No pg_dump, mysqldump, or sqlite3 CLI required.
                    Works anywhere Rails runs.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* AI Benefits Section */}
      <section className="py-5 bg-dark">
        <div className="container">
          <div className="row align-items-center">
            <div className="col-lg-6">
              <h2 className="mb-4">AI-Friendly Schema Organization</h2>
              <p className="lead">
                Stop overwhelming LLMs with 10,000+ line structure.sql files. Multi-file output creates
                organized, navigable schemas perfect for AI-assisted development.
              </p>
              <ul className="list-unstyled">
                <li className="mb-2">
                  <i className="bi bi-check-circle-fill text-success me-2" />
                  500-line chunks fit easily in LLM context windows
                </li>
                <li className="mb-2">
                  <i className="bi bi-check-circle-fill text-success me-2" />
                  Numbered directories show load order (05_tables/, 09_triggers/)
                </li>
                <li className="mb-2">
                  <i className="bi bi-check-circle-fill text-success me-2" />
                  Easy references: &quot;Check 05_tables/000015.sql for users table&quot;
                </li>
                <li className="mb-2">
                  <i className="bi bi-check-circle-fill text-success me-2" />
                  AI can navigate and understand structure efficiently
                </li>
              </ul>
            </div>
            <div className="col-lg-6">
              <div className="card bg-secondary">
                <div className="card-body">
                  <p className="text-monospace small mb-2">db/schema/ (Multi-File Output)</p>
                  <pre className="text-light mb-0">
                    {`├── 01_extensions/
│   └── 000001.sql
├── 02_types/
│   └── 000001.sql
├── 05_tables/
│   ├── 000001.sql (500 lines)
│   ├── 000002.sql (500 lines)
│   └── 000003.sql (350 lines)
├── 09_triggers/
│   └── 000001.sql
└── _manifest.json`}
                  </pre>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Quick Start */}
      <section className="py-5">
        <div className="container">
          <div className="row">
            <div className="col-lg-8 mx-auto">
              <h2 className="text-center mb-4">Quick Start</h2>
              <div className="card bg-dark">
                <div className="card-body">
                  <pre className="text-light mb-0">
                    {`# Add to Gemfile
gem 'better_structure_sql'

# Install
bundle install
rails generate better_structure_sql:install

# Dump your schema
rails db:schema:dump_better

# Clean structure.sql ready!`}
                  </pre>
                </div>
              </div>
              <div className="text-center mt-4">
                <Link to="/quick-start" className="btn btn-primary">
                  Full Quick Start Guide
                </Link>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Project Status */}
      <section className="py-4 bg-dark">
        <div className="container">
          <div className="row">
            <div className="col-lg-8 mx-auto text-center">
              <h2 className="h5 mb-2">
                <i className="bi bi-info-circle me-2" />
                Version {GEM_VERSION}
              </h2>
              <p className="mb-0">
                PostgreSQL is the primary target. MySQL, MariaDB and SQLite dumps are round-trip tested in CI.
                Feedback and contributions are welcome on{' '}
                <a href="https://github.com/sebyx07/better_structure_sql/issues">GitHub</a>.
              </p>
            </div>
          </div>
        </div>
      </section>
    </>
  );
}

export default Home;
