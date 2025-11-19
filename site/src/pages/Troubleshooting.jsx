import CodeBlock from '../components/CodeBlock/CodeBlock';

function Troubleshooting() {
  return (
    <div className="container py-5">
      <h1 className="display-4 mb-4">Troubleshooting</h1>
      <p className="lead mb-5">
        Common issues and solutions for BetterStructureSql
      </p>

      {/* Manually Adding Schema Versions in Production */}
      <section className="mb-5">
        <h2 className="mb-3">Manually Adding Schema Versions in Production</h2>
        <p>
          If you have an existing <code>schema.rb</code> or <code>structure.sql</code> in production
          but no stored schema versions, you can manually add them to the database.
        </p>

        <div className="alert alert-info">
          <strong>Scenario:</strong> You have a production database with a current schema, but no
          stored schema versions (table exists but is empty), and you want to capture the current
          schema as a baseline.
        </div>

        {/* Solution 1 */}
        <div className="card mb-4">
          <div className="card-header">
            <h4 className="mb-0">Solution 1: Store Current Production Schema (Simplest)</h4>
          </div>
          <div className="card-body">
            <p>
              If you&apos;re already using <code>structure.sql</code>, this is the simplest approach -
              just generate and store the current schema:
            </p>

            <h5 className="mt-3">From Command Line:</h5>
            <CodeBlock
              language="bash"
              code={`# Generate and store current schema in one step
RAILS_ENV=production rails db:schema:dump_better
RAILS_ENV=production rails db:schema:store`}
            />

            <h5 className="mt-4">From Rails Console:</h5>
            <CodeBlock
              language="ruby"
              code={`# Production Rails console
BetterStructureSql::Dumper.dump(output_path: 'db/structure.sql')
BetterStructureSql::SchemaVersions.store_current`}
            />

            <div className="alert alert-success mt-3">
              <strong>Best for:</strong> Quick baseline creation when you just want to start
              tracking versions from now on.
            </div>
          </div>
        </div>

        {/* Solution 2 */}
        <div className="card mb-4">
          <div className="card-header">
            <h4 className="mb-0">Solution 2: Import Existing Schema File</h4>
          </div>
          <div className="card-body">
            <p>
              If you have an existing <code>structure.sql</code> or <code>schema.rb</code> file
              that matches your production database:
            </p>

            <h5 className="mt-3">For structure.sql:</h5>
            <CodeBlock
              language="ruby"
              code={`# Production Rails console
content = File.read(Rails.root.join('db', 'structure.sql'))
db_version = ActiveRecord::Base.connection.select_value('SHOW server_version')

BetterStructureSql::SchemaVersions.store(
  content: content,
  format_type: 'sql',
  pg_version: db_version
)`}
            />

            <h5 className="mt-4">For schema.rb:</h5>
            <CodeBlock
              language="ruby"
              code={`# Production Rails console
content = File.read(Rails.root.join('db', 'schema.rb'))
db_version = ActiveRecord::Base.connection.select_value('SHOW server_version')

BetterStructureSql::SchemaVersions.store(
  content: content,
  format_type: 'rb',
  pg_version: db_version
)`}
            />

            <div className="alert alert-success mt-3">
              <strong>Best for:</strong> When you have an existing schema file in your codebase
              that you want to preserve as the first version.
            </div>
          </div>
        </div>

        {/* Solution 3 */}
        <div className="card mb-4">
          <div className="card-header">
            <h4 className="mb-0">Solution 3: Copy from Development</h4>
          </div>
          <div className="card-body">
            <p>
              If your development environment has schema versions but production doesn&apos;t:
            </p>

            <h5 className="mt-3">Step 1: Export from Development</h5>
            <CodeBlock
              language="ruby"
              code={`# Development Rails console
dev_version = BetterStructureSql::SchemaVersions.latest
File.write('tmp/schema_export.sql', dev_version.content)`}
            />

            <h5 className="mt-4">Step 2: Copy to Production Server</h5>
            <CodeBlock
              language="bash"
              code="scp tmp/schema_export.sql production-server:/tmp/"
            />

            <h5 className="mt-4">Step 3: Import in Production</h5>
            <CodeBlock
              language="ruby"
              code={`# Production Rails console
content = File.read('/tmp/schema_export.sql')
db_version = ActiveRecord::Base.connection.select_value('SHOW server_version')

BetterStructureSql::SchemaVersions.store(
  content: content,
  format_type: 'sql',
  pg_version: db_version
)`}
            />

            <div className="alert alert-success mt-3">
              <strong>Best for:</strong> Syncing production with development when they have
              the same schema structure.
            </div>
          </div>
        </div>

        {/* Solution 4 */}
        <div className="card mb-4">
          <div className="card-header">
            <h4 className="mb-0">Solution 4: Backfill Historical Versions from Git</h4>
          </div>
          <div className="card-body">
            <p>
              If you want to preserve historical schema versions from your git history:
            </p>

            <h5 className="mt-3">Step 1: Extract Historical Schemas</h5>
            <CodeBlock
              language="bash"
              code={`# Extract schema from specific git commits
git show main~10:db/structure.sql > /tmp/schema_v1.sql
git show main~5:db/structure.sql > /tmp/schema_v2.sql
git show main:db/structure.sql > /tmp/schema_v3.sql`}
            />

            <h5 className="mt-4">Step 2: Import Each Version</h5>
            <CodeBlock
              language="ruby"
              code={`# Production Rails console
db_version = ActiveRecord::Base.connection.select_value('SHOW server_version')

# Store historical versions (oldest first)
['/tmp/schema_v1.sql', '/tmp/schema_v2.sql', '/tmp/schema_v3.sql'].each do |file|
  content = File.read(file)
  BetterStructureSql::SchemaVersions.store(
    content: content,
    format_type: 'sql',
    pg_version: db_version
  )
  sleep 1  # Ensure different timestamps
end`}
            />

            <div className="alert alert-success mt-3">
              <strong>Best for:</strong> Creating a complete version history from git commits
              for audit trails or schema evolution tracking.
            </div>
          </div>
        </div>

        {/* Solution 5 */}
        <div className="card mb-4">
          <div className="card-header">
            <h4 className="mb-0">Solution 5: Multi-File Schema Import</h4>
          </div>
          <div className="card-body">
            <p>
              For multi-file schema output stored in git (when using directory-based mode):
            </p>

            <h5 className="mt-3">Step 1: Extract Directory from Git</h5>
            <CodeBlock
              language="bash"
              code={`# Extract multi-file schema directory from git commit
git archive --format=tar main:db/schema | tar -x -C /tmp/schema_export`}
            />

            <h5 className="mt-4">Step 2: Create ZIP and Import</h5>
            <CodeBlock
              language="ruby"
              code={`# Production Rails console
require 'zip'

db_version = ActiveRecord::Base.connection.select_value('SHOW server_version')
schema_dir = '/tmp/schema_export'

# Create ZIP from directory
zip_buffer = BetterStructureSql::ZipGenerator.create_from_directory(schema_dir)

BetterStructureSql::SchemaVersions.store(
  zip_archive: zip_buffer.string,
  output_mode: 'multi_file',
  pg_version: db_version
)`}
            />

            <div className="alert alert-success mt-3">
              <strong>Best for:</strong> Large schemas using multi-file directory output mode.
            </div>
          </div>
        </div>

        {/* Verification */}
        <div className="card mb-4 border-primary">
          <div className="card-header bg-primary text-white">
            <h4 className="mb-0">Verification</h4>
          </div>
          <div className="card-body">
            <p>After adding versions, verify they were stored correctly:</p>

            <CodeBlock
              language="ruby"
              code={`# Check count
BetterStructureSql::SchemaVersions.count
# => 3

# List versions
BetterStructureSql::SchemaVersions.all_versions.each do |v|
  puts "ID: #{v.id}, Created: #{v.created_at}, Size: #{v.formatted_size}"
end

# Verify latest version content
latest = BetterStructureSql::SchemaVersions.latest
puts latest.content.lines.first(10)`}
            />
          </div>
        </div>

        {/* Automated Script */}
        <div className="card mb-4 border-success">
          <div className="card-header bg-success text-white">
            <h4 className="mb-0">Automated Baseline Script</h4>
          </div>
          <div className="card-body">
            <p>Create a one-time setup rake task for easy baseline creation:</p>

            <CodeBlock
              language="ruby"
              code={`# lib/tasks/schema_baseline.rake
namespace :db do
  namespace :schema do
    desc 'Create baseline schema version from current database'
    task baseline: :environment do
      puts "Creating baseline schema version..."

      # Dump current schema
      BetterStructureSql::Dumper.dump(output_path: 'db/structure.sql')

      # Store as version
      BetterStructureSql::SchemaVersions.store_current

      latest = BetterStructureSql::SchemaVersions.latest
      puts "✓ Baseline created: ID #{latest.id}, Size #{latest.formatted_size}"
      puts "Total versions: #{BetterStructureSql::SchemaVersions.count}"
    end
  end
end`}
            />

            <h5 className="mt-4">Usage:</h5>
            <CodeBlock
              language="bash"
              code="RAILS_ENV=production rails db:schema:baseline"
            />
          </div>
        </div>
      </section>

      {/* Common Issues */}
      <section className="mb-5">
        <h2 className="mb-3">Common Issues</h2>

        <div className="accordion" id="commonIssues">
          {/* Issue 1 */}
          <div className="accordion-item">
            <h2 className="accordion-header">
              <button
                className="accordion-button collapsed"
                type="button"
                data-bs-toggle="collapse"
                data-bs-target="#issue1"
              >
                Table doesn&apos;t exist error
              </button>
            </h2>
            <div id="issue1" className="accordion-collapse collapse" data-bs-parent="#commonIssues">
              <div className="accordion-body">
                <p><strong>Solution:</strong> Run migration to create the schema versions table</p>
                <CodeBlock
                  language="bash"
                  code="RAILS_ENV=production rails db:migrate"
                />
              </div>
            </div>
          </div>

          {/* Issue 2 */}
          <div className="accordion-item">
            <h2 className="accordion-header">
              <button
                className="accordion-button collapsed"
                type="button"
                data-bs-toggle="collapse"
                data-bs-target="#issue2"
              >
                Permission denied when reading file
              </button>
            </h2>
            <div id="issue2" className="accordion-collapse collapse" data-bs-parent="#commonIssues">
              <div className="accordion-body">
                <p><strong>Solution:</strong> Ensure Rails process has read access to the schema file</p>
                <CodeBlock
                  language="bash"
                  code="chmod 644 db/structure.sql"
                />
              </div>
            </div>
          </div>

          {/* Issue 3 */}
          <div className="accordion-item">
            <h2 className="accordion-header">
              <button
                className="accordion-button collapsed"
                type="button"
                data-bs-toggle="collapse"
                data-bs-target="#issue3"
              >
                Database version mismatch
              </button>
            </h2>
            <div id="issue3" className="accordion-collapse collapse" data-bs-parent="#commonIssues">
              <div className="accordion-body">
                <p><strong>Solution:</strong> Get correct database version for your database type</p>
                <CodeBlock
                  language="ruby"
                  code={`# Get correct database version
db_version = case ActiveRecord::Base.connection.adapter_name
when 'PostgreSQL'
  ActiveRecord::Base.connection.select_value('SHOW server_version')
when 'Mysql2'
  ActiveRecord::Base.connection.select_value('SELECT VERSION()')
when 'SQLite'
  ActiveRecord::Base.connection.select_value('SELECT sqlite_version()')
end

# Use correct version when storing
BetterStructureSql::SchemaVersions.store(
  content: content,
  format_type: 'sql',
  pg_version: db_version
)`}
                />
              </div>
            </div>
          </div>

          {/* Issue 4 */}
          <div className="accordion-item">
            <h2 className="accordion-header">
              <button
                className="accordion-button collapsed"
                type="button"
                data-bs-toggle="collapse"
                data-bs-target="#issue4"
              >
                Schema not updating
              </button>
            </h2>
            <div id="issue4" className="accordion-collapse collapse" data-bs-parent="#commonIssues">
              <div className="accordion-body">
                <p><strong>Solution:</strong> Clear cached schema and regenerate</p>
                <CodeBlock
                  language="bash"
                  code={`# Clear cached schema
rm db/structure.sql

# Regenerate
rails db:schema:dump_better`}
                />
              </div>
            </div>
          </div>

          {/* Issue 5 */}
          <div className="accordion-item">
            <h2 className="accordion-header">
              <button
                className="accordion-button collapsed"
                type="button"
                data-bs-toggle="collapse"
                data-bs-target="#issue5"
              >
                Version storage failing
              </button>
            </h2>
            <div id="issue5" className="accordion-collapse collapse" data-bs-parent="#commonIssues">
              <div className="accordion-body">
                <p><strong>Solution:</strong> Check configuration and ensure table exists</p>
                <CodeBlock
                  language="bash"
                  code={`# Ensure table exists
rails db:migrate

# Check configuration
rails runner "puts BetterStructureSql.config.enable_schema_versions"`}
                />
              </div>
            </div>
          </div>

          {/* Issue 6 */}
          <div className="accordion-item">
            <h2 className="accordion-header">
              <button
                className="accordion-button collapsed"
                type="button"
                data-bs-toggle="collapse"
                data-bs-target="#issue6"
              >
                Permission errors (PostgreSQL)
              </button>
            </h2>
            <div id="issue6" className="accordion-collapse collapse" data-bs-parent="#commonIssues">
              <div className="accordion-body">
                <p><strong>Solution:</strong> Grant necessary PostgreSQL permissions</p>
                <CodeBlock
                  language="sql"
                  code={`GRANT SELECT ON ALL TABLES IN SCHEMA information_schema TO your_user;
GRANT SELECT ON ALL TABLES IN SCHEMA pg_catalog TO your_user;`}
                />
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Quick Tips */}
      <section className="mb-5">
        <h2 className="mb-3">Quick Tips</h2>

        <div className="row">
          <div className="col-md-6 mb-3">
            <div className="card h-100">
              <div className="card-body">
                <h5 className="card-title">💡 Already on structure.sql?</h5>
                <p className="card-text">
                  If you&apos;re already using <code>structure.sql</code>, the change is simple -
                  just run <code>rails db:schema:store</code> to create your first version!
                </p>
              </div>
            </div>
          </div>

          <div className="col-md-6 mb-3">
            <div className="card h-100">
              <div className="card-body">
                <h5 className="card-title">🔄 Automated Storage</h5>
                <p className="card-text">
                  Set up automatic schema version storage after migrations by adding a
                  custom rake task or git hook.
                </p>
              </div>
            </div>
          </div>

          <div className="col-md-6 mb-3">
            <div className="card h-100">
              <div className="card-body">
                <h5 className="card-title">📊 Multi-File Mode</h5>
                <p className="card-text">
                  For large schemas (100+ tables), consider using multi-file directory mode
                  for better git diffs and easier navigation.
                </p>
              </div>
            </div>
          </div>

          <div className="col-md-6 mb-3">
            <div className="card h-100">
              <div className="card-body">
                <h5 className="card-title">🗂️ Version History</h5>
                <p className="card-text">
                  Configure retention limits to control how many versions to keep.
                  Set to 0 for unlimited or specify a number (e.g., 10).
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Next Steps */}
      <div className="alert alert-primary">
        <h4 className="alert-heading">Need More Help?</h4>
        <hr />
        <ul className="mb-0">
          <li>
            <a href="#/configuration" className="alert-link">Configuration Guide</a> -
            Full configuration options
          </li>
          <li>
            <a href="#/quick-start" className="alert-link">Quick Start</a> -
            Getting started guide
          </li>
          <li>
            <a href="https://github.com/sebyx07/better_structure_sql/issues" className="alert-link" target="_blank" rel="noopener noreferrer">
              GitHub Issues
            </a> - Report bugs or request features
          </li>
        </ul>
      </div>
    </div>
  );
}

export default Troubleshooting;
