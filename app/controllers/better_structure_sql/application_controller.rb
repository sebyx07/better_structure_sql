# frozen_string_literal: true

module BetterStructureSql
  class ApplicationController < ActionController::Base
    layout 'better_structure_sql/application'

    # Override this method in your host application to add authentication
    # Example using Devise route constraints (recommended):
    #   authenticate :user, ->(user) { user.admin? } do
    #     mount BetterStructureSql::Engine, at: "/better_structure_sql"
    #   end
    #
    # Or override at controller level:
    #   BetterStructureSql::ApplicationController.class_eval do
    #     before_action :authenticate_admin!
    #
    #     private
    #
    #     def authenticate_admin!
    #       head :unauthorized unless current_user&.admin?
    #     end
    #   end
    before_action :authenticate_access!

    private

    def authenticate_access!
      # Default: no authentication (open access)
      # Override this in your host application for production use
      true
    end
  end
end
