# frozen_string_literal

class OauthboxProvider < ActiveRecord::Base
  self.table_name = "oauthbox_providers"

  validates :name, presence: true
  validates :button_title, presence: true
  validates :client_id, presence: true
  validates :client_secret, presence: true
  validates :authorize_url, presence: true
  validates :token_url, presence: true
  validates :token_url_method, presence: true, inclusion: { in: %w[GET POST PUT], message: "must be GET, POST, or PUT" }
  validates :user_json_url, presence: true
  validates :user_json_url_method, presence: true, inclusion: { in: %w[GET POST], message: "must be GET or POST" }
  validates :callback_user_id_path, presence: true
  validates :json_user_id_path, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
