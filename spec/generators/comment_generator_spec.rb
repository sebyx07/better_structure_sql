# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterStructureSql::Generators::CommentGenerator do
  subject(:generator) { described_class.new }

  describe '#generate' do
    it 'quotes table names and escapes the comment' do
      result = generator.generate(object_type: :table, object_name: 'Users', comment: "It's people")

      expect(result).to eq(%(COMMENT ON TABLE "Users" IS 'It''s people';))
    end

    it 'uses the function signature verbatim so overloads are unambiguous' do
      result = generator.generate(object_type: :function, object_name: 'add_numbers(a integer, b integer)', comment: 'Adds')

      expect(result).to eq("COMMENT ON FUNCTION add_numbers(a integer, b integer) IS 'Adds';")
    end

    it 'comments on procedures with COMMENT ON PROCEDURE' do
      result = generator.generate(object_type: :procedure, object_name: 'reset(IN id bigint)', comment: 'Resets')

      expect(result).to eq("COMMENT ON PROCEDURE reset(IN id bigint) IS 'Resets';")
    end

    it 'takes the table and column names separately so names containing dots stay intact' do
      result = generator.generate(object_type: :column, table_name: 'a.b', object_name: 'c.d', comment: 'Dotted')

      expect(result).to eq(%(COMMENT ON COLUMN "a.b"."c.d" IS 'Dotted';))
    end
  end
end
