# frozen_string_literal: true

require 'active_support/core_ext/file/atomic'

module BetterStructureSql
  # Handles writing schema output to either a single file or multiple files
  # with intelligent chunking based on line count limits.
  class FileWriter
    HEADER_FILENAME = '_header.sql'
    MANIFEST_FILENAME = '_manifest.json'
    OBJECT_SEPARATOR = "\n\n"
    SEPARATOR_LINES = 1

    # Section => directory. Order is CRITICAL for schema loading, it respects the dependency chain:
    # extensions -> types -> functions -> sequences -> tables -> indexes/fks -> views -> triggers -> migrations
    SECTION_DIRECTORIES = {
      extensions: '01_extensions',     # Must be first (enable features)
      types: '02_types',               # Enums, composites, ranges, domains that need no function
      functions: '03_functions',       # Plus the types that need a function (dependency-ordered)
      sequences: '04_sequences',       # Before tables that use them
      tables: '05_tables',             # Core schema
      indexes: '06_indexes',           # After tables exist
      foreign_keys: '07_foreign_keys', # After all tables exist
      views: '08_views',               # After tables (may use functions)
      materialized_views: '08_views',  # Bundled with views
      triggers: '09_triggers',         # After tables and functions
      comments: '10_comments',         # After all objects are created
      migrations: '20_migrations'      # Last (schema_migrations INSERT)
    }.freeze

    # Matches every numbered section directory, including ones no longer written
    SECTION_DIRECTORY_GLOB = '[0-9]*_*'

    attr_reader :config

    def initialize(config = BetterStructureSql.configuration)
      @config = config
    end

    # Detect if the output path is for single-file or multi-file mode
    # @param path [String] The output path
    # @return [Symbol] :single_file or :multi_file
    def detect_output_mode(path)
      # If path has no extension or is a directory, it's multi-file
      # Otherwise, if it ends with .sql or .rb, it's single-file
      return :multi_file if File.extname(path).empty?
      return :multi_file if path.end_with?('/')

      :single_file
    end

    # Write complete schema to a single file
    # @param path [String] The file path
    # @param content [String] The complete SQL content
    def write_single_file(path, content)
      full_path = Rails.root.join(path)
      FileUtils.mkdir_p(File.dirname(full_path))
      atomic_write(full_path, content)
    end

    # Write schema sections to multiple files with chunking
    #
    # Files left over from a previous, larger dump are removed so the directory
    # always mirrors the current schema (the loader executes every SQL file it finds).
    #
    # @param base_path [String] The base directory path
    # @param sections [Hash] Hash of section_name => array of SQL strings
    # @param header [String, nil] The header content (SET statements, etc.)
    # @return [Hash<String, String>] Map of relative file path => content
    def write_multi_file(base_path, sections, header)
      full_base_path = Rails.root.join(base_path)
      FileUtils.mkdir_p(full_base_path)

      atomic_write(full_base_path.join(HEADER_FILENAME), header.to_s)

      file_map = {}
      group_sections_by_directory(sections).each do |directory_name, objects|
        file_map.merge!(write_directory(full_base_path, directory_name, objects))
      end

      remove_stale_files(full_base_path, file_map)
      file_map
    end

    # Write the manifest file, or remove a leftover one when content is nil
    # @param base_path [String] The base directory path
    # @param content [String, nil] Manifest JSON
    def write_manifest(base_path, content)
      manifest_path = Rails.root.join(base_path, MANIFEST_FILENAME)
      return FileUtils.rm_f(manifest_path) if content.nil?

      atomic_write(manifest_path, content)
    end

    private

    # Merge section contents that share a directory, preserving load order
    # @param sections [Hash] Hash of section_name => array of SQL strings
    # @return [Hash<String, Array<String>>] Directory name => SQL strings
    def group_sections_by_directory(sections)
      SECTION_DIRECTORIES.each_with_object({}) do |(section_key, directory_name), grouped|
        section_content = sections[section_key]
        next if section_content.blank?

        (grouped[directory_name] ||= []).concat(section_content)
      end
    end

    # Chunk and write all objects of one directory
    # @return [Hash<String, String>] Map of relative file path => content
    def write_directory(full_base_path, directory_name, objects)
      section_dir = full_base_path.join(directory_name)
      FileUtils.mkdir_p(section_dir)

      chunks = chunk_section(objects, config.max_lines_per_file)
      chunks.each_with_index.to_h do |chunk, index|
        filename = format_filename(index + 1)
        content = chunk.join(OBJECT_SEPARATOR)
        atomic_write(section_dir.join(filename), "#{content}\n")

        ["#{directory_name}/#{filename}", content]
      end
    end

    # Remove SQL files (and emptied section directories) that the current dump did not write
    def remove_stale_files(full_base_path, file_map)
      Dir.glob(full_base_path.join(SECTION_DIRECTORY_GLOB).to_s).each do |section_dir|
        next unless File.directory?(section_dir)

        Dir.glob(File.join(section_dir, '*.sql')).each do |file_path|
          relative_path = "#{File.basename(section_dir)}/#{File.basename(file_path)}"
          File.delete(file_path) unless file_map.key?(relative_path)
        end

        Dir.rmdir(section_dir) if Dir.empty?(section_dir)
      end
    end

    # Chunk an array of SQL strings into file-sized groups
    # Each chunk respects max_lines_per_file with overflow_threshold, counting
    # the blank line that separates objects in the written file.
    # Single objects larger than max_lines get their own file
    #
    # @param objects [Array<String>] Array of SQL strings
    # @param max_lines [Integer] Maximum lines per file
    # @return [Array<Array<String>>] Array of chunks, each chunk is array of SQL strings
    def chunk_section(objects, max_lines)
      max_with_overflow = (max_lines * config.overflow_threshold).to_i
      chunks = []
      current_lines = 0

      objects.each do |object|
        object_lines = line_count(object)
        lines_if_added = current_lines + SEPARATOR_LINES + object_lines

        if chunks.empty? || start_new_chunk?(current_lines, lines_if_added, max_lines, max_with_overflow)
          chunks << [object]
          current_lines = object_lines
        else
          chunks.last << object
          current_lines = lines_if_added
        end
      end

      chunks
    end

    # A chunk is closed once it is full, or when the next object would push it past the overflow limit
    def start_new_chunk?(current_lines, lines_if_added, max_lines, max_with_overflow)
      current_lines >= max_lines || lines_if_added > max_with_overflow
    end

    # Number of lines an object occupies in the written file
    def line_count(object)
      object.chomp.count("\n") + 1
    end

    # Write a file so readers never observe a partially written dump
    # @param path [Pathname, String] The destination path
    # @param content [String] The file content
    def atomic_write(path, content)
      File.atomic_write(path.to_s, File.dirname(path)) { |file| file.write(content) }
    end

    # Generate zero-padded filename
    # @param index [Integer] The file number (1-based)
    # @return [String] Formatted filename like "000001.sql"
    def format_filename(index)
      "#{index.to_s.rjust(6, '0')}.sql"
    end
  end
end
