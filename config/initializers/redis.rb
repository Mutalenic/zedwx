require 'redis'

begin
  $redis = Redis.new(
    host: ENV.fetch('REDIS_HOST', 'localhost'),
    port: ENV.fetch('REDIS_PORT', '6379')
  )
  $redis.ping
  Rails.logger.info "Connected to Redis"
rescue Redis::CannotConnectError => e
  Rails.logger.error "Failed to connect to Redis: #{e.message}"
end