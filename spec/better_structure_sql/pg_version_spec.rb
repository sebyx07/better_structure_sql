# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterStructureSql::PgVersion do
  describe '.parse_version' do
    it 'extracts version from standard PostgreSQL version string' do
      version_string = 'PostgreSQL 14.5 (Ubuntu 14.5-1.pgdg20.04+1) on x86_64-pc-linux-gnu'
      expect(described_class.parse_version(version_string)).to eq('14.5')
    end

    it 'extracts version from simple PostgreSQL version string' do
      version_string = 'PostgreSQL 15.2'
      expect(described_class.parse_version(version_string)).to eq('15.2')
    end

    it 'extracts version from PostgreSQL 16' do
      version_string = 'PostgreSQL 16.0 on aarch64-apple-darwin21.6.0'
      expect(described_class.parse_version(version_string)).to eq('16.0')
    end

    it "returns 'unknown' for invalid version string" do
      version_string = 'Invalid version string'
      expect(described_class.parse_version(version_string)).to eq('unknown')
    end
  end

  describe '.major_version' do
    it 'extracts major version' do
      expect(described_class.major_version('14.5')).to eq(14)
      expect(described_class.major_version('15.2')).to eq(15)
      expect(described_class.major_version('16.0')).to eq(16)
    end
  end

  describe '.minor_version' do
    it 'extracts minor version' do
      expect(described_class.minor_version('14.5')).to eq(5)
      expect(described_class.minor_version('15.2')).to eq(2)
      expect(described_class.minor_version('16.0')).to eq(0)
    end

    it 'returns 0 when no minor version present' do
      expect(described_class.minor_version('14')).to eq(0)
    end
  end
end
