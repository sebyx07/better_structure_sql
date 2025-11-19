# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterStructureSql::Adapters::BaseAdapter do
  let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::AbstractAdapter) }
  let(:adapter)    { described_class.new(connection) }

  describe '#initialize' do
    it 'stores the connection' do
      expect(adapter.connection).to eq(connection)
    end
  end

  describe 'abstract introspection methods' do
    describe '#fetch_extensions' do
      it 'raises NotImplementedError' do
        expect { adapter.fetch_extensions(connection) }.to raise_error(
          NotImplementedError,
          /must implement #fetch_extensions/
        )
      end
    end

    describe '#fetch_custom_types' do
      it 'raises NotImplementedError' do
        expect { adapter.fetch_custom_types(connection) }.to raise_error(
          NotImplementedError,
          /must implement #fetch_custom_types/
        )
      end
    end

    describe '#fetch_tables' do
      it 'raises NotImplementedError' do
        expect { adapter.fetch_tables(connection) }.to raise_error(
          NotImplementedError,
          /must implement #fetch_tables/
        )
      end
    end

    describe '#fetch_indexes' do
      it 'raises NotImplementedError' do
        expect { adapter.fetch_indexes(connection) }.to raise_error(
          NotImplementedError,
          /must implement #fetch_indexes/
        )
      end
    end

    describe '#fetch_foreign_keys' do
      it 'raises NotImplementedError' do
        expect { adapter.fetch_foreign_keys(connection) }.to raise_error(
          NotImplementedError,
          /must implement #fetch_foreign_keys/
        )
      end
    end

    describe '#fetch_views' do
      it 'raises NotImplementedError' do
        expect { adapter.fetch_views(connection) }.to raise_error(
          NotImplementedError,
          /must implement #fetch_views/
        )
      end
    end

    describe '#fetch_materialized_views' do
      it 'raises NotImplementedError' do
        expect { adapter.fetch_materialized_views(connection) }.to raise_error(
          NotImplementedError,
          /must implement #fetch_materialized_views/
        )
      end
    end

    describe '#fetch_functions' do
      it 'raises NotImplementedError' do
        expect { adapter.fetch_functions(connection) }.to raise_error(
          NotImplementedError,
          /must implement #fetch_functions/
        )
      end
    end

    describe '#fetch_sequences' do
      it 'raises NotImplementedError' do
        expect { adapter.fetch_sequences(connection) }.to raise_error(
          NotImplementedError,
          /must implement #fetch_sequences/
        )
      end
    end

    describe '#fetch_triggers' do
      it 'raises NotImplementedError' do
        expect { adapter.fetch_triggers(connection) }.to raise_error(
          NotImplementedError,
          /must implement #fetch_triggers/
        )
      end
    end
  end

  describe 'capability methods' do
    describe '#supports_extensions?' do
      it 'returns false by default' do
        expect(adapter.supports_extensions?).to be false
      end
    end

    describe '#supports_materialized_views?' do
      it 'returns false by default' do
        expect(adapter.supports_materialized_views?).to be false
      end
    end

    describe '#supports_custom_types?' do
      it 'returns false by default' do
        expect(adapter.supports_custom_types?).to be false
      end
    end

    describe '#supports_domains?' do
      it 'returns false by default' do
        expect(adapter.supports_domains?).to be false
      end
    end

    describe '#supports_functions?' do
      it 'returns false by default' do
        expect(adapter.supports_functions?).to be false
      end
    end

    describe '#supports_triggers?' do
      it 'returns false by default' do
        expect(adapter.supports_triggers?).to be false
      end
    end

    describe '#supports_sequences?' do
      it 'returns false by default' do
        expect(adapter.supports_sequences?).to be false
      end
    end
  end

  describe 'version detection methods' do
    describe '#database_version' do
      it 'raises NotImplementedError' do
        expect { adapter.database_version }.to raise_error(
          NotImplementedError,
          /must implement #database_version/
        )
      end
    end

    describe '#parse_version' do
      it 'raises NotImplementedError' do
        expect { adapter.parse_version('some version') }.to raise_error(
          NotImplementedError,
          /must implement #parse_version/
        )
      end
    end
  end

  describe 'version utility methods' do
    describe '#major_version' do
      it 'extracts major version from version string' do
        expect(adapter.major_version('14.5')).to eq(14)
        expect(adapter.major_version('13.0')).to eq(13)
        expect(adapter.major_version('15.2.1')).to eq(15)
      end
    end

    describe '#minor_version' do
      it 'extracts minor version from version string' do
        expect(adapter.minor_version('14.5')).to eq(5)
        expect(adapter.minor_version('13.0')).to eq(0)
        expect(adapter.minor_version('15.2.1')).to eq(2)
      end

      it 'returns 0 if no minor version' do
        expect(adapter.minor_version('14')).to eq(0)
      end
    end

    describe '#compare_versions' do
      it 'returns 0 for equal versions' do
        expect(adapter.compare_versions('14.5', '14.5')).to eq(0)
      end

      it 'returns -1 when first version is less' do
        expect(adapter.compare_versions('14.4', '14.5')).to eq(-1)
        expect(adapter.compare_versions('13.5', '14.5')).to eq(-1)
      end

      it 'returns 1 when first version is greater' do
        expect(adapter.compare_versions('14.6', '14.5')).to eq(1)
        expect(adapter.compare_versions('15.0', '14.5')).to eq(1)
      end

      it 'handles different length version strings' do
        expect(adapter.compare_versions('14.5.1', '14.5')).to eq(1)
        expect(adapter.compare_versions('14.5', '14.5.1')).to eq(-1)
      end
    end

    describe '#version_at_least?' do
      it 'returns true when current version meets requirement' do
        expect(adapter.version_at_least?('14.5', '14.5')).to be true
        expect(adapter.version_at_least?('14.6', '14.5')).to be true
        expect(adapter.version_at_least?('15.0', '14.5')).to be true
      end

      it 'returns false when current version is below requirement' do
        expect(adapter.version_at_least?('14.4', '14.5')).to be false
        expect(adapter.version_at_least?('13.9', '14.5')).to be false
      end
    end
  end
end
