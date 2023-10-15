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
    http.request(req)
  end

  res.value
end
# rubocop:enable Metrics/MethodLength

def send_gw_check(gw_endpoint, is_join, player_name)
  uri = URI.parse(gw_endpoint)
  payload = {
    in_game_name: player_name,
    is_join: is_join,
    time: Time.now.iso8601,
    game_name: "Factorio"
  }
  # json encode

  req = Net::HTTP::Post.new(uri.path)
  req["Content-Type"] = "application/json"
  req.body = payload.to_json
  res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
    http.request(req)
  end

  res.value
end
# rubocop:enable Metrics/MethodLength
