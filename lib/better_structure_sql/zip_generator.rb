# frozen_string_literal: true

require 'zip'
require 'stringio'

module BetterStructureSql
  # Handles creating and extracting ZIP archives for multi-file schema dumps
  class ZipGenerator
    MAX_FILES_IN_ZIP = 300_000
    MAX_UNCOMPRESSED_SIZE = 800.megabytes

    class ZipError < StandardError; end

    # Create ZIP from existing directory
    # @param dir_path [String, Pathname] The directory path
    # @return [String] ZIP file binary data
    def self.create_from_directory(dir_path)
      buffer = Zip::OutputStream.write_buffer do |zip|
        Dir.glob("#{dir_path}/**/*").sort.each do |file_path|
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
    # @param zip_binary [String] ZIP file binary data
    # @param target_dir [String, Pathname] Target directory path
    def self.extract_to_directory(zip_binary, target_dir)
      FileUtils.mkdir_p(target_dir)

      Zip::File.open_buffer(StringIO.new(zip_binary)) do |zip_file|
        zip_file.each do |entry|
          # Security: rubyzip already prevents path traversal, but verify anyway
          next if entry.name.include?('..')

          path = File.join(target_dir, entry.name)
          FileUtils.mkdir_p(File.dirname(path))
          entry.extract(path) unless File.exist?(path)
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
  end
end
