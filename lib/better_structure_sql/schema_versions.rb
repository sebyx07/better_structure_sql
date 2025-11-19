# frozen_string_literal: true

module BetterStructureSql
  # Schema version storage and retrieval operations
  #
  # Provides class methods for storing, querying, and managing
  # schema versions with automatic retention cleanup.
  module SchemaVersions
    class << self
      # Store current schema from file
      def store_current(connection = ActiveRecord::Base.connection)
        config = BetterStructureSql.configuration
        pg_version = PgVersion.detect(connection)

        # Determine format and output mode
        format_type = deduce_format_type(config.output_path)
        output_mode = detect_output_mode(config.output_path)

        # Read content
        content, zip_archive, file_count = read_schema_content(config.output_path, output_mode)

        return nil unless content

        store(
          content: content,
          zip_archive: zip_archive,
          format_type: format_type,
          output_mode: output_mode,
          pg_version: pg_version,
          file_count: file_count,
          connection: connection
        )
      end

      # Store schema version with explicit parameters
      def store(content:, format_type:, pg_version:, **options)
        connection = options.fetch(:connection, ActiveRecord::Base.connection)
        output_mode = options.fetch(:output_mode, 'single_file')
        zip_archive = options[:zip_archive]
        file_count = options[:file_count]

        ensure_table_exists!(connection)

        version = SchemaVersion.create!(
          content: content,
          zip_archive: zip_archive,
          format_type: format_type,
          output_mode: output_mode,
          pg_version: pg_version,
          file_count: file_count,
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

      # Returns all stored schema versions
      #
      # @return [Array<SchemaVersion>] All versions ordered by creation date (newest first)
      def all_versions
        return [] unless table_exists?

        SchemaVersion.order(created_at: :desc).to_a
      end

      # Finds schema version by ID
      #
      # @param id [Integer] Version ID
      # @return [SchemaVersion, nil] Found version or nil
      def find(id)
        return nil unless table_exists?

        SchemaVersion.find_by(id: id)
      end

      # Returns total count of stored versions
      #
      # @return [Integer] Version count
      def count
        return 0 unless table_exists?

        SchemaVersion.count
      end

      # Returns versions filtered by format type
      #
      # @param format_type [String] Format type ('sql' or 'rb')
      # @return [Array<SchemaVersion>] Matching versions
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

      def read_schema_content(output_path, output_mode)
        case output_mode
        when 'single_file'
          full_path = Rails.root.join(output_path)
          return [nil, nil, nil] unless File.exist?(full_path)

          content = File.read(full_path)
          [content, nil, nil]

        when 'multi_file'
          full_path = Rails.root.join(output_path)
          return [nil, nil, nil] unless Dir.exist?(full_path)

          # Read all files and combine into single content
          content = read_multi_file_content(full_path)

          # Create ZIP archive from directory
          zip_archive = ZipGenerator.create_from_directory(full_path)

          # Count files
          file_count = Dir.glob("#{full_path}/**/*.sql").count

          [content, zip_archive, file_count]
        end
      end

      def read_multi_file_content(base_path)
        content_parts = []

        # Read header
        header_path = base_path.join('_header.sql')
        content_parts << File.read(header_path) if File.exist?(header_path)

        # Read manifest and embed as SQL comment for later extraction
        manifest_path = base_path.join('_manifest.json')
        if File.exist?(manifest_path)
          manifest_json = File.read(manifest_path)
          content_parts << "-- MANIFEST_JSON_START\n-- #{manifest_json.gsub("\n", "\n-- ")}\n-- MANIFEST_JSON_END"
        end

        # Read numbered directories in order (01_ through 10_)
        # Use pattern that works with Dir.glob
        Dir.glob(File.join(base_path, '*_*')).select { |f| File.directory?(f) }.sort.each do |dir|
          Dir.glob(File.join(dir, '*.sql')).sort.each do |file|
            content_parts << File.read(file)
          end
        end

        content_parts.join("\n\n")
      end

      def detect_output_mode(path)
        # No extension → directory → multi_file
        # Has extension (.sql, .rb) → file → single_file
        File.extname(path.to_s).empty? ? 'multi_file' : 'single_file'
      end

      def deduce_format_type(path)
        # Deduce format from file extension in output_path
        if path.to_s.end_with?('.rb')
          'rb'
        else
          'sql' # Default to SQL for .sql or any other extension
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
