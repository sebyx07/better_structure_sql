require "spec_helper"

RSpec.describe BetterStructureSql::Generators::ExtensionGenerator do
  subject(:generator) { described_class.new }

  describe "#generate" do
    context "when extension is in public schema" do
      it "generates CREATE EXTENSION without schema clause" do
        extension = { name: "pgcrypto", version: "1.3", schema: "public" }
        result = generator.generate(extension)

        expect(result).to eq("CREATE EXTENSION IF NOT EXISTS pgcrypto;")
      end
    end

    context "when extension is in custom schema" do
      it "generates CREATE EXTENSION with schema clause" do
        extension = { name: "uuid-ossp", version: "1.1", schema: "extensions" }
        result = generator.generate(extension)

        expect(result).to eq("CREATE EXTENSION IF NOT EXISTS uuid-ossp WITH SCHEMA extensions;")
      end
    end

    context "when extension is pg_catalog" do
      it "generates CREATE EXTENSION with schema clause" do
        extension = { name: "plpgsql", version: "1.0", schema: "pg_catalog" }
        result = generator.generate(extension)

        expect(result).to eq("CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;")
      end
    end
  end
end
