require_relative "lib/better_structure_sql/version"

Gem::Specification.new do |spec|
  spec.name = "better_structure_sql"
  spec.version = BetterStructureSql::VERSION
  spec.authors = ["Better Structure SQL Team"]
  spec.email = ["team@example.com"]

  spec.summary = "Clean PostgreSQL schema dumps for Rails without pg_dump noise"
  spec.description = "Generate clean, maintainable PostgreSQL schema dumps using pure Ruby introspection. No pg_dump dependency, deterministic output, optional schema versioning."
  spec.homepage = "https://github.com/example/better_structure_sql"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 7.0"
  spec.add_dependency "pg", ">= 1.0"

  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rspec-rails", "~> 6.0"
  spec.add_development_dependency "database_cleaner-active_record", "~> 2.1"
  spec.add_development_dependency "factory_bot_rails", "~> 6.2"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "rubocop-rails", "~> 2.19"
  spec.add_development_dependency "rubocop-rspec", "~> 2.20"
end
