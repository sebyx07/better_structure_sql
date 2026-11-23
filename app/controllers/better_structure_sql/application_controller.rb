# frozen_string_literal: true

module BetterStructureSql
  # Base controller for BetterStructureSql Rails Engine
  #
  # The web UI exposes the full database schema, so access control fails
  # closed: outside development and test every request is answered with
  # 403 Forbidden until the host application configures one of the following.
  #
  # @example Access check in an initializer
  #   BetterStructureSql::Engine.authenticate_with do |controller|
  #     controller.request.env['warden']&.user&.admin?
  #   end
  #
  # @example Route constraints (Devise shown), declared to the engine
  #   # config/initializers/better_structure_sql.rb
  #   BetterStructureSql::Engine.authentication_handled_by_routes!
  #
  #   # config/routes.rb
  #   authenticate :user, ->(user) { user.admin? } do
  #     mount BetterStructureSql::Engine, at: "/better_structure_sql"
  #   end
  #
  # @example Overriding the hook
  #   BetterStructureSql::ApplicationController.class_eval do
  #     private
  #
  #     def authenticate_access!
  #       head :unauthorized unless current_user&.admin?
  #     end
  #   end
  class ApplicationController < ActionController::Base
    # Response body sent when no access control has been configured
    ACCESS_NOT_CONFIGURED_MESSAGE = <<~MESSAGE
      BetterStructureSql: access to the schema versions UI is not configured.

      This UI exposes your database schema, so outside development and test it
      is disabled until the application declares how access is controlled.
      Add one of these to config/initializers/better_structure_sql.rb:

        # 1. Check access in the engine
        BetterStructureSql::Engine.authenticate_with do |controller|
          controller.request.env['warden']&.user&.admin?
        end

        # 2. The routes mounting the engine already restrict access
        #    (Devise `authenticate`, a `constraints` block, ...)
        BetterStructureSql::Engine.authentication_handled_by_routes!
    MESSAGE

    # Environments where the UI is open when no access control is configured
    LOCAL_ENVIRONMENTS = %w[development test].freeze

    layout 'better_structure_sql/application'

    protect_from_forgery with: :exception

    before_action :authenticate_access!
    # Schema dumps are sensitive: keep them out of browser and proxy caches
    before_action :no_store

    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

    private

    # Authentication hook for engine access control
    #
    # Runs the check registered with {Engine.authenticate_with}. Without one,
    # access is open only in development and test, or when the host declared
    # {Engine.authentication_handled_by_routes!}. May be overridden by the
    # host application.
    #
    # @return [void]
    def authenticate_access!
      authenticator = Engine.authenticator
      return run_authenticator(authenticator) if authenticator
      return if Engine.authentication_handled_by_routes? || local_environment?

      deny_unconfigured_access
    end

    def run_authenticator(authenticator)
      return if authenticator.call(self) || performed?

      render plain: 'Forbidden', status: :forbidden
    end

    def local_environment?
      LOCAL_ENVIRONMENTS.include?(Rails.env.to_s)
    end

    def deny_unconfigured_access
      logger&.error('[BetterStructureSql] Request denied: engine access control is not configured')
      render plain: ACCESS_NOT_CONFIGURED_MESSAGE, status: :forbidden
    end

    def render_not_found
      render plain: 'Schema version not found', status: :not_found
    end
  end
end
