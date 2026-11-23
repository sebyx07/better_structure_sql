import Seo from '../../components/Seo/Seo';
import CodeBlock from '../../components/CodeBlock/CodeBlock';

function Configuration() {
  return (
    <>
      <Seo
        title="Configuration"
        description="All BetterStructureSql configuration options: output path, feature toggles, schema versioning and multi-file output."
      />

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

  # Make rails db:schema:dump / db:schema:load use BetterStructureSql (opt-in, default false)
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

              <p className="mt-3">
                Store a version manually. <code>db:schema:store</code> reads the dumped schema at{' '}
                <code>output_path</code>, so dump first. Storage is skipped when the content hash
                matches the latest stored version.
              </p>
              <CodeBlock language="bash">
                {`rails db:schema:dump_better
rails db:schema:store`}
              </CodeBlock>

              <div className="alert alert-info mt-3">
                <i className="bi bi-info-circle me-2" />
                In multi-file mode <code>db:schema:store</code> also stores a ZIP of the directory.
                The file or directory on disk is never modified.
              </div>
            </section>

            <section className="mb-5">
              <h2 className="mb-3">Feature Toggles</h2>
              <p>Control which database features to include in the dump:</p>

              <CodeBlock language="ruby" filename="config/initializers/better_structure_sql.rb">
                {`BetterStructureSql.configure do |config|
  # All enabled by default (features auto-skip if not supported by database)
  config.include_extensions = true          # PostgreSQL only
  config.include_custom_types = true        # PostgreSQL (ENUM, composite)
  config.include_domains = true             # PostgreSQL only
  config.include_sequences = true           # PostgreSQL only
  config.include_functions = true           # PostgreSQL, MySQL (stored procedures)
  config.include_triggers = true            # All databases
  config.include_views = true               # All databases
  config.include_materialized_views = true  # PostgreSQL only
  config.include_comments = true            # PostgreSQL; MySQL table comments
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
                    <th scope="col">Option</th>
                    <th scope="col">PostgreSQL</th>
                    <th scope="col">MySQL</th>
                    <th scope="col">SQLite</th>
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
                    <td><span className="badge bg-warning text-dark">Inline ENUM/SET</span></td>
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
                    <td><span className="badge bg-warning text-dark">Stored Procs</span></td>
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
                  <tr>
                    <td><code>include_comments</code></td>
                    <td><span className="badge bg-success">Yes</span></td>
                    <td><span className="badge bg-warning text-dark">Tables only</span></td>
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
              <p>Every option, shown with its default value:</p>

              <CodeBlock language="ruby" filename="config/initializers/better_structure_sql.rb">
                {`BetterStructureSql.configure do |config|
  # Core settings
  config.output_path = 'db/structure.sql'         # A path without a file extension means multi-file mode
  config.replace_default_dump = false             # true: rails db:schema:dump uses this gem
  config.replace_default_load = false             # true: rails db:schema:load uses this gem
  config.search_path = '"$user", public'          # PostgreSQL: written as SET search_path TO ...
  config.adapter = :auto                          # :auto, :postgresql, :mysql, :sqlite

  # Schema versioning
  config.enable_schema_versions = false           # Needed by db:schema:store / versions / cleanup
  config.schema_versions_limit = 10               # Keep N versions (0 = unlimited)

  # Feature toggles (auto-skip if unsupported)
  config.include_extensions = true                # PostgreSQL only
  config.include_custom_types = true              # PostgreSQL (ENUM, composite)
  config.include_domains = true                   # PostgreSQL only
  config.include_sequences = true                 # PostgreSQL only
  config.include_functions = true                 # PostgreSQL, MySQL (stored procedures)
  config.include_triggers = true                  # All databases
  config.include_views = true                     # All databases
  config.include_materialized_views = true        # PostgreSQL only
  config.include_comments = true                  # PostgreSQL; MySQL table comments

  # Multi-file output settings
  config.max_lines_per_file = 500                 # Soft limit of lines per file
  config.overflow_threshold = 1.1                 # A file may grow to limit * threshold
  config.generate_manifest = true                 # Create _manifest.json

  # Formatting
  config.indent_size = 2                          # Spaces per indent level
  config.add_section_spacing = true               # Spacing between sections
  config.sort_tables = true                       # Alphabetical table order
end`}
              </CodeBlock>

              <div className="alert alert-info mt-3">
                <i className="bi bi-info-circle me-2" />
                The initializer written by <code>rails generate better_structure_sql:install</code>{' '}
                differs from these defaults in three places: it sets{' '}
                <code>enable_schema_versions = true</code>, <code>sort_tables = false</code> and{' '}
                <code>search_path = &apos;public&apos;</code>.
              </div>

              <div className="alert alert-warning">
                <i className="bi bi-exclamation-triangle me-2" />
                <code>config.schemas</code> (default <code>[&apos;public&apos;]</code>) and{' '}
                <code>config.include_rules</code> exist but have no effect yet: PostgreSQL tables
                are read from the <code>public</code> schema only and rules are not dumped. Both{' '}
                <code>replace_default_*</code> options are ignored when <code>output_path</code> ends
                in <code>.rb</code>.
              </div>
            </section>
          </div>
        </div>
      </div>
    </>
  );
}

export default Configuration;
