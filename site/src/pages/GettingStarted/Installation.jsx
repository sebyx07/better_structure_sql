import { Helmet } from 'react-helmet-async';

function Installation() {
  return (
    <>
      <Helmet>
        <title>Installation - BetterStructureSql</title>
      </Helmet>

      <div className="container py-5">
        <h1 className="mb-4">Installation</h1>
        <p className="lead">Get started with BetterStructureSql in minutes.</p>

        <div className="card bg-dark mb-4">
          <div className="card-body">
            <h5>Add to Gemfile</h5>
            <pre className="text-light">
              {`gem 'better_structure_sql'

# Add the appropriate database adapter
gem 'pg'        # For PostgreSQL
gem 'mysql2'    # For MySQL
gem 'sqlite3'   # For SQLite`}
            </pre>
          </div>
        </div>

        <p>More documentation coming soon...</p>
      </div>
    </>
  );
}

export default Installation;
