module Api
  module V1
    class WeatherController < ApplicationController
      def current
        location = params[:location]

        unless location.present?
          return render json: { error: "Location parameter is required" }, status: :bad_request
        end

        weather_data = OpenMeteoService.get_current_weather(location)

        if weather_data
          render json: weather_data
        else
          render json: { error: "Location not supported" }, status: :not_found
        end
      end
    end
  end
end
