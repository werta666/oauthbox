# frozen_string_literal: true

class OauthboxAuthenticatorProxy < Auth::ManagedAuthenticator
  def name
    "oauthbox_proxy"
  end

  def enabled?
    # 代理本身不显示为按钮，所以返回false
    false
  end

  def authenticators
    # 动态返回所有启用的提供商认证器
    authenticators = []
    
    begin
      if ActiveRecord::Base.connection.table_exists?(:oauthbox_providers)
        OauthboxProvider.where(enabled: true).order(:position).each do |provider|
          authenticators << OauthboxAuthenticator.new(provider.id)
        end
      end
    rescue => e
      # 使用安全的日志记录方式，避免Rails.logger未初始化导致的错误
      begin
        if defined?(Rails) && Rails.respond_to?(:logger)
          Rails.logger.error("OAuthbox: Error loading oauthbox providers: #{e.message}")
        else
          puts "OAuthbox: Error loading oauthbox providers: #{e.message}"
        end
      rescue
        # 忽略所有日志记录错误
      end
    end
    
    authenticators
  end

  def register_middleware(omniauth)
    # 每个实际的认证器会自己注册中间件
  end
end
