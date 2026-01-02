# frozen_string_literal: true

class CreateOauthboxProviders < ActiveRecord::Migration[6.0]
  def up
    unless table_exists?(:oauthbox_providers)
      create_table :oauthbox_providers do |t|
        t.string   :name,               null: false
        t.string   :button_title,       null: false, default: "OauthBox登录点"
        t.string   :client_id,          null: false
        t.string   :client_secret,      null: false
        t.string   :authorize_url,      null: false
        t.string   :token_url,          null: false
        t.string   :token_url_method,   null: false, default: "POST"
        t.string   :user_json_url,      null: false
        t.string   :user_json_url_method, null: false, default: "GET"
        t.string   :scope,              null: true
        t.string   :authorize_options,  null: true
        t.string   :authorize_signup_url, null: true
        t.boolean  :send_auth_header,   null: false, default: true
        t.boolean  :send_auth_body,     null: false, default: true
        t.boolean  :email_verified,     null: false, default: false
        t.boolean  :overrides_email,   null: false, default: false
        t.boolean  :allow_association_change, null: false, default: false
        t.string   :callback_user_id_path, null: false
        t.string   :callback_user_info_paths, null: true, default: "id"
        t.boolean  :fetch_user_details, null: false, default: true
        t.string   :json_user_id_path, null: false
        t.string   :json_username_path, null: true
        t.string   :json_name_path,    null: true
        t.string   :json_email_path,   null: true
        t.string   :json_email_verified_path, null: true
        t.string   :json_avatar_path,   null: true
        t.boolean  :enabled,            null: false, default: true
        t.integer  :position,           null: false, default: 0
        t.timestamps null: false
      end

      add_index :oauthbox_providers, :enabled, name: "idx_oauthbox_providers_enabled"
      add_index :oauthbox_providers, :position, name: "idx_oauthbox_providers_position"
    end
  end

  def down
    drop_table :oauthbox_providers if table_exists?(:oauthbox_providers)
  end
end
