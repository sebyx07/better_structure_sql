# frozen_string_literal: true

module BetterStructureSql
  # Handles writing schema output to either a single file or multiple files
  # with intelligent chunking based on line count limits.
  class FileWriter
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
      File.write(full_path, content)
    end

    # Write schema sections to multiple files with chunking
    # @param base_path [String] The base directory path
    # @param sections [Hash] Hash of section_name => array of SQL strings
    # @param header [String] The header content (SET statements, etc.)
    def write_multi_file(base_path, sections, header)
      full_base_path = Rails.root.join(base_path)
      FileUtils.mkdir_p(full_base_path)

      # Write header file
      write_chunk(full_base_path, '_header.sql', header)

      # Define section order with directory prefixes
      # Order CRITICAL for schema loading - respects dependency chain:
      # extensions -> types/domains -> functions -> sequences -> tables -> indexes/fks -> views -> triggers -> migrations
      section_order = {
        extensions: '01_extensions',     # Must be first (enable features)
        types: '02_types',               # Before domains and tables
        domains: '02_types',             # Bundled with types (domains are custom types)
        functions: '03_functions',       # Before triggers that call them
        sequences: '04_sequences',       # Before tables that use them
        tables: '05_tables',             # Core schema
        indexes: '06_indexes',           # After tables exist
        foreign_keys: '07_foreign_keys', # After all tables exist
        views: '08_views',               # After tables (may use functions)
        materialized_views: '08_views',  # Bundled with views
        triggers: '09_triggers',         # After tables and functions
        comments: '11_comments',         # After all objects are created
        migrations: '10_migrations'      # Last (schema_migrations INSERT)
      }

      file_map = {}
      directory_file_counters = Hash.new(0) # Track file numbers per directory

      # Group sections by directory to handle shared directories correctly
      sections_by_directory = {}
      section_order.each do |section_key, directory_name|
        next unless sections.key?(section_key)

        section_content = sections[section_key]
        next if section_content.blank?

        sections_by_directory[directory_name] ||= []
        sections_by_directory[directory_name].concat(section_content)
      end

      # Process each directory (with merged content from multiple sections)
      sections_by_directory.each do |directory_name, merged_content|
        # Create directory
        section_dir = full_base_path.join(directory_name)
        FileUtils.mkdir_p(section_dir)

        # Chunk the merged content and write files
        chunks = chunk_section(merged_content, config.max_lines_per_file)
        chunks.each do |chunk|
          # Increment counter for this directory
          directory_file_counters[directory_name] += 1
          filename = format_filename(directory_file_counters[directory_name])
          file_path = section_dir.join(filename)
          content = chunk.join("\n\n")
          File.write(file_path, "#{content}\n")

          # Track in file map for manifest
          relative_path = "#{directory_name}/#{filename}"
          file_map[relative_path] = content
        end
      end

      file_map
    end

    private

    # Chunk an array of SQL strings into file-sized groups
    # Each chunk respects max_lines_per_file with overflow_threshold
    # Single objects larger than max_lines get their own file
    #
    # @param objects [Array<String>] Array of SQL strings
    # @param max_lines [Integer] Maximum lines per file
    # @return [Array<Array<String>>] Array of chunks, each chunk is array of SQL strings
    def chunk_section(objects, max_lines)
      return [] if objects.empty?

      chunks = []
      current_chunk = []
      current_lines = 0
      max_with_overflow = (max_lines * config.overflow_threshold).to_i

      objects.each do |object|
        object_lines = object.lines.count

        # If this single object exceeds max_lines, give it a dedicated file
        if object_lines > max_lines
          # Flush current chunk if it has content
          chunks << current_chunk unless current_chunk.empty?

          # Single object in its own chunk
          chunks << [object]

          # Reset for next chunk
          current_chunk = []
          current_lines = 0
          next
        end

        # Decide whether to start a new chunk
        # If current chunk is already at max_lines, definitely start new chunk
        # If current chunk is under max_lines but adding this would exceed overflow, start new chunk
        # Otherwise, add to current chunk (even if it puts us slightly over max_lines, up to overflow threshold)
        if current_lines >= max_lines
          # Current chunk is full, start new one
          chunks << current_chunk unless current_chunk.empty?
          current_chunk = [object]
          current_lines = object_lines
        elsif current_lines.positive? && (current_lines + object_lines) > max_with_overflow
          # Adding this would exceed overflow threshold, start new chunk
          chunks << current_chunk
          current_chunk = [object]
          current_lines = object_lines
        else
          # Add to current chunk (may go slightly over max_lines, within overflow)
          current_chunk << object
          current_lines += object_lines
        end
      end

      # Don't forget the last chunk
      chunks << current_chunk unless current_chunk.empty?

      chunks
    end

    # Write a single chunk file
    # @param directory [Pathname] The directory path
    # @param filename [String] The filename
    # @param content [String] The file content
    def write_chunk(directory, filename, content)
      file_path = directory.join(filename)
      File.write(file_path, content)
    end

    # Generate zero-padded filename
    # @param index [Integer] The file number (1-based)
    # @return [String] Formatted filename like "000001.sql"
    def format_filename(index)
      "#{index.to_s.rjust(6, '0')}.sql"
    end
  end
end
