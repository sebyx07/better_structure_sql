module BetterStructureSql
  module Generators
    class TriggerGenerator < Base
      def generate(trigger)
        # PostgreSQL's pg_get_triggerdef returns complete CREATE TRIGGER statement
        definition = trigger[:definition].strip

        # Ensure definition ends with semicolon
        definition += ";" unless definition.end_with?(";")

        definition
      end
    end
  end
end
