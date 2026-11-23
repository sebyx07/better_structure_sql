# frozen_string_literal: true

require 'rails_helper'

# Ground truth for the PostgreSQL dump: build a rich schema, dump it, load the
# dump into an empty database and dump again. The load must succeed, both dumps
# must be byte-identical and both databases must have the same catalog contents.
class RoundTripSourceRecord < ActiveRecord::Base
  self.abstract_class = true
end

class RoundTripTargetRecord < ActiveRecord::Base
  self.abstract_class = true
end

RSpec.describe 'PostgreSQL dump round-trip' do
  # Catalog facts the dump must preserve, one sorted text line per object
  let(:catalog_fingerprint_sql) do
    <<~SQL
      SELECT 'column ' || c.relname || '.' || a.attname || ' ' || format_type(a.atttypid, a.atttypmod)
             || ' notnull=' || a.attnotnull || ' identity=' || a.attidentity::text || ' generated=' || a.attgenerated::text
             || ' collation=' || a.attcollation::regcollation::text
             || ' default=' || coalesce(pg_get_expr(ad.adbin, ad.adrelid), '')
      FROM pg_attribute a
      JOIN pg_class c ON c.oid = a.attrelid
      JOIN pg_namespace n ON n.oid = c.relnamespace
      LEFT JOIN pg_attrdef ad ON ad.adrelid = a.attrelid AND ad.adnum = a.attnum
      WHERE n.nspname = 'public' AND c.relkind IN ('r', 'p', 'v', 'm', 'c') AND a.attnum > 0 AND NOT a.attisdropped
      UNION ALL
      SELECT 'constraint ' || conrelid::regclass::text || coalesce(contypid::regtype::text, '') || ' ' || conname || ' '
             || pg_get_constraintdef(oid) || ' validated=' || convalidated
      FROM pg_constraint WHERE connamespace = 'public'::regnamespace AND contype <> 'n'
      UNION ALL
      SELECT 'index ' || indexdef FROM pg_indexes WHERE schemaname = 'public'
      UNION ALL
      SELECT 'partition ' || c.relname || ' ' || coalesce(pg_get_expr(c.relpartbound, c.oid), '')
             || ' key=' || coalesce(pg_get_partkeydef(c.oid), '')
      FROM pg_class c WHERE c.relnamespace = 'public'::regnamespace AND c.relkind IN ('r', 'p')
      UNION ALL
      SELECT 'relation ' || c.relname || ' persistence=' || c.relpersistence::text
             || ' options=' || coalesce(array_to_string(c.reloptions, ','), '')
             || ' inherits=' || coalesce((SELECT string_agg(i.inhparent::regclass::text, ',' ORDER BY i.inhseqno)
                                          FROM pg_inherits i WHERE i.inhrelid = c.oid), '')
             || ' local_columns=' || coalesce((SELECT string_agg(a.attname || ':' || a.attislocal || ':' || a.attinhcount, ','
                                                                 ORDER BY a.attnum)
                                               FROM pg_attribute a WHERE a.attrelid = c.oid AND a.attnum > 0), '')
      FROM pg_class c WHERE c.relnamespace = 'public'::regnamespace AND c.relkind IN ('r', 'p')
      UNION ALL
      SELECT 'sequence ' || sequencename || ' ' || data_type::text || ' ' || start_value || ' ' || increment_by || ' '
             || min_value || ' ' || max_value || ' ' || cache_size || ' ' || cycle
             || ' owned_by=' || coalesce((SELECT refobjid::regclass::text || '.' || refobjsubid || ':' || deptype::text
                                          FROM pg_depend WHERE objid = (schemaname || '.' || quote_ident(sequencename))::regclass
                                            AND refclassid = 'pg_class'::regclass AND deptype <> 'n'), '')
      FROM pg_sequences WHERE schemaname = 'public'
      UNION ALL
      SELECT 'trigger ' || pg_get_triggerdef(oid) FROM pg_trigger WHERE NOT tgisinternal
      UNION ALL
      SELECT 'routine ' || pg_get_functiondef(p.oid) FROM pg_proc p
      WHERE p.pronamespace = 'public'::regnamespace AND p.prokind IN ('f', 'p')
      UNION ALL
      SELECT 'view ' || c.relname || ' ' || pg_get_viewdef(c.oid) FROM pg_class c
      WHERE c.relnamespace = 'public'::regnamespace AND c.relkind IN ('v', 'm')
      UNION ALL
      SELECT 'enum ' || enumtypid::regtype::text || ' ' || string_agg(enumlabel, ',' ORDER BY enumsortorder)
      FROM pg_enum GROUP BY enumtypid
      UNION ALL
      SELECT 'range ' || rngtypid::regtype::text || ' ' || rngsubtype::regtype::text FROM pg_range
      UNION ALL
      SELECT 'domain ' || t.typname || ' ' || format_type(t.typbasetype, t.typtypmod) || ' notnull=' || t.typnotnull
             || ' default=' || coalesce(t.typdefault, '')
      FROM pg_type t WHERE t.typnamespace = 'public'::regnamespace AND t.typtype = 'd'
      UNION ALL
      SELECT 'comment ' || pg_describe_object(classoid, objoid, objsubid) || ' ' || description FROM pg_description d
      WHERE d.classoid IN ('pg_class'::regclass, 'pg_proc'::regclass)
        AND (d.classoid <> 'pg_class'::regclass OR d.objoid IN (SELECT oid FROM pg_class WHERE relnamespace = 'public'::regnamespace))
        AND (d.classoid <> 'pg_proc'::regclass OR d.objoid IN (SELECT oid FROM pg_proc WHERE pronamespace = 'public'::regnamespace))
      UNION ALL
      SELECT 'extension ' || extname FROM pg_extension
      ORDER BY 1
    SQL
  end

  let(:temp_dir) { Dir.mktmpdir }
  let(:config) do
    BetterStructureSql::Configuration.new.tap do |c|
      c.output_path = File.join(temp_dir, 'structure.sql')
    end
  end

  before(:all) do
    skip 'requires a PostgreSQL DATABASE_URL' unless ActiveRecord::Base.connection.adapter_name.match?(/postg/i)

    base_config = ActiveRecord::Base.connection_db_config.configuration_hash
    @connection_classes = [RoundTripSourceRecord, RoundTripTargetRecord]
    @database_names = %w[source target].map { |role| "#{base_config[:database]}_round_trip_#{role}" }
    @connection_classes.zip(@database_names).each do |connection_class, database|
      ActiveRecord::Base.connection.drop_database(database)
      ActiveRecord::Base.connection.create_database(database)
      connection_class.establish_connection(base_config.merge(database:))
    end
    RoundTripSourceRecord.connection.execute(File.read(File.expand_path('../fixtures/postgresql_round_trip.sql', __dir__)))
  end

  after(:all) do
    next unless @connection_classes

    @connection_classes.each(&:remove_connection)
    @database_names.each { |database| ActiveRecord::Base.connection.drop_database(database) }
  end

  before do
    @connection_classes.last.connection.execute('DROP SCHEMA public CASCADE; CREATE SCHEMA public;')
  end

  after { FileUtils.rm_rf(temp_dir) }

  def dump(connection)
    BetterStructureSql::Dumper.new(config, connection).dump(store_version: false)
  end

  it 'reloads the dump into an empty database and dumps it again identically' do
    source, target = @connection_classes.map(&:connection)

    first_dump = dump(source)
    target.execute(first_dump)
    second_dump = dump(target)

    expect(second_dump).to eq(first_dump)
    expect(target.select_values(catalog_fingerprint_sql)).to eq(source.select_values(catalog_fingerprint_sql))
  end

  it 'reloads a multi-file dump in directory order and dumps it again identically' do
    source, target = @connection_classes.map(&:connection)
    config.output_path = File.join(temp_dir, 'schema')
    config.max_lines_per_file = 20

    first_dump = dump(source)
    allow(ActiveRecord::Base).to receive(:connection).and_return(target)
    BetterStructureSql::SchemaLoader.new(config).load
    second_dump = dump(target)

    expect(second_dump).to eq(first_dump)
    expect(target.select_values(catalog_fingerprint_sql)).to eq(source.select_values(catalog_fingerprint_sql))
  end

  it 'creates functions, views and materialized views after everything they depend on' do
    statements = dump(@connection_classes.first.connection)
    position = ->(fragment) { statements.index(fragment) || raise("#{fragment} not dumped") }

    expect(statements).to include('SET check_function_bodies = false;')
    expect(position['FUNCTION public.b_double']).to be < position['FUNCTION public.a_quadruple']
    expect(position['FUNCTION public.a_quadruple']).to be < position['CREATE TABLE']
    expect(statements.rindex('CREATE TABLE')).to be < position['FUNCTION public.pending_orders']
    expect(position['FUNCTION public.pending_orders']).to be < position['VIEW "a_pending_order_labels"']
    expect(position['MATERIALIZED VIEW IF NOT EXISTS "order_totals"']).to be < position['VIEW "big_spenders"']
    expect(position['VIEW "big_spenders"']).to be < position['MATERIALIZED VIEW IF NOT EXISTS "a_big_spender_count"']
    expect(position['VIEW "big_spenders"']).to be < position['FUNCTION public.a_list_big_spenders']
    expect(position['FUNCTION public.a_list_big_spenders']).to be < position['VIEW "a_spender_ids"']
  end

  it 'creates custom types after the types and functions they use, and inheritance parents before children' do
    statements = dump(@connection_classes.first.connection)
    position = ->(fragment) { statements.index(fragment) || raise("#{fragment} not dumped") }

    expect(position['TYPE "z_kind"']).to be < position['TYPE "a_pair"']
    expect(position['DOMAIN "b_contact_email"']).to be < position['TYPE "a_contact"']
    expect(position['FUNCTION public.z_is_even']).to be < position['DOMAIN "a_even_int"']
    expect(position['DOMAIN "a_even_int"']).to be < position['FUNCTION public.a_double_even']
    expect(statements.rindex('CREATE TABLE')).to be < position['FUNCTION public.a_next_ticket']
    expect(position['TABLE IF NOT EXISTS "z_vehicles"']).to be < position['TABLE IF NOT EXISTS "b_cars"']
    expect(position['TABLE IF NOT EXISTS "b_cars"']).to be < position['TABLE IF NOT EXISTS "a_sports_cars"']
  end
end
