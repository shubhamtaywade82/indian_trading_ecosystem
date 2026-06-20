# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketData::DhanAdapter do
  let!(:exchange) { Exchange.create!(code: 'NSE', name: 'National Stock Exchange') }
  let!(:segment) { Segment.create!(exchange: exchange, code: 'NSE_EQ', name: 'NSE Equity') }
  let!(:fno_segment) { Segment.create!(exchange: exchange, code: 'NSE_FNO', name: 'NSE Derivatives') }
  let!(:instrument) { Instrument.create!(exchange: exchange, segment: segment, security_id: 12345, symbol: 'RELIANCE', instrument_type: :equity) }

  let!(:underlying) { Underlying.create!(instrument: instrument) }
  let!(:derivative_inst) { Instrument.create!(exchange: exchange, segment: fno_segment, security_id: 54321, symbol: 'RELIANCE-FUT', instrument_type: :future) }
  let!(:derivative_contract) do
    DerivativeContract.create!(
      underlying: underlying,
      security_id: 54321,
      contract_type: 'future',
      expiry_date: Date.tomorrow
    )
  end

  describe '.fetch_snapshot' do
    it 'queries Quote API first and maps response fields' do
      expect(DhanHQ::Models::MarketFeed).to receive(:quote).with({ 'NSE_EQ' => [12345] }).and_return({
        'status' => 'success',
        'data' => {
          'NSE_EQ' => {
            '12345' => {
              'lastPrice' => 2500.5,
              'volume' => 150000,
              'buyDepth' => [{ 'price' => 2500.0 }],
              'sellDepth' => [{ 'price' => 2501.0 }]
            }
          }
        }
      })

      snapshot = described_class.fetch_snapshot(instrument)
      expect(snapshot).to include(
        symbol: 'RELIANCE',
        last_price: 2500.5,
        volume: 150000,
        bid: 2500.0,
        ask: 2501.0
      )
    end

    it 'falls back to LTP API if Quote API fails' do
      expect(DhanHQ::Models::MarketFeed).to receive(:quote).and_raise(StandardError, "API Limit")
      expect(DhanHQ::Models::MarketFeed).to receive(:ltp).with({ 'NSE_EQ' => [12345] }).and_return({
        'status' => 'success',
        'data' => {
          'NSE_EQ' => {
            '12345' => {
              'lastPrice' => 2498.0
            }
          }
        }
      })

      snapshot = described_class.fetch_snapshot(instrument)
      expect(snapshot).to include(
        symbol: 'RELIANCE',
        last_price: 2498.0,
        volume: 0,
        bid: 2498.0,
        ask: 2498.0
      )
    end
  end

  describe '.fetch_historical' do
    it 'fetches intraday candles and parses hash format' do
      expect(DhanHQ::Models::HistoricalData).to receive(:intraday).with(
        security_id: 12345,
        exchange_segment: 'NSE_EQ',
        instrument: 'EQUITY',
        interval: '15',
        oi: true,
        from_date: '2026-06-01',
        to_date: '2026-06-05'
      ).and_return({
        'timestamp' => [1723791000, 1723791300],
        'open' => [2500.0, 2505.0],
        'high' => [2510.0, 2512.0],
        'low' => [2495.0, 2502.0],
        'close' => [2506.0, 2508.0],
        'volume' => [1000, 1200],
        'oi' => [10, 12]
      })

      candles = described_class.fetch_historical(instrument, '15m', '2026-06-01', '2026-06-05')
      expect(candles.size).to eq(2)
      expect(candles.first).to include(
        open: 2500.0,
        high: 2510.0,
        low: 2495.0,
        close: 2506.0,
        volume: 1000,
        oi: 10
      )
    end

    it 'resolves derivative contract types correctly' do
      expect(DhanHQ::Models::HistoricalData).to receive(:intraday).with(
        security_id: 54321,
        exchange_segment: 'NSE_FNO',
        instrument: 'FUTSTK', # Since underlying is EQUITY
        interval: '5',
        oi: true,
        from_date: '2026-06-01',
        to_date: '2026-06-01'
      ).and_return([])

      described_class.fetch_historical(derivative_inst, '5', '2026-06-01', '2026-06-01')
    end
  end
end
