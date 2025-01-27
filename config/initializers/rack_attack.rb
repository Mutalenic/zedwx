class Rack::Attack
  ### Configure Cache ###
  Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(
    url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0')
  )

  ### Throttle Spammy Clients ###
  throttle('requests by ip', limit: 100, period: 15.minutes) do |request|
    request.ip
  end

  # Throttle API endpoints specifically
  throttle('api/weather/ip', limit: 30, period: 15.minutes) do |request|
    request.ip if request.path.start_with?('/api/v1/weather')
  end

  # Block suspicious requests
  blocklist('block suspicious IPs') do |req|
    Rack::Attack::Fail2Ban.filter("pentesters-#{req.ip}", 
      maxretry: 3,
      findtime: 10.minutes,
      bantime: 1.hour
    ) do
      req.path.include?('wp-login') || 
      req.path.include?('xmlrpc.php')
    end
  end

  # Allow trusted IPs (like your monitoring service)
  safelist('allow from localhost') do |req|
    '127.0.0.1' == req.ip || '::1' == req.ip
  end

  ### Custom Throttle Response ###
  self.throttled_response = ->(env) {
    retry_after = (env['rack.attack.match_data'] || {})[:period]
    [
      429,
      {'Content-Type' => 'application/json'},
      [{error: 'Rate limit exceeded', retry_after: retry_after}.to_json]
    ]
  }
end