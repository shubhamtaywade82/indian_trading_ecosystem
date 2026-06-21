# frozen_string_literal: true

module Api
  module V1
    class InstrumentsController < ApplicationController
      # GET /api/v1/instruments
      def index
        instruments = if params[:q].present?
                        Core::Instrument.where("symbol ILIKE ? OR name ILIKE ?", "%#{params[:q]}%", "%#{params[:q]}%").limit(20)
                      else
                        Core::Instrument.limit(50)
                      end
        render json: instruments
      end

      # GET /api/v1/instruments/:id
      def show
        instrument = Core::Instrument.find(params[:id])
        render json: instrument
      end
    end
  end
end
