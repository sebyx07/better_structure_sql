# frozen_string_literal: true

module BetterStructureSql
  class SchemaVersion < ActiveRecord::Base
    self.table_name = 'better_structure_sql_schema_versions'

    # Callbacks
    before_save :set_metadata

    # Validations
    validates :content, presence: true
    validates :pg_version, presence: true
    validates :format_type, presence: true, inclusion: { in: %w[sql rb] }

    # Scopes
    scope :latest, -> { order(created_at: :desc).first }
    scope :by_format, ->(type) { where(format_type: type) }
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

    private

    def set_metadata
      return unless content_changed?

      self.content_size = content.bytesize
      self.line_count = content.lines.count
    end
  end
end
