# frozen_string_literal: true

require_relative "webhook"
require "logger"
require "net/http"
require_relative "factorio_watch/version"

# This module provides functionality for watching a Factorio server and sending notifications to a Discord webhook
# when players join or leave.
module FactorioWatch
  class Error < StandardError; end
  # Your code goes here...

  MyLogger = Logger.new($stdout)
  MyLogger.level = Logger::DEBUG

  JOIN_RE = /\[JOIN\] (.*) joined the game$/.freeze
  LEAVE_RE = /\[LEAVE\] (.*) left the game$/.freeze

  def send_factorio_notification(endpoint, is_join, player_name)
    content = is_join ? "#{player_name} が Factorio サーバーに参加しました" : "#{player_name} が Factorio サーバーから退出しました"

    begin
      send_discord_webhook(endpoint, content)
      MyLogger.info("send_factorio_notification success: player=#{player_name}, is_join=#{is_join}")
    rescue Net::HTTPExceptions => e
      MyLogger.error("Failed to send Discord webhook: #{e}")
    end
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def watch_factorio(factorio_path, factorio_args, endpoint)
    io = IO.popen([factorio_path, *factorio_args, { pgroup: 0 }], mode: "r")
    MyLogger.info("Process started")

    # spawn stdout reader thread
    t = Thread.new do
      MyLogger.debug("Reader thread started")
      while (line = io.gets)
        puts line
        # check for player join/leave
        checks = [
          [JOIN_RE, true],
          [LEAVE_RE, false]
        ]
        checks.each do |re, is_join|
          match = re.match(line)
          next if match.nil?

          player_name = match.captures[0]
          send_factorio_notification(endpoint, is_join, player_name)
          break
        end
      end
    end

    pid = io.pid

    Signal.trap("INT", proc do
      Process.kill("INT", pid)
    end)

    # wait for process termination
    MyLogger.debug("Watcher process is waiting for process termination")
    Process.wait pid
    MyLogger.debug("Watcher process is waiting for reader thread termination")
    t.join
    MyLogger.debug("Watcher process is terminating")
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize

  module_function :watch_factorio, :send_factorio_notification
end
