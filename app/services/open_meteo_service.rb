class OpenMeteoService
  BASE_URL = "https://api.open-meteo.com/v1/forecast".freeze

  def self.fetch_weather(latitude, longitude)
    params = {
      latitude: latitude,
      longitude: longitude,
      hourly: "temperature_2m,relativehumidity_2m,windspeed_10m,precipitation",
      timezone: "Africa/Lusaka"  # Zambia's timezone
    }

    response = Faraday.get(BASE_URL, params)
    JSON.parse(response.body)
  rescue Faraday::Error => e
    { error: "Failed to fetch weather data: #{e.message}" }
  end

  def self.get_current_weather(location)
    # Hardcoded coordinates for Lusaka initially
    coordinates = {
      "Lusaka" => { lat: -15.4167, lon: 28.2833 },
      "Livingstone" => { lat: -17.8531, lon: 25.8625 }
    }

    return nil unless coordinates[location]

    uri = URI("#{BASE_URL}?latitude=#{coordinates[location][:lat]}&longitude=#{coordinates[location][:lon]}&current_weather=true")
    response = Net::HTTP.get_response(uri)

    JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)
  end
end
