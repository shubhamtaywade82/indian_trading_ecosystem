require 'rails_helper'

RSpec.describe Strategy::VixMeanReversion, type: :model do
  let(:underlying_symbol) { 'RELIANCE' }
  let!(:exchange) { Exchange.find_or_create_by!(code: 'NSE') }
  let!(:segment_eq) { Segment.find_or_create_by!(code: 'NSE_EQ', exchange: exchange) }
  let!(:segment_fno) { Segment.find_or_create_by!(code: 'NSE_FNO', exchange: exchange) }

  let!(:underlying_instrument) do
    Instrument.create!(symbol: underlying_symbol, exchange_id: exchange.id, segment_id: segment_eq.id, instrument_type: 'equity', security_id: 10001, name: 'Reliance')
  end
  let!(:underlying_record) { Underlying.create!(instrument_id: underlying_instrument.id, asset_class: 'Equity') }

  let!(:core_underlying) do
    Core::Instrument.create!(symbol: underlying_symbol, exchange: 'NSE', segment: 'NSE_EQ', instrument_type: 'equity', name: 'Reliance')
  end

  let!(:opt_ce) do
    inst = Instrument.create!(symbol: 'RELIANCE26JUNCE2500', exchange_id: exchange.id, segment_id: segment_fno.id, instrument_type: 'option', security_id: 20001, name: 'Jun CE 2500')
    deriv = DerivativeContract.create!(underlying_id: underlying_record.id, security_id: 20001, expiry_date: Date.parse('2026-06-26'), contract_type: 'call_option', lot_size: 250)
    OptionContract.create!(derivative_contract_id: deriv.id, strike_price: 2500.0, option_type: 'CE')
  end

  let!(:core_opt_ce) do
    core_inst = Core::Instrument.create!(symbol: 'RELIANCE26JUNCE2500', exchange: 'NSE', segment: 'NSE_FNO', instrument_type: 'options', lot_size: 250, name: 'Jun CE 2500')
    Core::OptionContract.create!(instrument: core_inst, underlying_symbol: underlying_symbol, expiry_date: Date.parse('2026-06-26'), strike_price: 2500.0, option_type: 'CE')
  end

  let!(:option_chain) { OptionChain.create!(underlying_id: underlying_record.id, expiry: Date.parse('2026-06-26'), snapshot_at: Time.current) }
  let!(:entry_ce) { OptionChainEntry.create!(option_chain: option_chain, option_contract: opt_ce, ltp: 80.0, oi: 1000, volume: 500) }

  describe "#evaluate" do
    it "triggers buy on VIX compression followed by breakout expansion" do
      strategy = described_class.new(
        vix_percentile_threshold: 30.0,
        vix_compression_bars: 2,
        vix_rise_pct: 0.05,
        vix_ma_period: 5
      )
      
      # VIX history: compressed low values (e.g. 10.0), then sudden breakout to 12.0 (+20%)
      vix_history = Array.new(25, 10.0)
      vix_history[-1] = 12.0 # Breakout
      vix_history[-2] = 10.0
      
      vix_candles = vix_history.map { |v| { close: v.to_f } }
      
      # Underlying prices rising to ensure close > EMA (bullish direction)
      underlying_candles = (1..25).map { |i| { close: 2500.0 + (i * 5.0) } }
      snapshot = { 
        underlying_symbol => underlying_candles,
        'INDIAVIX' => vix_candles
      }
      
      signals = strategy.evaluate(snapshot, { total_value: 500_000.0 })
      
      expect(signals.length).to eq(1)
      expect(signals.first.instrument_id).to eq('RELIANCE26JUNCE2500')
    end
  end
end
