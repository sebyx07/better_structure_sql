# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterStructureSql::Generators::TriggerGenerator do
  subject(:generator) { described_class.new }

  describe '#generate' do
    it 'generates trigger definition from pg_get_triggerdef' do
      trigger = {
        name: 'update_timestamp_trigger',
        schema: 'public',
        table_name: 'users',
        definition: 'CREATE TRIGGER update_timestamp_trigger BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_timestamp()'
      }
      result = generator.generate(trigger)

      expect(result).to eq('CREATE TRIGGER update_timestamp_trigger BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_timestamp();')
    end

    it 'adds semicolon if missing' do
      trigger = {
        name: 'simple_trigger',
        schema: 'public',
        table_name: 'posts',
        definition: 'CREATE TRIGGER simple_trigger AFTER INSERT ON posts FOR EACH ROW EXECUTE FUNCTION log_insert()'
      }
      result = generator.generate(trigger)

      expect(result).to end_with(';')
    end

    it 'does not add duplicate semicolon' do
      trigger = {
        name: 'simple_trigger',
        schema: 'public',
        table_name: 'posts',
        definition: 'CREATE TRIGGER simple_trigger AFTER INSERT ON posts FOR EACH ROW EXECUTE FUNCTION log_insert();'
      }
      result = generator.generate(trigger)

      expect(result).to end_with(';')
      expect(result).not_to end_with(';;')
    end
  end
end
