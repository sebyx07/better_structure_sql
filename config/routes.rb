# frozen_string_literal: true

BetterStructureSql::Engine.routes.draw do
  resources :schema_versions, only: %i[index show] do
    member do
      get :raw
      get :download
    end
  end

  root to: 'schema_versions#index'
end
