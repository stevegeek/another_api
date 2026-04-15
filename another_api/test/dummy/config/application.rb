# frozen_string_literal: true

require_relative "boot"

require "active_record/railtie"
require "action_controller/railtie"

require "another_api"

module Dummy
  class Application < ::Rails::Application
    # Pin root to the dummy app directory — otherwise Rails picks up a
    # surrounding host app's config/environments/test.rb at startup.
    config.root = File.expand_path("..", __dir__)
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false
    config.consider_all_requests_local = true
    config.cache_classes = false
    config.active_support.deprecation = :stderr
    config.secret_key_base = "test_secret_key_base_for_another_api_dummy_app"
    config.api_only = true
    config.hosts.clear if config.respond_to?(:hosts)
    config.logger = Logger.new(IO::NULL)
  end
end
