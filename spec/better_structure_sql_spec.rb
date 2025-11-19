# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterStructureSql do
  it 'has a version number' do
    expect(BetterStructureSql::VERSION).not_to be_nil
  end

  describe '.configure' do
    after do
      described_class.reset_configuration
    end

    it 'yields configuration object' do
      expect { |b| described_class.configure(&b) }.to yield_with_args(BetterStructureSql::Configuration)
    end

    it 'allows setting configuration options' do
      described_class.configure do |config|
        config.output_path = 'db/custom_structure.sql'
        config.include_views = true
      end

      expect(described_class.configuration.output_path).to eq('db/custom_structure.sql')
      expect(described_class.configuration.include_views).to be true
    end
  end

  describe '.configuration' do
    it 'returns Configuration instance' do
      expect(described_class.configuration).to be_a(BetterStructureSql::Configuration)
    end

    it 'returns same instance on multiple calls' do
      config1 = described_class.configuration
      config2 = described_class.configuration

      expect(config1).to be(config2)
    end
  end

  describe '.reset_configuration' do
    it 'creates new configuration instance' do
      old_config = described_class.configuration
      described_class.reset_configuration
      new_config = described_class.configuration

      expect(new_config).not_to be(old_config)
    end
  end
end
