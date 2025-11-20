# frozen_string_literal: true

module BetterStructureSql
  # Base error class for all BetterStructureSql errors
  class Error < StandardError; end

  # Raised when adapter-specific operations fail
  class AdapterError < Error; end

  # Raised when database introspection fails
  class IntrospectionError < Error; end

  # Raised when SQL generation fails
  class GenerationError < Error; end

  # Raised when configuration is invalid
  class ConfigurationError < Error; end

  # Raised when schema versioning operations fail
  class SchemaVersionError < Error; end

  # Raised when file operations fail
  class FileError < Error; end
end
