# frozen_string_literal: true

require_relative "lib/api_serializer/version"

Gem::Specification.new do |spec|
  spec.name = "api_serializer"
  spec.version = ApiSerializer::VERSION
  spec.authors = ["Stephen Ierodiaconou"]
  spec.email = ["stevegeek@gmail.com"]

  spec.summary = "A declarative DSL for serializing Ruby objects to JSON with typed, versioned schemas."
  spec.description = "api_serializer provides a Schema and Serializer DSL for describing how Ruby objects are exposed over a JSON API, including variants, optional fields, composition, and nested object references. Zero ActiveSupport dependency."
  spec.homepage = "https://github.com/stevegeek/another_api"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main/api_serializer"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb"] + ["README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "literal", "~> 1.6"
end
