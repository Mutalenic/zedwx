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

  BASE_URL_HISTORICAL = "https://archive-api.open-meteo.com/v1/archive"

  def self.get_historical_weather(location, start_date, end_date)
    coordinates = LocationValidator.get_coordinates(location)
    return nil unless coordinates

    Rails.cache.fetch("weather/historical/#{location}/#{start_date}/#{end_date}", expires_in: 12.hours) do
      fetch_historical_data(coordinates, start_date, end_date)
    end
  end
  
  private
  
  def self.fetch_weather_data(coordinates)
    uri = URI("#{BASE_URL}?latitude=#{coordinates[:lat]}&longitude=#{coordinates[:lon]}&current_weather=true")
    response = Net::HTTP.get_response(uri)
    JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)
  end

  def self.fetch_historical_data(coordinates, start_date, end_date)
    uri = URI(BASE_URL_HISTORICAL)
    uri.query = URI.encode_www_form({
      latitude: coordinates[:lat],
      longitude: coordinates[:lon],
      start_date: start_date,
      end_date: end_date,
      daily: "temperature_2m_max,temperature_2m_min,precipitation_sum"
    })

    response = Net::HTTP.get_response(uri)
    JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)
  end
end