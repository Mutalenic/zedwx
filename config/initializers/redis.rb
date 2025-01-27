require "redis"

begin
  redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")
  $redis = Redis.new(
    url: redis_url,
    ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
  )
  $redis.ping
rescue Redis::CannotConnectError => e
  Rails.logger.error "Failed to connect to Redis: #{e.message}"
  $redis = nil
end
