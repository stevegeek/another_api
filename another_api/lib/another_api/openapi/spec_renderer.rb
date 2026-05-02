# frozen_string_literal: true

require "json"

module AnotherApi
  module OpenAPI
    # Renders the full OpenAPI specification and caches the result.
    #
    # In production the spec is computed once and cached for the lifetime of
    # the process. In development it is recomputed when any file under
    # configuration.watched_dirs changes (mtime-based check).
    class SpecRenderer
      class << self
        # @return [String] JSON string of the OpenAPI spec
        def render_json(configuration: AnotherApi::OpenAPI.configuration)
          refresh_cache(configuration) unless cache_valid?(configuration)
          @cached_json
        end

        # @return [Hash] the raw OpenAPI spec hash
        def render_hash(configuration: AnotherApi::OpenAPI.configuration)
          refresh_cache(configuration) unless cache_valid?(configuration)
          @cached_hash
        end

        # Force a cache reset (useful in tests or after deploy).
        def reset!
          @cached_json = nil
          @cached_hash = nil
          @cached_at = nil
          @last_mtime = nil
        end

        private

        def refresh_cache(configuration)
          @cached_hash = AnotherApi::OpenAPI::Generator.generate(configuration: configuration)
          @cached_json = JSON.pretty_generate(@cached_hash)
          @cached_at = Time.now
          @last_mtime = current_max_mtime(configuration)
        end

        def cache_valid?(configuration)
          return false if @cached_json.nil?
          return true if defined?(Rails) && Rails.env.production?

          current_max_mtime(configuration) == @last_mtime
        end

        def current_max_mtime(configuration)
          max = Time.at(0)
          base = (defined?(Rails) && Rails.respond_to?(:root)) ? Rails.root : Pathname.new(Dir.pwd)

          configuration.watched_dirs.each do |dir|
            full = base.join(dir)
            next unless full.exist?

            Dir.glob(full.join("**/*.rb")).each do |f|
              mtime = File.mtime(f)
              max = mtime if mtime > max
            end
          end
          max
        end
      end
    end
  end
end
