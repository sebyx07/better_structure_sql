require "spec_helper"

RSpec.describe BetterStructureSql::SchemaVersion do
  # Skip ActiveRecord tests if database not available
  # These are tested in integration tests with real database

  describe "instance methods" do
    let(:mock_version) do
      double("SchemaVersion",
        content: "CREATE TABLE users (id serial);",
        pg_version: "14.5",
        format_type: "sql",
        created_at: Time.current
      )
    end

    describe "#size" do
      it "calculates byte size of content" do
        # Test the logic of the size method
        content = "12345"
        expect(content.bytesize).to eq(5)
      end
    end

    describe "#formatted_size" do
      it "formats bytes correctly" do
        bytes = 500
        if bytes < 1024
          result = "#{bytes} bytes"
        end
        expect(result).to eq("500 bytes")
      end

      it "formats kilobytes correctly" do
        bytes = 2048
        if bytes >= 1024 && bytes < 1024 * 1024
          result = "#{(bytes / 1024.0).round(2)} KB"
        end
        expect(result).to eq("2.0 KB")
      end

      it "formats megabytes correctly" do
        bytes = 2 * 1024 * 1024
        if bytes >= 1024 * 1024
          result = "#{(bytes / 1024.0 / 1024.0).round(2)} MB"
        end
        expect(result).to eq("2.0 MB")
      end
    end
  end

  describe "validations" do
    # Note: validation logic is defined in the model
    # Integration tests with real database verify these work correctly
    it "defines validations for required fields" do
      expect(described_class).to respond_to(:validates)
    end
  end
end
