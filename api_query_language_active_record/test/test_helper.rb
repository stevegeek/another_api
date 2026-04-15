# frozen_string_literal: true

if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start do
    enable_coverage :branch
    minimum_coverage line: 85, branch: 70
    add_filter "/test/"
  end
end

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
$LOAD_PATH.unshift File.expand_path("../../api_query_language/lib", __dir__)
$LOAD_PATH.unshift File.expand_path("support", __dir__)

# AS is a test-only dep — the libs stay AS-free. The DB integration tests need
# Time.zone for date/time fixtures.
require "active_support"
require "active_support/core_ext/time"
Time.zone = "UTC"

# Load both the base parse-only gem and the AR backend.
require "api_query_language"
require "api_query_language/active_record"

require "minitest/autorun"
require "test_in_temp_database"

# Integration tests use SQLite by default. Set DATABASE_URL to a Postgres URL
# to run the full suite (including PG-only array/jsonb tests):
#
#   DATABASE_URL=postgres://user:pass@host/dbname bundle exec rake test

class ApiQueryLanguageTestCase < Minitest::Test
  class << self
    def test(name, &block)
      method_name = "test_#{name.gsub(/\s+/, "_").gsub(/[^A-Za-z0-9_]/, "")}"
      raise "duplicate test: #{method_name}" if method_defined?(method_name)
      define_method(method_name, &block)
    end

    def setup(&block)
      setup_hooks << block
    end

    def setup_hooks = @setup_hooks ||= []

    def inherited(subclass)
      super
      subclass.instance_variable_set(:@setup_hooks, setup_hooks.dup)
    end
  end

  def setup
    super
    self.class.setup_hooks.each { |h| instance_exec(&h) }
  end

  def assert_nothing_raised(*exceptions)
    yield
  rescue *(exceptions.empty? ? [StandardError] : exceptions) => e
    flunk "Expected nothing to be raised, but #{e.class} was raised: #{e.message}"
  end
end
