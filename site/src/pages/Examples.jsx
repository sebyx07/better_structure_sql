import { Link } from 'react-router-dom';
import Seo from '../components/Seo/Seo';

const REPO_TREE = 'https://github.com/sebyx07/better_structure_sql/tree/main';

const EXAMPLE_APPS = [
  {
    path: 'integration',
    name: 'PostgreSQL',
    summary:
      'Rails app exercising extensions, custom types, functions, triggers, views and materialized views.',
  },
  {
    path: 'integration_mysql',
    name: 'MySQL and MariaDB',
    summary:
      'Rails app with stored procedures, triggers, views, CHECK constraints and composite foreign keys; its bss:round_trip task dumps, loads and dumps again.',
  },
  {
    path: 'integration_sqlite',
    name: 'SQLite',
    summary:
      'Rails app with inline foreign keys, CHECK constraints, generated columns and triggers; its bss:round_trip task dumps, loads and dumps again.',
  },
];

function Examples() {
  return (
    <>
      <Seo
        title="Examples"
        description="Example Rails applications and tutorials showing BetterStructureSql output for PostgreSQL, MySQL and SQLite."
      />

      <div className="container py-5">
        <h1 className="mb-4">Examples</h1>
        <p className="lead">
          The repository ships a runnable Rails app per database. Each one contains migrations and
          the schema BetterStructureSql generates from them.
        </p>

        <div className="row g-4 mb-5">
          {EXAMPLE_APPS.map((app) => (
            <div className="col-md-4" key={app.path}>
              <div className="card h-100">
                <div className="card-body">
                  <h2 className="card-title h5">{app.name}</h2>
                  <p className="card-text">{app.summary}</p>
                  <a
                    href={`${REPO_TREE}/${app.path}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="btn btn-sm btn-primary"
                  >
                    <code className="text-reset">{app.path}/</code> on GitHub
                  </a>
                </div>
              </div>
            </div>
          ))}
        </div>

        <h2 className="mb-3">Tutorials</h2>
        <p>The database guides walk through migrations and the resulting schema dump:</p>
        <ul>
          <li>
            <Link to="/databases/postgresql">PostgreSQL guide</Link> - UUID functions, audit
            triggers, trigram search, enums, materialized views
          </li>
          <li>
            <Link to="/databases/mysql">MySQL guide</Link> - stored procedures and triggers
          </li>
          <li>
            <Link to="/databases/sqlite">SQLite guide</Link> - PRAGMA settings, CHECK constraints,
            triggers, inline foreign keys
          </li>
        </ul>
      </div>
    </>
  );
}

export default Examples;
