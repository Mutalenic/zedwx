Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get "weather/current", to: "weather#current"
      get "weather/historical", to: "weather#historical"
    end
  end
end
