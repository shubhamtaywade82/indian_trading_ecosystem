require 'rails_helper'

RSpec.describe Strategy::OptionsBuyingNaked, type: :model do
  let(:underlying_symbol) { 'RELIANCE' }
  
  # Setup option contracts in database
  let!(:underlying_instrument) do
    Core::Instrument.create!(
      symbol: underlying_symbol,
      exchange: 'NSE',
      segment: 'NSE_EQ',
      instrument_type: 'equity',
      lot_size: 1,
      name: 'Reliance Industries'
    )
  end

  let!(:opt_ce_1) do
    inst = Core::Instrument.create!(
      symbol: 'RELIANCE26JUNCE2500',
      exchange: 'NSE',
      segment: 'NSE_FNO',
      instrument_type: 'options',
      lot_size: 250,
      name: 'Reliance Jun 2500 Call'
    )
    Core::OptionContract.create!(
      instrument: inst,
      underlying_symbol: underlying_symbol,
      expiry_date: Date.parse('2026-06-26'),
      strike_price: 2500.0,
      option_type: 'CE'
    )
  end

  let!(:opt_ce_2) do
    inst = Core::Instrument.create!(
      symbol: 'RELIANCE26JUNCE2600',
      exchange: 'NSE',
      segment: 'NSE_FNO',
      instrument_type: 'options',
      lot_size: 250,
      name: 'Reliance Jun 2600 Call'
    )
    Core::OptionContract.create!(
      instrument: inst,
      underlying_symbol: underlying_symbol,
      expiry_date: Date.parse('2026-06-26'),
      strike_price: 2600.0,
      option_type: 'CE'
    )
  end

  let!(:opt_pe_1) do
    inst = Core::Instrument.create!(
      symbol: 'RELIANCE26JUNPE2500',
      exchange: 'NSE',
      segment: 'NSE_FNO',
      instrument_type: 'options',
      lot_size: 250,
      name: 'Reliance Jun 2500 Put'
    )
    Core::OptionContract.create!(
      instrument: inst,
      underlying_symbol: underlying_symbol,
      expiry_date: Date.parse('2026-06-26'),
      strike_price: 2500.0,
      option_type: 'PE'
    )
  end

  def build_candles(trend)
    # 30 candles
    flat = Array.new(22, 2500.0)
    ramp = if trend == :bullish
             (1..8).map { |i| 2500.0 + (i * 15.0) } # 2515 → 2620
           else
             (1..8).map { |i| 2500.0 - (i * 15.0) } # 2485 → 2380
           end
    (flat + ramp).map { |p| { close: p, candle_time: Time.zone.parse('2026-06-22 10:00:00') } }
  end

  describe "#evaluate" do
    context "when golden cross occurs (bullish)" do
      it "generates a BUY signal for Call option closest to ATM" do
        strategy = described_with_style("ATM")
        snapshot = { underlying_symbol => build_candles(:bullish) }
        
        signals = strategy.evaluate(snapshot, {})
        expect(signals.length).to eq(1)
        expect(signals.first.instrument_id).to eq('RELIANCE26JUNCE2600') # ATM closest to ~2620
        expect(signals.first.buy?).to be true
        expect(signals.first.metadata[:option_type]).to eq('CE')
      end

      it "selects OTM option if configured" do
        strategy = described_with_style("OTM", offset: 1)
        snapshot = { underlying_symbol => build_candles(:bullish) }
        
        signals = strategy.evaluate(snapshot, {})
        expect(signals.length).to eq(1)
        # OTM for Call: Strike > Underlying. ATM is 2600. Higher strike is 2600 (we don't have higher in mock, so it clamps to max or ATM)
        expect(signals.first.instrument_id).to eq('RELIANCE26JUNCE2600')
      end
    end

    context "when death cross occurs (bearish)" do
      it "generates a BUY signal for Put option closest to ATM" do
        strategy = described_with_style("ATM")
        snapshot = { underlying_symbol => build_candles(:bearish) }
        
        signals = strategy.evaluate(snapshot, {})
        expect(signals.length).to eq(1)
        expect(signals.first.instrument_id).to eq('RELIANCE26JUNPE2500') # ATM closest to ~2380 (out of 2500)
        expect(signals.first.buy?).to be true
        expect(signals.first.metadata[:option_type]).to eq('PE')
      end
    end
  end

  def described_with_style(style, offset: 0)
    described_class.new(
      short_period: 9,
      long_period: 21,
      strike_style: style,
      strike_offset: offset
    )
  end
end
