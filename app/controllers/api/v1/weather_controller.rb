module Api
  module V1
    class WeatherController < ApplicationController
      rescue_from Faraday::Error, with: :handle_api_error

      def current
        location = params[:location]
        
        unless location.present? && LocationValidator.valid_location?(location)
          return render json: { 
            error: "Invalid location. Supported locations: #{LocationValidator.supported_locations.join(', ')}" 
          }, status: :bad_request
        end

        weather_data = OpenMeteoService.get_current_weather(location)
        render json: weather_data
      end

      private

      def render_bad_request(message)
        render json: { error: message }, status: :bad_request
      end

      def render_not_found(message)
        render json: { error: message }, status: :not_found
      end

      def handle_api_error(exception)
        render json: { error: "Weather service unavailable: #{exception.message}" }, 
               status: :service_unavailable
      end
    end
  end
end