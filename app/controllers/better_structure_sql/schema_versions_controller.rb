# frozen_string_literal: true

module BetterStructureSql
  class SchemaVersionsController < ApplicationController
    # GET /better_structure_sql/schema_versions
    def index
      @schema_versions = SchemaVersion.order(created_at: :desc).limit(100)
    end

    # GET /better_structure_sql/schema_versions/:id
    def show
      @schema_version = SchemaVersion.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render plain: 'Schema version not found', status: :not_found
    end

    # GET /better_structure_sql/schema_versions/:id/raw
    def raw
      @schema_version = SchemaVersion.find(params[:id])

      send_data @schema_version.content,
                filename: "schema_version_#{@schema_version.id}_#{@schema_version.format_type}.txt",
                type: 'text/plain',
                disposition: 'attachment'
    rescue ActiveRecord::RecordNotFound
      render plain: 'Schema version not found', status: :not_found
    end
  end
end
