module WebmockHelper
  def stub_weather_api(location)
    stub_request(:get, /api\.open-meteo\.com/)
      .with(query: hash_including(location: location))
      .to_return(
        status: 200,
        body: { temperature: 25 }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_historical_weather_api
    stub_request(:get, "https://archive-api.open-meteo.com/v1/archive")
      .with(query: hash_including({
        'daily' => 'temperature_2m_max,temperature_2m_min,precipitation_sum',
        'end_date' => '2025-01-27',
        'latitude' => '-15.4167',
        'longitude' => '28.2833',
        'start_date' => '2024-12-27'
      }))
      .to_return(
        status: 200,
        body: {
          'latitude' => -15.4167,
          'longitude' => 28.2833,
          'daily' => {
            'time' => ['2024-12-27', '2025-01-27'],
            'temperature_2m_max' => [25.0, 26.0],
            'temperature_2m_min' => [18.0, 19.0],
            'precipitation_sum' => [0.0, 2.5]
          }
        }.to_json,
        headers: {'Content-Type' => 'application/json'}
      )
  end
end

RSpec.configure do |config|
  config.include WebmockHelper
end