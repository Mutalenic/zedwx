module CacheService
  def self.fetch_or_store(key, expires_in: 30.minutes)
    Rails.cache.fetch(key, expires_in: expires_in) do
      yield
    end
  end
end