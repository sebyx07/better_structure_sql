# frozen_string_literal: true

require 'digest'

FactoryBot.define do
  factory :schema_version, class: 'BetterStructureSql::SchemaVersion' do
    content { "-- Schema content\nCREATE TABLE test (id bigint);" }
    content_hash { Digest::MD5.hexdigest(content) }
    content_size { content.bytesize }
    line_count { content.count("\n") }
    pg_version { 'PostgreSQL 15.1' }
    format_type { 'sql' }
    output_mode { 'single_file' }

    trait :multi_file do
      output_mode { 'multi_file' }
      file_count { 5 }
      zip_archive { 'fake zip data' }
    end

    trait :large do
      content { 'X' * 1_000_000 }
    end

    trait :small do
      content { 'Small schema' }
    end
  end
end
