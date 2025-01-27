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

      def historical
        location = params[:location]
        start_date = params[:start_date]
        end_date = params[:end_date]

        unless location.present? && LocationValidator.valid_location?(location)
          return render json: { 
            error: "Invalid location. Supported locations: #{LocationValidator.supported_locations.join(', ')}" 
          }, status: :bad_request
        end

        unless valid_date_range?(start_date, end_date)
          return render json: { error: "Invalid date range" }, status: :bad_request
        end

        weather_data = OpenMeteoService.get_historical_weather(location, start_date, end_date)
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

      def valid_date_range?(start_date, end_date)
        return false unless start_date.present? && end_date.present?
        
        begin
          start_date = Date.parse(start_date)
          end_date = Date.parse(end_date)
          start_date <= end_date && end_date <= Date.today
        rescue Date::Error
          false
        end
      end
    end
  end
end