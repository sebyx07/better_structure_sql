# frozen_string_literal: true

BetterStructureSql::Engine.routes.draw do
  resources :schema_versions, only: [:index, :show] do
    member do
      get :raw
    end
  end

  root to: 'schema_versions#index'
end
