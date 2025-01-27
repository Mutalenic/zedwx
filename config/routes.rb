namespace :api do
  namespace :v1 do
    get 'weather/current', to: 'weather#current'
  end
end