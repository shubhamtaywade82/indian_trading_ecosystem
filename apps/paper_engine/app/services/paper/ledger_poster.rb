# frozen_string_literal: true

module Paper
  class LedgerPoster
    COA = %w[cash inventory realized_pnl brokerage stt gst exchange_charges
             sebi_charges stamp_duty dp_charges margin_blocked].freeze

    def self.post_trade_journal(account, trade, charges: {})
      instrument_account = "inventory:#{trade.instrument_id}"
      value = trade.fill_qty * trade.fill_price

      entries = case trade.side.to_s.downcase
      when "buy"
        [
          { ledger_account: instrument_account, debit: value, credit: 0 },
          { ledger_account: "cash", debit: 0, credit: value }
        ]
      when "sell"
        consumed_lots = LotConsumption.where(closing_trade: trade)
        consumed_cost = consumed_lots.sum { |lc| lc.qty_consumed * lc.trade_lot.entry_price }
        pnl = if consumed_cost > 0
          value - consumed_cost
        else
          value - get_average_cost(account, trade.instrument_id, trade.fill_qty)
        end

        pnl_account = "realized_pnl"
        [
          { ledger_account: "cash", debit: value, credit: 0 },
          { ledger_account: instrument_account, debit: 0, credit: (consumed_cost > 0 ? consumed_cost : value) },
          { ledger_account: pnl_account, debit: (pnl < 0 ? pnl.abs : 0), credit: (pnl > 0 ? pnl : 0) }
        ]
      else
        raise ArgumentError, "Unknown side: #{trade.side}"
      end

      ActiveRecord::Base.transaction do
        je = JournalEntry.create!(
          account: account,
          reference_type: "trade",
          reference_id: trade.id,
          description: "#{trade.side.upcase} #{trade.instrument_id} #{trade.fill_qty}@#{trade.fill_price}",
          occurred_at: Time.now.utc
        )

        entries.each do |e|
          LedgerEntry.create!(
            account: account,
            journal_entry: je,
            ledger_account: e[:ledger_account],
            debit: e[:debit] || 0,
            credit: e[:credit] || 0
          )
        end

        debits = je.ledger_entries.sum(:debit)
        credits = je.ledger_entries.sum(:credit)
        if debits != credits
          raise "Journal #{je.id} imbalanced: D#{debits} vs C#{credits}"
        end
      end

      DomainModels::Commands::CommandResult.success(payload: trade)
    rescue StandardError => e
      DomainModels::Commands::CommandResult.failure(error: e.message)
    end

    private

    def self.get_average_cost(account, instrument_id, qty)
      lots = TradeLot.where(account: account, instrument_id: instrument_id, side: "buy", status: "open")
      total_cost = lots.sum("remaining_qty * entry_price")
      total_qty = lots.sum(:remaining_qty)
      return total_cost / total_qty if total_qty > 0
      0
    end
  end
end