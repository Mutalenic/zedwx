class OpenMeteoService
  include CacheService
  
  BASE_URL = "https://api.open-meteo.com/v1/forecast"
  
  def self.get_current_weather(location)
    return nil unless LocationValidator.valid_location?(location)
    
    Rails.cache.fetch("weather/#{location}", expires_in: 30.minutes) do
      coordinates = LocationValidator.get_coordinates(location)
      fetch_weather_data(coordinates)
    end
  end
  
  private
  
  def self.fetch_weather_data(coordinates)
    uri = URI("#{BASE_URL}?latitude=#{coordinates[:lat]}&longitude=#{coordinates[:lon]}&current_weather=true")
    response = Net::HTTP.get_response(uri)
    JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)
  end
end