# frozen_string_literal: true

module BetterStructureSql
  # Controller for browsing and downloading stored schema versions
  #
  # Provides web UI actions for listing, viewing, and downloading schema
  # versions stored in the database. Large columns (content, zip_archive)
  # are only read by the actions that send them.
  #
  # @see SchemaVersion
  class SchemaVersionsController < ApplicationController
    # Maximum file size to load into memory (2MB)
    MAX_MEMORY_SIZE = 2.megabytes
    # Maximum file size to display in browser (1MB)
    # Large enough for most schemas but keeps browser responsive
    MAX_DISPLAY_SIZE = 1.megabyte
    # Schema versions listed per page
    PER_PAGE = 100
    # Characters read from the database per streamed chunk
    STREAM_CHUNK_CHARS = 512.kilobytes
    # Columns that are cheap to load (everything except content and zip_archive)
    METADATA_COLUMNS = %i[
      id pg_version format_type output_mode created_at
      content_size line_count file_count content_hash
    ].freeze
    # Content type of every schema text response
    TEXT_CONTENT_TYPE = 'text/plain; charset=utf-8'

    # Lists stored schema versions, newest first, one page at a time
    #
    # Loads only metadata (no content or zip_archive) for performance.
    #
    # @return [void]
    # GET /better_structure_sql/schema_versions?page=2
    def index
      @total_count = SchemaVersion.count
      @total_pages = [(@total_count.to_f / PER_PAGE).ceil, 1].max
      @page = requested_page.clamp(1, @total_pages)
      @schema_versions = SchemaVersion.select(*METADATA_COLUMNS)
                                      .order(created_at: :desc, id: :desc)
                                      .limit(PER_PAGE)
                                      .offset((@page - 1) * PER_PAGE)
                                      .load
    end

    # Displays details of a specific schema version
    #
    # Content is loaded for inline display only when it is at most
    # MAX_DISPLAY_SIZE; otherwise +content+ is nil. The ZIP archive is never
    # loaded.
    #
    # @return [void]
    # GET /better_structure_sql/schema_versions/:id
    def show
      @schema_version = SchemaVersion.select(*METADATA_COLUMNS, displayable_content_sql).find(params[:id])
    end

    # Downloads raw content of a schema version as plain text
    #
    # @return [void]
    # GET /better_structure_sql/schema_versions/:id/raw
    def raw
      version = find_metadata
      send_content(version, "schema_version_#{version.id}_#{file_extension(version)}.txt")
    end

    # Downloads schema version in appropriate format
    #
    # Multi-file versions with ZIP archives are sent as .zip files.
    # Single-file versions are sent as structure.sql or structure.rb.
    #
    # @return [void]
    # GET /better_structure_sql/schema_versions/:id/download
    def download
      version = find_metadata
      zip_archive = SchemaVersion.where(id: version.id).pick(:zip_archive) if version.multi_file?

      if zip_archive.present?
        send_zip_download(version, zip_archive)
      else
        send_content(version, "structure.#{file_extension(version)}")
      end
    end

    private

    def requested_page
      Integer(params[:page].to_s, 10)
    rescue ArgumentError
      1
    end

    # Selects content only when small enough to display, in a single query
    def displayable_content_sql
      Arel.sql("CASE WHEN content_size <= #{MAX_DISPLAY_SIZE.to_i} THEN content END AS content")
    end

    def find_metadata
      SchemaVersion.select(*METADATA_COLUMNS).find(params[:id])
    end

    # Maps the stored format to a known extension so the stored value never
    # reaches a response header
    def file_extension(version)
      version.format_type == 'rb' ? 'rb' : 'sql'
    end

    # Sends the validated ZIP archive of a multi-file schema version
    def send_zip_download(version, zip_archive)
      BetterStructureSql::ZipGenerator.validate_zip!(zip_archive)

      send_data zip_archive,
                filename: "schema_version_#{version.id}_#{version.created_at.to_i}.zip",
                type: 'application/zip',
                disposition: 'attachment'
    rescue Zip::Error, BetterStructureSql::ZipGenerator::ZipError => e
      logger&.error("[BetterStructureSql] Invalid ZIP archive for schema version #{version.id}: #{e.message}")
      render plain: 'Stored ZIP archive is invalid', status: :internal_server_error
    end

    # Sends content as a text attachment, streaming it when larger than MAX_MEMORY_SIZE
    def send_content(version, filename)
      return stream_content(version.id, filename) if version.content_size > MAX_MEMORY_SIZE

      send_data SchemaVersion.where(id: version.id).pick(:content),
                filename:,
                type: TEXT_CONTENT_TYPE,
                disposition: 'attachment'
    end

    def stream_content(version_id, filename)
      response.headers['Content-Type'] = TEXT_CONTENT_TYPE
      response.headers['Content-Disposition'] =
        ActionDispatch::Http::ContentDisposition.format(disposition: 'attachment', filename:)
      response.headers['X-Accel-Buffering'] = 'no' # Disable proxy buffering

      self.response_body = content_chunks(version_id)
    end

    # Reads content from the database one slice at a time, so a large schema
    # is never held in memory as a whole
    def content_chunks(version_id)
      Enumerator.new do |yielder|
        position = 1
        loop do
          chunk = content_slice(version_id, position)
          break if chunk.to_s.empty?

          yielder << chunk
          position += STREAM_CHUNK_CHARS
        end
      end
    end

    def content_slice(version_id, position)
      SchemaVersion.where(id: version_id)
                   .pick(Arel.sql("SUBSTR(content, #{position.to_i}, #{STREAM_CHUNK_CHARS.to_i})"))
    end
  end
end
