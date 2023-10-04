# frozen_string_literal: true

require "json"
require "net/http"

# rubocop:disable Metrics/MethodLength
def send_discord_webhook(endpoint, message)
  uri = URI.parse(endpoint)
  payload = {
    content: message,
    username: "FactorioWatch"
  }
  # json encode

  req = Net::HTTP::Post.new(uri.path)
  req["Content-Type"] = "application/json"
  req.body = payload.to_json
  res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
    http.request(req).body
  end

  res.value
end
# rubocop:enable Metrics/MethodLength
