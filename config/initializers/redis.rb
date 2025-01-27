require 'redis'

REDIS_CONFIG = {
  host: ENV.fetch('REDIS_HOST', 'localhost'),
  port: ENV.fetch('REDIS_PORT', '6379'),
  db: ENV.fetch('REDIS_DB', '0')
}

$redis = Redis.new(REDIS_CONFIG)