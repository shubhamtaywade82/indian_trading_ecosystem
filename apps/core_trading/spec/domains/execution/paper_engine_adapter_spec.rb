# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Execution::PaperEngineAdapter do
  let(:config) { double('RuntimeConfig', mode: 'paper', paper_account_id: 'ACC_123') }
  let(:adapter) { described_class.new(config) }
  let(:client_double) { instance_double(Execution::PaperEngineClient) }

  before do
    allow(adapter).to receive(:paper_engine_client).and_return(client_double)
  end

  describe '#place_order' do
    it 'posts to paper engine orders endpoint' do
      payload = { instrument_id: 'RELIANCE', side: 'buy', qty: 10 }
      expect(client_double).to receive(:post).with(
        '/api/v1/orders',
        {
          order: { instrument_id: 'RELIANCE', side: 'buy', qty: 10, product_type: 'CNC' },
          account_id: 'ACC_123'
        }
      ).and_return({ success: true, data: { order_id: 'P_ORD_123' } })

      res = adapter.place_order(payload)
      expect(res).to eq({ order_id: 'P_ORD_123' })
    end

    it 'returns error hash if post fails' do
      payload = { instrument_id: 'RELIANCE', side: 'buy', qty: 10 }
      expect(client_double).to receive(:post).and_return({ success: false, error: 'Connection refused' })

      res = adapter.place_order(payload)
      expect(res).to eq({ success: false, error: 'Connection refused' })
    end
  end

  describe '#cancel_order' do
    it 'sends delete to paper engine order endpoint' do
      expect(client_double).to receive(:delete).with('/api/v1/orders/P_ORD_123').and_return({ success: true })
      adapter.cancel_order('P_ORD_123')
    end
  end

  describe '#positions' do
    it 'gets positions from paper engine' do
      expect(client_double).to receive(:get).with(
        '/api/v1/positions',
        account_id: 'ACC_123'
      ).and_return({ success: true, data: [{ instrument_id: 'RELIANCE', qty: 10, avg_price: 2500.0 }] })

      res = adapter.positions
      expect(res).to eq({
        'RELIANCE' => { qty: 10, value: 25000.0, avg_price: 2500.0 }
      })
    end
  end

  describe '#holdings' do
    it 'gets holdings from paper engine' do
      expect(client_double).to receive(:get).with(
        '/api/v1/holdings',
        account_id: 'ACC_123'
      ).and_return({ success: true, data: [] })

      res = adapter.holdings
      expect(res).to eq([])
    end
  end

  describe '#funds' do
    it 'gets funds from paper engine' do
      expect(client_double).to receive(:get).with(
        '/api/v1/funds',
        account_id: 'ACC_123'
      ).and_return({ success: true, data: { available: 100000.0 } })

      res = adapter.funds
      expect(res).to eq({ available: 100000.0 })
    end
  end
end
