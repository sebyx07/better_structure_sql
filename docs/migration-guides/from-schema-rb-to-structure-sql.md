# From schema.rb to structure.sql

`schema.rb` cannot express database-specific objects: functions, triggers, views, extensions, custom types, check constraints written in SQL. A SQL dump can. This guide switches a Rails app from `db/schema.rb` to a dump written by this gem.

## Before you switch

| Check | Why |
|---|---|
| Your objects are in the [feature matrix](../../README.md#feature-matrix) | Aggregates, rules, row-level security policies and non-`public` PostgreSQL schemas are not dumped |
| Everyone can run migrations locally | The first SQL dump must come from a fully migrated database |

## Steps

1. Install:

   ```ruby
   # Gemfile
   gem 'better_structure_sql'
   ```

   ```bash
   bundle install
   rails generate better_structure_sql:install
   rails db:migrate
   ```

2. Optional: keep the last `schema.rb` as a stored version. Point the gem at it, store, then continue:

   ```ruby
   config.output_path = 'db/schema.rb'
   config.enable_schema_versions = true
   ```

   ```bash
   rails db:schema:dump     # Rails writes schema.rb; the gem does not replace Ruby-format dumps
   rails db:schema:store    # stored with format_type = 'rb'
   ```

3. Configure the SQL dump:

   ```ruby
   # config/initializers/better_structure_sql.rb
   BetterStructureSql.configure do |config|
     config.output_path = 'db/structure.sql'   # or 'db/schema' for multi-file output
     config.replace_default_dump = true        # also sets schema_format = :sql
     config.replace_default_load = true
   end
   ```

4. Dump and verify it loads into an empty database:

   ```bash
   rails db:schema:dump
   RAILS_ENV=test rails db:drop db:create db:schema:load
   bundle exec rspec    # or your test command
   ```

5. Commit:

   ```bash
   git rm db/schema.rb
   git add db/structure.sql config/initializers/better_structure_sql.rb
   ```

6. Update anything that names `db/schema.rb`: CI cache keys, deploy scripts, onboarding docs.

## Going back

```ruby
config.replace_default_dump = false
config.replace_default_load = false
```

Set `config.active_record.schema_format = :ruby` in `config/application.rb` if you set it elsewhere, run `rails db:schema:dump`, and restore `db/schema.rb` in git. Stored versions of either format stay in the table.

## Troubleshooting

| Symptom | Cause and fix |
|---|---|
| `relation already exists` on load | The loader does not drop objects. Load into an empty database (`db:drop db:create` first). |
| An object is missing from the dump | Check its `include_*` option, then the [feature matrix](../../README.md#feature-matrix). If it should be there, open a bug report with the object's definition. |
| `rails db:schema:dump` still writes `schema.rb` | `replace_default_dump` is ignored when `output_path` ends in `.rb`; check `output_path`. |
| The dump is too large to review | Switch to [multi-file output](../features/multi-file-output.md). |
