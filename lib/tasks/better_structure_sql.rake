namespace :db do
  namespace :schema do
    desc "Dump the database schema to db/structure.sql using BetterStructureSql"
    task dump_better: :environment do
      require "better_structure_sql"

      dumper = BetterStructureSql::Dumper.new
      output = dumper.dump

      puts "Schema dumped to #{BetterStructureSql.configuration.output_path}"
      puts "Total size: #{output.bytesize} bytes"
    end
  end
end
