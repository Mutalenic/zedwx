require 'redis'
require 'logger'

logger = Logger.new(STDOUT)

begin
  redis_url = ENV.fetch('REDIS_URL', 'redis://localhost:6379/0')
  logger.info "Connecting to Redis at #{redis_url}"

  redis = Redis.new(url: redis_url)

  # Connection test
  response = redis.ping
  logger.info "Connection test: #{response == 'PONG' ? 'OK' : 'FAILED'}"

  # Write/Read test
  redis.set('test_key', 'test_value')
  result = redis.get('test_key')
  logger.info "Write/Read test: #{result == 'test_value' ? 'OK' : 'FAILED'}"

  # Expiration test
  redis.setex('expire_key', 5, 'will_expire')
  ttl = redis.ttl('expire_key')
  logger.info "Expiration test: TTL = #{ttl} seconds"

  # Cache store test
  redis.flushdb
  logger.info "Cache cleared"

rescue Redis::CannotConnectError => e
  logger.error "Connection Error: #{e.message}"
rescue => e
  logger.error "Unexpected Error: #{e.class} - #{e.message}"
end
