# frozen_string_literal: true

if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start do
    enable_coverage :branch
    minimum_coverage line: 85, branch: 70
    add_filter "/test/"
  end
end

# Make sibling gems available without depending on bundler resolution order.
$LOAD_PATH.unshift File.expand_path("../../api_serializer/lib", __dir__)
$LOAD_PATH.unshift File.expand_path("../../api_query_language/lib", __dir__)
$LOAD_PATH.unshift File.expand_path("../../api_query_language_active_record/lib", __dir__)
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

ENV["RAILS_ENV"] = "test"

require_relative "dummy/config/environment"
require "rails/test_help"
require "minitest/autorun"

# Load the in-memory schema (we use SQLite memory).
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
load File.expand_path("dummy/db/schema.rb", __dir__)

# Routes are normally autoloaded from the dummy app, but pull them in
# explicitly so request specs can use them.
Rails.application.reload_routes!
