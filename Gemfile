# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

# CI matrix knobs (.github/workflows/ci.yml, canary.yml). Unset, the bundle is
# exactly the committed Gemfile.lock; set, CI resolves through the unlocked
# gemfiles/matrix.gemfile so the lock is never touched.
#   RAILS_VERSION  MAJOR.MINOR ("7.1" ... "8.1"), or "edge" for rails/rails main
#   DB_ADAPTER     "mysql2" adds the MySQL driver (pg and sqlite3 are always bundled)
rails_version = ENV.fetch('RAILS_VERSION', nil)
case rails_version
when nil then nil
when 'edge' then gem 'rails', github: 'rails/rails', branch: 'main'
else gem 'rails', "~> #{rails_version}.0"
end
gem 'mysql2', '>= 0.5' if ENV['DB_ADAPTER'] == 'mysql2'

gem 'rake', '>= 13.0'

group :development, :test do
  gem 'database_cleaner-active_record', '>= 2.1'
  gem 'factory_bot_rails', '>= 6.2'
  gem 'pry'
  gem 'pry-byebug'
  gem 'rails-controller-testing', '>= 1.0'
  gem 'rspec', '>= 3.12'
  gem 'rspec-rails', '>= 6.1'
  gem 'rubocop', '>= 1.50'
  gem 'rubocop-performance', '>= 1.20'
  gem 'rubocop-rails', '>= 2.19'
  gem 'rubocop-rspec', '>= 3.0'
  # Rails 7.1's SQLite adapter activates sqlite3 ~> 1.4; 7.2+ takes 2.x.
  gem 'sqlite3', rails_version&.start_with?('7.1') ? '~> 1.4' : '>= 2.1'
end
