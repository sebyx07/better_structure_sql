# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BetterStructureSql::SchemaVersionsController, type: :controller do
  # Use the engine's routes
  routes { BetterStructureSql::Engine.routes }

  # Helper to create test schema version using factory
  def create_schema_version(content_size: 1000)
    content = 'A' * content_size
    create(:schema_version, content: content)
  end

  describe 'GET #index' do
    context 'with no schema versions' do
      it 'returns success' do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'assigns empty array' do
        get :index
        expect(assigns(:schema_versions)).to eq([])
      end
    end

    context 'with schema versions' do
      before do
        @version1 = create(:schema_version)
        sleep 0.01 # Ensure different created_at timestamps
        @version2 = create(:schema_version)
      end

      it 'returns success' do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'assigns all versions ordered by created_at DESC' do
        get :index
        versions = assigns(:schema_versions).to_a # Force load into array
        expect(versions.length).to eq(2)
        expect(versions.first.id).to eq(@version2.id) # Most recent first
      end

      it 'limits to 100 versions' do
        # Create 150 versions total (2 already exist from before block)
        100.times { create(:schema_version) }
        get :index
        expect(assigns(:schema_versions).to_a.length).to eq(100)
      end
    end
  end

  describe 'GET #show' do
    context 'with small file (< 1MB)' do
      let(:version) { create_schema_version(content_size: 1000) }

      it 'returns success' do
        get :show, params: { id: version.id }
        expect(response).to have_http_status(:success)
      end

      it 'loads full content' do
        get :show, params: { id: version.id }
        schema_version = assigns(:schema_version)
        expect(schema_version.content).to be_present
        expect(schema_version.content.bytesize).to eq(1000)
      end
    end

    context 'with large file (> 1MB)' do
      let(:version) { create_schema_version(content_size: 2_000_000) }

      it 'returns success' do
        get :show, params: { id: version.id }
        expect(response).to have_http_status(:success)
      end

      it 'does not load content' do
        get :show, params: { id: version.id }
        schema_version = assigns(:schema_version)
        expect(schema_version).not_to respond_to(:content)
      end

      it 'includes content_size' do
        get :show, params: { id: version.id }
        schema_version = assigns(:schema_version)
        expect(schema_version.content_size).to eq(2_000_000)
      end
    end

    context 'with non-existent version' do
      it 'returns 404' do
        get :show, params: { id: 99_999 }
        expect(response).to have_http_status(:not_found)
      end

      it 'renders error message' do
        get :show, params: { id: 99_999 }
        expect(response.body).to include('Schema version not found')
      end
    end
  end

  describe 'GET #raw' do
    context 'with small file (< 2MB)' do
      let(:version) { create_schema_version(content_size: 1000) }

      it 'returns success' do
        get :raw, params: { id: version.id }
        expect(response).to have_http_status(:success)
      end

      it 'sends file with correct content-type' do
        get :raw, params: { id: version.id }
        expect(response.headers['Content-Type']).to eq('text/plain')
      end

      it 'sends file with correct disposition' do
        get :raw, params: { id: version.id }
        expect(response.headers['Content-Disposition']).to include('attachment')
        expect(response.headers['Content-Disposition']).to include("schema_version_#{version.id}_sql.txt")
      end

      it 'sends correct content' do
        get :raw, params: { id: version.id }
        expect(response.body.bytesize).to eq(1000)
      end
    end

    context 'with large file (> 2MB)' do
      let(:version) { create_schema_version(content_size: 3_000_000) }

      it 'returns success' do
        get :raw, params: { id: version.id }
        expect(response).to have_http_status(:success)
      end

      it 'streams file with correct headers' do
        get :raw, params: { id: version.id }
        expect(response.headers['Content-Type']).to eq('text/plain')
        expect(response.headers['Content-Disposition']).to include('attachment')
        expect(response.headers['Cache-Control']).to eq('no-cache')
        expect(response.headers['X-Accel-Buffering']).to eq('no')
      end

      it 'streams correct content' do
        get :raw, params: { id: version.id }
        # Response body should be an enumerator for streaming
        expect(response.body).to be_a(Enumerator)
        # Collect chunks and verify total size
        chunks = response.body.to_a
        total_size = chunks.sum(&:bytesize)
        expect(total_size).to eq(3_000_000)
      end
    end

    context 'with non-existent version' do
      it 'returns 404' do
        get :raw, params: { id: 99_999 }
        expect(response).to have_http_status(:not_found)
      end

      it 'renders error message' do
        get :raw, params: { id: 99_999 }
        expect(response.body).to include('Schema version not found')
      end
    end
  end

  describe 'size constants' do
    it 'has correct MAX_MEMORY_SIZE' do
      expect(described_class::MAX_MEMORY_SIZE).to eq(2.megabytes)
    end

    it 'has correct MAX_DISPLAY_SIZE' do
      expect(described_class::MAX_DISPLAY_SIZE).to eq(1.megabyte)
    end
  end
end
