# frozen_string_literal: true

module ::OauthboxPluginModule
  class OauthboxController < ::ApplicationController
    requires_plugin "oauthbox"

    before_action :ensure_admin
    before_action :set_provider, only: %i[show update destroy]

    def manager
      render "default/empty"
    rescue => e
      Rails.logger.error "OAuth2 Manager页面错误: #{e.message}"
      render plain: "Error: #{e.message}", status: 500
    end

    def index
      providers = OauthboxProvider.order(:position)
      render_json_dump(providers: providers.as_json(only: [:id, :name, :button_title, :client_id, :authorize_url, :token_url, :token_url_method, :user_json_url, :user_json_url_method, :scope, :authorize_options, :authorize_signup_url, :send_auth_header, :send_auth_body, :email_verified, :overrides_email, :allow_association_change, :callback_user_id_path, :callback_user_info_paths, :fetch_user_details, :json_user_id_path, :json_username_path, :json_name_path, :json_email_path, :json_email_verified_path, :json_avatar_path, :enabled, :position]))
    end

    def show
      render_json_dump(provider: @provider.as_json(only: [:id, :name, :button_title, :client_id, :authorize_url, :token_url, :token_url_method, :user_json_url, :user_json_url_method, :scope, :authorize_options, :authorize_signup_url, :send_auth_header, :send_auth_body, :email_verified, :overrides_email, :allow_association_change, :callback_user_id_path, :callback_user_info_paths, :fetch_user_details, :json_user_id_path, :json_username_path, :json_name_path, :json_email_path, :json_email_verified_path, :json_avatar_path, :enabled, :position]))
    end

    def create
      begin
        provider = OauthboxProvider.new(provider_params)

        if provider.save
          render json: success_json.merge(provider: provider.as_json(only: [:id, :name, :button_title, :client_id, :authorize_url, :token_url, :token_url_method, :user_json_url, :user_json_url_method, :scope, :authorize_options, :authorize_signup_url, :send_auth_header, :send_auth_body, :email_verified, :overrides_email, :allow_association_change, :callback_user_id_path, :callback_user_info_paths, :fetch_user_details, :json_user_id_path, :json_username_path, :json_name_path, :json_email_path, :json_email_verified_path, :json_avatar_path, :enabled, :position]))
        else
          render json: failed_json.merge(errors: provider.errors.full_messages), status: :unprocessable_entity
        end
      rescue => e
        Rails.logger.error "创建OAuth2提供商失败: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        render json: failed_json.merge(errors: ["创建OAuth2提供商失败: #{e.message}"]), status: :internal_server_error
      end
    end

    def update
      begin
        if @provider.update(provider_params)
          render json: success_json.merge(provider: @provider.as_json(only: [:id, :name, :button_title, :client_id, :authorize_url, :token_url, :token_url_method, :user_json_url, :user_json_url_method, :scope, :authorize_options, :authorize_signup_url, :send_auth_header, :send_auth_body, :email_verified, :overrides_email, :allow_association_change, :callback_user_id_path, :callback_user_info_paths, :fetch_user_details, :json_user_id_path, :json_username_path, :json_name_path, :json_email_path, :json_email_verified_path, :json_avatar_path, :enabled, :position]))
        else
          render json: failed_json.merge(errors: @provider.errors.full_messages), status: :unprocessable_entity
        end
      rescue => e
        Rails.logger.error "更新OAuth2提供商失败: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        render json: failed_json.merge(errors: ["更新OAuth2提供商失败: #{e.message}"]), status: :internal_server_error
      end
    end

    def destroy
      begin
        if @provider.destroy
          render json: success_json
        else
          render json: failed_json.merge(errors: @provider.errors.full_messages), status: :unprocessable_entity
        end
      rescue => e
        Rails.logger.error "删除OAuth2提供商失败: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        render json: failed_json.merge(errors: ["删除OAuth2提供商失败: #{e.message}"]), status: :internal_server_error
      end
    end

    private

    def set_provider
      begin
        @provider = OauthboxProvider.find(params[:id])
      rescue ActiveRecord::RecordNotFound => e
        render json: failed_json.merge(errors: ["OAuth2提供商不存在"]), status: :not_found
      rescue => e
        Rails.logger.error "查找OAuth2提供商失败: #{e.message}"
        render json: failed_json.merge(errors: ["查找OAuth2提供商失败: #{e.message}"]), status: :internal_server_error
      end
    end

    def provider_params
      params.require(:provider).permit(
        :name,
        :button_title,
        :client_id,
        :client_secret,
        :authorize_url,
        :token_url,
        :token_url_method,
        :user_json_url,
        :user_json_url_method,
        :scope,
        :authorize_options,
        :authorize_signup_url,
        :send_auth_header,
        :send_auth_body,
        :email_verified,
        :overrides_email,
        :allow_association_change,
        :callback_user_id_path,
        :callback_user_info_paths,
        :fetch_user_details,
        :json_user_id_path,
        :json_username_path,
        :json_name_path,
        :json_email_path,
        :json_email_verified_path,
        :json_avatar_path,
        :enabled,
        :position
      )
    end
  end
end