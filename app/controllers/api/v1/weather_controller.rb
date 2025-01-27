module Api
    module V1
      class WeatherController < ApplicationController
        def current
          location = Location.find_by(name: params[:location].titleize)
          
          if location
            render json: { 
              temperature: 25.5,  # Temporary static data
              humidity: 65,
              location: location.name 
            }
          else
            render json: { error: "Location not found" }, status: :not_found
          end
        end
      end
    end
  end