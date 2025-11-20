import { Helmet } from 'react-helmet-async';
import CodeBlock from '../../components/CodeBlock/CodeBlock';

function Configuration() {
  return (
    <>
      <Helmet>
        <title>Configuration - BetterStructureSql</title>
      </Helmet>

      <div className="container py-5">
        <div className="row">
          <div className="col-lg-10 offset-lg-1">
            <h1 className="mb-4">
              <i className="bi bi-sliders me-2" />
              Configuration
            </h1>
            <p className="lead">Configure BetterStructureSql for your needs.</p>

            <section className="mb-5">
              <h2 className="mb-3">Basic Configuration</h2>
              <p>Edit <code>config/initializers/better_structure_sql.rb</code>:</p>

              <CodeBlock language="ruby" filename="config/initializers/better_structure_sql.rb">
                {`BetterStructureSql.configure do |config|
  # Output path
  # Single file (default): 'db/structure.sql'
  # Directory (recommended): 'db/schema'
  config.output_path = 'db/structure.sql'

  # Replace default rake tasks
  config.replace_default_dump = true
  config.replace_default_load = true

  # Search path for PostgreSQL
  config.search_path = 'public'
end`}
              </CodeBlock>

              <div className="alert alert-info mt-3">
                <i className="bi bi-lightbulb me-2" />
                <strong>Tip:</strong> For projects with 100+ tables, use <code>config.output_path = &apos;db/schema&apos;</code> (directory mode) for better organization and git diffs.
              </div>
            </section>

            <section className="mb-5">
              <h2 className="mb-3">Schema Versioning</h2>
              <p>Store schema versions in your database for easy access and history tracking:</p>

              <CodeBlock language="ruby" filename="config/initializers/better_structure_sql.rb">
                {`BetterStructureSql.configure do |config|
  # Enable schema version storage
  config.enable_schema_versions = true

  # Keep last 10 versions (0 = unlimited)
  config.schema_versions_limit = 10
end`}
              </CodeBlock>

              <p className="mt-3">Store a version manually:</p>
              <CodeBlock language="bash">
                rails db:schema:store
              </CodeBlock>
            </section>

            <section className="mb-5">
              <h2 className="mb-3">Feature Toggles</h2>
              <p>Control which database features to include in the dump:</p>

              <CodeBlock language="ruby" filename="config/initializers/better_structure_sql.rb">
                {`BetterStructureSql.configure do |config|
  # All enabled by default (features auto-skip if not supported by database)
  config.include_extensions = true          # PostgreSQL only
  config.include_custom_types = true        # PostgreSQL (ENUM, composite), MySQL (ENUM/SET)
  config.include_domains = true             # PostgreSQL only
  config.include_sequences = true           # PostgreSQL only
  config.include_functions = true           # PostgreSQL, MySQL (stored procedures)
  config.include_triggers = true            # All databases
  config.include_views = true               # All databases
  config.include_materialized_views = true  # PostgreSQL only
end`}
              </CodeBlock>

              <div className="alert alert-info mt-3">
                <i className="bi bi-info-circle me-2" />
                Features not supported by your database are automatically skipped. No need to disable them manually.
              </div>

              <h3 className="mt-4 mb-3">Database Support Matrix</h3>
              <table className="table table-sm">
                <thead>
                  <tr>
                    <th>Feature</th>
                    <th>PostgreSQL</th>
                    <th>MySQL</th>
                    <th>SQLite</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td><code>include_extensions</code></td>
                    <td><span className="badge bg-success">Yes</span></td>
                    <td><span className="badge bg-secondary">No</span></td>
                    <td><span className="badge bg-secondary">No</span></td>
                  </tr>
                  <tr>
                    <td><code>include_custom_types</code></td>
                    <td><span className="badge bg-success">Yes</span></td>
                    <td><span className="badge bg-warning">ENUM/SET</span></td>
                    <td><span className="badge bg-secondary">No</span></td>
                  </tr>
                  <tr>
                    <td><code>include_domains</code></td>
                    <td><span className="badge bg-success">Yes</span></td>
                    <td><span className="badge bg-secondary">No</span></td>
                    <td><span className="badge bg-secondary">No</span></td>
                  </tr>
                  <tr>
                    <td><code>include_sequences</code></td>
                    <td><span className="badge bg-success">Yes</span></td>
                    <td><span className="badge bg-secondary">No</span></td>
                    <td><span className="badge bg-secondary">No</span></td>
                  </tr>
                  <tr>
                    <td><code>include_functions</code></td>
                    <td><span className="badge bg-success">Yes</span></td>
                    <td><span className="badge bg-warning">Stored Procs</span></td>
                    <td><span className="badge bg-secondary">No</span></td>
                  </tr>
                  <tr>
                    <td><code>include_triggers</code></td>
                    <td><span className="badge bg-success">Yes</span></td>
                    <td><span className="badge bg-success">Yes</span></td>
                    <td><span className="badge bg-success">Yes</span></td>
                  </tr>
                  <tr>
                    <td><code>include_views</code></td>
                    <td><span className="badge bg-success">Yes</span></td>
                    <td><span className="badge bg-success">Yes</span></td>
                    <td><span className="badge bg-success">Yes</span></td>
                  </tr>
                  <tr>
                    <td><code>include_materialized_views</code></td>
                    <td><span className="badge bg-success">Yes</span></td>
                    <td><span className="badge bg-secondary">No</span></td>
                    <td><span className="badge bg-secondary">No</span></td>
                  </tr>
                </tbody>
              </table>
            </section>

            <section className="mb-5">
              <h2 className="mb-3">Multi-File Output</h2>
              <div className="alert alert-warning mb-3">
                <i className="bi bi-star-fill me-2" />
                <strong>Recommended for large projects:</strong> Use directory mode (<code>db/schema</code>) instead of single file for better git diffs, easier navigation, and AI-friendly organization.
              </div>
              <p>For large schemas (1000+ tables), split into organized directories:</p>

              <CodeBlock language="ruby" filename="config/initializers/better_structure_sql.rb">
                {`BetterStructureSql.configure do |config|
  # Directory path instead of file
  config.output_path = 'db/schema'

  # File chunking settings
  config.max_lines_per_file = 500      # ~500 lines per file
  config.overflow_threshold = 1.1      # Allow 10% overflow
  config.generate_manifest = true      # Create _manifest.json
end`}
              </CodeBlock>

              <p className="mt-3">This creates an organized directory structure:</p>
              <CodeBlock language="text">
                {`db/schema/
├── _header.sql
├── _manifest.json
├── 01_extensions/
│   └── 000001.sql
├── 02_types/
│   └── 000001.sql
├── 05_tables/
│   ├── 000001.sql
│   ├── 000002.sql
│   └── 000003.sql
└── 09_triggers/
    └── 000001.sql`}
              </CodeBlock>
            </section>

            <section className="mb-5">
              <h2 className="mb-3">All Options Reference</h2>

              <CodeBlock language="ruby" filename="config/initializers/better_structure_sql.rb">
                {`BetterStructureSql.configure do |config|
  # Core settings
  config.output_path = 'db/structure.sql'         # File or directory
  config.replace_default_dump = true              # Override rake db:schema:dump
  config.replace_default_load = true              # Override rake db:schema:load
  config.search_path = 'public'                   # PostgreSQL only

  # Schema versioning
  config.enable_schema_versions = true            # All databases
  config.schema_versions_limit = 10               # Keep N versions (0 = unlimited)

  # Feature toggles (auto-skip if unsupported)
  config.include_extensions = true                # PostgreSQL only
  config.include_custom_types = true              # PostgreSQL (ENUM, composite), MySQL (ENUM/SET)
  config.include_domains = true                   # PostgreSQL only
  config.include_sequences = true                 # PostgreSQL only
  config.include_functions = true                 # PostgreSQL, MySQL (stored procedures)
  config.include_triggers = true                  # All databases
  config.include_views = true                     # All databases
  config.include_materialized_views = true        # PostgreSQL only

  # Multi-file output settings
  config.max_lines_per_file = 500                 # Lines per file
  config.overflow_threshold = 1.1                 # Allow 10% overflow
  config.generate_manifest = true                 # Create _manifest.json

  # Formatting
  config.add_section_spacing = true               # Spacing between sections
  config.sort_tables = false                      # Sort tables alphabetically
end`}
              </CodeBlock>
            </section>
          </div>
        </div>
      </div>
    </>
  );
}

export default Configuration;
