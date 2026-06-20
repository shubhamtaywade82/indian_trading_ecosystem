class TradeProcessor
  # execute can now take an existing order, or create a dummy one for legacy phase 1 support
  def self.execute(account:, instrument:, side:, qty:, price:, order: nil)
    ActiveRecord::Base.transaction do
      # 1. Use the provided order or create a dummy one for Phase 1 compatibility
      trade_order = order || PaperOrder.create!(
        account: account,
        instrument_id: instrument,
        side: side,
        order_type: 'MARKET',
        product_type: 'CNC',
        qty: qty,
        client_order_id: SecureRandom.uuid,
        status: 'FILLED'
      )

      # 2. Create the trade
      trade = PaperTrade.create!(
        paper_order: trade_order,
        account: account,
        instrument_id: instrument,
        side: side,
        fill_qty: qty,
        fill_price: price,
        fill_value: qty * price,
        exchange_ts: Time.current
      )

      # 3. Handle lots (Naive Phase 1)
      if side == 'buy'
        TradeLot.create!(
          account: account,
          instrument_id: instrument,
          opening_trade: trade,
          side: side,
          original_qty: qty,
          remaining_qty: qty,
          entry_price: price,
          strategy_id: trade_order.strategy_id,
          status: 'OPEN'
        )
      else
        remaining_to_sell = qty
        open_lots = TradeLot.where(account: account, instrument_id: instrument, side: 'buy', status: 'OPEN').order(created_at: :asc)
        
        open_lots.each do |lot|
          break if remaining_to_sell <= 0
          
          consume_qty = [lot.remaining_qty, remaining_to_sell].min
          realized_pnl = consume_qty * (price - lot.entry_price)

          LotConsumption.create!(
            trade_lot: lot,
            closing_trade: trade,
            qty_consumed: consume_qty,
            exit_price: price,
            realized_pnl: realized_pnl,
            costing_method: 'FIFO'
          )

          Paper::Accounting::TaxEngine.handle_consumption(LotConsumption.last)

          lot.remaining_qty -= consume_qty
          lot.status = 'CLOSED' if lot.remaining_qty.zero?
          lot.save!

          # Post the Realized PnL to the ledger
          JournalEntry.transaction do
            pnl_journal = JournalEntry.create!(
              account: account,
              reference_type: 'trade_pnl',
              reference_id: trade.id,
              description: "Realized PnL for trade " + trade.id.to_s
            )
            if realized_pnl > 0
              pnl_journal.ledger_entries.create!(account: account, ledger_account: "inventory:" + instrument, debit: realized_pnl)
              pnl_journal.ledger_entries.create!(account: account, ledger_account: "realized_pnl", credit: realized_pnl)
            elsif realized_pnl < 0
              pnl_journal.ledger_entries.create!(account: account, ledger_account: "realized_pnl", debit: realized_pnl.abs)
              pnl_journal.ledger_entries.create!(account: account, ledger_account: "inventory:" + instrument, credit: realized_pnl.abs)
            end
          end

          remaining_to_sell -= consume_qty
        end
      end

      # 4. Post the basic trade to Ledger (Cash vs Inventory)
      LedgerPoster.post_trade!(account: account, trade: trade)

      # 5. Post Charges to Ledger
      Paper::Accounting::ChargesEngine.post_to_ledger!(trade)

      # 6. Record Settlement constraints
      Paper::Accounting::SettlementEngine.handle_trade(trade)

      trade
    end
  end
end
