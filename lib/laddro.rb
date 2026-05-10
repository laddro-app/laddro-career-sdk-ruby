require_relative "laddro/client"
require_relative "laddro/error"

module Laddro
  def self.new(api_key = nil, base_url: "https://api.laddro.com")
    Client.new(api_key, base_url: base_url)
  end
end
