# frozen_string_literal: true

require 'rails_helper'

# Exercises the engine through the full middleware stack, mounted under a
# custom path and route name like a host application would.
RSpec.describe 'BetterStructureSql::Engine mounted in a host app', type: :request do
  before(:all) do
    Rails.application.routes.draw do
      mount BetterStructureSql::Engine, at: '/admin/schema', as: 'schema_ui'
    end
  end

  after do
    BetterStructureSql::Engine.reset_authentication!
    BetterStructureSql::SchemaVersion.delete_all
  end

  it 'renders links relative to the mount point, whatever the mount is named' do
    version = create(:schema_version)
    get '/admin/schema'
    expect(response).to have_http_status(:success)
    expect(response.body).to include(%(href="/admin/schema/schema_versions/#{version.id}"))
    expect(response.body).to include(%(href="/admin/schema/schema_versions/#{version.id}/download"))
  end

  it 'renders the show page with security headers' do
    version = create(:schema_version)
    get "/admin/schema/schema_versions/#{version.id}"
    expect(response).to have_http_status(:success)
    expect(response.headers['Cache-Control']).to eq('no-store')
    expect(response.headers['X-Content-Type-Options']).to eq('nosniff')
  end

  it 'streams large downloads completely' do
    content = "#{'CREATE TABLE t (id bigint);' * 100_000}\n"
    version = create(:schema_version, content:)
    get "/admin/schema/schema_versions/#{version.id}/download"
    expect(response.headers['Content-Type']).to eq('text/plain; charset=utf-8')
    expect(response.headers['Content-Disposition']).to start_with('attachment; filename="structure.sql"')
    expect(response.headers['Cache-Control']).to eq('no-store')
    expect(response.body).to eq(content)
  end

  it 'responds 404 for unknown and malformed ids' do
    get '/admin/schema/schema_versions/999999'
    expect(response).to have_http_status(:not_found)
    get '/admin/schema/schema_versions/abc/raw'
    expect(response).to have_http_status(:not_found)
  end

  it 'fails closed in production until access control is configured' do
    version = create(:schema_version)
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))

    get "/admin/schema/schema_versions/#{version.id}/raw"
    expect(response).to have_http_status(:forbidden)
    expect(response.body).not_to include('CREATE TABLE')

    BetterStructureSql::Engine.authenticate_with { |controller| controller.request.headers['X-Admin'] == 'yes' }
    get "/admin/schema/schema_versions/#{version.id}/raw", headers: { 'X-Admin' => 'yes' }
    expect(response).to have_http_status(:success)
  end
end
