# frozen_string_literal: true

require_relative "lib/another_api/version"

Gem::Specification.new do |spec|
  spec.name = "another_api"
  spec.version = AnotherApi::VERSION
  spec.authors = ["Stephen Ierodiaconou"]
  spec.email = ["stevegeek@gmail.com"]

  spec.summary = "A Rails engine for building opinionated JSON APIs with token auth, policies, and pagination."
  spec.description = "another_api is a Rails engine that wires api_serializer, api_query_language, ActionPolicy, and Dry::Monads into a batteries-included base controller for building versioned JSON APIs."
  spec.homepage = "https://github.com/stevegeek/another_api"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main/another_api"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb"] + ["README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 7.2.0"
  spec.add_dependency "action_policy", ">= 0.7"
  spec.add_dependency "dry-monads", ">= 1.6"
  spec.add_dependency "api_serializer", AnotherApi::VERSION
  spec.add_dependency "api_query_language", AnotherApi::VERSION
  spec.add_dependency "api_query_language-active_record", AnotherApi::VERSION
end
