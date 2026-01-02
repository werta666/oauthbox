# frozen_string_literal: true

class OmniAuth::Strategies::Oauthbox < ::OmniAuth::Strategies::OAuth2
  option :name, "oauthbox"

  uid do
    if path = options[:callback_user_id_path]
      path_segments = path.split(".")
      recurse(access_token, [*path_segments]) if path_segments.present?
    end
  end

  info do
    if paths = options[:callback_user_info_paths]
      paths_array = paths.split("|")
      result = Hash.new
      paths_array.each do |p|
        segments = p.split(":")
        if segments.length == 2
          key = segments.first
          path = [*segments.last.split(".")]
          result[key] = recurse(access_token, path)
        end
      end
      result
    end
  end

  def callback_url
    Discourse.base_url_no_prefix + script_name + callback_path
  end

  def recurse(obj, keys)
    return nil if !obj
    k = keys.shift
    result = obj.respond_to?(k) ? obj.send(k) : obj[k]
    keys.empty? ? result : recurse(result, keys)
  end
end
