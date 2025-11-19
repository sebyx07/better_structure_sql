# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BetterStructureSql::SchemaVersion, type: :model do
  describe 'metadata callbacks' do
    describe 'before_save :set_metadata' do
      it 'automatically sets content_size on create' do
        content = 'A' * 1000
        version = described_class.create!(
          content: content,
          pg_version: 'PostgreSQL 15.1',
          format_type: 'sql'
        )

        expect(version.content_size).to eq(1000)
      end

      it 'automatically sets line_count on create' do
        content = "Line 1\nLine 2\nLine 3"
        version = described_class.create!(
          content: content,
          pg_version: 'PostgreSQL 15.1',
          format_type: 'sql'
        )

        expect(version.line_count).to eq(3)
      end

      it 'updates metadata when content changes' do
        version = described_class.create!(
          content: 'Original content',
          pg_version: 'PostgreSQL 15.1',
          format_type: 'sql'
        )

        original_size = version.content_size
        version.line_count

        version.update!(content: "New content\nWith multiple\nLines")

        expect(version.content_size).not_to eq(original_size)
        expect(version.line_count).to eq(3)
      end

      it 'does not update metadata when content has not changed' do
        version = described_class.create!(
          content: 'Test content',
          pg_version: 'PostgreSQL 15.1',
          format_type: 'sql'
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
        version = described_class.create!(
          content: 'A' * 500,
          pg_version: 'PostgreSQL 15.1',
          format_type: 'sql'
        )

        # Reload to ensure content_size is from database
        version.reload

        expect(version.size).to eq(500)
      end
    end

    context 'when content has changed but not saved' do
      it 'calculates size from current content' do
        version = described_class.create!(
          content: 'A' * 500,
          pg_version: 'PostgreSQL 15.1',
          format_type: 'sql'
        )

        version.content = 'B' * 1000

        expect(version.size).to eq(1000)
      end
    end
  end

  describe '#formatted_size' do
    it 'formats bytes correctly' do
      version = described_class.create!(
        content: 'A' * 500,
        pg_version: 'PostgreSQL 15.1',
        format_type: 'sql'
      )

      expect(version.formatted_size).to eq('500 bytes')
    end

    it 'formats kilobytes correctly' do
      version = described_class.create!(
        content: 'A' * 2048,
        pg_version: 'PostgreSQL 15.1',
        format_type: 'sql'
      )

      expect(version.formatted_size).to eq('2.0 KB')
    end

    it 'formats megabytes correctly' do
      version = described_class.create!(
        content: 'A' * (2 * 1024 * 1024),
        pg_version: 'PostgreSQL 15.1',
        format_type: 'sql'
      )

      expect(version.formatted_size).to eq('2.0 MB')
    end

    context 'when content is not loaded' do
      it 'uses stored content_size' do
        version = described_class.create!(
          content: 'A' * 2048,
          pg_version: 'PostgreSQL 15.1',
          format_type: 'sql'
        )

        # Load only metadata, not content
        partial_version = described_class.select(:id, :content_size).find(version.id)

        expect(partial_version.formatted_size).to eq('2.0 KB')
      end
    end
  end

  describe 'edge cases' do
    it 'handles empty content' do
      version = described_class.create!(
        content: '',
        pg_version: 'PostgreSQL 15.1',
        format_type: 'sql'
      )

      expect(version.content_size).to eq(0)
      expect(version.line_count).to eq(0)
      expect(version.formatted_size).to eq('0 bytes')
    end

    it 'handles single line without newline' do
      version = described_class.create!(
        content: 'Single line',
        pg_version: 'PostgreSQL 15.1',
        format_type: 'sql'
      )

      expect(version.line_count).to eq(1)
    end

    it 'handles content with only newlines' do
      version = described_class.create!(
        content: "\n\n\n",
        pg_version: 'PostgreSQL 15.1',
        format_type: 'sql'
      )

      expect(version.line_count).to eq(4) # Empty string before each \n
    end

    it 'handles very large content' do
      large_content = 'A' * (5 * 1024 * 1024) # 5MB
      version = described_class.create!(
        content: large_content,
        pg_version: 'PostgreSQL 15.1',
        format_type: 'sql'
      )

      expect(version.content_size).to eq(5 * 1024 * 1024)
      expect(version.formatted_size).to eq('5.0 MB')
    end
  end
end
