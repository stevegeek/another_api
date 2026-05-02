# frozen_string_literal: true

# Reference configuration for the dummy app's OpenAPI generation. The
# integration test re-applies these settings in its own setup so they
# are robust to other tests that call `reset_configuration!`.
AnotherApi::OpenAPI.configure do |c|
  c.title = "Dummy API"
  c.version = "0.1"
  c.description = "Reference dummy app demonstrating AnotherApi::OpenAPI."
  c.path_prefix = "/api/test"

  # The dummy controllers live under test/dummy/app/controllers/test/.
  c.controllers_glob = "app/controllers/test/*_controller.rb"

  # The dummy schemas live under CoreSchemas::V2::*.
  c.schema_namespace_prefix = "CoreSchemas::V2::"
  c.default_variant_name = :default
  c.additional_discovery_variants = [:default]
end
