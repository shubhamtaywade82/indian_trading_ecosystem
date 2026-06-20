module Accounting
  class ChargesEngine
    def self.calculate(trade)
      order = trade.order
      return {} unless order

      profile = ChargeProfile.find_by(broker: 'Generic', segment: order.segment, product_type: order.product_type) ||
                ChargeProfile.find_by(segment: order.segment, product_type: order.product_type) ||
                ChargeProfile.first

      return {} unless profile

      value = trade.quantity * trade.price
      
      brokerage = [profile.brokerage_flat, value * profile.brokerage_pct].max
      stt = value * profile.stt_pct
      exchange = value * profile.exchange_pct
      sebi = value * profile.sebi_pct
      stamp = value * profile.stamp_pct
      gst = (brokerage + exchange + sebi) * profile.gst_pct

      {
        brokerage: brokerage,
        stt: stt,
        exchange: exchange,
        sebi: sebi,
        stamp: stamp,
        gst: gst,
        total: brokerage + stt + exchange + sebi + stamp + gst
      }
    end

    def self.post_charges(trade, runtime, account)
      charges = calculate(trade)
      return if charges.empty? || charges[:total] == 0

      # Deduct charges from margin account
      margin_account = Broker::MarginAccount.find_by(runtime: runtime, account: account)
      if margin_account
        margin_account.update!(cash_balance: margin_account.cash_balance - charges[:total])
      end

      # Create Cashflow entry
      PortfolioCashflow.create!(
        runtime_id: runtime.id,
        account_id: account.id,
        cashflow_type: 'CHARGES',
        amount: -charges[:total],
        reference_id: trade.id.to_s,
        reference_type: 'Trade'
      )
    end
  end
end
