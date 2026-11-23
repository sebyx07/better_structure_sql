# frozen_string_literal: true

# Round-trip check run by CI:
#   1. dump the migrated development database
#   2. load that dump into a freshly purged test database
#   3. dump the test database again
# ROUND_TRIP_LAYOUT=multi_file uses the directory layout (default: single file).
# Fails unless both dumps are byte-identical and both databases hold the same
# schema in sqlite_master, which catches objects that are lost or altered
# identically on both sides of the cycle.
namespace :bss do
  desc 'Dump development, load into a fresh test database, dump again, compare'
  task round_trip: :environment do
    out_dir = Rails.root.join('tmp/round_trip')
    FileUtils.rm_rf(out_dir)
    FileUtils.mkdir_p(out_dir)

    first, second = RoundTrip.output_paths(out_dir)
    source_schema = RoundTrip.dump(first)
    RoundTrip.load_into_fresh_test_database(first)
    loaded_schema = RoundTrip.dump(second)

    RoundTrip.compare!(out_dir, first, second, source_schema, loaded_schema)
    puts 'Round trip OK: dumps are byte-identical and sqlite_master matches'
  end
end

# Helpers for bss:round_trip
module RoundTrip
  module_function

  def dump(path)
    config = BetterStructureSql.configuration
    config.output_path = path.to_s
    config.enable_schema_versions = false
    BetterStructureSql::Dumper.new(config, ActiveRecord::Base.connection).dump(store_version: false)
    schema(ActiveRecord::Base.connection)
  end

  def load_into_fresh_test_database(path)
    test_config = ActiveRecord::Base.configurations.find_db_config('test')
    ActiveRecord::Tasks::DatabaseTasks.purge(test_config)
    ActiveRecord::Base.establish_connection(test_config)
    BetterStructureSql::SchemaLoader.new.load(path.to_s)
  end

  def output_paths(out_dir)
    extension = ENV.fetch('ROUND_TRIP_LAYOUT', 'single_file') == 'multi_file' ? '' : '.sql'
    [out_dir.join("first#{extension}"), out_dir.join("second#{extension}")]
  end

  # A dump file's content, or every file of a dump directory prefixed by its path
  def dump_content(path)
    return File.read(path) if File.file?(path)

    files = Dir.glob('**/*', base: path).sort.select { |file| File.file?(path.join(file)) }
    files.map { |file| "#{file}\n#{File.read(path.join(file))}" }.join("\n")
  end

  def compare!(out_dir, first_path, second_path, source_schema, loaded_schema)
    first = dump_content(first_path)
    abort 'Source database has no tables; run db:migrate first' unless first.include?('CREATE TABLE')
    abort "Dumps differ: diff -ru #{first_path} #{second_path}" unless first == dump_content(second_path)

    return if source_schema == loaded_schema

    File.write(out_dir.join('source_schema.sql'), source_schema)
    File.write(out_dir.join('loaded_schema.sql'), loaded_schema)
    abort "Loaded database differs from source: diff -u #{out_dir.join('source_schema.sql')} #{out_dir.join('loaded_schema.sql')}"
  end

  # Every object's SQL exactly as SQLite stores it, then the applied migration
  # versions: a loaded dump that lost them would leave every migration pending
  def schema(connection)
    objects = connection.select_values(<<~SQL.squish).join(";\n\n")
      SELECT sql FROM sqlite_master
      WHERE sql IS NOT NULL
        AND name NOT LIKE 'sqlite_%'
      ORDER BY type, name
    SQL
    versions = connection.select_values('SELECT version FROM schema_migrations ORDER BY version')
    "#{objects}\n\n-- schema_migrations: #{versions.join(', ')}"
  end
end
