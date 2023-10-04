require './webhook.rb'
require 'logger'
$logger = Logger.new(STDOUT)
$logger.level = Logger::DEBUG

$JOIN_RE = /\[JOIN\] (.*) joined the game$/
$LEAVE_RE = /\[LEAVE\] (.*) left the game$/

def send_factorio_notification(endpoint, is_join, player_name)
  content = is_join ? "#{player_name} が Factorio サーバーに参加しました" : "#{player_name} が Factorio サーバーから退出しました"

  begin
    send_discord_webhook(endpoint, content)
  rescue HTTPError, HTTPRetriableError, HTTPServerException, HTTPFatalError => e
    $logger.error("Failed to send Discord webhook: #{e}")
  end
end

def watch_factorio(factorio_path, factorio_args, endpoint)
  io = IO.popen([factorio_path, *factorio_args, :pgroup => 0], mode: 'r')
  $logger.info("Process started")

  # spawn stdout reader thread
  t = Thread.new do
    $logger.debug("Reader thread started")
    while (line = io.gets)
      puts line
    end
  end

  pid = io.pid

  Signal.trap("INT", Proc.new do
    Process.kill("INT", pid)
  end)

  # wait for process termination
  $logger.debug("Watcher process is waiting for process termination")
  Process.wait pid
  $logger.debug("Watcher process is waiting for reader thread termination")
  t.join
  $logger.debug("Watcher process is terminating")
end


# Get arguments
args = ARGV
if args.length < 3
  puts "Usage: #{$PROGRAM_NAME} <factorio_path> <endpoint> <factorio_args>"
  return
end

factorio_path = args[0]
endpoint = args[1]
factorio_args = args[2..-1]
$logger.debug("factorio_path: #{factorio_path}")
$logger.debug("endpoint: #{endpoint}")
$logger.debug("factorio_args: #{factorio_args}")
watch_factorio(factorio_path, factorio_args, endpoint)
