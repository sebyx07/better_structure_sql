import { Helmet } from 'react-helmet-async';
import { Link } from 'react-router-dom';
import CodeBlock from '../../components/CodeBlock/CodeBlock';

function QuickStart() {
  return (
    <>
      <Helmet>
        <title>Quick Start - BetterStructureSql</title>
      </Helmet>

      <div className="container py-5">
        <div className="row">
          <div className="col-lg-10 offset-lg-1">
            <h1 className="mb-4">
              <i className="bi bi-rocket me-2" />
              Quick Start
            </h1>
            <p className="lead">Get your first clean schema dump in 5 minutes.</p>

            <div className="alert alert-warning">
              <i className="bi bi-exclamation-triangle me-2" />
              Haven&apos;t installed yet? Start with <Link to="/install" className="alert-link">Installation</Link>
            </div>

            <section className="mb-5">
              <h2 className="mb-3">1. Install the Gem</h2>
              <CodeBlock language="bash">
                {`# Add to Gemfile
gem 'better_structure_sql'
gem 'pg'  # or mysql2 or sqlite3

bundle install`}
              </CodeBlock>
            </section>

            <section className="mb-5">
              <h2 className="mb-3">2. Run the Generator</h2>
              <CodeBlock language="bash">
                {`rails generate better_structure_sql:install
rails db:migrate`}
              </CodeBlock>
            </section>

            <section className="mb-5">
              <h2 className="mb-3">3. Generate Your Schema</h2>
              <CodeBlock language="bash">
                rails db:schema:dump_better
              </CodeBlock>

              <div className="alert alert-success mt-3">
                <h5 className="alert-heading">
                  <i className="bi bi-check-circle me-2" />
                  Done! Check db/structure.sql
                </h5>
                <p className="mb-0">
                  Your schema is now clean and git-friendly, without pg_dump noise.
                </p>
              </div>
            </section>

            <section className="mb-5">
              <h2 className="mb-3">Next Steps</h2>
              <div className="row">
                <div className="col-md-6 mb-3">
                  <div className="card h-100">
                    <div className="card-body">
                      <h5 className="card-title">
                        <i className="bi bi-gear me-2" />
                        Configuration
                      </h5>
                      <p className="card-text">
                        Configure multi-file output, schema versioning, and feature toggles.
                      </p>
                      <Link to="/configuration" className="btn btn-primary btn-sm">
                        Configure →
                      </Link>
                    </div>
                  </div>
                </div>
                <div className="col-md-6 mb-3">
                  <div className="card h-100">
                    <div className="card-body">
                      <h5 className="card-title">
                        <i className="bi bi-database me-2" />
                        Database Guides
                      </h5>
                      <p className="card-text">
                        Learn about advanced features for PostgreSQL, MySQL, and SQLite.
                      </p>
                      <Link to="/databases/postgresql" className="btn btn-primary btn-sm">
                        View Guides →
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

export default QuickStart;
