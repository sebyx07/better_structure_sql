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
  # Output path - single file (default)
  config.output_path = 'db/structure.sql'

  # Replace default rake db:schema:dump
  config.replace_default_dump = true

  # Search path for PostgreSQL
  config.search_path = '"$user", public'
end`}
              </CodeBlock>
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
  # All enabled by default
  config.include_extensions = true   # PostgreSQL extensions
  config.include_functions = true    # Functions/stored procedures
  config.include_triggers = true     # Triggers
  config.include_views = true        # Views and materialized views
end`}
              </CodeBlock>
            </section>

            <section className="mb-5">
              <h2 className="mb-3">Multi-File Output</h2>
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
├── 1_extensions/
│   └── 000001.sql
├── 2_types/
│   └── 000001.sql
├── 4_tables/
│   ├── 000001.sql
│   ├── 000002.sql
│   └── 000003.sql
└── 9_triggers/
    └── 000001.sql`}
              </CodeBlock>
            </section>

            <section className="mb-5">
              <h2 className="mb-3">All Options Reference</h2>

              <CodeBlock language="ruby" filename="config/initializers/better_structure_sql.rb">
                {`BetterStructureSql.configure do |config|
  # Core settings
  config.output_path = 'db/structure.sql'    # File or directory
  config.replace_default_dump = true          # Override rake db:schema:dump
  config.search_path = '"$user", public'      # PostgreSQL search path

  # Schema versioning
  config.enable_schema_versions = false       # Store versions in DB
  config.schema_versions_limit = 10           # Keep N versions (0 = unlimited)

  # Feature toggles
  config.include_extensions = true            # Extensions (PostgreSQL)
  config.include_functions = true             # Functions/procedures
  config.include_triggers = true              # Triggers
  config.include_views = true                 # Views (including materialized)

  # Multi-file output settings
  config.max_lines_per_file = 500            # Lines per file
  config.overflow_threshold = 1.1            # Allow 10% overflow
  config.generate_manifest = true            # Create _manifest.json

  # Formatting
  config.indent_size = 2                     # SQL indentation
  config.add_section_spacing = true          # Spacing between sections
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
