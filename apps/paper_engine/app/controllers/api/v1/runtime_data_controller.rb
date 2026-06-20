module Api
  module V1
    class RuntimeDataController < ApplicationController
      def trades
        render json: current_runtime.trades
      end

      def positions
        render json: Projections::Position.where(runtime: current_runtime)
      end

      def holdings
        render json: Projections::Holding.where(runtime: current_runtime)
      end

      def funds
        render json: Projections::Fund.where(runtime: current_runtime)
      end

      def depth
        book = Exchange::OrderBook.for(current_runtime.id, params[:symbol])
        render json: {
          bids: [{ price: book.bid_price, quantity: book.bid_qty }],
          asks: [{ price: book.ask_price, quantity: book.ask_qty }]
        }
      end

      def orderbook
        depth
      end

      def executions
        trades
      end

      private

      def current_runtime
        Runtime.first || Runtime.create!(name: "Test", mode: "paper", active: true)
      end
    end
  end
end
