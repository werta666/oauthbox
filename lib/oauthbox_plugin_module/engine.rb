# frozen_string_literal: true

module ::OauthboxPluginModule
  class Engine < ::Rails::Engine
    engine_name "oauthbox"
    isolate_namespace OauthboxPluginModule

    config.autoload_paths << File.join(config.root, "lib")
  end
end
