require 'rails_helper'

RSpec.describe Api::V1::WeatherController, type: :controller do
  before do
    stub_historical_weather_api
  end

  describe 'GET #historical' do
    let(:valid_params) do
      {
        location: 'Lusaka',
        start_date: '2024-12-27',
        end_date: '2025-01-27'
      }
    end

    context 'with valid parameters' do
      it 'returns historical weather data' do
        get :historical, params: valid_params
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with invalid location' do
      it 'returns bad request' do
        get :historical, params: valid_params.merge(location: 'Invalid')
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'with invalid date range' do
      it 'returns bad request' do
        get :historical, params: valid_params.merge(end_date: Date.tomorrow.to_s)
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end