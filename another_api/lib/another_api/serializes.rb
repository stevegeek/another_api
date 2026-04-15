module AnotherApi
  module Serializes
    extend ActiveSupport::Concern

    class_methods do
      def serialization(api_version: 2, schemas_namespace: nil, model_name: nil)
        schema_name = "#{schemas_namespace || "::CoreSchemas"}::V#{api_version}::#{model_name || name}"
        schema_klass = schema_name.safe_constantize
        raise NameError, "No schema defined for #{name} at '#{schema_name}'" unless schema_klass
        schema_klass
      end
    end

    def serialization(api_version: 2, context: {}, schemas_namespace: nil, model_name: nil)
      ApiSerializer::SerializationContextWrapper.new(self, self.class.serialization(api_version:, schemas_namespace:, model_name:), context)
    end
  end
end
