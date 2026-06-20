# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Execution::DhanAdapter do
  let!(:exchange) { Exchange.create!(code: 'NSE', name: 'National Stock Exchange') }
  let!(:segment) { Segment.create!(exchange: exchange, code: 'NSE_EQ', name: 'NSE Equity') }
  let!(:instrument) { Instrument.create!(exchange: exchange, segment: segment, security_id: 12345, symbol: 'RELIANCE', instrument_type: :equity) }
  let(:config) { double('RuntimeConfig', mode: 'live', broker: 'dhan') }
  let(:adapter) { described_class.new(config) }

  describe '#place_order' do
    it 'creates a MARKET order using DhanHQ Order model' do
      order_double = double('Order', order_id: 'ORD123', order_status: 'ACCEPTED')
      expect(DhanHQ::Models::Order).to receive(:create).with(hash_including(
        transaction_type: 'BUY',
        exchange_segment: 'NSE_EQ',
        security_id: '12345',
        quantity: 10,
        order_type: 'MARKET',
        product_type: 'INTRADAY'
      )).and_return(order_double)

      res = adapter.place_order({ instrument_id: 'RELIANCE', side: 'buy', qty: 10, product_type: 'INTRADAY' })
      expect(res).to include(
        success: true,
        order_id: 'ORD123',
        status: 'ACCEPTED'
      )
    end

    it 'creates a LIMIT order when price is specified' do
      order_double = double('Order', order_id: 'ORD456', order_status: 'PENDING')
      expect(DhanHQ::Models::Order).to receive(:create).with(hash_including(
        transaction_type: 'SELL',
        exchange_segment: 'NSE_EQ',
        security_id: '12345',
        quantity: 5,
        order_type: 'LIMIT',
        price: 2500.0
      )).and_return(order_double)

      res = adapter.place_order({ instrument_id: 'RELIANCE', side: 'sell', qty: 5, price: 2500.0 })
      expect(res).to include(
        success: true,
        order_id: 'ORD456',
        status: 'PENDING'
      )
    end
  end

  describe '#cancel_order' do
    it 'finds and cancels the order via DhanHQ Order model' do
      order_double = double('Order')
      expect(DhanHQ::Models::Order).to receive(:find).with('ORD123').and_return(order_double)
      expect(order_double).to receive(:cancel).and_return({ 'status' => 'success' })

      res = adapter.cancel_order('ORD123')
      expect(res).to eq({ success: true })
    end
  end

  describe '#positions' do
    it 'maps security IDs to symbol names and aggregates quantities' do
      pos1 = double('Position', security_id: 12345, net_qty: 15)
      pos2 = double('Position', security_id: 12345, net_qty: 20)
      expect(DhanHQ::Models::Position).to receive(:active).and_return([pos1, pos2])

      pos = adapter.positions
      expect(pos).to eq({ 'RELIANCE' => 35 })
    end
  end

  describe '#funds' do
    it 'extracts available balance' do
      funds_double = double('Funds', available_balance: 50000.75)
      expect(DhanHQ::Models::Funds).to receive(:fetch).and_return(funds_double)

      res = adapter.funds
      expect(res).to eq({ available: 50000.75 })
    end
  end
end
