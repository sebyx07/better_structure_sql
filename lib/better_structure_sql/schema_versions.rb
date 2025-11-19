# frozen_string_literal: true

module BetterStructureSql
  module SchemaVersions
    class << self
      # Store current schema from file
      def store_current(connection = ActiveRecord::Base.connection)
        config = BetterStructureSql.configuration
        format_type, content = read_current_schema(config)

        return nil unless content

        pg_version = PgVersion.detect(connection)

        store(
          content: content,
          format_type: format_type,
          pg_version: pg_version,
          connection: connection
        )
      end

      # Store schema version with explicit parameters
      def store(content:, format_type:, pg_version:, connection: ActiveRecord::Base.connection)
        ensure_table_exists!(connection)

        version = SchemaVersion.create!(
          content: content,
          format_type: format_type,
          pg_version: pg_version,
          created_at: Time.current
        )

        cleanup!(connection)

        version
      end

      # Retrieval methods
      def latest
        return nil unless table_exists?

        SchemaVersion.latest
      end

      def all_versions
        return [] unless table_exists?

        SchemaVersion.order(created_at: :desc).to_a
      end

      def find(id)
        return nil unless table_exists?

        SchemaVersion.find_by(id: id)
      end

      def count
        return 0 unless table_exists?

        SchemaVersion.count
      end

      def by_format(format_type)
        return [] unless table_exists?

        SchemaVersion.by_format(format_type).order(created_at: :desc).to_a
      end

      # Retention management
      def cleanup!(_connection = ActiveRecord::Base.connection)
        return 0 unless table_exists?

        config = BetterStructureSql.configuration
        limit = config.schema_versions_limit

        # Skip cleanup if unlimited (0)
        return 0 if limit.zero?

        # Delete oldest versions beyond limit
        total_count = SchemaVersion.count
        return 0 if total_count <= limit

        versions_to_delete = total_count - limit
        oldest_versions = SchemaVersion.oldest_first.limit(versions_to_delete)

        deleted_count = 0
        oldest_versions.each do |version|
          version.destroy
          deleted_count += 1
        end

        deleted_count
      end

      private

      def read_current_schema(config)
        sql_path = Rails.root.join(config.output_path)
        rb_path = Rails.root.join('db/schema.rb')

        if File.exist?(sql_path)
          ['sql', File.read(sql_path)]
        elsif File.exist?(rb_path)
          ['rb', File.read(rb_path)]
        else
          [nil, nil]
        end
      end

      def ensure_table_exists!(_connection)
        return if table_exists?

        raise Error, "Schema versions table does not exist. Run migration first:\n  " \
                     "rails generate better_structure_sql:migration\n  " \
                     'rails db:migrate'
      end

      def table_exists?
        ActiveRecord::Base.connection.table_exists?('better_structure_sql_schema_versions')
      rescue ActiveRecord::NoDatabaseError
        false
      end
    end
  end
end
