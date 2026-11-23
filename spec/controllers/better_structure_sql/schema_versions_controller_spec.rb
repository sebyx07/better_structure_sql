# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BetterStructureSql::SchemaVersionsController, type: :controller do
  render_views

  # Use the engine's routes
  routes { BetterStructureSql::Engine.routes }

  # Helper to create test schema version using factory
  def create_schema_version(content_size: 1000)
    content = 'A' * content_size
    create(:schema_version, content:)
  end

  def select_statements
    statements = []
    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
      statements << payload[:sql] if payload[:sql].start_with?('SELECT') && payload[:name] != 'SCHEMA'
    end
    yield
    statements
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  # The chunks a streamed body yields. response.body joins them into one
  # String on Rails < 8.0, so read the response stream instead.
  def streamed_chunks
    response.stream.enum_for(:each).to_a
  end

  def stub_environment(name)
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new(name))
  end

  after { BetterStructureSql::Engine.reset_authentication! }

  describe 'access control' do
    context 'when nothing is configured' do
      it 'allows access in development' do
        stub_environment('development')
        get :index
        expect(response).to have_http_status(:success)
      end

      %w[production staging].each do |environment|
        it "denies access in #{environment} with setup instructions" do
          stub_environment(environment)
          get :index
          expect(response).to have_http_status(:forbidden)
          expect(response.body).to include('BetterStructureSql::Engine.authenticate_with')
          expect(response.body).to include('BetterStructureSql::Engine.authentication_handled_by_routes!')
        end
      end

      it 'denies downloads in production without leaking content' do
        version = create(:schema_version, content: 'CREATE TABLE secrets (id bigint);')
        stub_environment('production')

        %i[show raw download].each do |action|
          get action, params: { id: version.id }
          expect(response).to have_http_status(:forbidden)
          expect(response.body).not_to include('secrets')
        end
      end
    end

    context 'when the routes handle authentication' do
      it 'allows access in production' do
        BetterStructureSql::Engine.authentication_handled_by_routes!
        stub_environment('production')
        get :index
        expect(response).to have_http_status(:success)
      end
    end

    context 'with an authenticator' do
      before { stub_environment('production') }

      it 'allows access when the block returns true' do
        BetterStructureSql::Engine.authenticate_with { |controller| controller.params[:token] == 'secret' }
        get :index, params: { token: 'secret' }
        expect(response).to have_http_status(:success)
      end

      it 'responds 403 when the block returns false' do
        BetterStructureSql::Engine.authenticate_with { |_controller| false }
        get :index
        expect(response).to have_http_status(:forbidden)
        expect(response.body).to eq('Forbidden')
      end

      it 'is enforced in development too' do
        stub_environment('development')
        BetterStructureSql::Engine.authenticate_with { |_controller| false }
        get :index
        expect(response).to have_http_status(:forbidden)
      end

      it 'keeps the response rendered by the block' do
        BetterStructureSql::Engine.authenticate_with { |controller| controller.head(:unauthorized) && false }
        get :index
        expect(response).to have_http_status(:unauthorized)
      end

      it 'requires a block' do
        expect { BetterStructureSql::Engine.authenticate_with }.to raise_error(ArgumentError, /requires a block/)
      end
    end

    it 'protects against request forgery' do
      expect(described_class.forgery_protection_strategy).to eq(ActionController::RequestForgeryProtection::ProtectionMethods::Exception)
    end

    it 'forbids caching of responses' do
      get :index
      expect(response.headers['Cache-Control']).to eq('no-store')
    end
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

      it 'renders the empty state' do
        get :index
        expect(response.body).to include('No Schema Versions Yet')
      end

      it 'names the task that stores a version' do
        get :index
        expect(response.body).to include('<code>rails db:schema:store</code>')
        expect(response.body).not_to include('db:schema:dump')
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

      it 'never selects the content or zip_archive columns' do
        statements = select_statements { get :index }
        expect(statements.join("\n")).not_to match(/\.\*|"content"|`content`|zip_archive/)
      end

      it 'runs a fixed number of queries regardless of the number of versions' do
        baseline = select_statements { get :index }.size
        5.times { create(:schema_version) }
        expect(select_statements { get :index }.size).to eq(baseline)
      end

      it 'escapes stored values' do
        BetterStructureSql::SchemaVersion.where(id: @version2.id)
                                         .update_all(pg_version: '<script>alert(1)</script>', format_type: '"><img src=x>')
        get :index
        expect(response.body).not_to include('<script>alert(1)</script>')
        expect(response.body).not_to include('<img src=x>')
        expect(response.body).to include('&lt;script&gt;alert(1)&lt;/script&gt;')
      end
    end

    context 'with more versions than fit on a page' do
      before do
        stub_const("#{described_class}::PER_PAGE", 2)
        @versions = Array.new(5) { |i| create(:schema_version, created_at: Time.utc(2024, 1, 1) + i.days) }
      end

      it 'limits the first page to PER_PAGE versions, newest first' do
        get :index
        expect(assigns(:schema_versions).map(&:id)).to eq(@versions.last(2).reverse.map(&:id))
      end

      it 'shows the total number of versions, not the page size' do
        get :index
        expect(assigns(:total_count)).to eq(5)
        expect(response.body).to include('Total: 5')
        expect(response.body).to include('Page 1 of 3')
      end

      it 'returns the requested page' do
        get :index, params: { page: 3 }
        expect(assigns(:schema_versions).map(&:id)).to eq([@versions.first.id])
      end

      it 'links to the next page' do
        get :index
        expect(response.body).to include('/schema_versions?page=2')
      end

      it 'orders versions with identical timestamps deterministically' do
        BetterStructureSql::SchemaVersion.update_all(created_at: Time.utc(2024, 1, 1))
        ids = (1..3).flat_map do |page|
          get :index, params: { page: }
          assigns(:schema_versions).map(&:id)
        end
        expect(ids).to eq(@versions.map(&:id).reverse)
      end

      ['0', '-4', 'abc', '99999999999999999999999', '2; DROP TABLE x'].each do |page|
        it "clamps the invalid page #{page.inspect} into range" do
          get :index, params: { page: }
          expect(response).to have_http_status(:success)
          expect(assigns(:page)).to be_between(1, 3)
        end
      end
    end

    it 'defaults to 100 versions per page' do
      expect(described_class::PER_PAGE).to eq(100)
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

      it 'does not select the zip_archive column' do
        version
        statements = select_statements { get :show, params: { id: version.id } }
        expect(statements.join("\n")).not_to match(/\.\*|zip_archive/)
      end
    end

    context 'with HTML in the schema content' do
      let(:version) { create(:schema_version, content: "COMMENT ON TABLE t IS '</pre><script>alert(1)</script>';") }

      it 'escapes the content' do
        get :show, params: { id: version.id }
        expect(response.body).not_to include('<script>alert(1)</script>')
        expect(response.body).to include('&lt;/pre&gt;&lt;script&gt;alert(1)&lt;/script&gt;')
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
        expect(assigns(:schema_version).content).to be_nil
      end

      it 'explains that the content is too large to display' do
        get :show, params: { id: version.id }
        expect(response.body).to include('too large to display')
        expect(response.body).not_to include('data-copy-target')
      end

      it 'includes content_size' do
        get :show, params: { id: version.id }
        schema_version = assigns(:schema_version)
        expect(schema_version.content_size).to eq(2_000_000)
      end
    end

    context 'with a multi-file version' do
      let(:version) { create(:schema_version, :multi_file) }

      it 'renders the multi-file notice and combined content' do
        get :show, params: { id: version.id }
        expect(response.body).to include('Download ZIP Archive')
        expect(response.body).to include('5 files')
        expect(response.body).to include('CREATE TABLE test')
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

      it 'returns 404 for an id beyond the bigint range' do
        get :show, params: { id: '99999999999999999999999' }
        expect(response).to have_http_status(:not_found)
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
        expect(response.headers['Content-Type']).to eq('text/plain; charset=utf-8')
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

    context 'with an unexpected stored format_type' do
      let(:version) { create_schema_version(content_size:) }

      before do
        BetterStructureSql::SchemaVersion.where(id: version.id).update_all(format_type: "sql\"\r\nSet-Cookie: a=b")
      end

      [1000, 3_000_000].each do |size|
        context "with #{size} bytes of content" do
          let(:content_size) { size }

          it 'keeps the stored value out of the Content-Disposition header' do
            get :raw, params: { id: version.id }
            expect(response.headers['Content-Disposition'])
              .to eq("attachment; filename=\"schema_version_#{version.id}_sql.txt\"; " \
                     "filename*=UTF-8''schema_version_#{version.id}_sql.txt")
          end
        end
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
        expect(response.headers['Content-Type']).to eq('text/plain; charset=utf-8')
        expect(response.headers['Content-Disposition']).to include('attachment')
        expect(response.headers['Cache-Control']).to eq('no-store')
        expect(response.headers['X-Accel-Buffering']).to eq('no')
      end

      it 'streams correct content' do
        get :raw, params: { id: version.id }
        expect(controller.response_body).to be_a(Enumerator)
        expect(streamed_chunks.sum(&:bytesize)).to eq(3_000_000)
      end

      it 'reads the content from the database in bounded slices' do
        get :raw, params: { id: version.id }
        chunks = streamed_chunks
        expect(chunks.size).to be > 1
        expect(chunks.map(&:length).max).to eq(described_class::STREAM_CHUNK_CHARS)
      end
    end

    context 'with large multibyte and whitespace-only content' do
      it 'streams it back unchanged' do
        content = "#{"-- h\u00E9llo \u4E16\u754C\n" * 150_000}#{' ' * 600_000}END"
        version = create(:schema_version, content:)
        get :raw, params: { id: version.id }
        expect(streamed_chunks.join).to eq(content)
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

  describe 'GET #download' do
    context 'with a single-file SQL version' do
      let(:version) { create(:schema_version) }

      it 'sends structure.sql as a text attachment' do
        get :download, params: { id: version.id }
        expect(response.headers['Content-Type']).to eq('text/plain; charset=utf-8')
        expect(response.headers['Content-Disposition']).to include('attachment; filename="structure.sql"')
        expect(response.body).to eq(version.content)
      end

      it 'does not load the zip_archive column' do
        version
        statements = select_statements { get :download, params: { id: version.id } }
        expect(statements.join("\n")).not_to match(/\.\*|zip_archive/)
      end
    end

    context 'with a single-file Ruby version' do
      it 'sends structure.rb' do
        version = create(:schema_version, format_type: 'rb')
        get :download, params: { id: version.id }
        expect(response.headers['Content-Disposition']).to include('filename="structure.rb"')
      end
    end

    context 'with a large single-file version' do
      it 'streams the content' do
        version = create_schema_version(content_size: 3_000_000)
        get :download, params: { id: version.id }
        expect(response.headers['Content-Disposition']).to include('attachment; filename="structure.sql"')
        expect(streamed_chunks.sum(&:bytesize)).to eq(3_000_000)
      end
    end

    context 'with a multi-file version' do
      let(:zip_archive) { BetterStructureSql::ZipGenerator.create_from_file_map('4_tables/000001.sql' => 'CREATE TABLE a ();') }
      let(:version) { create(:schema_version, :multi_file, zip_archive:) }

      it 'sends the ZIP archive' do
        get :download, params: { id: version.id }
        expect(response.headers['Content-Type']).to eq('application/zip')
        expect(response.headers['Content-Disposition'])
          .to include("attachment; filename=\"schema_version_#{version.id}_#{version.created_at.to_i}.zip\"")
        expect(response.body.b).to eq(zip_archive.b)
      end

      it 'does not load the content column' do
        version
        statements = select_statements { get :download, params: { id: version.id } }
        expect(statements.join("\n")).not_to match(/\.\*|"content"|`content`/)
      end
    end

    context 'with a corrupt ZIP archive' do
      it 'responds with a clear error instead of sending it' do
        version = create(:schema_version, :multi_file, zip_archive: 'fake zip data')
        get :download, params: { id: version.id }
        expect(response).to have_http_status(:internal_server_error)
        expect(response.body).to eq('Stored ZIP archive is invalid')
      end
    end

    context 'with a multi-file version without a ZIP archive' do
      it 'falls back to the combined content' do
        version = create(:schema_version, :multi_file, zip_archive: nil)
        get :download, params: { id: version.id }
        expect(response.headers['Content-Disposition']).to include('filename="structure.sql"')
        expect(response.body).to eq(version.content)
      end
    end

    context 'with non-existent version' do
      it 'returns 404' do
        get :download, params: { id: 99_999 }
        expect(response).to have_http_status(:not_found)
        expect(response.body).to include('Schema version not found')
      end
    end
  end

  describe 'layout' do
    let(:html) do
      get :index
      response.body
    end

    it 'pins every CDN asset to an exact version with an SRI hash' do
      assets = html.scan(/<(?:link|script)[^>]+cdn\.jsdelivr\.net[^>]+>/)
      expect(assets.size).to eq(3)
      expect(assets).to all(match(%r{/npm/[a-z-]+@\d+\.\d+\.\d+/}))
      expect(assets).to all(match(%r{integrity="sha384-[A-Za-z0-9+/]{64}"}))
      expect(assets).to all(include('crossorigin="anonymous"'))
    end

    it 'has no inline event handlers or style attributes' do
      create(:schema_version)
      get :show, params: { id: BetterStructureSql::SchemaVersion.last.id }
      expect(html + response.body).not_to match(/\son[a-z]+=|\sstyle=/)
    end

    it 'labels icon-only and interactive controls for assistive technology' do
      expect(html).to include('aria-label="Toggle navigation"')
      expect(html).to include('href="#main-content"')
      expect(html.scan(/<i class="bi [^>]*>/)).to all(include('aria-hidden="true"'))
    end

    it 'asks search engines not to index the schema' do
      expect(html).to include('<meta name="robots" content="noindex, nofollow">')
    end

    it 'titles each page' do
      version = create(:schema_version)
      get :show, params: { id: version.id }
      expect(response.body).to include("<title>Schema Version ##{version.id} - BetterStructureSql</title>")
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
