# frozen_string_literal: true

class MoveOauthboxToManagedAuthenticator < ActiveRecord::Migration[5.2]
  def up
    execute <<~SQL
    INSERT INTO user_associated_accounts (
      provider_name,
      provider_uid,
      user_id,
      created_at,
      updated_at
    ) SELECT
      'oauthbox',
      replace(key, 'oauthbox_user_', ''),
      (value::json->>'user_id')::integer,
      CURRENT_TIMESTAMP,
      CURRENT_TIMESTAMP
    FROM plugin_store_rows
    WHERE plugin_name = 'oauthbox'
    AND value::json->>'user_id' ~ '^[0-9]+$'
    ON CONFLICT (provider_name, user_id)
    DO NOTHING
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
