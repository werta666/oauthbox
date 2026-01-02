# frozen_string_literal: true

class AllowNullCallbackPaths < ActiveRecord::Migration[6.0]
  def up
    change_column_null :oauthbox_providers, :callback_user_id_path, true
    change_column_null :oauthbox_providers, :json_user_id_path, true
  end

  def down
    change_column_null :oauthbox_providers, :callback_user_id_path, false
    change_column_null :oauthbox_providers, :json_user_id_path, false
  end
end
