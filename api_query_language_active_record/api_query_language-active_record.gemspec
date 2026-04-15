# frozen_string_literal: true

require_relative "lib/api_query_language/active_record/version"

Gem::Specification.new do |spec|
  spec.name = "api_query_language-active_record"
  spec.version = ApiQueryLanguage::ActiveRecord::VERSION
  spec.authors = ["Stephen Ierodiaconou"]
  spec.email = ["stevegeek@gmail.com"]

  spec.summary = "ActiveRecord backend for api_query_language — applies parsed filter/sort expressions to AR relations."
  spec.description = "Consumes the ApiQueryLanguage AST and produces ActiveRecord/Arel queries. Provides ApiQueryLanguage::ActiveRecord::FilterExpression and SortExpression, both of which respond to #apply_to(relation)."
  spec.homepage = "https://github.com/stevegeek/another_api"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main/api_query_language_active_record"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb"] + ["README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "api_query_language", ApiQueryLanguage::ActiveRecord::VERSION
  spec.add_dependency "activerecord", ">= 7.2.0"
end
