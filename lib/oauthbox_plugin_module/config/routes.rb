# frozen_string_literal: true

OauthboxPluginModule::Engine.routes.draw do
  get "/manager" => "oauthbox#manager"
  scope "/admin", constraints: AdminConstraint.new do
    get "/" => "oauthbox#index"
    post "/" => "oauthbox#create"
    get "/:id" => "oauthbox#show"
    put "/:id" => "oauthbox#update"
    delete "/:id" => "oauthbox#destroy"
  end
end
