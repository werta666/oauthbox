# frozen_string_literal: true

require "rails_helper"

describe "Oauthbox Overrides Email", type: :request do
  fab!(:initial_email) { "initial@example.com" }
  fab!(:new_email) { "new@example.com" }
  fab!(:user) { Fabricate(:user, email: initial_email) }
  fab!(:uac) do
    UserAssociatedAccount.create!(user: user, provider_name: "oauthbox", provider_uid: "12345")
  end

  before do
    SiteSetting.oauthbox_enabled = true
    SiteSetting.oauthbox_callback_user_id_path = "uid"
    SiteSetting.oauthbox_fetch_user_details = false
    SiteSetting.oauthbox_email_verified = true

    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:oauthbox] = OmniAuth::AuthHash.new(
      provider: "oauthbox",
      uid: "12345",
      info: OmniAuth::AuthHash::InfoHash.new(email: new_email),
      extra: {
        raw_info: OmniAuth::AuthHash.new(email_verified: true),
      },
      credentials: OmniAuth::AuthHash.new,
    )
  end

  it "doesn't update email by default" do
    expect(user.reload.email).to eq(initial_email)

    get "/auth/oauthbox/callback"
    expect(response.status).to eq(302)
    expect(session[:current_user_id]).to eq(user.id)

    expect(user.reload.email).to eq(initial_email)
  end

  it "updates user email if enabled" do
    SiteSetting.oauthbox_overrides_email = true

    get "/auth/oauthbox/callback"
    expect(response.status).to eq(302)
    expect(session[:current_user_id]).to eq(user.id)

    expect(user.reload.email).to eq(new_email)
  end
end
