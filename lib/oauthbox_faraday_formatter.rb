# frozen_string_literal: true

require "faraday/logging/formatter"

class OauthboxFaradayFormatter < Faraday::Logging::Formatter
  def request(env)
    warn <<~LOG
      Oauthbox Debugging: request #{env.method.upcase} #{env.url}

      Headers:
      #{env.request_headers.to_yaml}

      Body:
      #{env[:body].to_yaml}
    LOG
  end

  def response(env)
    warn <<~LOG
      Oauthbox Debugging: response status #{env.status}

      From #{env.method.upcase} #{env.url}

      Headers:
      #{env.request_headers.to_yaml}

      Body:
      #{env[:body].to_yaml}
    LOG
  end
end
