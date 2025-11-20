# frozen_string_literal: true

module BetterStructureSql
  # Value object encapsulating schema version storage operation result
  #
  # Provides clean separation between storage logic and output formatting.
  # Used by SchemaVersions.store_current to indicate whether storage occurred
  # or was skipped due to duplicate content hash.
  #
  # @example Stored result
  #   version = SchemaVersion.create!(content: "...", content_hash: "abc123")
  #   result = StoreResult.new(skipped: false, version: version)
  #   result.stored? # => true
  #   result.version_id # => 5
  #
  # @example Skipped result
  #   result = StoreResult.new(skipped: true, version_id: 3, hash: "abc123")
  #   result.skipped? # => true
  #   result.version_id # => 3
  class StoreResult
    attr_reader :version, :version_id, :hash, :total_count

    # @param skipped [Boolean] Whether storage was skipped
    # @param version [SchemaVersion, nil] Created version (when stored)
    # @param version_id [Integer, nil] Existing version ID (when skipped)
    # @param hash [String, nil] Content hash
    # @param total_count [Integer, nil] Total version count after operation
    def initialize(skipped:, version: nil, version_id: nil, hash: nil, total_count: nil)
      @skipped = skipped
      @version = version
      @version_id = version_id || version&.id
      @hash = hash || version&.content_hash
      @total_count = total_count
    end

    # @return [Boolean] True if storage was skipped due to duplicate hash
    def skipped?
      @skipped
    end

    # @return [Boolean] True if new version was stored
    def stored?
      !@skipped
    end
  end
end
