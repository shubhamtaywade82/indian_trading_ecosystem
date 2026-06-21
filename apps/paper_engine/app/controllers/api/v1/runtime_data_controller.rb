module Api
  module V1
    class RuntimeDataController < ApplicationController
      # GET /api/v1/positions
      def positions
        lots = TradeLot.where(account: current_account, status: 'OPEN')
        data = lots.group_by(&:instrument_id).map do |instrument, open_lots|
          qty = open_lots.sum { |l| l.remaining_qty }
          avg_price = open_lots.sum { |l| l.entry_price * l.remaining_qty } / qty rescue 0
          { instrument_id: instrument, qty: qty, avg_price: avg_price.round(2) }
        end
        render json: data
      end

      # GET /api/v1/holdings
      def holdings
        lots = TradeLot.where(account: current_account, status: 'OPEN', product_type: 'CNC')
                       .joins(:opening_trade)
                       .where(paper_trades: { side: 'buy' })
        data = lots.group_by(&:instrument_id).map do |instrument, open_lots|
          qty = open_lots.sum { |l| l.remaining_qty }
          avg_price = open_lots.sum { |l| l.entry_price * l.remaining_qty } / qty rescue 0
          { instrument_id: instrument, qty: qty, avg_price: avg_price.round(2) }
        end
        render json: data
      end

      # GET /api/v1/trades
      def trades
        trades = PaperTrade.where(account: current_account).order(exchange_ts: :desc).limit(200)
        render json: trades.map { |t|
          {
            id: t.id,
            instrument_id: t.instrument_id,
            side: t.side,
            fill_qty: t.fill_qty,
            fill_price: t.fill_price,
            fill_value: t.fill_value,
            exchange_ts: t.exchange_ts
          }
        }
      end

      # GET /api/v1/funds
      def funds
        ma = MarginAccount.find_by(account_id: current_account.id)
        ma&.sync_from_ledger!
        render json: {
          cash: (ma&.cash_balance || 0).to_f,
          available: (ma&.available_margin || 0).to_f,
          blocked: (ma&.blocked_margin || 0).to_f,
          realized_pnl: (ma&.realized_pnl || 0).to_f
        }
      end

      # GET /api/v1/depth/:symbol
      def depth
        orders = PaperOrder.where(instrument_id: params[:symbol], status: 'OPEN')
        bids = orders.where(side: 'buy').order(price: :desc).limit(5).map { |o| { price: o.price, qty: o.qty } }
        asks = orders.where(side: 'sell').order(price: :asc).limit(5).map { |o| { price: o.price, qty: o.qty } }
        render json: { symbol: params[:symbol], bids: bids, asks: asks }
      end
    end
  end
end
