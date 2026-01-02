# frozen_string_literal: true

OauthboxPluginModule::Engine.routes.draw do
  get "/manager" => "oauthbox#manager"
  get "/admin" => "oauthbox#index"
  post "/admin" => "oauthbox#create"
  get "/admin/:id" => "oauthbox#show"
  put "/admin/:id" => "oauthbox#update"
  delete "/admin/:id" => "oauthbox#destroy"
end