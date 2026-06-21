# frozen_string_literal: true

module Api
  module V1
    class InstrumentsController < ApplicationController
      # GET /api/v1/instruments
      def index
        instruments = if params[:q].present?
                        Instrument.includes(:exchange)
                                  .where("symbol ILIKE ? OR trading_symbol ILIKE ? OR name ILIKE ?", "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%")
                                  .limit(20)
                      else
                        Instrument.includes(:exchange).limit(50)
                      end

        render json: instruments.map { |inst|
          {
            id: inst.id,
            symbol: inst.trading_symbol || inst.symbol,
            trading_symbol: inst.trading_symbol,
            exchange: inst.exchange&.code,
            instrument_type: inst.instrument_type
          }
        }
      end

      # GET /api/v1/instruments/:id
      def show
        instrument = Instrument.find(params[:id])
        render json: instrument
      end
    end
  end
end
