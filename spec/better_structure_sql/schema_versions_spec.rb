require "spec_helper"

RSpec.describe BetterStructureSql::SchemaVersions do
  let(:connection) { double("connection") }

  before do
    # Stub ActiveRecord::Base.connection to return our mock connection
    allow(ActiveRecord::Base).to receive(:connection).and_return(connection)
  end

  describe ".store" do
    it "stores a schema version with given parameters" do
      content = "CREATE TABLE users (id serial);"
      format_type = "sql"
      pg_version = "14.5"

      # Mock the table existence check
      allow(connection).to receive(:table_exists?)
        .with("better_structure_sql_schema_versions")
        .and_return(true)

      # Mock the create
      version = instance_double(BetterStructureSql::SchemaVersion, id: 1)
      allow(BetterStructureSql::SchemaVersion).to receive(:create!)
        .and_return(version)

      # Mock cleanup
      allow(described_class).to receive(:cleanup!).and_return(0)

      result = described_class.store(
        content: content,
        format_type: format_type,
        pg_version: pg_version,
        connection: connection
      )

      expect(result).to eq(version)
    end

    it "raises error when table does not exist" do
      allow(connection).to receive(:table_exists?)
        .with("better_structure_sql_schema_versions")
        .and_return(false)

      expect {
        described_class.store(
          content: "CREATE TABLE users",
          format_type: "sql",
          pg_version: "14.5",
          connection: connection
        )
      }.to raise_error(BetterStructureSql::Error, /Schema versions table does not exist/)
    end
  end

  describe ".latest" do
    it "returns nil when table does not exist" do
      allow(described_class).to receive(:table_exists?).and_return(false)
      expect(described_class.latest).to be_nil
    end

    it "returns latest version when table exists" do
      allow(described_class).to receive(:table_exists?).and_return(true)
      version = instance_double(BetterStructureSql::SchemaVersion)
      allow(BetterStructureSql::SchemaVersion).to receive(:latest).and_return(version)

      expect(described_class.latest).to eq(version)
    end
  end

  describe ".all_versions" do
    it "returns empty array when table does not exist" do
      allow(described_class).to receive(:table_exists?).and_return(false)
      expect(described_class.all_versions).to eq([])
    end

    it "returns all versions ordered by created_at DESC" do
      allow(described_class).to receive(:table_exists?).and_return(true)
      versions = [
        instance_double(BetterStructureSql::SchemaVersion),
        instance_double(BetterStructureSql::SchemaVersion)
      ]
      relation = double("relation")
      allow(BetterStructureSql::SchemaVersion).to receive(:order).with(created_at: :desc).and_return(relation)
      allow(relation).to receive(:to_a).and_return(versions)

      expect(described_class.all_versions).to eq(versions)
    end
  end

  describe ".count" do
    it "returns 0 when table does not exist" do
      allow(described_class).to receive(:table_exists?).and_return(false)
      expect(described_class.count).to eq(0)
    end

    it "returns count when table exists" do
      allow(described_class).to receive(:table_exists?).and_return(true)
      allow(BetterStructureSql::SchemaVersion).to receive(:count).and_return(5)

      expect(described_class.count).to eq(5)
    end
  end

  describe ".by_format" do
    it "returns empty array when table does not exist" do
      allow(described_class).to receive(:table_exists?).and_return(false)
      expect(described_class.by_format("sql")).to eq([])
    end

    it "returns versions filtered by format_type" do
      allow(described_class).to receive(:table_exists?).and_return(true)
      versions = [instance_double(BetterStructureSql::SchemaVersion)]
      scope = double("scope")
      relation = double("relation")

      allow(BetterStructureSql::SchemaVersion).to receive(:by_format).with("sql").and_return(scope)
      allow(scope).to receive(:order).with(created_at: :desc).and_return(relation)
      allow(relation).to receive(:to_a).and_return(versions)

      expect(described_class.by_format("sql")).to eq(versions)
    end
  end

  describe ".cleanup!" do
    it "returns 0 when table does not exist" do
      allow(described_class).to receive(:table_exists?).and_return(false)
      expect(described_class.cleanup!(connection)).to eq(0)
    end

    it "returns 0 when limit is 0 (unlimited)" do
      allow(described_class).to receive(:table_exists?).and_return(true)
      config = instance_double(BetterStructureSql::Configuration, schema_versions_limit: 0)
      allow(BetterStructureSql).to receive(:configuration).and_return(config)

      expect(described_class.cleanup!(connection)).to eq(0)
    end

    it "returns 0 when count is within limit" do
      allow(described_class).to receive(:table_exists?).and_return(true)
      config = instance_double(BetterStructureSql::Configuration, schema_versions_limit: 10)
      allow(BetterStructureSql).to receive(:configuration).and_return(config)
      allow(BetterStructureSql::SchemaVersion).to receive(:count).and_return(5)

      expect(described_class.cleanup!(connection)).to eq(0)
    end

    it "deletes oldest versions beyond limit" do
      allow(described_class).to receive(:table_exists?).and_return(true)
      config = instance_double(BetterStructureSql::Configuration, schema_versions_limit: 3)
      allow(BetterStructureSql).to receive(:configuration).and_return(config)
      allow(BetterStructureSql::SchemaVersion).to receive(:count).and_return(5)

      version1 = instance_double(BetterStructureSql::SchemaVersion)
      version2 = instance_double(BetterStructureSql::SchemaVersion)
      relation = double("relation")

      allow(BetterStructureSql::SchemaVersion).to receive(:oldest_first).and_return(relation)
      allow(relation).to receive(:limit).with(2).and_return([version1, version2])
      allow(version1).to receive(:destroy)
      allow(version2).to receive(:destroy)

      expect(described_class.cleanup!(connection)).to eq(2)
    end
  end
end
