require 'net/http'
require 'json'

class OpenMeteoService
  BASE_URL = 'https://api.open-meteo.com/v1/forecast'.freeze

  def self.get_weather(latitude, longitude)
    uri = URI(BASE_URL)
    uri.query = URI.encode_www_form({
      latitude: latitude,
      longitude: longitude,
      hourly: 'temperature_2m,relativehumidity_2m',
      timezone: 'auto'
    })

    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
      { error: 'Failed to fetch weather data' }
    end
  rescue StandardError => e
    { error: e.message }
  end
end
