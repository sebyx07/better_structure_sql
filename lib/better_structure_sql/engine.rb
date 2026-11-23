# frozen_string_literal: true

module BetterStructureSql
  # Rails Engine for mountable web UI
  #
  # Provides controllers and views for browsing stored schema versions
  # through a web interface. Uses Bootstrap 5 from CDN for styling.
  #
  # The UI exposes the full database schema, so outside development and test
  # every request is denied until the host application states how access is
  # controlled, with one of {authenticate_with} or
  # {authentication_handled_by_routes!}.
  class Engine < ::Rails::Engine
    isolate_namespace BetterStructureSql

    # Set the root to the gem root directory
    # For development with Docker volume mount, the gem is at /
    # In production, this will be the gem's installed location
    config.root = ENV.fetch('BETTER_STRUCTURE_SQL_ROOT', File.expand_path('../..', __dir__))

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: 'spec/factories'
    end

    class << self
      # @return [Proc, nil] the access check registered with {authenticate_with}
      attr_reader :authenticator

      # Registers the access check run before every engine action
      #
      # The block receives the controller instance. Access is granted when it
      # returns a truthy value; otherwise the engine responds 403 Forbidden,
      # unless the block already rendered or redirected.
      #
      # @example config/initializers/better_structure_sql.rb
      #   BetterStructureSql::Engine.authenticate_with do |controller|
      #     controller.request.env['warden']&.user&.admin?
      #   end
      #
      # @yieldparam controller [BetterStructureSql::ApplicationController]
      # @return [void]
      # @raise [ArgumentError] when no block is given
      def authenticate_with(&block)
        raise ArgumentError, 'authenticate_with requires a block' unless block

        @authenticator = block
      end

      # Declares that the routes mounting the engine already restrict access
      # (for example Devise's +authenticate+ or a +constraints+ block), so the
      # engine must not perform a check of its own.
      #
      # @return [void]
      def authentication_handled_by_routes!
        @authentication_handled_by_routes = true
      end

      # @return [Boolean] whether the host declared route-level access control
      def authentication_handled_by_routes?
        @authentication_handled_by_routes == true
      end

      # Clears any registered access control, restoring the defaults
      #
      # @return [void]
      def reset_authentication!
        @authenticator = nil
        @authentication_handled_by_routes = false
      end
    end
  end
end
