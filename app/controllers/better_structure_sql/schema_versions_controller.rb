# frozen_string_literal: true

module BetterStructureSql
  class SchemaVersionsController < ApplicationController
    # Maximum file size to load into memory (2MB)
    MAX_MEMORY_SIZE = 2.megabytes
    # Maximum file size to display in browser (200KB)
    MAX_DISPLAY_SIZE = 200.kilobytes

    # GET /better_structure_sql/schema_versions
    def index
      @schema_versions = SchemaVersion.order(created_at: :desc).limit(100)
    end

    # GET /better_structure_sql/schema_versions/:id
    def show
      @schema_version = SchemaVersion.select(:id, :pg_version, :format_type, :created_at, :updated_at,
                                             'LENGTH(content) as content_size').find(params[:id])

      # Only load content if it's small enough to display
      if @schema_version.content_size <= MAX_DISPLAY_SIZE
        @schema_version = SchemaVersion.find(params[:id])
      end
    rescue ActiveRecord::RecordNotFound
      render plain: 'Schema version not found', status: :not_found
    end

    # GET /better_structure_sql/schema_versions/:id/raw
    def raw
      version = SchemaVersion.select(:id, :format_type, 'LENGTH(content) as content_size').find(params[:id])

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

    private

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
