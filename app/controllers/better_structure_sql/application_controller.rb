# frozen_string_literal: true

module BetterStructureSql
  # Base controller for BetterStructureSql Rails Engine
  #
  # Provides authentication and authorization hooks for the web UI
  # that displays stored schema versions. By default, no authentication
  # is required (open access), but this should be overridden in production.
  #
  # @example Using Devise route constraints (recommended)
  #   authenticate :user, ->(user) { user.admin? } do
  #     mount BetterStructureSql::Engine, at: "/better_structure_sql"
  #   end
  #
  # @example Using controller-level authentication
  #   BetterStructureSql::ApplicationController.class_eval do
  #     before_action :authenticate_admin!
  #
  #     private
  #
  #     def authenticate_admin!
  #       head :unauthorized unless current_user&.admin?
  #     end
  #   end
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

    # Authentication hook for engine access control
    #
    # Default implementation allows open access. Override this method
    # in your host application to add authentication and authorization.
    # This method is called before all controller actions via before_action.
    #
    # @return [Boolean] true to allow access, false or head :unauthorized to deny
    def authenticate_access!
      # Default: no authentication (open access)
      # Override this in your host application for production use
      true
    end
  end
end
