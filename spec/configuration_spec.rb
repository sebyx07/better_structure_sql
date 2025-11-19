require "spec_helper"

RSpec.describe BetterStructureSql::Configuration do
  subject(:config) { described_class.new }

  describe "defaults" do
    it "sets output_path to db/structure.sql" do
      expect(config.output_path).to eq("db/structure.sql")
    end

    it "sets search_path to default PostgreSQL value" do
      expect(config.search_path).to eq('"$user", public')
    end

    it "disables replace_default_dump by default" do
      expect(config.replace_default_dump).to be false
    end

    it "enables include_extensions by default" do
      expect(config.include_extensions).to be true
    end

    it "disables include_functions by default" do
      expect(config.include_functions).to be false
    end

    it "disables include_triggers by default" do
      expect(config.include_triggers).to be false
    end

    it "disables include_views by default" do
      expect(config.include_views).to be false
    end

    it "disables schema versioning by default" do
      expect(config.enable_schema_versions).to be false
    end

    it "sets schema_versions_limit to 10" do
      expect(config.schema_versions_limit).to eq(10)
    end

    it "sets indent_size to 2" do
      expect(config.indent_size).to eq(2)
    end

    it "enables section spacing by default" do
      expect(config.add_section_spacing).to be true
    end

    it "enables table sorting by default" do
      expect(config.sort_tables).to be true
    end
  end

  describe "#validate!" do
    context "when output_path is blank" do
      it "raises an error" do
        config.output_path = ""
        expect { config.validate! }.to raise_error(BetterStructureSql::Error, /output_path cannot be blank/)
      end
    end

    context "when output_path is nil" do
      it "raises an error" do
        config.output_path = nil
        expect { config.validate! }.to raise_error(BetterStructureSql::Error, /output_path cannot be blank/)
      end
    end

    context "when schema_versions_limit is negative" do
      it "raises an error" do
        config.schema_versions_limit = -1
        expect { config.validate! }.to raise_error(BetterStructureSql::Error, /must be a non-negative integer/)
      end
    end

    context "when schema_versions_limit is not an integer" do
      it "raises an error" do
        config.schema_versions_limit = "10"
        expect { config.validate! }.to raise_error(BetterStructureSql::Error, /must be a non-negative integer/)
      end
    end

    context "when indent_size is zero" do
      it "raises an error" do
        config.indent_size = 0
        expect { config.validate! }.to raise_error(BetterStructureSql::Error, /must be a positive integer/)
      end
    end

    context "when indent_size is negative" do
      it "raises an error" do
        config.indent_size = -2
        expect { config.validate! }.to raise_error(BetterStructureSql::Error, /must be a positive integer/)
      end
    end

    context "when all settings are valid" do
      it "does not raise an error" do
        expect { config.validate! }.not_to raise_error
      end
    end
  end
end
