# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    @schema_versions_count = BetterStructureSql::SchemaVersion.count
    @latest_version = BetterStructureSql::SchemaVersion.order(created_at: :desc).first
  end
end
