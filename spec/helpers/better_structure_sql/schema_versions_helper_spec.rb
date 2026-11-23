# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BetterStructureSql::SchemaVersionsHelper, type: :helper do
  describe '#format_output_mode' do
    it 'renders a multi-file badge' do
      expect(helper.format_output_mode('multi_file')).to include('text-bg-info', 'Multi-File')
    end

    it 'renders a single-file badge' do
      expect(helper.format_output_mode('single_file')).to include('text-bg-secondary', 'Single File')
    end

    it 'renders unknown values as Unknown without echoing them' do
      badge = helper.format_output_mode('<script>')
      expect(badge).to include('Unknown')
      expect(badge).not_to include('script')
    end
  end

  describe '#format_type_badge' do
    it 'renders an SQL badge' do
      expect(helper.format_type_badge('sql')).to include('text-bg-primary', 'bi-filetype-sql', ' SQL')
    end

    it 'renders a Ruby badge' do
      expect(helper.format_type_badge('rb')).to include('text-bg-success', 'bi-filetype-rb', ' RB')
    end

    it 'renders nil and unexpected values as Unknown' do
      expect(helper.format_type_badge(nil)).to include('Unknown')
      expect(helper.format_type_badge('"><img src=x>')).not_to include('img')
    end

    it 'hides the decorative icon from assistive technology' do
      expect(helper.format_type_badge('sql')).to include('aria-hidden="true"')
    end
  end

  describe '#schema_version_timestamp' do
    it 'renders a machine-readable time element' do
      version = build(:schema_version, created_at: Time.utc(2024, 5, 6, 7, 8, 9))
      expect(helper.schema_version_timestamp(version))
        .to eq('<time datetime="2024-05-06T07:08:09Z">2024-05-06 07:08:09 UTC</time>')
    end
  end

  describe '#pagination_item' do
    before { helper.extend(BetterStructureSql::Engine.routes.url_helpers) }

    it 'links to the page when enabled' do
      expect(helper.pagination_item('Older', 2, enabled: true))
        .to match(%r{\A<li class="page-item"><a class="page-link" href="[^"]*/schema_versions\?page=2">Older</a></li>\z})
    end

    it 'renders a disabled entry without a link' do
      expect(helper.pagination_item('Newer', 0, enabled: false))
        .to eq('<li class="page-item disabled"><span class="page-link">Newer</span></li>')
    end
  end
end
