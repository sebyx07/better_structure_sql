# frozen_string_literal: true

module BetterStructureSql
  # Schema version storage and retrieval operations
  #
  # Provides class methods for storing, querying, and managing
  # schema versions with automatic retention cleanup.
  module SchemaVersions
    # Chunk size for streaming file reads (4MB)
    # Balances memory efficiency with read performance
    STREAM_CHUNK_SIZE = 4 * 1024 * 1024

    class << self
      # Store current schema from file with automatic deduplication
      #
      # Calculates content hash and compares with latest version.
      # Skips storage if hash matches (no schema changes).
      # The schema file or directory on disk is never modified.
      #
      # @param connection [ActiveRecord::Connection] Database connection
      # @param config [Configuration] Configuration naming the schema output path
      # @return [StoreResult] Result indicating stored or skipped
      # @raise [SchemaVersionError] If there is no schema file or directory to store
      def store_current(connection = ActiveRecord::Base.connection, config: BetterStructureSql.configuration)
        output_mode = detect_output_mode(config.output_path)
        content, zip_archive, file_count = read_schema_content(config.output_path, output_mode)
        raise SchemaVersionError, missing_schema_message(config.output_path) unless content

        content_hash = calculate_hash(content)

        # Compare with latest version's hash
        ensure_table_exists!(connection)
        latest_version = latest
        # Skip storage - no changes detected
        return build_skip_result(latest_version, count) if latest_version&.hash_matches?(content_hash)

        version = store(
          content:,
          content_hash:,
          zip_archive:,
          format_type: deduce_format_type(config.output_path),
          output_mode:,
          pg_version: PgVersion.detect(connection),
          file_count:,
          connection:
        )

        # Cleanup old versions (retention management)
        cleanup!(connection)

        build_stored_result(version)
      end

      # Store schema version with explicit parameters
      #
      # @param content [String] Schema content
      # @param content_hash [String] MD5 hash of content (required)
      # @param format_type [String] Format type ('sql' or 'rb')
      # @param pg_version [String] PostgreSQL version
      # @param options [Hash] Optional parameters (connection, output_mode, zip_archive, file_count)
      # @return [SchemaVersion] Created version
      def store(content:, content_hash:, format_type:, pg_version:, **options)
        connection = options.fetch(:connection, ActiveRecord::Base.connection)
        output_mode = options.fetch(:output_mode, 'single_file')
        zip_archive = options[:zip_archive]
        file_count = options[:file_count]

        ensure_table_exists!(connection)

        SchemaVersion.create!(
          content:,
          content_hash:,
          content_size: content.bytesize,
          line_count: content.count("\n"),
          zip_archive:,
          format_type:,
          output_mode:,
          pg_version:,
          file_count:,
          created_at: Time.current
        )
      end

      # Replaces the schema of a database with a stored version
      #
      # The database is purged first (every table and all data are dropped, the
      # stored schema versions included), so the stored schema loads into an empty
      # database. A schema that fails to load leaves the database purged.
      #
      # @param version [SchemaVersion] Version to restore, already read from the database
      # @param db_config [ActiveRecord::DatabaseConfigurations::DatabaseConfig] Database to replace
      # @return [void]
      def restore(version, db_config: ActiveRecord::Base.connection_db_config)
        Dir.mktmpdir('schema_restore') do |directory|
          path = write_version_files(version, directory)

          ActiveRecord::Tasks::DatabaseTasks.purge(db_config)
          ActiveRecord::Base.establish_connection(db_config)
          SchemaLoader.new.load_and_record(path)
        end
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

        SchemaVersion.find_by(id:)
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

      # Hash calculation methods

      # Calculates MD5 hash of schema content
      #
      # @param content [String] Schema content to hash
      # @return [String] 32-character MD5 hexdigest
      # @raise [ArgumentError] If content is nil
      def calculate_hash(content)
        raise ArgumentError, 'Content cannot be nil' if content.nil?

        require 'digest/md5'
        Digest::MD5.hexdigest(content)
      end

      # Calculates hash from a single schema file using streaming
      #
      # Streams file in 4MB chunks to avoid loading entire file into memory.
      # Efficient for large schema files (100MB+).
      #
      # @param path [String, Pathname] Path to schema file
      # @return [String] 32-character MD5 hexdigest
      # @raise [Errno::ENOENT] If file not found
      def calculate_hash_from_file(path)
        full_path = Rails.root.join(path)
        raise Errno::ENOENT, "File not found: #{path}" unless File.exist?(full_path)

        digest = Digest::MD5.new
        File.open(full_path, 'rb') do |file|
          while (chunk = file.read(STREAM_CHUNK_SIZE))
            digest.update(chunk)
          end
        end
        digest.hexdigest
      end

      # Calculates hash from multi-file schema directory using streaming
      #
      # Streams only .sql files (header + numbered directories) in order.
      # Uses 4MB chunks for memory efficiency with large schemas.
      #
      # Note: Manifest JSON is excluded from hash calculation as it's metadata
      # for tooling, not part of the actual schema content.
      #
      # @param path [String, Pathname] Path to schema directory
      # @return [String] 32-character MD5 hexdigest
      # @raise [Errno::ENOENT] If directory not found
      def calculate_hash_from_directory(path)
        full_path = Rails.root.join(path)
        raise Errno::ENOENT, "Directory not found: #{path}" unless Dir.exist?(full_path)

        digest = Digest::MD5.new

        # Stream _header.sql if exists
        header_path = full_path.join('_header.sql')
        stream_file_to_digest(digest, header_path) if File.exist?(header_path)

        # Stream all .sql files from numbered directories in order (01_extensions through 20_migrations)
        Dir.glob(File.join(full_path, '*_*')).select { |f| File.directory?(f) }.sort.each do |dir|
          Dir.glob(File.join(dir, '*.sql')).each do |file|
            stream_file_to_digest(digest, file)
          end
        end

        digest.hexdigest
      end

      # Combined read and hash operation
      #
      # @param output_path [String, Pathname] Path to schema file or directory
      # @param output_mode [String] 'single_file' or 'multi_file'
      # @return [Array<String, String, String, Integer>] content, content_hash, zip_archive, file_count
      def read_and_hash_content(output_path, output_mode)
        content, zip_archive, file_count = read_schema_content(output_path, output_mode)
        return [nil, nil, nil, nil] unless content

        content_hash = calculate_hash(content)
        [content, content_hash, zip_archive, file_count]
      end

      # Hash query methods

      # Retrieves content_hash of the most recent schema version
      #
      # @param _connection [ActiveRecord::Connection] Database connection (optional)
      # @return [String, nil] Hash of latest version or nil if no versions exist
      def latest_hash(_connection = ActiveRecord::Base.connection)
        return nil unless table_exists?

        SchemaVersion.latest&.content_hash
      end

      # Checks if a content hash exists in stored versions
      #
      # @param hash [String] Content hash to search for
      # @param _connection [ActiveRecord::Connection] Database connection (optional)
      # @return [Boolean] True if hash found, false otherwise
      def hash_exists?(hash, _connection = ActiveRecord::Base.connection)
        return false unless table_exists?

        SchemaVersion.exists?(content_hash: hash)
      end

      # Finds schema version by content hash
      #
      # Returns most recent version if multiple versions have the same hash.
      #
      # @param hash [String] Content hash to search for
      # @param _connection [ActiveRecord::Connection] Database connection (optional)
      # @return [SchemaVersion, nil] Found version or nil
      def find_by_hash(hash, _connection = ActiveRecord::Base.connection)
        return nil unless table_exists?

        SchemaVersion.where(content_hash: hash).order(created_at: :desc).first
      end

      # Retention management
      def cleanup!(_connection = ActiveRecord::Base.connection)
        return 0 unless table_exists?

        config = BetterStructureSql.configuration
        limit = config.schema_versions_limit

        # Skip cleanup if unlimited (0)
        return 0 if limit.zero?

        # Delete oldest versions beyond limit without loading their content into memory
        excess = SchemaVersion.count - limit
        return 0 unless excess.positive?

        excess_ids = SchemaVersion.oldest_first.limit(excess).pluck(:id)
        SchemaVersion.where(id: excess_ids).delete_all
      end

      private

      # Builds a skip result when storage is not needed
      #
      # @param version [SchemaVersion, nil] Existing version that matched
      # @param total_count [Integer] Total version count
      # @return [StoreResult] Skip result
      def build_skip_result(version, total_count)
        StoreResult.new(
          skipped: true,
          version_id: version&.id,
          hash: version&.content_hash,
          total_count:
        )
      end

      def missing_schema_message(output_path)
        "No schema found at #{output_path}. Dump it first with: rails db:schema:dump_better"
      end

      # Builds a stored result when new version was created
      #
      # @param version [SchemaVersion] Newly created version
      # @return [StoreResult] Stored result
      def build_stored_result(version)
        StoreResult.new(
          skipped: false,
          version:,
          total_count: count
        )
      end

      # Writes a stored version to disk in the form SchemaLoader loads
      #
      # @param version [SchemaVersion] Stored version
      # @param directory [String] Directory to write into
      # @return [String] Path of the schema file or directory
      def write_version_files(version, directory)
        if version.multi_file?
          path = File.join(directory, 'schema')
          ZipGenerator.extract_to_directory(version.zip_archive, path)
        else
          path = File.join(directory, "schema.#{version.format_type}")
          File.write(path, version.content)
        end
        path
      end

      # Streams a file to digest using STREAM_CHUNK_SIZE chunks
      #
      # @param digest [Digest::MD5] Digest instance to update
      # @param file_path [String, Pathname] Path to file
      def stream_file_to_digest(digest, file_path)
        File.open(file_path, 'rb') do |file|
          while (chunk = file.read(STREAM_CHUNK_SIZE))
            digest.update(chunk)
          end
        end
      end

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

        # Read _header.sql if exists
        header_path = base_path.join('_header.sql')
        content_parts << File.read(header_path) if File.exist?(header_path)

        # Read all .sql files from numbered directories in order (01_extensions through 20_migrations)
        # Note: Manifest JSON is excluded as it's metadata, not schema content
        Dir.glob(File.join(base_path, '*_*')).select { |f| File.directory?(f) }.sort.each do |dir|
          Dir.glob(File.join(dir, '*.sql')).each do |file|
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
