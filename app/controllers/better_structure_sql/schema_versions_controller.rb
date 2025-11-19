# frozen_string_literal: true

module BetterStructureSql
  # Controller for browsing and downloading stored schema versions
  #
  # Provides web UI actions for listing, viewing, and downloading schema
  # versions stored in the database. Implements memory-efficient streaming
  # for large files and multi-file ZIP archive support.
  #
  # @see SchemaVersion
  class SchemaVersionsController < ApplicationController
    # Maximum file size to load into memory (2MB)
    MAX_MEMORY_SIZE = 2.megabytes
    # Maximum file size to display in browser (200KB)
    MAX_DISPLAY_SIZE = 200.kilobytes

    # Lists stored schema versions with pagination
    #
    # Loads only metadata (no content or zip_archive) for performance.
    # Displays up to 100 most recent versions ordered by creation date.
    #
    # @return [void]
    # GET /better_structure_sql/schema_versions
    def index
      # Load only metadata for listing (no content or zip_archive)
      @schema_versions = SchemaVersion
                         .select(:id, :pg_version, :format_type, :output_mode, :created_at,
                                 :content_size, :file_count)
                         .order(created_at: :desc)
                         .limit(100)
    end

    # Displays details of a specific schema version
    #
    # Loads metadata first for performance. For small single-file versions
    # (under 200KB), loads content for inline display. For multi-file versions,
    # extracts and parses the embedded manifest JSON.
    #
    # @return [void]
    # @raise [ActiveRecord::RecordNotFound] if schema version not found
    # GET /better_structure_sql/schema_versions/:id
    def show
      # Load metadata first
      @schema_version = SchemaVersion
                        .select(:id, :pg_version, :format_type, :output_mode, :created_at,
                                :content_size, :line_count, :file_count)
                        .find(params[:id])

      # Only load content for small single-file versions
      if @schema_version.output_mode == 'single_file' && @schema_version.content_size <= MAX_DISPLAY_SIZE
        @schema_version = SchemaVersion.find(params[:id]) # Load with content
      elsif @schema_version.output_mode == 'multi_file'
        # Load content to extract manifest
        full_version = SchemaVersion.select(:id, :content).find(params[:id])
        @manifest = extract_manifest_from_content(full_version.content)
      end
    rescue ActiveRecord::RecordNotFound
      render plain: 'Schema version not found', status: :not_found
    end

    # Downloads raw content of a schema version as plain text
    #
    # Streams large files (>2MB) in chunks to avoid memory issues.
    # Smaller files are sent directly using send_data.
    #
    # @return [void]
    # @raise [ActiveRecord::RecordNotFound] if schema version not found
    # GET /better_structure_sql/schema_versions/:id/raw
    def raw
      version = SchemaVersion.select(:id, :format_type, :content_size).find(params[:id])

      filename = "schema_version_#{version.id}_#{version.format_type}.txt"

      # For large files, stream from database to avoid loading into memory
      if version.content_size > MAX_MEMORY_SIZE
        stream_large_file(version.id, filename)
      else
        # For smaller files, use regular send_data
        content = SchemaVersion.find(version.id).content
        send_data content,
                  filename: filename,
                  type: 'text/plain',
                  disposition: 'attachment'
      end
    rescue ActiveRecord::RecordNotFound
      render plain: 'Schema version not found', status: :not_found
    end

    # Downloads schema version in appropriate format
    #
    # Multi-file versions with ZIP archives are sent as .zip files.
    # Single-file versions are sent as .sql or .rb files based on format_type.
    #
    # @return [void]
    # @raise [ActiveRecord::RecordNotFound] if schema version not found
    # GET /better_structure_sql/schema_versions/:id/download
    def download
      version = SchemaVersion.find(params[:id])

      if version.multi_file? && version.zip_archive?
        send_zip_download(version)
      else
        send_file_download(version)
      end
    rescue ActiveRecord::RecordNotFound
      render plain: 'Schema version not found', status: :not_found
    end

    private

    # Sends ZIP archive download for multi-file schema versions
    #
    # Validates ZIP archive before sending to prevent corrupted downloads.
    # Filename includes version ID and timestamp.
    #
    # @param version [SchemaVersion] the schema version to download
    # @return [void]
    def send_zip_download(version)
      # Validate ZIP
      BetterStructureSql::ZipGenerator.validate_zip!(version.zip_archive)

      filename = "schema_version_#{version.id}_#{version.created_at.to_i}.zip"

      send_data version.zip_archive,
                filename: filename,
                type: 'application/zip',
                disposition: 'attachment'
    end

    # Sends single-file schema version download
    #
    # Streams large files (>2MB) to avoid memory issues. Filename is
    # structure.sql or structure.rb based on format_type.
    #
    # @param version [SchemaVersion] the schema version to download
    # @return [void]
    def send_file_download(version)
      extension = version.format_type == 'rb' ? 'rb' : 'sql'
      filename = "structure.#{extension}"

      # Handle large files with streaming
      if version.content_size > MAX_MEMORY_SIZE
        stream_large_content(version, filename)
      else
        send_data version.content,
                  filename: filename,
                  type: 'text/plain',
                  disposition: 'attachment'
      end
    end

    # Streams large content in 64KB chunks to avoid memory issues
    #
    # Sets response headers for streaming and disables proxy buffering.
    # Fetches content from database and yields chunks via Enumerator.
    #
    # @param version [SchemaVersion] the schema version to stream
    # @param filename [String] the filename for Content-Disposition header
    # @return [void]
    def stream_large_content(version, filename)
      response.headers['Content-Type'] = 'text/plain'
      response.headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
      response.headers['X-Accel-Buffering'] = 'no'

      self.response_body = Enumerator.new do |yielder|
        content = SchemaVersion.connection.select_value(
          "SELECT content FROM #{SchemaVersion.table_name} WHERE id = #{version.id}"
        )

        chunk_size = 64.kilobytes
        offset = 0
        while offset < content.bytesize
          yielder << content.byteslice(offset, chunk_size)
          offset += chunk_size
        end
      end
    end

    # Extracts embedded manifest JSON from multi-file schema content
    #
    # Manifest is stored between MANIFEST_JSON_START and MANIFEST_JSON_END markers
    # as SQL comments. Parses and returns the manifest hash.
    #
    # @param content [String] the schema content containing embedded manifest
    # @return [Hash, nil] parsed manifest hash or nil if not found/invalid
    def extract_manifest_from_content(content)
      # Manifest is embedded in content between MANIFEST_JSON_START and MANIFEST_JSON_END markers
      return nil unless content.include?('MANIFEST_JSON_START')

      # Extract JSON from between markers, removing comment prefixes
      start_marker = '-- MANIFEST_JSON_START'
      end_marker = '-- MANIFEST_JSON_END'

      start_pos = content.index(start_marker)
      end_pos = content.index(end_marker)

      return nil unless start_pos && end_pos

      manifest_section = content[(start_pos + start_marker.length)..(end_pos - 1)]
      manifest_json = manifest_section.lines
                                      .map { |line| line.sub(/^--\s?/, '') }
                                      .join

      JSON.parse(manifest_json)
    rescue JSON::ParserError => e
      Rails.logger.debug { "Failed to parse manifest: #{e.message}" }
      nil
    end

    # Streams large file content from database in chunks
    #
    # Sets appropriate headers for streaming downloads and disables proxy buffering.
    # Fetches content from database and streams in 64KB chunks via Enumerator.
    #
    # @param version_id [Integer] the schema version ID
    # @param filename [String] the filename for Content-Disposition header
    # @return [void]
    def stream_large_file(version_id, filename)
      # Set headers for streaming
      response.headers['Content-Type'] = 'text/plain'
      response.headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
      response.headers['Cache-Control'] = 'no-cache'
      response.headers['X-Accel-Buffering'] = 'no' # Disable proxy buffering

      # Stream the content in chunks
      self.response_body = Enumerator.new do |yielder|
        # Fetch content in a streaming fashion from database
        SchemaVersion.connection.select_value(
          "SELECT content FROM #{SchemaVersion.table_name} WHERE id = #{version_id}"
        ).tap do |content|
          # Stream in 64KB chunks
          chunk_size = 64.kilobytes
          offset = 0

          while offset < content.bytesize
            yielder << content.byteslice(offset, chunk_size)
            offset += chunk_size
          end
        end
      end
    end
  end
end
