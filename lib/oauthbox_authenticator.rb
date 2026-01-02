# frozen_string_literal: true

class OauthboxAuthenticator < Auth::ManagedAuthenticator
  def initialize(provider_id)
    @provider_id = provider_id
    @provider = nil
  end

  def name
    "oauthbox_provider_#{@provider_id}"
  end
  
  def provider
    @provider ||= OauthboxProvider.find_by(id: @provider_id)
  end

  def can_revoke?
    provider&.allow_association_change || false
  end

  def can_connect_existing_user?
    provider&.allow_association_change || false
  end

  def register_middleware(omniauth)
    return unless provider
    
    omniauth.provider :oauthbox,
                      name: name,
                      setup:
                        lambda { |env|
                          opts = env["omniauth.strategy"].options
                          opts[:client_id] = provider.client_id
                          opts[:client_secret] = provider.client_secret
                          opts[:provider_ignores_state] = SiteSetting.oauthbox_disable_csrf
                          opts[:callback_user_id_path] = provider.callback_user_id_path
                          opts[:callback_user_info_paths] = provider.callback_user_info_paths
                          opts[:client_options] = {
                            authorize_url: provider.authorize_url,
                            token_url: provider.token_url,
                            token_method: provider.token_url_method.downcase.to_sym,
                          }
                          opts[:authorize_options] = provider
                            .authorize_options
                            .split("|")
                            .map(&:to_sym)

                          if provider.authorize_signup_url.present? &&
                               ActionDispatch::Request.new(env).params["signup"].present?
                            opts[:client_options][
                              :authorize_url
                            ] = provider.authorize_signup_url
                          end

                          if provider.send_auth_header && provider.send_auth_body
                            opts[:client_options][:auth_scheme] = :request_body
                            opts[:token_params] = {
                              headers: {
                                "Authorization" => basic_auth_header,
                              },
                            }
                          elsif provider.send_auth_header
                            opts[:client_options][:auth_scheme] = :basic_auth
                          else
                            opts[:client_options][:auth_scheme] = :request_body
                          end

                          if provider.scope.present?
                            opts[:scope] = provider.scope
                          end

                          opts[:client_options][:connection_build] = lambda do |builder|
                            if SiteSetting.oauthbox_debug_auth && defined?(OauthboxFaradayFormatter)
                              builder.response :logger,
                                               Rails.logger,
                                               { bodies: true, formatter: OauthboxFaradayFormatter }
                            end

                            builder.request :url_encoded
                            builder.adapter FinalDestination::FaradayAdapter
                          end
                        }
  end

  def basic_auth_header
    return "" unless provider
    
    "Basic " +
      Base64.strict_encode64("#{provider.client_id}:#{provider.client_secret}")
  end

  def walk_path(fragment, segments, seg_index = 0)
    first_seg = segments[seg_index]
    return if first_seg.blank? || fragment.blank?
    return nil unless fragment.is_a?(Hash) || fragment.is_a?(Array)
    first_seg = segments[seg_index].scan(/([\d+])/).length > 0 ? first_seg.split("[")[0] : first_seg
    if fragment.is_a?(Hash)
      deref = fragment[first_seg]
    else
      array_index = 0
      if (seg_index > 0)
        last_index = segments[seg_index - 1].scan(/([\d+])/).flatten() || [0]
        array_index = last_index.length > 0 ? last_index[0].to_i : 0
      end
      if fragment.any? && fragment.length >= array_index - 1
        deref = fragment[array_index][first_seg]
      else
        deref = nil
      end
    end

    if deref.blank? || seg_index == segments.size - 1
      deref
    else
      seg_index += 1
      walk_path(deref, segments, seg_index)
    end
  end

  def json_walk(result, user_json, prop, custom_path: nil)
    return unless provider
    
    path = custom_path || provider.send("json_#{prop}_path")
    if path.present?
      path = path.gsub(".[].", ".").gsub(".[", "[")
      segments = parse_segments(path)
      val = walk_path(user_json, segments)
      result[prop] = val.presence || (val == [] ? nil : val)
    end
  end

  def parse_segments(path)
    segments = [+""]
    quoted = false
    escaped = false

    path
      .split("")
      .each do |char|
        next_char_escaped = false
        if !escaped && (char == '"')
          quoted = !quoted
        elsif !escaped && !quoted && (char == ".")
          segments.append +""
        elsif !escaped && (char == '\\')
          next_char_escaped = true
        else
          segments.last << char
        end
        escaped = next_char_escaped
      end

    segments
  end

  def log(info)
    # 使用安全的日志记录方式，避免Rails.logger未初始化导致的错误
    begin
      if SiteSetting.oauthbox_debug_auth
        if defined?(Rails) && Rails.respond_to?(:logger)
          Rails.logger.warn("OAuth2 Debugging: #{info}")
        else
          puts "OAuth2 Debugging: #{info}"
        end
      end
    rescue
      # 忽略所有日志记录错误
    end
  end

  def fetch_user_details(token, id)
    return nil unless provider
    
    user_json_url = provider.user_json_url.sub(":token", token.to_s).sub(":id", id.to_s)
    user_json_method = provider.user_json_url_method.downcase.to_sym

    bearer_token = "Bearer #{token}"
    connection = Faraday.new { |f| f.adapter FinalDestination::FaradayAdapter }
    headers = { "Authorization" => bearer_token, "Accept" => "application/json" }
    user_json_response = connection.run_request(user_json_method, user_json_url, nil, headers)

    log <<-LOG
      user_json request: #{user_json_method} #{user_json_url}

      request headers: #{headers}

      response status: #{user_json_response.status}

      response body:
      #{user_json_response.body}
    LOG

    if user_json_response.status == 200
      user_json = JSON.parse(user_json_response.body)

      log("user_json:\n#{user_json.to_yaml}")

      result = {}
      if user_json.present?
        json_walk(result, user_json, :user_id)
        json_walk(result, user_json, :username)
        json_walk(result, user_json, :name)
        json_walk(result, user_json, :email)
        json_walk(result, user_json, :email_verified)
        json_walk(result, user_json, :avatar)

        DiscoursePluginRegistry.oauthbox_additional_json_paths.each do |detail|
          prop = "extra:#{detail}"
          json_walk(result, user_json, prop, custom_path: detail)
        end
      end
      result
    else
      nil
    end
  end

  def primary_email_verified?(auth)
    return true if provider&.email_verified
    verified = auth["info"]["email_verified"]
    verified = true if verified == "true"
    verified = false if verified == "false"
    verified
  end

  def always_update_user_email?
    provider&.overrides_email || false
  end

  def after_authenticate(auth, existing_account: nil)
    return super(auth, existing_account: existing_account) unless provider
    
    log <<-LOG
      after_authenticate response:

      creds:
      #{auth["credentials"].to_hash.to_yaml}

      uid: #{auth["uid"]}

      info:
      #{auth["info"].to_hash.to_yaml}

      extra:
      #{auth["extra"].to_hash.to_yaml}
    LOG

    if provider.fetch_user_details && provider.user_json_url.present?
      if fetched_user_details = fetch_user_details(auth["credentials"]["token"], auth["uid"])
        auth["uid"] = fetched_user_details[:user_id] if fetched_user_details[:user_id]
        auth["info"]["nickname"] = fetched_user_details[:username] if fetched_user_details[
          :username
        ]
        auth["info"]["image"] = fetched_user_details[:avatar] if fetched_user_details[:avatar]
        %w[name email email_verified].each do |property|
          auth["info"][property] = fetched_user_details[property.to_sym] if fetched_user_details[
            property.to_sym
          ]
        end

        DiscoursePluginRegistry.oauthbox_additional_json_paths.each do |detail|
          auth["extra"][detail] = fetched_user_details["extra:#{detail}"]
        end

        DiscoursePluginRegistry.oauthbox_required_json_paths.each do |x|
          if fetched_user_details[x[:path]] != x[:required_value]
            result = Auth::Result.new
            result.failed = true
            result.failed_reason = x[:error_message]
            return result
          end
        end
      else
        result = Auth::Result.new
        result.failed = true
        result.failed_reason = I18n.t("login.authenticator_error_fetch_user_details")
        return result
      end
    end

    super(auth, existing_account: existing_account)
  end

  def enabled?
    return false unless provider
    provider.enabled == true
  end
end
