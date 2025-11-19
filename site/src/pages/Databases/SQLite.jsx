import CodeBlock from '../../components/CodeBlock/CodeBlock';

function SQLite() {
  return (
    <div className="container my-4">
      <div className="row">
        <div className="col-lg-10 offset-lg-1">
          <div className="sqlite-guide">
            <h1 className="mb-4">
              <i className="bi bi-database-dash text-info me-3" />
              SQLite Guide
            </h1>

            <div className="alert alert-info">
              <i className="bi bi-info-circle me-2" />
              SQLite support includes triggers, views, CHECK constraints, and PRAGMA settings.
              Coming soon: comprehensive tutorials for SQLite-specific features!
            </div>

            <section className="mb-5">
              <h2 className="border-bottom pb-2 mb-3">SQLite Features</h2>
              <div className="row">
                <div className="col-md-6">
                  <h4>✅ Supported</h4>
                  <ul>
                    <li>Triggers (BEFORE/AFTER)</li>
                    <li>Views</li>
                    <li>Indexes (btree)</li>
                    <li>Foreign Keys (inline)</li>
                    <li>CHECK Constraints</li>
                    <li>PRAGMA Settings</li>
                    <li>Type Affinities</li>
                  </ul>
                </div>
                <div className="col-md-6">
                  <h4>❌ Not Supported</h4>
                  <ul>
                    <li>Extensions</li>
                    <li>Stored Procedures/Functions</li>
                    <li>Materialized Views</li>
                    <li>Custom Types (uses CHECK for enums)</li>
                    <li>Sequences (uses AUTOINCREMENT)</li>
                  </ul>
                </div>
              </div>
            </section>

            <section className="mb-5">
              <h2 className="border-bottom pb-2 mb-3">Quick Example: PRAGMA Settings</h2>
              <CodeBlock language="sql" filename="Important SQLite PRAGMAs">
                {`PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
PRAGMA busy_timeout = 5000;

CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT NOT NULL UNIQUE,
  status TEXT DEFAULT 'pending',
  CONSTRAINT valid_status CHECK (status IN ('pending', 'active', 'inactive'))
);`}
              </CodeBlock>

              <p className="mt-3 text-muted">
                More comprehensive SQLite tutorials coming soon! Check back later for:
              </p>
              <ul className="text-muted">
                <li>Essential PRAGMA settings explained</li>
                <li>Using CHECK constraints for enum simulation</li>
                <li>Inline foreign keys best practices</li>
                <li>Type affinities and column types</li>
              </ul>
            </section>
          </div>
        </div>
      </div>
    </div>
  );
}

export default SQLite;
