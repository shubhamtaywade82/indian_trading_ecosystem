# frozen_string_literal: true

module Paper
  class TradeProcessor
    def self.execute(account:, instrument_id:, side:, qty:, price:, client_order_id: nil)
      if client_order_id.present?
        existing_order = PaperOrder.find_by(account: account, client_order_id: client_order_id)
        if existing_order&.paper_trades&.any?
          return existing_order.paper_trades.first
        end
      end

      side = side.to_s.downcase
      sequence_no = PaperTrade.where(account: account).maximum(:sequence_no).to_i + 1

      ActiveRecord::Base.transaction do
        order = PaperOrder.create!(
          account: account,
          instrument_id: instrument_id,
          side: side == "buy" ? "buy" : "sell",
          qty: qty,
          price: price,
          status: "filled",
          client_order_id: client_order_id || "paper-#{SecureRandom.hex(4)}"
        )

        trade = PaperTrade.create!(
          account: account,
          paper_order: order,
          instrument_id: instrument_id,
          side: side,
          fill_qty: qty,
          fill_price: price,
          fill_value: qty * price,
          sequence_no: sequence_no,
          slippage_applied: 0
        )

        if side == "buy"
          TradeLot.create!(
            account: account,
            opening_trade: trade,
            instrument_id: instrument_id,
            side: "buy",
            original_qty: qty,
            remaining_qty: qty,
            entry_price: price,
            status: "open"
          )
        else
          sell_qty_remaining = qty
          open_lots = TradeLot.where(
            account: account, instrument_id: instrument_id,
            side: "buy", status: "open"
          ).order(:created_at)

          open_lots.each do |lot|
            break if sell_qty_remaining <= 0
            consume = [sell_qty_remaining, lot.remaining_qty].min

            LotConsumption.create!(
              trade_lot: lot,
              closing_trade: trade,
              qty_consumed: consume,
              exit_price: price,
              realized_pnl: (price - lot.entry_price) * consume,
              costing_method: "fifo"
            )

            new_remaining = lot.remaining_qty - consume
            lot.update!(remaining_qty: new_remaining, status: new_remaining > 0 ? "open" : "closed")
            sell_qty_remaining -= consume
          end

          if sell_qty_remaining > 0
            raise "Cannot sell #{qty} - only #{qty - sell_qty_remaining} available"
          end

          TradeLot.create!(
            account: account,
            opening_trade: trade,
            instrument_id: instrument_id,
            side: "sell",
            original_qty: qty,
            remaining_qty: qty,
            entry_price: price,
            status: "open"
          )
        end

        LedgerPoster.post_trade_journal(account, trade)

        trade
      end
    rescue StandardError => e
      raise e
    end
  end
end