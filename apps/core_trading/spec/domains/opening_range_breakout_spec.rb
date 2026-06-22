require 'rails_helper'

RSpec.describe Strategy::OpeningRangeBreakout, type: :model do
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
    it "triggers buy on high breakout with volume confirmation" do
      strategy = described_class.new(orb_minutes: 15, volume_multiple: 1.2)
      
      # 3 range candles flat at 2500, followed by a breakout close at 2520 with high volume
      candles = [
        { close: 2500.0, high: 2500.0, low: 2500.0, volume: 100, candle_time: Time.zone.parse('2026-06-22 09:15:00') },
        { close: 2500.0, high: 2500.0, low: 2500.0, volume: 100, candle_time: Time.zone.parse('2026-06-22 09:20:00') },
        { close: 2500.0, high: 2500.0, low: 2500.0, volume: 100, candle_time: Time.zone.parse('2026-06-22 09:25:00') },
        { close: 2520.0, high: 2525.0, low: 2500.0, volume: 200, candle_time: Time.zone.parse('2026-06-22 09:35:00') }
      ]
      
      snapshot = { underlying_symbol => candles, 'INDIAVIX' => [{ close: 15.0 }] }
      signals = strategy.evaluate(snapshot, { total_value: 500_000.0 })
      
      expect(signals.length).to eq(1)
      expect(signals.first.instrument_id).to eq('RELIANCE26JUNCE2500')
      expect(signals.first.metadata[:range_high]).to eq(2500.0)
    end
  end
end
