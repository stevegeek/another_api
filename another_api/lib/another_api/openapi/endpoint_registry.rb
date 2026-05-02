# frozen_string_literal: true

module AnotherApi
  module OpenAPI
    # Global registry of API endpoint metadata declared by controllers via the
    # EndpointMetadata DSL. The Generator reads this instead of a hardcoded list.
    #
    # Thread-safe for reads after boot (writes happen at class-load time only).
    class EndpointRegistry
      Entry = Data.define(
        :controller_class,
        :action,
        :summary,
        :tags,
        :schema_lambda,
        :description,
        :custom_path,
        :custom_verb,
        :custom_operation_id,
        :custom_query_params
      ) do
        def initialize(custom_query_params: nil, **)
          super
        end
      end

      class << self
        def register(entry)
          entries << entry
        end

        def all
          entries.dup.freeze
        end

        def clear!
          entries.clear
        end

        def resolved_endpoints(configuration: AnotherApi::OpenAPI.configuration)
          all.map { |entry| resolve(entry, configuration) }.compact
        end

        # Extract the short class name from a schema class, stripping any
        # configured namespace prefix and collapsing remaining module
        # segments so that sibling namespaces produce distinct schema names.
        #
        # With prefix "MyApp::Schemas::V1::" set:
        #   MyApp::Schemas::V1::User           => "User"
        #   MyApp::Schemas::V1::Seller::Cart   => "SellerCart"
        #   MyApp::Schemas::V1::Buyer::Cart    => "BuyerCart"
        #
        # With prefix unset, falls back to demodulize.
        def schema_short_name(schema, configuration: AnotherApi::OpenAPI.configuration)
          klass = schema.is_a?(Class) ? schema : schema.class
          full_name = klass.name
          return nil unless full_name

          prefix = configuration.schema_namespace_prefix
          if prefix && !prefix.empty? && (suffix = full_name.delete_prefix(prefix)) != full_name
            suffix.delete("::")
          else
            full_name.demodulize
          end
        end

        private

        def entries
          @entries ||= []
        end

        def resolve(entry, configuration)
          route_info = find_route_for(entry, configuration)
          return nil unless route_info || entry.custom_path

          path = entry.custom_path || route_info[:path]
          verb = entry.custom_verb || route_info[:verb]

          {
            path: path,
            verb: verb,
            action: entry.action.to_s,
            operation_id: entry.custom_operation_id || build_operation_id(entry, path),
            tags: entry.tags,
            summary: entry.summary,
            schema_ref: resolve_schema_ref(entry, configuration),
            concerns: detect_concerns(entry.controller_class, configuration),
            description: entry.description,
            custom_query_params: entry.custom_query_params
          }
        end

        def find_route_for(entry, configuration)
          controller_path = entry.controller_class.controller_path
          action = entry.action.to_s

          route = Rails.application.routes.routes.detect do |r|
            defaults = r.defaults
            defaults[:controller] == controller_path && defaults[:action] == action
          end

          return nil unless route

          full_path = route.path.spec.to_s.sub("(.:format)", "")
          relative_path = configuration.path_prefix.to_s.empty? ? full_path : full_path.delete_prefix(configuration.path_prefix)

          {
            path: relative_path,
            verb: (route.verb.downcase if route.verb.present?) || verb_for_action(action)
          }
        end

        def verb_for_action(action)
          case action
          when "index", "show" then "get"
          when "create" then "post"
          when "update" then "patch"
          when "destroy" then "delete"
          else "get"
          end
        end

        def build_operation_id(entry, path)
          action = entry.action.to_s
          resource = path.gsub(%r{/:?\w+_id|/:id}, "")
            .tr("-", "_")
            .delete_prefix("/")
            .tr("/", "_")

          "#{action}_#{resource}"
        end

        def resolve_schema_ref(entry, configuration)
          return nil unless entry.schema_lambda

          schema = entry.schema_lambda.call
          return nil unless schema

          name = schema_short_name(schema, configuration: configuration)
          "#{name}Full" if name
        end

        def detect_concerns(controller_class, configuration)
          map = configuration.concern_map
          controller_class.ancestors.each_with_object([]) do |ancestor, concerns|
            key = ancestor.name
            concerns << map[key] if map.key?(key)
          end
        end
      end
    end
  end
end
