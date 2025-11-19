# frozen_string_literal: true

require_relative 'lib/better_structure_sql/version'

Gem::Specification.new do |spec|
  spec.name = 'better_structure_sql'
  spec.version = BetterStructureSql::VERSION
  spec.authors = ['sebyx07']
  spec.email = ['sebyx07.pro@gmail.com']

  spec.summary = 'Clean database schema dumps for Rails (PostgreSQL, MySQL, SQLite) without external tool dependencies'
  spec.description = <<~DESC
    Pure Ruby database schema dumper for Rails applications supporting PostgreSQL, MySQL, and SQLite.
    Generates clean, deterministic structure.sql files without pg_dump/mysqldump/sqlite3 CLI dependencies.
    Supports both single-file and multi-file output for massive schemas with tens of thousands
    of database objects. Includes schema versioning with ZIP storage and web UI for browsing versions.
  DESC
  spec.homepage = 'https://sebyx07.github.io/better_structure_sql/'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/sebyx07/better_structure_sql'
  spec.metadata['documentation_uri'] = 'https://sebyx07.github.io/better_structure_sql/'
  spec.metadata['changelog_uri'] = 'https://github.com/sebyx07/better_structure_sql/blob/main/CHANGELOG.md'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/sebyx07/better_structure_sql/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'pg', '>= 1.0'
  spec.add_dependency 'rails', '>= 7.0'
  spec.add_dependency 'rubyzip', '>= 2.0.0'

  spec.add_development_dependency 'database_cleaner-active_record', '~> 2.1'
  spec.add_development_dependency 'factory_bot_rails', '~> 6.2'
  spec.add_development_dependency 'rails-controller-testing', '~> 1.0'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rspec-rails', '~> 6.0'
  spec.add_development_dependency 'rubocop', '~> 1.50'
  spec.add_development_dependency 'rubocop-performance', '~> 1.20'
  spec.add_development_dependency 'rubocop-rails', '~> 2.19'
  spec.add_development_dependency 'rubocop-rspec', '~> 3.0'
  spec.add_development_dependency 'sqlite3', '>= 2.1'
end
