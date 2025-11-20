# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterStructureSql::Configuration do
  subject(:config) { described_class.new }

  describe 'defaults' do
    it 'sets output_path to db/structure.sql' do
      expect(config.output_path).to eq('db/structure.sql')
    end

    it 'sets search_path to default PostgreSQL value' do
      expect(config.search_path).to eq('"$user", public')
    end

    it 'disables replace_default_dump by default' do
      expect(config.replace_default_dump).to be false
    end

    it 'enables include_extensions by default' do
      expect(config.include_extensions).to be true
    end

    it 'enables include_functions by default' do
      expect(config.include_functions).to be true
    end

    it 'enables include_triggers by default' do
      expect(config.include_triggers).to be true
    end

    it 'enables include_views by default' do
      expect(config.include_views).to be true
    end

    it 'enables include_materialized_views by default' do
      expect(config.include_materialized_views).to be true
    end

    it 'disables include_rules by default' do
      expect(config.include_rules).to be false
    end

    it 'disables include_comments by default' do
      expect(config.include_comments).to be false
    end

    it 'enables include_domains by default' do
      expect(config.include_domains).to be true
    end

    it "sets schemas to ['public'] by default" do
      expect(config.schemas).to eq(['public'])
    end

    it 'disables schema versioning by default' do
      expect(config.enable_schema_versions).to be false
    end

    it 'sets schema_versions_limit to 10' do
      expect(config.schema_versions_limit).to eq(10)
    end

    it 'sets indent_size to 2' do
      expect(config.indent_size).to eq(2)
    end

    it 'enables section spacing by default' do
      expect(config.add_section_spacing).to be true
    end

    it 'enables table sorting by default' do
      expect(config.sort_tables).to be true
    end

    it 'sets max_lines_per_file to 500' do
      expect(config.max_lines_per_file).to eq(500)
    end

    it 'sets overflow_threshold to 1.1' do
      expect(config.overflow_threshold).to eq(1.1)
    end

    it 'enables manifest generation by default' do
      expect(config.generate_manifest).to be true
    end
  end

  describe '#validate!' do
    context 'when output_path is blank' do
      it 'raises an error' do
        config.output_path = ''
        expect { config.validate! }.to raise_error(BetterStructureSql::ConfigurationError, /output_path cannot be blank/)
      end
    end

    context 'when output_path is nil' do
      it 'raises an error' do
        config.output_path = nil
        expect { config.validate! }.to raise_error(BetterStructureSql::ConfigurationError, /output_path cannot be blank/)
      end
    end

    context 'when schema_versions_limit is negative' do
      it 'raises an error' do
        config.schema_versions_limit = -1
        expect { config.validate! }.to raise_error(BetterStructureSql::ConfigurationError, /must be a non-negative integer/)
      end
    end

    context 'when schema_versions_limit is not an integer' do
      it 'raises an error' do
        config.schema_versions_limit = '10'
        expect { config.validate! }.to raise_error(BetterStructureSql::ConfigurationError, /must be a non-negative integer/)
      end
    end

    context 'when indent_size is zero' do
      it 'raises an error' do
        config.indent_size = 0
        expect { config.validate! }.to raise_error(BetterStructureSql::ConfigurationError, /must be a positive integer/)
      end
    end

    context 'when indent_size is negative' do
      it 'raises an error' do
        config.indent_size = -2
        expect { config.validate! }.to raise_error(BetterStructureSql::ConfigurationError, /must be a positive integer/)
      end
    end

    context 'when schemas is empty array' do
      it 'raises an error' do
        config.schemas = []
        expect { config.validate! }.to raise_error(BetterStructureSql::ConfigurationError, /schemas must be a non-empty array/)
      end
    end

    context 'when schemas is not an array' do
      it 'raises an error' do
        config.schemas = 'public'
        expect { config.validate! }.to raise_error(BetterStructureSql::ConfigurationError, /schemas must be a non-empty array/)
      end
    end

    context 'when max_lines_per_file is zero' do
      it 'raises an error' do
        config.max_lines_per_file = 0
        expect { config.validate! }.to raise_error(BetterStructureSql::ConfigurationError, /must be a positive integer/)
      end
    end

    context 'when max_lines_per_file is negative' do
      it 'raises an error' do
        config.max_lines_per_file = -100
        expect { config.validate! }.to raise_error(BetterStructureSql::ConfigurationError, /must be a positive integer/)
      end
    end

    context 'when max_lines_per_file is not an integer' do
      it 'raises an error' do
        config.max_lines_per_file = '500'
        expect { config.validate! }.to raise_error(BetterStructureSql::ConfigurationError, /must be a positive integer/)
      end
    end

    context 'when overflow_threshold is less than 1.0' do
      it 'raises an error' do
        config.overflow_threshold = 0.9
        expect { config.validate! }.to raise_error(BetterStructureSql::ConfigurationError, /must be >= 1.0/)
      end
    end

    context 'when overflow_threshold is not numeric' do
      it 'raises an error' do
        config.overflow_threshold = '1.1'
        expect { config.validate! }.to raise_error(BetterStructureSql::ConfigurationError, /must be >= 1.0/)
      end
    end

    context 'when overflow_threshold is exactly 1.0' do
      it 'does not raise an error' do
        config.overflow_threshold = 1.0
        expect { config.validate! }.not_to raise_error
      end
    end

    context 'when all settings are valid' do
      it 'does not raise an error' do
        expect { config.validate! }.not_to raise_error
      end
    end
  end
end
