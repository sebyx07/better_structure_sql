# frozen_string_literal: true

module BetterStructureSql
  class SchemaVersionsController < ApplicationController
    # Maximum file size to load into memory (2MB)
    MAX_MEMORY_SIZE = 2.megabytes
    # Maximum file size to display in browser (200KB)
    MAX_DISPLAY_SIZE = 200.kilobytes

    # GET /better_structure_sql/schema_versions
    def index
      # Load only metadata for listing (no content or zip_archive)
      @schema_versions = SchemaVersion
                         .select(:id, :pg_version, :format_type, :output_mode, :created_at,
                                 :content_size, :file_count)
                         .order(created_at: :desc)
                         .limit(100)
    end

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

    def send_zip_download(version)
      # Validate ZIP
      BetterStructureSql::ZipGenerator.validate_zip!(version.zip_archive)

      filename = "schema_version_#{version.id}_#{version.created_at.to_i}.zip"

      send_data version.zip_archive,
                filename: filename,
                type: 'application/zip',
                disposition: 'attachment'
    end

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

    def extract_manifest_from_content(content)
      # Manifest is embedded as JSON in _manifest.json file within combined content
      # Look for the manifest marker and extract JSON
      manifest_marker = '-- Manifest:'
      return nil unless content.include?(manifest_marker)

      # Extract JSON from manifest comment
      manifest_json = content.lines.find { |line| line.include?(manifest_marker) }
                             &.sub(/.*-- Manifest:\s*/, '')
                             &.strip

      return nil unless manifest_json

      JSON.parse(manifest_json)
    rescue JSON::ParserError
      nil
    end

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
