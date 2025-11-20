# frozen_string_literal: true

require 'rails_helper'
require 'digest'

RSpec.describe BetterStructureSql::SchemaVersion, type: :model do
  describe 'metadata callbacks' do
    describe 'before_save :set_metadata' do
      it 'automatically sets content_size on create' do
        content = 'A' * 1000
        version = described_class.create!(
          content: content,
          content_hash: Digest::MD5.hexdigest(content),
          pg_version: 'PostgreSQL 15.1',
          format_type: 'sql',
          output_mode: 'single_file'
        )

        expect(version.content_size).to eq(1000)
      end

      it 'automatically sets line_count on create' do
        content = "Line 1\nLine 2\nLine 3"
        version = described_class.create!(
          content: content,
          content_hash: Digest::MD5.hexdigest(content),
          pg_version: 'PostgreSQL 15.1',
          format_type: 'sql',
          output_mode: 'single_file'
        )

        expect(version.line_count).to eq(3)
      end

      it 'updates metadata when content changes' do
        content = 'Original content'
        version = described_class.create!(
          content: content,
          content_hash: Digest::MD5.hexdigest(content),
          pg_version: 'PostgreSQL 15.1',
          format_type: 'sql',
          output_mode: 'single_file'
        )

        original_size = version.content_size
        version.line_count

        new_content = "New content\nWith multiple\nLines"
        version.update!(content: new_content, content_hash: Digest::MD5.hexdigest(new_content))

        expect(version.content_size).not_to eq(original_size)
        expect(version.line_count).to eq(3)
      end

      it 'does not update metadata when content has not changed' do
        content = 'Test content'
        version = described_class.create!(
          content: content,
          content_hash: Digest::MD5.hexdigest(content),
          pg_version: 'PostgreSQL 15.1',
          format_type: 'sql',
          output_mode: 'single_file'
        )

        original_size = version.content_size
        original_lines = version.line_count

        # Update pg_version but not content
        version.update!(pg_version: 'PostgreSQL 16.0')

        expect(version.content_size).to eq(original_size)
        expect(version.line_count).to eq(original_lines)
      end
    end
  end

  describe '#size' do
    context 'when content_size is present and content has not changed' do
      it 'returns stored content_size' do
        content = 'A' * 500
        version = described_class.create!(
          content: content,
          content_hash: Digest::MD5.hexdigest(content),
          pg_version: 'PostgreSQL 15.1',
          format_type: 'sql',
          output_mode: 'single_file'
        )

        # Reload to ensure content_size is from database
        version.reload

        expect(version.size).to eq(500)
      end
    end

    context 'when content has changed but not saved' do
      it 'calculates size from current content' do
        content = 'A' * 500
        version = described_class.create!(
          content: content,
          content_hash: Digest::MD5.hexdigest(content),
          pg_version: 'PostgreSQL 15.1',
          format_type: 'sql',
          output_mode: 'single_file'
        )

        version.content = 'B' * 1000

        expect(version.size).to eq(1000)
      end
    end
  end

  describe '#formatted_size' do
    it 'formats bytes correctly' do
      content = 'A' * 500
      version = described_class.create!(
        content: content,
        content_hash: Digest::MD5.hexdigest(content),
        pg_version: 'PostgreSQL 15.1',
        format_type: 'sql',
        output_mode: 'single_file'
      )

      expect(version.formatted_size).to eq('500 bytes')
    end

    it 'formats kilobytes correctly' do
      content = 'A' * 2048
      version = described_class.create!(
        content: content,
        content_hash: Digest::MD5.hexdigest(content),
        pg_version: 'PostgreSQL 15.1',
        format_type: 'sql',
        output_mode: 'single_file'
      )

      expect(version.formatted_size).to eq('2.0 KB')
    end

    it 'formats megabytes correctly' do
      content = 'A' * (2 * 1024 * 1024)
      version = described_class.create!(
        content: content,
        content_hash: Digest::MD5.hexdigest(content),
        pg_version: 'PostgreSQL 15.1',
        format_type: 'sql',
        output_mode: 'single_file'
      )

      expect(version.formatted_size).to eq('2.0 MB')
    end

    context 'when content is not loaded' do
      it 'uses stored content_size' do
        content = 'A' * 2048
        version = described_class.create!(
          content: content,
          content_hash: Digest::MD5.hexdigest(content),
          pg_version: 'PostgreSQL 15.1',
          format_type: 'sql',
          output_mode: 'single_file'
        )

        # Load only metadata, not content
        partial_version = described_class.select(:id, :content_size).find(version.id)

        expect(partial_version.formatted_size).to eq('2.0 KB')
      end
    end
  end

  describe 'edge cases' do
    it 'handles very small content' do
      content = 'a'
      version = described_class.create!(
        content: content,
        content_hash: Digest::MD5.hexdigest(content),
        pg_version: 'PostgreSQL 15.1',
        format_type: 'sql',
        output_mode: 'single_file'
      )

      expect(version.content_size).to eq(1)
      expect(version.line_count).to eq(1)
      expect(version.formatted_size).to eq('1 bytes')
    end

    it 'handles single line without newline' do
      content = 'Single line'
      version = described_class.create!(
        content: content,
        content_hash: Digest::MD5.hexdigest(content),
        pg_version: 'PostgreSQL 15.1',
        format_type: 'sql',
        output_mode: 'single_file'
      )

      expect(version.line_count).to eq(1)
    end

    it 'handles content with multiple newlines' do
      content = "a\n\n\n"
      version = described_class.create!(
        content: content,
        content_hash: Digest::MD5.hexdigest(content),
        pg_version: 'PostgreSQL 15.1',
        format_type: 'sql',
        output_mode: 'single_file'
      )

      expect(version.line_count).to eq(3) # "a\n", "\n", "\n"
    end

    it 'handles very large content' do
      large_content = 'A' * (5 * 1024 * 1024) # 5MB
      version = described_class.create!(
        content: large_content,
        content_hash: Digest::MD5.hexdigest(large_content),
        pg_version: 'PostgreSQL 15.1',
        format_type: 'sql',
        output_mode: 'single_file'
      )

      expect(version.content_size).to eq(5 * 1024 * 1024)
      expect(version.formatted_size).to eq('5.0 MB')
    end
  end
end
