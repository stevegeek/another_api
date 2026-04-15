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

require "api_query_language"
require "minitest/autorun"

# Tiny test-only DSL — provides ActiveSupport::TestCase's `test "..." do` and
# `setup do` syntaxes without pulling in ActiveSupport. Mirrors the helper in
# api_serializer so the two gems test in a consistent style.
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
