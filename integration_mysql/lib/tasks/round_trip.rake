# frozen_string_literal: true

# Round-trip check run by CI:
#   1. dump the migrated development database
#   2. load that dump into a freshly purged test database
#   3. dump the test database again
# ROUND_TRIP_LAYOUT=multi_file uses the directory layout (default: single file).
# Fails unless both dumps are byte-identical and both databases report the
# same DDL (SHOW CREATE ...), which catches objects that are lost or altered
# identically on both sides of the cycle.
namespace :bss do
  desc 'Dump development, load into a fresh test database, dump again, compare'
  task round_trip: :environment do
    out_dir = Rails.root.join('tmp/round_trip')
    FileUtils.rm_rf(out_dir)
    FileUtils.mkdir_p(out_dir)

    first, second = RoundTrip.output_paths(out_dir)
    source_ddl = RoundTrip.dump(first)
    RoundTrip.load_into_fresh_test_database(first)
    loaded_ddl = RoundTrip.dump(second)

    RoundTrip.compare!(out_dir, first, second, source_ddl, loaded_ddl)
    puts 'Round trip OK: dumps are byte-identical and SHOW CREATE output matches'
  end
end

# Helpers for bss:round_trip
module RoundTrip
  module_function

  def dump(path)
    config = BetterStructureSql.configuration
    config.output_path = path.to_s
    config.enable_schema_versions = false
    config.include_comments = true
    BetterStructureSql::Dumper.new(config, ActiveRecord::Base.connection).dump(store_version: false)
    show_create_all(ActiveRecord::Base.connection)
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

  def compare!(out_dir, first_path, second_path, source_ddl, loaded_ddl)
    first = dump_content(first_path)
    abort 'Source database has no tables; run db:migrate first' unless first.include?('CREATE TABLE')
    abort "Dumps differ: diff -ru #{first_path} #{second_path}" unless first == dump_content(second_path)

    return if source_ddl == loaded_ddl

    File.write(out_dir.join('source_ddl.sql'), source_ddl)
    File.write(out_dir.join('loaded_ddl.sql'), loaded_ddl)
    abort "Loaded database differs from source: diff -u #{out_dir.join('source_ddl.sql')} #{out_dir.join('loaded_ddl.sql')}"
  end

  # DDL of every object as MySQL itself reports it, normalized for values that
  # legitimately differ between databases (AUTO_INCREMENT counters, DEFINER)
  def show_create_all(connection)
    objects(connection).map { |kind, name| normalize(show_create(connection, kind, name)) }.join(";\n\n")
  end

  def objects(connection)
    connection.select_rows(<<~SQL.squish)
      SELECT IF(TABLE_TYPE = 'VIEW', 'VIEW', 'TABLE'), TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE()
      UNION ALL SELECT ROUTINE_TYPE, ROUTINE_NAME FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA = DATABASE()
      UNION ALL SELECT 'TRIGGER', TRIGGER_NAME FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA = DATABASE()
      ORDER BY 1, 2
    SQL
  end

  def show_create(connection, kind, name)
    row = connection.select_rows("SHOW CREATE #{kind} #{connection.quote_table_name(name)}").first
    sql = %w[TABLE VIEW].include?(kind) ? row[1] : row[2]
    kind == 'TABLE' ? sort_table_keys(sql) : sql
  end

  # Index and constraint lines are listed in creation order, which a load
  # legitimately changes; column order is significant and kept.
  def sort_table_keys(sql)
    header, *body, footer = sql.lines.map(&:chomp)
    columns, keys = body.map { |line| line.delete_suffix(',') }.partition { |line| line.start_with?('  `') }
    [header, (columns + keys.sort).join(",\n"), footer].join("\n")
  end

  # MySQL 8 prints "CHARACTER SET x" before COLLATE only for columns whose
  # charset was spelled out (e.g. added by ALTER TABLE); the column is the same.
  def normalize(sql)
    sql.sub(/ AUTO_INCREMENT=\d+/, '')
       .sub(/ DEFINER=`[^`]*`@`[^`]*`/, '')
       .gsub(/ CHARACTER SET (\w+) (?=COLLATE \1_)/, ' ')
  end
end
