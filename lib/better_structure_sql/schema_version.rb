# frozen_string_literal: true

module BetterStructureSql
  # ActiveRecord model for stored schema versions
  #
  # Stores schema snapshots with metadata for versioning, comparison,
  # and restoration. Supports both single-file and multi-file formats
  # with optional ZIP archive storage.
  class SchemaVersion < ActiveRecord::Base
    self.table_name = 'better_structure_sql_schema_versions'

    # Callbacks
    before_save :set_metadata

    # Validations
    validates :content, presence: true
    validates :pg_version, presence: true
    validates :format_type, presence: true, inclusion: { in: %w[sql rb] }
    validates :output_mode, presence: true, inclusion: { in: %w[single_file multi_file] }

    # Scopes
    scope :latest, -> { order(created_at: :desc).first }
    scope :by_format, ->(type) { where(format_type: type) }
    scope :by_output_mode, ->(mode) { where(output_mode: mode) }
    scope :recent, ->(limit) { order(created_at: :desc).limit(limit) }
    scope :oldest_first, -> { order(created_at: :asc) }

    # Instance methods
    def size
      # Use stored content_size if available and content hasn't changed
      if content_size.present? && !content_changed?
        content_size
      else
        content.bytesize
      end
    end

    # Returns human-readable size string
    #
    # @return [String] Formatted size (e.g., "1.5 MB", "250 KB")
    def formatted_size
      bytes = size
      if bytes < 1024
        "#{bytes} bytes"
      elsif bytes < 1024 * 1024
        "#{(bytes / 1024.0).round(2)} KB"
      else
        "#{(bytes / 1024.0 / 1024.0).round(2)} MB"
      end
    end

    # Checks if this version uses multi-file format
    #
    # @return [Boolean] True if multi-file format
    def multi_file?
      output_mode == 'multi_file'
    end

    # Checks if this version has a ZIP archive
    #
    # @return [Boolean] True if ZIP archive exists
    def zip_archive?
      zip_archive.present?
    end

    # Extracts ZIP archive to target directory
    #
    # @param target_dir [String, Pathname] Target directory path
    # @return [String, nil] Target directory path or nil if no archive
    def extract_zip_to_directory(target_dir)
      return nil unless zip_archive?

      ZipGenerator.extract_to_directory(zip_archive, target_dir)
      target_dir
    end

    private

    def set_metadata
      return unless content_changed?

      self.content_size = content.bytesize
      self.line_count = content.lines.count
    end
  end
end
