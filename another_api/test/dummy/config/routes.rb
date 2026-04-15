# frozen_string_literal: true

Rails.application.routes.draw do
  scope "/api/test" do
    resources :widgets, only: [:index, :show, :create, :update, :destroy], controller: "test/widgets"
    resources :posts, only: [:index, :show, :create], controller: "test/posts" do
      collection { get :defaults_index }
    end
  end
end
