require "redis"

begin
  $redis = Redis.new(
    url: ENV.fetch("REDIS_URL"),
    ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
  )
  $redis.ping
rescue Redis::CannotConnectError => e
  Rails.logger.error "Failed to connect to Redis: #{e.message}"
  $redis = nil
end
