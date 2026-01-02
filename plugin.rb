# frozen_string_literal: true

# name: oauthbox
# about: 一款提供多OAuth2 box登录插件
# meta_topic_id: todo
# version: 1.0
# authors: pandacc
# url: https://github.com/werta666/oauthbox

PLUGIN_NAME ||= "oauthbox".freeze

enabled_site_setting :oauthbox_enabled

register_asset "stylesheets/oauthbox.scss"

require_relative "lib/omniauth/strategies/oauthbox"
require_relative "lib/oauthbox_faraday_formatter"
require_relative "lib/oauthbox_provider"
require_relative "lib/oauthbox_authenticator"
require_relative "lib/oauthbox_authenticator_proxy"
require_relative "lib/oauthbox_plugin_module/engine"

# You should use this register if you want to add custom paths to traverse the user details JSON.
# We'll store the value in the user associated account's extra attribute hash using the full path as the key.
DiscoursePluginRegistry.define_filtered_register :oauthbox_additional_json_paths

# After authentication, we'll use this to confirm that the registered json paths are fulfilled, or display an error.
# This requires SiteSetting.oauthbox_fetch_user_details? to be true, and can be used with
# DiscoursePluginRegistry.oauthbox_additional_json_paths.
#
# Example usage:
# DiscoursePluginRegistry.register_oauthbox_required_json_path({
#   path: "extra:data.is_allowed_user",
#   required_value: true,
#   error_message: I18n.t("auth.user_not_allowed")
# }, self)

DiscoursePluginRegistry.define_filtered_register :oauthbox_required_json_paths

# 在插件激活阶段不直接访问数据库，避免导致错误
# 所有认证器注册都移到after_initialize阶段处理


after_initialize do
  Discourse::Application.routes.append do
    mount ::OauthboxPluginModule::Engine, at: "/oauthbox"
  end

  begin
    if ActiveRecord::Base.connection.table_exists?(:oauthbox_providers)
      begin
        providers = OauthboxProvider.where(enabled: true).order(:position).to_a
        providers.each do |provider|
          auth_provider(
            title: provider.button_title.present? ? provider.button_title : "OAuth Provider",
            authenticator: OauthboxAuthenticator.new(provider.id)
          )
        end
        Rails.logger.info("OAuthbox: 成功注册 #{providers.length} 个OAuth提供商认证器")
      rescue => e
        Rails.logger.error("OAuthbox: 加载提供商认证器失败: #{e.message}")
      end
    else
      Rails.logger.warn("OAuthbox: oauthbox_providers表不存在，按钮将无法显示。请确保已运行数据库迁移。")
    end
  rescue => e
    Rails.logger.error("OAuthbox: after_initialize阶段错误: #{e.message}")
  end
end
