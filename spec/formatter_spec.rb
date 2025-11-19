# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterStructureSql::Formatter do
  subject(:formatter) { described_class.new }

  describe '#format' do
    context 'with section spacing enabled' do
      it 'adds blank lines between sections' do
        content = "-- Tables\nCREATE TABLE users;\n-- Indexes\nCREATE INDEX idx;"

        result = formatter.format(content)

        expect(result).to include("\n\n")
      end
    end

    context 'with excessive blank lines' do
      it 'collapses multiple blank lines into one' do
        content = "CREATE TABLE users;\n\n\n\nCREATE TABLE posts;"

        result = formatter.format_section(content)

        expect(result).not_to include("\n\n\n")
        expect(result.scan("\n\n").count).to eq(1)
      end
    end

    context 'with trailing whitespace' do
      it 'removes trailing whitespace from lines' do
        content = "CREATE TABLE users;   \nid bigint;  "

        result = formatter.format_section(content)

        expect(result).to eq("CREATE TABLE users;\nid bigint;")
      end
    end
  end
end
