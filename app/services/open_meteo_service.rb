class OpenMeteoService
  BASE_URL = "https://api.open-meteo.com/v1/forecast".freeze

  def self.get_current_weather(location_name)
    location = Location.find_by(name: location_name.titleize)
    return unless location

    params = {
      latitude: location.latitude,
      longitude: location.longitude,
      current: "temperature_2m,relative_humidity_2m,wind_speed_10m,precipitation,weather_code",
      timezone: "Africa/Lusaka"
    }

    response = Faraday.get(BASE_URL, params)
    return unless response.success?

    raw_data = JSON.parse(response.body)
    format_response(raw_data)
  end

  private

  def self.format_response(raw_data)
    current = raw_data["current"]
    {
      temperature: current["temperature_2m"],
      humidity: current["relative_humidity_2m"],
      wind_speed: current["wind_speed_10m"],
      precipitation: current["precipitation"],
      weather_condition: translate_weather_code(current["weather_code"]),
      units: {
        temperature: "°C",
        wind_speed: "km/h",
        precipitation: "mm"
      }
    }
  end

  # WMO Weather Code translation for Zambia
  def self.translate_weather_code(code)
    {
      0 => "Clear sky",
      1 => "Mainly clear",
      2 => "Partly cloudy",
      3 => "Overcast",
      10 => "Mist",
      21 => "Patchy rain possible",
      22 => "Patchy snow possible",
      23 => "Patchy sleet possible",
      24 => "Patchy freezing drizzle possible",
      29 => "Thundery outbreaks possible",
      38 => "Blowing snow",
      39 => "Blizzard",
      45 => "Fog",
      49 => "Freezing fog",
      50 => "Patchy light drizzle",
      51 => "Light drizzle",
      56 => "Freezing drizzle",
      57 => "Heavy freezing drizzle",
      60 => "Patchy light rain",
      61 => "Light rain",
      63 => "Moderate rain at times",
      64 => "Moderate rain",
      65 => "Heavy rain at times",
      66 => "Heavy rain",
      67 => "Light freezing rain",
      68 => "Moderate or heavy freezing rain",
      69 => "Light sleet",
      70 => "Moderate or heavy sleet",
      71 => "Patchy light snow",
      72 => "Light snow",
      75 => "Patchy moderate snow",
      76 => "Moderate snow",
      77 => "Patchy heavy snow",
      78 => "Heavy snow",
      80 => "Patchy light rain with thunder",
      81 => "Moderate or heavy rain with thunder",
      82 => "Patchy snow with thunder",
      83 => "Moderate or heavy snow with thunder"
      
    }[code] || "Unknown weather condition"
  end
end