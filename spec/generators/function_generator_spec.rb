require "spec_helper"

RSpec.describe BetterStructureSql::Generators::FunctionGenerator do
  subject(:generator) { described_class.new }

  describe "#generate" do
    it "generates function definition from pg_get_functiondef" do
      function = {
        name: "update_timestamp",
        schema: "public",
        definition: <<~SQL.strip
          CREATE OR REPLACE FUNCTION public.update_timestamp()
           RETURNS trigger
           LANGUAGE plpgsql
          AS $function$
          BEGIN
            NEW.updated_at = NOW();
            RETURN NEW;
          END;
          $function$
        SQL
      }
      result = generator.generate(function)

      expect(result).to include("CREATE OR REPLACE FUNCTION public.update_timestamp()")
      expect(result).to include("RETURNS trigger")
      expect(result).to include("LANGUAGE plpgsql")
      expect(result).to end_with(";")
    end

    it "adds semicolon if missing" do
      function = {
        name: "simple_func",
        schema: "public",
        definition: "CREATE FUNCTION simple_func() RETURNS void AS $$ SELECT 1 $$ LANGUAGE sql"
      }
      result = generator.generate(function)

      expect(result).to end_with(";")
    end

    it "does not add duplicate semicolon" do
      function = {
        name: "simple_func",
        schema: "public",
        definition: "CREATE FUNCTION simple_func() RETURNS void AS $$ SELECT 1 $$ LANGUAGE sql;"
      }
      result = generator.generate(function)

      expect(result).to end_with(";")
      expect(result).not_to end_with(";;")
    end
  end
end
