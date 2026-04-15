# frozen_string_literal: true

source "https://rubygems.org"

gemspec name: "api_serializer", path: "api_serializer"
gemspec name: "api_query_language", path: "api_query_language"
gemspec name: "api_query_language-active_record", path: "api_query_language_active_record"
gemspec name: "another_api", path: "another_api"

group :development, :test do
  gem "rake"
  gem "minitest"
  gem "standard"
  gem "simplecov", require: false
end

group :test do
  gem "rails", ">= 7.2.0"
  gem "actionpack", ">= 7.2.0"
  gem "action_policy"
  gem "dry-monads"
  gem "activerecord", ">= 7.2.0"
  gem "sqlite3"
  gem "pg"
end

gem "literal", "~> 1.6.0"
