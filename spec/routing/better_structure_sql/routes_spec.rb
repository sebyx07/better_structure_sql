# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'BetterStructureSql::Engine routes', type: :routing do
  routes { BetterStructureSql::Engine.routes }

  it 'routes the root to the versions list' do
    expect(get: '/').to route_to('better_structure_sql/schema_versions#index')
  end

  it 'routes numeric ids to show, raw and download' do
    expect(get: '/schema_versions/12').to route_to('better_structure_sql/schema_versions#show', id: '12')
    expect(get: '/schema_versions/12/raw').to route_to('better_structure_sql/schema_versions#raw', id: '12')
    expect(get: '/schema_versions/12/download').to route_to('better_structure_sql/schema_versions#download', id: '12')
  end

  ['abc', '1abc', "1' OR '1'='1"].each do |id|
    it "does not route the malformed id #{id.inspect}" do
      expect(get: "/schema_versions/#{ERB::Util.url_encode(id)}").not_to be_routable
      expect(get: "/schema_versions/#{ERB::Util.url_encode(id)}/download").not_to be_routable
    end
  end

  it 'exposes no write routes' do
    expect(post: '/schema_versions').not_to be_routable
    expect(delete: '/schema_versions/1').not_to be_routable
  end
end
