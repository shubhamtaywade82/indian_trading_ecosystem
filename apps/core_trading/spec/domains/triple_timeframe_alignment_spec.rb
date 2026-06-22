require 'rails_helper'

RSpec.describe Strategy::TripleTimeframeAlignment, type: :model do
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
    it "triggers buy on daily & hourly bullish trend with 15m pullback hammer" do
      strategy = described_class.new(short_ema_period: 5, long_ema_period: 10)
      
      # Setup daily & hourly bullish trend (ramp prices up to guarantee short EMA > long EMA)
      bullish_trend = (1..15).map { |i| { close: 2500.0 + (i * 10.0), open: 2500.0 + (i * 10.0), high: 2500.0 + (i * 10.0) + 2.0, low: 2500.0 + (i * 10.0) - 2.0 } }
      
      # Last candle: pullback hammer touch (EMA is ~2620, close is 2632, low goes down to 2605)
      pullback_hammer = { close: 2632.0, open: 2629.0, high: 2632.0, low: 2605.0, candle_time: Time.zone.parse('2026-06-22 10:00:00') }
      
      candles = bullish_trend + [pullback_hammer]
      snapshot = { underlying_symbol => candles, 'INDIAVIX' => [{ close: 15.0 }] }
      
      signals = strategy.evaluate(snapshot, { total_value: 500_000.0 })
      
      expect(signals.length).to eq(1)
      expect(signals.first.instrument_id).to eq('RELIANCE26JUNCE2500')
    end
  end
end
