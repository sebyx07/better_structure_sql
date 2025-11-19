# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterStructureSql::Generators::ViewGenerator do
  subject(:generator) { described_class.new }

  describe '#generate' do
    context 'when view is in public schema' do
      it 'generates CREATE VIEW statement' do
        view = {
          name: 'active_users',
          schema: 'public',
          definition: 'SELECT * FROM users WHERE active = true'
        }
        result = generator.generate(view)

        expect(result).to eq("CREATE OR REPLACE VIEW active_users AS\nSELECT * FROM users WHERE active = true;")
      end
    end

    context 'when view is in custom schema' do
      it 'generates CREATE VIEW with schema prefix' do
        view = {
          name: 'user_stats',
          schema: 'analytics',
          definition: 'SELECT user_id, COUNT(*) FROM events GROUP BY user_id'
        }
        result = generator.generate(view)

        expect(result).to eq("CREATE OR REPLACE VIEW analytics.user_stats AS\nSELECT user_id, COUNT(*) FROM events GROUP BY user_id;")
      end
    end

    context 'when definition already has semicolon' do
      it 'does not add duplicate semicolon' do
        view = {
          name: 'simple_view',
          schema: 'public',
          definition: 'SELECT 1;'
        }
        result = generator.generate(view)

        expect(result).to eq("CREATE OR REPLACE VIEW simple_view AS\nSELECT 1;")
      end
    end
  end
end
