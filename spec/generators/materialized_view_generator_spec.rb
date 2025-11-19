# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterStructureSql::Generators::MaterializedViewGenerator do
  subject(:generator) { described_class.new }

  describe '#generate' do
    context 'when materialized view has no indexes' do
      it 'generates CREATE MATERIALIZED VIEW statement' do
        matview = {
          name: 'user_stats',
          schema: 'public',
          definition: 'SELECT user_id, COUNT(*) FROM events GROUP BY user_id',
          indexes: []
        }
        result = generator.generate(matview)

        expect(result).to eq("CREATE MATERIALIZED VIEW user_stats AS\nSELECT user_id, COUNT(*) FROM events GROUP BY user_id;")
      end
    end

    context 'when materialized view has indexes' do
      it 'generates CREATE MATERIALIZED VIEW with indexes' do
        matview = {
          name: 'user_stats',
          schema: 'public',
          definition: 'SELECT user_id, COUNT(*) FROM events GROUP BY user_id',
          indexes: [
            'CREATE INDEX idx_user_stats_user_id ON user_stats (user_id)',
            'CREATE INDEX idx_user_stats_count ON user_stats (count)'
          ]
        }
        result = generator.generate(matview)

        expected = <<~SQL.strip
          CREATE MATERIALIZED VIEW user_stats AS
          SELECT user_id, COUNT(*) FROM events GROUP BY user_id;

          CREATE INDEX idx_user_stats_user_id ON user_stats (user_id);
          CREATE INDEX idx_user_stats_count ON user_stats (count);
        SQL

        expect(result).to eq(expected)
      end
    end

    context 'when materialized view is in custom schema' do
      it 'generates with schema prefix' do
        matview = {
          name: 'daily_stats',
          schema: 'analytics',
          definition: 'SELECT date, COUNT(*) FROM events GROUP BY date',
          indexes: []
        }
        result = generator.generate(matview)

        expect(result).to eq("CREATE MATERIALIZED VIEW analytics.daily_stats AS\nSELECT date, COUNT(*) FROM events GROUP BY date;")
      end
    end
  end
end
