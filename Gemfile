source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.1"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.2.1"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Use mysql as the database for Active Record
gem "mysql2", "~> 0.5"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", "~> 6.4.1"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri mingw x64_mingw ]

  # Brings Rails named routes to modern javascript (https://github.com/elmassimo/js_from_routes)
  gem "js_from_routes", "~> 2.0.4"

  # rspec-rails brings the RSpec testing framework to Ruby on Rails as a drop-in alternative to its default testing framework, Minitest.
  gem 'rspec-rails', '~> 7.0.0'

  # This gem brings back assigns to your controller tests as well as assert_template to both controller and integration tests.
  gem 'rails-controller-testing'

  # Faker is a library for generating fake data such as names, addresses, and phone numbers. It is useful for testing and seeding databases.
  gem 'faker'
end

group :development do
  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"

  # Easily generate a diagram based on your application's Active Record models
  gem "rails-erd"

  # Capistrano is a framework for building automated deployment scripts
  gem "capistrano", "~> 3.17", require: false
  gem "capistrano-rails", require: false
  gem "capistrano-rvm"
  gem "capistrano-nvm", require: false
  gem "capistrano3-puma"
  gem "capistrano-sidekiq"

  # A Ruby binding to the Ed25519 elliptic curve public-key signature system described in RFC 8032
  gem "ed25519"

  # bcrypt_pbkdf is a ruby gem implementing bcrypt_pbkdf from OpenBSD
  gem "bcrypt_pbkdf"
end

# Vite is a build tool that aims to provide a faster and leaner development experience for modern web projects
gem "vite_rails"

# Inertia replaces your application's view layer. The views returned by your application are JavaScript page components. [https://inertiajs.com]
gem "inertia_rails", "~> 3.0"

# Audited is an ORM extension that logs all changes to your models
gem "audited"

# Devise is a flexible authentication solution for Rails based on Warden
gem "devise"

# Administrate is a library for Rails apps that automatically generates admin dashboards
gem "administrate"

# Use Redis adapter to run Action Cable in production
gem "redis"

# Sidekiq gem being updated to 8.1.0 which in turn requires connection_pool to be at version >= 3.0.0. This then introduced a compatibility issue between connection_pool and Rails 8.1
# https://github.com/rails/rails/pull/56292/commits
gem "connection_pool", "< 3"

# Simple, efficient background processing for Ruby
gem "sidekiq"
gem "sidekiq-scheduler"

# Figaro parses a Git-ignored YAML file in your application and loads its values into ENV
gem "figaro"

# Pundit provides a set of helpers which guide you in leveraging regular Ruby classes and object oriented design patterns to build a simple, robust and scaleable authorization system
gem "pundit"

# Rack::Attack is a rack middleware for blocking & throttling abusive requests
gem "rack-attack"

# Makes http fun again! Ain't no party like a httparty, because a httparty don't stop.
gem "httparty"

# Blueprinter is a JSON Object Presenter for Ruby that takes business objects and breaks them down into simple hashes and serializes them to JSON
gem "blueprinter"

# A pure-Ruby implementation of sd_notify(3) that can be used to communicate state changes of Ruby programs to systemd
gem "sd_notify"

# The Bugsnag exception reporter for Ruby gives you instant notification of exceptions thrown from your Rails, Sinatra, Rack or plain Ruby app
gem "bugsnag", "~> 6.29"
