# frozen_string_literal: true

require_relative "lib/api_query_language/version"

Gem::Specification.new do |spec|
  spec.name = "api_query_language"
  spec.version = ApiQueryLanguage::VERSION
  spec.authors = ["Stephen Ierodiaconou"]
  spec.email = ["stevegeek@gmail.com"]

  spec.summary = "A filter and sort query-language parser for JSON APIs."
  spec.description = "api_query_language parses filter and sort expressions from query strings, producing a structured AST that consumers can map onto their own query backend (ActiveRecord, Sequel, Elasticsearch, etc). Zero ActiveSupport and zero ActiveRecord dependency."
  spec.homepage = "https://github.com/stevegeek/another_api"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main/api_query_language"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb"] + ["README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "literal", "~> 1.0"
  spec.add_dependency "racc", "~> 1.7"
end
