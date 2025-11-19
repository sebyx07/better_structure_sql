import { Link } from 'react-router-dom';
import CodeBlock from '../../components/CodeBlock/CodeBlock';

function MySQL() {
  return (
    <div className="container my-4">
      <div className="row">
        <div className="col-lg-10 offset-lg-1">
          <div className="mysql-guide">
            <h1 className="mb-4">
              <i className="bi bi-database text-warning me-3" />
              MySQL Guide
            </h1>

            <div className="alert alert-info">
              <i className="bi bi-info-circle me-2" />
              MySQL support includes stored procedures, triggers, views, and indexes.
              Coming soon: comprehensive tutorials for MySQL-specific features!
            </div>

            <div className="alert alert-warning">
              <i className="bi bi-download me-2" />
              <strong>Getting Started:</strong>{' '}
              <Link to="/install" className="alert-link">Install BetterStructureSql</Link>
              {' '}• MySQL 8.0+ required •{' '}
              <a href="https://dev.mysql.com/downloads/mysql/" className="alert-link" target="_blank" rel="noopener noreferrer">
                Install MySQL
              </a>
            </div>

            <section className="mb-5">
              <h2 className="border-bottom pb-2 mb-3">MySQL Features</h2>
              <div className="row">
                <div className="col-md-6">
                  <h4>✅ Supported</h4>
                  <ul>
                    <li>Stored Procedures</li>
                    <li>Triggers (BEFORE/AFTER)</li>
                    <li>Views</li>
                    <li>Indexes (btree, hash, fulltext)</li>
                    <li>Foreign Keys</li>
                    <li>ENUM and SET types</li>
                    <li>CHECK Constraints (8.0.16+)</li>
                  </ul>
                </div>
                <div className="col-md-6">
                  <h4>❌ Not Supported</h4>
                  <ul>
                    <li>Extensions (MySQL doesn&apos;t have these)</li>
                    <li>Materialized Views</li>
                    <li>Custom Types (uses inline ENUM/SET)</li>
                    <li>Sequences (uses AUTO_INCREMENT)</li>
                  </ul>
                </div>
              </div>
            </section>

            <section className="mb-5">
              <h2 className="border-bottom pb-2 mb-3">Quick Example: Stored Procedure</h2>
              <CodeBlock language="sql" filename="Example MySQL Stored Procedure">
                {`CREATE PROCEDURE activate_user(IN user_id BIGINT)
BEGIN
  UPDATE users
  SET status = 'active', activated_at = NOW()
  WHERE id = user_id;

  INSERT INTO audit_logs (action, user_id, created_at)
  VALUES ('user_activated', user_id, NOW());
END;`}
              </CodeBlock>

              <p className="mt-3 text-muted">
                More comprehensive MySQL tutorials coming soon! Check back later for:
              </p>
              <ul className="text-muted">
                <li>Stored procedures for business logic</li>
                <li>Triggers for automatic updates</li>
                <li>ENUM and SET type usage</li>
                <li>Full-text search indexes</li>
              </ul>
            </section>
          </div>
        </div>
      </div>
    </div>
  );
}

export default MySQL;
