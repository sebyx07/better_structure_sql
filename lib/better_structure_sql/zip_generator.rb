# frozen_string_literal: true

require 'zip'
require 'stringio'

module BetterStructureSql
  # Handles creating and extracting ZIP archives for multi-file schema dumps
  class ZipGenerator
    MAX_FILES_IN_ZIP = 300_000
    MAX_UNCOMPRESSED_SIZE = 800.megabytes
    EXTRACT_CHUNK_SIZE = 1.megabyte

    class ZipError < StandardError; end

    # Create ZIP from existing directory
    # @param dir_path [String, Pathname] The directory path
    # @return [String] ZIP file binary data
    def self.create_from_directory(dir_path)
      buffer = Zip::OutputStream.write_buffer do |zip|
        Dir.glob("#{dir_path}/**/*").each do |file_path|
          next if File.directory?(file_path)

          relative_path = file_path.sub("#{dir_path}/", '')
          zip.put_next_entry(relative_path)
          zip.write File.read(file_path)
        end
      end

      buffer.string
    end

    # Create ZIP from file map (path => content hash)
    # @param file_map [Hash<String, String>] Hash of relative paths to content
    # @return [String] ZIP file binary data
    def self.create_from_file_map(file_map)
      buffer = Zip::OutputStream.write_buffer do |zip|
        file_map.sort.each do |path, content|
          zip.put_next_entry(path)
          zip.write content
        end
      end

      buffer.string
    end

    # Extract ZIP to directory
    #
    # Enforces the safety limits and refuses entries that would land outside the target.
    #
    # @param zip_binary [String] ZIP file binary data
    # @param target_dir [String, Pathname] Target directory path
    # @raise [ZipError] if the ZIP exceeds safety limits or contains an unsafe path
    def self.extract_to_directory(zip_binary, target_dir)
      validate_zip!(zip_binary)
      FileUtils.mkdir_p(target_dir)
      remaining_bytes = MAX_UNCOMPRESSED_SIZE

      Zip::File.open_buffer(StringIO.new(zip_binary)) do |zip_file|
        zip_file.each do |entry|
          next if entry.directory?

          remaining_bytes -= extract_entry(entry, safe_entry_path(entry.name, target_dir), remaining_bytes)
        end
      end
    end

    # Validate ZIP safety (prevent ZIP bombs)
    # @param zip_binary [String] ZIP file binary data
    # @raise [ZipError] if ZIP exceeds safety limits
    def self.validate_zip!(zip_binary)
      file_count = 0
      total_size = 0

      Zip::File.open_buffer(StringIO.new(zip_binary)) do |zip_file|
        zip_file.each do |entry|
          file_count += 1
          total_size += entry.size

          raise ZipError, "Too many files in ZIP (max #{MAX_FILES_IN_ZIP})" if file_count > MAX_FILES_IN_ZIP
          raise ZipError, "ZIP content too large (max #{MAX_UNCOMPRESSED_SIZE} bytes)" if total_size > MAX_UNCOMPRESSED_SIZE
        end
      end
    end

    # Resolve an entry name inside the target directory
    # @raise [ZipError] if the entry would be written outside the target directory
    def self.safe_entry_path(entry_name, target_dir)
      root = File.expand_path(target_dir)
      path = File.expand_path(File.join(root, entry_name))
      return path if path.start_with?("#{root}#{File::SEPARATOR}")

      raise ZipError, "Unsafe path in ZIP: #{entry_name}"
    end
    private_class_method :safe_entry_path

    # Write one entry, trusting the bytes actually decompressed rather than the declared size
    # @return [Integer] Bytes written
    # @raise [ZipError] if the entry inflates past the remaining byte budget
    def self.extract_entry(entry, path, remaining_bytes)
      FileUtils.mkdir_p(File.dirname(path))
      written = 0

      File.open(path, 'wb') do |file|
        entry.get_input_stream do |stream|
          while (chunk = stream.read(EXTRACT_CHUNK_SIZE))
            written += chunk.bytesize
            raise ZipError, "ZIP content too large (max #{MAX_UNCOMPRESSED_SIZE} bytes)" if written > remaining_bytes

            file.write(chunk)
          end
        end
      end

      written
    end
    private_class_method :extract_entry
  end
end
