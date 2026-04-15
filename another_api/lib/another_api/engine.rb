# frozen_string_literal: true

require "rails/engine"

module AnotherApi
  class Engine < ::Rails::Engine
    isolate_namespace AnotherApi
  end
end
