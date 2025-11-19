# frozen_string_literal: true

require 'json'

module BetterStructureSql
  # Generates manifest JSON files for multi-file schema dumps
  # Provides statistics and metadata about the schema files
  class ManifestGenerator
    attr_reader :config

    def initialize(config = BetterStructureSql.configuration)
      @config = config
    end

    # Generate JSON manifest from file map
    # @param file_map [Hash] Map of relative_path => content
    # @return [String] JSON manifest string
    def generate(file_map)
      manifest = {
        version: '1.0',
        total_files: file_map.size,
        total_lines: calculate_total_lines(file_map),
        max_lines_per_file: config.max_lines_per_file,
        directories: calculate_directory_stats(file_map)
      }

      JSON.pretty_generate(manifest)
    end

    # Parse manifest JSON string
    # @param json_string [String] The JSON manifest
    # @return [Hash] Parsed manifest data
    def parse(json_string)
      JSON.parse(json_string, symbolize_names: true)
    end

    private

    # Calculate total lines across all files
    # @param file_map [Hash] Map of relative_path => content
    # @return [Integer] Total line count
    def calculate_total_lines(file_map)
      file_map.values.sum { |content| content.lines.count }
    end

    # Calculate statistics per directory
    # @param file_map [Hash] Map of relative_path => content
    # @return [Hash] Directory name => {files:, lines:}
    def calculate_directory_stats(file_map)
      stats = Hash.new { |h, k| h[k] = { files: 0, lines: 0 } }

      file_map.each do |path, content|
        # Extract directory name (e.g., "1_extensions" from "1_extensions/000001.sql")
        directory = path.split('/').first
        next unless directory

        stats[directory][:files] += 1
        stats[directory][:lines] += content.lines.count
      end

      # Sort by directory name to ensure consistent ordering
      stats.sort.to_h
    end
  end
end
