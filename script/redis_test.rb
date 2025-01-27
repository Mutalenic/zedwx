require 'redis'

begin
  redis = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'))

  # Test connection
  puts "Connection test: #{redis.ping == 'PONG' ? 'OK' : 'FAILED'}"

  # Test write/read
  redis.set('test_key', 'test_value')
  result = redis.get('test_key')
  puts "Write/Read test: #{result == 'test_value' ? 'OK' : 'FAILED'}"

  # Test expiration
  redis.setex('expire_key', 1, 'will_expire')
  puts "Expiration test: #{redis.ttl('expire_key') > 0 ? 'OK' : 'FAILED'}"

rescue Redis::CannotConnectError => e
  puts "Connection Error: #{e.message}"
end
