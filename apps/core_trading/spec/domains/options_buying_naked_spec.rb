require 'rails_helper'

RSpec.describe Strategy::OptionsBuyingNaked, type: :model do
  let(:underlying_symbol) { 'RELIANCE' }
  
  # Setup underlying instrument and option contracts in database
  let!(:underlying_instrument) do
    Instrument.create!(
      symbol: underlying_symbol,
      exchange_id: exchange.id,
      segment_id: segment_eq.id,
      instrument_type: 'equity',
      security_id: 10001,
      name: 'Reliance Industries'
    )
  end

  let!(:underlying_record) do
    Underlying.create!(instrument_id: underlying_instrument.id, asset_class: 'Equity')
  end

  let!(:exchange) { Exchange.find_or_create_by!(code: 'NSE') }
  let!(:segment_eq) { Segment.find_or_create_by!(code: 'NSE_EQ', exchange: exchange) }
  let!(:segment_fno) { Segment.find_or_create_by!(code: 'NSE_FNO', exchange: exchange) }

  # Core models
  let!(:core_underlying) do
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
    # Primary Master Option
    inst = Instrument.create!(
      symbol: 'RELIANCE26JUNCE2500',
      exchange_id: exchange.id,
      segment_id: segment_fno.id,
      instrument_type: 'option',
      security_id: 20001,
      name: 'Reliance Jun 2500 Call'
    )
    deriv = DerivativeContract.create!(
      underlying_id: underlying_record.id,
      security_id: 20001,
      expiry_date: Date.parse('2026-06-26'),
      contract_type: 'call_option',
      lot_size: 250
    )
    OptionContract.create!(
      derivative_contract_id: deriv.id,
      strike_price: 2500.0,
      option_type: 'CE'
    )
  end

  let!(:core_opt_ce_1) do
    # Core Namespace Option
    core_inst = Core::Instrument.create!(
      symbol: 'RELIANCE26JUNCE2500',
      exchange: 'NSE',
      segment: 'NSE_FNO',
      instrument_type: 'options',
      lot_size: 250,
      name: 'Reliance Jun 2500 Call'
    )
    Core::OptionContract.create!(
      instrument: core_inst,
      underlying_symbol: underlying_symbol,
      expiry_date: Date.parse('2026-06-26'),
      strike_price: 2500.0,
      option_type: 'CE'
    )
  end

  let!(:opt_ce_2) do
    # Primary Master Option
    inst = Instrument.create!(
      symbol: 'RELIANCE26JUNCE2600',
      exchange_id: exchange.id,
      segment_id: segment_fno.id,
      instrument_type: 'option',
      security_id: 20002,
      name: 'Reliance Jun 2600 Call'
    )
    deriv = DerivativeContract.create!(
      underlying_id: underlying_record.id,
      security_id: 20002,
      expiry_date: Date.parse('2026-06-26'),
      contract_type: 'call_option',
      lot_size: 250
    )
    OptionContract.create!(
      derivative_contract_id: deriv.id,
      strike_price: 2600.0,
      option_type: 'CE'
    )
  end

  let!(:core_opt_ce_2) do
    # Core Namespace Option
    core_inst = Core::Instrument.create!(
      symbol: 'RELIANCE26JUNCE2600',
      exchange: 'NSE',
      segment: 'NSE_FNO',
      instrument_type: 'options',
      lot_size: 250,
      name: 'Reliance Jun 2600 Call'
    )
    Core::OptionContract.create!(
      instrument: core_inst,
      underlying_symbol: underlying_symbol,
      expiry_date: Date.parse('2026-06-26'),
      strike_price: 2600.0,
      option_type: 'CE'
    )
  end

  let!(:opt_pe_1) do
    # Primary Master Option
    inst = Instrument.create!(
      symbol: 'RELIANCE26JUNPE2500',
      exchange_id: exchange.id,
      segment_id: segment_fno.id,
      instrument_type: 'option',
      security_id: 20003,
      name: 'Reliance Jun 2500 Put'
    )
    deriv = DerivativeContract.create!(
      underlying_id: underlying_record.id,
      security_id: 20003,
      expiry_date: Date.parse('2026-06-26'),
      contract_type: 'put_option',
      lot_size: 250
    )
    OptionContract.create!(
      derivative_contract_id: deriv.id,
      strike_price: 2500.0,
      option_type: 'PE'
    )
  end

  let!(:core_opt_pe_1) do
    # Core Namespace Option
    core_inst = Core::Instrument.create!(
      symbol: 'RELIANCE26JUNPE2500',
      exchange: 'NSE',
      segment: 'NSE_FNO',
      instrument_type: 'options',
      lot_size: 250,
      name: 'Reliance Jun 2500 Put'
    )
    Core::OptionContract.create!(
      instrument: core_inst,
      underlying_symbol: underlying_symbol,
      expiry_date: Date.parse('2026-06-26'),
      strike_price: 2500.0,
      option_type: 'PE'
    )
  end

  # Setup Option Chain snapshot & entries
  let!(:option_chain) do
    OptionChain.create!(
      underlying_id: underlying_record.id,
      expiry: Date.parse('2026-06-26'),
      snapshot_at: Time.current
    )
  end

  let!(:entry_ce_1) do
    OptionChainEntry.create!(
      option_chain: option_chain,
      option_contract: opt_ce_1,
      ltp: 80.0,
      oi: 1000,
      volume: 500
    )
  end

  let!(:entry_ce_2) do
    OptionChainEntry.create!(
      option_chain: option_chain,
      option_contract: opt_ce_2,
      ltp: 40.0,
      oi: 50000, # Large OI -> Call Gamma Wall Resistance
      volume: 1200
    )
  end

  let!(:entry_pe_1) do
    OptionChainEntry.create!(
      option_chain: option_chain,
      option_contract: opt_pe_1,
      ltp: 60.0,
      oi: 50000, # Large OI -> Put Gamma Wall Support
      volume: 1000
    )
  end

  def build_candles(trend, start_price = 2500.0)
    flat = Array.new(22, start_price)
    ramp = if trend == :bullish
             (1..8).map { |i| start_price + (i * 15.0) } # Golden Cross
           else
             (1..8).map { |i| start_price - (i * 15.0) } # Death Cross
           end
    (flat + ramp).map { |p| { close: p, candle_time: Time.zone.parse('2026-06-22 10:00:00') } }
  end

  describe "#evaluate" do
    let(:market_data_with_vix) do
      {
        underlying_symbol => build_candles(:bullish, 2400.0), # end up at 2520
        'INDIAVIX' => [{ close: 15.0 }] # In safe range (12.0 - 25.0)
      }
    end

    let(:portfolio_state) do
      {
        total_value: 500_000.0,
        cash: 500_000.0,
        positions: {}
      }
    end

    context "with India VIX Volatility Filter" do
      it "blocks trades if VIX is too low (< 12.0)" do
        strategy = described_class.new(vix_min: 12.0)
        snapshot = market_data_with_vix.merge('INDIAVIX' => [{ close: 10.0 }])
        signals = strategy.evaluate(snapshot, portfolio_state)
        expect(signals).to be_empty
      end

      it "blocks trades if VIX is too high (> 25.0)" do
        strategy = described_class.new(vix_max: 25.0)
        snapshot = market_data_with_vix.merge('INDIAVIX' => [{ close: 30.0 }])
        signals = strategy.evaluate(snapshot, portfolio_state)
        expect(signals).to be_empty
      end

      it "allows trades if VIX is inside the safe corridor" do
        strategy = described_class.new(vix_min: 12.0, vix_max: 25.0)
        signals = strategy.evaluate(market_data_with_vix, portfolio_state)
        expect(signals).not_to be_empty
      end
    end

    context "with Gamma Wall / Open Interest Checks" do
      it "blocks CE entry if underlying price is too close to a major Call OI strike" do
        # CE Major OI is at strike 2600.
        # If underlying price ends up at 2595 (within 0.5% of 2600, which is 13 rupees)
        # 2595/2600 = gap of 0.19%
        strategy = described_class.new(vix_min: 12.0)
        snapshot = {
          underlying_symbol => build_candles(:bullish, 2475.0), # ends at 2595
          'INDIAVIX' => [{ close: 15.0 }]
        }
        
        signals = strategy.evaluate(snapshot, portfolio_state)
        expect(signals).to be_empty
      end

      it "allows CE entry if underlying price is far from Call OI walls" do
        strategy = described_class.new(vix_min: 12.0)
        snapshot = {
          underlying_symbol => build_candles(:bullish, 2400.0), # ends at 2520 (far from 2600)
          'INDIAVIX' => [{ close: 15.0 }]
        }
        signals = strategy.evaluate(snapshot, portfolio_state)
        expect(signals.length).to eq(1)
        expect(signals.first.instrument_id).to eq('RELIANCE26JUNCE2500')
      end
    end

    context "Position Sizing and Risk Metrics" do
      it "calculates correct risk-adjusted target quantity and SL/TP prices" do
        strategy = described_class.new(
          vix_min: 12.0,
          risk_pct_per_trade: 0.02, # 2% of 500k = 10,000 max capital
          stop_loss_pct: 0.15,
          take_profit_pct: 0.30
        )
        # Option price for RELIANCE26JUNCE2500 is 80.0, lot size is 250
        # Allowed qty = 10,000 / 80 = 125 options. 
        # Clamped/adjusted to 1 lot = 250 options
        signals = strategy.evaluate(market_data_with_vix, portfolio_state)
        expect(signals.length).to eq(1)
        
        meta = signals.first.metadata
        expect(meta[:target_qty]).to eq(250)
        expect(meta[:option_price]).to eq(80.0)
        expect(meta[:stop_loss]).to eq(68.0) # 80 - 15%
        expect(meta[:take_profit]).to eq(104.0) # 80 + 30%
        expect(meta[:target_weight]).to eq((250 * 80.0) / 500_000.0)
      end
    end
  end
end
